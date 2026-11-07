#!/usr/bin/env python3
"""Reproducible statement-line coverage for Project Echo.

The runner copies the project to a temporary directory, instruments every
runtime GDScript file, runs the full GdUnit4 suite against the copy and writes
JSON, LCOV, text and HTML reports under ``reports/coverage/``.

The working tree is never modified.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_PROJECT = SCRIPT_DIR.parents[2]
sys.path.insert(0, str(SCRIPT_DIR))

import instrumenter  # noqa: E402
import report as coverage_report  # noqa: E402

ANSI = re.compile(r"\x1b\[[0-9;]*m")
COPY_IGNORE = shutil.ignore_patterns(
    ".git",
    ".godot",
    ".empryo",
    "reports",
    "__pycache__",
    ".DS_Store",
    "GdUnitRunner.cfg",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--godot",
        default=os.environ.get("GODOT_BIN", "godot"),
        help="Godot binary (default: GODOT_BIN or godot)",
    )
    parser.add_argument(
        "--project",
        type=Path,
        default=DEFAULT_PROJECT,
        help="Project root (default: repository root)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Report directory (default: reports/coverage)",
    )
    parser.add_argument(
        "--baseline",
        type=Path,
        default=None,
        help="Baseline JSON used by the gate (default: reports/coverage/baseline.json)",
    )
    parser.add_argument(
        "--write-baseline",
        action="store_true",
        help="Write the current report as the new gate baseline",
    )
    parser.add_argument(
        "--enforce-gate",
        action="store_true",
        help="Exit non-zero when the gate fails (default: informational)",
    )
    parser.add_argument(
        "--tests",
        default="res://test",
        help="GdUnit4 test path (default: res://test)",
    )
    parser.add_argument(
        "--keep-temp",
        action="store_true",
        help="Keep the temporary instrumented project",
    )
    parser.add_argument(
        "--skip-import",
        action="store_true",
        help="Skip the import step (only for repeated local runs with --keep-temp)",
    )
    return parser.parse_args()


def fail(message: str):
    print(f"coverage: {message}", file=sys.stderr)
    raise SystemExit(2)


def godot_version(godot: str) -> str:
    result = subprocess.run(
        [godot, "--version"], capture_output=True, text=True, check=False
    )
    if result.returncode != 0:
        fail(f"cannot run {godot}: {result.stderr.strip() or result.stdout.strip()}")
    return result.stdout.strip().splitlines()[0] if result.stdout else "unknown"


def source_files(project: Path) -> list[Path]:
    files: list[Path] = []
    for directory in ("scripts", "autoload"):
        root = project / directory
        if not root.exists():
            continue
        files.extend(
            path.relative_to(project) for path in root.rglob("*.gd") if path.is_file()
        )
    return sorted(files)


def copy_project(project: Path, destination: Path) -> None:
    shutil.copytree(project, destination, ignore=COPY_IGNORE)


def instrument_project(project: Path, files: list[Path]) -> dict[str, list[int]]:
    statements: dict[str, list[int]] = {}
    for relative in files:
        res_path = relative.as_posix()
        lines = instrumenter.instrument_file(project / relative, res_path)
        statements[res_path] = lines
    return statements


def add_recorder_autoload(project_file: Path) -> None:
    text = project_file.read_text(encoding="utf-8")
    if "CoverageRecorder=" in text:
        return
    marker = "[autoload]\n"
    if marker not in text:
        text = text.rstrip("\n") + "\n\n[autoload]\n"
    recorder = 'CoverageRecorder="*res://test/tools/coverage/coverage_recorder.gd"\n'
    text = text.replace(marker, marker + recorder, 1)
    project_file.write_text(text, encoding="utf-8")


def import_project(godot: str, project: Path) -> None:
    print("coverage: importing temporary project")
    result = subprocess.run(
        [godot, "--headless", "--path", str(project), "--import"],
        capture_output=True,
        text=True,
        check=False,
        timeout=900,
    )
    if result.returncode != 0:
        print(ANSI.sub("", result.stdout[-4000:]))
        print(ANSI.sub("", result.stderr[-4000:]))
        fail("temporary project import failed")


def run_tests(godot: str, project: Path, tests: str, hits_file: Path) -> tuple[int, str]:
    command = [
        godot,
        "--headless",
        "--path",
        str(project),
        "-s",
        "-d",
        "--remote-debug",
        "tcp://127.0.0.1:0",
        "res://addons/gdUnit4/bin/GdUnitCmdTool.gd",
        "-a",
        tests,
        "--ignoreHeadlessMode",
    ]
    environment = os.environ.copy()
    environment["ECHO_COVERAGE_OUTPUT"] = str(hits_file)

    started = time.monotonic()
    result = subprocess.run(
        command,
        capture_output=True,
        text=True,
        check=False,
        env=environment,
        timeout=3600,
    )
    duration = round(time.monotonic() - started, 2)
    output = ANSI.sub("", result.stdout + ("\n" + result.stderr if result.stderr else ""))
    print(f"coverage: tests finished in {duration:.1f}s with exit code {result.returncode}")
    return result.returncode, output


def parse_test_summary(output: str, exit_code: int, duration: float) -> dict:
    summary = {
        "exit_code": exit_code,
        "duration_seconds": round(duration, 1),
        "cases": None,
        "suites": None,
        "failures": None,
        "errors": None,
        "skipped": None,
        "orphans": None,
    }
    overall = re.search(
        r"Overall Summary:\s*(\d+) test cases \|\s*(\d+) errors \|\s*(\d+) failures \|"
        r"\s*(\d+) flaky \|\s*(\d+) skipped \|\s*(\d+) orphans",
        output,
    )
    if overall:
        cases, errors, failures, _flaky, skipped, orphans = overall.groups()
        summary.update(
            {
                "cases": int(cases),
                "errors": int(errors),
                "failures": int(failures),
                "skipped": int(skipped),
                "orphans": int(orphans),
            }
        )

    suites = re.search(r"Executed test suites:\s*\((\d+)/(\d+)\)", output)
    if suites:
        summary["suites"] = int(suites.group(1))
        summary["suite_total"] = int(suites.group(2))
    return summary


def read_hits(path: Path) -> dict[str, list[int]]:
    if not path.exists():
        fail(f"coverage recorder did not write {path}")
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        fail(f"cannot parse coverage recorder output: {error}")
    return payload.get("hits", {})


def write_baseline(path: Path, report: dict) -> None:
    baseline = {key: value for key, value in report.items() if key != "gate"}
    coverage_report.write_json(path, baseline)


def main() -> int:
    args = parse_args()
    project = args.project.resolve()
    output = (args.output or project / "reports" / "coverage").resolve()
    baseline_path = (args.baseline or output / "baseline.json").resolve()

    if not (project / "project.godot").exists():
        fail(f"{project} is not a Godot project")

    version = godot_version(args.godot)
    files = source_files(project)
    if not files:
        fail("no source files found")

    temp_root = Path(tempfile.mkdtemp(prefix="echo-coverage-"))
    try:
        print(f"coverage: copying project to {temp_root}")
        copy_project(project, temp_root / "project")
        instrumented_root = temp_root / "project"

        statements = instrument_project(instrumented_root, files)
        instrumentable = sum(1 for lines in statements.values() if lines)
        total_statements = sum(len(lines) for lines in statements.values())
        print(
            f"coverage: instrumented {total_statements} statements in "
            f"{instrumentable} of {len(files)} files"
        )

        add_recorder_autoload(instrumented_root / "project.godot")

        if not args.skip_import:
            import_project(args.godot, instrumented_root)

        hits_file = temp_root / "coverage_hits.json"
        started = time.monotonic()
        exit_code, output_text = run_tests(args.godot, instrumented_root, args.tests, hits_file)
        duration = time.monotonic() - started

        hits = read_hits(hits_file)
        summary = parse_test_summary(output_text, exit_code, duration)
        current = coverage_report.build_report(statements, hits, summary, version)

        baseline = None
        if baseline_path.exists():
            try:
                baseline = json.loads(baseline_path.read_text(encoding="utf-8"))
            except json.JSONDecodeError:
                print(f"coverage: ignoring unreadable baseline {baseline_path}")
        current["gate"] = coverage_report.evaluate_gate(current, baseline)

        output.mkdir(parents=True, exist_ok=True)
        coverage_report.write_json(output / "coverage.json", current)
        coverage_report.write_lcov(output / "lcov.info", current)
        coverage_report.write_text(output / "coverage.txt", current)
        coverage_report.write_html(output / "index.html", current)
        if args.write_baseline:
            write_baseline(baseline_path, current)
            print(f"coverage: wrote baseline {baseline_path}")

        totals = current["totals"]
        target = current["target_totals"]
        print(
            f"coverage: target {target['covered']} / {target['statements']} statements "
            f"({target['percent']}%), all files {totals['covered']} / "
            f"{totals['statements']} ({totals['percent']}%), "
            f"{totals['files_with_hits']} / {totals['instrumentable_files']} files executed"
        )
        print(f"coverage: {output / 'index.html'}")
        print(f"coverage: {output / 'coverage.txt'}")

        if exit_code != 0 or summary["failures"] or summary["errors"]:
            print("coverage: test suite failed", file=sys.stderr)
            print(output_text[-6000:])
            return 1

        gate = current["gate"]
        if gate["enforced"] and not gate["passed"]:
            for failure in gate["failures"]:
                print(f"coverage gate: {failure['message']}", file=sys.stderr)
            if args.enforce_gate:
                return 1
            print("coverage gate: informational only (pass --enforce-gate to block)")
        return 0
    finally:
        if args.keep_temp:
            print(f"coverage: kept temporary project {temp_root / 'project'}")
        else:
            shutil.rmtree(temp_root, ignore_errors=True)


if __name__ == "__main__":
    raise SystemExit(main())
