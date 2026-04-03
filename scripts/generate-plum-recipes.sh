#!/usr/bin/env bash
set -euo pipefail

scheme="$1"
branch="$2"

mkdir -p plum

#################################
# Generate plum/full.recipe.yaml
#################################
{
  echo "# encoding: utf-8"
  echo "---"
  echo "recipe:"
  echo "  Rx: plum/full"
  echo "  args:"
  echo "  description: >-"
  echo "    万象拼音 ${scheme} 版（整个方案目录）- 分支 ${branch}"
  echo "install_files: >-"
  echo "  custom/**/*"
  echo "  dicts/**/*"
  echo "  lua/**/*"
  echo "  *.yaml"
  echo "  CHANGELOG.md"
  echo "  README.md"
  echo "  LICENSE"
} > "plum/full.recipe.yaml"

#################################
# Generate plum/dicts.recipe.yaml
#################################
{
  echo "# encoding: utf-8"
  echo "---"
  echo "recipe:"
  echo "  Rx: plum/dicts"
  echo "  args:"
  echo "  description: >-"
  echo "    万象拼音 ${scheme} 版，仅词库（dicts-only）- 分支 ${branch}"
  echo "install_files: >-"
  echo "  dicts/**/*"
} > "plum/dicts.recipe.yaml"
