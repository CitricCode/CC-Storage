--                    base_db                    --
--    A storage system for CC:T and CC:R mods    --
--         Copyright (C) 2024 CitricCode         --

--[[
   This module is a generic interface for custom
   binary databases used to store information about
   the storage system. This class is not ment to be
   used, but extended for each specific database.
   Any functions that are empty are required
   functions to be implimented by inherited classes
]]--


--- Generic class for a database interface. This
--- class is not ment to be used, but extended for
--- each specific database.
--- @class base_db
--- @field public db_path string: DB file location
--- @field protected db string: Database data
local base_db = {
   db_path = "",
   db = "",
}

--- Initialises the class
function base_db:init()
   local class = {}
   setmetatable(class, self)
   self.__index = self
   self:_read_db()
   return class
end

--- Serialises data to be stored in the database
--- @protected
--- @return string raw_data: Serialised data
--- @abstract
--- @diagnostic disable-next-line: missing-return
function base_db:_serialise(data) end

--- Deserialises data to be used in the program
--- @param raw_data string: Serialised data
--- @return table data: Deserialised data in table
--- @abstract
--- @diagnostic disable-next-line: missing-return
function base_db:_deserialise(raw_data) end


--- Reads the db and assigns its data to db
--- @protected
function base_db:_read_db()
   local file = fs.open(self.db_path, "rb")
   self.db = file.readAll()
   file.close()
end

--- Commits the db data and writes to the file
function base_db:write_db()
   local file = fs.open(self.db_path, "wb")
   file.write(self.db)
   file.close()
end

--- Creates an iterator that iterates through the
--- database
--- @protected
--- @return function: Iterator
--- @abstract
--- @diagnostic disable-next-line: missing-return
function base_db:_iterate() end

--- Returns the start index and end index for where
--- the given data is stored in the database
--- @protected
--- @return number|nil,number|nil: Nil if failed
--- @abstract
--- @diagnostic disable-next-line: missing-return
function base_db:_get_pos(data) end


--- Finds the next available ID
--- @protected
function base_db:_next_id()
   local idx = 1
   while pcall(self._get_pos,self,{id=idx}) do idx = idx+1 end
   return idx
end

--- Add the data to the end of the database
--- @param data table: Dictionary of data to append
function base_db:add(data)
   if self:_get_pos(data) then
      local data = textutils.serialise(data)
      error(data.."\n"..debug.traceback())
   end
   data.id = self:_next_id()
   
   self.db = self.db..self:_serialise(data)
end

--- Removes data from the database
--- @param data table: Dictionary of data to delete
function base_db:del(data)
   local srt, fin = self:_get_pos(data)
   if not srt then
      local data = textutils.serialise(data)
      error(data.."\n"..debug.traceback())
   end
   self.db = self.db:sub(1,srt)..self.db:sub(fin+1)
end

--- Finds the data from the database and returns it
--- @param data table: Dictionary of data to find
--- @return table: Filled dictionary of found data
function base_db:get_data(data)
   local srt, fin = self:_get_pos(data)
   if not srt then
      local data = textutils.serialise(data)
      error(data.."\n"..debug.traceback())
   end
   local raw_dat = self.db:sub(srt + 1, fin)
   return self:_deserialise(raw_dat)
end


return base_db