rockspec_format = "3.0"
package = "fallo"
version = "scm-1"

description = {
  summary = "Modern error handling for Lua",
  homepage = "https://github.com/NTBBloodbath/fallo",
  license = "LGPL-3",
}

dependencies = {
  "lua >= 5.1",
}

test_dependencies  = {
  "busted >= 2.2",
}

build = {
  type = "builtin"
  install = {
    lua = {
      tide = "lua/tide",
    },
  },
}

test = {
  type = "busted",
}
