--                    item_db                    --
--    A storage system for CC:T and CC:R mods    --
--         Copyright (C) 2024 CitricCode         --

--[[
   This module is an interface that extends base_db
   for a custom binary database used to store
   information about items in the storage system
   
   Format:
   Byte 1-2:   item_id    (uint16)  PK
   Byte 3-5:   item_num   (uint24)
   Byte 6-7:   item_mod   (uint16)  FK
   Byte 8:     null byte  (\0)
   Byte 9-n:   item_name  (Null terminated string)
   
   Example:
   00 01  00 01 23  00 01  00 73 74 6F 6E 65 00
   [Iid]  [ num  ]  [Mid]  [    item_name     ]
   
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
]]--test = require "database.db_misc"
--- @module "types"

--- @class item_data
--- @field id uint16: ID of the item
--- @field num uint24: Total sum of the item in db
--- @field m_id uint8: ID of the item's mod
--- @field name string: Name of the item


local db_misc = require "database.db_misc"
local base_db = require "database.base_db"
base_db.db_path = "/databases/items.db"

local item_db = base_db:init()


--- Serialises item data to be stored in database
--- @param data item_data: Item data to serialise
--- @return string raw_data: Serialised item data
function item_db:_serialise(data)
   local id = db_misc.to_str(2, data.id)
   local num = db_misc.to_str(3, data.num)
   local m_id = db_misc.to_str(2, data.m_id)
   local name = db_misc.pack_str(data.name)
   if #name<6 then name=name..(" "):rep(6-#name) end
   return id..num..m_id.."\0"..name.."\0"
end

--- Deserialises item data to be used
--- @param raw_data string: Serialised item data
--- @return item_data data: Deserialised data
function item_db:_deserialise(raw_data)
   return {
      id = db_misc.to_num(raw_data:sub(1, 2)),
      num = db_misc.to_num(raw_data:sub(3, 5)),
      m_id = db_misc.to_num(raw_data:sub(6, 7)),
      name = raw_data:sub(9, -2):gsub(" ", "")
   }
end

function item_db:_iterate()
   local srt, fin = 0, 0
   return function ()
      srt, fin = fin + 1, fin + 8
      while self.db:byte(fin)<128 do fin=fin+1 end
      return srt, fin
   end
end

--- Returns the start index and end index for where
--- the given item is stored in the database
--- @param data item_data: Item data to find
--- @return number|nil,number|nil: Nil if not found
function item_db:_get_pos(data)
   local srt, fin
   if data.id then
      local id = db_misc.to_str(2, data.id)
      id = "\0"..db_misc.esc_char(id)..".....\0"
      srt, fin = self.db:find(id.."(.-)\0")
   else
      local m_id = db_misc.to_str(2, data.m_id)
      m_id = "\0....."..db_misc.esc_char(m_id)
      local name = data.name
      name = name..(" "):rep(6-name:len())
      srt, fin=self.db:find(m_id.."\0"..name.."\0")
   end
   return srt, fin
end

--- Updates item_count of a given item
--- @param data item_data: Item data to update to
function item_db:upd(data)
   local srt, _ = self:_get_pos(data)
   if not srt then
      local data = textutils.serialise(data)
      error(data.."\n"..debug.traceback())
   end
   local db = self.db
   local num = db_misc.to_str(3, data.num)
   self.db = db:sub(1,srt+2)..num..db:sub(srt+5)
end


return item_db