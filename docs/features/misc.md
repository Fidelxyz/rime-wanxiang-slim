---
outline: deep
---

# 其他功能

## 候选词部分上屏

`Ctrl` + 数字键 `N` 上屏首选前 N 字，并保留后续编码以供继续编辑。

## Unicode 输入

输入大写 `U` + 十六进制 Unicode 编码，即可输入对应字符。

## 小键盘行为

可配置的小键盘行为。

```yaml
keypad_composer:
  # 小键盘模式。
  # auto: 按下小键盘数字键时，若存在待上屏内容，则数字不直接上屏；否则数字直接上屏。
  # compose: 按下小键盘数字键时，数字总是不直接上屏。
  # select: 按下小键盘数字键时，若处于选词状态，则选择对应候选词，否则输入数字。等同于主键盘数字键行为。
  keypad_mode: auto
```

## 删除键限制 <Badge>仅小狼毫</Badge>

输入中持续删除至编码为空时，阻止删除已上屏内容。默认关闭。

```yaml
backspace_limiter:
  # 退格限制。
  # 开启时，输入中持续删除至编码为空时，阻止删除已上屏内容。
  # 仅于小狼毫前端生效。
  enabled: false
```

## 版本显示

输入 `/version` 显示输入方案及 Rime 版本信息。

## Rime 内建功能

### 用户词删除

`Ctrl` + `Del` 软删除用户词。

```yaml
editor:
  bindings:
    Control+Delete: delete_candidate  # 删除候选项
```

### 循环切换音节

`Tab` 循环切换分词位置，`Ctrl` + `Tab` 逐字提交。

```yaml
key_binder:
  bindings:
    # 通过 Tab 切换到第一个音节输入辅助码后，Ctrl + Tab 提交并切换至下个音节。
    - {when: composing, accept: "Control+Tab", send_sequence: '{Home}{Shift+Right}{1}{Shift+Right}'}
```

### 自动上屏

三四位简码唯一时自动上屏。默认关闭。

```yaml
speller:
  # 自动上屏。
  #auto_select: true
```

### 数字后自动半角

中文状态下数字后输入符号自动转换为半角标点。默认关闭。

```yaml
punctuator:
  # 数字后标点优化。
  # 指定的数字后的标点将转换为半角标点。
  #digit_separators: ":,."

  # 数字后标点优化行为。
  # commit: 数字后标点直接提交。
  #digit_separator_action: commit
```
