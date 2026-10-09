#!/usr/bin/env python3
"""Generate Pro dictionaries from normalized auxiliary-code data."""

import csv
import shutil
from contextlib import ExitStack
from pathlib import Path

DICTS_DIR = Path("dicts")
DIST_DIR = Path("dist")
AUX_CODE_FILE = Path("data/aux_code.csv")
IGNORED_DICTS = ["english.dict.yaml"]


def get_alignment(
    han: str,
    segs: list[str],
    schema_maps: dict[str, dict[str, str]],
) -> list[list[str]] | None:
    """Return codes by pinyin position and schema, or None for mismatched counts."""
    characters = [char for char in han if not char.isspace()]
    if len(characters) != len(segs):
        return None

    return [
        [schema_map.get(char, "") for schema_map in schema_maps.values()]
        for char in characters
    ]


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


def copy_dict(dict_file: Path, out_files: list[Path]) -> None:
    """Copy the dictionary file directly to the output directories."""
    for out_file in out_files:
        shutil.copy2(dict_file, out_file)
        print(f"已复制: {out_file}")


def process_dict(
    dict_file: Path,
    out_files: list[Path],
    schema_maps: dict[str, dict[str, str]],
) -> None:
    """Process a single dictionary file and write the results for every schema."""
    with ExitStack() as stack:
        input_file = stack.enter_context(dict_file.open("r", encoding="utf-8"))
        output_files = [
            stack.enter_context(out_file.open("w", encoding="utf-8"))
            for out_file in out_files
        ]

        processing = False
        for line in input_file:
            if not processing:
                for output_file in output_files:
                    output_file.write(line)
                if "..." in line:
                    processing = True
                continue

            raw = line.rstrip("\n")
            if not raw or raw.lstrip().startswith("#"):
                for output_file in output_files:
                    output_file.write(line)
                continue

            parts = raw.split("\t")
            if len(parts) == 1:
                for output_file in output_files:
                    output_file.write(line)
                continue

            han = parts[0]
            col2 = parts[1]
            col3 = parts[2] if len(parts) > 2 else ""
            col4 = parts[3] if len(parts) > 3 else ""

            # If the second column is a frequency (all digits), move it to the third column.
            if col2.isdecimal():
                col3, col2 = col2, ""

            pinyins = col2.split(" ") if col2 else []

            aligned = get_alignment(han, pinyins, schema_maps)

            if aligned is None:
                warn_line = (
                    f"# Warning: pinyin count does not match character count "
                    f"or cannot be aligned ({dict_file}) => {raw}\n"
                )
                print(warn_line.rstrip())
                for output_file in output_files:
                    output_file.write(warn_line)
                continue

            for schema_index, output_file in enumerate(output_files):
                # Keep comma-separated alternatives in one spelling to match
                # upstream Pro dictionaries instead of expanding duplicate rows.
                new_col2 = " ".join(
                    pinyin + ";" + aligned[index][schema_index]
                    for index, pinyin in enumerate(pinyins)
                )
                if col4:
                    out_line = f"{han}\t{new_col2}\t{col3}\t{col4}\n"
                else:
                    out_line = (
                        f"{han}\t{new_col2}\t{col3}\n"
                        if col3
                        else f"{han}\t{new_col2}\n"
                    )
                output_file.write(out_line)

    for out_file in out_files:
        print(f"已处理: {out_file}")


def process(
    dicts_dir: Path,
    aux_code_file: Path,
    dist_dir: Path,
    ignored_dicts: list[str] | None = None,
) -> None:
    schema_maps = load_aux_table(aux_code_file)
    first_schema_map = next(iter(schema_maps.values()))
    print(f"已加载辅助码条目: {len(first_schema_map)}")

    for dict_file in dicts_dir.iterdir():
        if not dict_file.is_file() or not dict_file.name.endswith(".dict.yaml"):
            continue

        out_files = [
            (dist_dir / f"rime-wanxiang-{schema}-fuzhu" / dicts_dir / dict_file.name)
            for schema in schema_maps
        ]

        for out_file in out_files:
            out_file.parent.mkdir(parents=True, exist_ok=True)

        if ignored_dicts and dict_file.name in ignored_dicts:
            print(f"\n==> 复制 {dict_file.name}")
            copy_dict(dict_file, out_files)
        else:
            print(f"\n==> 处理 {dict_file.name}")
            process_dict(dict_file, out_files, schema_maps)


def main() -> None:
    process(
        dicts_dir=DICTS_DIR,
        aux_code_file=AUX_CODE_FILE,
        dist_dir=DIST_DIR,
        ignored_dicts=IGNORED_DICTS,
    )


if __name__ == "__main__":
    raise SystemExit(main())
