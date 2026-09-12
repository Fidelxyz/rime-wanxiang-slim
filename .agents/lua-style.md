# Lua Style Conventions

## File Structure
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

## Module Lifecycle
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

## Naming Conventions
- **Module tables**: Use `P` for processors, `T` for translators, `F` for filters, `M` for general utility modules
- **Functions**: Use snake_case with meaningful words; avoid abbreviations
- **Variables**: Use snake_case with meaningful words; avoid abbreviations
- **Constants**: Use SCREAMING_SNAKE_CASE for true constants
- **Type names**: Use PascalCase for class definitions

## Type Annotations
- **All functions** must have complete type annotations using LuaLS/EmmyLua syntax
- **Parameters**: Annotate with `---@param name type` before function definitions
- **Return values**: Annotate with `---@return type` (use `?` suffix for nullable types)
- **Class fields**: Annotate each field with its type (use `?` suffix for optional fields)
- **Local variables**: Annotate complex types with `---@type` when type inference is unclear
- **Type casts**: Use `---@cast` when narrowing types after validation
- **Nil checks**: Only add `?` suffix for types that can actually be nil; trust Rime API types defined in `librime.lua` to never be nil unless explicitly marked

## Comments
- **All comments** must be written in English
- Use `---` for documentation comments (LuaLS annotations)
- Use `--` for inline explanatory comments

## Code Organization
- **Column width**: Limit to 120 characters.
- **Goto labels**: Use `::continue::` for loop continuation (placed at end of loop body)
- **Early returns**: Prefer early returns for validation and edge cases
- **Guard clauses**: Use assertions (`assert()`) to validate required state/config
- **Table construction**: Initialize tables with explicit types when non-empty (e.g., `---@type string[]`)
- **List appending**: Use cached local variables for list length when appending in loops
- **String manipulation**: Use method syntax for string operations (e.g., `str:sub()`, `str:len()`) for readability
