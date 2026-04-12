# 万象拼音 — 功能与实现位置映射

本文档列出 README.md 中提到的所有功能，并映射到对应的实现文件。

---

## 核心功能亮点

### 全能拼音标注（带声调词库）

所有词语自带音调，支持多种带调方案、声调注释显示。

| 实现位置 | 说明 |
|----------|------|
| `dicts/*.dict.yaml` | 带声调拼音标注的词库数据 |
| `wanxiang_algebra.yaml` | 声调拼音到输入编码的转写规则（12+ 拼音方案） |
| `lua/wanxiang/super_comment_preedit.lua` | 声调注释显示 |

### 极致权重与分词

首选权重与分词片段最优解，结合语法模型（外部 `.gram` 二进制文件）。

| 实现位置 | 说明 |
|----------|------|
| `wanxiang.schema.yaml` | `translator` 配置，语法模型路径与权重设置 |
| `dicts/*.dict.yaml` | 词频数据 |
| 外部语法模型文件 (`.gram`) | 用户手动安装的静态二进制模块 |

### 深度反查系统

支持两分、多分、笔画三种反查方式，覆盖 Unicode 17 标准。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/super_lookup.lua` | 输入后反查（候选筛选）、辅助码反查 |
| `wanxiang_reverse.schema.yaml` | 输入前反查（拆字/笔画反查方案定义） |
| `wanxiang_reverse.dict.yaml` | 反查字典数据 |
| `wanxiang.schema.yaml` (`lookup_filter` 段) | 反查系统配置（引导符、数据源优先级） |
| `wanxiang_algebra.yaml` (`reverse/` 段) | 反查专用的拼写转写规则 |

### 全面辅码兼容

头部全拼编码 + 辅助码任意组合，内置 6 种主流辅码。

| 实现位置 | 说明 |
|----------|------|
| `custom/wanxiang_pro.schema.yaml` | PRO 版方案（辅码功能仅 PRO 版） |
| `lua/wanxiang/super_comment_preedit.lua` | 辅助码注释提示（Ctrl+A 循环切换） |
| `custom/wanxiang_chaifen_*.dict.yaml` | 7 种辅码拆分字典（自然码、墨奇、鹤形、虎码、五笔、汉心、首右） |
| `custom/wanxiang_chaifen.schema.yaml` | 辅码拆分反查方案 |

---

## 功能一览

### 辅助码系统

#### 直接辅助码（仅 PRO 版）

双拼后直接追加辅助码，4 码末尾追加 `/` 强制单字优先。

| 实现位置 | 说明 |
|----------|------|
| `custom/wanxiang_pro.schema.yaml` | PRO 方案中的辅助码编码配置 |
| `custom/wanxiang_pro.dict.yaml` | 携带辅助码的 PRO 词库（格式：`字 拼音;辅码 词频`） |
| `wanxiang_algebra.yaml` | `/` 引导辅助码聚拢的转写规则 |

#### 间接辅助码（仅 PRO 版）

使用 `/` 分隔符引导辅助码（格式：`拼音/辅码`）。

| 实现位置 | 说明 |
|----------|------|
| `custom/wanxiang_pro.schema.yaml` | 间接辅助码 speller 配置 |
| `wanxiang_algebra.yaml` | 间接辅助码转写规则 |

#### 大写辅助筛选

输入辅助码时可穿插小写、大写定位。

| 实现位置 | 说明 |
|----------|------|
| `wanxiang_algebra.yaml` | 大小写转写规则 |

### 反查系统

#### 候选筛选（输入后反查）

输入主拼音后按 `` ` `` 引导二次筛选（部首、两分、多分、笔画）。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/super_lookup.lua` | 候选筛选核心逻辑，支持 aux/db 双数据源 |
| `wanxiang.schema.yaml` (`lookup_filter` 段) | 反查配置（引导符、tags、数据源优先级） |

#### 输入前反查

通过 `` ` `` 引导拆字/笔画模式（如 `` `yu if `` 查找"震"）。

| 实现位置 | 说明 |
|----------|------|
| `wanxiang_reverse.schema.yaml` | 拆分与笔画反查方案定义 |
| `wanxiang_reverse.dict.yaml` | 反查字典数据 |
| `wanxiang.schema.yaml` | `reverse_lookup` 段与 `affix_segmentor` 配置 |

### 英文方案

整句英文输入、自动句中空格、首字母/全大写格式化、空码补全（`~` 标记）。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/english_filter.lua` | 英文全能过滤器：格式化、智能加空格、大小写、空码补全 |
| `wanxiang_english.schema.yaml` | 英文输入方案定义 |
| `wanxiang_english.dict.yaml` | 英文词典数据 |
| `dicts/en.dict.yaml` | 英文词条 |
| `wanxiang_algebra.yaml` (`english` 段) | 英文输入转写规则 |

