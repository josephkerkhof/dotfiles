#compdef workstation

_workstation() {
  local -a commands

  commands=(
    'test:check the flake and build a candidate'
    'activate:activate an existing candidate'
    'apply:test and then activate a candidate'
    'status:compare candidate, selected, and running systems'
    'list:list declared workstations and hostnames'
    'gc:preview and optionally collect Nix store garbage'
    'help:show general or command-specific help'
  )

  _arguments -s -S \
    '--workstation=[target a declared Darwin configuration]:workstation name' \
    '--flake=[use another workstation checkout]:flake directory:_directories' \
    '--yes[skip an activation or garbage-collection confirmation]' \
    '(-h --help)'{-h,--help}'[show help]' \
    '1:command:->command' \
    '*::argument:->argument'

  case "$state" in
    command)
      _describe 'command' commands
      ;;
    argument)
      if [[ ${words[2]} == help ]]; then
        _describe 'command' commands
      fi
      ;;
  esac
}

_workstation "$@"
