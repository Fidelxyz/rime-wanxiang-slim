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

### Packaging (CI only)
```bash
# Run from repo root — packages all schema variants into ZIP files
bash .github/workflows/scripts/release-build.sh

# Generates release notes
bash .github/workflows/scripts/generate-release-note.sh
```

### Release Management
- **Versioning**: Automated via [release-please](https://github.com/googleapis/release-please).
- **Canonical version**: `version.txt` (also patched into `lua/wanxiang/wanxiang.lua` via release-please `extra-files`).
- **Commit style**: [Conventional Commits](https://www.conventionalcommits.org/) — `feat:`, `fix:`, `dict:`, `perf:`, `refactor:`, `docs:`, `chore:`, `ci:`.
  - `dict:` is a **custom commit type** for dictionary updates.
- **Schema YAML files** use `version: "LTS"` (fixed label, not the numeric version).

### CI Workflows (GitHub Actions)
| Workflow | Purpose |
|----------|---------|
| `release.yml` | Orchestrates release-please + build + publish |
| `release-build.yml` | Packages 8 ZIP variants (base + 7 auxiliary code types) |
| `releases-napshot.yml` | Nightly dictionary snapshots, per-scheme snapshot branches |
| `Wanxiang_Matrix.yml` | Android APK matrix build (Trime app with schema baked in) |

### Manual Testing
No automated tests exist. Testing is done by deploying the schema to a Rime client and using the
input method. After modifying Lua or YAML files, redeploy in Rime and verify behavior manually.

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
local userdb = require("wanxiang/userdb")       -- database utilities
```
- Always use `local` for requires.
- Path uses `/` separator: `require("wanxiang/modulename")`.
- The shared module `wanxiang.lua` provides utility functions, version constant, and device detection.

### Naming Conventions
| Element | Convention | Examples |
|---------|-----------|----------|
| Module tables | Short uppercase or abbreviated | `M`, `F`, `AP` |
| Local functions | `snake_case` | `fast_type`, `is_table_type`, `get_shichen_and_ke` |
| Public module functions | `M.snake_case` or `M.PascalCase` | `M.init`, `M.func`, `wanxiang.IsChineseCharacter` |
| Constants | `UPPER_SNAKE_CASE` | `K_REJECT`, `K_ACCEPT`, `MAX_REPEAT`, `KP_MAP` |
| Local variables | `snake_case` | `code_len`, `last_seg`, `wrap_key` |
| Rime globals | As-is from Rime API | `rime_api`, `yield`, `Candidate`, `log` |

Note: Naming is not perfectly consistent. Some functions use `PascalCase` (`IsChineseCharacter`),
but `snake_case` is the dominant convention. Follow the existing style in the file you are editing.

### Formatting
- **Indentation**: 4 spaces (no tabs).
- **Strings**: Double quotes `"string"` is dominant. Single quotes appear in table keys and
  symbol definitions.
- **Line length**: No strict limit. Lines up to ~120 chars are common. Long `if` chains and
  tables often exceed 100 chars.
- **Semicolons**: Used sparingly for compact one-liners:
  ```lua
  local s=0; for _,v in ipairs(a) do s=s+v end; return s
  env.cache, env.locked = nil, false
  ```
- **Blank lines**: Separate logical sections. Major function groups separated by comment headers.

### Comments
- **Single-line** `-- comment` is the standard. Chinese-language comments dominate.
- **Section headers**: `-- 1. 全局常量定义 (Constants)`, `-- 2. 核心辅助函数 (Utilities)`
- **File headers**: Author attribution and feature description at the top:
  ```lua
  -- @amzxyz  https://github.com/amzxyz/rime_wanxiang
  -- 功能描述...
  ```
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

### Performance Patterns
- **Localize standard library functions** at module top for hot paths:
  ```lua
  local byte, find, gsub, upper, sub = string.byte, string.find, string.gsub, string.upper, string.sub
  ```
- **Caching**: Schema-level caches (e.g., `__input_type_cache`, `env.wrap_parts`) computed once
  in `init()` and reused across calls.
- **`_G.WanxiangSharedState`**: Global shared state table for cross-module communication.

### Rime-Specific Patterns
- `yield(Candidate(...))` to output candidates from translators/filters.
- `env.engine.schema.config:get_string(...)` / `get_bool(...)` / `get_int(...)` for config access.
- `env.engine.context` for input context, composition, and segments.
- Process results: `0` (kRejected), `1` (kAccepted), `2` (kNoop).
- Segment tags: `seg:has_tag("unicode")`, `seg:has_tag("wanxiang_reverse")`, etc.

## YAML Style

- **Indentation**: 2 spaces (Rime ecosystem standard).
- **Comments**: Chinese-language. Inline `# comment` with whitespace alignment padding.
  Full-line `#` comments for section headers. Commented-out config preserved with `#`.
- **File headers**: `# Rime schema` / `# Rime dictionary` + `# encoding: utf-8`.
- **Quoting**: Double quotes for version strings and special values. Single quotes for symbol
  definitions. Unquoted for simple identifiers.
- **Flow style**: `states: [ 中文, 英文 ]`, `{ when: has_menu, accept: minus, send: Page_Up }`.
- **Block style**: `description: |` for multiline strings.
- **Modular composition**: Heavy use of `__patch`, `__include`, `__append` directives.

## Shell Script Style (CI scripts)

- `#!/bin/bash` with `set -e`.
- `UPPER_SNAKE_CASE` for constants and directory paths.
- Bash arrays for lists. `rsync -av` for file operations. `zip -r -9 -q` for packaging.
- `[[ ]]` for conditionals. Chinese-language emoji-prefixed status messages.

## Key Warnings for Agents

1. **No package manager** — Do NOT run `npm install`, `pip install`, `cargo build`, etc.
2. **No test suite** — There are no tests to run. Verify changes by reading code carefully.
3. **Rime globals** — `rime_api`, `yield`, `Candidate`, `log`, `utf8` are provided by the Rime
   engine runtime and will show as undefined in static analysis. Use `---@diagnostic disable:
   undefined-global` where needed.
4. **Version management** — Do NOT manually edit version numbers. They are managed by
   release-please across `version.txt`, `.release-please-manifest.json`, and
   `lua/wanxiang/wanxiang.lua`.
5. **Dictionary files** — `.dict.yaml` files contain large datasets. Avoid reading entire
   dictionary files; they can be tens of thousands of lines.
6. **Chinese documentation** — README, comments, and commit messages are in Chinese. This is
   intentional and should be maintained.
7. **Conventional commits** — Use the format: `feat:`, `fix:`, `dict:`, `perf:`, `refactor:`,
   `docs:`, `chore:`, `ci:`. Messages may be in Chinese.
