-- ================ chests_core ================ --
--[[
   This module is an interface for a custom binary
   database used to store chests in the network and
   the contents within them

   Format:
   Byte 1-2:   chest_id   (uint16)
   Byte 3:     null byte  (\x00)
   Byte 4-n:   chest_name (Null terminated string)

   Example:
   00 01  00 63 68 65 73 74 5F 31 00
   [id ]  [          name          ]

   Notes:
    - ID must be unique
    - ID starts from 1
    - Name is assumed to only contain alphabetical
      characters and "_"
    - The database has a null byte at the start for
      convenience
]]--

local db_misc = require "/storage/db_misc"

local chest_core = {}

local chests_path = db_misc.db_path.."chests.db"

--- Finds the next available id for a chest
--- @param chests string: Entire chests.db
--- @return number: Available id to use
local function next_free_id(chests)
   local srt, search, index = 0, " ", 0
   while srt and search do
      index = index + 1
      search = db_misc.num_to_uint16(index)
      search = db_misc.escape_chars(search)
      srt, _ = chests:find("\x00"..search.."\x00")
   end
   return index
end


--- Adds a chest to the database
--- @param chest_name string: Name of the chest
--- @return nil|string: Return string if failed
function chest_core.add_chest(chest_name)
   if chest_core.chest_exists(chest_name) then
      return "Chest already exists"
   end
   local chests=db_misc.read_database(chests_path)
   local chest_id = next_free_id(chests)
   chest_id = db_misc.num_to_uint16(chest_id)
   chest_name = "\x00"..chest_name.."\x00"
   chests = chests..chest_id..chest_name
   db_misc.write_database(chests_path, chests)
end

--- Removes a chest from the database
--- @param chest_id number: uint16 id of the chest
--- @return nil|string: return if error
function chest_core.del_chest(chest_id)
   local chests=db_misc.read_database(chests_path)
   chest_id = db_misc.num_to_uint16(chest_id)
   chest_id = db_misc.escape_chars(chest_id)
   local search = "\x00"..chest_id.."\x00"
   local srt, _ = chests:find(search)
   if not srt then return "Mod not found" end
   local fin, _ = chests:find("\x00", srt + 4)
   chests = chests:sub(1, srt)..chests:sub(fin + 1)
   db_misc.write_database(chests_path, chests)
end

--- Overrides contents of chest
function chest_core.upd_chest()

end


--- Determines if a chest exists in database or not
--- @param chest_name string: Name of the chest
--- @return boolean: Whether the chest was found
function chest_core.chest_exists(chest_name)
   local chests=db_misc.read_database(chests_path)
   local search = "\x00"..chest_name.."\x00"
   if chests:search(search) then return true end
   return false
end

--- Finds chest_name given its id
--- @param chest_id number: uint16 id of the chest
--- @return string|nil: Return nil if failed
function chest_core.get_name(chest_id)
   local chests=db_misc.read_database(chests_path)
   chest_id = db_misc.num_to_uint16(chest_id)
   chest_id = db_misc.escape_chars(chest_id)
   local search = "\x00"..chest_id.."\x00"
   local _, srt = chests:find(search)
   if not srt then return nil end
   local fin, _ = chests:find("\x00", srt)
   local chest_name = chests:sub(srt + 1, fin - 1)
   return chest_name
end

--- Finds chest_id given its name
--- @param chest_name string: Name of the chest
--- @return number|nil: return nil if failed
function chest_core.get_id(chest_name)
   local chests=db_misc.read_database(chests_path)
   local search = "\x00"..chest_name.."\x00"
   local srt, _ = chests:find(search)
   if not srt then return nil end
   local chest_id = chests:sub(srt - 2, srt - 1)
   chest_id = db_misc.uint16_to_num(chest_id)
   return chest_id
end


return chest_core