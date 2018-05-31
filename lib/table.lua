-- local _, EventHorizon = ...
-- EventHorizon:file_preload()


-- function EventHorizon.deep_copy(object)
--   if type(object) == "table" then
--     local copy = {}
--     -- Don't improperly use the __pairs metamethod in Lua 5.2
--     for key, value in next, object do
--       copy[deep_copy(key)] = deep_copy(value)
--     end
--     setmetatable(copy, deep_copy(getmetatable(object)))
--     return copy
--   end
--   -- Most values in Lua are immutable
--   return object
-- end


-- local non_nil_value = function(_, value)
--   if value then return true end
-- end
-- function EventHorizon.any(object, predicate)
--   predicate = predicate or non_nil_value
--   if type(object) == "table" then
--     for key, value in pairs(object) do
--       if predicate(key, value) then
--         return true
--       end
--     end
--     return false
--   end
--   error("Invalid usage. Usage: any(object, [predicate])")
-- end

