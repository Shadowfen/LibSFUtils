#Logging-related functions

## SafeLoggerFunction()

`sfutil.SafeLoggerFunction(namespace, loggervar, addonname)`

Returns a function which will return a logger object (creating it if necessary first).
If a logger gets created, it will be enabled by default. (Debug-level will be DISABLED by default.)
* namespace = (table or string) the table that you want the logger object stored into. If this
        is not a table, we assume it is the name of the table that is found in _G.
        If it is a string, it will be used for the addonname parameter and the name of the
        table to find (or create) in _G.
* loggervar =  (string) the name of the logger instance variable to use.
* addonname =  (string) the name of the addon this logger object is associated with.

The function returned by this function runs quicker than **sfutil.SafeLogger()** because
the preliminary checking is done only before the function is created - not every time it runs.

## SafeLogger()

`function sfutil.SafeLogger(namespace, loggervar, addonname)`

Returns a logger object (creating it if necessary first)

Recommend that you create a specific logger function using [SafeLoggerFunction()](https://github.com/Shadowfen/LibSFUtils/wiki/SFUtils_Logger#sfutilsafeloggerfunctionnamespace-loggervar-addonname)
instead of using this function.

# The Logger Object
The logger object which is created by the above functions is based on the LibDebugLogger object. It has the normal functions: **Create**, **SetEnabled**, **Error**, **Warn**, **Info**, and **Debug** functions expected for a LibDebugLogger instance. It also has addition functions: **SetDebug**, and **origDebug**.

The **SetDebug()** allows you to turn on or off the writing of DEBUG messages to the logger.

The **origDebug** saves the original **Debug()** function for when DEBUG is turned off and the **:Debug()** function gets replaced with a function that does nothing. When **SetDebug(true)** is executed (allowing the writing of DEBUG messages), then the **origDebug** function gets copied back to the **:Debug()** function.
