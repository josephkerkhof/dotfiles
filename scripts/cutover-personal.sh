#!/bin/bash

set -Eeuo pipefail

readonly EXPECTED_HOST="Josephs-MacBook-Pro"
readonly NIX_BIN="/nix/var/nix/profiles/default/bin/nix"
readonly NIX_ENV="/nix/var/nix/profiles/default/bin/nix-env"
readonly CONFIRMATION="CUT OVER JOSEPHS MAC"

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

[[ ${1:-} == "--execute" ]] || fail "run with --execute after reviewing this script"
[[ $EUID -ne 0 ]] || fail "run as the normal user; the script requests sudo when needed"

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo"

[[ $repo == "$HOME/dotfiles" ]] || fail "expected repository at $HOME/dotfiles"
[[ $(scutil --get LocalHostName) == "$EXPECTED_HOST" ]] || fail "this is not the personal canary"
[[ $(uname -m) == "arm64" ]] || fail "expected Apple Silicon"
[[ $(git branch --show-current) == "nix" ]] || fail "expected the nix branch"
[[ -z $(git status --porcelain) ]] || fail "the Git worktree is not clean"
[[ -x $NIX_BIN && -x $NIX_ENV ]] || fail "Determinate Nix is unavailable"

expected_brew_roots=$(printf '%s\n' \
  act \
  age \
  blueutil \
  cloudflared \
  coreutils \
  direnv \
  dnsmasq \
  doctl \
  fastfetch \
  ffmpeg \
  gemini-cli \
  gh \
  git-lfs \
  glow \
  gnupg \
  go \
  golang-migrate \
  hashicorp/tap/terraform \
  helm \
  htop \
  hugo \
  jj \
  jq \
  kubernetes-cli \
  lazygit \
  libpq \
  mysql@8.4 \
  neovim \
  node \
  node@22 \
  opencode \
  osv-scanner \
  pandoc \
  pcre2 \
  phpantom-lsp \
  pinentry-mac \
  pnpm \
  poppler \
  ripgrep \
  roadrunner \
  starship \
  stow \
  switchaudio-osx \
  temporal \
  the_silver_searcher \
  tree \
  tree-sitter-cli \
  wget \
  yt-dlp \
  zsh-syntax-highlighting)

brew_roots=$(brew info --installed --json=v2 | jq -r \
  '.formulae[] | select(any(.installed[]; .installed_on_request == true)) | .full_name' | sort)
[[ $brew_roots == "$expected_brew_roots" ]] || {
  printf 'Homebrew requested formulae changed since review. Expected:\n%s\n\nActual:\n%s\n' \
    "$expected_brew_roots" "$brew_roots" >&2
  exit 1
}

base_brew_casks=(bruno caffeine codex font-hack font-hack-nerd-font ghostty mactex-no-gui ngrok vlc)
adopted_brew_casks=(discord logos steam telegram)
replaced_brew_casks=(balenaetcher raspberry-pi-imager signal)
for cask in "${base_brew_casks[@]}"; do
  brew list --cask "$cask" >/dev/null 2>&1 || fail "expected Homebrew cask is missing: $cask"
done
while IFS= read -r cask; do
  case $cask in
    balenaetcher | bruno | caffeine | codex | discord | font-hack | font-hack-nerd-font | ghostty | logos | mactex-no-gui | ngrok | raspberry-pi-imager | signal | steam | telegram | vlc) ;;
    *) fail "unexpected Homebrew cask: $cask" ;;
  esac
done < <(brew list --cask)
[[ $(brew tap) == $'anomalyco/tap\nhashicorp/tap' ]] || fail "Homebrew taps changed since review"

expected_apps=(
  "/Applications/IntelliJ IDEA.app"
  /Applications/Output
  /Applications/Sparrow.app
  /Applications/X-Plane
  /Applications/balenaEtcher.app
  /Applications/Discord.app
  /Applications/Logos.app
  /Applications/MakeMKV.app
  "/Applications/Raspberry Pi Imager.app"
  /Applications/Signal.app
  /Applications/Steam.app
  /Applications/Telegram.app
  /Applications/zoom.us.app
)
for app in "${expected_apps[@]}"; do
  [[ -e $app || -L $app ]] || fail "expected application path is missing: $app"
done

