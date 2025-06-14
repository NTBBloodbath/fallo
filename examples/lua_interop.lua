package.path = "../lua/?.lua;../lua/?/init.lua;" .. package.path

local Result = require("fallo")

---Legacy function using false, error pattern
---@param success boolean
local function legacy_api(success)
  if not success then
    return false, "something went wrong"
  end
  return true, { data = 42 }
end

---Modern function using errors
---@param success boolean
local function modern_api(success)
  if not success then
    error({ code = 500, message = "Internal error" })
  end
  return "ok"
end

-- Convert from legacy API
local res1 = Result.from_assert(legacy_api(true))
print("Legacy success:", res1:unwrap().data) --> 42

local res2 = Result.from_assert(legacy_api(false))
print("Legacy error:", res2.error) --> something went wrong

-- Convert to legacy API
local function wrapper()
  return res1:to_assert()
end

local data = wrapper()
print("Wrapped data:", data.data) --> 42

-- pcall integration
local res3 = Result.pcall(modern_api, false)
res3:map_err(function(err)
  ---@diagnostic disable-next-line missing-return
  print("Structured error code:", err.code) --> 500
end)

-- Using to_lua_error
local function test()
  return res3:to_lua_error()
end

local status, err = pcall(test)
if not status then
  print("Error message:", err) --> 500
end
