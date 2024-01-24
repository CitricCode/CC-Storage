-- ================ chests_core ================ --
--[[
   This module is an interface for a custom binary
   database used to store chests in the network and
   the contents within them

   Current format is in json, but it will be
   reworked to a binary database
]]--

local db_misc = require "/storage/db_misc"

local chest_core = {}

local chest_path = db_misc.db_path.."chests.db"


return chest_core