import os
import re
from contextlib import ExitStack
from pathlib import Path

# 辅助码表列定义
SCHEMA_COLUMNS: list[str] = [
    "pro-moqi-fuzhu-dicts",
    "pro-flypy-fuzhu-dicts",
    "pro-zrm-fuzhu-dicts",
    "pro-tiger-fuzhu-dicts",
    "pro-wubi-fuzhu-dicts",
    "pro-hanxin-fuzhu-dicts",
    "pro-shouyou-fuzhu-dicts",
]
SEP = ";"  # 拼音与辅助码段的分隔符

# ---------- 极广的汉字正则匹配：涵盖基础汉字、扩展区 A-H 以及 "〇" ----------
# 用于 split 的捕获组版本，一次调用即可切分整个词
CJK_SPLIT = re.compile(r"([〇\u3400-\u4DBF\u4E00-\u9FFF\U00020000-\U000323AF])")


# ---------- 中英文本边界解析 ----------
def tokenize_word(word: str) -> list[tuple[str, str]]:
    """
    将词组按照汉字和非汉字块进行拆分，返回 (type, text) 元组列表。
    使用 re.split 单次 C 级操作替代逐字符 Python 循环，性能更高。
    """
    units: list[tuple[str, str]] = []
    for part in CJK_SPLIT.split(word):
        if not part or part.isspace():
            continue
        if CJK_SPLIT.fullmatch(part):
            units.append(("cn", part))
        else:
            # 过滤掉空白后若仍有内容才追加
            stripped = part.replace(" ", "")
            if stripped:
                units.append(("en", stripped))
    return units


# ---------- 对齐：将汉字/非汉字块与拼音分段对齐 ----------
def get_alignment(
    units: list[tuple[str, str]], segs: list[str], per_schema_maps: list[dict]
) -> list[list[str]] | None:
    """
    迭代版对齐：将汉字和非汉字块对齐到拼音分段。
    一次性为所有 schema 计算对齐结果，避免重复对齐。

    返回值：每个 pinyin 位对应的辅助码列表，按 schema 顺序排列。
    例：[['aux_schema0', 'aux_schema1', ...], ...]  长度 == len(segs)
    返回 None 表示对齐失败。
    """
    n_schemas = len(per_schema_maps)
    n_units = len(units)
    n_segs = len(segs)

    # 快速路径：纯汉字词（最常见情况）
    all_cn = all(t == "cn" for t, _ in units)
    if all_cn:
        if n_units != n_segs:
            return None
        result = []
        for _, ch in units:
            result.append([m.get(ch, "") for m in per_schema_maps])
        return result

    # 通用路径：含英文片段的混合词（迭代 + 回溯）
    # 用显式栈替代递归，避免深递归开销
    # 栈元素：(u_idx, s_idx, built_result_so_far)
    # built_result_so_far 是 list of (n_schemas 长度的 list)，长度 == 已消耗 segs 数

    stack = [(0, 0, [])]
    while stack:
        u_idx, s_idx, built = stack.pop()

        if u_idx == n_units and s_idx == n_segs:
            return built

        if u_idx == n_units or s_idx == n_segs:
            continue

        utype, utext = units[u_idx]

        if utype == "cn":
            # 汉字：严格消耗 1 个拼音段
            aux_row = [m.get(utext, "") for m in per_schema_maps]
            stack.append((u_idx + 1, s_idx + 1, built + [aux_row]))

        else:
            # 非汉字：策略 1 —— 拼音字符串完全匹配
            en_text = utext.lower()
            empty_row = [""] * n_schemas
            current = ""
            found_strategy1 = False
            for k in range(s_idx, n_segs):
                current += segs[k].lower()
                if current == en_text:
                    empties = [empty_row] * (k - s_idx + 1)
                    # 压入栈（后进先出，优先探索此路径）
                    stack.append((u_idx + 1, k + 1, built + empties))
                    found_strategy1 = True
                    break

            if not found_strategy1:
                # 策略 2：容错消耗
                remaining_cn = sum(1 for t, _ in units[u_idx + 1 :] if t == "cn")
                max_consume = n_segs - s_idx - remaining_cn
                # 从大到小压栈，最大消耗最后弹出（优先尝试）
                for consume_len in range(1, max_consume + 1):
                    empties = [empty_row] * consume_len
                    stack.append((u_idx + 1, s_idx + consume_len, built + empties))

    return None


def add_suffix_before_extensions(filename: str, suffix: str) -> str:
    """
    在第一个点前插入后缀。

    >>> add_suffix_before_extensions("base.dict.yaml", ".pro")
    'base.pro.dict.yaml'
    """
    if not suffix:
        return filename
    i = filename.find(".")
    if i == -1:
        return filename + suffix
    return filename[:i] + suffix + filename[i:]


