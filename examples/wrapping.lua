package.path = "../lua/?.lua;../lua/?/init.lua;" .. package.path

local Result = require("fallo")

---@param a number
---@param b number
local function divide(a, b)
  if b == 0 then
    error("division by zero")
  end
  return a / b
end

-- Wrap single call
local res1 = Result.wrap(divide, 10, 2)
print("10/2 =", res1:unwrap())

local res2 = Result.wrap(divide, 10, 0)
print("10/0 error:", res2.error.message)

-- Create wrapped function
local safe_divide = Result.wrap_fn(divide)

local res3 = safe_divide(20, 5)
print("20/5 =", res3:unwrap())

local res4 = safe_divide(20, 0)
res4:map_err(function(e)
  return e.message
end):expect("Math operation failed")
