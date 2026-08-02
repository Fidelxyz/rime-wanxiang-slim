---
outline: deep
---

# 字符集过滤

通过开关切换候选字符集范围，过滤超出范围的候选。

## 切换开关

在[方案选单](https://github.com/rime/home/wiki/UserGuide#%E4%BD%BF%E7%94%A8%E6%96%B9%E6%A1%88%E9%81%B8%E5%96%AE)中切换「大字集」/「小字集」选项，或在输入法窗口按下 `Ctrl` + `G`，可开启或关闭默认 GBK 字符集过滤。

亦可通过 `option` 选项为每个字符集过滤器单独设置开关。

### 简繁转换联动

简繁转换开关 `s2t`、`s2hk`、`s2tw` 各自联动对应的字符集过滤规则。开启简繁转换时，候选将自动限定在对应的繁体字符集范围内。

## 过滤规则

- 候选文本中任一汉字字符不在允许范围内，即丢弃整个候选。
- 候选中的字母、数字、符号等非汉字字符不参与过滤。
- Unicode 输入、标点、反查（辅助筛选）产生的候选不参与过滤。

## 配置

```yaml
# 字符集过滤
charset_filter:
  # 字符集过滤器列表。
  # 每个过滤器包含以下选项：
  # option: 触发过滤的开关。可配置单个字符串、字符串列表（任一开关开启即生效），或 true（常开）。
  # charset: 启用的字符集，可设置多个选项，取并集。支持的选项：
  #   a: 通用规范汉字表
  #   b: GB2312
  #   g: GBK
  #   T: Big5
  #   j: 简体 (OpenCC t2s)
  #   f: 通用繁体 (OpenCC s2t)
  #   h: 香港繁体 (OpenCC s2hk)
  #   t: 台湾繁体 (OpenCC s2tw)
  #   u: Unicode 基本区
  #   A-I: Unicode 扩展 A-I 区
  #   c: Unicode CJK 兼容表意文字区
  # whitelist: 针对单个字符的白名单。
  # blacklist: 针对单个字符的黑名单。
  filters:
    - option: charset_filter
      charset: g
      whitelist: ""
      blacklist: ""
    - option: s2t
      charset: fa
      whitelist: ""
      blacklist: ""
    - option: s2hk
      charset: ha
      whitelist: ""
      blacklist: ""
    - option: s2tw
      charset: ta
      whitelist: ""
      blacklist: ""
```

### 字符集

`charset` 选项控制过滤的字符集范围。

使用单个字符标记表示对应的字符集：

| 标记 | 字符集 |
| --- | --- |
| `a` | 通用规范汉字表 |
| `b` | GB2312 |
| `g` | GBK |
| `T` | Big5 |
| `j` | 简体（OpenCC t2s） |
| `f` | 通用繁体（OpenCC s2t） |
| `h` | 香港繁体（OpenCC s2hk） |
| `t` | 台湾繁体（OpenCC s2tw） |
| `u` | Unicode 基本区 |
| `A` - `I` | Unicode 扩展 A-I 区 |
| `c` | Unicode CJK 兼容表意文字区 |

在选项字符串中包含多个标记字符，可为同一个过滤器设置多个字符集，最终结果取**并集**。

::: info 示例

`charset: fa` 表示「通用规范汉字表」与「通用繁体」的并集。

:::

### 黑白名单

`whitelist` / `blacklist` 配置为字符串，其中每个字符单独生效。

优先级：黑名单 > 白名单 > 字符集。
