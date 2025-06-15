package.path = "../lua/?.lua;../lua/?/init.lua;" .. package.path

local Result = require("fallo")

---@param user_id string
---@return Result<number, table> account balance
local function get_balance(user_id)
    if user_id == "invalid" then
        return Result.structured_error({
            code = 404,
            message = "User not found",
            context = {user_id = user_id}
        })
    end
    return Result.ok(1000)
end

---@param from string
---@param to string
---@param amount number
---@return Result<boolean, table>
local function transfer_funds(from, to, amount)
    return Result.try(function()
        local from_balance = get_balance(from):unwrap()
        ---@diagnostic disable-next-line unused-local
        local to_balance = get_balance(to):unwrap()

        if from_balance < amount then
            error({
                code = 400,
                message = "Insufficient funds",
                data = {available = from_balance, required = amount}
            })
        end

        print(string.format("Transferring $%d from %s to %s", amount, from, to))
        return true
    end)
end

-- Successful transfer
print("Successful transfer:")
transfer_funds("user1", "user2", 200)
    :map(function()
      ---@diagnostic disable-next-line missing-return
      print("Transfer succeeded!")
    end)
    :map_err(function(e)
      ---@diagnostic disable-next-line missing-return
      print("Error:", e.message)
    end)

-- User not found
print("\nUser not found:")
transfer_funds("invalid", "user2", 200)
    :map_err(function(e)
        print(string.format("Error %d: %s", e.code, e.message))
        ---@diagnostic disable-next-line missing-return
        print("Context:", e.context.user_id)
    end)

-- Insufficient funds
print("\nInsufficient funds:")
transfer_funds("user1", "user2", 1500)
    :map_err(function(e)
        print(string.format("Error %d: %s", e.code, e.message))
        print(
          string.format(
            "Available: $%d, Required: $%d",
            e.data.available,
            e.data.required
          )
        ---@diagnostic disable-next-line missing-return
        )
    end)

-- Mixed error types
print("\nMixed error types:")
local function complex_operation()
    return Result.try(function()
        local a = Result.ok(10):unwrap()
        local b = Result.wrap(function()
            error("raw error from legacy code")
        end):unwrap()
        return a + b
    end)
end

complex_operation()
    :map_err(function(e)
        print("Error:", e.message)
        ---@diagnostic disable-next-line missing-return
        print("Stack trace:", e.stack:sub(20, 100):gsub("\n", "") .. "...")
    end)
