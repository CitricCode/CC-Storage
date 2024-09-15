--                    base_db                    --
--    A storage system for CC:T and CC:R mods    --
--         Copyright (C) 2024 CitricCode         --

--- This module is a generic interface for custom
--- binary databases used to store information
--- about the storage system. This class is not
--- ment to be used, but extended for each specific
--- database. Any functions that have @abstract are
--- required functions to be implimented by
--- inherited classes.
--- @class base_db
--- @field protected _db_path string: DB file loc
--- @field protected _db_data string: DB stored dat
local base_db = {}
base_db.__index = base_db


--- Initialises the base class; This should only
--- be run from inherited classes
--- @param path string: Path to the database file
--- @return base_db: Returned instance of the class
function base_db:init(o, path)
   o = o or {}
   setmetatable(o, self)
   self._db_path = path
   self._db_data = ""
   self:_read_db()
   return o
end


--- @protected
--- Reads the entire database file and assigns it
--- into the `_db_data` field. Only called when
--- initialising the class. Will create the
--- database if the file does not exist.
function base_db:_read_db()
   if not fs.exists(self._db_path) then
      -- !!! Add logger log here for creating database file !!! --
      local file = fs.open(self._db_path, "w")
      file.write("CC-SS")
      file.close()
   end
   local file = fs.open(self._db_path, "rb")
   self._db_data = file.readAll()
   file.close()
end

--- Writes `_db_data` to the file to commit to disk
function base_db:write_db()
   local file = fs.open(self._db_path, "wb")
   file.write(self._db_data)
   file.close()
end


--- @protected
--- @abstract  
--- Serialises the data to be written to the db
--- @param data table: Data to serialise
--- @return string|nil raw_data: Raw dat if success
function base_db:_serialise(data) end

--- @protected
--- @abstract  
--- Deserialises the data to be used in the program
--- @param raw_data string: Data to deserialise
--- @return table|nil: Table of data if success
function base_db:_deserialise(raw_data) end


--- @protected
--- @abstract  
--- Returns an iterator that iterates through the
--- database and returns the start and end indicies
--- for the current iteration
--- @return function: Iterator function
function base_db:_iterate() end

--- @protected
--- @abstract  
--- Returns the start and end index for where the
--- given data is stored in the database. If 0, 0
--- is returned, then it was not found.
--- @param data table: Data to find in the database
--- @return number|nil: Start index or nil if err
--- @return number|nil: End index or nil if err
function base_db:_get_pos(data) end

--- Fills in missing data from the databases
--- @param data table: Data to find in the database
--- @return table|nil: Table full of complete data
function base_db:get_data(data)
   local srt, fin = self:_get_pos(data)
   -- !!! Add logger log here for failure to find data !!! --
   if not srt then return nil end
   local raw_data = self._db_data:sub(srt, fin)
   return self:_deserialise(raw_data)
end

--- @protected
--- Finds the next available unique ID in the db
--- @return integer|nil: Unique ID if success
function base_db:_next_id()
   local id = 1
   while true do
      local ret, _ = self:_get_pos({id=id})
      if ret == 0 then return id end
      -- !!! Add logger log here for no more available IDS/Incorrect parsing !!! --
      if ret == nil then return nil end
      id = id + 1
   end
end


--- Serialises and appends `data` to the database.
--- `data` must be complete and not already exist
--- in order to add to the database.
--- @param data table: Data to append to the db
--- @return number|nil: 1 if success, nil if error
function base_db:add(data)
   -- !!! Add logger log here for no more available IDS/Incorrect parsing !!! --
   if self:_get_pos(data) then return nil end
   data.id = self:_next_id()
   if not data.id then return nil end
   local raw_data = self:_serialise(data)
   self._db_data=self._db_data..raw_data
   return 1
end

--- Removes the given data from the databases
--- @param data table: Data to remove from the db
--- @return number|nil: 1 if success, nil if fail
function base_db:del(data)
   local srt, fin = self:_get_pos(data)
   -- !!! Add logger log here for delete failed due to not existing in db !!! --
   if not srt then return nil end
   self.db = self.db:sub(1,srt)..self.db:sub(fin+1)
   return 1
end


return base_db