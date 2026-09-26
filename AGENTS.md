# AGENTS.md

## Project Overview

Rime input method schema for Chinese pinyin input. it is a collection of YAML configuration files, Lua extensions, and dictionary data for the [Rime Input Method Engine](https://rime.im/).

### Directory Structure

```
├── lua/wanxiang/                # Lua plugin modules
├── lua/utils/                   # Lua utility modules
├── lua/data/                    # Data files for Lua plugins (emoji, charset, OpenCC)
├── lua/librime.lua              # Rime's Lua API type stubs
├── dicts/                       # Dictionary data files (.dict.yaml)
├── data/                        # Source data processed before schema packaging
├── opencc/                      # OpenCC data files for simplifier
├── custom/                      # Custom configuration templates
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
├── wanxiang_reverse.dict.yaml   # Dictionary for reverse lookup
├── wanxiang_reverse.schema.yaml # Sub-schema for reverse lookup
└── wanxiang_algebra.yaml        # Spelling algebra rules
```

## Lua Scripts

All Lua source files are in `lua/wanxiang/`. They are registered as processor, segmentor, translator or filter modules and configured in the YAML schema files.

### Style Conventions

Before modifying Lua source files, read and follow [Lua Style Conventions](.agents/lua-style.md).

### Rime's Lua API

`lua/librime.lua` is a full `---@meta rime` type stub file.

Documentation for Rime's Lua API can be found in the librime-lua documentation:
- https://github.com/hchunhui/librime-lua/wiki/Scripting
- https://github.com/hchunhui/librime-lua/wiki/API
- https://github.com/hchunhui/librime-lua/wiki/Objects

## Documentation

### Overview

#### User Documentation

- [README.md](README.md): The primary project documentation, containing a high-level overview.
- [docs/](docs/): VitePress documentation site containing detailed installation instructions, configuration guides, and feature documentation.

User documentation describes only what users need to know to understand and use it. It is not a place to store development memories, implementation details, or change logs.

#### Developer Documentation

- [FEATURES.md](FEATURES.md): A detailed mapping of project features to their implementation files, also recording removed features.

### Checklist for Updates

When modifying functional code or configuration, review the relevant documentation to determine whether existing descriptions remain accurate. **Update documentation only when the change makes an existing description inaccurate; otherwise, do not modify documentation.** Ensure any updates belong in the relevant document and match its existing level of detail.

**When a feature is removed**:
- Move its entry in [FEATURES.md](FEATURES.md) into the `## 已移除功能` section and list the deleted files/config blocks so future merges can resolve upstream conflicts and reintroductions safely.
- Add the removed feature to the `已移除功能列表` table in [README.md](README.md) and [introduction.md](docs/getting-started/introduction.md) so the fork's diff from upstream is clearly documented for users.

**When merging upstream changes**:
- Before merging, read the `## 已移除功能` section in [FEATURES.md](FEATURES.md). If any upstream change touches a removed feature listed there, **do not introduce it**.
- When merging documentation and comments, paraphrase upstream wording for clarity and readability before finalizing the merge result.

## Testing

Testing is handled automatically by [Mira](https://github.com/rimeinn/mira) on GitHub Actions. There is no need to run tests locally or verify test results after making edits.

## Version Control

Follow conventional commits: `build:`, `chore:`, `ci:`, `docs:`, `style:`, `refactor:`, `perf:`, `test:`.

## Defensive Coding

Don't add error handling, fallbacks, or validation **for scenarios that can't happen**. Trust internal code and framework guarantees. **Only validate at system boundaries** (user input, external APIs).
