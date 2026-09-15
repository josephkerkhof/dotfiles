_: {
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    package = null;

    settings = {
      font-family = "Berkeley Mono";
      font-style = "Regular";
      font-style-bold = "Bold";
      font-style-italic = "Oblique";
      font-style-bold-italic = "Bold Oblique";
      font-size = 16;
      theme = "islands-dark";
    };

    themes.islands-dark = {
      background = "#1E1F22";
      foreground = "#BCBEC4";
      cursor-color = "#BCBEC4";
      selection-background = "#214283";
      selection-foreground = "#BCBEC4";
      palette = [
        "0=#000000"
        "1=#F0524F"
        "2=#5C962C"
        "3=#A68A0D"
        "4=#3993D4"
        "5=#A771BF"
        "6=#00A3A3"
        "7=#808080"
        "8=#595959"
        "9=#FF4050"
        "10=#4FC414"
        "11=#E5BF00"
        "12=#1FB0FF"
        "13=#ED7EED"
        "14=#00E5E5"
        "15=#FFFFFF"
      ];
    };
  };
}
