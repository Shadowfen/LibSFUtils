local sfutil = LibSFUtils or {}

-- logger that prints to chat
local activePrintDebug = {
    Error = function(self,...)
            if not self.enabled then return end
            print("["..self.addonName.."] ERROR: "..string.format(...)) 
        end,
    Warn = function(self,...)
        if not self.enabled then return end
        print("["..self.addonName.."] WARN: "..string.format(...)) 
        end,
    Info = function(self,...)
        if not self.enabled then return end
        print("["..self.addonName.."] INFO: "..string.format(...)) 
        end,
    Debug = function(self,...)
        if not self.enabled then return end
        print("["..self.addonName.."] DEBUG: "..string.format(...)) 
        end,
    Create = function(self,name)
            local o = setmetatable({}, { __index = self})
            o.addonName = name
            return o
            end,
    SetEnabled=function(self,truefalse) self.enabled = truefalse end,
}

-- logger that does not print to anywhere
local nilPrintDebug = {
    Error = function(self,...) end,
    Warn = function(self,...) end,
    Info = function(self,...) end,
    Debug = function(self,...) end,
    Create = function(self,name)
            local o = setmetatable({}, { __index = self})
            o.addonName = name
            return o
            end,
    SetEnabled=function(self,truefalse) self.enabled = truefalse end,
}

-- logger that prints to chat when enabled
local printDebug = {
    Error = function(self,...)  
        if not self.enabled then return end
        print("["..self.addonName.."] ERROR: "..string.format(...)) 
        end,

    Warn = function(self,...)  
        if not self.enabled then return end
        print("["..self.addonName.."] WARN: "..string.format(...)) 
        end,

    Info = function(self,...) 
        if not self.enabled then return end
        print("["..self.addonName.."] INFO: "..string.format(...)) 
        end,

    Debug = function(self,...)
        if not self.enabled then return end
        print("["..self.addonName.."] DEBUG: "..string.format(...)) 
        end,

    Create = function(self,name)
            local o = setmetatable({}, { __index = self})
            o.addonName = name
            return o
            end,

    SetEnabled=function(self,tf)
            if  not self then return end
            if  self.enabled == tf then return end
            self.enabled = tf
            if tf == true then
                self.Error = activePrintDebug.Error
                self.Warn =  activePrintDebug.Warn
                self.Info =  activePrintDebug.Info
                self.Debug = activePrintDebug.Debug

            else
                self.Error = nilPrintDebug.Error
                self.Warn =  nilPrintDebug.Warn
                self.Info =  nilPrintDebug.Info
                self.Debug = nilPrintDebug.Debug
            end
        end,
}


-- create an instance of a logger (with LibDebugLogger if available, otherwise just print)
-- by default the logger is set to be not enabled (i.e. output nothing). You can use :SetEnabled() to turn on output
function sfutil.Createlogger(addonName)
    -- initialize the logger for an addon
    local logger = nil
    if LibDebugLogger then
        logger = LibDebugLogger:Create(addonName)
        logger.sfdb = "with LibDebugLogger"
    end
    if not LibDebugLogger then
        logger = printDebug:Create(addonName)
        logger.sfdb = "with printDebug"
    end
    return logger
end
