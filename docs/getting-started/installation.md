---
outline: deep
---

# 安装

> [!NOTE]
> 万象拼音输入方案依赖 Rime 前端。关于安装 Rime 的详细步骤，可参考 [oh-my-rime 方案提供的 Rime 安装指南](https://www.mintimate.cc/zh/guide/installRime.html)。

## 方案选择

万象拼音输入方案提供了两种版本：**标准版（Base）**和**进阶版（Pro）**，主要区别在于是否支持**辅助码**筛选。

|  | 标准版 (Base) | 进阶版 (Pro) |
| --- | --- | --- |
| **方案名称** | `wanxiang` | `wanxiang_pro` |
| **辅助码** | **不适用** | **9 种辅助码可选**，支持**直接引导**或**间接引导** |
| **自动调频** | 默认开启 | 默认关闭 |
| **用户词记录** | 自动造词 | 手动造词或自动造词 |

> [!IMPORTANT]
> **进阶版**方案根据辅助码方案的不同分为了多个包体。每一个包体对应一种**辅助码**方案的配置，请根据您使用的辅助码方案下载对应压缩包。每种辅助码方案配置均支持切换**任意拼音方案**。

## 安装方案

### 手动安装

1. 从 [Release](https://github.com/Fidelxyz/rime-wanxiang-slim/releases) 页面下载方案文件。
2. 将解压后的文件放入 Rime **用户目录**。
3. 在输入法菜单中，点击「重新部署」。

### 通过东风破（Plum）安装

[东风破](https://github.com/rime/plum)是 Rime 官方的命令行配置管理工具。

::: info Windows 用户注意事项
Windows 用户须使用 Git Bash 运行脚本，不支持 PowerShell 或 Command Prompt。
:::

1. 克隆 plum 分支。

    ```bash
    git clone https://github.com/Fidelxyz/rime-wanxiang-slim.git -b plum --depth 1
    cd plum
    ```

2. 若使用 [IBus](https://github.com/rime/ibus-rime) 或 [Fcitx 5](https://github.com/fcitx/fcitx5) 前端，需设置 `rime_frontend` 环境变量。

    ```bash
    # IBus
    export rime_frontend='rime/ibus-rime'
    # Fcitx 5
    export rime_frontend='fcitx/fcitx-rime'
    ```

3. 执行安装命令。

    万象拼音为每个输入方案提供了两种[配方](https://github.com/rime/home/wiki/Recipes)：**完整安装**与**仅词库安装**。推荐首次安装时使用完整安装，仅词库安装可供后续更新词库使用。

    **基础版（Base）**：

    ```bash [基础版]
    # 完整
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-base:plum/full
    # 仅词库
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-base:plum/dicts
    ```

    **进阶版（Pro）**：

    ::: code-group

    ```bash [自然码辅助]
    # 完整
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-zrm-fuzhu:plum/full
    # 仅词库
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-zrm-fuzhu:plum/dicts
    ```

    ```bash [小鹤形码辅助]
    # 完整
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-flypy-fuzhu:plum/full
    # 仅词库
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-flypy-fuzhu:plum/dicts
    ```

    ```bash [墨奇码辅助]
    # 完整
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-moqi-fuzhu:plum/full
    # 仅词库
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-moqi-fuzhu:plum/dicts
    ```

    ```bash [汉心码辅助]
    # 完整
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-hanxin-fuzhu:plum/full
    # 仅词库
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-hanxin-fuzhu:plum/dicts
    ```

    ```bash [五笔前二辅助]
    # 完整
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-wubi-fuzhu:plum/full
    # 仅词库
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-wubi-fuzhu:plum/dicts
    ```

    ```bash [虎码首末辅助]
    # 完整
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-tiger-fuzhu:plum/full
    # 仅词库
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-tiger-fuzhu:plum/dicts
    ```

    ```bash [首右码辅助]
    # 完整
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-shouyou-fuzhu:plum/full
    # 仅词库
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-shouyou-fuzhu:plum/dicts
    ```

    ```bash [首右+辅助]
    # 完整
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-shyplus-fuzhu:plum/full
    # 仅词库
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-shyplus-fuzhu:plum/dicts
    ```

    ```bash [万象码辅助]
    # 完整
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-shyplus-fuzhu:plum/full
    # 仅词库
    bash rime-install Fidelxyz/rime-wanxiang-slim@wanxiang-shyplus-fuzhu:plum/dicts
    ```

    :::

## 安装语法模型 <Badge type="info" text="可选" />

Rime 中集成的[八股文语法插件（librime-octagram）](https://github.com/lotem/librime-octagram)提供了上下文组句功能，用于提高长句输入的准确率。该功能为可选项，安装语法模型后会自动启用。

原版万象拼音提供了配套的万象语法模型 [RIME-LMDG](https://github.com/amzxyz/RIME-LMDG)。下载后放入 Rime 用户目录根目录（方案文件旁）并重新部署即可启用。
