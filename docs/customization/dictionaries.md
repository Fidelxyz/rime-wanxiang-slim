---
outline: deep
---

# 自定义词库

## 用户短语

从 `custom` 文件夹下复制 `custom_phrase.txt` 到用户目录根目录后，可在该文件中添加用户短语。

## 自定义主词库

为避免更新时修改被覆盖，不建议直接修改方案的词库文件，而是创建新的自定义词库文件，通过以下其中一种方式添加用户词库。

### 方法一：追加新词库

该方法适用于**仅追加新词库**的情形。

新建词库文件 `your_user_dict.dict.yaml`，并在 `translator/packs` 项下引入新的词典：

::: code-group

```yaml [wanxiang.custom.yaml]
patch:
  translator/packs/+:
    - your_user_dict
```

:::

### 方法二：修改方案引用词库

该方法适用于需要**修改方案词库**的情形。

复制方案词库文件 `wanxiang.dict.yaml` 并重命名，并更新所有方案文件中的引用：

::: code-group

```yaml [wanxiang.custom.yaml]
patch:
  translator/dictionary: your_user_dict
  user_dict_set/dictionary: your_user_dict
  add_user_dict/dictionary: your_user_dict
```

:::

### 扩展词库数据

部分扩展词库数据未默认启用，可查阅 `wanxiang.dict.yaml` 中的注释项，通过上述方式按需开启：

| 词库文件 | 用途 |
| --- | --- |
| `lianxiang.dict.yaml` | 联想词库 |
| `renming.dict.yaml` | 人名词库 |
| `wuzhong.dict.yaml` | 物种词库 |
