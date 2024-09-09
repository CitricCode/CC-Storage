--- Imports database from json

local item_db = (require "database.item_db"):init()
local mods_db = (require "database.mods_db"):init()

local file = fs.open("/tools/storage.json", "r")
local data = textutils.unserialiseJSON(file.readAll())
file.close()

local counts = {}

for _, stores in pairs(data) do
   for _, item in pairs(stores) do
      local name = item["name"]
      if not counts[name] then
         counts[name]=item["count"]
      else
         counts[name]=counts[name]+item["count"]
      end
   end
end

local added_mods = {}

for name, item_count in pairs(counts) do
   local _, idx = name:find(":")
   local mod_name = name:sub(1,idx-1)
   local item_name = name:sub(idx+1)
   local mod_data = {name=mod_name}
   if not added_mods[mod_name] then
      -- print("adding:", mod_name)
      -- mods_db:add(mod_data)
      io.write(mod_name..", ")
      added_mods[mod_name] = 1
   end
   -- mod_data = mods_db:get_data(mod_data)
   -- local item_data = {
   --    num=item_count,
   --    m_id=mod_data.id,
   --    name=item_name,
   -- }
   -- item_db:add(item_data)
end
