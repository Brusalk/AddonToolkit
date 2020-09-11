local AddonToolkitName, AddonToolkitModule = ...


-- AddonToolkit
--   * Interface that provides enhanced development tools
-- AddonNamespace
--   * Execution environment for an addon using AddonToolkit.

local original_globals = _G
local format = string.format
local addons = {}
local AddonNamespaceMetatable = {}
function AddonNamespaceMetatable:__tostring()
  return format("<AddonNamespace: %s>", self.__name)
end


function AddonNamespaceMetatable:__newindex(key, value)
  error(format("%s Leaking Global %s=%s! You cannot implicitly leak global values through to your AddonNamespace. " ..
               "If you want to export a value for other addons to import, use 'export(name, value)'. " ..
               "If you want to expose a value to the global WoW scope, use 'expose(name, value)'",
               tostring(self),
               tostring(key),
               tostring(value)
              ))
end


local function create_addon_namespace(name, addon_table, prior_env)
  if addons[name] then
    error(format("Name %q already defined as an Addon using AddonToolkit", name))
  end
  local addon_namespace = setmetatable({}, AddonNamespaceMetatable)
  AddonToolkitModule.mixin(addon_namespace, AddonToolkitModule)
  rawset(addon_namespace, "__name", name)
  rawset(addon_namespace, "__addon", addon_table)
  rawset(addon_namespace, "__prior_env", prior_env)
  addon_table.__namespace = addon_namespace
  addons[name] = addon_table
  return name, addon_table
end


-- Register/Receive an AddonNamespace with AddonToolkit
-- The execution environment of the file will be modified to use AddonToolkit
-- to be able to take advantage of AddonToolkits feature set and stdlib
-- Expected Usage (first line of all files): local name, MyAddon = AddonToolkit.AddOn(...)
function AddonToolkitModule.AddOn(name, addon_table, dont_isolate)
  if not addon_table.__namespace then
    name, addon_table = create_addon_namespace(name, addon_table, getfenv(2))
  end
  if not dont_isolate then
    setfenv(2, addon_table.__namespace)
  end
  return name, addon_table
end


-- Register/Receive a namespace for a particular module of an Addon.
-- This is _basically_ the same as being a separate addon, except names are
-- scoped to within the addon, so a module "logging" could exist for addon
-- "A" and addon "B"
-- A module is quite literally an addon just named "addon_name.module_name",
-- and can be imported as such
function AddonToolkitModule.Module(name, dont_isolate)
  local addon_namespace = getfenv(2) -- Get addon namespace from the caller
  if not addon_namespace.__name then
    error("Cannot directly create a module. Instead, you must first create/load an AddonToolkit AddOn")
  end

  local module_name = format("%s.%s", addon_namespace.__name, name)
  local module_table = addons[module_name]

  if not module_table then
    local _, t = create_addon_namespace(module_name, {})
    module_table = t
  end

  if not dont_isolate then
    setfenv(2, addons[module_name].__namespace)
  end

  return module_name, module_table
end



-- Mix-in a set of parent objects that obj should receive methods/constants from
-- Last write wins
local function starts_with(str, with)
  return string.sub(str, 1, string.len(with)) == with
end
function AddonToolkitModule.mixin(obj, ...)
  for _, mixin in ipairs({...}) do -- Technically misses nils, but w/e
    for key, value in pairs(mixin) do
      if not starts_with(key, "__") then -- Don't copy private members
        rawset(obj, key, value)
      end
    end
  end
  return obj
end


-- Import a value (or values if a list) from the specified AddonNamespace (or ModuleNamespace)
-- If AddonNamespace is a string, import from the Addon/Module named so
-- If AddonNamespace is a table, import from it directly.
-- If no AddonNamespace is given, imports from WoW Global scope
function AddonToolkitModule.import(name, from_addon)
  if not from_addon then
    return original_globals[name]
  end
  from_addon = type(from_addon) == "string" and AddonToolkitModule.get_addon(from_addon) or from_addon
  return from_addon[name] or from_addon.__namespace[name]
end


-- Export a value to the AddonNamespace. This _must_ be an explicit action
-- and implicit "global" setting is disallowed
function AddonToolkitModule.export(as, value, to)
  local addon_namespace = getfenv(2) -- Get namespace of caller :)
  if not addon_namespace.__addon and not to then
    error("Cannot export a value in an unisolated namespace without an explicit target")
  end

  if not addon_namespace.__addon then
    addon_namespace = to.__namespace
  end
  return rawset(addon_namespace, as, value)
end

-- Expose a value from the AddonNamespace to the global WoW namespace
function AddonToolkitModule.expose(as, value)
  original_globals[as] = value
  return value
end


-- Run a function in an addon's namespace
local function run_as_env(env, func, ...)
  local original_fenv = getfenv(func)
  setfenv(func, env)
  local rets = {func(...)}
  setfenv(func, original_fenv)
  return unpack(rets)
end


-- Run a function unisolated. It'll run in the original global and fenv
function AddonToolkitModule.unisolated(func, ...)
  local addon_namespace = getfenv(2)
  return run_as_env(addon_namespace.__prior_env, func, ...)
end


function AddonToolkitModule.get_addon(name)
  if not addons[name] then
    error(format("Addon/Module %q has not been defined yet. " +
                 "Check your load order and that libraries are properly loading", name))
  end
  return addons[name]
end

AddonToolkitModule.get_module = AddonToolkitModule.get_addon


-- Now we can init AddonToolkit!
AddonToolkitModule.AddOn(AddonToolkitName, AddonToolkitModule, false)
AddonToolkitModule.expose("AddonToolkit", AddonToolkitModule)
