local sfutil = LibSFUtils or {}

-- logger object that prints to chat
-- Use Create() to create a logger instance of this type
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
    SetEnabled = function(self,truefalse) self.enabled = truefalse end,
}

-- logger object that does not print to anywhere
-- Use Create() to create a logger instance of this type
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

-- logger object that prints to chat when enabled
-- Use Create() to create a logger instance of this type
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
        if not self.enabled or not self.SFenableDebug then return end
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

--[[
    function sfutil.SafeLoggerFunction(namespace, loggervar, addonname)

  Returns a function to return a logger object (creating it if necessary first).
  If a logger gets created, it will be enabled by default, and its DEBUG-level
  messages will be disabled by default. in the log.
  When disabled, no messages are WRITTEN to the log from this addon.

  Note: Enabling debug-level messages with SetDebug(true) may (probably will) cause
    some lagging in the game and tons of messages in the log viewer.

  Note: If you want to use this with LibDebugLogger, you have to require the LibDebuggLogger library in
    your addon's manifest!

    namespace = the table that you want the logger object stored into. If this
        is not a table, we assume it is the name of the table that is found in _G.
        If it is a string, it will be used for the addonname parameter and the name of the
        table to find (or create) in _G.
    loggervar =  the name of the logger instance to use.
    addonname =  the name of the addon this logger object is associated with.

    The function returned by this function runs quicker than sfutil.SafeLogger() because
    the preliminary safety checking is done only before the function is created - not every
    time it is run.

    This function allows you to call the logger without having to worry about it having been
    created yet.

    Example of use:
        MyAddon_Logger = sfutil.SafeLoggerFunction( MyAddon, "logger", MyAddon.name)
        ...
        MyAddon_Logger():SetDebug(true)
        MyAddon_Logger():Info("This is a test of the Emergency Broadcast System.")
        MyAddon_Logger():Debug("This is only a test.")
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

-- create an instance of a logger (with LibDebugLogger if available, otherwise just print to chat)
-- By default the logger is set to be not enabled (i.e. output nothing).
-- You can use :SetEnabled(true) to turn on output.
-- You can use :SetDebug(true) to turn on debug-level output as well.
function sfutil.Createlogger(addonName)
    -- initialize the logger for an addon
    local logger = nil

    if LibDebugLogger then
        logger = LibDebugLogger:Create(addonName)
        logger.sfdb = "with LibDebugLogger"
    else
        logger = printDebug:Create(addonName)
        logger.sfdb = "with printDebug"
    end

    -- Debug-level messages are turned off on creation by default.
    -- You must logger:SetDebug(true) in order to turn on debug-level
    -- messages. (And with the LibDebugLogger, you must ALSO turn on
    -- collection of debug-level messages in the Debug Log Viewer -> LibDebugLogger
    -- settings.)

    -- save the original Debug() so that we can turn it on and off
    logger.SFsvDebugFn = logger.Debug
    logger.SetDebug = function(self,truefalse)
        -- Note: For Debug to work, you must ALSO enable debug messages in the
        -- Debug Log Viewer -> LibLogDebugger settings!!!
        logger.SFenableDebug = truefalse

        -- change the Debug() function to send or not send according total
        -- if debug is enabled here.
        if logger.SFenableDebug == false then
            -- will not send anything to LibDebugLogger or to chat
            logger.Debug = nilPrintDebug.Debug
        else
            -- send debug messages to the original Debug()
            logger.Debug = logger.SFsvDebugFn
        end
    end
    -- debug is OFF by default. Can be changed by settings or other programmatic means
    logger:SetDebug(false)

    return logger
end

-- create an instance of a nil logger
-- This logger will never output anything (useful for completely turning off logging)
-- It has the same API as the real loggers in order to be replaceable with them, just no output ever.
function sfutil.CreateNilLogger(addonName)
    -- initialize the logger for an addon
    local logger = nilPrintDebug:Create(addonName)
    logger.sfdb = "with nilPrintDebug"
    logger.SetDebug=function(self,truefalse)
        self.SFenableDebug = truefalse
        end
    return logger
end
