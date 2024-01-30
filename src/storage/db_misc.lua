-- ================== db_misc ================== --
-- This module houses common functions used in the
-- other database modules

local db_misc = {}

db_misc.db_path = "/storage/databases/"

--- Converts lua number to 3 byte string
--- @param int number: Number to convert
--- @return string|nil, nil|string: if failed
function db_misc.num_to_uint24(int)
   if int < 0 or int > 16777215 then
      return nil, "Number out of uint24 range"
   end
   if int % 1 ~= 0 then
      return nil, "Number is not an int"
   end

   local byte_H = bit32.rshift(int, 16)
   local byte_M = bit32.rshift(int,  8)
   byte_M = bit32.band(byte_M, 0xff)
   local byte_L = bit32.band(int, 0xff)
   return string.char(byte_H, byte_M, byte_L)
end

--- Converts 3 byte string to lua number
--- @param bytes string: String to convert
--- @return number|nil, nil|string: if failed
function db_misc.uint24_to_num(bytes)
   if string.len(bytes) > 3 then
      return nil, "String is larger than 3 bytes"
   end

   local byte_H = string.byte(bytes, 1)
   byte_H = bit32.lshift(byte_H, 16)
   local byte_M = string.byte(bytes, 2)
   byte_M = bit32.lshift(byte_M,  8)
   local byte_L = string.byte(bytes, 3)
   return byte_H + byte_M + byte_L
end

--- Converts lua number to 2 byte string
--- @param int number: Number to convert
--- @return string|nil, nil|string: if failed
function db_misc.num_to_uint16(int)
   if int < 0 or int > 65535 then
      return nil, "Number is out of uint16 range"
   end
   if int % 1 ~= 0 then
      return nil, "Number is not an int"
   end

   local byte_H = bit32.rshift(int, 8)
   local byte_L = bit32.band(int, 0xff)
   return string.char(byte_H, byte_L)
end

--- Converts 2 byte string to lua number
--- @param bytes string: String to convert
--- @return number|nil, nil|string
function db_misc.uint16_to_num(bytes)
   if string.len(bytes) > 2 then
      return nil, "String is larger than 2 bytes"
   end

   local byte_H = string.byte(bytes, 1)
   byte_H = bit32.lshift(byte_H, 8)
   local byte_L = string.byte(bytes, 2)
   return byte_H + byte_L
end

--- Converts lua number to 1 byte string
--- @param int number: Number to convert
--- @return string|nil, nil|string: if failed
function db_misc.num_to_uint8(int)
   if int < 0 or int > 255 then
      return nil, "Number is out of uint8 range"
   end
   if int % 1 ~= 0 then
      return nil, "Number is not an int"
   end

   return string.char(int)
end

--- Converts 1 byte string to lua number
--- @param bytes string: String to convert
--- @return number|nil, nil|string: if failed
function db_misc.uint8_to_num(bytes)
   if string.len(bytes) > 1 then
      return nil, "String is larger than 1 byte"
   end

   return tonumber(bytes)
end


--- Adds escape chars to lua's magic characters
--- for example given ")." the result is "%)%."
--- @param string string: String to escape chars
--- @return string: Escaped string
function db_misc.escape_chars(string)
   string = string:gsub("%(", "%%%(")
   string = string:gsub("%%", "%%%%")
   string = string:gsub("%)", "%%%)")
   string = string:gsub("%.", "%%%.")
   string = string:gsub("%+", "%%%+")
   string = string:gsub("%-", "%%%-")
   string = string:gsub("%*", "%%%*")
   string = string:gsub("%?", "%%%?")
   string = string:gsub("%[", "%%%[")
   string = string:gsub("%]", "%%%]")
   string = string:gsub("%^", "%%%^")
   string = string:gsub("%$", "%%%$")
   return string
end

--- Reads entire database file and returns data
--- @param path string: Path to database
--- @return string: Database contents
function db_misc.read_database(path)
   local database_file = fs.open(path, "rb")
   local data = database_file.readAll()
   database_file.close()
   return data
end

--- Overwrites database file with data
--- @param path string: Path to database
--- @param data any: Data to override with
function db_misc.write_database(path, data)
   local database_file = fs.open(path, "wb")
   database_file.write(data)
   database_file.close()
end

return db_misc