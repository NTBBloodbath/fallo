---@module 'fallo'
---Rust-like Result type for structured error handling

---@class Result
---@field ok boolean|function True for success (Ok), false for error (Err)
---@field value any|nil Contained value when ok=true
---@field error any|nil Contained error when ok=false
local Result = {}

---@class ResultConfig
---@field traceback boolean Whether to add tracebacks to errors, enabled by default
Result.config = {
   traceback = true,
}

---Format an error value to a string for Lua errors
---@param err any The error value
---@return string
---@private
function Result.format_error(err)
   if type(err) == "table" and err.message then return err.message end
   return tostring(err)
end

---Convert a Lua error to a structured error
---@param err any The error value
---@param level? number The traceback start level (default: 3)
---@return table Structured error
---@private
function Result.structure_error(err, level)
   if type(err) == "table" then return err end

   local structured_err = {
      message = tostring(err),
   }

   if Result.config.traceback then
      structured_err.stack = debug.traceback("", level or 3)
   end
   return structured_err
end

---Metatable for Result objects
local result_mt = {
   __index = Result,
   __newindex = function() error("Results are immutable") end,
}

---Create a successful Result
---@generic T
---@param value T The success value
---@return Result<T> Ok result
function Result.ok(value) return setmetatable({ ok = true, value = value }, result_mt) end

---Create an Err result with structured error data
---@generic E
---@param error E The error value
---@return Result<any, E> Err result
function Result.err(error) return setmetatable({ ok = false, error = error }, result_mt) end