#### 英文智能加空格

支持 off/before/after/smart 四种策略，超时销毁、路径优化。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/english_filter.lua` | 加空格全部逻辑（smart 模式、超时、路径检测） |
| `wanxiang.schema.yaml` (`english_filter` 段) | 加空格策略配置项 |

### 英文数字字母汉字混合输入

字母、汉字、数字、特殊符号组合输入（如 `1000wclips`、`AD钙奶`、`Type-C`）。

| 实现位置 | 说明 |
|----------|------|
| `wanxiang_mixedcode.schema.yaml` | 混合编码方案定义 |
| `wanxiang_mixedcode.dict.yaml` | 混合编码词典 |
| `dicts/cn&en.dict.yaml` | 中英混合词条 |
| `wanxiang_algebra.yaml` (`mixed` 段) | 混合编码转写规则 |

### Unicode 输入

大写 `U` 开头输入 Unicode 码点（如 `U62fc` 得到"拼"）。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/unicode.lua` | Unicode 字符翻译器 |
| `wanxiang.schema.yaml` | recognizer 中 `unicode` 模式配置 |

### 自动上屏

三位/四位简码唯一时自动上屏。

| 实现位置 | 说明 |
|----------|------|
| `wanxiang.schema.yaml` | `speller` 段 `auto_select` 与 `auto_select_pattern` 配置（默认注释关闭） |

### 空码回溯

前面编码有候选但继续输入无候选时，显示上一次候选并标注 `~`。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/super_filter.lua` | 3 码回退逻辑，空码候选恢复与 `~` 标注 |
| `lua/wanxiang/english_filter.lua` | 英文场景的空码补全 |

### 数字后自动半角

中文状态输入数字后立即输入 `,` `.` 自动转换为数字分割符。

| 实现位置 | 说明 |
|----------|------|
| `wanxiang.schema.yaml` | `punctuator/digit_separators` 配置 |

### 错音错字提示

输入常见错读词时提示正确读音（如"给予"提示 `jǐ yǔ`）。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/super_comment_preedit.lua` | 错音纠正注释逻辑 |
| `dicts/cuoyin.dict.yaml` | 错音词条数据 |

### 短语格式化

自定义短语中 `\n` `\s` `\t` 等转换为实际换行/空格/制表符。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/super_filter.lua` | 转义序列格式化逻辑 |
| `custom_phrase.txt` (用户目录) | 自定义短语数据源 |

### 辅助码提示（仅 PRO）

任意长度候选词的辅助码提示，Ctrl+a 循环切换（辅助码/关闭），Ctrl+c 拆分提示。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/super_comment_preedit.lua` | 注释显示模块：辅助码提示、拆分提示 |
| `custom/wanxiang_chaifen.schema.yaml` | 拆分反查方案 |
| `custom/wanxiang_chaifen_*.dict.yaml` | 7 种辅码拆分字典 |

### 用户按需造词（仅 PRO）

`` `` `` 引导主动造词，支持后触发造词与次选造词。

| 实现位置 | 说明 |
|----------|------|
| `custom/wanxiang_pro.schema.yaml` | PRO 方案中用户词配置 |
| `wanxiang.schema.yaml` | `user_dict_set` 段与 `add_user_dict` 段 |

