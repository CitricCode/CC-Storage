--- @author CitricCode
--- @license 
--- @todo DELETE EVERYTHING, THIS IS THE OLD CODE

local item_core = require "/storage/item_core"

-- ==================== Setting ==================== --

local item_db_path = "/storage/databases/items.db"
local recipe_db_path = "/storage/databases/recipes.db"
local chest_db_path = "/storage/databases/chests.db"
local log_file_path = "/storage/log.txt"

local io_chest = "minecraft:barrel_1"
local io_monitor = "monitor_0"


-- =================== Variables =================== --

local args = {...}

local recipe_db = {}
local chest_db = {}

local banned_peripherals = {
   ["bottom"] = 1,
   ["top"] = 1,
   ["left"] = 1,
   ["right"] = 1,
   ["front"] = 1,
   ["back"] = 1,
   [io_chest] = 1
}

local queued_jobs = {}


-- ==================== General ==================== --

--- Appends line to log file with stack info and time
--- @param msg string: message to add to the log file
local function log(msg)
   local epoch = os.epoch("utc")
   local time
   time = os.date("%d/%m/%y %H:%M:%S.", epoch / 1000)
   time = time..tostring(epoch % 1000)
   local file = fs.open(log_file_path, "a")
   file.write(time.." - "..msg.."\n")
   file.close()
end

--- Splits the input string similarly to python
--- @param str string: String to split
--- @param sep string: Seperator to split string
--- @return table substrings: table of the substrings
local function split(str, sep)
   local substrings = {}
   for i in string.gmatch(str, "([^"..sep.."]+)") do
      table.insert(substrings, i)
   end
   return substrings
end

-- =================== Databases =================== --
--                      General                      --

--- Reads database from path
--- @param path string: Path to the database
--- @return table data: table containing database data
local function open_db(path)
   local file = fs.open(path, "r")
   local data = file.readAll()
   data = textutils.unserialiseJSON(data)
   file.close()
   return data
end

--- Overwrites database with serialised data
--- @param path string: Path to the database
--- @param data any: Data to serialise to JSON
local function write_db(path, data)
   local file = fs.open(path, "w")
   local data = textutils.serialiseJSON(data)
   file.write(data)
   file.close()
end

--- Reads databases from file and assigns them to var
local function import_dbs()
   chest_db = open_db(chest_db_path)
end


--                  Chests database                  --
--    ["chestName"] = {[slot] = {itemID, counts}}    --

--- Adds chest to database
--- @param chest_name string: name of the chest
--- @param contents table: table of contents in chest
--- @return nil|string error: if chest already exists
local function add_chest(chest_name, contents)
   if chest_db[chest_name] then
      log("Add chest failed, already exists")
      return "Add chest failed, already exists"
   end
   if chest_name == io_chest then return end
   if banned_peripherals[chest_name] then return end
   chest_db[chest_name] = contents
end

--- Overwrites chest contents in database
--- @param chest_name string: name of the chest
--- @param contents table: table of contents in chest
--- @return nil|string error: if doesn't exist
local function upd_chest(chest_name, contents)
   if not chest_db[chest_name] then
      log("Upd chest failed, doesn't exist")
      return "Upd chest failed, doesn't exist"
   end
   if chest_name == io_chest then return end
   chest_db[chest_name] = contents
end

--- Called by sync_storage to normalise data and tally
--- @param counts table: Current tally of all items
--- @param raw_contents table: Result from chest.list()
--- @return table count,table contents: Modified data
local function sync_chest(counts, raw_contents)
   local contents = {}
   for slot, item in pairs(raw_contents) do
      local item_mod = split(item.name, ":")[1]
      local item_name = split(item.name, ":")[2]

      if not item_core.item_exist(item_mod, item_name) then
         local item_data = {
            ["mod"] = item_mod,
            ["name"] = item_name,
            ["count"] = item.count
         }
         print("adding "..item_mod..":"..item_name)
         item_core.append_item(item_data)
      end

      local item_id = item_core.find_item_id(item_mod, item_name)
      contents[slot] = {item_id, item.count}

      if not counts[item_id] then
         counts[item_id] = item.count
      else
         counts[item_id] = item.count + counts[item_id]
      end
   end
   return counts, contents
end

--- Updates contents of all chests in database and
--- automatically adds missing items or chests and
--- commits to databases
--- @return nil|string error: if any process fails
--- @todo make it return any errors
local function sync_storage()
   local counts = {}
   local chests = {peripheral.find("inventory")}

   for _, chest in pairs(chests) do
      local chest_name = peripheral.getName(chest)
      if not banned_peripherals[chest_name] then
         local contents = chest.list()
         counts, contents = sync_chest(counts,contents)
         if not chest_db[chest_name] then
            add_chest(chest_name, contents)
         else
            upd_chest(chest_name, contents)
         end
      end
   end

   local result, index = "", 1
   while result ~= "Could not be found" do
      local count = counts[index]
      if not count then
         result = item_core.update_item(index, 0)
      else
         result = item_core.update_item(index, count)
      end
      index = index + 1
   end

   write_db(chest_db_path, chest_db)
end

--- Searches chest contents for items given filters
--- @param contents table: table of contents in chest
--- @param filters table: table of filters
--- @return nil|table results: if item matches found
local function chest_search(contents, filters)
   local results = {}
   local is_results_empty = true

   for slot, item in pairs(contents) do
      local is_result = true
      local item_id = item[1]
      local item_data = item_core.get_item_data(item_id)

      if filters["filter_name"] and item_data["name"] ~= filters["filter_name"] then
         is_result = false
      end
      if filters["filter_mod"] and item_data["mod"] ~= filters["filter_mod"] then
         is_result = false
      end
      if filters["item_id"] and item_id ~= filters["item_id"] then
         is_result = false
      end

      if is_result == true then
         is_results_empty = false
         results[slot] = {item_id, item[2]}
      end
   end
   if is_results_empty then return nil end
   return results
