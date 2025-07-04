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

-- Returns a function to return a logger object (creating it if necessary first).
-- If a logger gets created, it will be enabled by default.
--[[
    namespace = the table that you want the logger object stored into. If this
        is not a table, we assume it is the name of the table that is found in _G.
        If it is a string, it will be used for the addonname parameter and the name of the
        table to find (or create) in _G.
    loggervar =  the name of the logger instance to use.
    addonname =  the name of the addon this logger object is associated with.

    The function returned by this function runs quicker than sfutil.SafeLogger() because
    the preliminary checking is done only before the function is created - not every time it runs.
--]]
function sfutil.SafeLoggerFunction(namespace, loggervar, addonname)

    if type(namespace) ~= "table" then
        addonname = namespace
        namespace = _G[addonname]
        if not namespace then
            _G[addonname] = {}
            namespace = _G[addonname]
        end
    end

    return function()
        if not namespace[loggervar] then
            local mylogger
            mylogger = sfutil.Createlogger(addonname)
            mylogger:SetEnabled(true)
            mylogger:SetDebug(false)
            namespace[loggervar] = mylogger
        end
        return namespace[loggervar]
    end
end

-- Returns a logger object (creating it if necessary first)
--[[
    Recommend that you create a specific logger function using sfutils.SafeLoggerFunction()
    instead of using this function.
--]]
function sfutil.SafeLogger(namespace, loggervar, addonname)
    if type(namespace) ~= "table" then
        addonname = namespace
        namespace = _G[addonname]
        if not namespace then
            _G[addonname] = {}
            namespace = _G[addonname]
        end
    end

    local mylogger
    if not namespace[loggervar] then
        mylogger = sfutil.Createlogger(addonname)
        mylogger:SetEnabled(true)
    end
    namespace[loggervar] = mylogger
    return mylogger
end

-- create an instance of a logger (with LibDebugLogger if available, otherwise just print)
-- by default the logger is set to be not enabled (i.e. output nothing).
-- You can use :SetEnabled() to turn on output.
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

    logger.origDebug = logger.Debug
    logger.SetDebug=function(self,truefalse)
        logger.enableDebug = truefalse 
        if logger.enableDebug == false then
            logger.Debug = nilPrintDebug.Debug
        else
            logger.Debug = logger.origDebug
        end
    end
    logger:SetDebug(false)

    return logger
end

-- create an instance of a nil logger
-- This logger will never output anything (useful for turning off debugging)
function sfutil.CreateNilLogger(addonName)
    -- initialize the logger for an addon
    local logger = nilPrintDebug:Create(addonName)
    logger.sfdb = "with nilPrintDebug"
    logger.SetDebug=function(self,truefalse)
        self.enableDebug = truefalse 
        end
    return logger
end
