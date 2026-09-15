{lib, ...}: {
  home.activation.createScreenshotDirectory = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p "$HOME/Pictures/Screenshots"
  '';
}
