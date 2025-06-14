package.path = "../lua/?.lua;../lua/?/init.lua;" .. package.path

local Result = require("fallo")

---@param success boolean
local function legacy_api(success)
  if not success then
    return false, "something went wrong"
  end
  return true, { data = 42 }
end

-- Convert to Result pattern
local res = Result.from_assert(legacy_api(false))
res:map(function(data)
  ---@diagnostic disable-next-line missing-return
  print("Received:", data.data)
end):map_err(function(err)
  ---@diagnostic disable-next-line missing-return
  print("Error:", err.message)
end)
