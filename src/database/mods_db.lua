--                    mods_db                    --
--    A storage system for CC:T and CC:R mods    --
--         Copyright (C) 2024 CitricCode         --

local db_misc = require "database.db_misc"
local base_db = require "database.base_db"

--- @class mod_data
--- @field id number: UINT16 unique ID of the mod
--- @field name string: Name of the mod

--- This module is an interface that extends
--- base_db for a custom binary database used to
--- store mod names. This was created as a simple
--- compression by not repeating the same mod names
--- for each item and chests.
--- 
--- Format:  
--- Byte 1-2:   mod_id    (uint16)   PK  
--- Byte 4-n:   mod_name  (pkdStr)  
--- 
--- Example:  
--- 00 01  3D 70 1C B4 8D 16  
--- [ID ]  [     name      ]  
--- decodes to:  
--- {  
---    "id": 1,  
---    "name": "minecraft"  
--- }  
--- 
--- Notes:
---  - ID must be unique
---  - Assumes mod name must be unique and only
---    contain english lowercase alphabetical
---    characters and "_"
--- @class mods_db: base_db
local mods_db = { }

--- Initialises the mods_db class and loads the
--- database into memory.
--- @param path string: Path to the database file
--- @return mods_db: Returned instance of the class
function mods_db:init(o, path)
   o = base_db:init(o, path)
   setmetatable(o, self)
   return o
end


--- @protected
--- Serialises mod data to be stored in database
--- @param data mod_data: Dict containing mod data
--- @return string raw_data: Serialised data
function mods_db:_serialise(data)
   local id = db_misc.to_str(2, data.id)
   return id..db_misc.pack_str(data.name)
end

--- @protected
--- Deserialises mod data to be used
--- @param raw_dat string: Serialised mod data
--- @return mod_data data: Deserialised data table
function mods_db:_deserialise(raw_dat)
   return {
      ["id"] = db_misc.to_num(raw_dat:sub(1, 2)),
      ["name"] = db_misc.unpack_str(raw_dat:sub(3))
   }
end


--- @protected
--- Returns an iterator that iterates through the
--- mods database and returns the start and end
--- indicies for the offset the data is in the
--- database for the current iteration
--- @return function
function mods_db:_iterate()
   local srt, fin = 0, 0
   return function ()
      if fin == #self.db then return nil, nil end
      srt, fin = fin + 1, fin + 3
      while self.db:byte(fin)<128 do fin=fin+2 end
      fin = fin + 1
      return srt, fin
   end
end

--- @protected
--- Returns the start index and end index for where
--- the given mod is stored in the database
--- @param data mod_data: Dict containing mod data
--- @return number|nil,number|nil: Nil if not found
function mods_db:_get_pos(data)
   local srt, fin
   if data.id then
      local id = db_misc.to_str(2, data.id)
      id = db_misc.esc_char(id).."\0(.-)\0"
      srt, fin = self.db:find(id)
   else
      local name = "\0..\0"..data.name.."\0"
      srt, fin = self.db:find(name)
   end
   return srt, fin
end

--- Fills in `data` with any missing data from the
--- database. Data must contain either `data.id` or
--- `data.name`
--- @param data mod_data: Dict containing mod data
--- @return mod_data|nil: Complete data if success
function mods_db:get_data(data)
   return base_db.get_data(self, data)
end


--- Serialises and appends `data` to the database.
--- `data` must be complete and not already exist
--- in order to add to the database.
--- @param data mod_data: Dict of mod data
--- @return number|nil: 1 if success, nil if error
function mods_db:add(data)
   return base_db.add(self, data)
end

--- Removes a mod entry from the database. Data
--- must contain either `data.id` or `data.name`
--- @param data mod_data: Dict containing mod data
--- @return number|nil: 1 if success, nil if error
function mods_db:del(data)
   return base_db.del(self, data)
end


return mods_db