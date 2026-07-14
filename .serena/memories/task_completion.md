# Task Completion

Before marking a task done, run these checks:

```bash
# Format
stylua {lua,test}/**/*.lua

# Lint
luacheck lua/ test/

# Test
busted

# Type check (LuaLS)
lua-language-server --check lua/ --config .luarc.json
```
