--                    db_misc                    --
--    A storage system for CC:T and CC:R mods    --
--         Copyright (C) 2024 CitricCode         --

--[[
   This module houses common functions used in
   other database modules
]]--
--- @module "types"

local db_misc = {}

--- Converts lua number to string to a given length
--- into a byte array in little endian order.
--- @param len number: Count of bytes to convert to
--- @param int uint: Number to convert
--- @return string|nil: Returns nil if failed
function db_misc.to_str(len, int)
   if len < 0 or len % 1 ~= 0 then return nil end
   local max_num = (2 ^ (len * 8)) - 1
   if int < 0 or int > max_num then return nil end
   if int % 1 ~= 0 then return nil end
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
--- @return uint: Converted number
function db_misc.to_num(str)
   local num = 0
   for i = 0, #str-1 do
      num = num + bit32.lshift(str:byte(i+1), i*8)
   end
   return num
end

--- test = require "database.db_misc"

--- Compresses a string. Inputs only lowercase
--- letters and the only other character is an "_"
function db_misc.pack_str(str)
   str = str..("^"):rep(math.ceil(#str/3)*3 - #str)
   local chnk, pkd_str = 0, ""
   for i=1, #str do
      local char = str:byte(i) - 94
      if 0 > char or char > 123 or char == 2 then
         return nil
      end
      chnk = bit32.lshift(chnk, 5) + char
      if i-math.floor(i/3)*3==0 then
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

function db_misc.unpack_str(pkd_str)
   
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