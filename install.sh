#!/bin/sh
set -eu

case "$(uname -m)" in
    x86_64 | amd64) arch=x86_64 ;;
    arm64 | aarch64) arch=aarch64 ;;
    *) echo '不支持的 CPU 架构' >&2; exit 1 ;;
esac

suffix=
case "$(uname -s)" in
    Darwin) target=${arch}-apple-darwin ;;
    Linux) target=${arch}-unknown-linux-gnu ;;
    MINGW* | MSYS* | CYGWIN*) target=${arch}-pc-windows-msvc; suffix=.exe ;;
    *) echo '不支持的操作系统' >&2; exit 1 ;;
esac

name=rime-wanxiang-slim-installer-${target}${suffix}
binary=.installer/${name}
mkdir -p .installer

set --
if [ -f "${binary}" ]; then
    set -- -z "${binary}"
fi

temp=$(mktemp "${TMPDIR:-/tmp}/rime-wanxiang-slim-installer.XXXXXX")
status=$(curl -fSL -R "${@}" -o "${temp}" -w '%{http_code}' \
    "https://github.com/Fidelxyz/rime-wanxiang-slim-installer/releases/latest/download/${name}")
if [ "${status}" = 200 ]; then
    if [ -f "${binary}" ]; then
        echo '正在更新安装程序……'
    fi
    chmod +x "${temp}"
    mv -f "${temp}" "${binary}"
fi

exec "${binary}" <"$(tty <&2)"
