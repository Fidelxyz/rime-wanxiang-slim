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

echo "## 更新日志"
echo ""
echo "${changes}"
echo ""
echo "## 输入方案下载"
echo ""
echo "### 拼音输入方案（Base）"
echo ""
echo "适用于**不使用辅助码**的用户。"
echo ""
echo "- 下载地址：[rime-wanxiang-base.zip](${download_url}/rime-wanxiang-base.zip)"
echo ""
echo "### 拼音+辅助码输入方案（Pro）"
echo ""
echo "支持任意**拼音+辅助码方案**自由组合。"
echo ""
echo "每一个 zip 压缩包对应一种**辅助码**方案的配置，请根据您使用的辅助码方案下载对应压缩包。每种辅助码方案配置均支持切换**任意拼音方案**。"
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
echo "语法模型需单独下载，并放入输入法用户目录根目录（方案文件旁），无需配置。"
echo ""
echo "- 下载地址：[wanxiang-lts-zh-hans.gram](https://github.com/amzxyz/RIME-LMDG/releases/download/LTS/wanxiang-lts-zh-hans.gram)"
