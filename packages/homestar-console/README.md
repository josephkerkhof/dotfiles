# Homestar iDRAC 6 console

`homestar-console` runs Dell's Linux Java viewer on the Mac in a dedicated
Colima Docker profile. It works independently of Ubuntu on Homestar. Keep
iDRAC NIC Selection on **Shared**; this configuration changes no server
networking or firmware.

Run commands from the dotfiles repository root (`cd ~/dotfiles`). Install through
`workstation apply` on each Mac. Before activation, the same
launcher is available with `nix run path:.#homestar-console -- <command>`.
Rosetta is declared in [the shared Rosetta module](../../modules/darwin/rosetta.nix): workstation activation
installs it through Apple's `softwareupdate --install-rosetta --agree-to-license`
when missing, then verifies Intel execution. This explicitly accepts Apple's
license. An already-working installation is left alone. Apple supplies the
macOS-compatible Rosetta version; its binary is not a version-pinned Nix package.
No separate manual installation or Mac Java installation is required.

## Spotlight launcher

The package also builds **Homestar Console.app**. Home Manager copies it to
`~/Applications/Home Manager Apps/Homestar Console.app` during `workstation apply`,
where Spotlight can index it. Search Spotlight for **Homestar Console** to start
the runtime/viewer and open the browser, or reopen an existing session.

On each Mac, first run `homestar-console configure` in a terminal to enter
credentials privately. The app uses the same local credentials and declarative
private connection metadata as the command. It invokes the pinned Nix command
directly, without depending on an interactive shell's PATH. Startup output goes
to `~/.local/share/homestar-console/app.log`; failures show a dialog with an
**Open Log** button. The app exits after opening the browser, leaving the
console running until `homestar-console stop` is used.

The AppleScript applet is compiled and ad-hoc signed during the Nix build using
macOS's built-in `osacompile` and `codesign`. Its stable bundle identifier is
`com.josephkerkhof.homestar-console`. Any macOS local-network permission prompt
applies to this app's launch context; terminal-based verification does not
verify the app's permission state.

## Command-line usage

The Nix package declares Python, Colima, Docker, OpenSSH, curl, coreutils, Perl,
and Bash; Colima's Nix dependency closure supplies Lima and its VM tooling.
The digest-pinned container supplies Java and the GUI stack. macOS supplies
Virtualization.framework and built-in commands such as `open` and `softwareupdate`.

```sh
homestar-console configure     # enter this Mac's username/password in hidden prompts
homestar-console               # start the VM/viewer as needed and open the browser
homestar-console status
homestar-console logs          # last 150 container log lines
homestar-console stop          # remove only the console container and credential copies
homestar-console runtime-stop  # stop the dedicated VM only if no containers are running
```

The browser listens at `http://127.0.0.1:5800`; raw VNC is disabled. Closing
the tab does not stop the console. `start --no-open` performs the same readiness
checks without opening a browser. Readiness means HTTP is responding and the
Java process is running; confirm a live server image and input in the viewer.
After editing credentials, use `stop` then `start` to recreate the session.

## Runtime and isolation

The pinned Home Manager module supports `isService`, `isActive`,
`setDockerHost`, and `mutableSettings`. The shared profile disables the first
three, merges its settings on activation, and never starts at login. It uses
an ARM64 Linux VM, Apple's `vz` virtualization driver, Rosetta, 2 CPUs, 2 GiB
RAM, and a 10 GiB data disk. The launcher disables host directory mounts and
SSH-agent forwarding. It verifies the guest architecture and Rosetta registration
and exercises the pinned Intel Java binary before creating a new session.

All Docker calls select `colima-homestar-console` explicitly and verify its
socket endpoint. Docker configuration is isolated under
`~/.local/share/homestar-console/docker`, leaving Docker Desktop and other
contexts unchanged. VM state stays under `~/.config/colima`; startup output is
saved to `~/.local/share/homestar-console/runtime.log`. `stop` leaves the VM
running, and `runtime-stop` refuses while any container in it is running.

## Credentials and private metadata

Each Mac supplies its own credentials through `homestar-console configure`,
run directly in a terminal. Both username and password prompts are hidden;
noninteractive input is refused. Credentials live only in
`~/.config/homestar-console/credentials.json` (0600), never in Git or Nix.
The launcher copies private secret files into the container via stdin, rather
than putting passwords in Docker environment variables or command arguments.
The Dell viewer itself receives the password in its Java arguments inside the
VM, so access to this Docker daemon remains trusted. No host directory or
Docker socket is mounted inside the viewer. The `logs` command redacts the
locally configured username and password before displaying container output.

