local _, AddonToolkit = AddonToolkit.AddOn(...)
local _, Method = AddonToolkit.Module("Method")

local format = import("format")
local ipairs = import("ipairs")
local table = import("table")
local pairs = import("pairs")
local setmetatable = import("setmetatable")
local next = import("next")
local type = import("type")
local unpack = import("unpack")

-- Schema for self-documenting function usage using metatables with __call to
-- add arg definition processing/help text
local function usage_message(function_table)
  local msg = format("Usage: %s({", function_table.name)
  for i, required_arg in ipairs(function_table.required_arguments) do
    msg = msg .. format("%s=%s, ", required_arg, i)
  end
  for arg, default_value in pairs(function_table.default_arguments) do
    msg = msg .. format("[%s=<%s>]", arg, default_value)
  end
  return msg .. "})"
end


local function usage_error_message(function_table, args, missing_args)
  return format("Invalid call to function_table %s. Got args %s. Usage: %s",
      function_table.name,
      args,
      function_table.usage
  )
end


local function shallow_copy(object)
  if type(object) == "table" then
    local copy = {}
    -- Don't improperly use the __pairs metamethod in Lua 5.2
    for key, value in next, object do
      copy[key] = value
    end
    return copy
  end
  -- Most values in Lua are immutable
  return object
end


local function parse_args(function_table, args)
  args = args or {}
  local missing_required_args = {}
  for _, required_arg in ipairs(function_table.required_arguments) do
    if args[required_arg] == nil then
      table.insert(missing_required_args, required_arg)
    end
  end
  if next(missing_required_args) then
    error(usage_error_message(function_table, args, missing_required_args), 2)
  end

  local final_args = shallow_copy(args)
  for arg, default in pairs(function_table.default_arguments) do
    if args[arg] == nil then
      final_args[arg] = default
    end
  end

  local varargs = {}
  for _, v in ipairs(final_args) do
    table.insert(varargs, v)
  end

  return final_args, varargs
end


local function_metatable = {
  __call = function(function_table, a, b, c)
    if c ~= nil then error("You specified too many arguments for " .. function_table.name .. ". Specify arguments using an argument table!") end
    local self, args = nil, nil
    if a ~= nil and b ~= nil then
      self = a
      args = b
    elseif b == nil then
      args = a
    else
      error(format("Error when calling function %s. Got %s, %s. " ..
                   "You must always specify args, and can optionally specify self",
                   function_table.name,
                   tostring(a),
                   tostring(b)
                  ))
    end
    local parsed_args, varargs = parse_args(function_table, args)
    if self then
      return function_table.impl(self, parsed_args, unpack(varargs))
    end
    return function_table.impl(parsed_args, unpack(varargs))
  end,
  __tostring = function(function_table)
    return format("<Function: %s>", function_table.name)
  end
}
local function method(args)
  if not args.name or not args.impl then error("Must specify function name and impl") end
  local function_table = {
    self = args.self or false,
    name = args.name,
    required_arguments = args.required_arguments or {},
    default_arguments = args.default_arguments or {},
    impl = args.impl,
  }
  function_table.usage = usage_message(function_table)
  return setmetatable(function_table, function_metatable)
end

local function varargs(...)
  return {
    __varargs = true,
    ...
  }
end


export("method", method)