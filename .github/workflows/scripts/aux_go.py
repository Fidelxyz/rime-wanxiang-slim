import os
import re
from typing import List, Optional, Tuple

# ---------- 极广的汉字正则匹配：涵盖基础汉字、扩展区 A-H 以及 "〇" ----------
# 用于 split 的捕获组版本，一次调用即可切分整个词
CJK_SPLIT = re.compile(r"([〇\u3400-\u4DBF\u4E00-\u9FFF\U00020000-\U000323AF])")


# ---------- 中英文本边界解析 ----------
def tokenize_word(word: str) -> List[Tuple[str, str]]:
    """
    将词组按照汉字和非汉字块进行拆分，返回 (type, text) 元组列表。
    使用 re.split 单次 C 级操作替代逐字符 Python 循环，性能更高。
    """
    units = []
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
    units: List[Tuple[str, str]], segs: List[str], per_schema_maps: List[dict]
) -> Optional[List[List[str]]]:
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


# ---------- 在第一个点前插入后缀（例：base.dict.yaml -> base.pro.dict.yaml） ----------
def add_suffix_before_extensions(filename: str, suffix: str) -> str:
    if not suffix:
        return filename
    i = filename.find(".")
    return (filename + suffix) if i == -1 else (filename[:i] + suffix + filename[i:])


# ========== 1) 从"单个 aux 文件"加载 字 -> 辅助码段列表，并预计算各 schema 映射 ==========
# 行格式：字<TAB>;段1;段2;... （保留空段，不偏移；段内逗号原样保留）
def load_aux_table(aux_file_path):
    if not os.path.isfile(aux_file_path):
        raise FileNotFoundError(f"aux 文件不存在：{aux_file_path}")
    aux_map = {}
    print(f"加载辅助码表文件: {os.path.basename(aux_file_path)}")
    with open(aux_file_path, "r", encoding="utf-8") as f:
        for raw in f:
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split("\t")
            if len(parts) < 2:
                continue
            ch = parts[0]
            aux_list = parts[1].split(";")  # 保留空串占位（分号才是边界）
            aux_map[ch] = aux_list
    return aux_map


# ========== 2) 区间选择（严格：第 N 段 = aux_list[N]；N 从 1 起）==========
# 不处理逗号：分号窗口原样拼接
def select_aux_segment(aux_list, start_idx, end_idx=None):
    if not aux_list:
        return ""
    s = max(1, start_idx)
    e = end_idx if end_idx is not None else len(aux_list)
    e = max(s, min(e, len(aux_list)))
    window = aux_list[s:e]  # 允许空段
    return "".join(window) if window else ""


def build_schema_maps(aux_map: dict, index_mapping: list) -> List[dict]:
    """为每个 schema 预计算 字 -> 辅助码字符串 的扁平映射表。
    将 select_aux_segment 的切片/join 从每行每字提前到启动时一次性完成。
    """
    schema_maps = []
    for s_idx, e_idx, subdir in index_mapping:
        m = {
            ch: select_aux_segment(aux_list, s_idx, e_idx)
            for ch, aux_list in aux_map.items()
        }
        schema_maps.append(m)
        print(f"  预计算 schema [{subdir}]：{len(m)} 条")
    return schema_maps


DIGIT_RE = re.compile(r"^\d+$")


