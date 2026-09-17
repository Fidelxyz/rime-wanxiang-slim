#!/usr/bin/env bash
set -euo pipefail

branch="$1"

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
  echo "    万象拼音精简版 - ${branch}"
  echo "install_files: >-"
  echo "  custom/**/*"
  echo "  dicts/**/*"
  echo "  lua/**/*"
  echo "  opencc/**/*"
  echo "  install.*"
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
  echo "    万象拼音精简版（仅词库）- ${branch}"
  echo "install_files: >-"
  echo "  dicts/**/*"
  echo "  opencc/dicts/**/*"
} > "plum/dicts.recipe.yaml"
