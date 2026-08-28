#!/usr/bin/env python3
"""Generate Pro dictionaries from normalized auxiliary-code data."""

import csv
import re
import shutil
from contextlib import ExitStack
from pathlib import Path

# Separator between pinyin and auxiliary code in the output dicts.
SEP = ";"

# Pattern to check if a string consists entirely of digits.
DIGIT_PATTERN = re.compile(r"^\d+$")


def get_alignment(
    han: str,
    segs: list[str],
    schema_maps: dict[str, dict[str, str]],
) -> list[list[str]] | None:
    """
    Align each CJK character of the word to one pinyin segment.
    Compute the alignment for all schemas at once to avoid aligning repeatedly.

    Returns: for each pinyin position, a list of auxiliary codes ordered by schema.
    e.g. [['aux_schema0', 'aux_schema1', ...], ...]  with length == len(segs).
    Returns None when the alignment fails.
    """
    chars = [ch for ch in han if not ch.isspace()]
    if len(chars) != len(segs):
        return None
    result = []
    for ch in chars:
        result.append([schema_map.get(ch, "") for schema_map in schema_maps.values()])
    return result


def load_aux_table(aux_file: Path) -> dict[str, dict[str, str]]:
    """Load character-to-code mappings keyed by CSV schema ID."""
    print(f"加载辅助码表文件: {aux_file.name}")

    with aux_file.open("r", encoding="utf-8", newline="") as input_file:
        reader = csv.DictReader(input_file)
        assert reader.fieldnames
        schema_maps: dict[str, dict[str, str]] = {
            schema: {} for schema in reader.fieldnames[1:]
        }
        for row in reader:
            char = row["#"]
            for schema, schema_map in schema_maps.items():
                schema_map[char] = row[schema]

    return schema_maps


def copy_dict(dict_file: Path, out_files: list[Path]):
    """
    Copy the dictionary file directly to the output directories.
    """
    for out_file in out_files:
        shutil.copy2(dict_file, out_file)
        print(f"已复制: {out_file}")


def process_dict(
    dict_file: Path,
    out_files: list[Path],
    schema_maps: dict[str, dict[str, str]],
):
    """
    Process a single dictionary file and write the results for every schema.
    """
    passthrough_set = {
        "的\td\t1000",
        "了\tl\t999",
        "吗\tm\t999",
        "吧\tb\t999",
    }

    with ExitStack() as stack:  # Close all files on exit
        fin = stack.enter_context(dict_file.open("r", encoding="utf-8"))
        fouts = [
            stack.enter_context(out_file.open("w", encoding="utf-8"))
            for out_file in out_files
        ]

        processing = False
        for line in fin:
            if not processing:
                for fout in fouts:
                    fout.write(line)
                if "..." in line:
                    processing = True
                continue

            raw = line.rstrip("\n")
            if (not raw) or raw.lstrip().startswith("#"):
                for fout in fouts:
                    fout.write(line)
                continue

            parts = raw.split("\t")
            if len(parts) == 1:
                for fout in fouts:
                    fout.write(line)
                continue

            han = parts[0]
            col2 = parts[1] if len(parts) > 1 else ""
            col3 = parts[2] if len(parts) > 2 else ""
            col4 = parts[3] if len(parts) > 3 else ""

            # If the second column is a frequency (all digits), move it to the third column.
            if DIGIT_PATTERN.fullmatch(col2 or ""):
                col3, col2 = col2, ""

            # Pass specific lines through unchanged.
            if raw.strip() in passthrough_set:
                for fout in fouts:
                    fout.write(raw + "\n")
                continue

            pinyins = col2.split(" ") if col2 else []

            # Alignment: computed once for all schemas.
            aligned = get_alignment(han, pinyins, schema_maps)

            if aligned is None:
                warn_line = (
                    f"# Warning: pinyin count does not match character count "
                    f"or cannot be aligned ({dict_file}) => {raw}\n"
                )
                print(warn_line.rstrip())
                for fout in fouts:
                    fout.write(warn_line)
                continue

            # Build the output line for each schema.
            for si, fout in enumerate(fouts):
                new_cols = []
                for i, py in enumerate(pinyins):
                    aux = aligned[i][si] if i < len(aligned) else ""
                    # Keep comma-separated alternatives in one spelling to match
                    # upstream Pro dictionaries instead of expanding duplicate rows.
                    new_cols.append(py + SEP + aux)
                new_col2 = " ".join(new_cols)
                if col4:
                    out_line = (
                        f"{han}\t{new_col2}\t{col3}\t{col4}\n"
                        if col3
                        else f"{han}\t{new_col2}\t\t{col4}\n"
                    )
                else:
                    out_line = (
                        f"{han}\t{new_col2}\t{col3}\n"
                        if col3
                        else f"{han}\t{new_col2}\n"
                    )
                fout.write(out_line)

    for out_file in out_files:
        print(f"已处理: {out_file}")


def process(
    dicts_dir: Path,
    aux_code_file: Path,
    dist_dir: Path,
    no_conversion_dicts: list[str] | None = None,
):
    schema_maps = load_aux_table(aux_code_file)
    first_schema_map = next(iter(schema_maps.values()))
    print(f"已加载辅助码条目: {len(first_schema_map)}")

    # Collect dict files to process
    for dict_file in dicts_dir.iterdir():
        if not dict_file.is_file():
            continue

        if not dict_file.name.endswith(".dict.yaml"):
            continue

        out_files = [
            (dist_dir / f"rime-wanxiang-{schema}-fuzhu" / dicts_dir / dict_file.name)
            for schema in schema_maps
        ]

        for out_file in out_files:
            out_file.parent.mkdir(parents=True, exist_ok=True)

        # Copy the original dict file to output if it's in the no_conversion_dicts list
        if no_conversion_dicts and dict_file.name in no_conversion_dicts:
            print(f"\n==> 复制 {dict_file.name}")
            copy_dict(dict_file, out_files)
        else:
            print(f"\n==> 处理 {dict_file.name}")
            process_dict(dict_file, out_files, schema_maps)


if __name__ == "__main__":
    AUX_CODE_FILE = Path("data/aux_code.csv")
    DICTS_DIR = Path("dicts")
    DIST_DIR = Path("dist")

    NO_CONVERSION_DICTS = [
        "english.dict.yaml",
    ]

    process(
        dicts_dir=DICTS_DIR,
        aux_code_file=AUX_CODE_FILE,
        dist_dir=DIST_DIR,
        no_conversion_dicts=NO_CONVERSION_DICTS,
    )