# ========== 3) 处理单个词库（单次读取，同时写入所有 schema 输出）==========
def process_file_all_schemas(in_file, out_files, per_schema_maps, sep=";"):
    """一次读取输入文件，同时向所有 schema 输出文件写入。
    避免重复 I/O 和重复行解析。
    """
    n_schemas = len(per_schema_maps)

    # 打开输入文件
    try:
        fin = open(in_file, "r", encoding="utf-8")
    except Exception as e:
        print(f"读取失败 {in_file}: {e}")
        return

    # 打开所有输出文件
    fouts = []
    for out_file in out_files:
        os.makedirs(os.path.dirname(out_file) or ".", exist_ok=True)
        try:
            fouts.append(open(out_file, "w", encoding="utf-8", buffering=256 * 1024))
        except Exception as e:
            for f in fouts:
                f.close()
            fin.close()
            print(f"写入失败 {out_file}: {e}")
            return

    passthrough_set = {
        "的\td\t1000",
        "了\tl\t999",
        "吗\tm\t999",
        "吧\tb\t999",
    }

    # 写入缓冲区（每个输出文件一个）
    BUF_SIZE = 4096
    bufs: List[List[str]] = [[] for _ in range(n_schemas)]

    def flush_all():
        for i, fout in enumerate(fouts):
            if bufs[i]:
                fout.writelines(bufs[i])
                bufs[i] = []

    def write_all(text: str):
        for i in range(n_schemas):
            bufs[i].append(text)
        if len(bufs[0]) >= BUF_SIZE:
            flush_all()

    def write_schema(i: int, text: str):
        bufs[i].append(text)
        if len(bufs[i]) >= BUF_SIZE:
            fouts[i].writelines(bufs[i])
            bufs[i] = []

    processing = False
    for line in fin:
        if not processing:
            write_all(line)
            if "..." in line:
                processing = True
            continue

        raw = line.rstrip("\n")
        if (not raw) or raw.lstrip().startswith("#"):
            write_all(line)
            continue

        parts = raw.split("\t")
        if len(parts) == 1:
            write_all(line)
            continue

        han = parts[0]
        col2 = parts[1] if len(parts) > 1 else ""
        col3 = parts[2] if len(parts) > 2 else ""
        col4 = parts[3] if len(parts) > 3 else ""

        # 第二列若是频率（全数字），挪到第三列
        if DIGIT_RE.fullmatch(col2 or ""):
            col3, col2 = col2, ""

        # 特定行直通
        stripped_raw = raw.strip()
        if stripped_raw in passthrough_set:
            write_all(raw + "\n")
            continue

        pinyins = col2.split(" ") if col2 else []

        # 对齐：一次性为所有 schema 计算
        units = tokenize_word(han)
        aligned = get_alignment(units, pinyins, per_schema_maps)

        if aligned is None:
            warn_base = f"# 警告: 拼音数与字数不匹配或无法对齐（{in_file}) => {raw}\n"
            print(warn_base.rstrip())
            write_all(warn_base)
            continue

        # 为每个 schema 构造输出行
        for si in range(n_schemas):
            new_cols = []
            for i, py in enumerate(pinyins):
                aux = aligned[i][si] if i < len(aligned) else ""
                new_cols.append(py + sep + aux)
            new_col2 = " ".join(new_cols)
            if col4:
                out_line = (
                    f"{han}\t{new_col2}\t{col3}\t{col4}\n"
                    if col3
                    else f"{han}\t{new_col2}\t\t{col4}\n"
                )
            else:
                out_line = (
                    f"{han}\t{new_col2}\t{col3}\n" if col3 else f"{han}\t{new_col2}\n"
                )
            write_schema(si, out_line)

    flush_all()
    fin.close()
    for fout in fouts:
        fout.close()
    for out_file in out_files:
        print(f"已处理: {out_file}")


# ========== 4) 扫目录 + 七套区间（按白名单）==========
def process_batch(
    input_dir,
    aux_file_path,
    base_out_dir,
    index_mapping,
    files_whitelist=None,
    sep=";",
    output_suffix="",
):
    aux_map = load_aux_table(aux_file_path)
    print(f"已加载辅助码条目：{len(aux_map)}")

    # 预计算所有 schema 的扁平映射表
    print("预计算各 schema 辅助码映射...")
    per_schema_maps = build_schema_maps(aux_map, index_mapping)

    # 预建输出目录
    for _, _, subdir in index_mapping:
        os.makedirs(os.path.join(base_out_dir, subdir), exist_ok=True)

    # 收集要处理的文件
    to_process = []
    for entry in os.scandir(input_dir):
        if not entry.is_file():
            continue
        name = entry.name
        if files_whitelist and name not in files_whitelist:
            continue
        if not (
            name.endswith(".yaml") or name.endswith(".yml") or name.endswith(".txt")
        ):
            continue
        to_process.append(entry.path)

    if not to_process:
        print("输入目录内没有匹配文件")
        return

    # 每个输入文件只读一次，同时写出所有 schema 输出
    for in_file in to_process:
        fn = os.path.basename(in_file)
        out_name = add_suffix_before_extensions(fn, output_suffix)
        out_files = [
            os.path.join(base_out_dir, subdir, out_name)
            for _, _, subdir in index_mapping
        ]
        print(f"\n=== 处理 {fn} → {len(out_files)} 个输出 ===")
        process_file_all_schemas(in_file, out_files, per_schema_maps, sep=sep)


# ========== 5) 入口 ==========
if __name__ == "__main__":
    # 七套区间（第 N 段，从 1 起）
    index_mapping = [
        (1, 2, "pro-moqi-fuzhu-dicts"),
        (2, 3, "pro-flypy-fuzhu-dicts"),
        (3, 4, "pro-zrm-fuzhu-dicts"),
        (4, 5, "pro-tiger-fuzhu-dicts"),
        (5, 6, "pro-wubi-fuzhu-dicts"),
        (6, 7, "pro-hanxin-fuzhu-dicts"),
        (7, None, "pro-shouyou-fuzhu-dicts"),
    ]

    # 路径
    AUX_FILE = "custom/aux_code.txt"  # ← 单个 aux 文件
    INPUT_DIR = "dicts"  # ← 词库文件夹
    OUT_ROOT = "."  # ← 输出根目录

    # 仅处理这些文件
    FILES = [
        "jichu.dict.yaml",
        "zi.dict.yaml",
        "duoyin.dict.yaml",
        "cuoyin.dict.yaml",
        "diming.dict.yaml",
        "shici.dict.yaml",
        "lianxiang.dict.yaml",
        "renming.dict.yaml",
        "wuzhong.dict.yaml",
    ]

    # 输出文件在第一个点前插这个后缀（如 ".pro"；设为空串则不加）
    OUTPUT_SUFFIX = ".pro"

    process_batch(
        INPUT_DIR,
        AUX_FILE,
        OUT_ROOT,
        index_mapping,
        files_whitelist=FILES,
        sep=";",
        output_suffix=OUTPUT_SUFFIX,
    )
