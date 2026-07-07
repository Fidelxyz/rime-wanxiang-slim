#!/usr/bin/env python3
"""Sync grammar parameters from upstream schema files into this repository.

Extracts grammar parameter values from upstream schema files and updates the
corresponding keys in the local schema files, ensuring that grammar parameters
stay in sync when dictionaries are updated.

Only individual parameter values are updated; the rest of the local schema
(comments, blank lines, ordering) is preserved unchanged.

Usage::

    scripts/update_grammar_params.py --source <upstream_dir> [--repo-root <dir>]
"""

import argparse
import re
import sys
from pathlib import Path

# Maps local schema path to upstream source path (relative to source dir root).
SCHEMA_SOURCE_PATH: dict[str, str] = {
    "wanxiang.schema.yaml": "wanxiang.schema.yaml",
    "wanxiang_pro.schema.yaml": "custom/wanxiang_pro.schema.yaml",
}

GRAMMAR_PARAM_KEYS: tuple[str, ...] = (
    "collocation_max_length",
    "collocation_min_length",
    "collocation_penalty",
    "non_collocation_penalty",
    "weak_collocation_penalty",
    "rear_penalty",
)

GRAMMAR_KEY_PATTERN = re.compile(r"^grammar:")
PARAM_LINE_PATTERN = re.compile(r"^(\s+)([a-zA-Z_]+)\s*:\s*(.*)")


def extract_grammar_range(text: str) -> tuple[int, int]:
    """Return (start_line, end_line) of the grammar block. Line numbers are 0-based.

    Raises ValueError if no grammar block is found.
    """
    lines = text.splitlines()
    start = next(
        (i for i, line in enumerate(lines) if GRAMMAR_KEY_PATTERN.match(line)), None
    )
    if start is None:
        raise ValueError("no grammar block found in schema")

    end = start
    for i in range(start + 1, len(lines)):
        if lines[i].startswith((" ", "\t")):
            end = i
        elif lines[i].strip() == "" or lines[i].startswith("#"):
            continue
        else:
            break

    return start, end


def extract_params(text: str) -> dict[str, str]:
    """Extract the hardcoded grammar parameter values from a schema file."""
    params: dict[str, str] = {}
    start, end = extract_grammar_range(text)
    for line in text.splitlines()[start + 1 : end + 1]:
        match = PARAM_LINE_PATTERN.match(line)
        if match and match.group(2) in GRAMMAR_PARAM_KEYS:
            params[match.group(2)] = match.group(3).strip()
    return params


def update_param_values(
    local_text: str, upstream_params: dict[str, str]
) -> tuple[str, bool]:
    """Update grammar parameter values in-place, returning (new_text, changed)."""
    start, end = extract_grammar_range(local_text)
    lines = local_text.splitlines()

    changed = False
    for i in range(start + 1, end + 1):
        match = PARAM_LINE_PATTERN.match(lines[i])
        if not match:
            continue
        key, old_val = match.group(2), match.group(3).strip()
        new_val = upstream_params.get(key)
        if new_val is not None and old_val != new_val:
            lines[i] = f"{match.group(1)}{key}: {new_val}"
            changed = True

    return "\n".join(lines), changed


class GrammarUpdateError(Exception):
    """Raised for any expected, user-facing failure."""


def sync_grammar_params(source_dir: Path, repo_root: Path) -> None:
    print("==> Syncing grammar parameters from upstream")
    for local_path, upstream_path in SCHEMA_SOURCE_PATH.items():
        upstream_file = source_dir / upstream_path
        local_file = repo_root / local_path

        if not upstream_file.is_file():
            raise GrammarUpdateError(f"missing upstream schema: {upstream_file}")

        upstream_text = upstream_file.read_text(encoding="utf-8")
        upstream_params = extract_params(upstream_text)

        local_text = local_file.read_text(encoding="utf-8")
        new_text, changed = update_param_values(local_text, upstream_params)

        if changed:
            old_params = extract_params(local_text)
            local_file.write_text(new_text, encoding="utf-8")
            print(f"    {local_path}: updated")
            for key in GRAMMAR_PARAM_KEYS:
                old_val = old_params.get(key, "N/A")
                new_val = upstream_params.get(key, "N/A")
                if old_val != new_val:
                    print(f"      {key}: {old_val} -> {new_val}")
        else:
            print(f"    {local_path}: unchanged")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source",
        required=True,
        type=Path,
        help="Path to the upstream source checkout.",
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parent.parent,
        help="Repository root to write into (default: this script's parent directory).",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)

    source_dir: Path = args.source
    repo_root: Path = args.repo_root.resolve()

    if not source_dir.is_dir():
        print(f"error: source directory does not exist: {source_dir}", file=sys.stderr)
        return 1

    try:
        sync_grammar_params(source_dir, repo_root)
        print("==> Done")
    except GrammarUpdateError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
