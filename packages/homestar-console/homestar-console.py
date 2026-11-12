#!@python@
"""Local-only iDRAC viewer; credentials never enter Nix or Docker's environment."""

import argparse
import fcntl
import getpass
import io
import ipaddress
import json
import os
from pathlib import Path
import re
import socket
import subprocess
import sys
import tarfile
import tempfile
import time
import urllib.error
import urllib.request

IMAGE = "docker.io/domistyle/idrac6@sha256:93287ea08e0c843782829d8efc41668bc453c3df448b056849d0958da5789937"
PROFILE = "homestar-console"
CONTEXT = "colima-" + PROFILE
LABEL = "io.github.josephkerkhof.homestar-console"
URL = "http://127.0.0.1:5800"
HOME = Path.home()
STATE = HOME / ".local/share/homestar-console"
CONFIG = HOME / ".config/homestar-console/credentials.json"
CONNECTION = Path(os.environ.get("HOMESTAR_CONSOLE_CONNECTION", HOME / ".config/homestar-console/connection.json"))
COLIMA_HOME = HOME / ".config/colima"
SETTINGS = Path("@settings@")
STARTAPP = Path("@startapp@")


def fail(message):
    raise RuntimeError(message)


def run(args, *, capture=False, check=True, **kwargs):
    if capture:
        kwargs.update(stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return subprocess.run(args, check=check, **kwargs)


def docker(*args, **kwargs):
    return run(["docker", "--context", CONTEXT, *args], **kwargs)


def colima(*args, **kwargs):
    return run(["colima", "--profile", PROFILE, *args], **kwargs)


def validate(config):
    if set(config) != {"host", "port", "user", "password"}:
        fail("Credentials must contain host, port, user, and password.")
    for key in ("host", "user", "password"):
        value = config[key]
        if not isinstance(value, str) or not value or any(ord(c) < 32 for c in value):
            fail(f"{key} must be nonempty with no control characters.")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9.-]*", config["host"]):
        fail("Use an IPv4 address or DNS hostname, without a URL or port.")
    if type(config["port"]) is not int or not 1 <= config["port"] <= 65535:
        fail("port must be an integer from 1 to 65535.")
    return config


