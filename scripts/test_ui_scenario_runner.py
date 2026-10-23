import contextlib
import importlib.util
import io
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("runner", Path(__file__).with_name("run_ui_scenario.py"))
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


class RunnerSafetyTests(unittest.TestCase):
    def test_xctestrun_receives_language_without_losing_existing_environment(self):
        target = {"TestBundlePath": "__TESTROOT__/UI.xctest", "EnvironmentVariables": {"EXISTING": "keep"}}
        data = {"TestConfigurations": [{"TestTargets": [target]}]}
        self.assertEqual(runner.configure_test_run(data, "ru"), 1)
        self.assertEqual(target["EnvironmentVariables"], {"EXISTING": "keep", "UI_TEST_LANGUAGE": "ru"})

    def test_invalid_profile_does_not_execute_commands(self):
        with patch.object(runner.subprocess, "run") as execute:
            with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
                runner.main(["--language", "unsupported"])
            execute.assert_not_called()

    def test_build_failure_deletes_only_the_simulator_created_by_the_runner(self):
        owned = "11111111-1111-4111-8111-111111111111"
        calls = []

        def execute(command, **kwargs):
            calls.append(command)
            output = ""
            if command[:4] == ["xcrun", "simctl", "list", "devicetypes"]:
                output = json.dumps({"devicetypes": [{"name": "iPhone 17 Pro Max", "identifier": "device.type"}]})
            elif command[:4] == ["xcrun", "simctl", "list", "runtimes"]:
                output = json.dumps({"runtimes": [{"version": "26.5", "identifier": "runtime.id", "isAvailable": True}]})
            elif command[:3] == ["xcrun", "simctl", "create"]:
                output = owned + "\n"
            elif command[0] == "xcodebuild":
                raise subprocess.CalledProcessError(65, command)
            return subprocess.CompletedProcess(command, 0, stdout=output)

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "Example.xcodeproj").mkdir()
            with patch.object(runner.subprocess, "run", side_effect=execute), contextlib.redirect_stdout(io.StringIO()):
                self.assertNotEqual(runner.main([], root=root), 0)
            deletions = [command for command in calls if command[:3] == ["xcrun", "simctl", "delete"]]
            self.assertEqual(deletions, [["xcrun", "simctl", "delete", owned]])
            self.assertFalse(any("erase" in command or "all" in command for command in calls))
            report = next((root / "ui-test-results").glob("*/run.json"))
            self.assertEqual(json.loads(report.read_text())["status"], "failed")


if __name__ == "__main__":
    unittest.main()
