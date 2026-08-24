# Logging-related functions (version 77)

`SFUtils_Logger` provides a small logging abstraction for ESO addons.

It supports:

- `LibDebugLogger` when available
- A lightweight chat-based fallback logger
- A no-op logger
- Independent control of normal and DEBUG logging
- Lazy logger creation
- Safe logger access when addon file load order is complex
- Convenience functions for DEBUG logging
- An execution guard for avoiding expensive DEBUG message construction

LibSFUtils has historically provided both logger creation and wrapper functionality around `LibDebugLogger`. The current implementation also supports using the same addon-facing API when `LibDebugLogger` is unavailable. 

---

## Recommended Usage

For most addons, use `InitSafeLogger()`:

```lua
local Logger, logDebug, logWouldDebug =
    SF.InitSafeLogger(MyAddon, "logger", MyAddon.name)
```
This creates three local functions:
Function | Purpose
-- | --
Logger() | Returns the addon's logger instance
logDebug(...) | Convenience function for DEBUG logging
logWouldDebug() | Tests whether DEBUG logging is currently active

## Use as an Execution Guard
The primary purpose of `logWouldDebug()` is to prevent expensive operations that exist only to produce debug output.
Avoid:
```lua
local details = SF.tblstr(largeTable)
logDebug("Current state:<<1>>", details)
```
because `SF.tblstr()` executes even when DEBUG logging is disabled.
Instead use:
```lua
if logWouldDebug() then
    local details = SF.tblstr(largeTable)
    logDebug("Current state: <<1>>", details)
end
```
This is especially useful for:
- Large table dumps
- Recursive string formatting
- Expensive calculations
- Building diagnostic data
- Multi-step debugging code
----
# Logger Backends
```
sfutil.Createlogger()
```
 automatically selects the available backend.
```
                Createlogger()
                       |
              LibDebugLogger?
                 /          \
               yes           no
                |             |
                v             v
        LibDebugLogger    printDebug
```
## LibDebugLogger
When `LibDebugLogger` is available
```lua
logger = LibDebugLogger:Create(addonName)
```
The logger uses the normal `LibDebugLogger` implementation.
The original DEBUG function is retained so that `SetDebug()` can enable or disable DEBUG output without replacing the underlying logger.
## Print Logger
When `LibDebugLogger` is unavailable, `SFUtils_Logger` uses its own print-based implementation.
Messages are written to chat using `print()`.
Example:
```
[MyAddon] ERROR: Unable to load configuration
[MyAddon] WARN: Using default configuration
[MyAddon] INFO: Configuration loaded
[MyAddon] DEBUG: Processing item 12345
```

The print implementation has its own enabled-state checks, so it can also be used as a standalone logger implementation.

----

# Logger State
The logger has two independent controls.
## Normal Logging
Controlled with:
```lua
logger:SetEnabled(true)
logger:SetEnabled(false)
```
When disabled, `Error()`, `Warn()`, and `Info()` produce no output.
## DEBUG Logging
Controlled with:
```lua
logger:SetDebug(true)
logger:SetDebug(false)
```
DEBUG output requires both normal logging and DEBUG logging to be enabled.
```lua
logger:SetEnabled(true)
logger:SetDebug(true)
```
Only then will:
```lua
logger:Debug("...")
```
produce output.

----

# `logger:SetEnabled()`
```lua
logger:SetEnabled(true)
logger:SetEnabled(false)
```
Enables or disables normal logging.
When using the print logger, changing this state also switches the logger's methods between active and no-op implementations.
For example:
```lua
logger:SetEnabled(false)

logger:Error("Not displayed")
logger:Warn("Not displayed")
logger:Info("Not displayed")
```
Re-enable it with:
`logger:SetEnabled(true)`

----

# `logger:SetDebug()`
```lua
logger:SetDebug(true)
logger:SetDebug(false)
```
Controls DEBUG-level logging independently of normal logging.
Example:
```lua
logger:SetEnabled(true)

logger:SetDebug(false)
logger:Debug("Not displayed")

logger:SetDebug(true)
logger:Debug("Displayed")
```
The logger initially has DEBUG logging disabled.

----

# `sfutil.SafeLoggerFunction()`
```lua
local Logger =
    SF.SafeLoggerFunction(namespace, loggervar, addonname)
```
Creates a lazy logger accessor.
The returned function creates the logger if necessary and returns it.
Example:
```lua
local Logger =
    SF.SafeLoggerFunction(MyAddon, "logger", MyAddon.name)
```
Usage:
```lua
Logger():Info("Addon initialized")
Logger():Debug("Debug information")
```
`SafeLoggerFunction()` is the lower-level convenience function used when only the logger accessor is required.
If an addon also wants `logDebug()` and `logWouldDebug()`, prefer:
```lua
local Logger, logDebug, logWouldDebug =
    SF.InitSafeLogger(MyAddon, "logger", MyAddon.name)
```

----