### 中文无感造词（仅 PRO）

关闭调频下通过逐步选字选词上屏记录整段，不产生小碎片。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/auto_phrase.lua` | 自动造词模块 |
| `wanxiang.schema.yaml` | `add_user_dict` 段配置 |

### 英文造词

英文输入编码末尾输入指定符号（默认 `\\`）触发英文造词，记录到 `en.userdb`。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/english_filter.lua` | 英文造词逻辑（`trigger` 配置可自定义触发符） |
| `wanxiang.schema.yaml` | `english_filter` 段 `trigger` 配置 |

### 简码系统（Super Replacer 简码模式）

公共简码与用户自定义简码，支持 `abbrev_rule` 参数控制简码规则，单开关控制启用/禁用，成语库已合并。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/super_replacer.lua` | 简码处理逻辑（`abbrev` 类型规则） |
| `lua/data/abbrev.txt` | 公共简码数据 |
| `lua/data/chengyu.txt` | 成语数据（约 23k 行） |
| `wanxiang.schema.yaml` | `abbrev` 开关、`abbrev_rule` 参数配置 |
| `custom/wanxiang.custom.yaml` 等 | 用户简码配置模板 |

### 联想空格打断功能

空格键打断联想并上屏空格，对齐大厂输入法行为。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/super_processor.lua` | `predict_space` 配置与打断逻辑 |
| `wanxiang.schema.yaml` | `super_processor/predict_space` 配置项 |

### 用户词删除

Ctrl+Del 标记用户词为不使用（假性删除）。

| 实现位置 | 说明 |
|----------|------|
| Rime 引擎内置功能 | `Ctrl+Delete` 是 Rime 原生用户词删除快捷键 |

### 字符集过滤

可配置字符集规则，支持多选项并集、黑白名单、简繁联动，二进制滤镜数据库。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/charset_filter.lua` | 字符集过滤模块 |
| `lua/data/charset.reverse.bin` | 二进制字符集标记数据库 |
| `wanxiang.schema.yaml` | `charset` 段配置（option、base、whitelist、blacklist） |

### 超级替换（Super Replacer）

替代 OpenCC 的增强组件，支持 append/replace/comment/abbrev 四种模式，链式/并行处理。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/super_replacer.lua` | 超级替换模块，LevelDB 数据库 `lua/replacer.userdb` |
| `lua/data/emoji.txt` | Emoji 数据 |
| `lua/data/abbrev.txt` | 公共简码数据 |
| `lua/data/STCharacters.txt` | 简繁单字转换 |
| `lua/data/STPhrases.txt` | 简繁词组转换 |
| `lua/data/HKVariants.txt` | 香港繁体变体 |
| `lua/data/TWVariants.txt` | 台湾繁体变体 |
| `lua/data/others.txt` | 其他替换数据 |
| `wanxiang.schema.yaml` | `super_replacer` 段配置（rules、chain、db_name 等） |

### 手动排序

Ctrl+J/K/L/P 手动调整候选排序，支持多设备同步。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/sequencer.lua` | 手动排序模块，LevelDB 数据库 `lua/sequence.userdb` |
| `wanxiang.schema.yaml` | 排序快捷键配置 |

### 小键盘有妙用

auto 模式/compose 模式下的数字键行为控制。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/super_processor.lua` | KP（数字小键盘）映射处理（`KP_MAP`） |
| `wanxiang.schema.yaml` | 小键盘相关配置 |

### 删除键限制

输入中持续删除至编码为 0 时卡住，防止误删已上屏内容。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/super_processor.lua` | Backspace 限制逻辑 |

### 输入长度限制

重复输入 8 个相同字母或分词片段超过 30 个时限制。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/super_processor.lua` | `MAX_REPEAT` / `MAX_SEGMENTS` 限制逻辑 |

### Tab 循环切换音节

多次按 Tab 循环切换分词位置，Ctrl+Tab 逐字确认。

