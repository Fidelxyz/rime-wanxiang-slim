#!/usr/bin/env bash
set -euo pipefail

script_dir="$(dirname "$(realpath "$0")")"
root_dir="${script_dir}/.."
dist_dir="${root_dir}/dist"
custom_dir="${root_dir}/custom"

schema_list=(
    "base"
    "flypy"
    "hanxin"
    "moqi"
    "shouyou"
    "shyplus"
    "tiger"
    "wubi"
    "wx"
    "zrm"
)

archive=true

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-archive)
            archive=false
            shift
            ;;
        *)
            shift
            ;;
    esac
done

package_schema_base() {
    local out_dir=$1

    # Copy ${root_dir}/ to ${out_dir}/
    rsync -av \
        --exclude='.*' \
        --include='dicts/***' \
        --include='lua/***' \
        --exclude='opencc/dicts/decomposition.txt' \
        --include='opencc/***' \
        --include='README.md' \
        --include='CHANGELOG.md' \
        --include='LICENSE' \
        --exclude='wanxiang_pro.schema.yaml' \
        --include="*.yaml" \
        --exclude='*' \
        "${root_dir}/" "${out_dir}/"

    # Copy ${root_dir}/dicts/ to ${out_dir}/dicts/
    rsync -av \
        --include='*/' \
        --exclude='wanxiang_pro.custom.yaml' \
        --include='*.custom.yaml' \
        --exclude='*' \
        "${custom_dir}/" "${out_dir}/custom/"
}

package_schema_pro() {
    local schema="$1"
    local out_dir="$2"

    # Copy ${root_dir}/ to ${out_dir}/
    rsync -av \
        --exclude='.*' \
        --include='lua/***' \
        --include='opencc/***' \
        --include='README.md' \
        --include='CHANGELOG.md' \
        --include='LICENSE' \
        --exclude='wanxiang.schema.yaml' \
        --include="*.yaml" \
        --exclude='*' \
        "${root_dir}/" "${out_dir}/"

    # Copy ${root_dir}/dicts/ to ${out_dir}/dicts/
    rsync -av \
        --include='cn&en.dict.yaml' \
        --include='en.dict.yaml' \
        --exclude='*' \
        "${root_dir}/dicts/" "${out_dir}/dicts/"

    # Copy decomposition dict to ${out_dir}/
    cp "${root_dir}/custom/${schema}_chaifen.txt" "${out_dir}/opencc/dicts/decomposition.txt"

    # A hack to replace spaces with colons in decomposition.txt to adapt to OpenCC format,
    # while allowing fetching the raw chaifen.txt from upstream without modification.
    # Spaces are later recovered from colons in decomposition.txt by the `comment_format`
    # of the simplifier config.
    sed -i 's/ /:/g' "${out_dir}/opencc/dicts/decomposition.txt"

    # Copy ${root_dir}/custom/ to ${out_dir}/custom/
    rsync -av \
        --exclude='wanxiang.custom.yaml' \
        --include='*.custom.yaml' \
        --exclude='*' \
        "${root_dir}/custom/" "${out_dir}/custom/"

    # 5) Edit default.yaml: - schema: wanxiang -> - schema: wanxiang_pro
    sed -i -E 's/^([[:space:]]*)-\s*schema:\s*wanxiang\s*$/\1- schema: wanxiang_pro/' "${out_dir}/default.yaml"
}

package_schema() {
    schema_name="$1"
    echo
    echo "=== 开始打包方案：${schema_name}"

    if [[ "${schema_name}" == "base" ]]; then
        out_dir="${dist_dir}/rime-wanxiang-base"
        package_schema_base "${out_dir}"
    else
        out_dir="${dist_dir}/rime-wanxiang-${schema_name}-fuzhu"
        package_schema_pro "${schema_name}" "${out_dir}"
    fi

    if [[ "${archive}" == "true" ]]; then
        zip_name="$(basename "${out_dir}").zip"
        (cd "${out_dir}" && zip -r -q "../${zip_name}" .)
        echo "=== 完成打包: ${zip_name}"
    else
        echo "=== 跳过归档: $(basename "${out_dir}")"
    fi
}


rm -rf "${dist_dir}"
mkdir -p "${dist_dir}"

echo "=== 生成 PRO 词库"
python3 "${script_dir}/generate_pro_dicts.py"
echo "=== 生成 PRO 词库完成"

for schema in "${schema_list[@]}"; do
    package_schema "${schema}"
done
