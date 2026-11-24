# 万象拼音 — 功能与实现位置映射

本文档列出万象拼音输入方案中的所有功能，并映射到对应的实现文件。`schema.yaml` 指 `wanxiang.schema.yaml` 与 `wanxiang_pro.schema.yaml`。

## 功能一览

### 辅助码

#### 直接与间接辅助码（仅 PRO）

拼音编码后直接追加辅助码，末尾追加 `/` 强制单字优先；或使用 `/` 分隔符引导辅助码。

- `wanxiang_pro.schema.yaml`：辅助码 speller 配置
- `wanxiang_algebra.yaml`：`pro/直接辅助`、`pro/间接辅助` 转写规则，`小鹤双拼提权`、`自然码提权` 四码字提权规则
- `scripts/generate_pro_dicts.py`：依据 `data/aux_code.csv` 生成携带辅助码的 PRO 词库

#### 声调输入

7890 数字键代表一二三四声，支持连续按键修正声调，编码区以上标显示。

- `wanxiang_algebra.yaml`：声调数字到拼音声调的转写规则
- `schema.yaml`：`speller/alphabet` 中的 `7890`
- `lua/wanxiang/tone_corrector.lua`：声调修正处理器
- `lua/wanxiang/preedit_tone_displayer.lua`：声调数字转上标显示

### 反查 / 辅助筛选

#### 反查

通过 `` ` `` 引导拆字/笔画模式。

- `wanxiang_reverse.schema.yaml`：拆分与笔画反查方案定义
- `wanxiang_reverse.dict.yaml`：反查词典，导入 `dicts/reverse.dict.yaml`
- `dicts/reverse.dict.yaml`：反查词条，由 `scripts/update_dicts.py` 从上游同步
- `custom/wanxiang_reverse.custom.yaml`：反查 custom 模板
- `schema.yaml`：`wanxiang_reverse` 段，`reverse_lookup_translator` 与 `affix_segmentor` 挂载
- `wanxiang_algebra.yaml`（`reverse` 段）：各拼音与笔画规则

#### 辅助筛选

输入主拼音后按 `` ` `` 引导二次筛选（部首、两分、多分、笔画）。引导符后可在任意位置插入声调数字 `7890`，提取后按字序筛选声调，剩余字母继续匹配辅助码。

- `lua/wanxiang/lookup_filter.lua`：候选筛选、声调提取与匹配
- `lua/utils/segmented_cache.lua`：反查/注释解析结果的分段缓存
- `lua/utils/utils.lua`：`get_pinyin_tone` 从注释拼音读取声调
- `schema.yaml`：`lookup_filter` 段

### 提示

#### 错音错字提示

输入常见错读词时提示正确读音。

- `lua/wanxiang/comment_hint_displayer.lua`：错音纠正提示逻辑
- `dicts/correction.dict.yaml`：错音词条数据
- `schema.yaml`：`correction_hint` 段

#### 编码全拼展开

Ctrl+S 切换编码区显示模式：原编码 / 带声调全拼 / 无声调全拼。

- `lua/wanxiang/preedit_pinyin_expander.lua`：编码区全拼展开逻辑
- `schema.yaml`：`raw_code`/`tone_pinyin_code`/`toneless_pinyin_code` 开关组及 Ctrl+S 绑定

#### 读音与辅助码提示

候选注释开关组：Base 为关闭 / 带调读音 / 无调读音，PRO 为关闭 / 辅助码 / 读音，以 Ctrl+A 循环切换。PRO 另以 Ctrl+C 切换辅助码拆分提示。

- `lua/wanxiang/comment_hint_displayer.lua`：注释显示模块
- `schema.yaml`：提示开关组、`code_hint/max_candidate_length`（显示辅助码的最大候选长度）
- `wanxiang_pro.schema.yaml`：`decomposition_hint` 开关及同名 simplifier 段
- `opencc/decomposition.json`、`data/decomposition/*.txt`：9 种辅助码的拆分数据，由 `scripts/build.sh` 按方案打包为 `opencc/dicts/decomposition.txt`

#### 候选类型标记

为不同类型的候选词在注释末尾追加对应标记。

- `lua/wanxiang/candidate_type_marker.lua`：读取配置并追加类型标记逻辑
- `schema.yaml`：`candidate_type_marker` 段

### 模糊音

可按需开启 10 组双向模糊音，默认全部关闭。