| 实现位置 | 说明 |
|----------|------|
| `wanxiang.schema.yaml` | `key_binder/bindings` 中 Tab/Ctrl+Tab 配置 |

### 循环切换分词

多次按下分词键 <kbd>'</kbd> 循环切换分词模式。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/manual_segmentor.lua` | 循环分词处理器 |

### 候选切割机

Ctrl+1~0 上屏首选前 N 个字，保留后续编码。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/partial_commit.lua` | 部分上屏处理器 |

### 万能键斜杠 `/`

辅助码聚拢、间接辅助码引导、短码英文前置、双击上屏斜杠。

| 实现位置 | 说明 |
|----------|------|
| `wanxiang_algebra.yaml` | `/` 相关的转写规则（辅助码聚拢、英文前置） |
| `lua/wanxiang/super_processor.lua` | 双击斜杠 |
| `wanxiang.schema.yaml` | 斜杠相关的 speller/recognizer 配置 |

### 输入预测

根据上文输入主动弹出预测词或被动置顶预测词。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/user_predict.lua` | 输入预测模块 |

---

## 方案与版本

### 方案切换

通过 `/flypy`、`/zrm` 等指令切换双拼/全拼方案（共 15 种）。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/set_schema.lua` | 方案切换翻译器，自动修改 custom 文件 |
| `wanxiang_algebra.yaml` | 12+ 拼音方案的转写规则 |
| `custom/` 目录 | custom 文件模板 |

### 版本对比（标准版 vs PRO 版）

| 实现位置 | 说明 |
|----------|------|
| `wanxiang.schema.yaml` | 标准版方案定义 |
| `custom/wanxiang_pro.schema.yaml` | PRO 版方案定义 |
| `custom/wanxiang_pro.dict.yaml` | PRO 版词库（带辅助码） |
| `custom/wanxiang_pro.custom.yaml` | PRO 版自定义模板 |

---

## 配置与数据管理

### 正则增强按键绑定

基于正则匹配当前输入编码绑定不同按键动作。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/key_binder.lua` | 正则增强按键绑定处理器 |
| `wanxiang.schema.yaml` | `key_binder/bindings` 段配置 |

### 自定义短语

`custom_phrase.txt` 实现编码到自定义输出的映射。

| 实现位置 | 说明 |
|----------|------|
| `wanxiang.schema.yaml` | `custom_phrase` 翻译器配置 |
| `custom_phrase.txt` (用户目录) | 用户自定义短语数据 |

### 自定义词库

通过 packs 法或重命名法扩展词库。

| 实现位置 | 说明 |
|----------|------|
| `wanxiang.dict.yaml` | 主词库清单（import_tables 引用子词库） |
| `dicts/` 目录 | 全部子词库文件 |

---

## 共享基础设施

| 文件 | 说明 |
|------|------|
| `lua/wanxiang/wanxiang.lua` | 共享工具库：设备检测、正则解析、中文判断、UTF-8 工具 |
| `lua/wanxiang/userdb.lua` | UserDb 封装库：元数据操作、弱引用池、迭代器 |
| `lua/librime.lua` | Rime API 类型标注（仅用于 IDE 提示，非运行时代码） |
| `default.yaml` | Rime 全局设置（方案列表、菜单、切换器） |
| `weasel.yaml` | Windows 小狼毫前端配置 |

---

## CI / 构建脚本

### PRO 辅助码词库生成脚本（`aux_go.py`）

将通用词库与辅助码表合并，生成 7 种辅码方案的 PRO 词库。

| 实现位置 | 说明 |
|----------|------|
| `.github/workflows/scripts/aux_go.py` | 主脚本 |
| `custom/aux_code.txt` | 辅助码源表（字 → 分号分隔的多方案辅码段） |
| `dicts/*.dict.yaml` | 输入词库（9 个文件，合计约 244 万行） |
| `pro-*-fuzhu-dicts/` | 各方案输出目录（7 个） |

#### 脚本设计要点

