--                   stores_db                   --
--    A storage system for CC:T and CC:R mods    --
--         Copyright (C) 2024 CitricCode         --

--[[
   This module is an interface that extends base_db
   for a custom binary database used to store the
   contents of each chest in the storage system
   
   Format:
   Byte 1:     chest_id  (uint8)    FK
   Byte 2-3:   chest_num (uint16)
   Byte 4:     slot_num  (uint8)
   Byte 5-6:   item_id   (uint16)   FK
   Byte 7:     count     (uint8)
   Byte 8:     null byte (\0)
   
   Example:
   01  02 34  05  00 06  7F  00
   id  ch_nu  sl  it_id  co
   
   Notes:
    - All numbers start at 1
    - The database has a null byte at the start for
      convenience
]]--

local db_misc = require "database.db_misc"
local base_db = require "database.base_db"
base_db.db_path = "/databases/stores.db"

local stores_db = base_db:init()

--- Serialises slot data to be stored in database
--- @param data table: Dict containing store data
--- @return string raw_data: Serialised slot data
function stores_db:_serialise(data)
   local c_id = db_misc.to_str(1, data.c_id)
   local c_num = db_misc.to_str(2, data.c_num)
   local s_id = db_misc.to_str(1, data.s_id)
   local i_id = db_misc.to_str(2, data.i_id)
   local num = db_misc.to_str(1, data.num)
   return c_id..c_num..s_id..i_id..num.."\0"
end

--- Deserialises slot data to be used
--- @param raw_data string: Serialised slot data
--- @return table data: Deserialised data in table
function stores_db:_deserialise(raw_data)
   return {
      ["c_id"] = db_misc.to_num(raw_data:sub(1,1)),
      ["c_num"]= db_misc.to_num(raw_data:sub(2,3)),
      ["s_id"] = db_misc.to_num(raw_data:sub(4,4)),
      ["i_id"] = db_misc.to_num(raw_data:sub(5,6)),
      ["num"] = db_misc.to_num(raw_data:sub(7,7))
   }
end

--- Returns the start index and end index for where
--- the given chest slot is stored in the database
--- @param data table: Dict containing store data
--- @return number|nil,number|nil: Nil if not found
function stores_db:_get_pos(data)
   local c_id = db_misc.to_str(1, data.c_id)
   c_id = db_misc.esc_char(c_id)
   local c_num = db_misc.to_str(2, data.c_num)
   c_num = db_misc.esc_char(c_num)
   local s_id = db_misc.to_str(1, data.s_id)
   s_id = db_misc.esc_char(s_id)
   local patrn = "\0"..c_id..c_num..s_id.."...\0"
   local srt, fin = self.db:find(patrn)
   return srt, fin
end

--- Returns the start and end index for each item
--- that is stored in a given chest
--- @param data table: Dict containing store data
--- @return table: Array of positions in the db 
function stores_db:_get_poses(data)
   local c_id = db_misc.to_str(1, data.c_id)
   c_id = db_misc.esc_char(c_id)
   local c_num = db_misc.to_str(2, data.c_num)
   c_num = db_misc.esc_char(c_num)
   local patrn = "\0"..c_id..c_num.."....\0"
   local srt, fin, res = 0, 0, {}
   while srt do
      srt, fin = self.db:find(patrn)
      res:insert({srt, fin})
   end
   return res
end

--- This module is a linking table and does not
--- have a primary key, as such this func should
--- not be used
function stores_db:_next_id() end


--- Returns a list of deserialised slot data for
--- a given chest
--- @param data table: Dict containing store data
function stores_db:get_contents(data)
   local res = {}
   local poses = self:_get_poses(data)
   for _, loc in ipairs(poses) do
      local raw_dat = self.db:sub(loc[1]+1, loc[2])
      res:insert(self:_deserialise(raw_dat))
   end
   return res
end

--- Updates a specific slot's item id and count
--- @param data table: Dict containing store data
function stores_db:upd(data)
   local srt, _ = self:_get_pos(data)
   if not srt then
      local data = textutils.serialise(data)
      error(data.."\n"..debug.traceback())
   end
   local i_id = db_misc.to_str(2, data.i_id)
   local dat = i_id..db_misc.to_str(1, data.num)
   local db = self.db
   self.db = db:sub(1, srt+3)..dat..db:sub(srt+6)
end

--- Updates all slots within a given chest. Assumes
--- `all_data` is a list of new slot data.
--- `data.c_id` and `data.c_num` must be set
--- @param data table: Dict containing store data
--- @param slot_data table: List of new slot data
--- shit looks buggy as crap this **will** throw errors at your face
function stores_db:upd_all(data, slot_data)
   local res = self:get_contents(data)
   for _, result in ipairs(res) do
      self:del(result)
   end
   for _,slot in ipairs(slot_data) do
      self:add(slot)
   end
   self.data = all_data
end

return stores_db