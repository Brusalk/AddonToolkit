local helpers = {}


-- Load a file for an addon how WoW does. The addon name and addon_table are passed into each file via ...
-- While loading all files from a given .toc (or nested xmls), the same addon table is passed in to every
-- lua file/context. Thus, we do that here
local addons = {}
function helpers.addon_loadfile(addon_name, filepath)
  local addon_table = addons[addon_name] or {}
  file_loader = assert(loadfile(filepath))
  return file_loader(addon_name, addon_table)
end


return helpers