# `sfutil.SafeLogger()`
```lua
local logger =
    SF.SafeLogger(namespace, loggervar, addonname)
```
Returns a logger instance, creating it if necessary.
Unlike `SafeLoggerFunction()`, this function returns the logger immediately.
Example:
```lua
local logger =
    SF.SafeLogger(MyAddon, "logger", MyAddon.name)

logger:Info("Addon initialized")
```
If the logger already exists, the existing logger is returned.
```lua
local logger1 =
    SF.SafeLogger(MyAddon, "logger", MyAddon.name)

local logger2 =
    SF.SafeLogger(MyAddon, "logger", MyAddon.name)

assert(logger1 == logger2)
```
For large addons where logger initialization order is a concern, prefer `InitSafeLogger()`.

----

# `sfutil.Createlogger()`
```lua
local logger = SF.Createlogger(addonName)
```
Creates a logger instance.
The backend is selected automatically based on whether `LibDebugLogger` is available.
The newly created logger starts with DEBUG logging disabled.
```lua
logger.SFenableDebug == false
```
`SafeLogger()` and `SafeLoggerFunction()` enable normal logging after creating the logger.

----

# `sfutil.CreateNilLogger()`
```lua
local logger = SF.CreateNilLogger(addonName)
```
Creates a logger that never produces output.
It provides the same logging interface:
```lua
logger:Error(...)
logger:Warn(...)
logger:Info(...)
logger:Debug(...)
```
but all operations are no-ops.
This allows logging implementations to be replaced without requiring callers to test whether logging is available.

----

# Recommended Pattern
For a typical addon:
```lua
local SF = LibSFUtils

local Logger, logDebug, logWouldDebug =
    SF.InitSafeLogger(MyAddon, "logger", MyAddon.name)
```
Use the logger for normal messages:
```lua
Logger():Error("Unable to load data")
Logger():Warn("Using default configuration")
Logger():Info("Configuration loaded")
```
Use `logDebug()` for normal DEBUG messages:
```lua
logDebug("Processing item <<1>>", itemId)
```
Use `logWouldDebug()` when preparing the debug message requires significant work:
```lua
if logWouldDebug() then
    local state = BuildDebugState()
    logDebug("Current state: <<1>>", state)
end
```
This provides a clean separation:
```
Normal logging
    |
    +-- Logger():Error()
    +-- Logger():Warn()
    +-- Logger():Info()

Debug logging
    |
    +-- logDebug()
    |
    +-- logWouldDebug()
          |
          +-- guard expensive debug-only work
```

----

# File Load Order
`InitSafeLogger()` is specifically useful when an addon consists of many Lua files.
A common pattern is to initialize the logging functions in an early file:
```lua
-- MyAddon.lua

local SF = LibSFUtils

MyAddon.Logger,
MyAddon.logDebug,
MyAddon.logWouldDebug =
    SF.InitSafeLogger(MyAddon, "logger", MyAddon.name)
```
Other files can then use the functions without explicitly creating the logger:
```lua
-- MyAddon_Items.lua

local logDebug = MyAddon.logDebug

function MyAddon:ProcessItem(item)
    logDebug("Processing item <<1>>", item.id)
end
```
The actual logger does not have to be created at the point where the functions are defined.
This removes an otherwise unnecessary load-order dependency.

----

# Performance Considerations

The logger functions are designed so that disabled DEBUG logging does not perform the formatting work required to produce the message.
For example:
```lua
logDebug("Large diagnostic string: <<1>>", expensiveValue
```
will return before formatting when DEBUG logging is disabled.
However, Lua evaluates function arguments **before** entering `logDebug()`.
Therefore this:
```lua
logDebug("State: <<1>>", BuildExpensiveState())
```
still executes:
```lua
BuildExpensiveState()
```
even when DEBUG logging is disabled.
Use:
```lua
if logWouldDebug() then
    logDebug("State: <<1>>", BuildExpensiveState())
end
```
when argument construction is expensive.
This distinction is important:`logDebug(...)`
    prevents logger/message formatting
whereas:`logWouldDebug()`
    prevents expensive caller-side work

----

# Summary
For new addon code, the recommended pattern is:
```lua
local Logger, logDebug, logWouldDebug =
    SF.InitSafeLogger(MyAddon, "logger", MyAddon.name)
```
Then:
```lua
Logger():Info("Normal informational message")
```
for normal logging,
```lua
logDebug("Debug message <<1>>", value)
```
for DEBUG logging, and:
```lua
if logWouldDebug() then
    local diagnostic = BuildExpensiveDiagnosticData()
    logDebug("Diagnostic data: <<1>>", diagnostic)
end
```
when expensive work should only be performed while DEBUG logging is active.
This provides a single addon-facing logging API while allowing the underlying implementation to use `LibDebugLogger`, the SFUtils print logger, or a no-op logger.
The existing LibSFUtils release documentation also describes `SafeLoggerFunction()` as a lazy logger accessor and `SetDebug()` as the DEBUG-output control, so this structure preserves those established concepts while documenting the newer `InitSafeLogger()` convenience layer.
