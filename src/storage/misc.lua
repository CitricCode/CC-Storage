-- =================== misc.lua ==================== --
local misc = {}

--- Converts lua number to 3 byte string
--- @param int number: Number to convert
--- @return string|nil, nil|string: if failed
function misc.num_to_uint24(int)
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
function misc.uint24_to_num(bytes)
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
function misc.num_to_uint16(int)
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
function misc.uint16_to_num(bytes)
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
function misc.num_to_uint8(int)
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
function misc.uint8_to_num(bytes)
   if string.len(bytes) > 1 then
      return nil, "String is larger than 1 byte"
   end

   return tonumber(bytes)
end


--- Appends time and message to log file
--- @param path string: Path to log file
--- @param msg string: String to split
function misc.log(path, msg)
   local epoch = os.epoch("utc")
   local time = os.date("%H:%M:%S.", epoch / 1000)
   time = time..tostring(epoch % 1000)
   local file = fs.open(path, "a")
   file.write(time.." - "..msg.."\n")
   file.close()
end

--- Splits input string similarly to python
--- @param str string: String to split
--- @param sep string: Seperator to split string
--- @return table substrings: table of the substrings
function misc.split(str, sep)
   local substrings = {}
   for i in string.gmatch(str, "([^"..sep.."]+)") do
      table.insert(substrings, i)
   end
   return substrings
end

--- Finds start and end indexies for all occurences of
--- substr in str
--- @param str string: String to search through
--- @param substr string: Substring to find occurences
function misc.find_all_occurences(str, substr)
   local occurences = {}
   local first, last
   while true do
      first, last = string.find(substr, first + 1)
      if not first then break end
      table.insert(occurences, {first, last})
   end
   return occurences
end

return misc
