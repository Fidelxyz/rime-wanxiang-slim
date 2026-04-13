import re
import sys
import time
from io import TextIOWrapper
from pathlib import Path

RIME_DIR = Path(__file__).resolve().parent.parent

POLYPHONES = {
    "Eul的神圣法杖 > 的": "de",
    "艾AA > 艾": "ai",
    "大V > 大": "da",
    "QQ音乐 > 乐": "yue",
    "QQ会员 > 会": "hui",
    "QQ会员 > 员": "yuan",
    "阿Q精神 > 阿": "a",
    "G胖 > 胖": "pang",
    "阿Q > 阿": "a",
    "阿Q正传 > 阿": "a",
    "阿Q正传 > 传": "zhuan",
    "单边z变换 > 单": "dan",
    "卡拉OK > 卡": "ka",
    "IP地址 > 地": "di",
    "IP卡 > 卡": "ka",
    "SIM卡 > 卡": "ka",
    "UIM卡 > 卡": "ka",
    "USIM卡 > 卡": "ka",
    "X染色体 > 色": "se",
    "Y染色体 > 色": "se",
    "蒙奇·D·路飞 > 奇": "qi",
    "蒙奇·D·龙 > 奇": "qi",
    "马歇尔·D·蒂奇 > 奇": "qi",
    "蒙奇·D·卡普 > 奇": "qi",
    "蒙奇·D·卡普 > 卡": "ka",
    "波特卡斯·D·艾斯 > 卡": "ka",
    "波特卡斯·D·艾斯 > 艾": "ai",
    "A壳 > 壳": "ke",
    "B壳 > 壳": "ke",
    "C壳 > 壳": "ke",
    "D壳 > 壳": "ke",
    "芭比Q了 > 了": "le",
    "江南Style > 南": "nan",
    "三无Marblue > 无": "wu",
    "V字仇杀队 > 仇": "chou",
    "Q弹 > 弹": "tan",
    "M系列 > 系": "xi",
    "阿Sir > 阿": "a",
    "MAC地址 > 地": "di",
    "OK了 > 了": "le",
    "OK了吗 > 了": "le",
    "圈X > 圈": "quan",
    "A型血 > 血": "xue",
    "A血型 > 血": "xue",
    "B型血 > 血": "xue",
    "B血型 > 血": "xue",
    "AB型血 > 血": "xue",
    "AB血型 > 血": "xue",
    "O型血 > 血": "xue",
    "O血型 > 血": "xue",
    "没bug > 没": "mei",
    "没有bug > 没": "mei",
    "卡bug > 卡": "ka",
    "查bug > 查": "cha",
    "提bug > 提": "ti",
    "CT检查 > 查": "cha",
    "N卡 > 卡": "ka",
    "A卡 > 卡": "ka",
    "A区 > 区": "qu",
    "B区 > 区": "qu",
    "C区 > 区": "qu",
    "D区 > 区": "qu",
    "E区 > 区": "qu",
    "F区 > 区": "qu",
    "IT行业 > 行": "hang",
    "TF卡 > 卡": "ka",
    "A屏 > 屏": "ping",
    "A和B > 和": "he",
    "X和Y > 和": "he",
    "查IP > 查": "cha",
    "VIP卡 > 卡": "ka",
    "VIP会员 > 会": "hui",
    "VIP会员 > 员": "yuan",
    "Chromium系 > 系": "xi",
    "Chrome系 > 系": "xi",
    "QQ游戏大厅 > 大": "da",
    "QQ飞车 > 车": "che",
}

DIGIT_MAP = {
    "0": "零",
    "1": "一",
    "2": "二",
    "3": "三",
    "4": "四",
    "5": "五",
    "6": "六",
    "7": "七",
    "8": "八",
    "9": "九",
    "Ⅰ": "一",
    "Ⅱ": "二",
}

han_pinyin = {}


def load_han_pinyin():
    hanzi_path = RIME_DIR / "cn_dicts" / "8105.dict.yaml"
    if not hanzi_path.exists():
        print(f"File not found: {hanzi_path}")
        sys.exit(1)

    with open(hanzi_path, "r", encoding="utf-8") as f:
        is_mark = False
        for line in f:
            line = line.strip()
            if not is_mark:
                if line == "---" or "..." in line or "name:" in line:
                    pass
                if line == "---" or not line.startswith("#"):
                    if "\t" in line:
                        is_mark = True
                if not is_mark:
                    continue

            if not line or line.startswith("#"):
                continue
            parts = line.split("\t")
            if len(parts) >= 2:
                text, code = parts[0], parts[1]
                if text not in han_pinyin:
                    han_pinyin[text] = []
                han_pinyin[text].append(code)


def split_mixed_words(input_str: str) -> list[str]:
    result = []
    word = ""
    for r in input_str:
        if r in ("·", "-", "."):
            continue
        elif re.match(r"[A-Za-z]", r):
            word += r
        else:
            if word:
                result.append(word)
                word = ""
            result.append(r)
    if word:
        result.append(word)
    return result


def text_to_pinyin(text: str) -> str:
    code_parts = []
    parts = split_mixed_words(text)

    for part in parts:
        if part in DIGIT_MAP:
            digit = DIGIT_MAP[part]
            code_parts.append(han_pinyin[digit][0])
        elif part not in han_pinyin or len(han_pinyin[part]) == 0:
            code_parts.append(part)
        elif len(han_pinyin[part]) > 1:
            poly_key = f"{text} > {part}"
            if poly_key in POLYPHONES:
                val = POLYPHONES[poly_key]
                code_parts.append(val)
            else:
                print(f"❌ 多音字未指定读音: {text} {part}")
                sys.exit(1)
        else:
            code_parts.append(han_pinyin[part][0])

    return "'".join(code_parts)


def write_prefix(f: TextIOWrapper):
    content = """# Rime dictionary
# encoding: utf-8
#
# https://github.com/iDvel/rime-ice
# ------- 中英混输词库 -------
# 由 custom/cn_en.txt 自动生成
---
name: cn_en
version: "LTS"
sort: original
...
"""
    f.write(content)


def main():
    start_time = time.time()
    load_han_pinyin()

    DATA_PATH = RIME_DIR / "custom" / "cn_en.txt"
    if not DATA_PATH.exists():
        print(f"File not found: {DATA_PATH}")
        sys.exit(1)

    EN_DICTS_DIR = RIME_DIR / "en_dicts"
    EN_DICTS_DIR.mkdir(parents=True, exist_ok=True)
    OUT_PATH = EN_DICTS_DIR / "cn_en.dict.yaml"

    uniq = set()
    with open(OUT_PATH, "w", encoding="utf-8") as out_f:
        write_prefix(out_f)
        with open(DATA_PATH, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip("\n")
                if not line or line.startswith("#"):
                    continue

                stripped_line = line.strip()
                if stripped_line != line:
                    print(f"❌ 前后有空格 {line}")

                line = stripped_line
                if line in uniq:
                    print(f"❌ 重复 {line}")
                    continue

                uniq.add(line)

                code = text_to_pinyin(line)
                out_f.write(f"{line}\t{code}\n")

                lower_code = code.lower()
                if code != lower_code:
                    out_f.write(f"{line}\t{lower_code}\n")

    print(f"更新中英混输 耗时: {time.time() - start_time:.2f}s")


if __name__ == "__main__":
    main()
