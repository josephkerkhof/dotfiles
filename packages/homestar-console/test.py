"""Checks for credential handling and runtime ownership boundaries, without a VM."""
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys
import tarfile
import tempfile
import unittest
from contextlib import redirect_stdout
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("console", sys.argv.pop(1))
console = importlib.util.module_from_spec(spec)
spec.loader.exec_module(console)


class ConsoleTests(unittest.TestCase):
    def test_logs_redact_runtime_credentials(self):
        with tempfile.TemporaryDirectory() as directory:
            output = io.StringIO()
            with patch.object(console, "STATE", Path(directory)), patch.object(console, "runtime_ready", return_value=True), \
                 patch.object(console, "container", return_value={"owned": True}), \
                 patch.object(console, "credentials", return_value={"user": "test-user", "password": "test-secret"}), \
                 patch.object(console, "docker", return_value=subprocess.CompletedProcess([], 0, b"test-user", b"test-secret")), \
                 patch.dict(console.os.environ), patch.object(sys, "argv", ["homestar-console", "logs"]), redirect_stdout(output):
                console.main()
            self.assertEqual(output.getvalue(), "[redacted][redacted]")

    def test_configure_refuses_noninteractive_credential_input(self):
        with patch.object(sys.stdin, "isatty", return_value=False), patch.object(console.getpass, "getpass") as prompt:
            with self.assertRaisesRegex(RuntimeError, "could echo"):
                console.configure()
            prompt.assert_not_called()

    def test_private_connection_rejects_credentials(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "connection.json"
            path.write_text(json.dumps({"host": "idrac.example.test", "port": 443, "password": "test"}))
            with patch.object(console, "CONNECTION", path):
                with self.assertRaisesRegex(RuntimeError, "never put credentials"):
                    console.connection()

    def test_legacy_local_metadata_is_not_authoritative(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "credentials.json"
            path.write_text(json.dumps({"user": "test", "password": "test", "host": "old.example.test", "port": 5900}))
            path.chmod(0o600)
            with patch.object(console, "CONFIG", path):
                self.assertEqual(console.credentials(), {"user": "test", "password": "test"})

    def test_foreign_context_rejected_before_docker_info(self):
        data = [{"Endpoints": {"docker": {"Host": "unix:///other/docker.sock"}}}]
        with patch.object(console, "docker", return_value=subprocess.CompletedProcess([], 0, json.dumps(data).encode())) as docker:
            with self.assertRaisesRegex(RuntimeError, "outside"):
                console.runtime_ready()
            self.assertEqual(docker.call_count, 1)

    def test_foreign_container_is_never_modified(self):
        with patch.object(console, "docker", return_value=subprocess.CompletedProcess([], 0, b'[{"Config":{"Labels":{}}}]')):
            with self.assertRaisesRegex(RuntimeError, "unowned"):
                console.container()

    def test_credentials_are_private_files_not_environment_or_arguments(self):
        config = {"host": "idrac.example.test", "port": 443, "user": "root", "password": "space $* secret"}
        with tempfile.TemporaryDirectory() as directory:
            script = Path(directory) / "startapp.sh"
            script.write_text("#!/bin/sh\nexit 0\n")
            with patch.object(console, "STARTAPP", script), patch.object(console, "docker") as docker:
                console.copy_secrets(console.validate(config))
                args, kwargs = docker.call_args
                self.assertNotIn(config["password"], str(args))
                with tarfile.open(fileobj=io.BytesIO(kwargs["input"])) as tar:
                    member = tar.getmember("run/secrets/idrac_password")
                    self.assertEqual(member.mode, 0o600)
                    self.assertEqual(member.uid, 1000)
                    self.assertEqual(tar.extractfile(member).read().decode(), config["password"])

    def test_world_readable_credentials_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "credentials.json"
            path.write_text("{}")
            path.chmod(0o644)
            with patch.object(console, "CONFIG", path):
                with self.assertRaisesRegex(RuntimeError, "private"):
                    console.credentials()

    def test_runtime_stop_refuses_any_running_workload(self):
        with tempfile.TemporaryDirectory() as directory:
            with patch.object(console, "STATE", Path(directory)), patch.object(console, "runtime_ready", return_value=True), \
                 patch.object(console, "docker", return_value=subprocess.CompletedProcess([], 0, b"some-container\n")), \
                 patch.object(console, "colima") as colima, patch.dict(console.os.environ), \
                 patch.object(sys, "argv", ["homestar-console", "runtime-stop"]):
                with self.assertRaisesRegex(RuntimeError, "running containers"):
                    console.main()
                colima.assert_not_called()


unittest.main()
