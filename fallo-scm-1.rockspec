rockspec_format = "3.0"
package = "fallo"
version = "scm-1"

description = {
  summary = "Modern error handling for Lua",
  homepage = "https://github.com/NTBBloodbath/fallo",
  license = "LGPL-3",
}

source = {
  url = "git+https://github.com/NTBBloodbath/fallo",
}

dependencies = {
  "lua >= 5.1",
  "lua-cjson >= 2.1.0",
}

test_dependencies  = {
  "busted >= 2.2",
}

build = {
  type = "builtin",
  modules = {
    ["fallo"] = "lua/fallo/init.lua",
  },
  -- install = {
  --   lua = {
  --     fallo = "lua/fallo",
  --   },
  -- },
}

test = {
  type = "busted",
}
