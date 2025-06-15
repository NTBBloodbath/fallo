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
:inspect(function() print("Transfer succeeded!") end)

-- User not found with enhanced error handling
print("\nUser not found:")
transfer_funds("invalid", "user2", 200)
:map_err(function(e)
   return {
      code = e.code,
      message = "Account error: " .. e.message,
      context = e.context,
      stack = e.stack
   }
end)
:inspect_err(function(e)
   print(string.format("[ERROR %d] %s", e.data.code, e.data.message))
   print("Context user:", e.data.context.user_id)
   print("Stack trace:")
   print(e.stack:sub(1, 200)) -- Print first 200 chars of stack
end)

-- Complex error transformation
print("\nComplex error handling:")
local res = transfer_funds("user1", "user2", 1500)
:map_err(function(e)
   -- Add business context to error
   return {
      code = e.code,
      message = "Transfer failed: " .. e.message,
      transaction = {from = "user1", to = "user2", amount = 1500},
      original = e
   }
end)

res:inspect_err(function(e)
   print("\nDetailed error report:")
   print(string.format("Code: %d", e.code))
   print("Message:", e.message)
   print("Requested amount:", e.transaction.amount)
   print("Available:", e.original.data.available)
end)

-- Chained operations with error recovery
print("\nError recovery:")
transfer_funds("user1", "invalid", 300)
:or_else(function(err)
   print("Primary transfer failed:", err.message)
   print("Attempting fallback transfer...")
   return transfer_funds("user1", "fallback", 300)
end)
:inspect(function()
   print("Fallback transfer succeeded!")
end)
:inspect_err(function(e)
   print("All transfer attempts failed:", e.message)
end)
