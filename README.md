
# 万象系列输入方案

专注于输入的万象拼音方案精简版。

---

## 万象拼音

基于 AI 辅助与大规模语料筛选构建的 Rime 拼音方案，以万象词库和语法模型为核心，提供流畅的整句输入体验。

[万象词库](https://github.com/amzxyz/RIME-LMDG) 覆盖日常、专业、文学等领域，结合词频优化与语法模型，实现精准的整句预测。

---

## 核心功能

**精准权重与分词**：长期优化首选权重与分词片段，配合语法模型，提供流畅的整句输入体验。

**反查系统**：支持至 Unicode 17 (U17) 标准，提供两分、多分、笔画三种反查方式。

**Lua 扩展**：支持成对符号包裹首选、输入后反查、OpenCC 替代、超级注释、手动实时排序、无感造词等功能。

**辅助码兼容**：支持拼音 + 辅助码任意组合，内置 6 种主流辅码（墨奇码、鹤形、自然码、虎码首末、五笔前2、汉心码）。

---

## 精简说明

本仓库是 [amzxyz/rime_wanxiang](https://github.com/amzxyz/rime_wanxiang) 的 fork。

这是一个专注于输入的精简分支，移除了以下无关功能：

| 已移除功能 | 说明 |
| --- | --- |
| 超级 Tips | 表情、化学式、翻译、简码提示等直接上屏功能 |
| 时间日期 Lua | 多种中文日期时间格式输入 |
| 数字翻译器 Lua | 大小写中文数字转换 |
| 符号输入方案 | `/` 前缀触发特殊符号候选 |
| 计算器 Lua | 数学表达式直接得出计算结果 |
| 输入统计 Lua | 统计用户输入字数等数据 |
| 版本显示 Lua | `/wx` 触发显示万象版本号 |
| 翻译模式 | Ctrl+E 进入中英互译模式 |
| T9 九宫格方案 | 移动端 T9 输入方案 |
| 14 键 / 18 键设定 | 移动端缩减键盘布局的转写支持 |
| 声调辅助筛选 | 用 7890 数字键代表四声进行辅助筛选 |
| 输入码音调显示 Lua | Ctrl+S 使输入码实时显示全拼并加音调，Shift+Enter 上屏编码字符串 |

---

## 版本对比

|  | 标准版 (Standard) | 增强版 (Pro) |
| --- | --- | --- |
| **方案文件** | `wanxiang.schema.yaml` | `wanxiang_pro.schema.yaml` |
| **支持类型** | 全拼、任意双拼 | 仅支持双拼 |
| **自动调频** | 默认开启 | 默认关闭 |
| **用户词记录** | 自动记录 | 手动造词（` `` ` 引导）或无感造词 |
| **用户词位置** | `wanxiang.userdb` | `zc.userdb` |
| **辅助码** | 仅基于声调 | 7 种辅助码可选，兼声调辅助 |
| **词库格式** | 你 → `nǐ` → 1000 | 你 → `nǐ;re` → 1000 |

---

## 快速开始

如果你不熟悉 Rime 基础概念（用户目录、部署等），建议先参考：

- [Oh My Rime - Rime 安装指南](https://www.mintimate.cc/zh/guide/installRime.html)
- [Rime 参数配置详解](https://xishansnow.github.io/posts/41ac964d.html)

> [!TIP]
> 万象有独特的自动化配置逻辑，建议先按以下步骤完整运行，体验功能后再进行定制。

### 1. 安装

1. 从 [Release](https://github.com/amzxyz/rime_wanxiang/releases) 页面下载方案文件，或使用[万象工具箱](#万象工具箱)。
2. 将解压后的文件放入 Rime **用户目录**。
3. 点击“重新部署”。

### 2. 切换输入方案

在输入状态下，输入以下由 `/` 引导的指令切换对应方案。切换后需**重新部署**。

可用切换指令：

| 指令 | 方案 |
| --- | --- |
| `/flypy` | 小鹤双拼 |
| `/mspy` | 微软双拼 |
| `/zrm` | 自然码 |
| `/sogou` | 搜狗双拼 |
| `/znabc` | 智能ABC |
| `/ziguang` | 紫光双拼 |
| `/pyjj` | 拼音加加 |
| `/gbpy` | 国标双拼 |
| `/lxsq` | 乱序17 |
| `/pinyin` | 全拼 |
| `/wxsp` | 万象双拼 |
| `/zrlong` | 自然龙（反查为全拼） |
| `/hxlong` | 汉心龙（反查为全拼） |
| `/jjf` | 间接辅助 |
| `/zjf` | 直接辅助 |

<details>
<summary>⚠️ <strong>iOS 平台方案切换步骤</strong></summary>

**仓输入法 (Hamster)**

1. 仓设置 → 输入方案设置 → 右上角 `+` → 方案下载，下载万象方案。
2. 在输入法界面长按 `/`（不要上划），输入切换指令（如 `/flypy`）。
3. 仓设置 → 文件管理 → **使用键盘文件覆盖应用文件**。
4. 仓设置 → RIME → 重新部署。

**元书输入法 (Hamster3)**

1. 从 `RimeSharedSupport` 目录复制 `include_keyboard_rime_files.txt` 到万象方案目录。
2. 在文件底部追加：

    ```
    ^.*[.]custom.*$
    ```

</details>

### 2. 安装语法模型（推荐）

下载语法模型文件，放置于 Rime **用户目录根目录**，无需额外配置。

> 语法模型为静态二进制文件，大小固定，CPU 计算为主，内存占用极低。

<details>
<summary>⚠️ <strong>Android 用户注意事项（Fcitx5 等前端）</strong></summary>

部分安卓前端的数据存储在 `/data` 目录下，受严格权限控制。

**不要**使用 MT 管理器等工具直接复制文件，这会导致由权限不一致引发的读取失败。

须使用输入法 App 自带的“导入文件”功能；或（Root 用户）手动复制后使用 `chown` 和 `chmod` 修正权限。

</details>

### 3. 个人配置：Custom Patch

`*.custom.yaml` 是对方案文件的补丁，属于个人私有配置，**不会被升级覆盖**。

custom 文件必须位于**用户目录根目录**（与 `wanxiang.schema.yaml` 同级）。

> [!CAUTION]
> 不要直接修改 `custom` 文件夹中的文件，该文件夹为模板仓库，修改不会生效。

通过 `/` 指令切换方案时，脚本会自动将模板从 `custom` 文件夹复制到根目录完成初始化。初始化后请仔细阅读每一行，保留需要的配置并删除不需要的。

更多方法参见 `custom` 目录中的 [Rime Custom Patch 语法指南](PATCH_GUIDE.md)。

补丁对应关系：

| Custom 文件 | 对应方案文件 | 用途 |
| --- | --- | --- |
| `wanxiang.custom.yaml` | `wanxiang.schema.yaml` | 输入方案配置 |
| `default.custom.yaml` | `default.yaml` | 全局配置（通常留给前端控制） |
| `squirrel.custom.yaml` | `squirrel.yaml` | Mac 鼠须管外观 |
| `weasel.custom.yaml` | `weasel.yaml` | Win 小狼毫外观 |

> [!IMPORTANT]
> 不要在 `default.custom.yaml` 中修改输入方案配置。所有方案相关修改（模糊音、快捷键等）应针对具体 `schema` 进行 patch，`default` 文件请留给输入法前端自动管理。

---

## 安装与更新工具

### 万象工具箱

PC 用户推荐使用[**万象工具箱**](https://github.com/amzxyz/RIME-LMDG/releases/tag/tool)，内置在线更新器。

- **智能更新**：自动检测 GitHub / CNB 源，自动下载并解压覆盖。
- **白名单保护**：支持受控文件覆盖，防止个人配置被覆盖。
- **双重重置模式**：
  - 构建重置：清空 `build` 目录，强制重新编译。
  - 纯净重置：仅保留白名单文件，其余全部替换为官方最新版。

### 第三方更新工具

- [Python / PowerShell 脚本](https://github.com/rimeinn/rime-wanxiang-update-tools)
- [Go 语言更新器](https://github.com/ca-x/rime-wanxiang-updater)

### 东风破 (Plum) 管理器

> [!WARNING]
> Windows 用户必须使用 Git Bash 运行脚本，不支持 PowerShell 或 CMD。

1. 克隆 plum 分支：

    ```bash
    git clone -b plum --depth 1 https://github.com/amzxyz/rime_wanxiang.git
    cd plum
    ```

2. 如使用 Linux / macOS 的 ibus 或 fcitx 前端，需设置环境变量：

    ```bash
    export rime_frontend='rime/ibus-rime'
    # 或
    export rime_frontend='fcitx/fcitx-rime'
    ```

3. 执行安装命令：

    <details>
    <summary>基础版（完整）</summary>

    ```bash
    bash rime-install amzxyz/rime_wanxiang@wanxiang-base:plum/full
    ```
    </details>

    <details>
    <summary>基础版（仅词库）</summary>

    ```bash
    bash rime-install amzxyz/rime_wanxiang@wanxiang-base:plum/dicts
    ```
    </details>

    <details>
    <summary>自然码辅助版（完整）</summary>

    ```bash
    bash rime-install amzxyz/rime_wanxiang@wanxiang-zrm-fuzhu:plum/full
    ```
    </details>

    <details>
    <summary>自然码辅助版（仅词库）</summary>

    ```bash
    bash rime-install amzxyz/rime_wanxiang@wanxiang-zrm-fuzhu:plum/dicts
    ```
    </details>

    <details>
    <summary>墨奇辅助版（完整）</summary>

    ```bash
    bash rime-install amzxyz/rime_wanxiang@wanxiang-moqi-fuzhu:plum/full
    ```
    </details>

    <details>
    <summary>墨奇辅助版（仅词库）</summary>

    ```bash
    bash rime-install amzxyz/rime_wanxiang@wanxiang-moqi-fuzhu:plum/dicts
    ```
    </details>

    <details>
    <summary>小鹤辅助版（完整）</summary>

    ```bash
    bash rime-install amzxyz/rime_wanxiang@wanxiang-flypy-fuzhu:plum/full
    ```
    </details>

    <details>
    <summary>小鹤辅助版（仅词库）</summary>

    ```bash
    bash rime-install amzxyz/rime_wanxiang@wanxiang-flypy-fuzhu:plum/dicts
    ```
    </details>

    <details>
    <summary>虎码辅助版（完整）</summary>

    ```bash
    bash rime-install amzxyz/rime_wanxiang@wanxiang-tiger-fuzhu:plum/full
    ```
    </details>

    <details>
    <summary>虎码辅助版（仅词库）</summary>

    ```bash
    bash rime-install amzxyz/rime_wanxiang@wanxiang-tiger-fuzhu:plum/dicts
    ```
    </details>

    <details>
    <summary>五笔辅助版（完整）</summary>

    ```bash
    bash rime-install amzxyz/rime_wanxiang@wanxiang-wubi-fuzhu:plum/full
    ```
    </details>

    <details>
    <summary>五笔辅助版（仅词库）</summary>

    ```bash
    bash rime-install amzxyz/rime_wanxiang@wanxiang-wubi-fuzhu:plum/dicts
    ```
    </details>

    <details>
    <summary>汉心辅助版（完整）</summary>

    ```bash
    bash rime-install amzxyz/rime_wanxiang@wanxiang-hanxin-fuzhu:plum/full
    ```
    </details>

    <details>
    <summary>汉心辅助版（仅词库）</summary>

    ```bash
    bash rime-install amzxyz/rime_wanxiang@wanxiang-hanxin-fuzhu:plum/dicts
    ```
    </details>

    <details>
    <summary>首右辅助版（完整）</summary>

    ```bash
    bash rime-install amzxyz/rime_wanxiang@wanxiang-shouyou-fuzhu:plum/full
    ```
    </details>

    <details>
    <summary>首右辅助版（仅词库）</summary>

    ```bash
    bash rime-install amzxyz/rime_wanxiang@wanxiang-shouyou-fuzhu:plum/dicts
    ```
    </details>

---

## 可选扩展数据

部分扩展数据未随压缩包分发，可从仓库 `custom` 目录下载：

| 文件名 | 用途 | 安装方式 |
| --- | --- | --- |
| `renming.dict.yaml` | 人名词库（Pro 版使用工具箱刷新编码） | 复制内容追加到根目录 `wanxiang.dict.yaml` |
| `wuzhong.dict.yaml` | 物种词库（动植物分类等词条，Pro 版使用工具箱刷新） | 复制内容追加到根目录 `wanxiang.dict.yaml` |
| `jm_flypy.txt` | 小鹤双拼简码 | 复制内容追加到根目录 `custom_phrase.txt` |
| `jm_zrm.txt` | 自然码双拼简码 | 复制内容追加到根目录 `custom_phrase.txt` |

---

## 数据文件说明

| 文件 | 用途 | 数据库位置 |
| --- | --- | --- |
| `lua/data/emoji.txt` | Emoji 数据库 | `lua/replacer.userdb` |
| `lua/data/abbrev.txt` | 公共简码数据库 | `lua/replacer.userdb` |
| `lua/data/*Phrases.txt` | OpenCC 简繁转换词组（HK 香港 / TW 台湾） | `lua/replacer.userdb` |
| `lua/data/*Characters.txt` | OpenCC 简繁转换单字（ST 简繁 / TS 繁简） | `lua/replacer.userdb` |
| `super_sequence.lua` | 手动排序 Lua 实时数据 | `lua/sequence.userdb` |

---

## 功能详解

### 辅助码系统（仅 Pro 版）

#### 直接辅助码

在双拼编码后直接追加辅助码。例如输入"镇"：双拼 `vf` + 首位辅助码 `j` → `vfj`，如候选未出现可继续追加第二位辅助码。

**重码处理**：当"双拼 + 辅码"与现有词组重码时（均为 4 码），优先显示词组。在编码末尾追加 `/` 可强制忽略词组，优先展示带辅码的单字。

#### 间接辅助码

使用 `/` 作为分隔符引导辅助码，格式：`拼音/辅码`。例如：双拼 `ni` + 辅助码 `re` → `ni/re`。

不输入 `/` 则视为普通拼音，不干扰整句切分。适合新手或轻量级用户。

### 反查系统

在方案文件中配置 `wanxiang_lookup`：

```yaml
wanxiang_lookup:
  tags: [ abc ]
  key: "`"
  lookup: [ wanxiang_reverse ]
  data_source: [ aux, db ]    # aux: 从词库注释提取；db: 从反查数据库提取
```

反查和笔画需在 `wanxiang_reverse.custom.yaml` 中配置。

#### 候选筛选（输入后反查）

输入主拼音后按 <kbd>`</kbd>，再输入部首读音首字母进行二次筛选。例如按 `j`（jin）筛选金字旁，按 `mu` 筛选木字旁。

- 单字：支持两分（`` ni`re ``）、多分（`` mu`ckrida ``）、笔画（`` ni`pspzhpd ``）
- 词组：匹配辅助码序列的任意非空子字符串

#### 输入前反查

在拼音状态下输入反查符 `` ` ``，再输入部件的拼音编码，从部件查找目标字。例如输入 `` ` `` 后输入"雨"和"辰"的双拼编码 `yu if`，可找到"震"字并显示辅助码。

### 其他功能

**Unicode 输入**：大写 U 开头，如 `U62fc` 得到"拼"。

**数字金额大写**：大写 R 开头，如 `R1234` 得到"一千二百三十四、壹仟贰佰叁拾肆元整"。

**自动上屏**：三四位简码唯一时自动上屏（默认关闭，在 `speller:` 字段下取消注释开启）。

**空码回溯**：输入编码无候选时，显示上一次候选并标注 `~`，可直接空格上屏，减少回删操作。

**数字后自动半角**：中文状态下输入数字后紧跟 `,` 或 `.` 自动转为数字分隔符，如 `1000,000` 或 `3.1415`。如不需要此功能，可通过 patch 修改：

```
punctuator/digit_separators: ","  →  punctuator/digit_separators: commit
```

**错音错字提示**：如输入 `gei yu 给予`，会提示正确读音 `jǐ yǔ`，全拼双拼均支持。

**短语格式化 Lua**：将 `custom_phrase.txt` 中的 `\n`、`\s`、`\t` 等转换为实际的换行、空格、制表符，支持动态变量（时间、日期等）。

**成对符号包裹 Lua**：输入词汇编码后按 `\` 锁定，再按映射字符触发成对符号包裹首选候选。

**输入模式切换 Lua**：使用 Shift+Space 在中文、英文、混合候选词之间切换。

**辅助码提示 Lua（仅 Pro）**：显示候选词的辅助码提示，Ctrl+A 循环切换辅助码提示 / 声调全拼提示 / 关闭注释，Ctrl+C 开启拆分辅助提示。

**按需造词（仅 Pro）**：通过 ` `` ` 引导进入造词模式；编码后双击 ` `` ` 可在不删除编码的情况下后触发造词；次选词上屏后自动记录。

**无感造词 Lua（仅 Pro）**：关闭调频时，逐步选字上屏会自动记录词条，不产生碎片。

**英文造词 Lua**：英文编码末尾输入 `\\` 触发英文造词，记录到 `en.userdb`。

**用户词删除**：Ctrl+Del 标记用户词为不使用（假性删除）。

**字符集过滤 Lua**：默认过滤启用，可通过开关切换字集范围（通用规范、GB2312、GBK、Big5、简繁体等），Ctrl+G 快捷切换。支持联动简繁转换开关，对不同开关单独配置显示范围和黑白名单。

```yaml
charset:
  - option: charset_filter
    base: a
    addlist:
      - "诶濛硷氽尛躝〇冇吔咗囧屌鲶芶咲畑垅𰻝𰻞"
    blacklist: []
  - option: s2t
    base: f
    addlist: []
    blacklist: []
```

**超级替换 Lua**：替代内置 OpenCC，支持候选词的动态替换和追加。

数据文件（`.txt`）使用 Tab 分隔：`匹配内容[Tab]替换内容1|替换内容2`

| 模式 | 行为 | 示例 |
| --- | --- | --- |
| `append` | 在原词后追加新候选 | `哈哈` → `1.哈哈 2.😄` |
| `replace` | 直接替换原词 | `软件` → `軟體` |
| `comment` | 仅在注释中提示 | `hello` → `hello〔你好〕` |
| `abbrev` | 匹配输入编码而非文本 | `zm` → `1.怎么 2.在吗` |

**手动排序 Lua**：Ctrl+J 向左，Ctrl+K 向右，Ctrl+L 移除排序，Ctrl+P 置顶。支持多设备同步（通过 `/sync` 目录）。

**Pro 版开启自动调频**：在 `wanxiang_pro.custom.yaml` 中添加：

```yaml
  enable_user_dict: true
```

---

## 自定义词库

### 固定词库

**packs 方式**：确保外部词库文件名 `userxx.dict.yaml` 与内部 `name: userxx` 一致：

```yaml
patch:
  translator/packs/+:
    - userxx
```

**重命名方式**：将 `wanxiang.dict.yaml` 重命名为 `wanxianguser.dict.yaml`（避免更新覆盖），并更新所有方案文件中的引用：

```yaml
patch:
  translator/dictionary: wanxianguser
  user_dict_set/dictionary: wanxianguser
  add_user_dict/dictionary: wanxianguser
```

### 用户词库迁移

同步目录默认为用户目录下的 `/sync`，可在 `installation.yaml` 中自定义：

```yaml
# Linux / macOS / Android
sync_dir: "/home/amz/sync"

# Windows
sync_dir: "D:\\home\\amz\\sync"
```

点击右键菜单"同步用户数据"后，词库以 `设备名/wanxiang.userdb.txt` 格式导出到同步目录。将 txt 文件在设备间共享后再次同步即可合并数据。

词库中预处理格式必须与万象编码完全一致，可使用[词库刷拼音辅助码工具](https://github.com/amzxyz/RIME-LMDG/releases/tag/tool)处理。

---

## 反馈与问题

- [万象词库问题收集反馈表](https://docs.qq.com/smartsheet/DWHZsdnZZaGh5bWJI?viewId=vUQPXH&tab=BB08J2)
- [为什么 Pro 版默认关闭调频](https://github.com/amzxyz/RIME-LMDG/wiki/%E4%B8%BA%E4%BB%80%E4%B9%88%E8%A6%81%E5%85%B3%E9%97%AD%E8%B0%83%E9%A2%91%E4%BB%A5%E5%8F%8A%E4%B8%8E%E4%B9%8B%E5%85%B3%E8%81%94%E7%9A%84%E6%8E%AA%E6%96%BD%E6%9C%89%E5%93%AA%E4%BA%9B)
