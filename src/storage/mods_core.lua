-- ================ mods_core ================== --
--[[
   This module is an interface for the a custom
   binary database used to store mod names.
   
   Format:
   Byte 1-2:   mod_id   (uint16)
   Byte 2-n:   mod_name (null terminated string)
   
   Example:
   00 01  6D 69 6E 65 63 72 61 66 74 00
   [ID ]  [           name            ]
   
   Notes:
    - ID must be unique
    - ID starts from 1
    - Name is assumed to only contain alphabetical
      characters
    - The database has a null byte at the start
]]--

local db_misc = require "/storage/db_misc"

local mods_core = {}

local mods_path = db_misc.db_path.."mods.db"

--- Finds the next available id for a mod
--- @param mods string: String containing mods.db
--- @return number: Available id to use
local function next_free_id(mods)
   local srt, search, index = 0, " ", 0
   while srt and search do
      index = index + 1
      search = "\x00"..db_misc.num_to_uint16(index)
      srt, _ = mods:find(search, 1, false)
   end
   return index
end

--- Adds mod to the database, assumes mod not exist
--- @param mod_name string: Name of the mod to add
--- @return nil|string: Return string if failed
function mods_core.add_mod(mod_name)
   if mods_core.mod_exists(mod_name) then
      return "Mod already exists"
   end
   local mods = db_misc.read_database(mods_path)
   local mod_id = next_free_id(mods)
   mod_id = db_misc.num_to_uint16(mod_id)
   local serialised_data = mod_id..mod_name.."\x00"
   mods = mods..serialised_data
   db_misc.write_database(mods_path, mods)
end

--- @todo create functionality for deleting mod
---       make sure it denies deletion if items
---       are in the database that still use it
function mods_core.del_mod()

end

--- Determines if mod exists in database or not
--- @param mod_name string: Name of the mod to look
--- @return boolean: Whether the mod was found
function mods_core.mod_exists(mod_name)
   local mods = db_misc.read_database(mods_path)
   local search = ".."..mod_name.."\x00"
   if mods:find(search) then return true end
   return false
end

--- Finds mod_name given its id
--- @param mod_id number: uint16 id of the mod
--- @return string|nil: Return nil if failed
function mods_core.get_name(mod_id)
   local mods = db_misc.read_database(mods_path)
   mod_id = db_misc.num_to_uint16(mod_id)
   local search = "\x00"..mod_id
   local _, srt = mods:find(search, 1, true)
   local fin, _ = mods:find("\x00", srt)
   if not (srt or fin) then return nil end
   local mod_name = mods:sub(srt + 1, fin - 1)
   return mod_name
end

--- Finds mod_id given its name
--- @param mod_name string: Name of the mod to look
--- @return number|nil: return nil if failed
function mods_core.get_id(mod_name)
   local mods = db_misc.read_database(mods_path)
   local search = ".."..mod_name.."\x00"
   local srt, _ = mods:find(search)
   if not srt then return nil end
   local mod_id = mods:sub(srt, srt + 1)
   mod_id = db_misc.uint16_to_num(mod_id)
   return mod_id
end

return mods_core