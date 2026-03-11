# Rime Custom Patch 语法指南

## 基本概念

**权重优先级**：`custom.yaml` > `schema.yaml` > `default.yaml`

- 修改 `wanxiang.schema.yaml` → 创建/修改 `wanxiang.custom.yaml`
- `dict.yaml` 不能被 patch
- **一个 custom 文件顶层必须只有一个 `patch:`**
- 其他顶层内容（如模糊音段落）必须放在文件末尾，不能插在 `patch:` 中间

### 关于"最终态"

编译时，Rime 会先递归处理 `__include`、`__patch`、`__append` 等指令，展开为最终形态（可在 `build/` 文件夹查看）。Custom patch 针对的是这个最终形态，因此不能 patch 一个含有 `__include` 的段落。

## 引用指令

### `__include` — 引用段落内容

```yaml
schema:
  __include: xxx          # 将顶层段落 xxx 的内容放到 schema 下

__include: xxx            # 将顶层段落 xxx 的内容放到与 schema 同级（注意缩进）

schema:
  __include: wanxiang_algebra:/xxx  # 从外部文件引用段落
```

### `__patch` 与 `__append` — 叠加引用

`__patch` 可在 `__include` 之后叠加引入另一个段落（两个 `__include` 叠加无效）：

```yaml
patch:
  speller/algebra:
    __include: wanxiang_algebra:/mixed/通用派生规则
    __patch: wanxiang_algebra:/mixed/全拼
```

`__append` 用于将两个列表段落拼接：

```yaml
# 另一个文件中
mixed:
  全拼:
    __append:
      - xxx
      - yyy
```

## Patch 操作语法

列表下标从 **0** 开始计数。

| 操作 | 语法示例 | 说明 |
|------|----------|------|
| 追加到末尾 | `key/+:` | 在列表末尾追加值 |
| 全局替换 | `key: value` | 替换整个键（清空原有子项） |
| 局部替换 | `key/subkey: value` | 仅修改指定子键，不影响其他 |
| 替换指定行 | `key/@N:` | 替换第 N+1 行（下标从0起） |
| 替换末尾行 | `key/@last:` | 替换最后一行 |
| 插入到指定行前 | `key/@before N:` | 在第 N+1 行前插入，后续行后移 |

> [!NOTE]
> 不支持删除键值对（`key/-:`），但可[通过覆盖或置空实现删除效果](#示例删除值的两种方法)。

### 示例：三种常用替换方式

**整体替换**：清空 engine 下所有内容，只保留 translators 一项

```yaml
patch:
  engine:
    translators:
      - table_translator@custom_phrase
```

**部分替换**：只清空 translators，engine 其他模块不受影响

```yaml
patch:
  engine/translators:
    - table_translator@custom_phrase
```

**追加**：translators 原有内容不变，末尾新增一项

```yaml
patch:
  engine/translators/+:
    - table_translator@custom_phrase
```

### 示例：删除值的两种方法

**方法一：整体覆盖，注释掉不需要的行**（适合列表）

```yaml
patch:
  engine/filters:
    - lua_filter@*chars_filter
    - lua_filter@*cold_word_drop.filter
    - lua_filter@*assist_sort
    - lua_filter@*autocap_filter
    - reverse_lookup_filter@radical_reverse_lookup
    - lua_filter@*pro_preedit_format
    - simplifier@emoji
    - simplifier@traditionalize
    - simplifier@mars
    - simplifier@chinese_english
    - simplifier@zrm_chaifen
    - lua_filter@*search@radical_pinyin
    #- lua_filter@*en_spacer       # 注释掉即为删除
    - lua_filter@*pro_comment_format
    - uniquifier
```

**方法二：将键值置空**（适合单个键值对）

```yaml
patch:
  custom_phrase/user_dict:
  custom_phrase/initial_quality:
```

### 注意：engine 模块顺序敏感

`engine` 下的组件（processors、translators、filters）有顺序要求。若用 `/+` 追加，新项会排到末尾，可能导致功能失效。

**错误示例**（新项排到末尾）：
```yaml
patch:
  engine/translators/+:
    - table_translator@custom_phrase
```

**正确示例**（插入到指定位置）：
```yaml
patch:
  engine/translators/@before 5:   # 插入到第6行前，原第6行后移
    table_translator@custom_phrase  # 注意：不加短横线 -
  engine/translators/@5:           # 替换第6行
    table_translator@custom_phrase
```

### `/` 路径与缩进的区别

`menu/page_size: 10` 与 `menu: {page_size: 10}` **行为不同**：

- `menu/page_size: 10` — 局部修改，`menu` 下其他键不受影响
- `menu: {page_size: 10}` — 全局替换，`menu` 下原有内容**全部清空**
