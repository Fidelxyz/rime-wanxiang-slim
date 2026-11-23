---
outline: deep
---

# 按键绑定

Rime 提供了 `key_binder` 组件，可在指定条件下按下指定按键时，将按键转换为发送按键、切换开关或切换方案等操作。

## 配置

可在 `key_binder/bindings` 配置项下配置按键绑定。

每条绑定由触发条件 `when`、触发按键 `accept` 和一项**操作**组成。

::: info 示例

```yaml
key_binder:
  bindings:
    # Ctrl + Shift + 3 切换中英标点。
    - {when: always, accept: Control+Shift+3, toggle: ascii_punct}

    # Tab 在不同音节之间跳转。
    - {when: has_menu, accept: "Tab", send: "Control+Right"}

    # 通过 Tab 切换到第一个音节输入辅助码后，Ctrl + Tab 提交并切换至下个音节。
    - {when: composing, accept: "Control+Tab", send_sequence: '{Home}{Shift+Right}{1}{Shift+Right}'}
```

:::

### 触发条件

触发条件 `when` 的**值**接受以下选项：

- `predicting`：显示联想候选时
- `paging`：已翻页时
- `has_menu`：存在候选时（西文模式除外）
- `composing`：输入编码非空时
- `always`：任何时候

同一按键绑定多个条件时，按上述从上到下的优先级顺序匹配。

### 触发按键

