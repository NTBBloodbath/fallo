# Conventions

## Code style
- StyLua: 3-space indent, 120 col width, double quotes (`"`), collapse simple statements
- LuaCATS annotations for all params/returns (`---@param`, `---@return`)
- `---@diagnostic disable` for known lint edge cases (e.g. `missing-return`)

## Naming
- `Result.ok(value)` / `Result.err(error)` — static constructors
- Instance methods: `:is_ok()`, `:is_err()`, `:unwrap()`, `:map()`, `:and_then()`, `:or_else()`, `:inspect()`, `:match()`, etc.
- Internal: `_ok`, `_value`, `_error` fields (underscore prefix = private convention)

## Patterns
- Static methods on `Result` table, instance methods on metatable
- `pcall` + graceful fallback for optional deps (cjson)
- `setmetatable({...}, result_mt)` for construction
- `_` prefix for "private" helper functions
