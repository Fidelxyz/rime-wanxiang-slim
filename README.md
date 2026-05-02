# 万象拼音输入方案精简版

[![Test](https://github.com/Fidelxyz/rime-wanxiang-slim/actions/workflows/test.yml/badge.svg)](https://github.com/Fidelxyz/rime-wanxiang-slim/actions/workflows/test.yml) _测试由 [Mira / 韻鏡](https://github.com/rimeinn/mira) 驱动_

<blockquote>
<p align="center"><em><strong>You don't pay for what you don't use.</strong></em></p>

<p align="center"><em><strong>只为你所需的功能买单。</strong></em></p>
</blockquote>

这是源自于 C++ 的[零开销（Zero-overhead）](https://en.cppreference.com/w/cpp/language/Zero-overhead_principle.html)设计哲学。

原版[万象拼音输入方案](https://github.com/amzxyz/rime_wanxiang)涵盖了丰富的功能，在“对标大厂体验”的同时也引入了具有“大厂风味”的庞大臃肿：其中大部分与输入无关的功能不会被绝大多数用户使用（我为什么要在一个输入法中计算时辰，且[该功能花费了超 3000 行代码来实现](https://github.com/amzxyz/rime_wanxiang/blob/v15.7.0/lua/wanxiang/shijian.lua)？），却依旧会带来潜在的性能负担。此外，其“低内聚、高耦合”的混乱架构设计[^1]也增加了用户的自定义难度及开发者的维护难度。

该 Fork 作为一个**专注于输入**的精简分支，移除了原版中与输入无关的功能，遵循 [SOLID 原则](https://en.wikipedia.org/wiki/SOLID)重构了代码架构，并为全部 Lua 代码添加了完整的类型注解。该 Fork 由科班程序员维护，定期同步上游更新，逐步重写原版由 LLM 生成的低效代码，提供更轻量高效的输入体验。同时，该 Fork 重写了原版混乱的说明文档，为用户提供更低的上手门槛和更好的自定义体验。

[^1]: [“高内聚、低耦合”](https://baike.baidu.com/item/%E9%AB%98%E5%86%85%E8%81%9A%E4%BD%8E%E8%80%A6%E5%90%88/5227009)是软件工程中的设计原则，指模块内部的元素应该紧密相关（高内聚），而模块之间的依赖关系应该尽量减少（低耦合）。此处“低内聚、高耦合”为其反义词。原版万象拼音输入方案采用了大量“超级模块”的设计，将互不相关的功能混杂在同一个模块中，而实现单个功能的代码却分散在各处，以毫无必要的方式增加了代码的复杂度和维护难度。

<details>
<summary>
已移除功能列表
</summary>
<br>

输入相关：
- 声调辅助筛选：用 <kbd>7</kbd><kbd>8</kbd><kbd>9</kbd><kbd>0</kbd> 数字键代表四声辅助筛选
- 辅筛定点改字：通过辅助码修改候选长句中的特定字
- 成对符号包裹：输入末尾追加 `\` + 映射键，将候选词用符号对包裹
- 量词预测调频：输入数字后提升单字量词权重
- 固定已输入语句：按下句号锁定当前候选，双击句号锁定上一次 N-1 字候选
- 候选排序 —— 受 Rime 接口限制，上游实现存在较大问题，因此暂时移除，可使用用户短语替代

快捷短语相关：
- 快符输入：单字母 + `/` 上屏自定义符号
- 符号输入：`/` 前缀触发特殊符号候选
- 时间日期输入
- 中文大写数字输入
- 中英翻译
- 短语格式化：自定义短语中重复字符与动态变量（时间、日期等）格式化

提示相关：
- 超级 Tips：表情、化学式、翻译等提示
- 编码音调显示
- 计算器
- 输入统计
- 版本显示

特殊布局相关：
- T9 九宫格方案
- 14 键 / 18 键

</details>

## 版本对比

标准版与 Pro 版本的主要区别在于是否支持**辅助码**筛选。

|  | 标准版 (Base) | 增强版 (Pro) |
| --- | --- | --- |
| **辅助码** | **不适用** | **9 种辅助码可选**，支持**直接引导**或**间接引导** |
| **自动调频** | 默认开启 | 默认关闭 |
| **用户词记录** | 自动记录 | 手动造词（` `` ` 引导）或无感造词 |

## 支持方案

支持**任意组合**以下拼音方案与辅助码方案。

**拼音方案**：

- 全拼
- 自然码
- 智能ABC
- 小鹤双拼
- 微软双拼
- 搜狗双拼
- 紫光双拼
- 国标双拼
- 拼音加加
- 乱序17
- 自然龙（反查为全拼）
- 汉心龙（反查为全拼）

**辅助码方案**：

- 自然码
- 小鹤形码
- 墨奇码
- 汉心码
- 五笔前二
- 虎码首末
- 首右码
- 首右+
- 万象码

## 快速开始

如果你不熟悉 Rime 基础概念（用户目录、部署等），建议先阅读以下文档：

- [Oh My Rime - Rime 安装指南](https://www.mintimate.cc/zh/guide/installRime.html)
- [Rime 参数配置详解](https://xishansnow.github.io/posts/41ac964d.html)

> [!TIP]
> 万象有独特的自动化配置逻辑，建议先按以下步骤完整运行，体验功能后再进行定制。

### 1. 安装

1. 从 [Release](https://github.com/Fidelxyz/rime-wanxiang-slim/releases) 页面下载方案文件。
2. 将解压后的文件放入 Rime **用户目录**。
3. 点击“重新部署”。

### 2. 切换输入方案

在输入状态下，输入以下由 `/` 引导的指令切换对应方案。切换后需**重新部署**。

**切换拼音方案**：

| 指令 | 方案 |
| --- | --- |
| `/pinyin` | 全拼 |
| `/zrm` | 自然码 |
| `/znabc` | 智能ABC |
| `/flypy` | 小鹤双拼 |
| `/mspy` | 微软双拼 |
| `/sogou` | 搜狗双拼 |
| `/ziguang` | 紫光双拼 |
| `/gbpy` | 国标双拼 |
| `/pyjj` | 拼音加加 |
| `/lxsq` | 乱序17 |
| `/zrlong` | 自然龙（反查为全拼） |
| `/hxlong` | 汉心龙（反查为全拼） |

**切换辅助码引导模式**：

| 指令 | 方案 |
| --- | --- |
| `/jjf` | 间接辅助 |
| `/zjf` | 直接辅助 |

<details>
<summary>
⚠️ <strong>iOS 平台方案切换步骤</strong>
</summary>
<br>

**仓输入法 (Hamster)**

1. 「仓设置 → 输入方案设置 → 右上角 `+` → 方案下载」，下载万象方案并切换。
2. 在输入法界面长按 `/`（不要上划），输入上述方案切换指令。
3. 「仓设置 → 文件管理 → **使用键盘文件覆盖应用文件**」。（如启用了 iCloud 同步功能，需另外执行「仓设置首页 -> iCloud同步 -> **拷贝应用文件至iCloud**」。）
4. 「仓设置 → RIME → 重新部署」。

**元书输入法 (Hamster3)**

1. 从 `RimeSharedSupport` 目录复制 `include_keyboard_rime_files.txt` 到万象方案目录。
2. 在文件底部追加：

    ```
    ^.*[.]custom.*$
    ```

</details>

### 3. 安装语法模型（推荐）

下载语法模型文件，放置于 Rime **用户目录根目录**，无需额外配置。

> 语法模型为静态二进制文件，大小固定，CPU 计算为主，内存占用极低。

<details>
<summary>
⚠️ <strong>Android 用户注意事项（Fcitx5 等前端）</strong>
</summary>
<br>

部分安卓前端的数据存储在 `/data` 目录下，受严格权限控制。

**不要**使用 MT 管理器等工具直接复制文件，这会导致由权限不一致引发的读取失败。

须使用输入法 App 自带的“导入文件”功能；或（Root 用户）手动复制后使用 `chown` 和 `chmod` 修正权限。

</details>

### 4. 使用补丁文件自定义

`*.custom.yaml` 是对方案文件的补丁，属于个人私有配置，**不会被升级覆盖**。

custom 文件须位于**用户目录根目录**（`*.schema.yaml` 旁）。通过 `/` 指令切换方案时，脚本已自动将模板从 `custom` 文件夹复制到根目录完成初始化。

> [!CAUTION]
> 不要直接修改 `custom` 文件夹中的文件，该文件夹为模板仓库，修改不会生效。

补丁对应关系：

| Custom 文件 | 对应方案文件 | 用途 |
| --- | --- | --- |
| `wanxiang.custom.yaml` | `wanxiang.schema.yaml` | [仅基础版] 输入方案配置 |
| `wanxiang_pro.custom.yaml` | `wanxiang_pro.schema.yaml` | [仅 Pro 版] 输入方案配置 |
| `default.custom.yaml` | `default.yaml` | 全局配置 |
| `squirrel.custom.yaml` | `squirrel.yaml` | Squirrel 鼠须管前端配置 |
| `weasel.custom.yaml` | `weasel.yaml` | Weasel 小狼毫前端配置 |

如需自定义，请查阅对应的**方案文件**找到需要修改的选项，并在补丁文件下的 `patch` 项下添加补丁项。详见 [**Rime Custom Patch 语法指南**](PATCH_GUIDE.md) 及 [Rime 定制指南](https://github.com/rime/home/wiki/CustomizationGuide)。

> [!IMPORTANT]
> 不要在 `default.custom.yaml` 中修改输入方案配置。所有方案相关修改（模糊音、快捷键等）应针对具体 `schema` 进行 patch，`default` 文件建议交由输入法前端自动管理。

## 安装与更新工具

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
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-base:plum/full
    ```
    </details>

    <details>
    <summary>基础版（仅词库）</summary>

    ```bash
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-base:plum/dicts
    ```
    </details>

    <details>
    <summary>自然码辅助版（完整）</summary>

    ```bash
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-zrm-fuzhu:plum/full
    ```
    </details>

    <details>
    <summary>自然码辅助版（仅词库）</summary>

    ```bash
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-zrm-fuzhu:plum/dicts
    ```
    </details>

    <details>
    <summary>小鹤形码辅助版（完整）</summary>

    ```bash
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-flypy-fuzhu:plum/full
    ```
    </details>

    <details>
    <summary>小鹤形码辅助版（仅词库）</summary>

    ```bash
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-flypy-fuzhu:plum/dicts
    ```
    </details>

    <details>
    <summary>墨奇码辅助版（完整）</summary>

    ```bash
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-moqi-fuzhu:plum/full
    ```
    </details>

    <details>
    <summary>墨奇码辅助版（仅词库）</summary>

    ```bash
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-moqi-fuzhu:plum/dicts
    ```
    </details>

    <details>
    <summary>汉心码辅助版（完整）</summary>

    ```bash
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-hanxin-fuzhu:plum/full
    ```
    </details>

    <details>
    <summary>汉心码辅助版（仅词库）</summary>

    ```bash
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-hanxin-fuzhu:plum/dicts
    ```
    </details>

    <details>
    <summary>五笔前二辅助版（完整）</summary>

    ```bash
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-wubi-fuzhu:plum/full
    ```
    </details>

    <details>
    <summary>五笔前二辅助版（仅词库）</summary>

    ```bash
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-wubi-fuzhu:plum/dicts
    ```
    </details>

    <details>
    <summary>虎码首末辅助版（完整）</summary>

    ```bash
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-tiger-fuzhu:plum/full
    ```
    </details>

    <details>
    <summary>虎码首末辅助版（仅词库）</summary>

    ```bash
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-tiger-fuzhu:plum/dicts
    ```
    </details>

    <details>
    <summary>首右码辅助版（完整）</summary>

    ```bash
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-shouyou-fuzhu:plum/full
    ```
    </details>

    <details>
    <summary>首右码辅助版（仅词库）</summary>

    ```bash
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-shouyou-fuzhu:plum/dicts
    ```
    </details>

    <details>
    <summary>首右+辅助版（完整）</summary>

    ```bash
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-shyplus-fuzhu:plum/full
    ```
    </details>

    <details>
    <summary>首右+辅助版（仅词库）</summary>

    ```bash
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-shyplus-fuzhu:plum/dicts
    ```
    </details>

    <details>
    <summary>万象码辅助版（完整）</summary>

    ```bash
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-shyplus-fuzhu:plum/full
    ```
    </details>

    <details>
    <summary>万象码辅助版（仅词库）</summary>

    ```bash
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-shyplus-fuzhu:plum/dicts
    ```
    </details>

## 扩展词库

部分扩展数据未默认启用，可按需开启：

| 文件名 | 用途 | 安装方式 |
| --- | --- | --- |
| `renming.dict.yaml` | 人名词库 | 在 `wanxiang.dict.yaml` 中取消注释 `dicts/renming` |
| `wuzhong.dict.yaml` | 物种词库 | 在 `wanxiang.dict.yaml` 中取消注释 `dicts/wuzhong` |
| `custom_phrase.txt` | 自定义短语 | 复制 `custom/custom_phrase.txt` 到根目录，并添加自定义短语内容 |

## 功能详解

### 辅助码

#### 直接辅助码（仅 Pro 版）

在双拼编码后直接追加辅助码。例如输入“镇”：双拼 `vf` + 首位辅助码 `j` → `vfj`，如候选未出现可继续追加第二位辅助码。

**重码处理**：

- 当"双拼 + 辅码"与现有词组重码时（均为 4 码），优先显示词组。
- 在编码末尾追加 `/` 可强制聚拢辅助码，优先展示单字。
- 以大写输入任意一位辅助码，即可强制聚拢为单字。如：`niRE` / `nirE` / `niRe` 均表示双拼 `ni` + 辅助码 `re`。

#### 间接辅助码（仅 Pro 版）

使用 `/` 作为分隔符引导辅助码，格式：`拼音/辅码`。例如：双拼 `ni` + 辅助码 `re` → `ni/re`。

不输入 `/` 则视为普通拼音，不干扰整句切分。

### 辅助筛选

输入拼音后输入反查符 `` ` ``，再输入辅助码进行二次筛选。

- 单字：支持两分（`` ni`re ``）、多分（`` mu`ckrida ``）、笔画（`` ni`pspzhpd ``）。
- 词组：匹配辅助码序列的任意非空子字符串。

### 反查

输入反查符 `` ` ``，再输入部件的拼音编码，从部件查找目标字。

> **示例**：输入 `` ` `` 后输入“雨”和“辰”的双拼编码 `yu if`，可找到“震”字并显示辅助码。

配置项：`lookup_filter`。笔画反查模式需在 `wanxiang_reverse.custom.yaml` 中配置 `speller/algebra`。

### 造词

**手动造词（仅 Pro）**：通过 ` `` ` 引导进入造词模式；编码后双击 ` `` ` 可在不删除编码的情况下后触发造词；次选词上屏后自动记录。配置项：`add_user_dict`。

**自动造词（仅 Pro）**：关闭调频时，选字上屏会自动记录不在词库中的词条。配置项：`add_user_dict/enable_auto_phrase`。

**英文造词**：英文编码末尾输入 `\\` 触发英文造词，记录到 `en.userdb`。

### 提示

**错音错字提示**：输入常见错误读音时提示正确读音。配置项：`super_comment/correction_enabled`。

**辅助码提示（仅 Pro）**：显示候选词的辅助码提示，<kbd>Ctrl</kbd>+<kbd>A</kbd> 循环切换辅助码提示 / 声调全拼提示 / 关闭注释，<kbd>Ctrl</kbd>+<kbd>C</kbd> 开启拆分辅助提示。

### 候选排序

**自动调频**：默认关闭，配置项：`translator/enable_user_dict`。

**输入预测**：上屏后弹出预测候选（推荐仅在手机端开启），或置顶预测候选词。配置项：`user_predict`。

### 字符集过滤

可通过开关切换字符集范围（通用规范、GB2312、GBK、Big5、简繁体等），<kbd>Ctrl</kbd>+<kbd>G</kbd> 快捷切换。支持联动简繁转换开关，对不同开关单独配置字符集范围和黑白名单。配置项：`charset_filter`。

### 输入预测

根据上文输入置顶预测词或主动弹出预测词。

**联想空格打断**：空格键打断联想并上屏空格。配置项：`super_processor/enable_predict_space` / `user_predict/enable_predict_space`。

### 非汉字词库输入

**英文输入**：支持整句英文输入、自动句中空格、首字母/全大写格式化、空码补全。

**混合词输入**：支持包含字母、汉字、数字、特殊符号的混合词输入。

**短码英文词前置**：输入编码末尾追加 `/` 可前置短码英文词候选。

### 其他功能

**空码回溯**：输入编码无候选时，显示上一次候选，可直接空格上屏，减少回删操作。

**Unicode 输入**：`U` + Unicode 编码输入对应字符。配置项：`recognizer/patterns/unicode`。

**短语格式化**：将 `custom_phrase.txt` 中的 `\n`、`\s`、`\t` 解析为换行、空格、制表符。

**循环切换分词**：多次按下分词键 <kbd>'</kbd> 循环切换分词模式。配置项：`manual_segmentor`。

**小键盘行为**：小键盘不直接上屏。配置项：`keypad_composer`。

**删除键限制**（仅 Weasel 小狼毫生效）：输入中持续删除至编码为空时，阻止删除已上屏内容。配置项：`super_processor/enable_backspace_limit`。

**输入长度限制**：限制重复按键输入或分词过多的编码。配置项：`super_processor/limit_repeated`。

**候选词部分上屏**：<kbd>Ctrl</kbd> + 数字键上屏首选前 N 字，并保留后续编码。

### RIME 内建功能

**用户词删除**：<kbd>Ctrl</kbd>+<kbd>Del</kbd> 软删除用户词。

**循环切换音节**：多次按 <kbd>Tab</kbd> 循环切换分词位置，<kbd>Ctrl</kbd>+<kbd>Tab</kbd> 逐字确认。配置项：`key_binder`。

**自动上屏**：三四位简码唯一时自动上屏。默认关闭，配置项：`speller/auto_select`。

**数字后自动半角**：中文状态下数字后输入符号自动转换为半角标点。默认关闭，配置项：`punctuator/digit_separators`、`punctuator/digit_separator_action`。

## 自定义词库

### 固定词库

**packs 方式**：新建 `your_user_dict.dict.yaml`，并添加 `translator/packs` 配置项：

```yaml
patch:
  translator/packs/+:
    - your_user_dict
```

**重命名方式**：将 `wanxiang.dict.yaml` 重命名为 `your_user_dict.dict.yaml`（避免更新覆盖），并更新所有方案文件中的引用：

```yaml
patch:
  translator/dictionary: your_user_dict
  user_dict_set/dictionary: your_user_dict
  add_user_dict/dictionary: your_user_dict
```

### 用户词库迁移

同步目录默认为用户目录下的 `/sync`，可在 `installation.yaml` 中自定义：

```yaml
# Linux / macOS / Android
sync_dir: "/home/username/sync"

# Windows
sync_dir: "D:\\home\\username\\sync"
```

点击输入法菜单「同步用户数据」后，词库以 `<设备名>/wanxiang.userdb.txt` 格式导出到同步目录。将 txt 文件在设备间共享后再次同步即可合并数据。

词库格式须与万象词库格式一致，可使用[词库刷拼音辅助码工具](https://github.com/amzxyz/RIME-LMDG/releases/tag/tool)处理。
