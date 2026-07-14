# Tech Stack

- **Language**: Lua 5.1+ (LuaJIT compatible)
- **Package mgr**: Lux (`lux.toml`) + LuaRocks (`fallo-scm-1.rockspec`)
- **Dependency**: `lua-cjson >= 2.1.0` (optional, graceful fallback via pcall)
- **Test**: Busted 2.2+ (`.busted` config)
- **Formatter**: StyLua (config: `.stylua.toml` — Lua51, 120 cols, 3-space indent, `"` quotes)
- **Linter**: Luacheck (via flake)
- **LSP**: lua-language-server (`.luarc.json`)
- **Dev env**: Nix flake (`flake.nix`) — stylua, lua5_1, lua-ls, cjson, busted, luacov, luacheck
