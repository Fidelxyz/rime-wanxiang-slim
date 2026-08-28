#!/usr/bin/env python3
"""Normalize dictionary and auxiliary-code data from upstream.

This script reads dictionary and auxiliary-code source data from an already
present local checkout of the upstream source tree and writes normalized results
into this repository's working tree.

What it does:

1. Rename each upstream pinyin dictionary identifier to a proper English
   identifier, renaming the output file to ``dicts/<english>.dict.yaml`` and
   rewriting the file's internal ``name:``.
2. Set each dictionary's ``version:`` field to the upstream release version.
3. Replace each dictionary's original comment header with a standardized header
   recording the upstream source, the original file name, and the upstream
   copyright/licence.
4. Write a code-only auxiliary CSV and normalized per-schema decomposition
   tables for direct consumption by the Pro dictionary generator and packager.

Usage::

    scripts/update_dicts.py --source <upstream_dir> --tag <tag> [--repo-root <dir>]
"""

import argparse
import csv
import re
import sys
from dataclasses import dataclass
from pathlib import Path

UPSTREAM_REPO = "amzxyz/rime-wanxiang"
UPSTREAM_URL = f"https://github.com/{UPSTREAM_REPO}"
UPSTREAM_LICENSE = "CC BY 4.0"

DICT_NAME_MAPPING: dict[str, str] = {
    "zi": "chars",
    "jichu": "base",
    "lianxiang": "association",
    "cuoyin": "correction",
    "duoyin": "polyphone",
    "shici": "poetry",
    "diming": "place",
    "wuzhong": "species",
    "renming": "person",
    "yixue": "medical",
    "huaxue": "chemistry",
    "yaopin": "pharmaceutical",
    "mingren": "celebrity",
    "yiren": "artist",
    "fangyan": "dialect",
    "taifeng": "typhoon",
    "en": "english",
}
IGNORED_DICTS = {
    "mixed.dict.yaml",
}

SRC_AUXILIARY_CSV_PATH = Path("custom/aux_code.csv")
SRC_DEDICATED_DECOMPOSITION: dict[str, Path] = {
    "wubi": Path("custom/wubi_chaifen.txt"),
}
DST_AUXILIARY_CSV_PATH = Path("data/aux_code.csv")
DST_DECOMPOSITION_DIR = Path("data/decomposition")
AUXILIARY_SCHEMA_MAPPING: dict[str, str] = {
    "万象": "wx",
    "墨奇": "moqi",
    "野鹤": "flypy",
    "自然码": "zrm",
    "虎码首末": "tiger",
    "五笔前2": "wubi",
    "汉心码": "hanxin",
    "首右": "shouyou",
    "首右Plus": "shyplus",
}

AUXILIARY_CANDIDATE_SEPARATOR_PATTERN = re.compile(r"[|｜]")
AUXILIARY_CODE_SEPARATOR_PATTERN = re.compile(r"[,;]")
AUXILIARY_CODE_ONLY_PATTERN = re.compile(r"[a-z]+(?:[,;][a-z]+)*")
GLUED_AUXILIARY_CODE_PREFIX_PATTERN = re.compile(r"^([a-z]+)(?=[^a-z])")
GLUED_AUXILIARY_CODE_SUFFIX_PATTERN = re.compile(r"([a-z]+)$")
GLUED_DECOMPOSITION_CODE_PATTERN = re.compile(r"([^\sa-z])([a-z]+)$")


class Error(Exception):
    """Raised for any expected, user-facing failure."""


@dataclass(frozen=True)
class AuxiliaryCandidate:
    """Normalized decomposition and auxiliary-code parts of one candidate."""

    decomposition: str
    code_text: str


