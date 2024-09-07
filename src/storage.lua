--                    storage                    --
--    A storage system for CC:T and CC:R mods    --
--         Copyright (C) 2024 CitricCode         --

--[[
   The main program to be run. This is a proof of
   concept and is for testing and thus will be
   subject to regular changes.
]]--

-- local mod_db_module = require "storage.mods_db"
-- local item_db_module = require "storage.item_db"
-- local chest_db_module = require "storage.chests_db"
-- local store_db_module = require "storage.stores_db"

-- local mod_db = mod_db_module:init()
-- local item_db = item_db_module:init()
-- local chest_db = chest_db_module:init()
-- local store_db = store_db_module:init()

local args = {...}

local io_chest = "minecraft:barrel_1"
local ban_per = {
   ["bottom"] = 1,
   ["top"] = 1,
   ["left"] = 1,
   ["right"] = 1,
   ["front"] = 1,
   ["back"] = 1,
   [io_chest] = 1
}

local queued_jobs = {}


local function sync_chest()
   
end

local function sync_stores()
   local counts = {}
   local chests = {peripheral.find("inventory")}
   for _, chest in pairs(chests) do
      local r_name = peripheral.getName(chest)
      local srt, _ = r_name:find(":")
      local fin, _ = r_name:find("_[^_]+$")
      -- mod_db.data = {["name"]=r_name:sub(0, srt-1)}
      -- local ches={["name"]=r_name:sub(srt+1,fin-1)}
      -- local c_id = tonumber(r_name:sub(fin+1))
      -- mod_db:get_data
   end
end

sync_stores()