{pkgs}:
pkgs.writeShellApplication {
  name = "mov2web";
  runtimeInputs = [pkgs.ffmpeg];
  text = builtins.readFile ./mov2web.sh;
  meta.description = "Convert MOV screen recordings to web-optimized MP4";
}
