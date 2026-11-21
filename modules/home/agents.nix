{lib, ...}: let
  skills = ../../agents/skills;
in {
  xdg.configFile.agents.source = ../../agents;

  # Codex and OpenCode read ~/.agents/skills. Per-file links leave the folder writable.
  home.file = lib.mapAttrs' (name: _:
    lib.nameValuePair ".agents/skills/${name}" {
      source = skills + "/${name}";
      recursive = true;
    })
  (builtins.readDir skills);
}
