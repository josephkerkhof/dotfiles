{lib, ...}: let
  islandsDark = builtins.head (lib.importJSON ../../rex/themes.json);
  write = "$DRY_RUN_CMD /usr/bin/defaults write com.superlogical.rex";
in {
  xdg.configFile."rex/init.lua".source = ../../rex/init.lua;

  # Rex.app keeps its font and theme in user defaults, not in init.lua.
  home.activation.rexAppearance = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${write} Workspace.terminalFontName -string "Berkeley Mono"
    ${write} Workspace.terminalFontPointSize -float 16
    ${write} Workspace.customThemes -data "$(/usr/bin/xxd -p ${../../rex/themes.json} | /usr/bin/tr -d '\n')"
    ${write} Workspace.darkThemeID -string ${islandsDark.id}
  '';
}
