--                      item                     --
--    A storage system for CC:T and CC:R mods    --
--         Copyright (C) 2024 CitricCode         --

--[[
   This module houses a class for storing item data
   and other items relating to retrieving that data
]]--

local mod_module = require "storage.mod"

local item = {
   id = 0,
   num = 0,
   mod = "",
   name = ""
}

--- Initialises the item class based off argument.
--- If number, it will initialise with the item ID.
--- If string, it will initialise with "mod:name".
--- If table, it will initialise with the data.
--- @param arg number|string|table: Data to init
--- @return table|nil: Return class if success
function item:init(databases, arg)
   if not databases or not arg then return nil end
   local type = type(arg)
   if type=="number" then self:_id_init(arg) end
   if type=="string" then self:_name_init(arg) end
   if type=="table" then self:_data_init(arg) end
   local class = {}
   setmetatable(class, self)
   self.__index = self
end

function item:_id_init(databases, id)
   local item_db = databases.item_db
   
end

function item:_name_init(databases, name)
   
end

function item:_data_init(databases, data)
   
end


return item