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
         assert.are.same({ 15 }, res:unwrap())
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
         local res = Result.structured_error({
            code = 404,
            message = "Not found",
         })

         assert.is_true(res:is_err())
         assert.are.equal("Not found", res.error.message)
         assert.are.equal(404, res.error.data.code)
         assert.is_string(res.error.stack)
      end)

      it("preserves structured errors in unwrap", function()
         local res = Result.structured_error({ message = "test" })
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
         local res = Result.structured_error({
            code = 404,
            message = "Not found",
         })

         res:match({
            ok = function(_) error("Shouldn't execute") end,
            err = function(e)
               assert.are.equal("Not found", e.message)
               -- I don't recall having to return a value from this but whatever
               ---@diagnostic disable-next-line missing-return
               assert.are.equal(404, e.data.code)
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
         local a, b, c = res:to_lua_error()
         assert.are.same({ 1, 2, 3 }, { a, b, c })
      end)

      it("converts Err to Lua error", function()
         local res = Result.err("woops")
         local status, err = pcall(res.to_lua_error, res)
         assert.is_false(status)
         assert.are.equal("woops", err)
      end)

      it("converts structured errors in to_lua_error", function()
         local res = Result.structured_error({ message = "custom error" })
         local status, err = pcall(res.to_lua_error, res)
         assert.is_false(status)
         assert.are.equal("custom error", err)
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
         local err = Result.structured_error({ message = "error" })

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
         assert.are.same({ "data" }, res1.value)
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
end)
