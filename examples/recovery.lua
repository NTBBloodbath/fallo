package.path = "../lua/?.lua;../lua/?/init.lua;" .. package.path

local Result = require("fallo")

---@param should_fail boolean
local function fetch_data(should_fail)
  if should_fail then
    return Result.err({ code = 500, message = "Server Error" })
  end
  return Result.ok({ id = 1, name = "Alice" })
end

-- Fallback to default value
local user1 = fetch_data(true)
  :unwrap_or({ name = "Default User" })
print("User:", user1.name)

-- Recover with another operation
fetch_data(true)
  :or_else(function(err)
    print("Fallback triggered:", err.message)
    return fetch_data(false)
  end)
  :inspect(function(user)
    print("Recovered user:", user.name)
  end)

-- Complex recovery using match
fetch_data(true)
  :match({
    ok = function(data) return data end,
    err = function(err)
      if err.code == 500 then
        -- One could also return a plain table, this is
        -- just for demo purposes with an extra map call
        return Result.ok({ name = "Fallback User" })
      end
      error("Unrecoverable error")
    end
  })
  :inspect(function(user)
    print("Fallback user:", user.name)
  end)
