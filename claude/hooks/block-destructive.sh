#!/usr/bin/env bash
# PreToolUse(Bash) hook: deny force pushes, history rewrites, and other destructive commands.
# Managed by ~/dotfiles (claude/hooks, modules/home/claude-code.nix).

input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
[ -z "$cmd" ] && exit 0

# Flatten newlines/tabs so multiline commands match on one line.
c="$(printf '%s' "$cmd" | tr '\n\r\t' '   ')"

deny() {
  jq -nc --arg r "BLOCKED by safety hook (user rule: no force pushes or destructive commands). $1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

m() { printf '%s' "$c" | grep -Eq "$1"; }

# Force push — --force, --force-with-lease, -f, or a +refspec
if m 'git[[:space:]]+push([[:space:]]|$)' && \
   m 'git[[:space:]]+push.*(--force-with-lease|--force([[:space:]=]|$)|(^|[[:space:]])-[A-Za-z]*f([[:space:]]|$)|[[:space:]]\+[A-Za-z])'; then
  deny "Force push is disabled. Undo commits with 'git revert'; never rewrite pushed history."
fi

# Delete a remote branch/ref via push
if m 'git[[:space:]]+push.*(--delete([[:space:]]|$)|[[:space:]]:[A-Za-z._/-])'; then
  deny "Deleting a remote branch/ref via push is disabled."
fi

# git reset --hard
if m 'git[[:space:]]+reset([[:space:]]|$).*--hard'; then
  deny "'git reset --hard' discards your working tree. Use 'git restore' / 'git stash' / 'git revert'."
fi

# git clean -f (deletes untracked files)
if m 'git[[:space:]]+clean([[:space:]]|$).*(-[A-Za-z]*f|--force)'; then
  deny "'git clean -f' deletes untracked files."
fi

# git branch -D (force-delete, vs safe -d)
if m 'git[[:space:]]+branch[[:space:]]+(-[A-Za-z]*D([[:space:]]|$)|.*[[:space:]]-[A-Za-z]*D([[:space:]]|$)|--delete.*--force|--force.*--delete)'; then
  deny "'git branch -D' force-deletes a branch. Use 'git branch -d' (merged branches only)."
fi

# git rebase (history rewrite) — but allow the recovery subcommands
if m 'git[[:space:]]+rebase([[:space:]]|$)' && \
   ! m 'git[[:space:]]+rebase.*(--abort|--continue|--skip|--quit|--edit-todo|--show-current-patch)'; then
  deny "'git rebase' rewrites history."
fi

# filter-branch / filter-repo (history rewrite)
if m 'git[[:space:]]+filter-(branch|repo)([[:space:]]|$)'; then
  deny "filter-branch / filter-repo rewrite history."
fi

# reflog expire / gc --prune (destroy recovery data)
if m 'git[[:space:]]+reflog[[:space:]]+expire'; then
  deny "'git reflog expire' destroys recovery history."
fi
if m 'git[[:space:]]+gc([[:space:]]|$).*--prune'; then
  deny "'git gc --prune' destroys unreachable objects."
fi

# rm -rf (and -fr, -r -f, -f -r, with -R)
if m '(^|[[:space:];&|(`])rm[[:space:]].*(-[A-Za-z]*[rR][A-Za-z]*f|-[A-Za-z]*f[A-Za-z]*[rR]|-[rR][[:space:]]+-f|-f[[:space:]]+-[rR])'; then
  deny "'rm -rf' is irreversible. Delete specific paths without -rf, or move them to a trash dir."
fi

exit 0
