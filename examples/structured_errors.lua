package.path = "../lua/?.lua;../lua/?/init.lua;" .. package.path

local Result = require("fallo")

---@param user string
local function authenticate(user)
  if user ~= "admin" then
    return Result.err({
      code = 401,
      message = "Unauthorized",
      context = { attempted_user = user }
    }):with_traceback()
  end
  return Result.ok({ token = "secret" })
end

local res = authenticate("guest")

if res:is_err() then
  local err = res.error
  print(string.format("Error %d: %s", err.code, err.message))
  print("Context:", err.context.attempted_user)
  print("Stack trace:", err.stack:sub(20, 74):gsub("\n", "") .. "...")
end

-- Preserving structured errors
local status, err = pcall(res.unwrap, res)
if not status then
  print("Preserved error code?", err.code)
end
