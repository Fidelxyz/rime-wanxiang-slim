# AGENTS.md — Wanxiang Pinyin (万象拼音)

## Project Overview

Rime input method schema for Chinese pinyin input. **Not a compiled software project** — it is a
collection of YAML configuration files, Lua extensions, and dictionary data for the
[Rime Input Method Engine](https://rime.im/). Author: `amzxyz`.

### Directory Structure

```
├── lua/wanxiang/          # 17 Lua plugin modules (core logic)
├── lua/data/              # Data files for Lua plugins (emoji, charset, OpenCC)
├── dicts/                 # Dictionary data files (.dict.yaml)
├── custom/                # Custom configuration templates, pro schema variants
├── .github/workflows/     # CI/CD (GitHub Actions)
├── wanxiang.schema.yaml   # Main input schema definition
├── wanxiang_algebra.yaml  # Spelling algebra rules (1391+ lines, 12+ pinyin schemes)
├── default.yaml           # Rime global settings
└── version.txt            # Canonical version (managed by release-please)
```

## Build / Release / Test Commands

There is **no traditional build system** (no Makefile, npm, cargo, etc.) and **no test framework**.

## Lua Code Style

All Lua source files are in `lua/wanxiang/`. They are loaded by the Rime engine as processor,
filter, or translator plugins.

### Module Pattern
```lua
-- Module table at top of file, returned at end
local M = {}       -- or: local F = {}, local AP = {}, etc.

function M.init(env)   -- Rime lifecycle: called on schema load
function M.func(input, env)  -- Rime lifecycle: main processing function
function M.fini(env)   -- Rime lifecycle: cleanup on schema unload

return M
```
Some simpler modules return a single function directly (`return translator`, `return unicode`).

### Imports / Requires
```lua
local wanxiang = require("wanxiang/wanxiang")  -- shared utilities
local userdb = require("wanxiang/userdb")      -- database utilities
```
- The shared module `wanxiang.lua` provides utility functions, version constant, and device detection.

### Formatting
- **Strings**: Double quotes `"string"` is dominant. Single quotes appear in table keys and
  symbol definitions.
- **Blank lines**: Separate logical sections. Major function groups separated by comment headers.

### Comments
- **Single-line** `-- comment` is the standard. Chinese-language comments dominate.
- **Section headers**: `-- 1. 全局常量定义 (Constants)`, `-- 2. 核心辅助函数 (Utilities)`
- **File headers**: Feature description at the top.
- **EmmyLua/LuaLS annotations** are used in `wanxiang.lua` and `librime.lua`:
  ```lua
  ---@param env Env
  ---@return boolean
  ---@diagnostic disable: undefined-global
  ```
  `librime.lua` is a full `---@meta rime` type stub file (not meant to be required at runtime).

### Error Handling
- `pcall` for Rime API calls that may fail (config access, key iteration):
  ```lua
  local ok_map, map = pcall(function() return config:get_map("path") end)
  ```
- Guard clauses with early returns:
  ```lua
  if not context or not context.composition or context.composition:empty() then
      return false
  end
  ```
- `io.open` checked for nil before use; files always closed after use.
- No `assert()` or `error()` usage — Lua errors crash the input method, so defensive coding
  with nil checks is preferred.

### Rime-Specific Patterns
- `yield(Candidate(...))` to output candidates from translators/filters.
- `env.engine.schema.config:get_string(...)` / `get_bool(...)` / `get_int(...)` for config access.
- `env.engine.context` for input context, composition, and segments.
- Process results: `0` (kRejected), `1` (kAccepted), `2` (kNoop).
- Segment tags: `seg:has_tag("unicode")`, `seg:has_tag("wanxiang_reverse")`, etc.

## YAML Style

- **Indentation**: 2 spaces.
- **Comments**: Chinese-language. Inline `# comment` with whitespace alignment padding.
  Full-line `#` comments for section headers. Commented-out config preserved with `#`.
- **Quoting**: Double quotes for version strings and special values. Single quotes for symbol
  definitions. Unquoted for simple identifiers.
- **Flow style**: `states: [ 中文, 英文 ]`, `{ when: has_menu, accept: minus, send: Page_Up }`.
- **Block style**: `description: |` for multiline strings.
- **Modular composition**: Heavy use of `__patch`, `__include`, `__append` directives.

## Documentation

- **README.md**: The primary project documentation, containing installation instructions,
  configuration guides, and a high-level feature overview.
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

1. **No test suite** — There are no tests to run. Verify changes by reading code carefully.
2. **Rime globals** — `rime_api`, `yield`, `Candidate`, `log`, `utf8` are provided by the Rime
   engine runtime and will show as undefined in static analysis.
3. **Dictionary files** — `.dict.yaml` files contain large datasets. Avoid reading entire
   dictionary files; they can be tens of thousands of lines.
4. **Chinese documentation** — README, comments, and commit messages are in Chinese. This is
   intentional and should be maintained.
5. **Conventional commits** — Use the format: `feat:`, `fix:`, `dict:`, `perf:`, `refactor:`,
   `docs:`, `chore:`, `ci:`. Messages may be in Chinese.
6. **Release file exclusions** — Markdown (`*.md`) and image (`*.jpg`, `*.png`) files are
   excluded from release ZIP packages in `release-build.sh`. When adding or renaming
   documentation or image files, update the `--exclude` and `--include` patterns in the rsync
   calls within that script to ensure the new files are properly excluded from (or included in)
   the release packages.
