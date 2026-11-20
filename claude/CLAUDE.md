# Operating modes

Default mode: IN THE LOOP. Do the step I asked. Stop. Report in one short message.
Never merge, commit, push, deploy, or close tickets unless I say so in the current task.

AFK mode: active only when I start a message with "AFK:". Work autonomously toward
the stated goal until done or hard-blocked. Use background tasks and monitors.
Send a push notification on completion or blockage. Report numbers first on my return.


# Committing

Don't ever enter your name (Claude or Claude Code) into my commit messages.
Don't ever enter co-authored text in commit messages.


# Writing code

## Comments

Avoid writing paragraph-long comments. Comments should be two lines long at most.

If you feel the urge to write paragraph-long comments, you need to make the code cleaner so it's more obvious what the
code is doing. I will grant you exceptions to this rule, but they must be approved explicitly by me.


# Claude Code configuration

`~/.claude/CLAUDE.md`, `settings.json`, `hooks/`, and the managed skills are read-only links from `~/dotfiles`.
Do not edit them in `~/.claude`. Change the sources in `~/dotfiles/claude/` and
`~/dotfiles/modules/home/claude-code.nix`, build, and ask me to activate.
