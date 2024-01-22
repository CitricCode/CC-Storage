-- =================== misc ==================== --
-- This module houses varius functions for common
-- purposes

local misc = {}

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
--- @return table substrings: table of the splits
function misc.split(str, sep)
   local substrings = {}
   for i in string.gmatch(str,"([^"..sep.."]+)") do
      table.insert(substrings, i)
   end
   return substrings
end

return misc
