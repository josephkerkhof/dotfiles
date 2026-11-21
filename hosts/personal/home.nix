_: {
  # Codex writes config.toml and rules/ itself, so they stay mutable.
  programs.codex = {
    enable = true;
    context = ../../agents/AGENTS.md;

    # Same hook that `rex skill setup --agent codex` writes.
    hooks.SessionStart = [
      {
        hooks = [
          {
            type = "command";
            command = "/bin/sh -c 'rex __internal session-start --agent codex --feature-session-naming=false 2>/dev/null || true'";
            timeout = 5;
            statusMessage = "Loading Rex terminal context";
          }
        ];
      }
    ];
  };
}
