#!/usr/bin/env bash

set -Eeuo pipefail

readonly program_name="workstation"
readonly default_flake_dir="${WORKSTATION_FLAKE:-${HOME:-}/dotfiles}"
readonly system_profile="/nix/var/nix/profiles/system"
readonly nix_env="/nix/var/nix/profiles/default/bin/nix-env"
readonly nix_store="/nix/var/nix/profiles/default/bin/nix-store"
readonly darwin_rebuild="/run/current-system/sw/bin/darwin-rebuild"

command_name=""
target=""
expected_hostname=""
flake_dir="$default_flake_dir"
flake_ref=""
build_flake_ref=""
workstations_json=""
candidate_path=""
temporary_snapshot_root=""
temporary_work_dir=""
assume_yes=false
workstation_was_set=false
flake_was_set=false
help_requested=false

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  readonly bold=$'\033[1m'
  readonly blue=$'\033[34m'
  readonly green=$'\033[32m'
  readonly yellow=$'\033[33m'
  readonly reset=$'\033[0m'
else
  readonly bold=""
  readonly blue=""
  readonly green=""
  readonly yellow=""
  readonly reset=""
fi

usage() {
  cat <<'EOF'
Manage tested nix-darwin workstation systems safely.

Usage:
  workstation <command> [options]
  workstation help [command]

Everyday workflow:
  workstation test                 Check and build this Mac's configuration
  workstation activate             Activate the tested candidate
  workstation apply                Test, then activate the candidate

Commands:
  test       Check the flake and build result-<workstation>
  activate   Activate an existing, matching candidate
  apply      Run test followed by activate
  status     Compare the candidate, selected, and running systems
  list       List declared workstations and hostnames
  gc         Preview and optionally collect machine-wide Nix store garbage
  help       Show general or command-specific help

Options:
  --workstation=NAME   Target a declared Darwin configuration
  --flake=PATH         Use a checkout other than ~/dotfiles
  --yes                Skip the activate or garbage-collection confirmation
  -h, --help           Show help

The workstation is inferred from the current hostname when --workstation is
omitted. Testing another workstation is allowed; activating it on the wrong Mac
is not.

Examples:
  workstation apply
  workstation test --workstation=work
  workstation status --workstation personal
  workstation gc
  workstation help activate
EOF
}

command_help() {
  case "$1" in
    test)
      cat <<'EOF'
Usage: workstation test [--workstation=NAME] [--flake=PATH]

Archive one immutable source snapshot, run all flake checks against it, then
build the selected Darwin configuration into its result-<workstation> candidate
link. This does not alter the running system.

Examples:
  workstation test
  workstation test --workstation=personal
  workstation --workstation work test
EOF
      ;;
    activate)
      cat <<'EOF'
Usage: workstation activate [--workstation=NAME] [--flake=PATH] [--yes]

Activate a matching result-<workstation> candidate, normally created by
`workstation test`. The declared hostname must match this Mac. The command shows
the current and candidate paths, asks for confirmation, uses sudo only for
system activation, and verifies that all system links agree afterward.

Use --yes only when the activation has already been reviewed.
EOF
      ;;
    apply)
      cat <<'EOF'
Usage: workstation apply [--workstation=NAME] [--flake=PATH] [--yes]

Run `workstation test`, then activate the resulting candidate after showing the
planned switch and asking for confirmation. Use --yes to skip that confirmation.
EOF
      ;;
    status)
      cat <<'EOF'
Usage: workstation status [--workstation=NAME] [--flake=PATH]

Show the selected workstation and compare its result link with the selected
system profile and the currently running system. This command changes nothing.
EOF
      ;;
    list)
      cat <<'EOF'
Usage: workstation list [--flake=PATH]

List the nix-darwin configurations declared by the flake and their hostnames.
The configuration matching the current Mac is marked as current.
EOF
      ;;
    gc)
      cat <<'EOF'
Usage: workstation gc [--yes]

List retained system generations and preview machine-wide Nix store garbage.
After the preview, ask before collecting unreferenced paths. Candidate result
links and other Nix garbage-collection roots remain protected.

Garbage collection is not scoped to a workstation. Successful activation
already limits the system profile to its newest five generations.
EOF
      ;;
    help)
      cat <<'EOF'
Usage: workstation help [command]

Show general help or detailed help for one command.
EOF
      ;;
    *)
      fail "Unknown command '$1'. Run 'workstation help' to see valid commands."
      ;;
  esac
}