def normalize_auxiliary_candidate(candidate: str) -> AuxiliaryCandidate | None:
    """Normalize one upstream candidate into separate decomposition and code parts.

    Candidates with both parts become ``AuxiliaryCandidate(decomposition, codes)``.
    Code-only candidates have an empty decomposition, while decomposition-only
    candidates have empty code text. Empty candidates return ``None``.
    """
    candidate = candidate.strip()
    if not candidate:
        return None

    candidate_parts = candidate.rsplit(maxsplit=1)
    if len(candidate_parts) == 2:
        decomposition, code_text = candidate_parts
        return AuxiliaryCandidate(decomposition, code_text.lower())

    if AUXILIARY_CODE_ONLY_PATTERN.fullmatch(candidate):
        return AuxiliaryCandidate("", candidate.lower())

    prefix_match = GLUED_AUXILIARY_CODE_PREFIX_PATTERN.search(candidate)
    suffix_match = GLUED_AUXILIARY_CODE_SUFFIX_PATTERN.search(candidate)
    auxiliary_codes: list[str] = []
    decomposition_start = 0
    decomposition_end = len(candidate)

    if prefix_match:
        auxiliary_codes.append(prefix_match.group(1))
        decomposition_start = prefix_match.end()
    if suffix_match and (
        not prefix_match or suffix_match.start() >= prefix_match.end()
    ):
        auxiliary_codes.append(suffix_match.group(1))
        decomposition_end = suffix_match.start()

    if not auxiliary_codes:
        return AuxiliaryCandidate(candidate, "")

    decomposition = candidate[decomposition_start:decomposition_end]
    return AuxiliaryCandidate(decomposition, ",".join(auxiliary_codes))


def normalize_auxiliary_cell(cell: str) -> list[AuxiliaryCandidate]:
    """Normalize every candidate in one upstream CSV cell."""
    normalized_candidates: list[AuxiliaryCandidate] = []
    for candidate in AUXILIARY_CANDIDATE_SEPARATOR_PATTERN.split(cell):
        normalized_candidate = normalize_auxiliary_candidate(candidate)
        if normalized_candidate:
            normalized_candidates.append(normalized_candidate)
    return normalized_candidates


def extract_auxiliary_codes(candidates: list[AuxiliaryCandidate]) -> str:
    """Return comma-separated auxiliary codes from normalized candidates."""
    auxiliary_codes: list[str] = []
    for candidate in candidates:
        auxiliary_codes.extend(
            code
            for code in AUXILIARY_CODE_SEPARATOR_PATTERN.split(candidate.code_text)
            if code
        )
    return ",".join(auxiliary_codes)


def format_decomposition_cell(candidates: list[AuxiliaryCandidate]) -> str:
    """Serialize normalized candidates for an OpenCC decomposition table."""
    formatted_candidates: list[str] = []
    for candidate in candidates:
        if candidate.decomposition and candidate.code_text:
            formatted_candidates.append(
                f"{candidate.decomposition}:{candidate.code_text}"
            )
        else:
            formatted_candidates.append(candidate.decomposition or candidate.code_text)
    return "｜".join(formatted_candidates)


def normalize_dedicated_decomposition_text(text: str) -> str:
    """Convert a dedicated decomposition source to the normalized OpenCC format."""
    return "".join(
        (
            line.rstrip("\n").replace(" ", ":")
            if " " in line.rstrip("\n")
            else GLUED_DECOMPOSITION_CODE_PATTERN.sub(r"\1:\2", line.rstrip("\n"))
        )
        + line[len(line.rstrip("\n")) :]
        for line in text.splitlines(keepends=True)
    )


@dataclass(frozen=True)
class NormalizedAuxiliaryRow:
    """One character and its normalized cells ordered by auxiliary schema."""

    char: str
    cells: list[list[AuxiliaryCandidate]]


NormalizedAuxiliaryData = list[NormalizedAuxiliaryRow]


def parse_auxiliary_code_csv(input_path: Path) -> NormalizedAuxiliaryData:
    """Parse an upstream auxiliary-code CSV into normalized rows."""
    normalized_data: NormalizedAuxiliaryData = []

    with input_path.open(
        "r", encoding="utf-8-sig", errors="ignore", newline=""
    ) as input_file:
        reader = csv.reader(input_file)
        header = next(reader, None)
        if header is None:
            raise Error(f"auxiliary-code CSV has no header: {input_path}")

        expected_columns = len(AUXILIARY_SCHEMA_MAPPING) + 1
        if len(header) != expected_columns:
            raise Error(
                f"auxiliary-code CSV header has {len(header)} columns, "
                f"expected {expected_columns}: {input_path}"
            )
        if tuple(header) != ("#", *AUXILIARY_SCHEMA_MAPPING):
            raise Error(f"unexpected auxiliary-code CSV header: {input_path}")

        for line_number, row in enumerate(reader, start=2):
            if len(row) != expected_columns:
                raise Error(
                    f"auxiliary-code CSV row {line_number} has {len(row)} columns, "
                    f"expected {expected_columns}: {input_path}"
                )

            char = row[0].strip()
            if not char:
                continue

            normalized_cells = [normalize_auxiliary_cell(cell) for cell in row[1:]]
            normalized_data.append(NormalizedAuxiliaryRow(char, normalized_cells))

    return normalized_data


