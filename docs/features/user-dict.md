---
outline: deep
---

# 造词

## 手动造词 <Badge type="tip" text="仅 Pro" />

在编码中**任意位置**输入造词引导符 ` `` ` 进入手动造词模式，随后提交的词条会被记录到用户词库中。

```yaml
user_dict_appender:
  # 手动造词引导符。
  prefix: "``"

  # 手动造词提示。
  tips: "〔造词〕"
```

```yaml
key_binder:
  bindings:
    # 通过 Tab 切换到第一个音节输入辅助码后，Ctrl + Tab 上屏并切换至下个音节。
    - {when: composing, accept: "Control+Tab", send_sequence: '{Home}{Shift+Right}{1}{Shift+Right}'}
```

## 自动造词 <Badge type="tip" text="仅 Pro" />

自动记录词库中不存在的**非句子**词条。

```yaml
user_dict_appender:
  # 启用自动造词。开启后，将自动记录词库中不存在的非句子词条。
  enable_auto_phrase: true
```

## 英文造词

英文编码末尾输入 `\\` 触发英文造词。

```yaml
wanxiang_english:
  # 英文造词触发符号，双击触发造词。
  user_dict_trigger: "\\"
```