fail() {
  printf '%sError:%s %s\n' "$bold" "$reset" "$*" >&2
  exit 1
}

note() {
  printf '%s%s%s\n' "$blue" "$*" "$reset"
}

success() {
  printf '%sOK:%s %s\n' "$green" "$reset" "$*"
}

warning() {
  printf '%sWarning:%s %s\n' "$yellow" "$reset" "$*" >&2
}

cleanup() {
  if [[ -n "$temporary_snapshot_root" ]]; then
    rm -f "$temporary_snapshot_root" || true
  fi
  if [[ -n "$temporary_work_dir" ]]; then
    rmdir "$temporary_work_dir" 2>/dev/null || true
  fi
}

trap cleanup EXIT

step() {
  printf '\n%s%s%s\n' "$bold" "$*" "$reset"
}

expand_flake_dir() {
  case "$flake_dir" in
    "~")
      [[ -n ${HOME:-} ]] || fail "HOME is unset, so '~' cannot be expanded. Use an absolute --flake path."
      flake_dir="$HOME"
      ;;
    \~/*)
      [[ -n ${HOME:-} ]] || fail "HOME is unset, so '~' cannot be expanded. Use an absolute --flake path."
      flake_dir="$HOME/${flake_dir#\~/}"
      ;;
  esac
}

prepare_flake() {
  [[ -n ${HOME:-} || $flake_was_set == true || -n ${WORKSTATION_FLAKE:-} ]] \
    || fail "HOME is unset. Select the workstation checkout with --flake=PATH."
  expand_flake_dir
  [[ -d "$flake_dir" ]] || fail "Flake directory '$flake_dir' does not exist. Use --flake=PATH to select it."
  [[ -f "$flake_dir/flake.nix" ]] || fail "No flake.nix exists in '$flake_dir'. Use --flake=PATH to select the workstation checkout."
  flake_dir="$(readlink -f "$flake_dir")"
  flake_ref="path:$flake_dir"
}

ensure_normal_user() {
  [[ $EUID -ne 0 ]] || fail "Run this command as your normal user. It invokes sudo only for activation and listing system generations."
  command -v nix >/dev/null 2>&1 || fail "The nix command is unavailable in PATH."
}

load_workstations() {
  if ! workstations_json="$(nix eval --json "$flake_ref#darwinConfigurations" \
    --no-write-lock-file \
    --apply 'configs: builtins.mapAttrs (_: value: value.config.networking.hostName) configs')"; then
    fail "Could not evaluate Darwin workstations from '$flake_dir'. Review the Nix error above."
  fi

  jq -e 'type == "object"' >/dev/null <<<"$workstations_json" \
    || fail "darwinConfigurations did not evaluate to a workstation set."
}

available_workstations() {
  jq -r 'keys | join(", ")' <<<"$workstations_json"
}

validate_target_name() {
  [[ $target =~ ^[A-Za-z_][A-Za-z0-9_-]*$ ]] \
    || fail "Unsupported workstation name '$target'. Use a name beginning with a letter or underscore, followed by letters, numbers, underscores, or hyphens."
}

resolve_target() {
  local current_hostname
  local matches

  if [[ -n "$target" ]]; then
    validate_target_name
  fi
  prepare_flake
  load_workstations
  current_hostname="$(/bin/hostname -s)"

  if [[ -n "$target" ]]; then
    jq -e --arg target "$target" 'has($target)' >/dev/null <<<"$workstations_json" \
      || fail "Unknown workstation '$target'. Available workstations: $(available_workstations)."
  else
    matches="$(jq -r --arg hostname "$current_hostname" \
      'to_entries[] | select(.value == $hostname) | .key' <<<"$workstations_json")"

    if [[ -z "$matches" ]]; then
      fail "No workstation declares hostname '$current_hostname'. Select one with --workstation=NAME. Available: $(available_workstations)."
    fi
    if [[ $(wc -l <<<"$matches" | tr -d ' ') -ne 1 ]]; then
      fail "More than one workstation declares hostname '$current_hostname': $(tr '\n' ' ' <<<"$matches"). Use --workstation=NAME."
    fi

    target="$matches"
    validate_target_name
  fi

  expected_hostname="$(jq -r --arg target "$target" '.[$target]' <<<"$workstations_json")"
}

snapshot_flake() {
  local archive_json
  local snapshot_path

  if ! archive_json="$(nix flake archive --json --no-write-lock-file "$flake_ref")"; then
    fail "Could not create an immutable source snapshot from '$flake_dir'. Review the Nix error above."
  fi
  snapshot_path="$(jq -r '.path // empty' <<<"$archive_json")"
  [[ $snapshot_path == /nix/store/* ]] || fail "Nix did not return a valid source snapshot path."
  [[ -x "$nix_store" ]] || fail "The system nix-store executable is unavailable: $nix_store"
  temporary_work_dir="$(mktemp -d "${TMPDIR:-/tmp}/workstation.XXXXXX")"
  temporary_snapshot_root="$temporary_work_dir/source"
  if ! "$nix_store" --add-root "$temporary_snapshot_root" --realise "$snapshot_path" >/dev/null; then
    fail "Could not protect the source snapshot from garbage collection."
  fi
  build_flake_ref="path:$snapshot_path"
}

candidate_link() {
  printf '%s/result-%s\n' "$flake_dir" "$target"
}

resolve_link() {
  local path="$1"
  if [[ -e "$path" || -L "$path" ]]; then
    readlink -f "$path" 2>/dev/null || true
  fi
}

validate_candidate() {
  local candidate="$1"
  local candidate_target
  local candidate_hostname

  [[ -f "$candidate/workstation-name" && -f "$candidate/workstation-hostname" ]] \
    || fail "The $target candidate has no workstation identity. Rebuild it with '$program_name test --workstation=$target'."
  candidate_target="$(<"$candidate/workstation-name")"
  candidate_hostname="$(<"$candidate/workstation-hostname")"
  [[ $candidate_target == "$target" ]] \
    || fail "The result-$target link contains a '$candidate_target' system. Rebuild the candidate before activation."
  [[ $candidate_hostname == "$expected_hostname" ]] \
    || fail "The $target candidate was built for '$candidate_hostname', but the checkout now declares '$expected_hostname'. Rebuild it before activation."
}

candidate_matches_target() {
  local candidate="$1"

  [[ -f "$candidate/workstation-name" && -f "$candidate/workstation-hostname" ]] \
    && [[ "$(<"$candidate/workstation-name")" == "$target" ]] \
    && [[ "$(<"$candidate/workstation-hostname")" == "$expected_hostname" ]]
}

print_target() {
  printf '%sTarget:%s        %s' "$bold" "$reset" "$target"
  if [[ $workstation_was_set == false ]]; then
    printf ' (inferred)'
  fi
  printf '\n%sDeclared host:%s %s\n' "$bold" "$reset" "$expected_hostname"
  printf '%sFlake:%s         %s\n' "$bold" "$reset" "$flake_dir"
}

confirm() {
  local prompt="$1"
  local answer

  if [[ $assume_yes == true ]]; then
    return 0
  fi
  [[ -t 0 ]] || fail "Confirmation requires an interactive terminal. Review the operation, then rerun it with --yes."

  printf '%s [y/N] ' "$prompt"
  read -r answer
  [[ $answer == "y" || $answer == "Y" || $answer == "yes" || $answer == "YES" ]]
}

run_test() {
  local candidate
  local published_candidate

  print_target

  step "[1/3] Capturing one source snapshot"
  snapshot_flake

  step "[2/3] Checking the flake"
  if ! nix flake check "$build_flake_ref" --no-write-lock-file --print-build-logs; then
    fail "Checks failed. Fix the reported issue and run '$program_name test --workstation=$target' again."
  fi

  step "[3/3] Building $target"
  if ! candidate="$(nix build "$build_flake_ref#darwinConfigurations.$target.system" \
    --no-write-lock-file \
    --out-link "$(candidate_link)" --print-build-logs --print-out-paths)"; then
    fail "The $target system did not build. The running system was not changed."
  fi

  [[ $candidate == /nix/store/* && $candidate != *$'\n'* ]] \
    || fail "The build did not return exactly one system output."
  validate_candidate "$candidate"
  published_candidate="$(resolve_link "$(candidate_link)")"
  [[ $published_candidate == "$candidate" ]] \
    || fail "Another process changed $(candidate_link) while it was being built. Rerun the test before activation."
  candidate_path="$candidate"

  printf '\n'
  success "Candidate ready for $target"
  printf '  %s\n' "$candidate"

  if [[ $expected_hostname == "$(/bin/hostname -s)" ]]; then
    printf '\nNext:\n  %s activate --workstation=%s\n' "$program_name" "$target"
  else
    printf '\nBuilt for %s. Activation is blocked on this Mac (%s).\n' \
      "$expected_hostname" "$(/bin/hostname -s)"
  fi
}

run_activate() {
  local candidate
  local current_hostname
  local profile
  local running

  current_hostname="$(/bin/hostname -s)"
  ensure_activation_target
  [[ -x "$nix_env" ]] || fail "The system nix-env executable is unavailable: $nix_env"

  candidate="${candidate_path:-$(resolve_link "$(candidate_link)")}"
  [[ -n "$candidate" ]] \
    || fail "No valid candidate exists for $target. Run '$program_name test --workstation=$target' first."
  validate_candidate "$candidate"
  [[ -x "$candidate/activate" ]] \
    || fail "The $target candidate has no executable activation program: $candidate/activate"

  profile="$(resolve_link "$system_profile")"
  running="$(resolve_link /run/current-system)"

  print_target
  printf '%sCurrent:%s       %s\n' "$bold" "$reset" "${running:-(unavailable)}"
  printf '%sSelected:%s      %s\n' "$bold" "$reset" "${profile:-(unavailable)}"
  printf '%sCandidate:%s     %s\n' "$bold" "$reset" "$candidate"

  printf '\nActivation updates macOS, Homebrew, Home Manager, and user configuration.\n'
  if ! confirm "Activate $target on $current_hostname?"; then
    warning "Activation cancelled; no changes were made."
    return 0
  fi

  step "[1/3] Authorizing system activation"
  /usr/bin/sudo -v

  step "[2/3] Selecting and activating $target"
  /usr/bin/sudo -H "$nix_env" --profile "$system_profile" --set "$candidate"
  if ! /usr/bin/sudo -H "$candidate/activate"; then
    fail "Activation failed. Inspect the output above and compare '$system_profile' with /run/current-system before continuing."
  fi

  step "[3/3] Verifying the running system"
  profile="$(resolve_link "$system_profile")"
  running="$(resolve_link /run/current-system)"
  if [[ $candidate != "$profile" ]] || [[ $candidate != "$running" ]]; then
    printf '  Candidate: %s\n  Selected:  %s\n  Running:   %s\n' \
      "$candidate" "${profile:-(unavailable)}" "${running:-(unavailable)}" >&2
    fail "Activation did not converge on one system. Review the paths above before making further changes."
  fi

  success "$target is selected and running"
  printf '  %s\n' "$running"
  printf '\nTest the command, application, or preference you changed before committing.\n'
}

run_status() {
  local candidate
  local profile
  local running

  candidate="$(resolve_link "$(candidate_link)")"
  profile="$(resolve_link "$system_profile")"
  running="$(resolve_link /run/current-system)"

  print_target
  printf '%sCurrent host:%s  %s\n' "$bold" "$reset" "$(/bin/hostname -s)"
  printf '\n%sCandidate:%s %s\n' "$bold" "$reset" "${candidate:-(not built)}"
  printf '%sSelected:%s  %s\n' "$bold" "$reset" "${profile:-(unavailable)}"
  printf '%sRunning:%s   %s\n' "$bold" "$reset" "${running:-(unavailable)}"

  if [[ -z "$candidate" ]]; then
    printf '\nNext:\n  %s test --workstation=%s\n' "$program_name" "$target"
  elif ! candidate_matches_target "$candidate"; then
    warning "The candidate identity does not match $target. It cannot be activated."
    printf 'Next:\n  %s test --workstation=%s\n' "$program_name" "$target"
  elif [[ $candidate == "$profile" && $candidate == "$running" ]]; then
    printf '\n'
    success "The candidate is selected and running"
  elif [[ $profile == "$running" ]]; then
    note "A candidate is ready but not active."
    printf 'Next:\n  %s activate --workstation=%s\n' "$program_name" "$target"
  else
    warning "The selected and running systems differ. Inspect this state before activating another candidate."
  fi
}

run_list() {
  local current_hostname
  local name
  local hostname
  local marker

  current_hostname="$(/bin/hostname -s)"
  printf '%sDeclared Darwin workstations%s\n\n' "$bold" "$reset"
  printf '%-20s %-30s %s\n' "WORKSTATION" "HOSTNAME" "MATCH"

  while IFS=$'\t' read -r name hostname; do
    marker=""
    if [[ $hostname == "$current_hostname" ]]; then
      marker="current"
    fi
    printf '%-20s %-30s %s\n' "$name" "$hostname" "$marker"
  done < <(jq -r 'to_entries | sort_by(.key)[] | [.key, .value] | @tsv' <<<"$workstations_json")

  printf '\nCurrent hostname: %s\n' "$current_hostname"
}

run_gc() {
  [[ -x "$darwin_rebuild" ]] || fail "The running system has no darwin-rebuild executable: $darwin_rebuild"

  step "[1/2] Retained system generations"
  /usr/bin/sudo -H "$darwin_rebuild" --list-generations

  step "[2/2] Machine-wide garbage collection preview"
  nix store gc --dry-run

  printf '\nCollection affects all unreferenced Nix store paths on this Mac.\n'
  printf 'System generations, result-* candidates, and other registered roots remain protected.\n'
  printf 'Nix recalculates which paths are unreferenced when collection begins.\n'
  if ! confirm "Collect unreferenced store paths now?"; then
    warning "Garbage collection cancelled; no store paths were removed."
    return 0
  fi

  step "Collecting unreferenced store paths"
  nix store gc
  success "Nix store garbage collection completed"
}

ensure_activation_target() {
  local current_hostname

  current_hostname="$(/bin/hostname -s)"
  if [[ $expected_hostname != "$current_hostname" ]]; then
    fail "Refusing to activate $target: it declares '$expected_hostname', but this Mac is '$current_hostname'. Use '$program_name test --workstation=$target' to build it without activation."
  fi
}

parse_arguments() {
  local -a positional=()

  while (($#)); do
    case "$1" in
      --workstation=*)
        target="${1#*=}"
        [[ -n "$target" ]] || fail "--workstation requires a name."
        workstation_was_set=true
        ;;
      --workstation)
        shift
        (($#)) || fail "--workstation requires a name."
        target="$1"
        workstation_was_set=true
        ;;
      --flake=*)
        flake_dir="${1#*=}"
        [[ -n "$flake_dir" ]] || fail "--flake requires a path."
        flake_was_set=true
        ;;
      --flake)
        shift
        (($#)) || fail "--flake requires a path."
        flake_dir="$1"
        flake_was_set=true
        ;;
      --yes)
        assume_yes=true
        ;;
      -h | --help)
        help_requested=true
        ;;
      --)
        shift
        positional+=("$@")
        break
        ;;
      -*)
        fail "Unknown option '$1'. Run '$program_name help' to see valid options."
        ;;
      *)
        positional+=("$1")
        ;;
    esac
    shift
  done

  if ((${#positional[@]})); then
    command_name="${positional[0]}"
  fi
  if ((${#positional[@]} > 1)); then
    if [[ $command_name == help && ${#positional[@]} -eq 2 ]]; then
      command_help "${positional[1]}"
      exit 0
    fi
    fail "Unexpected argument '${positional[1]}'. Run '$program_name help ${command_name:-}' for usage."
  fi
}

main() {
  parse_arguments "$@"

  if [[ -z "$command_name" ]]; then
    usage
    exit 0
  fi
  if [[ $command_name == help ]]; then
    usage
    exit 0
  fi
  if [[ $help_requested == true ]]; then
    command_help "$command_name"
    exit 0
  fi

  case "$command_name" in
    test)
      [[ $assume_yes == false ]] || fail "The test command does not require confirmation; remove --yes."
      ;;
    activate | apply) ;;
    status)
      [[ $assume_yes == false ]] || fail "The status command does not use --yes."
      ;;
    list)
      [[ $workstation_was_set == false ]] || fail "The list command shows every workstation; remove --workstation."
      [[ $assume_yes == false ]] || fail "The list command does not use --yes."
      ;;
    gc)
      [[ $workstation_was_set == false ]] || fail "Garbage collection is machine-wide; remove --workstation."
      [[ $flake_was_set == false ]] || fail "Garbage collection does not evaluate a flake; remove --flake."
      ;;
    *)
      fail "Unknown command '$command_name'. Run '$program_name help' to see valid commands."
      ;;
  esac

  case "$command_name" in
    test | activate | apply | status)
      ensure_normal_user
      resolve_target
      if [[ $command_name == apply ]]; then
        ensure_activation_target
      fi
      ;;
    list)
      ensure_normal_user
      prepare_flake
      load_workstations
      ;;
    gc)
      ensure_normal_user
      ;;
  esac

  case "$command_name" in
    test) run_test ;;
    activate) run_activate ;;
    apply)
      run_test
      printf '\n%sCandidate testing complete; preparing activation.%s\n\n' "$bold" "$reset"
      run_activate
      ;;
    status) run_status ;;
    list) run_list ;;
    gc) run_gc ;;
  esac
}

main "$@"