- `wanxiang_algebra.yaml`（`模糊音_*` 段）：声母、韵母模糊音转写规则
- `custom/wanxiang.custom.yaml` / `custom/wanxiang_pro.custom.yaml`：模糊音配置模板

### 候选排序

#### 候选置顶

Ctrl+P 置顶当前候选，Ctrl+L 取消置顶。置顶记录写入独立的用户数据库 `pinned.userdb`，下次输入相同编码时被置顶的候选会排在最前。

- `lua/wanxiang/candidate_pinner.lua`：置顶处理器与翻译器
- `schema.yaml`：`candidate_pinner` 段，processors 中 `candidate_pinner*P`、主翻译器之前的 `candidate_pinner*T`

#### 单字 / 词组优先

单字与词组编码重合时，优先显示单字或词组候选。

- `lua/wanxiang/lookup_filter.lua`：辅助筛选时按开关调整单字与词组候选顺序
- `schema.yaml`：`char_priority` 开关

### 字符集过滤

可配置字符集规则，支持多选项并集、黑白名单、简繁联动，二进制滤镜数据库，Ctrl+G 切换。

- `lua/wanxiang/charset_filter.lua`：字符集过滤模块
- `lua/data/charset.reverse.bin`：二进制字符集标记数据库
- `schema.yaml`：`charset_filter` 开关及同名配置段

### 非汉字词库输入

#### 英文输入

英文词库输入、首字母/全大写格式化。长度不超过 3 的编码末尾追加 `/` 可前置对应的英文词候选。

- `lua/wanxiang/english_case_formatter.lua`：智能英文大小写格式化
- `lua/wanxiang/english_translator.lua`：按开关输出英文词库及英文用户词典候选
- `lua/wanxiang/english_single_letter_promoter.lua`：单字母输入时生成大小写候选并置前
- `schema.yaml`：`disable_english` 开关，默认开启英文候选，关闭时同时停用单字母候选派生和英文造词
- `lua/utils/utils.lua`：英文判断公共工具函数
- `wanxiang_english.schema.yaml` / `wanxiang_english.dict.yaml`：英文输入方案定义与词典
- `dicts/english.dict.yaml`：英文词条，由 `scripts/generate_english_dict.py` 从 ESDB 词表和 wordfreq 词频生成
- `wanxiang_algebra.yaml`（`english` 段）：英文输入转写规则，含短码追加 `/` 的派生规则

#### Emoji 输入

通过汉字词汇输入 Emoji。

- `schema.yaml`：`emoji` 开关及同名 simplifier 段
- `opencc/emoji.json`、`opencc/dicts/emoji.txt`：Emoji 转换配置与数据
- `scripts/convert_emoji_dict_to_opencc.py`：生成 `opencc/dicts/emoji.txt`

### 造词

#### 手动造词（仅 PRO）

` `` ` 引导主动造词，引导符可输入在编码起始或末尾。造词模式下添加造词提示并移除整句候选。

