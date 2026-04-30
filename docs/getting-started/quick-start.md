---
outline: deep
---

# 快速上手

## 切换输入方案

在输入状态下，输入以下命令切换对应方案。切换后需**重新部署**。

切换**拼音方案**：

| 命令 | 方案 |
| --- | --- |
| `/pinyin` | 全拼 |
| `/zrm` | 自然码 |
| `/znabc` | 智能ABC |
| `/flypy` | 小鹤双拼 |
| `/mspy` | 微软双拼 |
| `/sogou` | 搜狗双拼 |
| `/ziguang` | 紫光双拼 |
| `/gbpy` | 国标双拼 |
| `/pyjj` | 拼音加加 |
| `/lxsq` | 乱序17 |
| `/zrlong` | 自然龙（反查为全拼） |
| `/hxlong` | 汉心龙（反查为全拼） |

切换**辅助码引导模式**：

| 命令 | 辅助码引导模式 |
| --- | --- |
| `/jjf` | 间接辅助 |
| `/zjf` | 直接辅助 |

## 对方案进行自定义

**自定义文件** `custom.yaml` 是对方案文件 `schema.yaml` 的补丁，用于存放用户对方案配置的修改，更新方案时不会被覆盖。

自定义文件 `custom.yaml` 位于**用户目录根目录**（方案文件 `schema.yaml` 旁）。通过指令切换方案时，脚本已自动将自定义文件模板从 `custom` 文件夹复制到根目录完成初始化。

> [!NOTE]
> 请勿修改 `custom` 文件夹中的文件。该文件夹为模板仓库，位于此处的配置不会生效。

以下为万象拼音的方案文件与对应的自定义文件：

| 方案文件 | 自定义文件 | 用途 |
| --- | --- | --- |
| `default.yaml` | `default.custom.yaml` | 全局配置 |
| `wanxiang.schema.yaml` | `wanxiang.custom.yaml` | [仅基础版] 输入方案配置 |
| `wanxiang_pro.schema.yaml` | `wanxiang_pro.custom.yaml` | [仅进阶版] 输入方案配置 |
| `wanxiang_english.schema.yaml` | `wanxiang_english.custom.yaml` | 英文输入子方案 |
| `wanxiang_mixedcode.schema.yaml` | `wanxiang_mixedcode.custom.yaml` | 中英混合词输入子方案 |
| `squirrel.yaml` | `squirrel.custom.yaml` | [仅 Squirrel 鼠须管] 输入法前端配置 |
| `weasel.yaml` | `weasel.custom.yaml` | [仅 Weasel 小狼毫] 输入法前端配置 |

如需自定义，请查阅对应的**方案文件**找到需要修改的选项，并在补丁文件下的 `patch` 项下添加补丁项。

关于方案文件选项的解释，详见 [`Schema.yaml` 详解](https://github.com/LEOYoon-Tsaw/Rime_collections/blob/master/Rime_description.md)。

关于自定义文件的使用方法，详见 [Rime 定制指南](/customization/rime)。
