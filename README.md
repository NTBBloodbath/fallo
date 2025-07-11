<div align="center">

# Fallo

![Lua Version](https://img.shields.io/badge/Lua-5.1+-blue?style=for-the-badge&logo=lua)
[![LuaRocks](https://img.shields.io/luarocks/v/NTBBloodbath/fallo?style=for-the-badge&logo=lua)](https://luarocks.org/modules/ntbbloodbath/fallo)
![GitHub License](https://img.shields.io/github/license/NTBBloodbath/fallo?style=for-the-badge&logo=gitbook)

Fallo (failure in Spanish) is a modern, ergonomic error handling library for Lua with support for structured errors, highly inspired by Rust's `Result`.

It provides comprehensive error propagation, transformation, and interoperability with Lua's native
error system.

</div>

## Features
- **Structured errors** with metadata and stack traces.
- **Method chaining** for complex workflows.
- **Seamless interoperability** with Lua's error system.
- **Automatic error propagation** with `Result.safe`.
- **Side effect handlers** for logging and metrics.
- **LuaCATS annotations** for safe typing editor support.
- **Zero dependencies** self-contained single-file library.

## Installation
### Luarocks
```
luarocks install fallo
```

### Manual
As `fallo` is a self-contained single-file library, you can easily download [fallo](./lua/fallo/init.lua), place it in your project directory and import it using:
```
local Result = require("fallo")
```

> [!IMPORTANT]
>
> Starting from version 2.1.0, fallo uses the `lua-cjson` library by default for structured error
> serialization. However, this is handled gracefully, so if you embed the library directly in your
> project or won't be using serialization, you won't encounter any issues and will maintain the
> behavior of previous versions, though using serialization is recommended.

## Usage

<details>
  <summary>Basic Usage</summary>

### Creating Results
```lua
local Result = require("fallo")

-- Successful result
local success = Result.ok(42)

-- Error result
local failure = Result.err("File not found")

-- Structured error
local structured = Result.err({
  code = 404,
  message = "User not found",
  context = {user_id = "abc123"}
})
```

### Handling Results
```lua
-- Basic inspection
if success:is_ok() then
  print("Value:", success:unwrap())
end

if failure:is_err() then
  print("Error:", failure.error)
end

-- Safe unwrapping
local value = success:unwrap_or(100)
local computed = failure:unwrap_or_else(function(err)
  return "Default: " .. err
end)

-- Chained operations
Result.ok(5)
  :map(function(x) return x * 2 end) -- 10
  :and_then(function(x) return Result.ok(x + 1) end) -- 11
  :inspect(print) -- Prints 11
```

</details>

<details>
  <summary>Error Propagation</summary>

### Automatic Propagation
```lua
local config = Result.safe(function()
  local raw = read_file("config.json"):unwrap()
  return parse_json(raw):unwrap()
end)

config:inspect_err(function(e)
  print("Failed to load config:", e.message)
end)
```

### Traditional Lua Integration
```lua
-- Convert to Lua's error system
local function legacy_api()
  return Result.ok(42):to_lua_error()
end

-- Convert from Lua's assert pattern
local function modern_wrapper()
  local success, data = legacy_api()
  return Result.from_assert(success, data)
end
```

</details>

> [!NOTE]
>
> Check out the [examples](./examples) directory for usage examples.

## Core API
### Configuration
| Option                 | Description                                       | Default     |
| ---------------------- | ------------------------------------------------- | ----------- |
| `traceback`            | Whether to add error stack traces                 | `true`      |
| `json`                 | JSON module to be used for serialization or `nil` | `lua-cjson` |

<details>
  <summary>Example</summary>

```lua
local Result = require("fallo")

Result.config = {
  traceback = true,
  json = vim.json, -- nil to disable JSON serialization
}
```

</details>

### Result Creation

| Method                    | Description                   | Example                                             |
| ------------------------- | ----------------------------- | --------------------------------------------------- |
| `Result.ok(value)`        | Creates successful result     | `Result.ok(42)`                                     |
| `Result.err(error)`       | Creates error result          | `Result.err("failed")`, `Result.err({ oh = "no" })` |
| `Result.wrap(fn, ...)`    | Wraps function call           | `Result.wrap(os.remove, "temp.txt")`                |
| `Result.wrap_fn(fn)`      | Creates safe function         | `safe_remove = Result.wrap_fn(remove_tmpfiles)`     |
| `Result.safe(fn)`         | Protected execution context   | `Result.safe(may_fail)`                             |
| `Result.serialize(err)`   | Serialize a structured error  | `Result.serialize(err)`                             |
| `Result.deserialize(err)` | Deserialize an error          | `Result.deserialize(err)`                           |
| `:with_traceback()`       | Add error traceback to result | `res:with_traceback()`                              |

### Result Handling
| Method                 | Description                       | Example                                     |
| ---------------------- | --------------------------------- | ------------------------------------------- |
| `:unwrap()`            | Returns value or throws error     | `value = res:unwrap()`                      |
| `:unwrap_or(default)`  | Returns value or default          | `value = res:unwrap_or(0)`                  |
| `:unwrap_or_else(fn)`  | Returns value or computes default | `value = res:unwrap_or_else(error_handler)` |
| `:expect(message)`     | Unwraps with custom error message | `res:expect("Should have value")`           |
| `:try()`               | Propagates the error if Result is not Ok | `res:try()`           |
| `:is_ok()`             | Checks if result is successful    | `if res:is_ok() then ... end`               |
| `:is_err()`            | Checks if result is error         | `if res:is_err() then ... end`              |

### Transformations
| Method                 | Description                       | Example                                    |
| ---------------------- | --------------------------------- | ------------------------------------------ |
| `:map(fn)`             | Transforms success value          | `res:map(tostring)`                        |
| `:map_err(fn)`         | Transforms error value            | `res:map_err(enrich_error)`                |
| `:and_then(fn)`        | Chains result-returning functions | `res:and_then(validate)`                   |
| `:or_else(fn)`         | Recovers from errors              | `res:or_else(fallback)`                    |
| `:inspect(fn)`         | Side effect on success            | `res:inspect(print)`                       |
| `:inspect_err(fn)`     | Side effect on error              | `res:inspect_or(log_error)`                |
| `:match(patterns)`     | Pattern matching                  | `res:match({ok=success_fn, err=error_fn})` |

## Contribute
1. Fork it (https://github.com/NTBBloodbath/fallo/fork)
2. Create your feature branch (<kbd>git checkout -b my-new-feature</kbd>)
3. Commit your changes (<kbd>git commit -am "feat: add some feature"</kbd>). **Please use [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/)**.
4. Push to the branch (<kbd>git push origin my-new-feature</kbd>)
5. Create a new Pull Request.

> [!IMPORTANT]
>
> Before commit your changes, make sure to format the code by running `stylua {lua,test}/**/*.lua`, and run `busted` to make sure all tests works correctly.

## TODO
- [x] Allow error propagation
- [ ] Coroutine-based async error handling
- [x] Expose configuration options (e.g. enable/disable stack traces)
- [ ] Improve structured errors through metatables

## License
Fallo is licensed under [LGPL-3.0+](./LICENSE).