The address and HTTPS port come from private-assets `homeModules.homestar`,
which declares `~/.config/homestar-console/connection.json` for both Macs.
This file contains only `host` and `port`. These are non-secret metadata;
credentials must never be added to that file or to the private flake.
Older credential files may still have address fields; the launcher ignores
those fields, and running `configure` replaces them with credentials only.
Hostnames are resolved on macOS and passed through `--add-host`, so private
macOS hosts-file entries also work inside the container.

To test a candidate before activation, use its generated private metadata:

```sh
connection_file=$(nix eval --raw path:.#darwinConfigurations.personal.config.home-manager.users.joseph.xdg.configFile.\"homestar-console/connection.json\".source)
HOMESTAR_CONSOLE_CONNECTION="$connection_file" nix run path:.#homestar-console
```

Use `work` in that attribute path when testing the work configuration. Build
the corresponding system first so the generated file exists in the store.
This override selects only non-secret metadata; credentials still come from
the local runtime file.

## Image and compatibility

The image is [DomiStyle/docker-idrac6](https://github.com/DomiStyle/docker-idrac6),
pinned to `sha256:93287ea08e0c843782829d8efc41668bc453c3df448b056849d0958da5789937`
(`linux/amd64`). Inspection of this exact image confirmed Zulu Java 8,
baseimage-gui 4.11.2, and removal of Java's security policy file for legacy
iDRAC compatibility. These relaxed settings stay inside the container.
The packaged [startapp.sh](startapp.sh) replaces upstream's startup script
to quote credentials, bound downloads, and fail on incomplete JARs. Dell's
viewer and native libraries are downloaded from the configured iDRAC firmware
each session; they are not part of the pinned image. HTTPS certificate checking
is disabled for those legacy downloads, as in upstream.

Virtual media is not configured or acceptance-tested: no ISO directories are
mounted. Console video, keyboard, and mouse are the primary workflow.
Viewer preferences are session-only: `/config` is a temporary filesystem,
so stopping sessions does not accumulate anonymous Docker configuration volumes.
Clipboard passthrough into Homestar is not configured: the browser's Clipboard
panel targets the container desktop, with Dell's KVM as another layer beyond it.
Normal keyboard input works; bulk text entry would need a separate mechanism
that sends text as keystrokes. SSH remains useful for text-heavy work when
Ubuntu is running.

## Verification

Verification on 2026-11-12: both Darwin systems build and the flake checks pass,
including nine launcher boundary/credential tests and ShellCheck. Live tests on
the available Apple Silicon Mac verified VZ, ARM64 Linux, Rosetta registration,
the pinned Intel Java 8 JVM, a synthetic Swing GUI with browser HTTP 200,
loopback-only binding, and launcher stop/cold-start operations. Launching directly
from Ghostty successfully downloaded Dell's resources and established an iDRAC
login and 1024×768 video session; Joseph confirmed live video, keyboard, and mouse
all work. Reopening with unrelated `DOCKER_HOST` and `DOCKER_CONTEXT` values also
passed. Agent-launched networking had reported `No route to host` despite a
valid macOS route and Safari connectivity; launching the VM from Ghostty resolved
that test limitation without changing Java or security settings. Full workstation
activation was not independently verified; no boot/reboot test or work-Mac runtime
test was performed.
The Spotlight app's compiled AppleScript, bundle metadata, and ad-hoc signature
have been verified in the Nix build. Joseph subsequently confirmed that the app
launches successfully.

## Troubleshooting

- If startup fails, use `status` and `logs`. A browser page alone does not prove
  a successful iDRAC login. Downloads need the iDRAC HTTPS port; console traffic
  needs TCP 5900 from the VM. The iDRAC address may differ from Ubuntu's address.
- A missing Rosetta installation is a hard error, with guidance to run
  `workstation apply` to install the declared prerequisite.
  The launcher does not silently fall back to QEMU.
- If Safari reaches iDRAC but agent-launched processes cannot, stop the dedicated
  VM with `stop` and `runtime-stop`, then launch from a normal terminal to test
  that process context. This is not evidence of a Java architecture mismatch.
- A busy local port 5800 causes startup to fail; stop its owner or adjust the
  launcher's port deliberately rather than exposing the viewer on the LAN.
- If a session fails, logs remain available until `stop` or the next `start`
  replaces its container. `stop` preserves the local credential file and VM disk.
- Update the digest only after reviewing the new image and testing Java, browser
  transport, and a real iDRAC session. Neither launch nor activation follows
  `latest` or updates the image pin.
