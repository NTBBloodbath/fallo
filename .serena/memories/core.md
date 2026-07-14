# Fallo

Single-file Lua library providing Rust-like `Result<T, E>` for structured error handling.

- Entry: `lua/fallo/init.lua` — exports `Result` table with Ok/Err constructors + methods
- Test: `test/fallo_spec.lua` — busted spec
- Build: `lux.toml` (Lux) + `fallo-scm-1.rockspec` (LuaRocks)
- Key invariant: `_ok` / `_value` / `_error` fields on metatable-protected tables. Immutable after creation.

Architecture: `result_mt` metatable with `__index=Result`, `__newindex` blocks mutation.
All instance methods use `:` (self) syntax. Static methods use `.` syntax.

See `mem:tech_stack`, `mem:conventions`, `mem:task_completion`, `mem:suggested_commands`.
