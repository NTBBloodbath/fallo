# Suggested Commands

```bash
# Run tests
busted

# Format code
stylua {lua,test}/**/*.lua

# Lint
luacheck lua/ test/

# Type check
lua-language-server --check lua/ --config .luarc.json

# Full dev shell (Nix)
nix develop

# Generate rockspec (CI)
lua generate_rockspec.lua

# Check Serena memories
serena memories check
```
