package.path = "../lua/?.lua;../lua/?/init.lua;" .. package.path

local Result = require("fallo")

-- Creating results
local success = Result.ok(42)
local failure = Result.err("division by zero")

-- Basic inspection
print("Success is ok?", success:is_ok())
print("Failure is err?", failure:is_err())

-- Unwrapping
print("Success value:", success:unwrap())

local _, err = pcall(function()
  failure:unwrap()
end)
print("Failure unwrap error:", err)

-- Safe unwrapping
print("Failure with default:", failure:unwrap_or(100))
print("Failure with computed:", failure:unwrap_or_else(function(e)
  return "Error: " .. e
end))
