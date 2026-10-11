---
outline: deep
---

# 自定义词库

## 用户短语

从 `custom` 文件夹下复制 `custom_phrase.txt`（或创建空白文本文件）到 [Rime **用户目录**](https://github.com/rime/home/wiki/UserData)后，可在该文件中添加用户短语。

一行代表一个用户短语，格式为：`词汇<Tab>编码<Tab>权重`，以制表符分隔。权重为可选项。

### 特殊字符转义

`custom_phrase.txt` 支持以下转义字符：

| 转义字符 | 解析结果 |
| --- | --- |
| `\n` | 换行 |
| `\s` | 空格 |
| `\t` | 制表符 |
| `\\` | 反斜杠 |

### 配置

```yaml
custom_phrase:
  dictionary: ""
  user_dict: custom_phrase
  db_class: stabledb
  enable_completion: false
  enable_sentence: false
  initial_quality: 99
```

::: tip 使用其他用户短语文件

如需改用其他用户短语文件，可在方案自定义文件 `custom.yaml` 中添加以下补丁：

```yaml
patch:
  custom_phrase/user_dict: user_custom_phrase
```

以上配置会将用户短语文件改为用户目录下的 `user_custom_phrase.txt`。

:::

## 自定义主词库

为避免更新时修改被覆盖，不建议直接修改方案的词库文件，而是创建新的自定义词库文件，通过以下其中一种方式添加用户词库。

### 方法一：追加新词库

该方法适用于**仅追加新词库**的情形。

新建词库文件 `your_user_dict.dict.yaml`，并在方案自定义文件 `custom.yaml` 中 `translator/packs` 项下引入新的词典：

```yaml
patch:
  translator/packs/+:
    - your_user_dict
```

### 方法二：修改方案引用词库

该方法适用于需要**修改方案词库**的情形。

1. 复制方案词库文件 `wanxiang.dict.yaml` 到原文件旁，并重命名为任意名称。下文以 `your_user_dict.dict.yaml` 为例。

2. 修改 `your_user_dict.dict.yaml` 中的 `import_tables` 词库引用。

3. 在方案自定义文件 `custom.yaml` 中添加补丁：

   ```yaml
   patch:
     translator/dictionary: your_user_dict
     user_dict/prism: your_user_dict
     candidate_pinner/prism: your_user_dict
     user_dict_appender/dictionary: your_user_dict
   ```

4. 修改主词库后，需使用仓库中的脚本同步生成用户目录下的 `wanxiang_syllables.dict.yaml`，然后重新部署：

   ```sh
   python3 scripts/generate_syllable_dict.py . --dictionary your_user_dict
   ```

   以后更新该主词库或其引用的词库时，也需重新运行此命令。

### 扩展词库数据

部分扩展词库数据未默认启用，可查阅 `wanxiang.dict.yaml` 中的注释项，通过上述方式按需开启：

| 词库 | 用途 |
| --- | --- |
| `dicts/association` | 联想词库 |
| `dicts/species` | 物种词库 |
| `dicts/person` | 人名词库 |
| `dicts/medical` | 医学词库 |
| `dicts/chemistry` | 化学词库 |
| `dicts/pharmaceutical` | 药品词库 |
| `dicts/celebrity` | 名人词库 |
| `dicts/artist` | 艺人词库 |
| `dicts/dialect` | 方言词库 |
| `dicts/typhoon` | 台风词库 |