end

-- filters = {["item_name"], ["item_id"], ["item_mod"],
--           ["categories"]={["category_name"]=1, etc},
--           ["chest_names"]={"name", "name", etc} }

--- Searches though all chests for items given filters
--- @param filters table: table of filters
--- @return nil|table results: if item matches found
local function storage_search(filters)
   local item_results = {}
   local chest_names = filters["chest_names"]
   filters["chest_names"] = nil

   if not chest_names then
      chest_names = {}
      for chest_name, _ in pairs(chest_db) do
         table.insert(chest_names, chest_name)
      end
   end
   for _, chest_name in pairs(chest_names) do
      local contents = chest_db[chest_name]
      local results = chest_search(contents, filters)
      item_results[chest_name] = results
   end
   return item_results
end


-- ==================== Storage ==================== --

--- Pulls items from storage into the io_chest
--- @param item_id integer: item to pull from storage
--- @param filters table: table of filters to restrict
--- @param count integer: count to pull from storage
--- @return integer|nil, nil|string error: if failed
local function req_item(item_id, filters, count)
   local io_pull = peripheral.wrap(io_chest).pullItems
   filters["item_id"] = item_id
   local item_results = storage_search(filters)

   if not item_results then
      return nil, "Could not find item in storage"
   end
   for chest_name, results in pairs(item_results) do
      for slot, _ in pairs(results) do
         if count == 0 then return 0, nil end
         local num_pulled = 0
         num_pulled = io_pull(chest_name, slot, count)
         local item_count = item_core.get_item_data(item_id)["count"]
         item_core.update_item(item_id, item_count - num_pulled)
         local slot_count = chest_db[chest_name][slot][2]
         slot_count = slot_count - num_pulled
         if slot_count == 0 then
            chest_db[chest_name][slot] = nil
         else
            chest_db[chest_name][slot] = slot_count
         end
         if num_pulled == 0 then return count, nil end
         count = count - num_pulled
      end
   end
end

--- Pushes items from io_chest into storage system
--- @return boolean success
local function put_item()
   local io_handle = peripheral.wrap(io_chest)
   local io_push = io_handle.pushItems
   local success = true

   for slot, item_data in pairs(io_handle.list()) do
      local split = split(item_data.name, ":")
      local item_mod = split[1]
      local item_name = split[2]
      if not item_core.item_exist(item_mod, item_name) then
         local item_data = {
            ["mod"] = item_mod,
            ["name"] = item_name,
            ["count"] = item_data.count
         }
         item_core.append_item(item_data)
      end

      local item_count = item_data.count
      for chest_name, _ in pairs(chest_db) do
         local num_push = io_push(chest_name, slot)
         item_count = item_count - num_push
         if item_count == 0 then break end
      end
      if item_count > 0 then success = false end
   end

   return success
end

local function tally_results(item_results)
   local totals = {}
   for _, contents in pairs(item_results) do
      for _, item in pairs(contents) do
         local item_name = item_core.get_item_data(item[1])["name"]
         local item_total = totals[item_name]
         if not item_total then
            item_total = item[2]
         else
            item_total = item_total + item[2]
         end
         totals[item_name] = item_total
      end
   end
   return totals
end

-- ================ User Interfaces ================ --

local function usr_inp_filt()
   write("Input item name: ")
   local item_name = read()
   if item_name == "" then item_name = nil end
   write("Input item mod: ")
   local item_mod = read()
   if item_mod == "" then item_mod = nil end
   local filters = {
      ["filter_mod"] = item_mod,
      ["filter_name"] = item_name
   }
   return filters
end

local function display_storage()
   write("Input page number: ")
   local page = read()
   if page == "" then page = 1 end

   local low_indx = 17 * (page - 1)
   local crt_indx = 1

   local item_results = storage_search(usr_inp_filt())
   if not item_results then
      print("No items found")
      return
   end
   local item_totals = tally_results(item_results)
   for item_name, total in pairs(item_totals) do
      if (low_indx + 18 > crt_indx) and (crt_indx > low_indx) then
         print(item_name.." "..total)
      end
      crt_indx = crt_indx + 1
   end
end

--- @todo not entering a number causes error
local function main()
   import_dbs()
   if args[1] == "-r" then
      local split = split(args[2], ":")
      local item_mod = split[1]
      local item_name = split[2]
      if not (item_mod or item_name) then
         print("Add the item name in the format 'mod:item' e.g. 'minecraft:stone'")
      end
      if not type(args[3]) == "number" then
         print("Not a number")
         return
      end
      local item_id = item_core.find_item_id(item_mod, item_name)
      if not item_id then
         print("Item not found")
         return
      end
      args[3] = math.floor(args[3])
      local err = req_item(item_id, {}, args[3])
      sync_storage()
      if err then print(err) return end

   elseif args[1] == "-s" then
      local success = put_item()
      if not success then
         print("Failed to store all items")
      end
	  sync_storage()
     
   elseif args[1] == "-u" then
      sync_storage()

   elseif args[1] == "-d" then
      display_storage()
   elseif args[1] == "-h" then
      print("-r [name] [amount] || Requests items from storage")
      print("-s || Stores contents of barrel into storage")
      print("-u || Updates database")
      print("-d || Displays items in storage given filters")
   end
   write_db(chest_db_path, chest_db)
end

local start_time = os.epoch("utc")
main()
local finish_time = os.epoch("utc")
print(finish_time - start_time)