触发按键 `accept` 的**值**接受一个[按键表达式](#按键表达式)。

### 操作

每条按键绑定中，接受以下任一选项作为操作的**键**：

- `send`：发送一个按键。接受[按键表达式](#按键表达式)为**值**。
- `send_sequence`：依次发送按键序列。接受[按键表达式](#按键表达式)序列为**值**，每个表达式以 `{}` 包裹。
- `toggle`：切换一个开关，或循环切换至多选开关的下一选项。接受一个开关或选项名称为**值**。
- `set_option`：开启一个开关，或选中多选开关的一个选项。接受一个开关或选项名称为**值**。
- `unset_option`：关闭一个开关，或恢复多选开关至默认选项。接受一个开关或选项名称为**值**。
- `select`：切换至指定方案 ID 的输入方案，或 `.next` 切换至下一个方案。

> [!NOTE]
> 开关或选项名称指方案文件 `schema.yaml` 中的 `switches/@n/name` 或 `switches/@n/options` 项。

### 按编码匹配的按键绑定

除 Rime 原生按 `when` 条件触发的绑定外，还支持按输入编码 `match` 条件触发的按键绑定。

::: info 示例

```yaml
key_binder:
  bindings:
    # 编码中输入 `` 进入造词模式。
    - {match: ".*`", accept: "`", send_sequence: '{BackSpace}{Home}{`}{`}{End}'}
```

:::

此类绑定接受三个键值：

- `match`：匹配的输入编码模式。接受一个正则表达式为值，需匹配完整编码。
- `accept`：触发按键。接受一个[按键表达式](#按键表达式)。
- `send_sequence`：触发后依次发送的按键序列。接受[按键表达式](#按键表达式)序列为值，每个表达式以 `{}` 包裹。

## 按键表达式

> [!INFO]
> Rime 中的按键表达式定义位于 [librime](https://github.com/rime/librime) 中的 [key_table.cc](https://github.com/rime/librime/blob/master/src/rime/key_table.cc)。

> [!IMPORTANT]
> Rime 中的按键表达式**区分大小写**。

单个字母（`A`–`Z`、`a`–`z`）或数字（`0`–`9`）即为对应按键的表达式。

此外，常用的按键表达式有[^1]：

[^1]: 修改自 [`Schema.yaml` 详解](https://github.com/LEOYoon-Tsaw/Rime_collections/blob/master/Rime_description.md)。

| 按键表达式 | 描述 |
| --- | --- |
| `BackSpace` | 退格 |
| `Tab` | 制表符 |
| `Linefeed` | 换行 |
| `Clear` | 清除 |
| `Return` | 回车 |
| `Pause` | 暂停 |
| `Sys_Req` | 印屏 |
| `Escape` | 退出 |
| `Delete` | 删除 |
| `Home` | 原位 |
| `Left` | 左箭头 |
| `Up` | 上箭头 |
| `Right` | 右箭头 |
| `Down` | 下箭头 |
| `Prior` / `Page_Up` | 上翻 |
| `Next` / `Page_Down` | 下翻 |
| `End` | 末尾 |
| `Begin` | 起始 |
| `Shift_L` | 左 Shift |
| `Shift_R` | 右 Shift |
| `Control_L` | 左 Ctrl |
| `Control_R` | 右 Ctrl |
| `Meta_L` | 左 Meta |
| `Meta_R` | 右 Meta |
| `Alt_L` | 左 Alt |
| `Alt_R` | 右 Alt |
| `Super_L` | 左 Super |
| `Super_R` | 右 Super |
| `Hyper_L` | 左 Hyper |
| `Hyper_R` | 右 Hyper |
| `Caps_Lock` | 大写锁定 |
| `Shift_Lock` | Shift 锁定 |
| `Scroll_Lock` | 滚动锁定 |
| `Num_Lock` | 小键盘锁定 |
| `Select` | 选定 |
| `Print` | 打印 |
| `Execute` | 运行 |
| `Insert` | 插入 |
| `Undo` | 还原 |
| `Redo` | 重做 |
| `Menu` | 菜单 |
| `Find` | 搜索 |
| `Cancel` | 取消 |
| `Help` | 帮助 |
| `Break` | 中断 |
| `space` | 空格 |
| `exclam` | ! |
| `quotedbl` | " |
| `numbersign` | # |
| `dollar` | $ |
| `percent` | % |
| `ampersand` | & |
| `apostrophe` | ' |
| `parenleft` | ( |
| `parenright` | ) |
| `asterisk` | * |
| `plus` | + |
| `comma` | , |
| `minus` | - |
| `period` | . |
| `slash` | / |
| `colon` | : |
| `semicolon` | ; |
| `less` | < |
| `equal` | = |
| `greater` | > |
| `question` | ? |
| `at` | @ |
| `bracketleft` | [ |
| `backslash` | \ |
| `bracketright` | ] |
| `asciicircum` | ^ |
| `underscore` | _ |
| `grave` | ` |
| `braceleft` | { |
| `bar` | | |
| `braceright` | } |
| `asciitilde` | ~ |
| `KP_Space` | 小键盘空格 |
| `KP_Tab` | 小键盘制表符 |
| `KP_Enter` | 小键盘回车 |
| `KP_Delete` | 小键盘删除 |
| `KP_Home` | 小键盘原位 |
| `KP_Left` | 小键盘左箭头 |
| `KP_Up` | 小键盘上箭头 |
| `KP_Right` | 小键盘右箭头 |
| `KP_Down` | 小键盘下箭头 |
| `KP_Prior` / `KP_Page_Up` | 小键盘上翻 |
| `KP_Next` / `KP_Page_Down` | 小键盘下翻 |
| `KP_End` | 小键盘末尾 |
| `KP_Begin` | 小键盘起始 |
| `KP_Insert` | 小键盘插入 |
| `KP_Equal` | 小键盘等于 |
| `KP_Multiply` | 小键盘乘号 |
| `KP_Add` | 小键盘加号 |
| `KP_Subtract` | 小键盘减号 |
| `KP_Divide` | 小键盘除号 |
| `KP_Decimal` | 小键盘小数点 |
| `KP_0` | 小键盘 0 |
| `KP_1` | 小键盘 1 |
| `KP_2` | 小键盘 2 |
| `KP_3` | 小键盘 3 |
| `KP_4` | 小键盘 4 |
| `KP_5` | 小键盘 5 |
| `KP_6` | 小键盘 6 |
| `KP_7` | 小键盘 7 |
| `KP_8` | 小键盘 8 |
| `KP_9` | 小键盘 9 |
