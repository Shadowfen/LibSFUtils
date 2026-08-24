local sfutil = LibSFUtils
assert(sfutil, "LibSFUtils_Global must be loaded before this file")


-- logger object that prints to chat
-- activePrintDebug is the functional print-to-chat logger implementation.
-- It can be used directly (in place of LibDebugLogger) and therefore performs 
-- its own enabled-state checks.
-- printDebug also uses these methods as its enabled-state implementations.
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
            if not self.enabled or not self.SFenableDebug then return end
            print("["..self.addonName.."] DEBUG: "..string.format(...))
        end,
    Create = function(self,name)
            local o = setmetatable({}, { __index = self})
            o.addonName = name
            return o
        end,
    SetEnabled = function(self,truefalse) self.enabled = truefalse end,
}

-- logger object that does not print anywhere
-- Use nilPrintDebug:Create() or sfutil.CreateNilLogger() to create a logger instance of this type
-- nilPrintDebug is the disabled/no-op implementation table.
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

-- helper for the printDebug table below (and the CreateLogger())
local function UpdateDebugMethod(self)
    if self.enabled and self.SFenableDebug then
        if self.SFsvDebugFn == nil then
            self.Debug = activePrintDebug.Debug
        else
            self.Debug = self.SFsvDebugFn
        end
    else
        self.Debug = nilPrintDebug.Debug
    end
end

-- logger object that prints to chat when enabled
-- Use Create() to create a logger instance of this type
-- printDebug is the prototype/factory and state-management table.
local printDebug = {
    Error = activePrintDebug.Error,
    Warn = activePrintDebug.Warn,
    Info = activePrintDebug.Info,
    Debug = activePrintDebug.Debug,
    Create = activePrintDebug.Create,

    SetEnabled = function(self, tf)
        if self.enabled == tf then return end

        self.enabled = tf

        if tf then
            self.Error = activePrintDebug.Error
            self.Warn  = activePrintDebug.Warn
            self.Info  = activePrintDebug.Info
        else
            self.Error = nilPrintDebug.Error
            self.Warn  = nilPrintDebug.Warn
            self.Info  = nilPrintDebug.Info
        end
        UpdateDebugMethod(self)
    end,
}

--[[ Returns a function to return a logger object (creating it if necessary first).
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

--[[ Returns a logger object (creating it if necessary first)
    Parameters:
        namespace = the table that you want the logger object stored into. Typically the
            namespace table for your addon that you use - such as MyAddon = {}
            If this is not a table, we assume it is the name of the table that is found in _G.
            If it is a string, it will be used for the addonname parameter and the name of the
            table to find (or create) in _G.
        loggervar =  the name of the logger instance to use.
        addonname =  the name of the addon this logger object is associated with.

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

    local mylogger = namespace[loggervar]

    if not mylogger then
        mylogger = sfutil.Createlogger(addonname)
        mylogger:SetEnabled(true)
        namespace[loggervar] = mylogger
    end

    return mylogger
end

local function SetDebug(self, truefalse)
    self.SFenableDebug = truefalse
    UpdateDebugMethod(self)
end

-- create an instance of a logger (with LibDebugLogger if available, otherwise just print to chat)
-- By default the logger is set to be not enabled (i.e. output nothing).
-- You can use :SetEnabled(true) to turn on output.
-- You can use :SetDebug(true) to turn on debug-level output as well.
function sfutil.Createlogger(addonName)
    local logger

    if LibDebugLogger then
        logger = LibDebugLogger:Create(addonName)
        logger.sfdb = "with LibDebugLogger"

        -- Save the LibDebugLogger implementation.
        logger.SFsvDebugFn = logger.Debug

    else
        logger = printDebug:Create(addonName)
        logger.sfdb = "with printDebug"
    end

    logger.SetDebug = SetDebug
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

--[[ InitSafeLogger(namespace, loggervar, addonname)
    
    Initialize a set of safe, lazy logger functions for an addon. (Uses 
    LibDebugLogger as the basis logger if it is loaded first otherwise
    it will log to chat.)
    
    Returns three functions:
        loggerFn       - returns the addon's logger, creating it if necessary
        logDebug       - logs a DEBUG-level message if debug logging is enabled
        logWouldDebug  - returns true if DEBUG-level logging is currently enabled
    
    The returned functions do not require the logger to already exist. The
    logger is created on the first call to any of the returned functions.
    This allows the functions to be initialized early in an addon's load
    sequence without creating a dependency on logger initialization order.
    
    loggerFn has the same behavior as the function returned by
    SafeLoggerFunction(). It returns the same logger instance on subsequent
    calls.
    
    logDebug(message, ...)
        Logs a debug message using the addon's logger.
        
        Parameters:
            message - the message to log, or nil
            ...     - optional additional message parameters

        * If message contains ESO zo_strformat placeholders (<<1>>, <<2>>,
            etc.), zo_strformat() is used to format the message. 
        * Otherwise, SF.str() is used to process the message and its additional 
            parameters, converting them to strings to concatenate (without delimiters).
        
        No message is generated when debug logging is disabled.
        

    logWouldDebug()
        Returns true when the logger is enabled and DEBUG-level logging is
        enabled. This can be used to avoid performing expensive operations
        solely to construct a debug message.
    
        Example:
            if logWouldDebug() then
                local details = BuildExpensiveDebugString()
                logDebug("Details: <<1>>", details)
            end
    
    Parameters:
        namespace - table containing the logger instance. If this is not a
                    table, it is treated as the addon's global table name.
                    The table is created in _G if it does not already exist.
        
        loggervar - string containing the name of the logger instance stored
                   in namespace.
        
        addonname - name associated with the logger. When namespace is a
                    string, it is also used as the global table name.
    
    Returns:
        loggerFn      - function returning the lazily-created logger
        logDebug      - function for filtered DEBUG-level logging
        logWouldDebug - function returning whether DEBUG logging is active
    
    Example:
        local Logger, logDebug, logWouldDebug =
            sfutil.InitSafeLogger(MyAddon, "logger", MyAddon.name)

        -- Full logger API:
        Logger():Info("Addon initialized")
        Logger():Warn("Something unexpected happened")

        -- Convenience debug logging:
        logDebug("Processing item <<1>>", itemId)

        -- Avoid expensive debug processing when debug logging is disabled:
        if logWouldDebug() then
            local details = BuildDebugDetails()
            logDebug("Details: <<1>>", details)
        end

    Note:
        InitSafeLogger() initializes the logging functions but does not
        immediately create the logger. This makes the returned functions
        safe to define in files that may load before the logger is otherwise
        needed or initialized.
--]]
function sfutil.InitSafeLogger(namespace, loggervar, addonname)
    local loggerFn = sfutil.SafeLoggerFunction(
        namespace,
        loggervar,
        addonname
    )

    local function logDebug(message, ...)
        if message == nil then return end

        local logger = loggerFn()
        if not logger.enabled or not logger.SFenableDebug then
            return
        end

        local paramCount = select("#", ...)

        if paramCount == 0 then
            logger:Debug(message)
            return
        end

        if type(message) == "string"
            and message:find("<<%d+>>", 1)
        then
            logger:Debug(zo_strformat(message, ...))
            return
        end

        logger:Debug(sfutil.str(message, ...))
    end

    local function logWouldDebug()
        local logger = loggerFn()
        return logger.enabled and logger.SFenableDebug
    end

    return loggerFn, logDebug, logWouldDebug
end