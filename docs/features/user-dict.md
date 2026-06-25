---
outline: deep
---

# 造词

## 手动造词 <Badge type="tip" text="仅 Pro" />

在编码**起始**或**末尾**处输入造词引导符 ` `` ` 进入手动造词模式，随后提交的**中文**或**英文**词条会被记录到用户词库中。

```yaml
recognizer:
  patterns:
    user_dict_appender: "^``[A-Za-z/`']*$"

user_dict_appender:
  # 手动造词引导符。
  prefix: "``"

  # 手动造词提示。
  tips: "〔造词〕"

key_binder:
  bindings:
    # 编码中输入 `` 进入造词模式。
    - {match: "^.*`$", accept: "`", send_sequence: '{BackSpace}{Home}{`}{`}{End}'}
```

## 自动造词 <Badge type="tip" text="仅 Pro" />

自动记录词库中不存在的**非句子**词条。

```yaml
user_dict_appender:
  # 启用自动造词。开启后，将自动记录词库中不存在的非句子词条。
  enable_auto_phrase: true
```
