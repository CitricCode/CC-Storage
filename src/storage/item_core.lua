-- ================ item_core ================== --
-- This module is an interface for the items and
-- mods databases

local db_misc = require "/storage/db_misc"

local database = {}

local databases_path = "/storage/databases/"
local items_path = databases_path.."items.db"
local mods_path = databases_path.."mods.db"

--                 Mods database                 --
--              name: string|"\x00"              --

--- Adds mod to the database, assumes mod not exist
--- @param mod_name string: Name of the mod to add
local function append_mod(mod_name)
   local database_file = fs.open(mods_path, "ab")
   database_file.write(mod_name.."\x00")
   database_file.close()
end

--- Determines if mod exists in database or not
--- @param mod_name string: Name of the mod to look
--- @return boolean: Whether the mod was found
local function mod_exist(mod_name)
   local mods = db_misc.read_database(mods_path)
   if mods:find(mod_name, 1, true) then
      return true
   end
   return false
end

--- Finds the mod name from its id
--- @param mod_id number: uint8 id of the mod
--- @return string|nil: Name of the mod or nil
local function get_mod_name(mod_id)
   local mods = db_misc.read_database(mods_path)
   local srt, fin, index = 0, 0, 0
   while index ~= mod_id do
      srt = fin
      _, fin = mods:find("\x00", fin + 1)
      if not fin then return nil end
      index = index + 1
   end
   local mod_name = mods:sub(srt + 1, fin - 1)
   return mod_name
end

--- Finds mod id from its name, assumes mod exists
--- @param mod_name string: Name of the mod to look
--- @return number|nil: The found mod id or nil
local function get_mod_id(mod_name)
   local mods = db_misc.read_database(mods_path)
   local srt, _ = mods:find(mod_name, 1, true)
   if not srt then return nil end
   mods = mods:sub(1, srt - 1)
   local _, mod_id = mods:gsub("\x00", "")
   return mod_id + 1
end

--                 Item database                 --
--mod_id: uint8|name: string|"\x00"|count: uint24--

--- Serialises item data to be stored
--- @param item_data table: Dictionary of item data
--- @return string: Serialised data to be stored
local function serialise_item(item_data)
   if not mod_exist(item_data.mod) then
      append_mod(item_data.mod)
   end
   local mod_id = get_mod_id(item_data.mod)
   mod_id = db_misc.num_to_uint8(mod_id)
   local item_name = item_data.name.."\x00"
   local item_num = item_data.count
   local item_num = db_misc.num_to_uint24(item_num)
   local serialised_data = mod_id..item_name
   serialised_data = serialised_data..item_num
   return serialised_data
end

--- Deserialises item data to be used
--- @param raw_data string: item data in database
--- @return table: deserialised data in dictionary
local function deserialise_item(raw_data)
   local len = raw_data:len()
   local mod_id = raw_data:byte(1)
   local mod_name = get_mod_name(mod_id)
   local item_name = raw_data:sub(2, len - 4)
   local item_count = raw_data:sub(len - 2, len)
   item_count = db_misc.uint24_to_num(item_count)
   local item_data = {
      ["mod"] = mod_name,
      ["name"] = item_name,
      ["count"] = item_count
   }
   return item_data
end

--- Add an item to the end of the database
--- @param item_data table: Dictionary of item data
--- @return nil|string: Returns error if failed
function database.append_item(item_data)
   local mod_name = item_data.mod
   local item_name = item_data.name
   if database.item_exist(mod_name, item_name) then
      return "Item already exists"
   end
   local serialised_data=serialise_item(item_data)
   local database_file = fs.open(items_path, "ab")
   database_file.write(serialised_data)
   database_file.close()
end

--- Modifies count stored in database because the
--- other values should not be modified
--- @param item_id number: ID of the item to update
--- @param item_count number: New count in storage
--- @return nil|string: return string if failed
function database.update_item(item_id, item_count)
   local err
   item_count,err=db_misc.num_to_uint24(item_count)
   if err then return err end
   local items = db_misc.read_database(items_path)

   local fin, index = 0, 0
   while index ~= item_id do
      _, fin = items:find("\x00", fin + 4)
      if not fin then
         return "Could not be found"
      end
      index = index + 1
   end
   local start_slice = items:sub(1, fin)
   local end_slice = items:sub(fin + 4)
   items = start_slice..item_count..end_slice
   db_misc.write_database(items_path, items)
end

--- Ditermines whether item exists in database
--- @param mod_name string: Name of the item's mod
--- @param item_name string: Name of the item
--- @return boolean: If found in database or not
function database.item_exist(mod_name, item_name)
   if not mod_exist(mod_name) then return false end
   local items = db_misc.read_database(items_path)
   local mod_id = get_mod_id(mod_name)
   mod_id = db_misc.num_to_uint8(mod_id)
   local search = mod_id..item_name.."\x00"
   local _, result = items:find(search, 1, true)
   if result then return true end
   return false
end

--- Finds item_id of item given its mod and name
--- @param mod_name string: Name of the items mod
--- @param item_name string: Name of the item
--- @return number|nil: returns nil if not found
function database.find_item_id(mod_name, item_name)
   local exists
   exists=database.item_exist(mod_name, item_name)
   if not exists then return nil end
   local items = db_misc.read_database(items_path)
   local mod_id = get_mod_id(mod_name)
   local mod_id = db_misc.num_to_uint8(mod_id)
   local target = mod_id..item_name.."\x00"
   local cur_name = ""
   local srt, fin, index = 0, -4, 0
   while cur_name ~= target do
      srt = fin + 4
      _, fin = items:find("\x00", fin + 4)
      if not fin then return nil end
      cur_name = items:sub(srt, fin)
      index = index + 1
   end
   return index
end

--- Returns item data given it's id
--- @param item_id number: Id of the item to get
--- @return table|nil: Dictionary storing item data
function database.get_item_data(item_id)
   local items = db_misc.read_database(items_path)
   local srt, fin, index = 0, -4, 0
   while item_id ~= index do
      srt = fin + 4
      _, fin = items:find("\x00", fin + 4)
      if not fin then return nil end
      index = index + 1
   end
   fin = fin + 3
   local raw_data = items:sub(srt, fin)
   local item_data = deserialise_item(raw_data)
   return item_data
end

return database