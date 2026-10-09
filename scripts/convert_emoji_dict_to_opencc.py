#!/usr/bin/env python3
"""
Data source: https://github.com/dofy/apple-emoji-dict
"""

import argparse
import json


def convert(input_path: str, output_path: str) -> None:
    with open(input_path, encoding="utf-8") as input_file:
        entries: dict[str, list[str]] = json.load(input_file)

    with open(output_path, "w", encoding="utf-8") as output_file:
        for key, values in sorted(entries.items()):
            if not values:
                continue
            output_file.write(f"{key}\t{key} {' '.join(values)}\n")

    print(f"Written {len(entries)} entries to {output_path}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert emoji JSON dict to OpenCC text format."
    )
    parser.add_argument("input", help="Input emoji JSON file")
    parser.add_argument("output", help="Output OpenCC txt file")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    convert(args.input, args.output)


if __name__ == "__main__":
    raise SystemExit(main())
