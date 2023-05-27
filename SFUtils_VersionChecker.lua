-- LibSFUtils is already defined in prior loaded file

LibSFUtils = LibSFUtils or {}


--[[
An implementation of a logger which does nothing.
--]]
local nilLibDebug = {
    Error = function(self,...)  end,
    Warn = function(self,...)  end,
    Info = function(self,...)  end,
    Debug = function(self,...)  end,
}
setmetatable(nilLibDebug, { __call = function(self, name) 
            self.addonName = name 
            return self
        end
    })

--[[
An implementation of a logger which uses the lua print function
to output the messages.
--]]
local printLibDebug = {
    Error = function(self,...)  print("ERROR: "..string.format(...)) end,
    Warn = function(self,...)  print("WARN: "..string.format(...)) end,
    Info = function(self,...)  print("INFO: "..string.format(...)) end,
    Debug = function(self,...)  print("DEBUG: "..string.format(...)) end,
}
setmetatable(printLibDebug, getmetatable(nilLibDebug))

-- -----------------------------------------------------------------------
-- Object for checking minimum version of libraries is met.
-- Use of this requires a logger such as the LibDebugLogger addon,
-- or you can write your own that implements <logger>:Error(), <logger>:Warn(),
-- and <logger>:Info().
--
local VC = {}

setmetatable(VC, { __call = function(self, name, plogger) return VC:New(name) end 
    })

function VC:New(addonName)
	o = {} 
	setmetatable(o, self)
	self.__index = self
    local mt = getmetatable(o)
    mt.__index = self
    
    o.addonName = addonName
    o.enabled = true
    if not logger then
        o.logger = nilLibDebug
    end
    
    return o
end

--[[
Add a logger to the VersionChecker instance and enable logging.
(If a logger is not specified, then default to the printLibDebug logger.)

Note: The LibDebugLogger is a drop-in replacement for the other loggers we define here.
    We simply require an object that implements Error, Warn, Info, and Debug object methods
	for us to use as a logger.
--]]
function VC:Enable(plogger)
    self.enabled = true
    if not plogger then
        if self.logger == nilLibDebug then
            self.logger = printLibDebug
        end
    else
        self.logger = plogger
    end
end

--[[
Disable logging in the VersionChecker instance
--]]
function VC:Disable()
    self.enabled = false
end

--[[
*local function
Load in information about all loaded addons to a table indexed by addon Name.
The table also has a "count" entry containing the number of all of the addons in the table.

The table is Global to the game; so once it is loaded it is available for any addon to use.
--]]
LibSFUtils.addonlist = { count=0 }
local function loadAddonList()
    local addonlist = LibSFUtils.addonlist
    --if addonlist.count > 0 then return end
    
    local AddOnManager = GetAddOnManager()
	local currAddons = AddOnManager:GetNumAddOns()
	if addonlist.count >= currAddons then return end
    for i = 1, currAddons do
        local name, title, author, description, enabled, state, 
					isOutOfDate, isLibrary = AddOnManager:GetAddOnInfo(i)
		if addonlist[name] == nil then
			addonlist[name] = { 
				index=i, 
				enabled=enabled, 
				state=state, 
				isOutOfDate=isOutOfDate, 
				isLibrary=isLibrary 
			}
			addonlist.count=addonlist.count+1
			local version = AddOnManager.GetAddOnVersion 
							and AddOnManager:GetAddOnVersion(i) or 0
			addonlist[name].version = version
		end
    end
end

--[[
Force load in information about all loaded addons to a table indexed by addon Name.
Previous information that might have been in the addon table will be discarded.

The table also has a "count" entry containing the number of all of the addons in the table.

The table is Global to the game; so once it is loaded it is available for any addon to use.

Note: This is a LibSFUtils function - not a VersionChecker one.
--]]
function LibSFUtils.ForceUpdateAddons()
    local addonlist = { count=0 }
    local AddOnManager = GetAddOnManager()
	local currAddons = AddOnManager:GetNumAddOns()
    for i = 1, currAddons do
        local name, title, author, description, enabled, state, 
				isOutOfDate, isLibrary = AddOnManager:GetAddOnInfo(i)
        addonlist[name] = { 
			index=i, 
			enabled=enabled, 
			state=state, 
			isOutOfDate=isOutOfDate, 
			isLibrary=isLibrary 
		}
        addonlist.count=addonlist.count+1
        local version = AddOnManager.GetAddOnVersion 
			and AddOnManager:GetAddOnVersion(i) or 0
        addonlist[name].version = version
    end
	LibSFUtils.addonlist = addonlist
end

--[[
Get all the information about an addon from the name.
Returns the following fields: name, title, author, description, 
    enabled, state, isOutOfDate, isLibrary
or 
    nil if addon is not found. 
This does another api call since not all the information is cached.
--]]
function LibSFUtils.GetAddonInfo(libname)
    if LibSFUtils.addonlist.count == 0 then
        loadAddonList()
    end
    local AddOnManager = GetAddOnManager()
    if LibSFUtils.addonlist[libname] then
		local indx = LibSFUtils.addonlist[libname].index
		if indx then
			return LibSFUtils.addonlist[libname]
			--return AddOnManager:GetAddOnInfo(indx)
		else
			return
		end
	end
    return
end

--[[
Get the index of an addon from the name.
--]]
function LibSFUtils.GetAddonIndex(libname)
    if LibSFUtils.addonlist.count == 0 then
        loadAddonList()
    end
    if LibSFUtils.addonlist[libname] then
        return LibSFUtils.addonlist[libname].index
    end
    return -1
end

--[[
Get the version of an addon from the name.
--]]
function LibSFUtils.GetAddonVersion(name)
    if LibSFUtils.addonlist.count == 0 then
        loadAddonList()
    end
    if LibSFUtils.addonlist[name] then
        return LibSFUtils.addonlist[name].version
    end
    return -1
end

--[[
Check the internal addon table for the addon named and compare the
loaded version to the expected one.
This requires a logger being specified for the VersionChecker instance.
It also depends on LibSFUtils functions.

Note: This is a VersionChecker function.
--]]
function VC:CheckVersion(libname, expectedVersion)
    if not self.enabled then return end
    if not libname then return end
    if not expectedVersion then expectedVersion = 9999999 end
    
    local logger = self.logger
    local version = LibSFUtils.GetAddonVersion(libname)
    if version < 0 then
        logger:Warn("Missing required Library \"%s\" ", libname)
        return
    end
    if version == 0 then
        logger:Warn("Library \"%s\" does not provide version information", libname)
        return
    end
    if version < expectedVersion then
        logger:Error("Outdated version of \"%s\" detected (%d) - expected version %d - possibly embedded in another older addon.", libname, version or -1, expectedVersion) 
    end
end

--[[
Write a message to the logger that the named addon does not provide version information.
--]]
function VC:NoVersion(libname)
    if not self.enabled then return end
    self.logger:Info("Library \"%s\" does not provide version information", libname)
end

LibSFUtils.VersionChecker = VC