---Wrap a function to capture its result
---@param fn function Function to wrap
---@vararg any Function arguments
---@return Result result of the function call
function Result.wrap(fn, ...)
   local args = { ... }
   local returns = { pcall(fn, unpack(args)) }
   local success = table.remove(returns, 1)

   if not success then
      local err = returns[1]
      if type(err) == "table" then
         -- Preserve existing structured errors
         return Result.err(err)
      end
      -- capture traceback stack for new errors
      if Result.config.traceback then
         return Result.err(err):with_traceback()
      end
      return Result.err(err)
   end

   return Result.ok(#returns > 1 and returns or returns[1])
end

---Create a function wrapper that returns Results
---@param fn function Function to wrap
---@return function(...):Result Wrapped function
function Result.wrap_fn(fn)
   return function(...) return Result.wrap(fn, ...) end
end

---Unwrap value or throw error
---@return any Success value
function Result:unwrap()
   if self.ok then
      return self.value
   else
      error(self.error, 2)
   end
end

---Unwrap or return default value
---@generic T
---@param default T Default value
---@return T|any Value or default
function Result:unwrap_or(default)
   if self.ok then return self.value end
   return default
end

---Unwrap or compute from error
---@generic T, E
---@param fn fun(error: E): T Default generator
---@return T|any Value or computed default
function Result:unwrap_or_else(fn)
   if self.ok then return self.value end
   return fn(self.error)
end

---Unwrap or throw with custom message
---@param message string Custom error message
---@return any Success value
function Result:expect(message)
   if self.ok then
      return self.value
   else
      error(string.format("%s: %s", message, tostring(self.error)), 2)
   end
end

---Check if result is Ok
---@return boolean True is result is Ok
function Result:is_ok()
   ---@type boolean
   return self.ok
end

---Check if result is Err
---@return boolean True if result is Err
function Result:is_err() return not self.ok end

---Map success value to new value
---@generic T, U
---@param fn fun(value: T): U Mapping function
---@return Result<U> New result
function Result:map(fn)
   if self.ok then return Result.ok(fn(self.value)) end
   return self
end

---Map error value to a new error
---@generic E, F
---@param fn fun(error: E): F Mapping function
---@return Result New result
function Result:map_err(fn)
   if not self.ok then
      local new_err = fn(self.error)

      -- Preserve structured error metadata
      if type(self.error) == "table" and type(new_err) == "table" then
         new_err.stack = new_err.stack or self.error.stack
      end
      return Result.err(new_err)
   end
   return self
end

---Chain operations that return Results
---@generic T, U
---@param fn fun(value: T): Result<U> Chaining function
---@return Result<U> New result
function Result:and_then(fn)
   if self.ok then return fn(self.value) end
   return self
end

---Recover from error with new Result
---@generic E, T
---@param fn fun(error: E): Result<T> Recovery function
---@return Result<T> New result
function Result:or_else(fn)
   if self.ok then return self end
   return fn(self.error)
end

---@generic T, U
---@alias ok_fn fun(value: T): U

---@generic E, U
---@alias err_fn fun(error: E): U

---Pattern-match on result state
---@generic U
---@param patterns {ok: ok_fn, err: err_fn}
---@return U Result of matching pattern
function Result:match(patterns)
   if self.ok then
      return patterns.ok and patterns.ok(self.value)
   else
      return patterns.err and patterns.err(self.error)
   end
end

---Convert to Lua's error system
---Returns values if Ok, throws error if Err
---@return any ... Result values if Ok, formatted error if Err
function Result:to_lua_error()
   if self.ok then
      return self.value
   else
      error(Result.format_error(self.error), 0)
   end
end

---Convert from pcall returns to Result
---@param success boolean Result of pcall
---@param ... any Return values from pcall
---@return Result
function Result.from_pcall(success, ...)
   if not success then return Result.err(Result.structure_error((...))) end
   return Result.ok({ ... })
end

---Safe pcall wrapper returning Result
---@param fn function Function to call
---@param ... any Arguments
---@return Result
function Result.pcall(fn, ...) return Result.from_pcall(pcall(fn, ...)) end

---Convert from xpcall returns to Result
---@param success boolean Result of xpcall
---@param result any Return value from xpcall
---@return Result
function Result.from_xpcall(success, result)
   if not success then return Result.err(Result.structure_error(result)) end
   return Result.ok(result)
end

---Convert to Lua's xpcall system
---Returns values if Ok, throws formatted error if Err
---@param message_handler function Custom message handler
---@return any ... Result values if Ok
function Result:to_xpcall(message_handler)
   if self.ok then
      return self.value
   else
      error(message_handler(self.error), 0)
   end
end

---Convert from Lua's assert pattern
---@param success boolean Result of protected call
---@param ... any Return values from protected call
---@return Result
function Result.from_assert(success, ...)
   if not success then return Result.err(Result.structure_error((...))) end
   return Result.ok(...)
end

---Convert to Lua's assert system
---Returns values if Ok, throws error if Err using `assert()`
---@return any ... Result values if Ok
function Result:to_assert()
   if self.ok then
      return self.value
   else
      return false, Result.format_error(self.error)
   end
end

---Perform side effect on success value without modification
---@generic T
---@param fn fun(value: T) Inspection function
---@return Result Same result
function Result:inspect(fn)
   if self.ok then fn(self.value) end
   return self
end

---Perform side effect on error value without modification
---@generic E
---@param fn fun(error: E) Inspection function
---@return Result Same result
function Result:inspect_err(fn)
   if not self.ok then fn(self.error) end
   return self
end

---Add stack trace to error (if enabled in config)
---@return Result self (for chaining)
function Result:with_traceback()
   if not self.ok and Result.config.traceback then
      local err = self.error

      -- Ensure error is structured
      if type(err) ~= "table" then self.error = Result.structure_error(err, 2) end

      -- Add traceback if not already present
      if type(err) == "table" and not err.stack then err.stack = debug.traceback("", 2) end
   end
   return self
end

---Create a protected execution context for error propagation
---@generic T
---@param fn fun(): T Function to execute in protected mode
---@return Result<T> Result of the execution
function Result.try(fn)
   local co = coroutine.create(fn)

   local function step(...)
      local returns = { coroutine.resume(co, ...) }
      local success = table.remove(returns, 1)

      if not success then
         if Result.config.traceback then
            return Result.err(returns[1]):with_traceback()
         end
         return Result.err(returns[1])
      end

      if coroutine.status(co) == "dead" then return Result.ok(returns[1] or returns) end

      -- Handle results from the function
      local result = returns[1]
      if type(result) == "table" and getmetatable(result) == result_mt then
         if result:is_err() then
            -- Preserve structured error metadata
            local err = result.error
            if type(err) == "table" and err.stack then
               -- Append current stack to existing trace
               local current_trace = debug.traceback("", 2)
               result.error.stack = err.stack and (err.stack .. "\n" .. current_trace) or current_trace
            end
            return result
         end
         return step(result:unwrap())
      end

      return step(unpack(returns))
   end

   return step()
end

return Result
