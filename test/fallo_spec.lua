local Result = require("fallo")

describe("Result class", function()
   describe("Core functionality #core", function()
      it("Creates Ok results", function()
         local res = Result.ok(42)
         assert.is_true(res:is_ok())
         assert.is_false(res:is_err())
         assert.are.equal(42, res:unwrap())
      end)

      it("Creates Err results", function()
         local res = Result.err("failure")
         assert.is_false(res:is_ok())
         assert.is_true(res:is_err())
         assert.has.errors(function() res:unwrap() end, "failure")
      end)
   end)

   describe("Wrapping functions #wrap", function()
      it("wraps successful calls", function()
         local function add(a, b) return a + b end
         local res = Result.wrap(add, 10, 5)
         assert.is_true(res:is_ok())
         assert.are.same(15, res:unwrap())
      end)

      it("wraps failing calls", function()
         local function fail() error("boom") end
         local res = Result.wrap(fail)
         assert.is_true(res:is_err())
         -- wrap errors contain the file:line where the error was thrown
         assert.are.equal("test/fallo_spec.lua:29: boom", res.error.message)
      end)

      it("creates wrapped functions", function()
         local function div(a, b)
            -- Lua is retarded and does not count this as an error by default
            if a == 0 or b == 0 then error("Cannot divide by zero") end
            return a / b
         end
         local safe_div = Result.wrap_fn(div)
         local res = safe_div(10, 0)
         assert.is_true(res:is_err())
      end)
   end)

   describe("Value handling #values", function()
      it("unwraps with default values", function()
         local ok = Result.ok(5)
         local err = Result.err("oops")

         assert.are.equal(5, ok:unwrap_or(0))
         assert.are.equal(0, err:unwrap_or(0))
         assert.are.equal(10, err:unwrap_or_else(function() return 10 end))
      end)

      it("transforms values", function()
         local ok = Result.ok(2)
         local err = Result.err(3)

         assert.are.equal(4, ok:map(function(x) return x * 2 end):unwrap())
         assert.are.equal(6, err:map_err(function(x) return x * 2 end).error)
      end)
   end)

   describe("Chaining operations #chains", function()
      it("chains successful operations", function()
         local res = Result.ok(5):and_then(function(x) return Result.ok(x * 2) end):map(function(x) return x + 1 end)

         assert.are.equal(11, res:unwrap())
      end)

      it("short-circuits errors", function()
         local res = Result.ok(5)
            :and_then(function() return Result.err("fail") end)
            :and_then(function() return Result.ok(10) end)

         assert.is_true(res:is_err())
      end)
   end)

   describe("Error recovery #recovery", function()
      it("recovers from errors", function()
         local res = Result.err("original"):or_else(function() return Result.ok("recovered") end)

         assert.are.equal("recovered", res:unwrap())
      end)
   end)

   describe("Structured errors #structured", function()
      it("creates structured errors", function()
         local res = Result.err({
            code = 404,
            message = "Not found",
         }):with_traceback()

         assert.is_true(res:is_err())
         assert.are.equal("Not found", res.error.message)
         assert.are.equal(404, res.error.code)
         assert.is_string(res.error.stack)
      end)

      it("preserves structured errors in unwrap", function()
         local res = Result.err({ message = "test" }):with_traceback()
         local status, err = pcall(res.unwrap, res)
         assert.is_false(status)
         assert.are.equal("test", err.message)
         assert.is_string(err.stack)
      end)
   end)

   describe("Pattern Matching #match", function()
      it("handles Ok results", function()
         local res = Result.ok(42)
         local output = res:match({
            ok = function(v) return "Got " .. v end,
            err = function(_) return "failed" end,
         })
         assert.are.equal("Got 42", output)
      end)

      it("handles Err results", function()
         local res = Result.err("timeout")
         local output = res:match({
            ok = function(_) return "success" end,
            err = function(e) return "Error: " .. e end,
         })
         assert.are.equal("Error: timeout", output)
      end)

      it("handles structured errors", function()
         local res = Result.err({
            code = 404,
            message = "Not found",
         })

         res:match({
            ok = function(_) error("Shouldn't execute") end,
            err = function(e)
               assert.are.equal("Not found", e.message)
               -- I don't recall having to return a value from this but whatever
               ---@diagnostic disable-next-line missing-return
               assert.are.equal(404, e.code)
            end,
         })
      end)

      it("supports different return types", function()
         local ok_res = Result.ok(10)
         local err_res = Result.err("invalid")

         local ok_val = ok_res:match({
            ok = function(v) return v * 2 end,
            err = function(_) return 0 end,
         })

         local err_val = err_res:match({
            ok = function(_) return {} end,
            err = function(e) return { error = e } end,
         })

         assert.are.equal(20, ok_val)
         assert.are.same({ error = "invalid" }, err_val)
      end)
   end)

   describe("Lua Error Interop #interop", function()
      it("converts Ok to Lua return", function()
         local res = Result.ok(42)
         local value = res:to_lua_error()
         assert.are.equal(42, value)
      end)

      it("converts Ok table to multiple returns", function()
         local res = Result.ok({ 1, 2, 3 })
         local err_res = res:to_lua_error()
         assert.are.same({ 1, 2, 3 }, err_res)
      end)

      it("converts Err to Lua error", function()
         local res = Result.err("woops")
         local status, err = pcall(res.to_lua_error, res)
         assert.is_false(status)
         assert.are.equal("woops", err)
      end)

      it("converts structured errors in to_lua_error", function()
         local res = Result.err({ message = "custom error" })
         local status, err = pcall(res.to_lua_error, res)
         assert.is_false(status)
         assert.are.equal('{"message":"custom error"}', err)
      end)

      it("creates from pcall success", function()
         local function success_fn() return 1, 2 end
         local res = Result.from_pcall(pcall(success_fn))
         assert.is_true(res:is_ok())
         assert.are.same({ 1, 2 }, res.value)
      end)

      it("creates from pcall failure", function()
         local function fail_fn() error("failed") end
         local res = Result.from_pcall(pcall(fail_fn))
         assert.is_true(res:is_err())
         -- errors contain the file:line where the error was thrown
         assert.are.equal("test/fallo_spec.lua:203: failed", res.error.message)
         assert.is_string(res.error.stack)
      end)

      it("uses Result.pcall for safe calls", function()
         local res = Result.pcall(error, "oops", 0)
         assert.is_true(res:is_err())
         assert.are.equal("oops", res.error.message)
      end)

      it("creates from xpcall returns", function()
         local function success() return "ok" end
         local function failure() error("bad") end
         local handler = function(err) return "HANDLED: " .. err end

         local _, res1 = xpcall(success, handler)
         local _, res2 = xpcall(failure, handler)

         local result1 = Result.from_xpcall(true, res1)
         local result2 = Result.from_xpcall(false, res2)

         assert.is_true(result1:is_ok())
         assert.are.equal("ok", result1.value)
         assert.is_true(result2:is_err())
         assert.are.equal("HANDLED: test/fallo_spec.lua:219: bad", result2.error.message)
      end)

      it("converts to xpcall system", function()
         local handler = function(err) return "HANDLED: " .. tostring(err.message) end

         local ok = Result.ok("success")
         local err = Result.err({ message = "error" })

         assert.are.equal("success", ok:to_xpcall(handler))
         local status, msg = pcall(err.to_xpcall, err, handler)
         assert.is_false(status)
         assert.are.equal("HANDLED: error", msg)
      end)

      it("creates from assert pattern", function()
         local function success() return true, "data" end
         local function failure() return false, "issue" end

         local res1 = Result.from_assert(success())
         local res2 = Result.from_assert(failure())

         assert.is_true(res1:is_ok())
         assert.are.same("data", res1.value)
         assert.is_true(res2:is_err())
         assert.are.equal("issue", res2.error.message)
      end)

      it("converts to assert patterns", function()
         local ok = Result.ok(5)
         local err = Result.err("problem")

         local val = ok:to_assert()
         local status, problem = err:to_assert()

         assert.are.equal(5, val)
         assert.is_false(status)
         assert.are.equal("problem", problem)
      end)
   end)

   describe("Automatic Error Propagation #auto-propagation", function()
      it("automatically propagates errors in try blocks", function()
         local function nested_ops()
            local a = Result.ok(10):unwrap()
            local b = Result.err("failed"):unwrap() --> Should propagate
            return a + b
         end

         local res = Result.safe(nested_ops)
         assert.is_true(res:is_err())
         assert.are.equal("test/fallo_spec.lua:276: failed", res.error.message)
      end)

      it("continues execution after successful unwraps", function()
         local res = Result.safe(function()
            local a = Result.ok(5):unwrap()
            local b = Result.ok(10):unwrap()
            return a + b
         end)

         assert.are.equal(15, res:unwrap())
      end)

      it("handles nested try blocks", function()
         local function inner() Result.err("inner error"):unwrap() end

         local res = Result.safe(function()
            inner()
            return "success"
         end)

         assert.is_true(res:is_err())
         assert.are.equal("test/fallo_spec.lua:296: inner error", res.error.message)
      end)

      it("propagates structured errors", function()
         local res = Result.safe(
            function()
               return Result.err({
                  code = 500,
                  message = "Server Error",
               }):unwrap()
            end
         )

         assert.is_true(res:is_err())
         assert.are.equal(500, res.error.code)
      end)

      it("preserves structured errors through map_err", function()
         local original = Result.err({
            code = 404,
            message = "Not found",
            context = { resource = "user" },
         }):with_traceback()

         local transformed = original
            :map_err(function(err)
               err.message = "Modified: " .. err.message
               err.extra = "new field"
               return err
            end)
            :with_traceback()

         assert.is_true(transformed:is_err())
         local err = transformed.error
         assert.are.equal(404, err.code)
         assert.are.equal("Modified: Not found", err.message)
         assert.are.equal("new field", err.extra)
         assert.are.equal("user", err.context.resource)
         assert.is_string(err.stack)
      end)

      it("preserves stack traces through propagation", function()
         local function inner() Result.err("original error"):unwrap() end

         local function outer() inner() end

         local res = Result.safe(outer)
         assert.is_true(res:is_err())
         assert.is_string(res.error.stack)
      end)

      it("preserves error structure through multiple transformations", function()
         local res = Result.safe(function()
            Result
               .err({
                  code = 400,
                  message = "Bad request",
               })
               :map_err(
                  function(e)
                     return {
                        code = e.code,
                        message = "Validation: " .. e.message,
                        stage = "input",
                     }
                  end
               )
               :inspect_err(function(e) e.checked = true end)
               ---@diagnostic disable-next-line missing-return
               :unwrap()
         end)

         assert.is_true(res:is_err())
         local err = res.error
         assert.are.equal(400, err.code)
         assert.are.equal("Validation: Bad request", err.message)
         assert.are.equal("input", err.stage)
         assert.is_true(err.checked)
         assert.is_string(err.stack)
      end)

      it("handles regular Lua errors", function()
         local res = Result.safe(function() error("raw Lua error") end)

         assert.is_true(res:is_err())
         assert.are.equal("test/fallo_spec.lua:386: raw Lua error", res.error.message)
      end)

      it("works with complex workflows", function()
         local function get_value() return Result.ok(42) end

         local function might_fail(should_fail)
            if should_fail then return Result.err("intentional failure") end
            return Result.ok(100)
         end

         local res = Result.safe(function()
            local a = get_value():unwrap()
            local b = might_fail(false):unwrap()
            local c = might_fail(true):unwrap() --> Should stop here

            return a + b + c
         end)

         assert.is_true(res:is_err())
         assert.are.equal("test/fallo_spec.lua:403: intentional failure", res.error.message)
      end)
   end)

   describe("Explicit Error Propagation #explicit-propagation", function()
      it("propagates errors from Result.err", function()
         local function test() Result.err("test error"):try() end

         local ok, err = pcall(test)
         assert.is_false(ok)
         assert.are.equal("test error", err)
      end)

      it("returns values from Result.ok", function()
         local value = Result.ok(42):try()
         assert.are.equal(42, value)
      end)

      it("works with nested propagations", function()
         local function inner() Result.err("inner error"):try() end

         local function outer() inner() end

         local ok, err = pcall(outer)
         assert.is_false(ok)
         assert.are.equal("inner error", err)
      end)

      it("combines with safe blocks", function()
         local res = Result.safe(function()
            ---@diagnostic disable-next-line missing-return
            Result.err("propagated in try"):try()
         end)

         assert.is_true(res:is_err())
         assert.are.equal("propagated in try", res.error.message)
      end)
   end)

   describe("Error Serialization", function()
      it("serializes structured error without JSON", function()
         -- Save existing JSON implementation to restore it later
         local json = Result.config.json
         Result.config.json = nil

         local err = { code = 400, message = "Bad request" }
         -- This will serialize only the structured error message as intended
         local serialized = Result.serialize(err)
         assert.are.equal("Bad request", serialized)

         Result.config.json = json
      end)

      it("serializes tables with JSON", function()
         local err = { code = 500, message = "Internal Server Error" }
         local serialized = Result.serialize(err)
         assert.are.equal('{"message":"Internal Server Error","code":500}', serialized)
      end)

      it("deserializes JSON strings", function()
         local json_str = '{"message":"Yabbadabbadoo"}'
         local deserialized = Result.deserialize(json_str)
         assert.are.equal("Yabbadabbadoo", deserialized.message)
      end)

      it("leaves non-JSON strings untouched", function()
         local err_str = "regular error"
         local deserialized = Result.deserialize(err_str)
         assert.are.equal("regular error", deserialized)
      end)

      it("handles invalid JSON gracefully", function()
         local invalid_json = "{invalid}"
         local deserialized = Result.deserialize(invalid_json)
         assert.are.equal("{invalid}", deserialized)
      end)
   end)
end)
