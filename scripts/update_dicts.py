#!/usr/bin/env python3
"""Normalize dictionary and decomposition data from an upstream rime_wanxiang checkout.

This script reads dictionary and character-decomposition data from an
already-present local checkout of the upstream source tree and writes
normalized results into this repository's working tree.

What it does:

1. Rename each upstream pinyin dictionary identifier to a proper English
   identifier, renaming the output file to ``dicts/<english>.dict.yaml`` and
   rewriting the file's internal ``name:``.
2. Set each dictionary's ``version:`` field to the upstream release version.
3. Replace each dictionary's original comment header with a standardized header
   recording the upstream source, the original file name, and the upstream
   copyright/licence.
4. Convert each per-schema decomposition file to the OpenCC-compatible decomposition
   format by separating the auxiliary code with a colon. Two schemas (shyplus,
   zrm) ship the auxiliary code glued to the components with no separator; the
   missing separator is inserted first.

Usage::

    scripts/update_dicts.py --source <upstream_dir> --tag <tag> [--repo-root <dir>]
"""

from __future__ import annotations

import argparse
import re
import sys
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
    "en": "english",
    "cn&en": "mixedcode",
}

# Per-schema decomposition files to convert.
DECOMPOSITION_SCHEMAS: list[str] = [
    "flypy",
    "hanxin",
    "moqi",
    "shouyou",
    "shyplus",
    "tiger",
    "wubi",
    "wx",
    "zrm",
]

# A decomposition data line is ``<char><TAB><components>[<sep>]<auxcode>``. The
# separator between the decomposition components and the auxiliary code must
# become a colon so OpenCC treats the value as a single candidate (the colon is
# turned back into a space for display by the schema's ``comment_format``).
#
# Most schemas separate the auxcode with a single space (``口可 kk``,
# ``亡丶 f;fdvg``); there the space *is* the separator and is simply replaced by
# a colon. A few schemas instead glue the auxcode directly onto the components
# with no separator (``丿勹pb``, ``{⺁}px``, ``.dk``); there a colon is inserted
# before the trailing lowercase-letter auxcode. Lines that are auxcode-only
# (``kg``) or component-only (``󰂮󰄼·󰂮󰄋``) are left untouched.
_DECOMPOSITION_GLUED_AUX_CODE = re.compile(r"([^\sa-z])([a-z]+)$")


class UpdateError(Exception):
    """Raised for any expected, user-facing failure."""


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
        raise UpdateError(
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
        raise UpdateError(
            f"dictionary has no 'name:' directive: dicts/{pinyin}.dict.yaml"
        )

    return "".join(out)


def convert_decomposition_line(line: str) -> str:
    """Convert a single decomposition line to the colon-separated decomposition format.

    If the line already has a space separating the components from the auxiliary
    code, that space becomes the colon. Otherwise, when a lowercase-letter
    auxcode is glued directly to the components, a colon is inserted before it.
    This covers both formats per line without any per-schema knowledge.
    """
    if " " in line:
        return line.replace(" ", ":")
    return _DECOMPOSITION_GLUED_AUX_CODE.sub(r"\1:\2", line)


def convert_decomposition_text(text: str) -> str:
    """Convert decomposition text, preserving line count and endings."""
    return "".join(
        convert_decomposition_line(line.rstrip("\n")) + line[len(line.rstrip("\n")) :]
        for line in text.splitlines(keepends=True)
    )


def normalize_dictionaries(
    source_dir: Path, repo_root: Path, version: str, tag: str
) -> None:
    print("==> Normalizing dictionaries")
    for pinyin, english in DICT_NAME_MAPPING.items():
        input_path = source_dir / "dicts" / f"{pinyin}.dict.yaml"
        output_path = repo_root / "dicts" / f"{english}.dict.yaml"

        if not input_path.is_file():
            raise UpdateError(f"missing upstream dictionary: {input_path}")

        text = input_path.read_text(encoding="utf-8")
        output_path.write_text(
            normalize_dict_text(text, english, version, pinyin, tag), encoding="utf-8"
        )
        print(f"    dicts/{pinyin}.dict.yaml -> dicts/{english}.dict.yaml")

        # Remove the stale pinyin-named file left over from before the rename.
        if pinyin != english:
            (repo_root / "dicts" / f"{pinyin}.dict.yaml").unlink(missing_ok=True)


def normalize_decomposition(source_dir: Path, repo_root: Path) -> None:
    print("==> Converting decomposition data")
    for schema in DECOMPOSITION_SCHEMAS:
        input_path = source_dir / "custom" / f"{schema}_chaifen.txt"
        output_path = repo_root / "data" / "decomposition" / f"{schema}.txt"

        if not input_path.is_file():
            raise UpdateError(f"missing upstream decomposition file: {input_path}")

        text = input_path.read_text(encoding="utf-8")
        output_path.write_text(convert_decomposition_text(text), encoding="utf-8")
        print(f"    data/decomposition/{schema}.txt")


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
    version = tag[1:] if tag.startswith("v") else tag

    if not source_dir.is_dir():
        print(f"error: source directory does not exist: {source_dir}", file=sys.stderr)
        return 1

    print(f"==> Updating dictionaries from {UPSTREAM_REPO} {tag} (version {version})")
    print(f"    source:    {source_dir}")
    print(f"    repo-root: {repo_root}")

    try:
        normalize_dictionaries(source_dir, repo_root, version, tag)
        normalize_decomposition(source_dir, repo_root)
    except UpdateError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    print("==> Done")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
