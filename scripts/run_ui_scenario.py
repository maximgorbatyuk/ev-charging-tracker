#!/usr/bin/env python3
"""Run one UI scenario on a simulator owned by this invocation."""

import argparse
import datetime
import fcntl
import json
import plistlib
import subprocess
import sys
import uuid
from pathlib import Path

TEXT_SIZES = (
    "extra-small", "small", "medium", "large", "extra-large", "extra-extra-large",
    "extra-extra-extra-large", "accessibility-medium", "accessibility-large",
    "accessibility-extra-large", "accessibility-extra-extra-large",
    "accessibility-extra-extra-extra-large",
)


def configure_test_run(data, language):
    count = 0
    if isinstance(data, dict):
        if "TestBundlePath" in data:
            data.setdefault("EnvironmentVariables", {})["UI_TEST_LANGUAGE"] = language
            return 1
        for value in data.values():
            count += configure_test_run(value, language)
    elif isinstance(data, list):
        for value in data:
            count += configure_test_run(value, language)
    return count


def command(arguments, log=None, check=True, timeout=120):
    options = {"text": True, "check": check, "stderr": subprocess.STDOUT, "timeout": timeout}
    if log is None:
        options["stdout"] = subprocess.PIPE
        return subprocess.run(arguments, **options).stdout or ""
    with log.open("w") as stream:
        stream.write("Command: " + json.dumps(arguments) + "\n")
        stream.flush()
        subprocess.run(arguments, stdout=stream, **options)
    return ""


def main(argv=None, root=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scenario", choices=["create-edit-cancel"], default="create-edit-cancel")
    parser.add_argument("--device", default="iPhone 17 Pro Max")
    parser.add_argument("--runtime", default="26.5")
    parser.add_argument("--language", choices=["en", "ru"], default="en")
    parser.add_argument("--appearance", choices=["light", "dark"], default="light")
    parser.add_argument("--text-size", choices=TEXT_SIZES, default="large")
    parser.add_argument("--dry-run", action="store_true", help="Print the profile without creating a device")
    args = parser.parse_args(argv)
    root = Path(root) if root is not None else Path(__file__).resolve().parent.parent
    projects = list(root.glob("*.xcodeproj"))
    if len(projects) != 1:
        parser.error("Expected exactly one .xcodeproj in the repository root")
    project = projects[0]
    profile = vars(args).copy()
    profile["project"] = project.name
    profile["scheme"] = project.stem + "UI"
    if args.dry_run:
        print(json.dumps(profile, indent=2))
        return 0

    cache = root / ".ui-test-cache"
    cache.mkdir(exist_ok=True)
    with (cache / "runner.lock").open("w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print("Another UI scenario is running for this repository", file=sys.stderr)
            return 1
        return run_profile(root, project, args, profile, cache)


def run_profile(root, project, args, profile, cache):
    run_id = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ-") + uuid.uuid4().hex[:8]
    output = root / "ui-test-results" / run_id
    output.mkdir(parents=True)
    report = {"profile": profile, "status": "failed", "simulator": None}
    created = None
    patched = None
    exit_code = 1
    print("Results: " + str(output), flush=True)
    try:
        types = json.loads(command(["xcrun", "simctl", "list", "devicetypes", "--json"]))["devicetypes"]
        runtimes = json.loads(command(["xcrun", "simctl", "list", "runtimes", "--json"]))["runtimes"]
        device_type = next((item for item in types if item["name"] == args.device), None)
        runtime = next((item for item in runtimes if item["version"] == args.runtime and item.get("isAvailable")), None)
        if device_type is None or runtime is None:
            raise ValueError("Requested device type or installed runtime was not found")

        raw_id = command(["xcrun", "simctl", "create", "UI Scenario " + run_id, device_type["identifier"], runtime["identifier"]]).strip()
        created = str(uuid.UUID(raw_id)).upper()
        report["simulator"] = created
        print("Created isolated simulator: " + created, flush=True)
        command(["xcrun", "simctl", "boot", created])
        command(["xcrun", "simctl", "bootstatus", created, "-b"], timeout=300)
        command(["xcrun", "simctl", "ui", created, "appearance", args.appearance])
        command(["xcrun", "simctl", "ui", created, "content_size", args.text_size])

        destination = "platform=iOS Simulator,id=" + created
        derived = cache / "DerivedData"
        print("Building the UI-only scheme", flush=True)
        command(["xcodebuild", "-project", str(project), "-scheme", profile["scheme"], "-configuration", "Debug", "-destination", destination, "-derivedDataPath", str(derived), "build-for-testing"], output / "build.log", timeout=1800)
        candidates = [path for path in (derived / "Build/Products").glob("*.xctestrun") if not path.name.startswith("Profile-")]
        if len(candidates) != 1:
            raise ValueError("Expected exactly one generated xctestrun file")
        data = plistlib.loads(candidates[0].read_bytes())
        if configure_test_run(data, args.language) != 1:
            raise ValueError("The UI-only scheme must contain exactly one test target")
        patched = candidates[0].with_name("Profile-" + run_id + ".xctestrun")
        patched.write_bytes(plistlib.dumps(data))

        result_bundle = output / "Results.xcresult"
        print("Running fixed scenario: " + args.scenario, flush=True)
        command(["xcodebuild", "test-without-building", "-xctestrun", str(patched), "-destination", destination, "-parallel-testing-enabled", "NO", "-maximum-concurrent-test-simulator-destinations", "1", "-only-testing:" + project.stem + "ScenarioUITests/ScenarioTests/testCreateEditCancel", "-resultBundlePath", str(result_bundle)], output / "test.log", timeout=900)
        summary = json.loads(command(["xcrun", "xcresulttool", "get", "test-results", "summary", "--path", str(result_bundle), "--format", "json"]))
        (output / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
        if summary.get("result") != "Passed" or summary.get("passedTests") != 1 or summary.get("skippedTests") != 0 or summary.get("failedTests") != 0:
            raise ValueError("Expected one passed UI test with no skipped tests")
        report["status"] = "passed"
        exit_code = 0
    except (OSError, ValueError, subprocess.SubprocessError, KeyboardInterrupt) as error:
        report["error"] = str(error)
        print("Scenario failed: " + str(error), flush=True)
    finally:
        result_bundle = output / "Results.xcresult"
        if result_bundle.exists():
            try:
                command(["xcrun", "xcresulttool", "export", "attachments", "--path", str(result_bundle), "--output-path", str(output / "attachments")], output / "export.log")
            except (OSError, subprocess.SubprocessError) as error:
                report["artifactError"] = str(error)
                report["status"] = "failed"
                exit_code = 1
        if patched is not None:
            try:
                patched.unlink(missing_ok=True)
            except OSError as error:
                report["profileCleanupError"] = str(error)
                report["status"] = "failed"
                exit_code = 1
        if created is not None:
            try:
                command(["xcrun", "simctl", "shutdown", created], check=False)
            except (OSError, subprocess.SubprocessError) as error:
                report["shutdownError"] = str(error)
            try:
                command(["xcrun", "simctl", "delete", created])
                report["simulatorDeleted"] = True
            except (OSError, subprocess.SubprocessError) as error:
                report["cleanupError"] = str(error)
                report["status"] = "failed"
                exit_code = 1
        (output / "run.json").write_text(json.dumps(report, indent=2) + "\n")
    print("Result: " + report["status"] + " — " + str(output), flush=True)
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
