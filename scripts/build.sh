#!/usr/bin/env bash
set -euo pipefail

script_dir="$(dirname "$(realpath "$0")")"
root_dir="${script_dir}/.."
dist_dir="${root_dir}/dist"
custom_dir="${root_dir}/custom"

exclude_dict_files=(
    "wuzhong.dict.yaml"
    "renming.dict.yaml"
    "wuzhong.pro.dict.yaml"
    "renming.pro.dict.yaml"
)

schema_list=("base" "flypy" "hanxin" "moqi" "tiger" "wubi" "zrm" "shouyou")

package_schema_base() {
    local out_dir=$1

    rm -rf "${out_dir}"
    mkdir -p "${out_dir}"

    # 1) custom/：仅拷贝 yaml，排除指定文件（保留目录结构）
    mkdir -p "${out_dir}/custom"
    rsync -av --prune-empty-dirs \
        --include='*/' \
        --exclude='wanxiang_chaifen_*.dict.yaml' \
        --exclude='wanxiang_chaifen.schema.yaml' \
        --exclude='wanxiang_pro.custom.yaml' \
        --exclude='wanxiang_pro.dict.yaml' \
        --exclude='wanxiang_pro.schema.yaml' \
        --include='*.yaml' \
        --exclude='*' \
        "${custom_dir}/" "${out_dir}/custom/"

    # 2) 根目录 → ${out_dir}（不排 dicts/），排除若干
    out_base="$(basename "${out_dir}")"
    rsync -av --ignore-existing \
        --exclude='.*' \
        --exclude='/custom' \
        --exclude='/dist' \
        --exclude='/scripts' \
        --exclude='release-please-config.json' \
        --include='README.md' \
        --include='CHANGELOG.md' \
        --exclude='*.md' \
        --exclude="/$out_base" \
        "${root_dir}/" "${out_dir}/"
}

package_schema_pro() {
    local schema="$1"
    local out_dir="$2"

    rm -rf "${out_dir}"
    mkdir -p "${out_dir}"

    # 1) 移动分包后的 dicts
    if [[ -d "${dist_dir}/pro-${schema}-fuzhu-dicts" ]]; then
        mv "${dist_dir}/pro-${schema}-fuzhu-dicts" "${out_dir}/dicts"
    fi
    # 1.1) 补充必要的附加文件
    for file in "en.dict.yaml" "cn&en.dict.yaml" "chengyu.txt" "people.dict.yaml"; do
        if [[ -f "${root_dir}/dicts/${file}" ]]; then
            cp "${root_dir}/dicts/${file}" "${out_dir}/dicts/"
        fi
    done

    # 2) 复制拆分表并重命名，同时拷贝 schema
    src="${root_dir}/custom/wanxiang_chaifen_${schema}.dict.yaml"
    dst="${out_dir}/wanxiang_chaifen.dict.yaml"
    [[ -f "$src" ]] && cp "$src" "$dst"

    for file in \
        wanxiang_pro.dict.yaml \
        wanxiang_pro.schema.yaml \
        wanxiang_chaifen.schema.yaml
    do
        src="${root_dir}/custom/${file}"
        dst="${out_dir}/${file}"
        [[ -f "$src" ]] && cp "$src" "$dst"
    done

    # 3) custom/：仅拷贝 yaml，排除若干（保留目录结构）
    mkdir -p "${out_dir}/custom"
    rsync -av --prune-empty-dirs \
        --include='*/' \
        --exclude='wanxiang.custom*' \
        --exclude='wanxiang_chaifen_*.dict.yaml' \
        --exclude='wanxiang_chaifen.schema.yaml' \
        --exclude='wanxiang_pro.dict.yaml' \
        --exclude='wanxiang_pro.schema.yaml' \
        --include='*.yaml' \
        --exclude='*' \
        "${root_dir}/custom/" "${out_dir}/custom/"

    # 4) 根目录 → ${out_dir}
    rsync -av --ignore-existing \
        --exclude='.*' \
        --exclude='/custom' \
        --exclude='/dicts' \
        --exclude='/dist' \
        --exclude='/scripts' \
        --exclude='release-please-config.json' \
        --include='README.md' \
        --include='CHANGELOG.md' \
        --exclude='*.md' \
        --exclude='wanxiang.dict.yaml' \
        --exclude='wanxiang.schema.yaml' \
        "${root_dir}/" "${out_dir}/"

    # 5) default.yaml: - schema: wanxiang -> - schema: wanxiang_pro
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

    zip_name="$(basename "${out_dir}").zip"
    # Exclude ${exclude_dict_files[@]} files for only zip packages.
    zip_exclude_args=()
    for file in "${exclude_dict_files[@]}"; do
        zip_exclude_args+=("dicts/${file}")
    done
    (cd "${out_dir}" && zip -r -q "../${zip_name}" . -x "${zip_exclude_args[@]}")
    echo "=== 完成打包: ${zip_name}"
}


rm -rf "${dist_dir}"
mkdir -p "${dist_dir}"

echo "=== PRO 分包开始"
python3 "${script_dir}/split_aux.py"
echo "=== PRO 分包完毕"

for schema in "${schema_list[@]}"; do
    package_schema "${schema}"
done
