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
      search = escape_magic_chars(search)
      srt, _ = items:find("\x00"..search..".-\x00")
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
   local item_name = "\x00"..item_data.name.."\x00"
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
   local item_name = raw_data:sub(8, -2)
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
   if item_core.item_exists(item_data) then
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
function item_core.del_item()
   if not item_core.item_exists() then
      
   end
end

function item_core.upd_item()

end


--- Checks is a given item name with mod is in the
--- database already
--- @param item_name string: Name of the item
--- @param item_mod string: Name of the mod
--- @return boolean: Whether it exists or not
function item_core.name_exists(item_name, item_mod)
   local items = db_misc.read_database(items_path)
   item_mod = db_misc.num_to_uint16(item_mod)
   item_mod = escape_magic_chars(item_mod)
   local search = "\x00....."..item_mod.."\x00"
   search = search..item_name.."\x00"
   if items:find(search) then return true end
   return false
end

--- Checks if a given item id is in the database
--- already
--- @param item_id number: uint16 id of the item
--- @return boolean: whether it was found or not
function item_core.id_exists(item_id)
   local items = db_misc.read_database(items_path)
   item_id = db_misc.num_to_uint16(item_id)
   item_id = escape_magic_chars(item_id)
   local search = "\x00"..item_id..".....\x00"
   if items:find(search) then return true end
   return false
end

function item_core.data_by_name()

end

function item_core.data_by_id()

end


-- --- Add an item to the end of the database
-- --- @param item_data table: Dictionary of item data
-- --- @return nil|string: Returns error if failed
-- function database.append_item(item_data)
--    local mod_name = item_data.mod
--    local item_name = item_data.name
--    if database.item_exist(mod_name, item_name) then
--       return "Item already exists"
--    end
--    local serialised_data=serialise_item(item_data)
--    local database_file = fs.open(items_path, "ab")
--    database_file.write(serialised_data)
--    database_file.close()
-- end

-- --- Modifies count stored in database because the
-- --- other values should not be modified
-- --- @param item_id number: ID of the item to update
-- --- @param item_count number: New count in storage
-- --- @return nil|string: return string if failed
-- function database.update_item(item_id, item_count)
--    local err
--    item_count,err=db_misc.num_to_uint24(item_count)
--    if err then return err end
--    local items = db_misc.read_database(items_path)

--    local fin, index = 0, 0
--    while index ~= item_id do
--       _, fin = items:find("\x00", fin + 4)
--       if not fin then
--          return "Could not be found"
--       end
--       index = index + 1
--    end
--    local start_slice = items:sub(1, fin)
--    local end_slice = items:sub(fin + 4)
--    items = start_slice..item_count..end_slice
--    db_misc.write_database(items_path, items)
-- end

-- --- Ditermines whether item exists in database
-- --- @param mod_name string: Name of the item's mod
-- --- @param item_name string: Name of the item
-- --- @return boolean: If found in database or not
-- function database.item_exist(mod_name, item_name)
--    if not mods_core.mod_exists(mod_name) then
--       return false
--    end
--    local items = db_misc.read_database(items_path)
--    local mod_id = mods_core.get_id(mod_name)
--    mod_id = db_misc.num_to_uint8(mod_id)
--    local search = mod_id..item_name.."\x00"
--    local _, result = items:find(search, 1, true)
--    if result then return true end
--    return false
-- end

-- --- Finds item_id of item given its mod and name
-- --- @param mod_name string: Name of the items mod
-- --- @param item_name string: Name of the item
-- --- @return number|nil: returns nil if not found
-- function database.find_item_id(mod_name, item_name)
--    local exists
--    exists=database.item_exist(mod_name, item_name)
--    if not exists then return nil end
--    local items = db_misc.read_database(items_path)
--    local mod_id = mods_core.get_id(mod_name)
--    local mod_id = db_misc.num_to_uint8(mod_id)
--    local target = mod_id..item_name.."\x00"
--    local cur_name = ""
--    local srt, fin, index = 0, -4, 0
--    while cur_name ~= target do
--       srt = fin + 4
--       _, fin = items:find("\x00", fin + 4)
--       if not fin then return nil end
--       cur_name = items:sub(srt, fin)
--       index = index + 1
--    end
--    return index
-- end

-- --- Returns item data given it's id
-- --- @param item_id number: Id of the item to get
-- --- @return table|nil: Dictionary storing item data
-- function database.get_item_data(item_id)
--    local items = db_misc.read_database(items_path)
--    local srt, fin, index = 0, -4, 0
--    while item_id ~= index do
--       srt = fin + 4
--       _, fin = items:find("\x00", fin + 4)
--       if not fin then return nil end
--       index = index + 1
--    end
--    fin = fin + 3
--    local raw_data = items:sub(srt, fin)
--    local item_data = deserialise_item(raw_data)
--    return item_data
-- end

return item_core