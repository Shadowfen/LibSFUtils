-- This is always the first source file loaded so that
-- it can create the addon table/namespace.

LibSFUtils = {
    name = "LibSFUtils",
    LibVersion = 54,    -- change this with every release!
    author = "Shadowfen",
}
--[[
An implementation of a logger which uses the lua print function
to output the messages.
--]]
-- [ [
local printLibDebug = {
    Error = function(self,...)  print("ERROR: "..string.format(...)) end,
    Warn = function(self,...)  print("WARN: "..string.format(...)) end,
    Info = function(self,...)  print("INFO: "..string.format(...)) end,
    Debug = function(self,...)  print("DEBUG: "..string.format(...)) end,
}
setmetatable(printLibDebug,  { __call = function(self, name) 
            self.addonName = name 
            return self
        end
    })

if LibDebugLogger then
  LibSFUtils.logger = LibDebugLogger:Create("SFUtils")
  LibSFUtils.logger:SetEnabled(true)
else
  LibSFUtils.logger = printLibDebug("SFUtils")
end
-- ] ]
