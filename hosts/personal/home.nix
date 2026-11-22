{
  inputs,
  lib,
  pkgs,
  ...
}: let
  mcp-musescore = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.mcp-musescore;
in {
  programs = {
    # Codex writes config.toml and rules/ itself, so they stay mutable.
    codex = {
      enable = true;
      context = ../../agents/AGENTS.md;
      enableMcpIntegration = true;
      # Merge the declared MCP servers into the mutable config.toml.
      mutableSettings = true;

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

    mcp = {
      enable = true;
      servers.musescore.command = lib.getExe mcp-musescore;
    };
    claude-code.enableMcpIntegration = true;
    opencode.enableMcpIntegration = true;
  };

  # Copy, not link: ~/Documents syncs to iCloud, and MuseScore runs the plugin from there.
  home.activation.museScoreMcpPlugin = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run mkdir -p "$HOME/Documents/MuseScore4/Plugins"
    run install -m 644 ${inputs.mcp-musescore}/musescore-mcp-websocket.qml \
      "$HOME/Documents/MuseScore4/Plugins/musescore-mcp-websocket.qml"
  '';
}
