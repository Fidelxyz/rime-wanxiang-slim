#!/usr/bin/env python3
"""
Data source: https://github.com/dofy/apple-emoji-dict
"""

import argparse
import json


def convert(input_path: str, output_path: str) -> None:
    with open(input_path, encoding="utf-8") as f:
        data: dict[str, list[str]] = json.load(f)

    with open(output_path, "w", encoding="utf-8") as f:
        for key, values in sorted(data.items()):
            if not values:
                continue
            line = f"{key}\t{key} {' '.join(values)}"
            f.write(line + "\n")

    print(f"Written {len(data)} entries to {output_path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Convert emoji JSON dict to OpenCC text format."
    )
    parser.add_argument(
        "input",
        help="Input emoji JSON file",
    )
    parser.add_argument(
        "output",
        help="Output OpenCC txt file",
    )
    args = parser.parse_args()

    convert(args.input, args.output)
