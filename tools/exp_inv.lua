--- Exports a storage system to json for testing

local out = {}

local chests = {peripheral.find("inventory")}
for _, chest in pairs(chests) do
   out[peripheral.getName(chest)] = chest.list()
end

local file = fs.open("storage.json", "w")
local data = textutils.serialiseJSON(out)
file.write(data)
file.close()