[[ $(readlink "$HOME/.zshenv") == "dotfiles/zsh/.zshenv" ]] || fail "unexpected ~/.zshenv owner"
[[ $(readlink "$HOME/.zshrc") == "dotfiles/zsh/.zshrc" ]] || fail "unexpected ~/.zshrc owner"
[[ $(readlink "$HOME/.gitconfig") == "dotfiles/git/.gitconfig" ]] || fail "unexpected ~/.gitconfig owner"
[[ $(readlink "$HOME/.config/ghostty") == "../dotfiles/ghostty/.config/ghostty" ]] || fail "unexpected Ghostty owner"
[[ $(readlink "$HOME/.config/lazygit") == "../dotfiles/lazygit/.config/lazygit" ]] || fail "unexpected LazyGit owner"
[[ $(readlink "$HOME/.config/nvim") == "../dotfiles/nvim/.config/nvim" ]] || fail "unexpected Neovim owner"

tmutil destinationinfo | grep -q 'Name *: tm-kerkhof' || fail "expected Time Machine destination is unavailable"
printf 'Verify Time Machine completed a current backup, then type exactly: %s\n> ' "$CONFIRMATION"
read -r confirmation
[[ $confirmation == "$CONFIRMATION" ]] || fail "backup confirmation did not match"

mkdir -p "$HOME/.local/state/nix-cutover"
git rev-parse HEAD >"$HOME/.local/state/nix-cutover/git-revision.before"
brew leaves >"$HOME/.local/state/nix-cutover/brew-leaves.before"
printf '%s\n' "$brew_roots" >"$HOME/.local/state/nix-cutover/brew-roots.before"
brew list --cask >"$HOME/.local/state/nix-cutover/brew-casks.before"

"$NIX_BIN" flake check path:. --print-build-logs
"$NIX_BIN" build path:.#darwinConfigurations.personal.system --out-link result-personal
SYSTEM_PATH=$(readlink result-personal)
readonly SYSTEM_PATH
[[ -x $SYSTEM_PATH/activate ]] || fail "personal system activation is missing"

casks_to_adopt=()
for cask in "${adopted_brew_casks[@]}"; do
  if ! brew list --cask "$cask" >/dev/null 2>&1; then
    casks_to_adopt+=("$cask")
  fi
