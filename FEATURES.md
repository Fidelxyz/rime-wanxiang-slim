# 万象拼音 — 功能与实现位置映射

本文档列出 README.md 中提到的所有功能，并映射到对应的实现文件。

## 功能一览

### 辅助码

#### 直接辅助码（仅 PRO）

双拼后直接追加辅助码，4 码末尾追加 `/` 强制单字优先。

- `custom/wanxiang_pro.schema.yaml`：PRO 方案中的辅助码编码配置
- `custom/wanxiang.dict.yaml`：携带辅助码的 PRO 词库（格式：`字 拼音;辅码 词频`）
- `wanxiang_algebra.yaml`：`/` 引导辅助码聚拢的转写规则

#### 间接辅助码（仅 PRO）

使用 `/` 分隔符引导辅助码（格式：`拼音/辅码`）。

- `custom/wanxiang_pro.schema.yaml`：间接辅助码 speller 配置
- `wanxiang_algebra.yaml`：间接辅助码转写规则

#### 辅助筛选

输入主拼音后按 `` ` `` 引导二次筛选（部首、两分、多分、笔画）。

- `lua/wanxiang/lookup_filter.lua`：候选筛选核心逻辑，支持 aux/db 双数据源
- `wanxiang.schema.yaml` (`lookup_filter` 段)：反查配置（引导符、tags、数据源优先级）

#### 声调辅助筛选

7890 数字键代表一二三四声，支持连续按键修正声调。

- `wanxiang_algebra.yaml`：声调数字(7890)到拼音声调的转写规则
- `wanxiang.schema.yaml`：`alphabet` 中 7890、`tone_corrector` 配置段
- `lua/wanxiang/tone_corrector.lua`：声调修正处理器
- `lua/wanxiang/preedit_tone_displayer.lua`：声调数字转上标显示（7890 → ¹²³⁴）

#### 编码全拼展开

Ctrl+S 切换编码区显示模式：原编码 / 带声调全拼 / 无声调全拼。

- `lua/wanxiang/preedit_pinyin_expander.lua`：编码区全拼展开逻辑
- `wanxiang.schema.yaml`：`tone_pinyin_code`/`toneless_pinyin_code` 开关、Ctrl+S 绑定

### 反查

通过 `` ` `` 引导拆字/笔画模式（如 `` `yu if `` 查找"震"）。

- `wanxiang_reverse.schema.yaml`：拆分与笔画反查方案定义
- `wanxiang_reverse.dict.yaml`：反查字典数据
- `wanxiang.schema.yaml`：`reverse_lookup` 段与 `affix_segmentor` 配置

### 造词

#### 手动造词（仅 PRO）

`` `` `` 引导主动造词，支持后触发造词与次选造词。造词模式下添加造词提示并移除整句候选。

- `lua/wanxiang/user_dict_appender.lua`：造词模式下为候选添加 `user_dict_appender/tips` 提示，并移除整句（sentence）候选
- `custom/wanxiang_pro.schema.yaml`：PRO 方案中用户词配置
- `wanxiang.schema.yaml`：`user_dict` 段与 `user_dict_appender` 段

#### 自动造词（仅 PRO）

关闭调频下通过逐步选字选词上屏记录整段，不产生小碎片。

- `lua/wanxiang/auto_phrase.lua`：自动造词模块
- `wanxiang.schema.yaml`：`user_dict_appender` 段配置

#### 英文造词

英文编码开头输入造词引导符 ` `` `（与手动造词共用 `user_dict_appender/prefix` 配置）触发英文造词，将上屏的英文词条记录到 `en.userdb`。仅在首个音节段（尚未选定中文词）时提供英文整词候选。

- `lua/wanxiang/english_user_dict_appender.lua`：提供英文整词候选；将上屏的英文词条写入英文用户词库（触发符读取 `user_dict_appender/prefix`）
- `wanxiang.schema.yaml`：`english` 段 `trigger` 配置

### 提示

#### 错音错字提示

输入常见错读词时提示正确读音（如"给予"提示 `jǐ yǔ`）。

- `lua/wanxiang/comment_hint_displayer.lua`：错音纠正提示逻辑（使用 Memory API 查询）
- `dicts/correction.dict.yaml`：错音词条数据
- `wanxiang.schema.yaml` / `wanxiang_pro.schema.yaml`：`correction_hint` 配置段

#### 辅助码提示（仅 PRO）

任意长度候选词的辅助码提示，Ctrl+a 循环切换（辅助码/关闭），Ctrl+c 拆分提示。

- `lua/wanxiang/comment_hint_displayer.lua`：注释显示模块：辅助码提示、拆分提示
- `custom/wanxiang_chaifen.schema.yaml`：拆分反查方案
- `custom/wanxiang_chaifen_*.dict.yaml`：7 种辅码拆分字典

#### 版本显示

`/version` 触发显示输入方案及 Rime 版本。

- `lua/wanxiang/version_displayer.lua`：版本显示翻译器

### 字符集过滤

可配置字符集规则，支持多选项并集、黑白名单、简繁联动，二进制滤镜数据库。

- `lua/wanxiang/charset_filter.lua`：字符集过滤模块
- `lua/data/charset.reverse.bin`：二进制字符集标记数据库
- `wanxiang.schema.yaml`：`charset` 段配置（option、base、whitelist、blacklist）

### 非汉字词库输入

#### 英文输入

整句英文输入、首字母/全大写格式化。

- `lua/wanxiang/english_case_formatter.lua`：智能英文大小写格式化（前两个输入字母驱动）
- `lua/wanxiang/english_single_letter_promoter.lua`：单字母输入时生成大小写候选并置前
- `lua/utils/utils.lua`：英文判断公共工具函数（`is_english_phrase`、`ENGLISH_SYMBOLS`）
- `wanxiang_english.schema.yaml`：英文输入方案定义
- `wanxiang_english.dict.yaml`：英文词典数据
- `dicts/english.dict.yaml`：英文词条
- `wanxiang_algebra.yaml` (`english` 段)：英文输入转写规则

#### 混合词输入

字母、汉字、数字、特殊符号组合输入（如 `1000wclips`、`AD钙奶`、`Type-C`）。

- `wanxiang_mixedcode.schema.yaml`：混合编码方案定义
- `wanxiang_mixedcode.dict.yaml`：混合编码词典
- `dicts/mixedcode.dict.yaml`：中英混合词条
- `wanxiang_algebra.yaml` (`mixed` 段)：混合编码转写规则

### 其他功能

#### Unicode 输入

大写 `U` 开头输入 Unicode 码点（如 `U62fc` 得到"拼"）。

- `lua/wanxiang/unicode.lua`：Unicode 字符翻译器
- `wanxiang.schema.yaml`：recognizer 中 `unicode` 模式配置

#### 短语格式化

自定义短语中 `\n` `\s` `\t` 等转换为实际换行/空格/制表符。

- `lua/wanxiang/phrase_escaper.lua`：转义序列格式化逻辑
- `custom_phrase.txt` (用户目录)：自定义短语数据源

#### 候选类型符号

为不同类型的候选词（如 emoji 等）在注释末尾追加对应符号。

- `lua/wanxiang/candidate_type_marker.lua`：读取配置并追加类型符号逻辑
- `wanxiang.schema.yaml` / `wanxiang_pro.schema.yaml`：`candidate_type_marker` 配置项

#### 小键盘行为

小键盘不直接上屏。

- `lua/wanxiang/keypad_composer.lua`：KP（数字小键盘）映射处理（`KP_MAP`）
- `wanxiang.schema.yaml`：小键盘相关配置

### 删除键限制

输入中持续删除至编码为空时，阻止删除已上屏内容。

- `lua/wanxiang/backspace_limiter.lua`：Backspace 限制逻辑

### 候选词部分上屏

<kbd>Ctrl</kbd> + 数字键上屏首选前 N 字，并保留后续编码。

- `lua/wanxiang/partial_committer.lua`：部分上屏处理器

### 候选置顶

<kbd>Ctrl</kbd>+<kbd>P</kbd> 置顶当前候选，<kbd>Ctrl</kbd>+<kbd>L</kbd> 取消置顶。置顶记录写入独立的用户数据库 `wanxiang_pinned.userdb`，下次输入相同编码时被置顶的候选会排在最前。

- `lua/wanxiang/candidate_pinner.lua`：置顶处理器与过滤器
- `wanxiang.schema.yaml` / `wanxiang_pro.schema.yaml`：`candidate_pinner` 段配置，processors 中 `candidate_pinner*P`

### 万能键斜杠 `/`

辅助码聚拢、间接辅助码引导、短码英文前置、双击上屏斜杠。

- `wanxiang_algebra.yaml`：`/` 相关的转写规则（辅助码聚拢、英文前置）
- `lua/wanxiang/backspace_limiter.lua`：双击斜杠
- `wanxiang.schema.yaml`：斜杠相关的 speller/recognizer 配置

### 方案切换

通过 `/flypy`、`/zrm` 等指令切换双拼/全拼方案（共 15 种）。

- `lua/wanxiang/set_schema.lua`：方案切换翻译器，自动修改 custom 文件
- `wanxiang_algebra.yaml`：12+ 拼音方案的转写规则
- `custom/` 目录：custom 文件模板

## 已移除功能

### 输入相关

以下功能已从本仓库中移除。保留记录以便从上游合并时参考。

#### 辅筛定点改字

通过辅助码修改候选长句中的特定字。

- `lua/wanxiang/lookup_filter.lua`：辅筛定点改字功能

#### 成对符号包裹

输入编码末尾追加 `\a` 等触发成对符号包裹（如 `\k` 映射 `《》`）。

- `lua/wanxiang/super_filter.lua`：成对符号包裹逻辑（`wrap_parts` 映射）
- `wanxiang.schema.yaml`：`paired_symbols` 配置段
- `custom/wanxiang_pro.schema.yaml`：`paired_symbols` 配置段
- `custom/wanxiang.custom.yaml`：`paired_symbols` 配置段（模板）
- `custom/wanxiang_pro.custom.yaml`：`paired_symbols` 配置段（模板）

#### 量词预测调频

输入数字后提升单字量词权重。

- `lua/wanxiang/user_predict.lua`：量词预测逻辑
- `wanxiang.schema.yaml` 等：量词数据

#### 输入预测

根据上文输入置顶预测词或主动弹出预测词。

- `lua/wanxiang/user_predict.lua`：输入预测模块

##### 联想空格打断

空格键打断联想并上屏空格，对齐大厂输入法行为。

- `lua/wanxiang/user_predict.lua`：`predict_space` 配置与打断逻辑
- `wanxiang.schema.yaml`：`user_predict/enable_predict_space` 配置项

#### 英文智能加空格

支持 off/before/after/smart 四种策略，超时销毁。

- `lua/wanxiang/english_spacer.lua`：加空格全部逻辑（smart 模式、超时）
- `wanxiang.schema.yaml` (`english` 段)：加空格策略配置项

#### 空码回溯

前面编码有候选但继续输入无候选时，显示上一次候选并标注 `~`。

- `lua/wanxiang/fallback_filter.lua`：3 码回退逻辑，空码候选恢复与 `~` 标注

#### 固定已输入语句

按下句号锁定当前候选句子，双击句号锁定上一个N-1长度的候选句子。

- `lua/wanxiang/force_upper_aux.lua`：自动施加辅助码

#### 循环切换分词

多次按下分词键 <kbd>'</kbd> 循环切换分词模式。

- `lua/wanxiang/super_processor.lua`：循环分词处理器

#### 输入长度限制

限制重复按键输入或分词过多的编码。

- `lua/wanxiang/super_processor.lua`：`RepeatLimit` 重复声母 / 最大分词数限制逻辑
- `wanxiang.schema.yaml`：`super_processor/limit_repeated` 配置项
- `wanxiang_pro.schema.yaml`：`super_processor/limit_repeated` 配置项

#### 输入模式切换

Shift+Space 在中文/英文/混合候选词之间切换。

- `lua/wanxiang/super_filter.lua`：英文句子过滤、模式切换逻辑
- `wanxiang.schema.yaml`：`input_type` 开关配置
- `wanxiang_english.schema.yaml`：英文方案 Shift+Space 切换配置

#### 超级替换

替代 OpenCC 的增强组件，支持 append/replace/comment/abbrev 四种模式，链式/并行处理。

- `lua/wanxiang/super_replacer.lua`：超级替换模块，LevelDB 数据库 `lua/replacer.userdb`
- `lua/data/emoji.txt`：Emoji 数据
- `lua/data/abbrev.txt`：公共简码数据
- `lua/data/STCharacters.txt`：简繁单字转换
- `lua/data/STPhrases.txt`：简繁词组转换
- `lua/data/HKVariants.txt`：香港繁体变体
- `lua/data/TWVariants.txt`：台湾繁体变体
- `lua/data/others.txt`：其他替换数据
- `wanxiang.schema.yaml`：`super_replacer` 段配置（rules、chain、db_name 等）

#### 候选排序

Ctrl+J/K/L/P 手动调整候选排序，支持多设备同步。

- `lua/wanxiang/sequencer.lua`：手动排序模块，LevelDB 数据库 `lua/sequence.userdb`
- `wanxiang.schema.yaml`：排序快捷键配置

### 快捷短语相关

#### 快符输入

单字母 + `/` 快速上屏自定义符号（如 `a/` 上屏"！"），支持 `repeat` 重复上屏。

- `lua/wanxiang/super_processor.lua`：快符处理逻辑（`quick_symbol_text` 映射、拦截与自动上屏）
- `wanxiang.schema.yaml`：`quick_symbol_text` 配置段
- `custom/wanxiang_pro.schema.yaml`：`quick_symbol_text` 配置段
- `custom/wanxiang.custom.yaml`：`quick_symbol_text` 配置段（模板）
- `custom/wanxiang_pro.custom.yaml`：`quick_symbol_text` 配置段（模板）

#### 符号输入

`/` 前缀触发特殊符号候选。

- `wanxiang_symbols.yaml`：符号输入方案定义

#### 时间日期输入

多种日期时间格式输入。

- `lua/wanxiang/shijian.lua`：时间日期翻译器

#### 中文大写数字输入

大小写中文数字转换。

- `lua/wanxiang/number_translator.lua`：数字翻译器

#### 中英翻译

Ctrl+E 进入翻译模式（OpenCC 查表中英互译）。

- `lua/data/chinese_english.txt`：中译英数据
- `lua/data/english_chinese.txt`：英译中数据
- `wanxiang.schema.yaml` 等：`chinese_english` 开关、replacer type、Ctrl+E 绑定

#### 短语格式化

自定义短语中重复字符与动态变量（时间、日期等）格式化。

| 已删除文件 | 说明 |
|------------|------|
| `lua/wanxiang/super_filter.lua` | 短语动态变量格式化 |

### 提示相关

#### 超级 Tips

表情、化学式、翻译、简码提示等，通过自定义按键直接上屏，不占候选框。

- `lua/wanxiang/super_tips.lua`：Tips 系统，LevelDB 数据库 `lua/tips.userdb`
- `lua/data/tips_show.txt`：Tips 自带数据
- `lua/data/tips_user.txt预留自定义文件`：Tips 用户自定义数据
- `wanxiang.schema.yaml` 等：`tips` 段配置（`disabled_types`、`tips_key`）、Ctrl+t 开关、`super_tips` 开关与处理器

#### 计算器

输入数学表达式直接得到计算结果。

- `lua/wanxiang/super_calculator.lua`：超级计算器

#### 输入统计

统计用户输入字数等数据。

- `lua/wanxiang/input_statistics.lua`：输入统计模块

### 特殊布局相关

#### T9 九宫格方案

移动端 T9 输入方案。

- `wanxiang_t9.schema.yaml`：九宫格方案定义
- `lua/data/t9_abbrev.txt`：T9 专用简码数据

#### 14 键 / 18 键

移动端缩减键盘布局的转写支持。

- `custom/wanxiang.custom.yaml`：`18jian` / `14jian` xlit 转写段落
