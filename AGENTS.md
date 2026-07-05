# AGENTS.md — Wanxiang Pinyin (万象拼音)

## Project Overview

Rime input method schema for Chinese pinyin input. **Not a compiled software project** — it is a collection of YAML
configuration files, Lua extensions, and dictionary data for the [Rime Input Method Engine](https://rime.im/).

### Directory Structure

```
├── lua/wanxiang/                # Lua plugin modules
├── lua/utils/                   # Lua utility modules
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

All Lua source files are in `lua/wanxiang/`. They are registered as processor, segmentor, translator or filter modules and configured in the YAML schema files.

### Style Conventions

#### File Structure
Files contain the following sections in order if applicable:
1. **Module docstring**: Brief description of the module's purpose using `---` comments
2. **Author attribution**: `---@author` tags listing contributors
3. **Type definitions**: Custom `---@class` definitions for module-specific types:
   - `ModuleNameConfig`: Configuration loaded from schema YAML (e.g., `EnglishConfig`, `CharsetFilterConfig`)
   - `ModuleNameState`: Runtime state and cached data (e.g., `EnglishState`, `CharsetFilterState`)
   - Other module-specific types as needed
4. **Environment extension**: `---@diagnostic disable-next-line: duplicate-type` followed by `---@class Env` to extend the global `Env` type with:
   - `module_name_config ModuleNameConfig?`: Configuration field (nullable)
   - `module_name_state ModuleNameState?`: State field (nullable)
5. **Local dependencies**: `require()` statements for dependencies
   (e.g., `local wanxiang = require("wanxiang.wanxiang")`)
6. **Constants and static data**: Module-level constants, lookup tables, and static configuration
7. **Helper functions**: Private local functions used internally
8. **Public API**: Exported functions in a table (typically `P`, `T`, `F`, or `M`)
9. **Return statement**: Export the public API table

#### Module Lifecycle
Standard Rime module pattern with three functions defined in order:

**`init(env)`**: Initialize module state and configuration, set up event listeners
```lua
env.module_name_config = {
    -- Configuration fields loaded from schema YAML
}

env.module_name_state = {
    -- Runtime state and cached data
}
```

**`fini(env)`**: Clean up resources, disconnect event listeners, clear state
```lua
-- If notifier or db needs to be disconnected
assert(env.module_name_state)
env.module_name_state.notifier:disconnect()

env.module_name_config = nil
env.module_name_state = nil
```

**`func(..., env)`**: Main processing function (for filters/translators or processors)
```lua
local config = env.module_name_config
assert(config)
local state = env.module_name_state
assert(state)

-- Use config and state...
```

**Helper function parameter order**: When passing config/state to helper functions, follow this order if applicable:
```
([local params]..., config, state, [global params]env, ctx, ...)
```

#### Naming Conventions
- **Module tables**: Use `P` for processors, `T` for translators, `F` for filters, `M` for general utility modules
- **Functions**: Use snake_case with meaningful words; avoid abbreviations
- **Variables**: Use snake_case with meaningful words; avoid abbreviations
- **Constants**: Use SCREAMING_SNAKE_CASE for true constants
- **Type names**: Use PascalCase for class definitions

#### Type Annotations
- **All functions** must have complete type annotations using LuaLS/EmmyLua syntax
- **Parameters**: Annotate with `---@param name type` before function definitions
- **Return values**: Annotate with `---@return type` (use `?` suffix for nullable types)
- **Class fields**: Annotate each field with its type (use `?` suffix for optional fields)
- **Local variables**: Annotate complex types with `---@type` when type inference is unclear
- **Type casts**: Use `---@cast` when narrowing types after validation
- **Nil checks**: Only add `?` suffix for types that can actually be nil; trust Rime API types defined in `librime.lua` to never be nil unless explicitly marked

#### Comments
- **All comments** must be written in English
- Use `---` for documentation comments (LuaLS annotations)
- Use `--` for inline explanatory comments

#### Code Organization
- **Column width**: Limit to 120 characters.
- **Goto labels**: Use `::continue::` for loop continuation (placed at end of loop body)
- **Early returns**: Prefer early returns for validation and edge cases
- **Guard clauses**: Use assertions (`assert()`) to validate required state/config
- **Table construction**: Initialize tables with explicit types when non-empty (e.g., `---@type string[]`)
- **List appending**: Use cached local variables for list length when appending in loops
- **String manipulation**: Use method syntax for string operations (e.g., `str:sub()`, `str:len()`) for readability

#### Defensive coding
Don't add error handling, fallbacks, or validation **for scenarios that can't happen**. Trust internal code and framework guarantees. **Only validate at system boundaries** (user input, external APIs).

### Rime's Lua API

`lua/librime.lua` is a full `---@meta rime` type stub file.

Documentation for Rime's Lua API can be found in the librime-lua documentation:
- https://github.com/hchunhui/librime-lua/wiki/Scripting
- https://github.com/hchunhui/librime-lua/wiki/API
- https://github.com/hchunhui/librime-lua/wiki/Objects

## Documentation

- **README.md**: The primary project documentation, containing a high-level overview and quick start guide.
- **docs/**: VitePress documentation site containing detailed installation instructions, configuration guides, and feature documentation.
- **FEATURES.md**: A detailed mapping of project features to their implementation files.

When modifying functional code (Lua) or configuration (YAML), always check if the changes impact the features described in the documentation. Update the relevant documentation files accordingly to keep them in sync with the codebase:
- Update `docs/` for user-facing feature changes, configuration options, or usage instructions.
- Update `FEATURES.md` for implementation file mappings.
- Update `README.md` for high-level overview changes.

If a feature is removed, do not just delete its entry from `FEATURES.md`. Move it into the `## 已移除功能` section and list the deleted files/config blocks so future merges can resolve upstream conflicts and reintroductions safely.

Also add the removed feature to the **精简说明** table in `README.md` so the fork's diff from upstream is clearly documented for users.

## Merging from Upstream

When merging any upstream changes, **ALWAYS** follow this procedure:

### Step 1: Check for new features
Review the upstream diff/commits for any new features being introduced (i.e. The **ENTIRE** patch, if there is any). If new features are found:

1. List all new features clearly.
2. **PAUSE and ASK the user** a **multiple-choice** question for whether to introduce each feature.
3. Based on the user's answer:
   - **Yes, introduce it**: Add the feature to the appropriate section in `FEATURES.md`.
   - **No, skip it**: Add the feature to the `## 已移除功能` section in `FEATURES.md`, documenting the files/config blocks involved so future merges can handle conflicts.

### Step 2: Check removed features before merging
Before merging, read the `## 已移除功能` section in `FEATURES.md`. If any upstream change touches a feature listed there, **do not introduce it** — skip or revert that change during the merge.

### Step 3: Resolving conflicts
When resolving merge conflicts, always read the full upstream changes to understand the intention behind them. Auto-merging can introduce false changes — do not blindly accept them. Compare each conflict hunk against the upstream changes to determine the correct resolution.

### Step 4: Merge docs clearly
When merging text-heavy files (e.g., Markdown docs, guides, notes), paraphrase upstream wording for clarity and readability before finalizing the merge result.

## Testing

Testing is handled automatically by [Mira](https://github.com/rimeinn/mira) on GitHub Actions. There is no need to run tests locally or verify test results after making edits.

## Version Control

This repository use Jujutsu for version control.

Follow conventional commits: `build:`, `chore:`, `ci:`, `docs:`, `style:`, `refactor:`, `perf:`, `test:`.
