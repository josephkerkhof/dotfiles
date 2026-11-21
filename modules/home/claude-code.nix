{
  lib,
  pkgs,
  ...
}: let
  hook = name: {
    type = "command";
    command = "$HOME/.claude/hooks/${name}";
  };
in {
  programs.claude-code = {
    enable = true;
    context = ../../agents/AGENTS.md;
    skills = ../../agents/skills;

    hooks = {
      "block-commit-attribution.sh" = ../../claude/hooks/block-commit-attribution.sh;
      "block-destructive.sh" = ../../claude/hooks/block-destructive.sh;
      "block-prose-comments.py" = ../../claude/hooks/block-prose-comments.py;
    };

    settings = {
      permissions.defaultMode = "auto";

      # These skills are installed only on the work Mac and stay disabled.
      skillOverrides = lib.genAttrs [
        "deep-agents-core"
        "deep-agents-memory"
        "deep-agents-orchestration"
        "framework-selection"
        "langchain-dependencies"
        "langchain-fundamentals"
        "langchain-middleware"
        "langchain-rag"
        "langgraph-fundamentals"
        "langgraph-human-in-the-loop"
        "langgraph-persistence"
      ] (_: "off");

      hooks.PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            (hook "block-destructive.sh")
            (hook "block-commit-attribution.sh")
          ];
        }
        {
          matcher = "Write|Edit|MultiEdit";
          hooks = [
            {
              type = "command";
              command = "${lib.getExe pkgs.python3} $HOME/.claude/hooks/block-prose-comments.py";
            }
          ];
        }
      ];

      # Same hook that `rex skill setup --agent claude` writes.
      hooks.SessionStart = [
        {
          hooks = [
            {
              type = "command";
              command = "/bin/sh -c 'rex __internal session-start --agent claude --feature-session-naming=false 2>/dev/null || true'";
              timeout = 5;
            }
          ];
        }
      ];

      enabledPlugins = {
        "laravel@laravel" = true;
        "frontend-design@claude-plugins-official" = false;
        "warp@claude-code-warp" = true;
        "pyright-lsp@claude-plugins-official" = false;
        "skill-creator@claude-plugins-official" = false;
        "php-lsp@claude-plugins-official" = true;
        "be-terse@be-terse" = true;
        "swift-lsp@claude-plugins-official" = true;
      };

      extraKnownMarketplaces =
        lib.mapAttrs (_: repo: {
          source = {
            source = "github";
            inherit repo;
          };
        }) {
          laravel = "laravel/agent-skills";
          temporal-marketplace = "temporalio/agent-skills";
          claude-code-warp = "warpdotdev/claude-code-warp";
          be-terse = "bigskysoftware/be-terse";
        };

      effortLevel = "high";
      modelSettings = lib.genAttrs [
        "claude-opus-5"
        "claude-fable-5"
        "claude-opus-5-5"
      ] (_: {effortLevel = "xhigh";});

      feedbackDrafts = "off";
      tui = "fullscreen";
      verbose = false;
      voiceEnabled = true;
      switchModelsOnFlag = false;
      agentPushNotifEnabled = true;
      skipAutoPermissionPrompt = true;
      skipDangerousModePermissionPrompt = true;
    };
  };
}
