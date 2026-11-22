{
  pkgs,
  src,
}:
pkgs.writeShellApplication {
  name = "mcp-musescore";
  runtimeInputs = [pkgs.uv];
  runtimeEnv = {
    UV_PYTHON = pkgs.lib.getExe pkgs.python313;
    UV_PYTHON_DOWNLOADS = "never";
    FASTMCP_SHOW_SERVER_BANNER = "false";
    FASTMCP_CHECK_FOR_UPDATES = "off";
  };
  # uv installs the versions pinned by upstream uv.lock into a mutable cache venv.
  text = ''
    export UV_PROJECT_ENVIRONMENT="''${XDG_CACHE_HOME:-$HOME/.cache}/mcp-musescore/venv"
    exec uv run --quiet --frozen --no-dev --project "${src}" -- python "${src}/server.py" "$@"
  '';
  meta.description = "MuseScore MCP server from ghchen99/mcp-musescore";
}
