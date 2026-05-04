---
outline: deep
---

# 快速上手

## 切换输入方案

在输入状态下，输入以下命令切换对应方案。切换后需**重新部署**。

### 切换拼音方案

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

### 辅助码引导模式

| 命令 | 辅助码引导模式 |
| --- | --- |
| `/jjf` | 间接辅助 |
| `/zjf` | 直接辅助 |

关于辅助码引导模式的说明，详见[辅助码](/features/auxiliary-code)章节。

## 切换输入模式或功能开关

按下 `Ctrl` + `` ` ``，可呼出[方案选单](https://github.com/rime/home/wiki/UserGuide#%E4%BD%BF%E7%94%A8%E6%96%B9%E6%A1%88%E9%81%B8%E5%96%AE)。在方案选单中，可开启或关闭特定的输入模式或功能开关。

具体功能说明及配置方法相见「功能详解」章节。

## 对方案进行自定义

**自定义文件** `custom.yaml` 是对方案文件 `schema.yaml` 的补丁，用于存放用户对方案配置的修改，更新方案时不会被覆盖。

自定义文件 `custom.yaml` 位于**[用户目录](https://github.com/rime/home/wiki/UserData)根目录**（方案文件 `schema.yaml` 旁）。通过指令切换方案时，脚本已自动将自定义文件模板从 `custom` 文件夹复制到根目录完成初始化。

> [!TIP]
> 请勿修改 `custom` 文件夹中的文件。该文件夹为模板仓库，位于此处的配置不会生效。

以下为万象拼音的方案文件与对应的自定义文件：

| 方案文件 | 自定义文件 | 用途 |
| --- | --- | --- |
| `default.yaml` | `default.custom.yaml` | 全局配置 |
| `wanxiang.schema.yaml` | `wanxiang.custom.yaml` | <Badge>仅 Base</Badge> 输入方案配置 |
| `wanxiang_pro.schema.yaml` | `wanxiang_pro.custom.yaml` | <Badge>仅 Pro</Badge> 输入方案配置 |
| `wanxiang_english.schema.yaml` | `wanxiang_english.custom.yaml` | 英文输入子方案 |
| `wanxiang_mixedcode.schema.yaml` | `wanxiang_mixedcode.custom.yaml` | 中英混合词输入子方案 |
| `squirrel.yaml` | `squirrel.custom.yaml` | <Badge>仅鼠须管</Badge> 输入法前端配置 |
| `weasel.yaml` | `weasel.custom.yaml` | <Badge>仅小狼毫</Badge> 输入法前端配置 |

如需自定义，请查阅对应的**方案文件**找到需要修改的选项，并在补丁文件下的 `patch` 项下添加补丁项。

关于方案文件选项的解释，详见 [`Schema.yaml` 详解](https://github.com/LEOYoon-Tsaw/Rime_collections/blob/master/Rime_description.md)。

关于自定义文件的使用方法，详见 [Rime 定制指南](/customization/rime)。
