--                    db_misc                    --
--    A storage system for CC:T and CC:R mods    --
--         Copyright (C) 2024 CitricCode         --

--[[
   This module houses common functions used in
   other database modules
]]--

local db_misc = {}


--- Converts lua number to string to a given length
--- into a byte array in little endian order.
--- @param len number: Count of bytes to convert to
--- @param int number: Number to convert
--- @return string|nil: Returns nil if failed
function db_misc.to_str(len, int)
   if len < 0 or len % 1 ~= 0 then return nil end
   local max_num = (2 ^ (len * 8)) - 1
   if int < 0 or int > max_num then return nil end
   if int % 1 ~= 0 then return nil end
   -- print("passed")
   local str = ""
   for i = 0, len-1 do
      local char = bit32.rshift(int, i*8)
      str = str..string.char(bit32.band(char,0xff))
   end
   return str
end

--- Converts byte array into a number. Assumes
--- the byte array is in little endian order.
--- @param str string: Byte array to convert
--- @return number: Converted number
function db_misc.to_num(str)
   local num = 0
   for i = 0, #str-1 do
      num = num + bit32.lshift(str:byte(i+1), i*8)
   end
   return num
end


--- Custom string compression to further reduce db
--- filesize. This code only accepts a string with
--- lowercase letters and underscores, however it
--- has room for 3 more characters in the future.
--- One packet takes 2 bytes and starts with a
--- terminator flag as the first bit, and proceeds
--- with three 5bit characters.
--- @param str string: String to compress
--- @return string|nil: Nil if invalid characters
function db_misc.pack_str(str)
   str = str..("^"):rep((3 - #str % 3) % 3)
   local chnk, pkd_str = 0, ""
   for i=1, #str do
      local char = str:byte(i) - 94
      if 0 > char or char > 123 or char == 2 then
         return nil
      end
      chnk = bit32.lshift(chnk, 5) + char
      if i % 3 == 0 or i == #str then
         if i == #str then chnk = chnk + 0x8000 end
         local ubyte, lbyte = "", ""
         ubyte=string.char(bit32.rshift(chnk, 8))
         lbyte = string.char(bit32.band(chnk,0xff))
         pkd_str = pkd_str..ubyte..lbyte
         chnk = 0
      end
   end
   return pkd_str
end

--- Reverses a custom string compression algorithm
--- to convert it back to the original string.
--- @param pkd_str string: Byte array to decompress
--- @return string|nil: Nil if pkd_str is invalid
function db_misc.unpack_str(pkd_str)
   if #pkd_str % 2 ~= 0 then return nil end
   local chnk, str = 0, ""
   for i=1, #pkd_str, 2 do
      chnk = bit32.lshift(pkd_str:byte(i), 8)
      chnk = chnk + pkd_str:byte(i+1)
      for j=2, 0, -1 do
         local char
         char=bit32.band(bit32.rshift(chnk,j*5),31)
         if char == 0 then break end
         str = str..string.char(char + 94)
      end
   end
   return str
end

--- Adds escape chars to lua's magic characters
--- for example given ")." the result is "%)%."
--- @param string string: String to escape chars
--- @return string: Escaped string
function db_misc.esc_char(string)
   local esc_chars = "%()[]^*+-.$?"
   for i = 1, #esc_chars do
      local char = esc_chars:sub(i, i)
      string = string:gsub("%"..char, "%%%"..char)
   end
   return string
end

return db_misc