| 模块 | 说明 |
|------|------|
| `load_aux_table()` | 加载 `aux_code.txt`，返回 `字 → aux_list` 映射 |
| `build_schema_maps()` | 启动时为 7 个 schema 预计算 `字 → 辅码字符串` 扁平映射，消除运行期切片与 join |
| `tokenize_word()` | 用 `re.split`（单次 C 级操作）将词切分为汉字/非汉字块，替代逐字符 Python 循环 |
| `get_alignment()` | 迭代栈版对齐（替代递归）；纯汉字词走快速路径；一次计算所有 schema 的辅码 |
| `process_file_all_schemas()` | 每个输入文件只读一次，同时向 7 个输出文件写入，消除 7× 重复 I/O |
| `process_batch()` | 外层循环改为"按文件"而非"按 schema"，统筹调用上述函数 |

---

## 词库文件一览

| 文件 | 内容 |
|------|------|
| `dicts/zi.dict.yaml` | 单字表 |
| `dicts/jichu.dict.yaml` | 基础词组（2-3 字） |
| `dicts/lianxiang.dict.yaml` | 联想词组（5+ 字） |
| `dicts/cuoyin.dict.yaml` | 错音容错词条 |
| `dicts/duoyin.dict.yaml` | 多音字兼容 |
| `dicts/shici.dict.yaml` | 诗词 |
| `dicts/diming.dict.yaml` | 地名 |
| `dicts/renming.dict.yaml` | 人名（可选） |
| `dicts/wuzhong.dict.yaml` | 物种（可选） |
| `dicts/en.dict.yaml` | 英文词条 |
| `dicts/cn&en.dict.yaml` | 中英混合词条 |
| `dicts/chengyu.txt` | 成语数据 |

---

## 已移除功能

以下功能已从本仓库中移除。保留记录以便从上游合并时参考。

### 超级 Tips

表情、化学式、翻译、简码提示等，通过自定义按键直接上屏，不占候选框。

| 已删除文件/配置 | 说明 |
|-----------------|------|
| `lua/wanxiang/super_tips.lua` | Tips 系统，LevelDB 数据库 `lua/tips.userdb` |
| `lua/data/tips_show.txt` | Tips 自带数据 |
| `lua/data/tips_user.txt预留自定义文件` | Tips 用户自定义数据 |
| `wanxiang.schema.yaml` 等 | `tips` 段配置（`disabled_types`、`tips_key`）、Ctrl+t 开关、`super_tips` 开关与处理器 |

### 快符输入

单字母 + `/` 快速上屏自定义符号（如 `a/` 上屏"！"），支持 `repeat` 重复上屏。

| 已删除文件/配置 | 说明 |
|-----------------|------|
| `lua/wanxiang/super_processor.lua` | 快符处理逻辑（`quick_symbol_text` 映射、拦截与自动上屏） |
| `wanxiang.schema.yaml` | `quick_symbol_text` 配置段 |
| `custom/wanxiang_pro.schema.yaml` | `quick_symbol_text` 配置段 |
| `custom/wanxiang.custom.yaml` | `quick_symbol_text` 配置段（模板） |
| `custom/wanxiang_pro.custom.yaml` | `quick_symbol_text` 配置段（模板） |

### 声调辅助筛选

7890 数字键代表一二三四声，支持与辅助码混合使用。

| 已删除配置 | 说明 |
|------------|------|
| `wanxiang_algebra.yaml` | 声调数字(7890)到拼音声调的转写规则 |
| `wanxiang.schema.yaml` 等 | `alphabet` 中 7890、`tone_display`/`full_pinyin` 开关 |
| `lua/wanxiang/super_processor.lua` | 声调回退逻辑（在 7890 之间轮巡切换） |
| `lua/wanxiang/super_lookup.lua` | 反查中声调筛选与 `tone_map` 表 |

### 输入码音调显示

Ctrl+S 使输入码实时显示全拼并加音调，Shift+Enter 上屏编码字符串。

