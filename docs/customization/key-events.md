# 键盘事件

Rime 的 `key_binder/bindings` 选项下的 `accept` 和 `send` 键值接受按键表达式。

## 按键表达式

> [!INFO]
> Rime 中的按键表达式定义位于 <https://github.com/rime/librime/blob/master/src/rime/key_table.cc>。

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
| `KP_Prior、KP_Page_Up` | 小键盘上翻 |
| `KP_Next、KP_Page_Down` | 小键盘下翻 |
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
