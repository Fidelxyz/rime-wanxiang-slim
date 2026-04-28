#!/usr/bin/env python3
import argparse
import json
import re
import subprocess
import time
from pathlib import Path


def parse_args():
    parser = argparse.ArgumentParser(
        description="Run Mira and convert its output to CTRF JSON."
    )
    parser.add_argument(
        "--report-dir",
        "--out-dir",
        dest="report_dir",
        default="reports",
        help="Directory for CTRF JSON reports",
    )
    parser.add_argument("mira", help="Mira executable")
    parser.add_argument("tests", nargs="+", help="Test YAML files")
    return parser.parse_args()


def run_command(cmd: list[str]) -> tuple[int, list[str]]:
    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )

    lines: list[str] = []
    assert process.stdout is not None
    for line in process.stdout:
        print(line, end="")
        lines.append(line.rstrip("\n"))

    returncode = process.wait()
    return returncode, lines


def parse_tests(lines: list[str]) -> list[tuple[str, str]]:
    pattern = re.compile(r"^- (.+?)\.\.\.\s+(PASS|FAIL|SKIP)\s*$")
    cases: list[tuple[str, str]] = []
    for raw in lines:
        line = raw.strip()
        match = pattern.match(line)
        if match:
            name, status = match.group(1), match.group(2)
            cases.append((name, status))
    return cases


def build_ctrf_report(
    suite_name: str,
    cases: list[tuple[str, str]],
    start_ms: int,
    stop_ms: int,
) -> dict:
    tests: list[dict] = []
    for name, status in cases:
        normalized_status = {
            "PASS": "passed",
            "FAIL": "failed",
        }.get(status, "other")
        test = {
            "name": name,
            "status": normalized_status,
            "duration": 0,
            "suite": [suite_name],
            "rawStatus": status,
        }
        tests.append(test)

    summary = {
        "tests": len(tests),
        "passed": sum(1 for t in tests if t["status"] == "passed"),
        "failed": sum(1 for t in tests if t["status"] == "failed"),
        "pending": 0,
        "skipped": 0,
        "other": sum(1 for t in tests if t["status"] == "other"),
        "start": start_ms,
        "stop": stop_ms,
    }

    return {
        "reportFormat": "CTRF",
        "specVersion": "1.0.0",
        "results": {
            "tool": {"name": "Mira"},
            "summary": summary,
            "tests": tests,
        },
    }


def write_report(report: dict, out_path: Path) -> None:
    out_path = Path(out_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(report, indent=2), encoding="utf-8")


def infer_suite_name(test_path: str) -> str:
    base = Path(test_path).name
    for suffix in (".test.yaml", ".test.yml", ".yaml", ".yml"):
        if base.endswith(suffix):
            return base[: -len(suffix)]
    return Path(base).stem


def main():
    args = parse_args()
    cmd: list[str] = [args.mira]

    ret = 0
    for test_file in args.tests:
        print(f"==> Testing {test_file}")
        start_ms = int(time.time() * 1000)
        returncode, lines = run_command(cmd + [test_file])
        stop_ms = int(time.time() * 1000)
        if returncode != 0 and ret == 0:
            ret = returncode

        suite_name = infer_suite_name(test_file)
        cases = parse_tests(lines)
        report = build_ctrf_report(suite_name, cases, start_ms, stop_ms)
        out_path = Path(args.report_dir) / f"{suite_name}.json"
        write_report(report, out_path)

    return ret


if __name__ == "__main__":
    raise SystemExit(main())
