# AGENTS.md — Wanxiang Pinyin (万象拼音)

## Project Overview

Rime input method schema for Chinese pinyin input. **Not a compiled software project** — it is a collection of YAML
configuration files, Lua extensions, and dictionary data for the [Rime Input Method Engine](https://rime.im/).

### Directory Structure

```
├── lua/wanxiang/                # Lua plugin modules
├── lua/data/                    # Data files for Lua plugins (emoji, charset, OpenCC)
├── lua/librime.lua              # Rime's Lua API type stubs
├── dicts/                       # Dictionary data files (.dict.yaml)
├── opencc/                      # OpenCC data files for simplifier
├── custom/                      # Custom configuration templates, data files
├── scripts/                     # Build and maintenance scripts
├── tests/                       # Mira test cases
├── .github/workflows/           # CI/CD (GitHub Actions)
├── default.yaml                 # Rime global settings
├── punctuation.yaml             # Punctuation mappings
├── wanxiang.dict.yaml           # Main dictionary file
├── wanxiang.schema.yaml         # Main input schema definition for standard version
├── wanxiang_pro.schema.yaml     # Main input schema definition for pro version
├── wanxiang_english.dict.yaml   # Dictionary for English input
├── wanxiang_english.schema.yaml # Sub-schema for English input
├── wanxiang_mixcode.dict.yaml   # Dictionary for Chinese and English mixed input
├── wanxiang_mixcode.schema.yaml # Sub-schema for Chinese and English mixed input
├── wanxiang_reverse.dict.yaml   # Dictionary for reverse lookup
├── wanxiang_reverse.schema.yaml # Sub-schema for reverse lookup
└── wanxiang_algebra.yaml        # Spelling algebra rules
```

## Lua Scripts

All Lua source files are in `lua/wanxiang/`. They are registered as processor, segmentor, translator or filter modules
and configured in the YAML schema files.

### Rime's Lua API

`lua/librime.lua` is a full `---@meta rime` type stub file.

Documentation for Rime's Lua API can be found in the librime-lua documentation:
- https://github.com/hchunhui/librime-lua/wiki/Scripting
- https://github.com/hchunhui/librime-lua/wiki/API
- https://github.com/hchunhui/librime-lua/wiki/Objects

## Documentation

- **README.md**: The primary project documentation, containing installation instructions, configuration guides,
  and a high-level feature overview.
- **FEATURES.md**: A detailed mapping of project features to their implementation files.

When modifying functional code (Lua) or configuration (YAML), always check if the changes
impact the features described in `README.md` or the implementation mappings in `FEATURES.md`.
Update these documentation files accordingly to keep them in sync with the codebase.

If a feature is removed, do not just delete its entry from `FEATURES.md`.
Move it into the `## 已移除功能` section and list the deleted files/config blocks so future
merges can resolve upstream conflicts and reintroductions safely.

Also add the removed feature to the **精简说明** table in `README.md` so the fork's diff from
upstream is clearly documented for users.

## Merging from Upstream

When merging any upstream changes, **ALWAYS** follow this procedure:

### Step 1: Check for new features
Review the upstream diff/commits for any new features being introduced (i.e. The **ENTIRE** patch,
if there is any). If new features are found:

1. List all new features clearly.
2. **PAUSE and ASK the user** a **multiple-choice** question for whether to introduce each feature.
3. Based on the user's answer:
   - **Yes, introduce it**: Add the feature to the appropriate section in `FEATURES.md`.
   - **No, skip it**: Add the feature to the `## 已移除功能` section in `FEATURES.md`, documenting
   the files/config blocks involved so future merges can handle conflicts.

### Step 2: Check removed features before merging
Before merging, read the `## 已移除功能` section in `FEATURES.md`. If any upstream change touches
a feature listed there, **do not introduce it** — skip or revert that change during the merge.

### Step 3: Resolving conflicts
When resolving merge conflicts, always consult `patch.patch` to see exactly what the upstream changed.
Auto-merging can introduce false changes — do not blindly accept them. Compare each conflict hunk
against the patch to determine the correct resolution.

### Step 4: Merge docs clearly
When merging text-heavy files (e.g., Markdown docs, guides, notes), paraphrase upstream wording for
clarity and readability before finalizing the merge result.

## Key Warnings for Agents

- Typing annotations: Always add typing annotations for all functions.
- English comments: Always write comments in English.
- Defensive coding: Don't add error handling, fallbacks, or validation **for scenarios that can't happen**. Trust
  internal code and framework guarantees. **Only validate at system boundaries** (user input, external APIs).
- Conventional commits: Use the format: `build:`, `chore:`, `ci:`, `docs:`, `style:`, `refactor:`, `perf:`, `test:`.
