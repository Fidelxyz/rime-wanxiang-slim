---
outline: deep
---

# Rime 定制指南

Rime 配置文件的优先级为 `custom.yaml` > `schema.yaml` > `default.yaml`。位于优先级较高的文件中的配置会覆盖优先级较低文件中的同名配置。

编译时，Rime 会首先递归展开 `__include`、`__patch` 和 `__append` 引用指令，随后应用 `custom.yaml` 中的补丁。最终生成的配置位于 `build` 文件夹下。

## 补丁

关于自定义文件中 `patch` 补丁的用法和示例，详见[Rime 定制指南](https://github.com/rime/home/wiki/CustomizationGuide#%E5%AE%9A%E8%A3%BD%E6%8C%87%E5%8D%97)。

基本语法：

```yaml
patch:
  "一级设定项/二级设定项/三级设定项": 新的设定值
  "另一个设定项": 新的设定值
  "再一个设定项": 新的设定值
  "含列表的设定项/@n": 列表第n个元素新的设定值，从0开始计数
  "含列表的设定项/@last": 列表最后一个元素新的设定值
  "含列表的设定项/@before 0": 在列表第一个元素之前插入新的设定值（不建议在补丁中使用）
  "含列表的设定项/@after last": 在列表最后一个元素之后插入新的设定值（不建议在补丁中使用）
  "含列表的设定项/@next": 在列表最后一个元素之后插入新的设定值（不建议在补丁中使用）
  "含列表的设定项/+": 与列表合并的设定值（必须为列表）
  "含字典的设定项/+": 与字典合并的设定值（必须为字典，注意YAML字典的无序性）
```

> [!IMPORTANT]
> 以下两种补丁的行为不同：
> 
> ```yaml
> patch:
>   dict/key: value
> ```
> 
> 仅修改 `dict` 字典下的 `key` 设定值，`dict` 字典下的其他设定值不受影响。
> 
> ```yaml
> patch:
>   dict:
>     key: value
> ```
>
> 覆盖整个 `dict` 字典，`dict` 字典下的所有设定项将被清空并替换为 `{key: value}`。

> [!TIP]
> 补丁不支持直接删除设定项（`key/-:`），但可通过以下方式实现**删除**效果：
> 
> 对于**列表**，可整体覆盖整个列表，并删除不需要的项。
> 
> ```yaml
> patch:
>   list:
>     - item1
>     - item2  # [!code --]
>     - item3
> ```
> 
> 对于**字典**，可将需要删除的键值置空。
> 
> ```yaml
> patch:
>   dict/key:
> ```

## 引用指令

关于 `__include`、`__patch` 和 `__append` 引用指令的用法和示例，详见[Rime 配置文件](https://github.com/rime/home/wiki/Configuration)。

> [!NOTE]
> 自定义文件 `custom.yaml` 中的补丁只能针对**展开引用指令后**的配置进行修改，不能修改引用指令本身。
>
> 例如，以下示例中试图修改 `__include` 指令的行为是无效的，因为该指令展开后将不再包含 `__include` 指令：
>
> ```yaml
> patch:
>   speller/algebra/__include: ... # [!code warning]
> ```