- `lua/wanxiang/user_dict_translator.lua`：在空自造词库时跳过检索，非空时保留原生拼写匹配与调频，仅输出用户词候选
- `lua/wanxiang/user_dict_appender.lua`：添加造词提示并过滤整句候选
- `lua/wanxiang/key_binder.lua`：编码末尾输入 `` ` `` 时改写为开头的造词引导符
- `schema.yaml`：`user_dict`、`user_dict_appender` 段，`recognizer/patterns/user_dict_appender`（Base 默认注释）

#### 自动造词

关闭调频下通过逐步选字选词上屏记录整段，PRO 默认启用，Base 默认关闭。

- `lua/wanxiang/auto_user_dict_appender.lua`：自动造词模块
- `lua/wanxiang/candidate_code_recorder.lua`：记录候选编码，供自动造词与候选置顶读取
- `schema.yaml`：`user_dict_appender/enable_auto_phrase`

#### 英文造词（仅 PRO）

英文编码开头输入造词引导符 ` `` ` 触发英文造词，将上屏的英文词条记录到 `user_dict_en` 用户词典。尚未部分上屏时提供英文整词候选。

- `lua/wanxiang/english_user_dict_appender.lua`：英文词条追加与整词候选
- `schema.yaml`：`wanxiang_english` 段

### 快捷短语

#### Unicode 输入

大写 `U` 开头输入 Unicode 码点。

- `lua/wanxiang/unicode.lua`：Unicode 字符翻译器
- `schema.yaml`：recognizer 中 `unicode` 模式

#### 短语字符转义

`custom_phrase.txt` 中的自定义短语，`\n` `\s` `\t` 等转义转换为实际换行/空格/制表符。

- `lua/wanxiang/phrase_escaper.lua`：转义序列格式化逻辑
- `custom/custom_phrase.txt`：自定义短语模板
- `schema.yaml`：`custom_phrase` 段

### 其他功能

#### 小键盘行为

`keypad_mode` 控制小键盘数字键：`auto` 有待上屏内容时不直接上屏，`compose` 总不直接上屏，`select` 选词时选择候选。

- `lua/wanxiang/keypad_composer.lua`：数字小键盘映射处理
- `schema.yaml`：`keypad_composer` 段

#### 删除键限制

输入中持续删除至编码为空时，阻止删除已上屏内容。默认关闭，仅于桌面前端生效。

- `lua/wanxiang/backspace_limiter.lua`：Backspace 限制逻辑
- `schema.yaml`：`backspace_limiter/enabled`

#### 候选词部分上屏

Ctrl + 数字键上屏当前选中候选的前 N 字，并保留后续编码。

- `lua/wanxiang/partial_committer.lua`：部分上屏处理器

#### 以词定字

`[` / `]` 上屏候选的首字 / 末字。

- `lua/wanxiang/character_selector.lua`：以词定字处理器
- `schema.yaml`：`character_selector` 段

#### 音节跳转

Tab 在音节之间跳转（仅 Base），Ctrl+Tab 提交当前音节并跳至下个音节。

- `wanxiang.schema.yaml`：`key_binder/bindings` 中的 Tab 绑定
- `schema.yaml`：`key_binder/bindings` 中的 Ctrl+Tab 绑定

#### 简繁转换

简体 / 繁体 / 港繁 / 臺繁转换。

- `schema.yaml`：`zh_*` 开关组，`s2t`、`s2hk`、`s2tw` simplifier 段
- `opencc/s2*.json`、`opencc/dicts/`：OpenCC 简繁转换配置与数据

#### 双击斜杠上屏

输入 `/` 后再按 `/` 上屏斜杠。

- `lua/wanxiang/key_binder.lua`：按当前编码匹配 `key_binder/bindings` 中带 `match` 的绑定并发送按键序列
- `schema.yaml`：`key_binder/bindings` 中的双击斜杠绑定

#### 方案切换

通过 `/flypy`、`/zrm` 等指令切换双拼/全拼方案，PRO 另可通过 `/zjf`、`/jjf` 切换直接/间接辅助码，由 `schema.yaml` 的 `command/enabled` 控制，默认启用。

- `lua/wanxiang/schema_switcher.lua`：方案切换翻译器，统一替换主方案和反查 custom 文件的 `__patch` 列表中的拼音规则引用
- `lua/utils/file.lua`：custom 文件读写，以及错音词条、字符集数据库等数据文件的定位
- `wanxiang_algebra.yaml`（`base`、`pro`、`reverse` 段）：各拼音方案的转写规则
- `custom/`：custom 文件模板

#### 版本显示

`/version` 显示方案、前端、librime 与 Lua 版本及当前拼音方案，PRO 另显示辅助码方案与引导模式，由 `command/enabled` 控制。

- `lua/wanxiang/version_displayer.lua`：版本显示翻译器
- `lua/meta.lua`：版本号及打包时由 `scripts/build.sh` 写入的辅助码方案 `AUX_CODE`

### 词库维护

- `scripts/update_dicts.py`：将上游词库规范化后同步到本仓库（含去除反查拆分编码的声调后缀），`LOCAL_DICTS` 保留本地英文词条
- `scripts/update_grammar_params.py`：从上游方案同步 `grammar` 参数

## 已移除功能

本节记录已删除及上游新增但本项目未引入的功能，供合并上游时参考。除标注“本地”外，路径均指上游仓库，`schema.yaml` 指上游的 `wanxiang.schema.yaml` 与 `custom/wanxiang_pro.schema.yaml`。

### 输入相关

#### 辅助筛选扩展

- 词组直接辅助码（仅 Base）：输入完整两字词拼音后，直接追加辅助码筛选词组，支持任意字的单码、双码及两字首码组合。[上游说明](https://github.com/amzxyz/rime-wanxiang/blob/v18.1.8/docs/doc/super_lookup.md)
- 排序优化：同长度候选按辅助码数据源优先级、集中命中单字或跨字匹配的情况调整顺序。
- 定点改字：通过辅助码修改候选长句中的特定字。

- `lua/wanxiang/super_lookup.lua`：无引导符的两字词辅助筛选、匹配来源与程度排序、`attempt_phrase_correction` 定点改字
- `wanxiang.schema.yaml`：`wanxiang_lookup/enable_direct`、`wanxiang_lookup/data_source` 配置项

#### 反查声调筛选

部件或笔画反查后追加 `7890`，按目标字本身的声调筛选。

- `wanxiang_reverse.dict.yaml`：携带目标字声调后缀的反查编码
- `schema.yaml`：`recognizer/patterns/wanxiang_reverse` 允许声调数字
- `scripts/update_dicts.py`（本地）：同步反查字典数据时去除拆分编码末尾的声调后缀

#### 上下文调频

学习连续上屏词语之间的关系，根据前一个或前两个词调整现有候选顺序；输入数字后提升单字量词权重；回删编码后重新输入同一完整编码时，交换当前段的前两个候选。[上游说明](https://github.com/amzxyz/rime-wanxiang/blob/v18.1.8/docs/doc/context_reorder.md)

- `lua/wanxiang/context_reorder.lua`：上下文学习与排序、量词调频、回删重输交换、删词及退格撤销学习记录
- `schema.yaml`：`context_reorder` 开关、处理器、过滤器及同名配置段（含 `custom_classifiers`、`enable_fallback_reorder`）

#### 联想空格打断

空格键打断联想并上屏空格，对齐大厂输入法行为。

- `lua/wanxiang/super_processor.lua`：联想空格打断逻辑
- `schema.yaml`：`super_processor/enable_predict_space` 配置项

#### 候选逐项排序

Ctrl+J/K 将候选向前或向后移动，Ctrl+L 重置排序记录，支持多设备同步。

- `lua/wanxiang/super_sequence.lua`：手动排序模块，LevelDB 数据库 `sequence`
- `schema.yaml`：`super_sequence` 段中的排序快捷键

#### 英文空格与整句

在英文单词前后自动添加空格；连续输入多个英文单词时生成带词间空格的整句候选。

- `lua/wanxiang/super_english.lua`：连续英文自动空格、整句候选的词间空格恢复
- `schema.yaml` / `wanxiang_english.schema.yaml`：`wanxiang_english/english_spacing`、`spacing_timeout` 配置项
- `wanxiang_english.schema.yaml`：`super_english` 处理器、翻译器与过滤器挂载

#### 英文候选数量限制

限制英文候选输出数量。

- `lua/wanxiang/super_english.lua`：候选数量限制
- `schema.yaml`：`wanxiang_english/max_candidates` 配置项

#### 空码回溯

输入 3 码无候选时，回退显示 2 码时的首选单字并标注 `~`；英文方案继续输入无候选时，按已记忆的前缀候选拼接出候选并标注 `~`。

- `lua/wanxiang/super_filter.lua`：3 码回退逻辑，空码候选恢复与 `~` 标注
- `lua/wanxiang/super_english.lua`：英文方案的输入记忆与回溯

#### 固定已输入语句（仅 PRO）

按 F1 固定当前候选句子，连按两次固定前 N-1 字候选。

- `lua/wanxiang/force_upper_aux.lua`：将候选各字的大写辅助码施加到音节后以固定分词
- `custom/wanxiang_pro.schema.yaml`：`force_upper_aux` 处理器及同名配置段
- `lua/wanxiang/super_comment_preedit.lua`：`force_upper_aux/symbol` 的编码区显示

#### 循环切换分词

多次按下分词键 ' 循环切换分词模式。

- `lua/wanxiang/super_processor.lua`：循环分词处理器
- `schema.yaml`：`super_processor/enable_seg_loop` 配置项

#### 输入长度限制

限制重复按键输入或分词过多的编码。

- `lua/wanxiang/super_processor.lua`：`handle_limit_repeat` 重复声母 / 最大分词数限制逻辑
- `schema.yaml`：`super_processor/limit_repeated` 配置项

### 快捷短语相关

#### 快符输入

单字母 + `/` 快速上屏自定义符号，支持 `repeat` 重复上屏。

- `lua/wanxiang/super_processor.lua`：快符处理逻辑
- `schema.yaml`：`quick_symbol_text` 配置段

#### 符号输入

`/` 前缀触发特殊符号候选，包含 XCompose 组合序列。

- `wanxiang_symbols.yaml`：符号输入方案定义
- `schema.yaml`：`recognizer/patterns/punct` 与 `punctuator` 导入 `wanxiang_symbols`

#### 符号 / Emoji 搜索

通过 `/sym` 和 `/emoji` 按 Codex 名称查找符号与 Emoji，支持路径补全、模糊搜索和多个关键词搜索。[上游说明](https://github.com/amzxyz/rime-wanxiang/blob/v18.1.8/docs/doc/super_symbols.md)

- `lua/wanxiang/super_symbols.lua`：名称搜索与路径补全
- `lua/data/codex_sym.txt` / `lua/data/codex_emoji.txt`：符号与 Emoji 名称数据
- `schema.yaml`：`super_symbols` 翻译器、配置段及 recognizer 规则

#### 成对符号包裹

输入编码末尾追加 `\a` 等触发成对符号包裹。

- `lua/wanxiang/super_filter.lua`：符号包裹处理
- `schema.yaml`：`paired_symbols` 配置段

#### 随机标识与密码生成

通过 `/uuid`、`/uuidq`、`/ulid`、`/mima`、`/mimas` 生成 UUID v4、UUID v7、ULID 或随机密码。[上游说明](https://github.com/amzxyz/rime-wanxiang/blob/v18.1.8/docs/doc/random_tools.md)

- `lua/wanxiang/random_tools.lua`：随机标识与密码翻译器
- `schema.yaml`：`random_tools` 翻译器与配置段

#### Unicode 扩展输入

使用二、八、十进制 Unicode 码点输入字符；将字符转换为 Unicode 转义、UTF-8、UTF-16、HTML 和 URL 编码作为候选，Ctrl+U 将当前候选转入编码转换，再次按下恢复原编码。

- `lua/wanxiang/unicode_conversion.lua`：多进制码点解析、编码转换及候选查询处理器
- `schema.yaml`：`unicode_conversion` 处理器与翻译器、扩展 recognizer 规则及 `unicode/key` 配置

#### 时间日期输入

多种日期时间格式输入。

- `lua/wanxiang/shijian.lua`：时间日期翻译器
- `schema.yaml`：`sjc` 等 recognizer 规则及 `date_formats` 等时间日期格式配置

#### 中文大写数字输入

大小写中文数字转换。

- `lua/wanxiang/number_conversion.lua`：数字与金额翻译器

#### 金额与日期模式字母选词

在中文大写数字、`N` 日期及 `/` 数字符号输入中，使用 `q`–`p` 选择当前页候选。依附于时间日期输入、中文大写数字输入与符号输入。

- `lua/wanxiang/super_processor.lua`：特殊模式下的字母选词

#### 短语动态变量

自定义短语中重复字符与动态变量格式化。

- `lua/wanxiang/super_filter.lua`：短语动态变量格式化

#### 超级替换

增强替换组件，支持 append/replace/comment/abbrev 四种模式、链式/并行处理，以及按最长匹配分段替换或派生整句候选。

- `lua/wanxiang/super_replacer.lua`：超级替换模块，LevelDB 数据库 `build/replacer`
- `lua/data/others.txt`：其他替换数据
- `lua/data/sentence.txt`：整句派生数据
- `lua/data/en_abbrev.txt`：英文简码数据
- `schema.yaml`：`super_replacer` 段配置

### 提示相关

#### 超级 Tips

表情、化学式、翻译、简码提示等，通过自定义按键直接上屏，不占候选框。

- `lua/wanxiang/super_tips.lua`：Tips 系统，LevelDB 数据库 `build/tips`
- `lua/data/tips_show.txt`：Tips 自带数据，另读取用户创建的 `lua/data/tips_user.txt`
- `schema.yaml`：`super_tips` 开关、处理器与配置段，Ctrl+T 绑定

#### 反查字符区提示

在反查候选注释中显示汉字所属的基本区、扩展区或兼容区。

- `lua/wanxiang/super_comment_preedit.lua`：反查候选的 Unicode 字符区注释

#### 计算器

输入数学表达式直接得到计算结果。

- `lua/wanxiang/super_calculator.lua`：超级计算器

#### 输入统计

统计用户输入字数等数据，`/htj` 按日期或区间查询历史统计。

- `lua/wanxiang/input_statistics.lua`：输入字数统计与历史查询
- `schema.yaml`：`input_stats` 配置段、`htj` recognizer 规则

### 词库相关

#### 中英混合词输入

字母、汉字、数字、特殊符号组合输入。

- `wanxiang_mixedcode.schema.yaml`：混合编码方案定义
- `wanxiang_mixedcode.dict.yaml`：混合编码词典
- `dicts/mixed.dict.yaml`：中英混合词条
- `custom/wanxiang_mixedcode.custom.yaml`：混合编码 custom 模板
- `wanxiang_algebra.yaml`（`mixed` 段）：混合编码转写规则，含数字转英文单词或拼音读法的 `混合派生`
- `schema.yaml`：`dependencies`、`translators` 与 `wanxiang_mixedcode` 配置段
- `lua/wanxiang/set_input_types.lua`：方案切换处理的 custom 文件列表中的 `wanxiang_mixedcode.custom.yaml`
- `scripts/update_dicts.py`（本地）：`IGNORED_SRC_DICTS` 忽略 `mixed` 词库

#### 扩展词库

名人、艺人等扩展词库，在主词典中按需启用。本项目改由上游 [rime-wanxiang-data](https://github.com/amzxyz/rime-wanxiang-data/releases/tag/dict-nightly) 提供。

- `dicts/mingren.dict.yaml` / `dicts/yiren.dict.yaml`：名人、艺人词库
- `wanxiang.dict.yaml`：扩展词库的导入项
- `scripts/update_dicts.py`（本地）：`IGNORED_SRC_DICTS` 忽略扩展词库

#### 简码输入

按简码查询公共词条（含成语简码），并指定简码候选插入的位置与数量。

- `wanxiang_abbrev.dict.yaml` / `dicts/abbrev.dict.yaml`：公共简码数据
- `wanxiang_abbrev.schema.yaml`：简码编译方案
- `custom/wanxiang_abbrev.custom.yaml`：简码 custom 模板
- `lua/wanxiang/custom_phrase.lua`：简码候选插入与去重
- `schema.yaml`：`abbrev` 开关、`abbrev_phrase` 配置段
- `scripts/update_dicts.py`（本地）：`IGNORED_SRC_DICTS` 忽略 `abbrev` 词库

#### 中英翻译

为英文输入追加中文翻译候选，Ctrl+E 切换。

- `lua/data/english_chinese.txt`：英译中数据
- `schema.yaml` / `wanxiang_english.schema.yaml`：`english_chinese` 开关、`super_replacer` 规则、Ctrl+E 绑定

#### 自定义短语词典

将自定义短语编译为多方案共用的词典，并将整词匹配的自定义短语置顶。为 T9、14 键、18 键等特殊布局共用自定义短语而引入。

- `wanxiang_phrase.schema.yaml` / `custom_phrase.dict.yaml`：自定义短语编译方案与词典
- `custom/wanxiang_phrase.custom.yaml`：自定义短语 custom 模板
- `lua/wanxiang/custom_phrase.lua`：自定义短语置顶
- `schema.yaml`：`wanxiang_phrase` 依赖及 `custom_phrase/prism`

#### OpenCC 自定义词条

用户可追加的简繁词组与 Emoji 词条。

- `opencc/wanxiang/Custom_STPhrases.txt` / `opencc/wanxiang/Custom_Emoji.txt`：自定义词条
- `opencc/wanxiang_*.json`：对自定义词条的引用

### 特殊布局相关

#### Lite / Pure 版本

Lite 使用无声调词库并减少 Lua 功能；Pure 不含英文、反查与 Lua，适用于 Windows 7 和 Fcitx 4。

- `custom/wanxiang_lite.{schema,custom,dict}.yaml`：Lite 方案
- `custom/wanxiang_pure.{schema,custom,dict}.yaml`：Pure 方案
- `wanxiang_algebra.yaml`（`lite` 段）：Lite 转写规则

#### T9 九宫格方案

移动端 T9 输入方案。

- `wanxiang_t9.schema.yaml` / `wanxiang_t9i.schema.yaml`：九宫格方案定义
- `wanxiang_abbrev_t9.dict.yaml` / `wanxiang_abbrev_t9.schema.yaml` / `dicts/t9_abbrev.dict.yaml`：T9 简码词库
- `wanxiang_phrase_t9.schema.yaml`：T9 自定义词库
- `wanxiang_algebra.yaml`：`9jian` 转写段
- `lua/wanxiang/wanxiang.lua`：`t9` 输入类型标记
- `lua/wanxiang/super_comment_preedit.lua`：数字编码的拼音编码区显示，由 `schema.yaml` 的 `super_comment/convert_abbrev_preedit` 控制单音节简码是否显示完整拼音

#### 14 键 / 18 键

移动端缩减键盘布局的转写支持。

- `wanxiang_algebra.yaml`：`26jian`、`18jian`、`14jian` 转写段