def load_aux_table(aux_file: Path) -> dict[str, list[str]]:
    """
    从单个 aux 文件加载“字 -> 辅助码段”列表，并预计算各 schema 映射。
    每行格式：
        字<TAB>;段1;段2;...
    （保留空段，不偏移；段内逗号原样保留）
    """
    if not aux_file.is_file():
        raise FileNotFoundError(f"aux 文件不存在：{aux_file}")

    print(f"加载辅助码表文件: {aux_file.name}")

    aux_map: dict[str, list[str]] = {}
    with aux_file.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            cols = line.split("\t")
            if len(cols) < 2:
                continue

            char = cols[0]
            # Skip the first empty segment before the first ';'
            aux_list = cols[1].split(";")[1:]
            aux_map[char] = aux_list

    return aux_map


def build_schema_maps(aux_table: dict[str, list[str]]) -> list[dict[str, str]]:
    """
    Build a mapping for each aux code schema that maps characters to their corresponding aux code segment for that schema.
    """
    return [
        {ch: aux_list[i] for ch, aux_list in aux_table.items()}
        for i in range(len(SCHEMA_COLUMNS))
    ]


DIGIT_RE = re.compile(r"^\d+$")


def process_dict(
    dict_file: Path,
    out_files: list[Path],
    schema_maps: list[dict[str, str]],
):
    """
    处理单个词库文件，输出所有 schema 的结果。
    """
    passthrough_set = {
        "的\td\t1000",
        "了\tl\t999",
        "吗\tm\t999",
        "吧\tb\t999",
    }

    for out_file in out_files:
        os.makedirs(out_file.parent or ".", exist_ok=True)

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

            # 第二列若是频率（全数字），挪到第三列
            if DIGIT_RE.fullmatch(col2 or ""):
                col3, col2 = col2, ""

            # 特定行直通
            if raw.strip() in passthrough_set:
                for fout in fouts:
                    fout.write(raw + "\n")
                continue

            pinyins = col2.split(" ") if col2 else []

            # 对齐：一次性为所有 schema 计算
            units = tokenize_word(han)
            aligned = get_alignment(units, pinyins, schema_maps)

            if aligned is None:
                warn_line = (
                    f"# 警告: 拼音数与字数不匹配或无法对齐（{dict_file}) => {raw}\n"
                )
                print(warn_line.rstrip())
                for fout in fouts:
                    fout.write(warn_line)
                continue

            # 为每个 schema 构造输出行
            for si, fout in enumerate(fouts):
                new_cols = []
                for i, py in enumerate(pinyins):
                    aux = aligned[i][si] if i < len(aligned) else ""
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
    aux_file: Path,
    out_dir: Path,
    dicts: list[str] | None = None,
    output_suffix: str = "",
):
    aux_table = load_aux_table(aux_file)
    print(f"已加载辅助码条目：{len(aux_table)}")

    print("拆分各 schema 辅助码映射...")
    schema_maps = build_schema_maps(aux_table)
    print("拆分完成。")

    # Collect dict files to process
    dict_files: list[Path] = []
    for file in dicts_dir.iterdir():
        if not file.is_file():
            continue

        # Filter by dicts if provided
        dict_name = file.name
        if dicts and dict_name not in dicts:
            continue
        if not dict_name.endswith((".yaml", ".yml", ".txt")):
            continue

        dict_files.append(file)

    # 每个输入文件只读一次，同时写出所有 schema 输出
    for dict_file in dict_files:
        out_filename = add_suffix_before_extensions(dict_file.name, output_suffix)
        out_files = [(out_dir / schema / out_filename) for schema in SCHEMA_COLUMNS]
        print(f"\n=== 处理 {dict_file.name} ===")
        process_dict(dict_file, out_files, schema_maps)


if __name__ == "__main__":
    AUX_FILE = Path("custom/aux_code.txt")  # 辅助码表文件
    DICTS_DIR = Path("dicts")  # 词库文件夹
    OUT_DIR = Path("dist")  # 输出根目录

    # 仅处理这些文件
    DICTS = [
        "jichu.dict.yaml",
        "zi.dict.yaml",
        "duoyin.dict.yaml",
        "cuoyin.dict.yaml",
        "diming.dict.yaml",
        "shici.dict.yaml",
        "lianxiang.dict.yaml",
        "renming.dict.yaml",
        "wuzhong.dict.yaml",
        "mixed.dict.yaml",
    ]

    # 输出文件在第一个点前插这个后缀（如 ".pro"；设为空串则不加）
    OUTPUT_SUFFIX = ".pro"

    process(
        DICTS_DIR,
        AUX_FILE,
        OUT_DIR,
        dicts=DICTS,
        output_suffix=OUTPUT_SUFFIX,
    )
