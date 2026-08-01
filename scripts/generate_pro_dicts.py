#!/usr/bin/env python3
"""Generate Pro dictionaries from normalized auxiliary-code data."""

import csv
import re
import shutil
from contextlib import ExitStack
from pathlib import Path

# Separator between pinyin and auxiliary code in the output dicts.
SEP = ";"

# Pattern to split Chinese and non-Chinese text blocks.
CJK_SPLIT_PATTERN = re.compile(r"([〇\u3400-\u4DBF\u4E00-\u9FFF\U00020000-\U000323AF])")
# Pattern to check if a string consists entirely of digits.
DIGIT_PATTERN = re.compile(r"^\d+$")


def tokenize_word(word: str) -> list[tuple[str, str]]:
    """
    Split a word into CJK and non-CJK blocks, returning a list of (type, text) tuples.
    """
    units: list[tuple[str, str]] = []
    for part in CJK_SPLIT_PATTERN.split(word):
        if not part or part.isspace():
            continue
        if CJK_SPLIT_PATTERN.fullmatch(part):
            units.append(("cn", part))
        else:
            # Append only if there is content left after stripping whitespace.
            stripped = part.replace(" ", "")
            if stripped:
                units.append(("en", stripped))
    return units


def get_alignment(
    units: list[tuple[str, str]],
    segs: list[str],
    schema_maps: dict[str, dict[str, str]],
) -> list[list[str]] | None:
    """
    Align CJK and non-CJK blocks to the pinyin segments.
    Compute the alignment for all schemas at once to avoid aligning repeatedly.

    Returns: for each pinyin position, a list of auxiliary codes ordered by schema.
    e.g. [['aux_schema0', 'aux_schema1', ...], ...]  with length == len(segs).
    Returns None when the alignment fails.
    """
    n_schemas = len(schema_maps)
    n_units = len(units)
    n_segs = len(segs)

    # Fast path: pure CJK words (the most common case).
    all_cn = all(t == "cn" for t, _ in units)
    if all_cn:
        if n_units != n_segs:
            return None
        result = []
        for _, ch in units:
            result.append([schema_map.get(ch, "") for schema_map in schema_maps.values()])
        return result

    # General path: mixed words containing English segments (iterative + backtracking).
    # Use an explicit stack instead of recursion to avoid deep recursion overhead.
    # Stack element: (u_idx, s_idx, built_result_so_far)
    # built_result_so_far is a list of rows (each row has n_schemas entries),
    # whose length equals the number of segs consumed so far.

    stack = [(0, 0, [])]
    while stack:
        u_idx, s_idx, built = stack.pop()

        if u_idx == n_units and s_idx == n_segs:
            return built

        if u_idx == n_units or s_idx == n_segs:
            continue

        utype, utext = units[u_idx]

        if utype == "cn":
            # CJK: strictly consume exactly one pinyin segment.
            aux_row = [schema_map.get(utext, "") for schema_map in schema_maps.values()]
            stack.append((u_idx + 1, s_idx + 1, built + [aux_row]))

        else:
            # Non-CJK, strategy 1: exact match against the joined pinyin string.
            en_text = utext.lower()
            empty_row = [""] * n_schemas
            current = ""
            found_strategy1 = False
            for k in range(s_idx, n_segs):
                current += segs[k].lower()
                if current == en_text:
                    empties = [empty_row] * (k - s_idx + 1)
                    # Push onto the stack (LIFO, so this path is explored first).
                    stack.append((u_idx + 1, k + 1, built + empties))
                    found_strategy1 = True
                    break

            if not found_strategy1:
                # Strategy 2: fault-tolerant consumption.
                remaining_cn = sum(1 for t, _ in units[u_idx + 1 :] if t == "cn")
                max_consume = n_segs - s_idx - remaining_cn
                # Push from small to large so the largest consumption is popped
                # (and tried) first.
                for consume_len in range(1, max_consume + 1):
                    empties = [empty_row] * consume_len
                    stack.append((u_idx + 1, s_idx + consume_len, built + empties))

    return None


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
            units = tokenize_word(han)
            aligned = get_alignment(units, pinyins, schema_maps)

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
        "mixedcode.dict.yaml",
        "english.dict.yaml",
    ]

    process(
        dicts_dir=DICTS_DIR,
        aux_code_file=AUX_CODE_FILE,
        dist_dir=DIST_DIR,
        no_conversion_dicts=NO_CONVERSION_DICTS,
    )
