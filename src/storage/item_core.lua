-- ================ item_core ================== --
--[[
   This module is an interface for a custom binary
   database used to store information about items
   in the storage system
   
   Format:
   Byte 1-2:   item_id (uint16)
   Byte 3-5:   item_count (uint24)
   Byte 6-7:   item_mod (uint16)
   Byte 8-n:   item_name (\x00 string \x00)
   
   Example:
   00 01  00 01  00 01 23  00 73 74 6F 6E 65 00
   [Iid]  [Mid]  [count ]  [    item_name     ]
   
   Notes:
    - Item id must be unique
    - Item id starts at 1, 0 is used for no item
    - Name is assumed to only contain alphabetical
      characters
    - The database has a null byte at the start for
      convenience
    - mod_id combined with item name is always
      unique
    - The item name must not be less than 6 chars
      long. If so, the name will be padded with
      spaces to the right
]]--

local db_misc = require "/storage/db_misc"
local mods_core = require "/storage/mods_core"

local item_core = {}

local items_path = db_misc.db_path.."items.db"


--- Adds escape chars to lua's magic characters
--- for example given ")." the result is "%)%."
--- @param search string: String to escape chars
--- @return string: Escaped string
local function escape_magic_chars(search)
   search = search:gsub("%%", "%%%%")
   search = search:gsub("%(", "%%%(")
   search = search:gsub("%)", "%%%)")
   search = search:gsub("%.", "%%%.")
   search = search:gsub("%+", "%%%+")
   search = search:gsub("%-", "%%%-")
   search = search:gsub("%*", "%%%*")
   search = search:gsub("%?", "%%%?")
   search = search:gsub("%[", "%%%[")
   search = search:gsub("%]", "%%%]")
   search = search:gsub("%^", "%%%^")
   search = search:gsub("%$", "%%%$")
   return search
end

--- Finds the next available id for a new item
--- @return number: Available id
local function next_free_id(items)
   local srt, search, index = 0, " ", 0
   while srt and search do
      index = index + 1
      search = db_misc.num_to_uint16(index)
      search = escape_magic_chars(search).."....."
      srt, _ = items:find("\x00"..search.."\x00")
   end
   return index
end

--- Serialises item data to be stored in database
--- @param item_data table: Dictionary of item data
--- @return string|nil: Return nil if error
local function serialise_item(item_data)
   local items = db_misc.read_database(items_path)
   local item_id = item_data.id
   if not item_id then
      item_id = next_free_id(items)
   end
   item_id = db_misc.num_to_uint16(item_id)
   local item_count = item_data.count
   item_count = db_misc.num_to_uint24(item_count)
   local item_mod = mods_core.get_id(item_data.mod)
   if not item_mod then
      mods_core.add_mod(item_data.mod)
      item_mod = mods_core.get_id(item_data.mod)
   end
   item_mod = db_misc.num_to_uint16(item_mod)
   local item_name = item_data.name
   if item_name:len() < 6 then
      local pad = (" "):rep(6 - item_name:len())
      item_name = item_name..pad
   end
   item_name = "\x00"..item_name.."\x00"
   local raw_data = item_id..item_count..item_mod
   return raw_data..item_name
end

--- Deserialises item data to be used
--- @param raw_data string: item data in database
--- @return table: deserialised data in dictionary
local function deserialise_item(raw_data)
   local item_id = raw_data:sub(1, 2)
   local item_count = raw_data:sub(3, 5)
   local item_mod = raw_data:sub(6, 7)
   local item_name = raw_data:sub(9, -2)
   item_name = item_name:gsub(" ", "")
   return {
      ["id"] = db_misc.uint16_to_num(item_id),
      ["num"] = db_misc.uint24_to_num(item_count),
      ["mod"] = db_misc.uint16_to_num(item_mod),
      ["name"] = item_name
   }
end


--- Add an item to the end of the database
--- @param item_data table: Dictionary of item data
--- @return nil|string: Returns error if failed
function item_core.add_item(item_data)
   local item_nam = item_data.name
   local item_mod = item_data.mod
   if not mods_core.get_id(item_mod) then
      mods_core.add_mod(item_mod)
   end
   if item_core.name_exists(item_nam,item_mod) then
      return "Item already exists"
   end
   local raw_data = serialise_item(item_data)
   local items = db_misc.read_database(items_path)
   items = items..raw_data
   db_misc.write_database(items_path, items)
