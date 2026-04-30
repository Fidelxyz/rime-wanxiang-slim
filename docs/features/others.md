---
outline: deep
---

# 其他功能

## 提示

**错音错字提示**：输入常见错误读音时提示正确读音。配置项：`super_comment/correction_enabled`。

**辅助码提示（仅 Pro）**：显示候选词的辅助码提示，<kbd>Ctrl</kbd>+<kbd>A</kbd> 循环切换辅助码提示 / 声调全拼提示 / 关闭注释，<kbd>Ctrl</kbd>+<kbd>C</kbd> 开启拆分辅助提示。

## 候选排序

**自动调频**：默认关闭，配置项：`translator/enable_user_dict`。

## 字符集过滤

可通过开关切换字符集范围（通用规范、GB2312、GBK、Big5、简繁体等），<kbd>Ctrl</kbd>+<kbd>G</kbd> 快捷切换。支持联动简繁转换开关，对不同开关单独配置字符集范围和黑白名单。配置项：`charset_filter`。

## 输入预测

**输入预测**：上屏后弹出预测候选（推荐仅在手机端开启），或置顶预测候选词。配置项：`user_predict`。

**联想空格打断**：空格键打断联想并上屏空格。配置项：`super_processor/enable_predict_space` / `user_predict/enable_predict_space`。

## 非汉字词库输入

**英文输入**：支持整句英文输入、自动句中空格、首字母/全大写格式化、空码补全。

**混合词输入**：支持包含字母、汉字、数字、特殊符号的混合词输入。

**短码英文词前置**：输入编码末尾追加 `/` 可前置短码英文词候选。

## 其他功能

**空码回溯**：输入编码无候选时，显示上一次候选，可直接空格上屏，减少回删操作。

**Unicode 输入**：`U` + Unicode 编码输入对应字符。配置项：`recognizer/patterns/unicode`。

**短语格式化**：将 `custom_phrase.txt` 中的 `\n`、`\s`、`\t` 解析为换行、空格、制表符。

**循环切换分词**：多次按下分词键 <kbd>'</kbd> 循环切换分词模式。配置项：`manual_segmentor`。

**小键盘行为**：小键盘不直接上屏。配置项：`keypad_composer`。

**删除键限制**（仅 Weasel 小狼毫生效）：输入中持续删除至编码为空时，阻止删除已上屏内容。配置项：`super_processor/enable_backspace_limit`。

**输入长度限制**：限制重复按键输入或分词过多的编码。配置项：`super_processor/limit_repeated`。

**候选词部分上屏**：<kbd>Ctrl</kbd> + 数字键上屏首选前 N 字，并保留后续编码。

## RIME 内建功能

**用户词删除**：<kbd>Ctrl</kbd>+<kbd>Del</kbd> 软删除用户词。

**循环切换音节**：多次按 <kbd>Tab</kbd> 循环切换分词位置，<kbd>Ctrl</kbd>+<kbd>Tab</kbd> 逐字确认。配置项：`key_binder`。

**自动上屏**：三四位简码唯一时自动上屏。默认关闭，配置项：`speller/auto_select`。

**数字后自动半角**：中文状态下数字后输入符号自动转换为半角标点。默认关闭，配置项：`punctuator/digit_separators`、`punctuator/digit_separator_action`。
