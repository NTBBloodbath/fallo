package.path = "../lua/?.lua;../lua/?/init.lua;" .. package.path

local Result = require("fallo")

---@param str string
local function parse_number(str)
  local num = tonumber(str)
  if not num then
    return Result.err({ type = "parse", input = str })
  end
  return Result.ok(num)
end

---@param num number
local function validate_even(num)
  if num % 2 == 0 then
    return Result.ok(num)
  end
  return Result.err({ type = "validation", reason = "odd number" })
end

---@param n number
local function double(n)
  return n * 2
end

-- Successful chain
Result.ok("42")
  :and_then(parse_number)
  :and_then(validate_even)
  :map(double)
  :map(function(n)
    ---@diagnostic disable-next-line missing-return
    print("Result:", n)
  end)

-- Failing chain
Result.ok("abc")
  :and_then(parse_number)
  :map_err(function(err)
    return { stage = "parsing", error = err }
  end)
  :and_then(validate_even)
  :map_err(function(err)
    ---@diagnostic disable-next-line missing-return
    print("Error:", err.error.type, "at", err.stage) --> parse at parsing
  end)