end

--- Removes an item from the database
--- @todo deny deleting item if it has dependencies
--- @param item_id number: uint16 id of the item
--- @return nil|string: return if error
function item_core.del_item(item_id)
   if not item_core.id_exists(item_id) then
      return "Item does not exist"
   end
   local items = db_misc.read_database(items_path)
   item_id = db_misc.num_to_uint16(item_id)
   item_id = escape_magic_chars(item_id)
   local search = "\x00"..item_id..".....\x00"
   local srt, fin = items:find(search)
   _, fin = items:find("\x00", fin + 1)
   items = items:sub(1, srt)..items:sub(fin + 1)
   db_misc.write_database(items_path, items)
end

--- Updates item_count of a given item_id
--- @param item_id number: uint16 id of item
--- @param item_count number: uint24 total count
--- @return string|nil: return if err
function item_core.upd_item(item_id, item_count)
   if not item_core.id_exists(item_id) then
      return "Item does not exist"
   end
   local items = db_misc.read_database(items_path)
   item_id = db_misc.num_to_uint16(item_id)
   item_id = escape_magic_chars(item_id)
   item_count = db_misc.num_to_uint24(item_count)
   local search = "\x00"..item_id..".....\x00"
   local srt, fin = items:find(search)
   local srt_slice = items:sub(1, srt + 2)
   local fin_slice = items:sub(fin - 2)
   items = srt_slice..item_count..fin_slice
   db_misc.write_database(items_path, items)
end


--- Checks is a given item name with mod is in the
--- database already
--- @param item_name string: Name of the item
--- @param item_mod string: Name of the mod
--- @return boolean: Whether it exists or not
function item_core.name_exists(item_name, item_mod)
   item_mod = mods_core.get_id(item_mod)
   if not item_mod then return false end
   item_mod = db_misc.num_to_uint16(item_mod)
   item_mod = escape_magic_chars(item_mod)
   if item_name:len() < 6 then
      local pad = (" "):rep(6 - item_name:len())
      item_name = item_name..pad
   end
   local items = db_misc.read_database(items_path)
   local search = "\x00....."..item_mod.."\x00"
   search = search..item_name.."\x00"
   if items:find(search) then return true end
   return false
end

--- @param item_id number: uint16 id of the item
--- @return boolean: whether it was found or not
function item_core.id_exists(item_id)
   local items = db_misc.read_database(items_path)
   item_id = db_misc.num_to_uint16(item_id)
   item_id = escape_magic_chars(item_id)
   local search = "\x00"..item_id..".....\x00"
   print(items:find(search))
   if items:find(search) then return true end
   return false
end


--- Returns item_data given the item name and mod
--- @param item_name string: Name of the item
--- @param item_mod string: Name of the mod
--- @return table|nil: Return nothing if err
function item_core.data_by_name(item_name,item_mod)
   local items = db_misc.read_database(items_path)
   item_mod = mods_core.get_id(item_mod)
   if not item_mod then return nil end
   item_mod = db_misc.num_to_uint16(item_mod)
   item_mod = escape_magic_chars(item_mod)
   if item_name:len() < 6 then
      local pad = (" "):rep(6 - item_name:len())
      item_name = item_name..pad
   end
   local search = "\x00....."..item_mod.."\x00"
   search = search..item_name.."\x00"
   local srt, fin = items:find(search)
   if not (srt or fin) then return nil end
   local raw_data = items:sub(srt + 1, fin)
   return deserialise_item(raw_data)
end

--- Returns item_data given the item's ID
--- @param item_id number: uint16 ID of the item
--- @return table|nil: Return nothing if err
function item_core.data_by_id(item_id)
   local items = db_misc.read_database(items_path)
   item_id = db_misc.num_to_uint16(item_id)
   item_id = escape_magic_chars(item_id)
   local search = "\x00"..item_id..".....\x00"
   local srt, fin = items:find(search)
   if not (srt or fin) then return nil end
   _, fin = items:find("\x00", fin + 1)
   local raw_data = items:sub(srt + 1, fin)
   return deserialise_item(raw_data)
end


return item_core