| 已删除配置 | 说明 |
|------------|------|
| `lua/wanxiang/super_comment_preedit.lua` | preedit 音调显示逻辑、`full_pinyin` 上屏功能 |
| `custom/wanxiang.custom.yaml` 等 | `tone_preedit` 配置段落 |

### 成对符号包裹

输入编码末尾追加 `\a` 等触发成对符号包裹（如 `\k` 映射 `《》`）。

| 已删除文件/配置 | 说明 |
|-----------------|------|
| `lua/wanxiang/super_filter.lua` | 成对符号包裹逻辑（`wrap_parts` 映射） |
| `lua/wanxiang/sequencer.lua` | 成对符号触发符读取与兼容缓存路径 |
| `wanxiang.schema.yaml` | `paired_symbols` 配置段 |
| `custom/wanxiang_pro.schema.yaml` | `paired_symbols` 配置段 |
| `custom/wanxiang.custom.yaml` | `paired_symbols` 配置段（模板） |
| `custom/wanxiang_pro.custom.yaml` | `paired_symbols` 配置段（模板） |

### 时间日期

多种日期时间格式输入。

| 已删除文件 | 说明 |
|------------|------|
| `lua/wanxiang/shijian.lua` | 时间日期翻译器 |

### 数字翻译

大小写中文数字转换。

| 已删除文件 | 说明 |
|------------|------|
| `lua/wanxiang/number_translator.lua` | 数字翻译器 |

### 符号输入方案

`/` 前缀触发特殊符号候选。

| 已删除文件 | 说明 |
|------------|------|
| `wanxiang_symbols.yaml` | 符号输入方案定义 |

### 计算器

输入数学表达式直接得到计算结果。

| 已删除文件 | 说明 |
|------------|------|
| `lua/wanxiang/super_calculator.lua` | 超级计算器 |

### 输入统计

统计用户输入字数等数据。

| 已删除文件 | 说明 |
|------------|------|
| `lua/wanxiang/input_statistics.lua` | 输入统计模块 |

### 版本显示

`/wx` 触发显示万象版本号。

| 已删除文件 | 说明 |
|------------|------|
| `lua/wanxiang/version_display.lua` | 版本显示翻译器 |

### 固定已输入语句

按下句号锁定当前候选句子，双击句号锁定上一个N-1长度的候选句子。

| 已删除文件 | 说明 |
|------------|------|
| `lua/wanxiang/force_upper_aux.lua` | 自动施加辅助码 |

### 短语格式化

自定义短语中重复字符与动态变量（时间、日期等）格式化。

| 已删除文件 | 说明 |
|------------|------|
| `lua/wanxiang/super_filter.lua` | 短语动态变量格式化 |

### 翻译模式

Ctrl+E 进入翻译模式（OpenCC 查表中英互译）。

| 已删除文件/配置 | 说明 |
|-----------------|------|
| `lua/data/chinese_english.txt` | 中译英数据 |
| `lua/data/english_chinese.txt` | 英译中数据 |
| `wanxiang.schema.yaml` 等 | `chinese_english` 开关、replacer type、Ctrl+E 绑定 |

### 输入模式切换

Shift+Space 在中文/英文/混合候选词之间切换。

| 实现位置 | 说明 |
|----------|------|
| `lua/wanxiang/super_filter.lua` | 英文句子过滤、模式切换逻辑 |
| `wanxiang.schema.yaml` | `input_type` 开关配置 |
| `wanxiang_english.schema.yaml` | 英文方案 Shift+Space 切换配置 |

### T9 九宫格方案

移动端 T9 输入方案。

| 已删除文件 | 说明 |
|------------|------|
| `wanxiang_t9.schema.yaml` | 九宫格方案定义 |
| `lua/data/t9_abbrev.txt` | T9 专用简码数据 |

### 14 键 / 18 键

移动端缩减键盘布局的转写支持。

| 已删除配置 | 说明 |
|------------|------|
| `custom/wanxiang.custom.yaml` | `18jian` / `14jian` xlit 转写段落 |