def write_code_only_auxiliary_csv(
    normalized_data: NormalizedAuxiliaryData,
    output_path: Path,
) -> None:
    """Write normalized auxiliary codes to a code-only CSV."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8", newline="") as output_file:
        writer = csv.writer(output_file, lineterminator="\n")
        writer.writerow(["#", *AUXILIARY_SCHEMA_MAPPING.values()])
        writer.writerows(
            [row.char, *(extract_auxiliary_codes(cell) for cell in row.cells)]
            for row in normalized_data
        )


def write_auxiliary_decomposition_tables(
    normalized_data: NormalizedAuxiliaryData,
    schemas: list[str],
    decomposition_directory: Path,
) -> None:
    """Write normalized auxiliary data to per-schema decomposition tables."""
    decomposition_lines: dict[str, list[str]] = {schema: [] for schema in schemas}

    for row in normalized_data:
        for schema, candidates in zip(
            AUXILIARY_SCHEMA_MAPPING.values(), row.cells, strict=True
        ):
            if schema not in decomposition_lines:
                continue
            decomposition_cell = format_decomposition_cell(candidates)
            if decomposition_cell:
                decomposition_lines[schema].append(
                    f"{row.char}\t{decomposition_cell}\n"
                )

    decomposition_directory.mkdir(parents=True, exist_ok=True)
    for schema, lines in decomposition_lines.items():
        output_file = decomposition_directory / f"{schema}.txt"
        output_file.write_text("".join(lines), encoding="utf-8")


def validate_upstream_files(source_dir: Path) -> bool:
    """Report upstream file changes and return whether all required files exist."""
    expected_files = set()
    expected_files.update(
        Path("dicts") / f"{pinyin}.dict.yaml" for pinyin in DICT_NAME_MAPPING
    )
    expected_files.add(SRC_AUXILIARY_CSV_PATH)
    expected_files.update(SRC_DEDICATED_DECOMPOSITION.values())

    actual_files = set()
    actual_files.update(
        path.relative_to(source_dir)
        for path in (source_dir / "dicts").glob("*.dict.yaml")
        if path.is_file()
    )
    actual_files.update(
        path.relative_to(source_dir)
        for pattern in ("*.csv", "*_chaifen.txt")
        for path in (source_dir / "custom").glob(pattern)
        if path.is_file()
    )

    ignored_files = set()
    ignored_files.update(Path("dicts") / name for name in IGNORED_DICTS)

    new_files = sorted(actual_files - expected_files - ignored_files)
    if new_files:
        print(
            "warning: unrecognized upstream files will not be processed:",
            file=sys.stderr,
        )
        for path in new_files:
            print(f"    {path.as_posix()}", file=sys.stderr)

    missing_files = sorted(expected_files - actual_files)
    if missing_files:
        print("error: required upstream files are missing:", file=sys.stderr)
        for path in missing_files:
            print(f"    {path.as_posix()}", file=sys.stderr)
        return False

    return True


def build_dict_header(src_name: str, tag: str) -> str:
    """Return the standardized comment header for a normalized dictionary."""
    return (
        "# Rime dictionary\n"
        "# encoding: utf-8\n"
        "#\n"
        f"# Original file: {UPSTREAM_URL}/blob/{tag}/dicts/{src_name}.dict.yaml\n"
        f"# Copyright (c) amzxyz, licensed under {UPSTREAM_LICENSE}.\n"
    )


def normalize_dict_text(
    text: str, english: str, version: str, pinyin: str, tag: str
) -> str:
    """Rewrite a dictionary's header, ``name:`` and ``version:`` directives.

    The leading comment block (everything before the ``---`` document marker) is
    replaced by :func:`build_dict_header`. Within the directive block (between
    ``---`` and ``...``) the ``name:`` and ``version:`` values are rewritten.
    Entry lines after ``...`` are preserved verbatim.
    """
    lines = text.splitlines(keepends=True)

    marker_index = next(
        (i for i, line in enumerate(lines) if line.rstrip("\n") == "---"), None
    )
    if marker_index is None:
        raise Error(
            f"dictionary has no '---' document marker: dicts/{pinyin}.dict.yaml"
        )

    out: list[str] = [build_dict_header(pinyin, tag), "---\n"]

    saw_name = False
    in_directives = True
    for line in lines[marker_index + 1 :]:
        if in_directives:
            if line.rstrip("\n") == "...":
                in_directives = False
                out.append(line)
                continue
            if line.startswith("name:"):
                out.append(f"name: {english}\n")
                saw_name = True
                continue
            if line.startswith("version:"):
                out.append(f'version: "{version}"\n')
                continue
        out.append(line)

    if not saw_name:
        raise Error(f"dictionary has no 'name:' directive: dicts/{pinyin}.dict.yaml")

    return "".join(out)


def normalize_dictionaries(
    source_dir: Path, repo_root: Path, version: str, tag: str
) -> None:
    """Normalize every configured upstream dictionary."""
    print("==> Normalizing dictionaries")
    for pinyin, english in DICT_NAME_MAPPING.items():
        input_path = source_dir / "dicts" / f"{pinyin}.dict.yaml"
        output_path = repo_root / "dicts" / f"{english}.dict.yaml"

        text = input_path.read_text(encoding="utf-8")
        output_path.write_text(
            normalize_dict_text(text, english, version, pinyin, tag), encoding="utf-8"
        )
        print(f"    dicts/{pinyin}.dict.yaml -> dicts/{english}.dict.yaml")

        # Remove the stale pinyin-named file left over from before the rename.
        if pinyin != english:
            (repo_root / "dicts" / f"{pinyin}.dict.yaml").unlink(missing_ok=True)


def normalize_auxiliary_sources(source_dir: Path, repo_root: Path) -> None:
    """Generate code-only auxiliary data and normalized decomposition tables."""
    print("==> Normalizing auxiliary-code sources")

    normalized_data = parse_auxiliary_code_csv(source_dir / SRC_AUXILIARY_CSV_PATH)

    print("  Writing normalized auxiliary-code CSV:")
    write_code_only_auxiliary_csv(normalized_data, repo_root / DST_AUXILIARY_CSV_PATH)
    print(f"    {DST_AUXILIARY_CSV_PATH.as_posix()}")

    print("  Writing normalized auxiliary decomposition tables:")
    decomposition_schemas = [
        schema
        for schema in AUXILIARY_SCHEMA_MAPPING.values()
        if schema not in SRC_DEDICATED_DECOMPOSITION
    ]
    write_auxiliary_decomposition_tables(
        normalized_data, decomposition_schemas, repo_root / DST_DECOMPOSITION_DIR
    )
    for schema in decomposition_schemas:
        print(f"    {(DST_DECOMPOSITION_DIR / f'{schema}.txt').as_posix()}")

    print("  Writing normalized dedicated decomposition tables:")
    for schema, source_path in SRC_DEDICATED_DECOMPOSITION.items():
        input_path = source_dir / source_path
        output_path = repo_root / DST_DECOMPOSITION_DIR / f"{schema}.txt"
        output_path.write_text(
            normalize_dedicated_decomposition_text(
                input_path.read_text(encoding="utf-8")
            ),
            encoding="utf-8",
        )
        print(f"    {output_path.relative_to(repo_root).as_posix()}")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source",
        required=True,
        type=Path,
        help="Path to the upstream source checkout.",
    )
    parser.add_argument(
        "--tag",
        required=True,
        help="Upstream release tag, e.g. v15.16.0. The dictionary 'version:' "
        "field is set to the tag without its leading 'v'.",
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
    tag: str = args.tag
    version = tag.removeprefix("v")

    if not source_dir.is_dir():
        print(f"error: source directory does not exist: {source_dir}", file=sys.stderr)
        return 1

    if not validate_upstream_files(source_dir):
        return 1

    print(f"==> Updating dictionaries from {UPSTREAM_REPO} {tag} (version {version})")
    print(f"    source:    {source_dir}")
    print(f"    repo-root: {repo_root}")

    try:
        normalize_dictionaries(source_dir, repo_root, version, tag)
        normalize_auxiliary_sources(source_dir, repo_root)
    except Error as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    print("==> Done")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
