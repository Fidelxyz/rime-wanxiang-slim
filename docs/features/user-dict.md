---
outline: deep
---

# 造词

## 手动造词

在编码**起始**或**末尾**处输入造词引导符 ` `` ` 进入手动造词模式，随后提交的**中文**或**英文**词条会被记录到用户词库中。仅 Pro 默认开启。

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

::: tip <Badge type="tip" text="仅 Base" /> 启用手动造词

在方案自定义文件 `wanxiang.custom.yaml` 中添加以下补丁以启用手动造词：

```yaml
patch:
  recognizer/patterns/user_dict_appender: "^``[A-Za-z/`']*$"
  user_dict/enable_user_dict: true
  user_dict_appender/enable_user_dict: true
```

:::

## 自动造词

自动记录词库中不存在的**非句子**词条。仅 Pro 默认开启。

```yaml
user_dict_appender:
  # 启用自动造词。开启后，将自动记录词库中不存在的非句子词条。
  enable_auto_phrase: true
```

::: tip 开启或关闭自动造词

在方案自定义文件 `custom.yaml` 中添加以下补丁以开启或关闭自动造词：

```yaml
patch:
  user_dict_appender/enable_auto_phrase: true
```

:::
