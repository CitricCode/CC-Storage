--- Initialises CraftOS with populated peripherals

local file = fs.open("/tools/storage.json", "r")
local data = file.readAll()
data = textutils.unserialiseJSON(data)
file.close()

periphemu.create("back", "modem")
for name, chest in pairs(data) do
   _ = periphemu.create(name, "chest", true)
   local chest_ref = peripheral.wrap(name)
   for slot, item in ipairs(chest) do
      local num = chest_ref.setItem(slot, item)
   end
end