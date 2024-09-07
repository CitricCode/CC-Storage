--                     types                     --
--    A storage system for CC:T and CC:R mods    --
--         Copyright (C) 2024 CitricCode         --

--[[
   This module is just for defining common types
   used for documentation. This does not have any
   lua code just global annotations that I don't
   want to repeat in every file.

   The uint8/16/24 arent classes but aliases for
   numbers. They are defined as classes to show 
   the type in my IDE as using aliases just made
   them show up as "number" instead of "uint8"
]]--

--- @class uint8 Unsigned 8-bit integer
--- @class uint16 Unsigned 16-bit integer
--- @class uint24 Unsigned 24-bit integer
--- @alias uint uint8|uint16|uint24