#!/usr/bin/env bash
# PreToolUse(Bash) hook: deny Co-Authored-By trailers and the name Claude in commit and PR messages.
# Managed by ~/dotfiles (claude/hooks, modules/home/claude-code.nix).

input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
[ -z "$cmd" ] && exit 0

# Flatten newlines/tabs so multiline heredoc messages match on one line.
c="$(printf '%s' "$cmd" | tr '\n\r\t' '   ')"

deny() {
  jq -nc --arg r "BLOCKED by attribution hook (user rule: no Co-Authored-By or Claude in commit messages). $1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

m() { printf '%s' "$c" | grep -Eiq "$1"; }

# Only care about commands that write a message somewhere.
if ! m '(git[[:space:]]+(commit|merge|tag|notes)|gh[[:space:]]+pr[[:space:]]+(create|edit|merge)|gh[[:space:]]+release|git[[:space:]]+commit-tree|git[[:space:]]+interpret-trailers)'; then
  exit 0
fi

if m 'co-authored-by'; then
  deny "Remove the Co-Authored-By trailer and re-run."
fi

if m 'noreply@anthropic\.com'; then
  deny "Remove the anthropic.com author line and re-run."
fi

if m 'generated[[:space:]]+with[[:space:]]+\[?claude'; then
  deny "Remove the 'Generated with Claude Code' footer and re-run."
fi

if m '(^|[^A-Za-z])claude([^A-Za-z]|$)'; then
  deny "Remove the word 'Claude' from the message and re-run."
fi

exit 0