def configure():
    if not sys.stdin.isatty() or not sys.stderr.isatty():
        fail("Run configure directly in a terminal; refusing a prompt that could echo credentials.")
    config = validate_credentials({"user": getpass.getpass("iDRAC username (hidden): "),
                                   "password": getpass.getpass("iDRAC password (hidden): ")})
    CONFIG.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd, name = tempfile.mkstemp(dir=CONFIG.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            json.dump(config, stream)
            stream.write("\n")
        os.replace(name, CONFIG)
    finally:
        Path(name).unlink(missing_ok=True)
    print(f"Saved locally with mode 0600: {CONFIG}")


def credentials():
    if not CONFIG.exists():
        fail("Run 'homestar-console configure' to enter credentials locally first.")
    stat = CONFIG.stat()
    if stat.st_uid != os.getuid() or stat.st_mode & 0o077:
        fail(f"Credentials must be owned by you and private: chmod 600 {CONFIG}")
    data = json.loads(CONFIG.read_text())
    # Older local files may contain connection fields. They are not authoritative;
    # configure rewrites the file with credentials only on the next local setup.
    return validate_credentials({key: data.get(key) for key in ("user", "password")})


def validate_credentials(data):
    for key in ("user", "password"):
        value = data.get(key)
        if not isinstance(value, str) or not value or any(ord(c) < 32 for c in value):
            fail(f"{key} must be nonempty with no control characters.")
    return data


def connection():
    if not CONNECTION.is_file():
        fail("Missing private-assets connection.json. Activate the workstation configuration, "
             "or set HOMESTAR_CONSOLE_CONNECTION to its generated non-secret connection file.")
    data = json.loads(CONNECTION.read_text())
    if set(data) != {"host", "port"}:
        fail("Private connection.json must contain only host and port; never put credentials in Nix.")
    validate({**data, "user": "validation", "password": "validation"})
    return data


def runtime_ready():
    # An explicit context is insufficient if its endpoint has been repointed.
    result = docker("context", "inspect", CONTEXT, capture=True, check=False)
    if result.returncode:
        return False
    endpoint = json.loads(result.stdout)[0]["Endpoints"]["docker"]["Host"]
    if endpoint != f"unix://{COLIMA_HOME}/{PROFILE}/docker.sock":
        fail("Refusing a Docker context that points outside the dedicated Colima profile.")
    return docker("info", capture=True, check=False).returncode == 0


def container():
    result = docker("container", "inspect", PROFILE, capture=True, check=False)
    if result.returncode:
        return None
    data = json.loads(result.stdout)[0]
    if data["Config"].get("Labels", {}).get(LABEL) != "true":
        fail("An unowned container has the console's name; refusing to modify it.")
    return data


def start_runtime():
    if run(["/usr/bin/arch", "-x86_64", "/usr/bin/true"], capture=True, check=False).returncode:
        fail("Rosetta is required. Run 'workstation apply' to install the declared system prerequisites, then retry.")
    if not runtime_ready():
        settings = json.loads(SETTINGS.read_text())
        # Explicit flags also support nix run before Home Manager activation.
        args = ["start", "--activate=false", "--save-config=false", "--template=false",
                "--ssh-config=false", "--ssh-agent=false", "--mount", "none", "--vz-rosetta",
                "--kubernetes=false", "--network-address=false"]
        for flag, key in [("arch", "arch"), ("vm-type", "vmType"), ("runtime", "runtime"),
                          ("cpu", "cpu"), ("memory", "memory"), ("disk", "disk"),
                          ("mount-type", "mountType")]:
            args.extend(["--" + flag, str(settings[key])])
        log = STATE / "runtime.log"
        print(f"Starting dedicated Colima VM; startup log: {log}", flush=True)
        with log.open("w") as stream:
            result = run(
                ["colima", "--profile", PROFILE, *args], stdout=stream, stderr=subprocess.STDOUT,
                check=False)
        if result.returncode:
            fail(f"Colima startup failed. See {log}.")
        # An already-running profile may have been started outside this wrapper.
        if docker("context", "inspect", CONTEXT, capture=True, check=False).returncode:
            docker("context", "create", CONTEXT, "--docker",
                   f"host=unix://{COLIMA_HOME}/{PROFILE}/docker.sock", capture=True)
    if not runtime_ready():
        fail("Dedicated Docker context is unavailable; see homestar-console status.")
    # Verify the running VM, not just the requested configuration.
    colima("ssh", "--", "sh", "-c",
           "test \"$(uname -m)\" = aarch64 && "
           "grep -q '^enabled$' /proc/sys/fs/binfmt_misc/rosetta && "
           "grep -q '^interpreter /mnt/lima-rosetta/rosetta$' /proc/sys/fs/binfmt_misc/rosetta")


def copy_secrets(config):
    archive = io.BytesIO()
    with tarfile.open(fileobj=archive, mode="w") as tar:
        directory = tarfile.TarInfo("run/secrets")
        directory.type = tarfile.DIRTYPE
        directory.mode = 0o700
        directory.uid = directory.gid = 1000
        tar.addfile(directory)
        for key, value in config.items():
            content = str(value).encode()
            item = tarfile.TarInfo("run/secrets/idrac_" + key)
            item.size = len(content)
            item.mode = 0o600
            item.uid = item.gid = 1000
            tar.addfile(item, io.BytesIO(content))
        script = STARTAPP.read_bytes()
        item = tarfile.TarInfo("startapp.sh")
        item.size = len(script)
        item.mode = 0o755
        tar.addfile(item, io.BytesIO(script))
    docker("cp", "-a", "-", PROFILE + ":/", input=archive.getvalue(), capture=True)


def start(no_open):
    config = {**connection(), **credentials()}
    # Resolve on macOS: private /etc/hosts mappings need not exist in Linux.
    address = socket.gethostbyname(config["host"])
    ipaddress.IPv4Address(address)
    start_runtime()
    existing = container()
    if existing and existing["State"]["Running"]:
        if existing["Config"]["Image"] != IMAGE:
            fail("Console uses an older image; run stop, then start to upgrade.")
    else:
        if existing:
            docker("rm", PROFILE, capture=True)
        docker("pull", "--platform", "linux/amd64", IMAGE)
        # Exercise the chosen Intel JVM through Rosetta before launching the UI.
        docker("run", "--rm", "--platform", "linux/amd64", "--network", "none",
               "--entrypoint", "java", IMAGE, "-version")
        docker("create", "--name", PROFILE, "--label", LABEL + "=true",
               "--platform", "linux/amd64", "--restart", "no",
               "--tmpfs", "/config:rw,nosuid,nodev,size=64m",
               "--publish", "127.0.0.1:5800:5800", "--add-host", config["host"] + ":" + address,
               "--env", "VNC_LISTENING_PORT=-1", "--env", "WEB_AUDIO=0",
               "--log-opt", "max-size=5m", "--log-opt", "max-file=2", IMAGE, capture=True)
        copy_secrets(config)
        docker("start", PROFILE, capture=True)
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    deadline = time.monotonic() + 120
    while time.monotonic() < deadline:
        data = container()
        if not data or not data["State"]["Running"]:
            fail("Console exited. Run 'homestar-console logs' for diagnostics.")
        try:
            with opener.open(URL, timeout=2) as response:
                processes = docker("top", PROFILE, "-eo", "pid,comm", capture=True).stdout.splitlines()
                if response.status == 200 and any(line.split()[-1:] == [b"java"] for line in processes):
                    print(f"Browser interface ready: {URL}\nConfirm video, keyboard, and mouse in the viewer.")
                    if not no_open:
                        run(["/usr/bin/open", URL])
                    return
        except (OSError, urllib.error.URLError):
            pass
        time.sleep(2)
    fail("Browser interface and Java viewer did not become ready in 120s. Run 'homestar-console logs'.")


def main():
    parser = argparse.ArgumentParser(prog="homestar-console", description=__doc__)
    parser.add_argument("command", nargs="?", default="start",
                        choices=["start", "configure", "stop", "runtime-stop", "status", "logs"])
    parser.add_argument("--no-open", action="store_true", help="start without opening a browser")
    args = parser.parse_args()
    os.umask(0o077)
    if args.command == "configure":
        configure()
        return
    STATE.mkdir(parents=True, exist_ok=True, mode=0o700)
    # Isolate contexts and registry state as well as the VM. Never context-use.
    for key in ("DOCKER_HOST", "DOCKER_CONTEXT", "DOCKER_TLS_VERIFY", "DOCKER_CERT_PATH", "LIMA_HOME"):
        os.environ.pop(key, None)
    os.environ["DOCKER_CONFIG"] = str(STATE / "docker")
    os.environ["COLIMA_HOME"] = str(COLIMA_HOME)
    with (STATE / "command.lock").open("w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            fail("Another homestar-console operation is running.")
        if args.command == "start":
            start(args.no_open)
        elif args.command == "status":
            colima("status", check=False)
            if runtime_ready():
                data = container()
                print("Console: " + (data["State"]["Status"] if data else "absent"))
            print(f"Startup log: {STATE / 'runtime.log'}")
        elif not runtime_ready():
            print("Dedicated runtime is stopped or unavailable; nothing changed.")
        elif args.command == "logs":
            if container():
                output = docker("logs", "--tail", "150", PROFILE, capture=True)
                message = (output.stdout + output.stderr).decode(errors="replace")
                # Never forward local credential values into logs or an agent transcript.
                for value in sorted(credentials().values(), key=len, reverse=True):
                    message = message.replace(value, "[redacted]")
                print(message, end="")
            else:
                print("No console container. See status for the VM startup log.")
        elif args.command == "stop":
            if container():
                docker("stop", "--time", "10", PROFILE, capture=True)
                docker("rm", PROFILE, capture=True)
            print("Console removed, including its credential copies. VM remains available.")
        elif args.command == "runtime-stop":
            active = docker("ps", "-q", capture=True).stdout.strip()
            if active:
                fail("VM has running containers. Stop the console (and any other workloads) first.")
            colima("stop")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, ValueError, OSError, subprocess.CalledProcessError) as error:
        # Never print subprocess output or credential values implicitly.
        print(f"homestar-console: {error}", file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        sys.exit(130)
