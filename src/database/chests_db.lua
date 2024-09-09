--                   chests_db                   --
--    A storage system for CC:T and CC:R mods    --
--         Copyright (C) 2024 CitricCode         --

--[[
   This module is an interface for a custom binary
   database used to store prefixes for chests ids
   that are used by cc
   
   Format:
   Byte 1:     name_id    (uint8)   PK
   Byte 2-3:   mod_id     (uint16)  FK
   Byte 4-n:   chest_name (packed string)
   
   Example:
   01  02  56 D1 40 E1 15 47 D6 C0
   id  id  [     chest_name      ]
   
   Notes:
    - IDs must be unique
    - IDs starts from 1
    - Name is assumed to only contain lowercase
      letters and underscores

   !!! REWORK THIS BECAUSE THE FORMAT IS NOT CONSISTANT !!!
]]--

local db_misc = require "database.db_misc"
local base_db = require "database.base_db"
base_db.db_path = "/databases/chests.db"

local chests_db = base_db:init()

--- Serialises chest data to be stored in database
--- @param data table: Dict containing chest data
--- @return string raw_data: Serialised data
function chests_db:_serialise(data)
   local id = db_misc.to_str(1, data.id)
   local m_id = db_misc.to_str(2, data.m_id)
   return id..m_id.."\0"..data.name.."\0"
end

--- Deserialises chest data to be used
--- @param raw_dat string: Serialised chest data
--- @return table data: Deserialised data in table
function chests_db:_deserialise(raw_dat)
   return {
      ["id"] = db_misc.to_num(raw_dat:sub(1, 1)),
      ["m_id"] = db_misc.to_num(raw_dat:sub(2,3)),
      ["name"] = db_misc.unpack_str(raw_dat:sub(4))
   }
end

--- Returns the start index and end index for where
--- the given chest is stored in the database
--- @param data table: Dict containing chest data
--- @return number|nil,number|nil: Nil if not found
function chests_db:_get_pos(data)
   local srt, fin
   if data.id then
      local id = db_misc.to_str(1, data.id)
      id = "\0"..db_misc.esc_char(id).."..\0"
      srt, fin = self.db:find(id.."(.-)\0")
   else
      local m_id = db_misc.to_str(2, data.m_id)
      m_id = "\0."..db_misc.esc_char(m_id).."\0"
      srt,fin = self.db:find(m_id..data.name.."\0")
   end
   return srt, fin
end


return chests_db