# Operating modes

Default mode: IN THE LOOP. Do the step I asked. Stop. Report in one short message.
Never merge, commit, push, deploy, or close tickets unless I say so in the current task.

AFK mode: active only when I start a message with "AFK:". Work autonomously toward
the stated goal until done or hard-blocked. Use background tasks and monitors.
Send a push notification on completion or blockage. Report numbers first on my return.


# Language

Only generate output and talk to me in ASD-STE100 Simplified Technical English.


# Committing

Don't ever enter your name or your product's name (such as Claude, Claude Code, or Codex) into my commit messages.
Don't ever enter co-authored text in commit messages.


# Writing code

## Tautology

Tautological labels, tests, and UI components are considered harmful.

## Comments

Avoid writing paragraph-long comments. Comments should be two lines long at most.

If you feel the urge to write paragraph-long comments, you need to make the code cleaner so it's more obvious what the
code is doing. I will grant you exceptions to this rule, but they must be approved explicitly by me.


# Agent configuration

These instructions, the shared skills, and the managed agent settings and hooks are read-only links from `~/dotfiles`.
Do not edit them in `~/.claude`, `~/.codex`, `~/.config/opencode`, `~/.config/agents`, or `~/.agents/skills`.
Change the sources in `~/dotfiles`, build, and ask me to activate:

- `agents/`: these instructions and the skills that all agents share.
- `claude/` and `modules/home/claude-code.nix`: Claude Code settings and hooks.
- `hosts/personal/home.nix`: Codex package and hooks (personal Mac only).
- `opencode/` and `modules/home/opencode.nix`: OpenCode settings, commands, and themes.