done
if ((${#casks_to_adopt[@]})); then
  brew install --cask --adopt "${casks_to_adopt[@]}"
fi

casks_to_replace=()
for cask in "${replaced_brew_casks[@]}"; do
  if ! brew list --cask "$cask" >/dev/null 2>&1; then
    casks_to_replace+=("$cask")
  fi
done
if ((${#casks_to_replace[@]})); then
  brew install --cask --force "${casks_to_replace[@]}"
fi

sudo -v

# Parent-directory Stow links must be gone before Home Manager writes children.
/opt/homebrew/bin/stow --dir="$repo" --target="$HOME" --delete ghostty git lazygit nvim zsh

sudo "$NIX_ENV" --profile /nix/var/nix/profiles/system --set "$SYSTEM_PATH"
sudo "$SYSTEM_PATH/activate"

readonly PROFILE_BIN="/etc/profiles/per-user/$USER/bin"
[[ -x $PROFILE_BIN/nvim ]] || fail "Home Manager Neovim is unavailable"
[[ -x $PROFILE_BIN/opencode ]] || fail "Home Manager OpenCode is unavailable"
[[ -x $PROFILE_BIN/gpg ]] || fail "Home Manager GnuPG is unavailable"
[[ $(readlink "$HOME/.config/ghostty/config") == /nix/store/* ]] || fail "Ghostty is not Home Manager owned"
[[ $(readlink "$HOME/.config/lazygit/config.yml") == /nix/store/* ]] || fail "LazyGit is not Home Manager owned"
[[ $("$PROFILE_BIN/git" config --global --get user.signingkey) == "51C7FCE5909B5D1F80813F0671A696CAC91CEA76" ]] || fail "Git signing key is not configured"
[[ $("$PROFILE_BIN/git" config --global --get commit.gpgsign) == "true" ]] || fail "Git commit signing is not enabled"
"$PROFILE_BIN/gpg" --list-secret-keys 51C7FCE5909B5D1F80813F0671A696CAC91CEA76 >/dev/null

"$PROFILE_BIN/nvim" --headless \
  -c 'lua assert(vim.g.nix_nvim_config:find("/nix/store/", 1, true) == 1); assert(vim.fn.exists(":Lazy") == 0); assert(vim.fn.exists(":Mason") == 0)' \
  -c qa
"$PROFILE_BIN/opencode" --version
/bin/zsh -lic '
  for command in nvim git direnv starship; do
    command_path=$(command -v "$command") || exit 1
    print -r -- "$command_path"
    [[ $command_path == /etc/profiles/per-user/$USER/bin/* ]] || exit 1
  done
'

grep -q 'pam_tid.so' /etc/pam.d/sudo_local || fail "Touch ID sudo authentication is not configured"
grep -q 'pam_watchid.so' /etc/pam.d/sudo_local || fail "Apple Watch sudo authentication is not configured"
[[ $(defaults read NSGlobalDomain ApplePressAndHoldEnabled) == 0 ]] || fail "keyboard defaults are not active"
[[ $(defaults read com.apple.dock autohide) == 1 ]] || fail "Dock defaults are not active"
[[ $(defaults read com.apple.finder FXPreferredViewStyle) == "Nlsv" ]] || fail "Finder defaults are not active"
[[ $(defaults read com.apple.screencapture location) == "$HOME/Pictures/Screenshots" ]] || fail "screenshot defaults are not active"

brew services stop cloudflared >/dev/null 2>&1 || true
sudo /opt/homebrew/bin/brew services stop dnsmasq >/dev/null 2>&1 || true
brew services stop mysql@8.4 >/dev/null 2>&1 || true
brew services stop temporal >/dev/null 2>&1 || true

formulae=()
while IFS= read -r formula; do
  [[ -n $formula ]] && formulae+=("$formula")
done <<<"$expected_brew_roots"
brew uninstall --formula "${formulae[@]}"
brew uninstall --cask font-hack mactex-no-gui
brew autoremove
brew untap anomalyco/tap hashicorp/tap

rm -rf \
  "$HOME/.bun" \
  "$HOME/.cargo" \
  "$HOME/.rustup" \
  "$HOME/.local/share/nvim/lazy" \
  "$HOME/.local/share/nvim/mason" \
  "$HOME/.local/share/nvim/site"
rm -f "$HOME/.local/share/nvim"/tree-sitter-*.tar.gz
rm -f \
  "$HOME/Library/Fonts/BerkeleyMono-Regular.otf" \
  "$HOME/Library/Fonts/BerkeleyMono-Bold.otf" \
  "$HOME/Library/Fonts/BerkeleyMono-Oblique.otf" \
  "$HOME/Library/Fonts/BerkeleyMono-Bold-Oblique.otf"
sudo rm -rf \
  "/Applications/IntelliJ IDEA.app" \
  /Applications/Output \
  /Applications/Sparrow.app \
  /Applications/X-Plane \
  /Applications/zoom.us.app
sudo rm -rf /opt/homebrew/var/mysql
rmdir "$HOME/.local/bin" >/dev/null 2>&1 || true
rm -f "$HOME/.gnupg/gpg-agent.conf.hm-backup"

[[ $(brew leaves) == "mas" ]] || fail "Homebrew formula leaves should contain only mas"
for app in "/Applications/IntelliJ IDEA.app" /Applications/Output /Applications/Sparrow.app /Applications/X-Plane /Applications/zoom.us.app; do
  [[ ! -e $app && ! -L $app ]] || fail "removed application path remains: $app"
done
expected_brew_casks=$(printf '%s\n' \
  balenaetcher \
  bruno \
  caffeine \
  codex \
  discord \
  font-hack-nerd-font \
  ghostty \
  logos \
  ngrok \
  raspberry-pi-imager \
  signal \
  steam \
  telegram \
  vlc)
[[ $(brew list --cask) == "$expected_brew_casks" ]] || fail "unexpected Homebrew cask inventory after cleanup"
[[ -z $(brew tap) ]] || fail "unexpected Homebrew taps remain after cleanup"
for app_id in 682658836 408981434 361285480 361304891 361309726 1289583905 1662217862; do
  /opt/homebrew/bin/mas list | grep -q "^$app_id " || fail "App Store application is missing: $app_id"
done

readonly TARGET_PATH="$PROFILE_BIN:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin"
for removed in terraform node pnpm npm wrangler mysql temporal rr act cloudflared dnsmasq migrate hugo psql pandoc rustc cargo bun pdflatex gemini; do
  if PATH="$TARGET_PATH" command -v "$removed" >/dev/null 2>&1; then
    fail "removed command still resolves: $removed"
  fi
done

"$PROFILE_BIN/nvim" --headless -c 'lua assert(vim.fn.exists(":Lazy") == 0); assert(vim.fn.exists(":Mason") == 0)' -c qa
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate | grep -qi enabled || fail "application firewall is not enabled"

printf '\nPersonal Nix cutover completed. Keep %s/result-personal until the canary is accepted.\n' "$repo"
