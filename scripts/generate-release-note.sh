#!/usr/bin/env bash
set -euo pipefail

packages=(
    "zrm:自然码"
    "flypy:小鹤"
    "moqi:墨奇"
    "hanxin:汉心"
    "wubi:五笔前二"
    "tiger:虎码首末"
    "shouyou:首右"
    "shyplus:首右+"
    "wx:万象"
)

repo_url="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}"
download_url="${repo_url}/releases/download/${TAG_NAME}"

changes="$(gh release view --json body -t "{{.body}}" "${TAG_NAME}" | sed '1d; /./,$!d')"

##########################
# Print the release note #
##########################

if [[ -n "${PRERELEASE}" ]]; then
    echo "> [!WARNING]"
    echo "> 这是一个**预发布版本**，其功能可能尚未稳定，配置和行为可能随时发生变化。除非您明确了解您在做什么，否则不建议日常使用该版本。"
    echo ">"
    echo "> 对于普通用户，建议使用[稳定版](${repo_url}/releases/latest)。"
    echo ""
fi

echo "## 更新日志"
echo ""
echo "${changes}"
echo ""
echo "## 输入方案下载"
echo ""
echo "关于不同输入方案之间的区别，详见[方案选择](https://fidel.js.org/rime-wanxiang-slim/getting-started/installation#%E6%96%B9%E6%A1%88%E9%80%89%E6%8B%A9)。"
echo ""
echo "### 基础版（Base）"
echo ""
echo "支持**全拼**和**双拼**方案，不支持辅助码。"
echo ""
echo "- 下载地址：[rime-wanxiang-base.zip](${download_url}/rime-wanxiang-base.zip)"
echo ""
echo "### 进阶版（Pro）"
echo ""
echo "支持**双拼**方案与**辅助码**方案自由组合。"
echo ""
echo "每一个 zip 压缩包对应一种**辅助码**方案的配置，请根据您使用的**辅助码**方案下载对应压缩包。每种辅助码方案配置均支持切换**任意双拼方案**。"
echo ""

for entry in "${packages[@]}"; do
    type="${entry%%:*}"
    name="${entry##*:}"
    echo "- ${name}辅助码：[rime-wanxiang-${type}-fuzhu.zip](${download_url}/rime-wanxiang-${type}-fuzhu.zip)"
done

echo ""
echo "## 可选数据下载"
echo ""
echo "### 语法模型"
echo ""
echo "语法模型需单独下载，并放入输入法用户目录根目录（方案文件旁）即可启用。"
echo ""
echo "- 下载地址：[wanxiang-lts-zh-hans.gram](https://github.com/amzxyz/RIME-LMDG/releases/download/LTS/wanxiang-lts-zh-hans.gram)"
