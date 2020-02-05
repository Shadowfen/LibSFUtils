-- LibSFUtils is already defined in prior loaded file

LibSFUtils = LibSFUtils or {}


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
    local mt = getmetatable (o)
    mt.__index = self
    
    o.addonName = addonName
    o.enabled = true
    if not logger then
        o.logger = nilLibDebug
    end
    
    return o
end

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

function VC:Disable()
    self.enabled = false
end

LibSFUtils.addonlist = { count=0 }
local function loadAddonList()
    local addonlist = LibSFUtils.addonlist
    if addonlist.count > 0 then return end
    
    local AddOnManager = GetAddOnManager()
    for i = 1, AddOnManager:GetNumAddOns() do
        local name, title, author, description, enabled, state, isOutOfDate, isLibrary = AddOnManager:GetAddOnInfo(i)
        addonlist[name] = { index=i, enabled=enabled, state=state, isOutOfDate=isOutOfDate, isLibrary=isLibrary }
        addonlist.count=addonlist.count+1
        local version = AddOnManager.GetAddOnVersion and AddOnManager:GetAddOnVersion(i) or 0
        addonlist[name].version = version
    end
end

function LibSFUtils.GetAddonIndex(libname)
    if LibSFUtils.addonlist.count == 0 then
        loadAddonList()
    end
    if LibSFUtils.addonlist[libname] then
        return LibSFUtils.addonlist[libname].index
    end
    return -1
end

function LibSFUtils.GetAddonVersion(name)
    if LibSFUtils.addonlist.count == 0 then
        loadAddonList()
    end
    if LibSFUtils.addonlist[name] then
        return LibSFUtils.addonlist[name].version
    end
    return -1
end

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

function VC:NoVersion(libname)
    if not self.enabled then return end
    self.logger:Info("Library \"%s\" does not provide version information", libname)
end

LibSFUtils.VersionChecker = VC