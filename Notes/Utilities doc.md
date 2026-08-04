Here is a reference-style Markdown document for the utilities shown in your code.

````markdown
# Utility Functions Reference

This section documents the miscellaneous helper functions provided by **LibSFUtils**. These utilities simplify common Lua tasks, provide safer function invocation, assist with argument handling, formatting, addon metadata, chat output, and several ESO-specific conveniences.

---

# Argument Utilities

## `iter_args(...)`

Creates an iterator for a variable argument list without requiring Lua 5.2's `table.pack()`.

Unlike iterating over a temporary table directly, the iterator returns the current argument index, the argument value, and the total number of arguments on each iteration.

### Syntax

```lua
for index, value, total in sfutil.iter_args(...) do
    ...
end
```

### Parameters

| Parameter | Description |
|----------|-------------|
| `...` | Any number of arguments. |

### Returns

An iterator function returning:

| Return | Description |
|---------|-------------|
| `index` | Current argument index. |
| `value` | Current argument value. |
| `total` | Total number of arguments originally supplied. |

### Example

```lua
for i, value, total in sfutil.iter_args("a", 5, true) do
    d(i, value, total)
end
```

Output

```
1    a      3
2    5      3
3    true   3
```

---

# Function Utilities

## `closure(callback, selfTable)`

Creates a closure that permanently binds a table as the first parameter passed to a callback.

This is useful when passing object methods as callbacks while preserving the desired `self` value.

### Syntax

```lua
local fn = sfutil.closure(callback, selfTable)
```

### Parameters

| Parameter | Description |
|----------|-------------|
| `callback` | Function to invoke later. |
| `selfTable` | Table passed as the first parameter to the callback. |

### Returns

A callable function.

### Example

```lua
local callback = sfutil.closure(MyObject.Update, MyObject)

callback(10, 20)
```

Internally this performs

```lua
MyObject.Update(MyObject, 10, 20)
```

---

## `WrapFunction()`

Wraps an existing function so all future calls pass through a wrapper function.

This is useful for:

- debugging
- profiling
- logging
- instrumentation
- temporary hooks

### Syntax

Global function

```lua
sfutil.WrapFunction("FunctionName", wrapper)
```

Namespaced function

```lua
sfutil.WrapFunction(namespace, "FunctionName", wrapper)
```

### Wrapper Signature

```lua
function wrapper(originalFunction, ...)
```

The wrapper receives the original function as its first argument and may call it or completely replace its behavior.

### Example

```lua
sfutil.WrapFunction("MyFunction",
    function(original, ...)
        d("Before")
        local result = original(...)
        d("After")
        return result
    end)
```

---

# Safe Function Calls

## `safeCall10(fn, ...)`

Executes a function inside `pcall()` and safely returns up to ten return values without creating a temporary table.

This version minimizes memory allocations and is useful for frequently called functions.

### Syntax

```lua
local ok, result1, result2 = sfutil.safeCall10(fn, ...)
```

### Returns

| Return | Description |
|---------|-------------|
| `ok` | `true` if the call succeeded. |
| remaining | Up to ten return values from the function. |

On failure

```lua
false, errorMessage
```

### Example

```lua
local ok, value = sfutil.safeCall10(MyFunction)
```

---

## `safeCall(fn, ...)`

Executes a function safely using `pcall()`.

Unlike `safeCall10()`, this version preserves every return value by storing them temporarily in a table.

### Syntax

```lua
local ok, ... = sfutil.safeCall(fn, ...)
```

### Returns

| Return | Description |
|---------|-------------|
| `ok` | Success flag. |
| remaining | All values returned by the function. |

### Example

```lua
local ok, a, b, c, d = sfutil.safeCall(MyFunction)
```

---

# Boolean Utilities

## `bool2str(bool)`

Converts a boolean value into `"true"` or `"false"`.

### Example

```lua
sfutil.bool2str(true)
```

Returns

```
true
```

---

## `str2bool(str)`

Converts a string representation into a boolean.

Accepted true values:

- `"true"`
- `"1"`

Everything else returns `false`.

### Example

```lua
sfutil.str2bool("true")
```

Returns

```lua
true
```

---

## `isTrue(value)`

Performs a stricter boolean test than Lua's built-in truthiness.

Returns `true` only for the following values:

- `true`
- `"true"`
- `1`
- `"1"`

Everything else returns `false`.

### Example

```lua
sfutil.isTrue("1")
```

Returns

```lua
true
```

---

# Default Value Utilities

## `nilDefault(value, default)`

Returns `default` only if `value` is `nil`.

Unlike Lua's `or` operator, `false` is preserved.

### Example

```lua
local enabled = sfutil.nilDefault(saved.enabled, false)
```

---

## `nilDefaultStr(value, default)`

Returns `default` if the value is either:

- `nil`
- an empty string

### Example

```lua
local name = sfutil.nilDefaultStr(userName, "Unknown")
```

---

# Addon Metadata

## `addonMeta(namespace, addonName)`

Creates or populates a table containing information about the current addon and player.

### Collected Fields

| Field | Description |
|-------|-------------|
| `addonName` | Addon name. |
| `server` | Current world/server name. |
| `account` | Account display name. |
| `charId` | Character ID. |
| `charName` | Character name. |
| `fmtCharName` | Formatted character name. |
| `API` | Current ESO API version. |

### Example

```lua
local meta = sfutil.addonMeta("MyAddon")
```

---

# Time Utilities

## `secondsToClock(seconds)`

Converts a number of seconds into an `HH:MM:SS` string.

### Example

```lua
sfutil.secondsToClock(3665)
```

Returns

```
01:01:05
```

---

# System Chat Utilities

## `initSystemMsgPrefix(addonName[, color])`

Creates a colored prefix suitable for addon chat messages.

### Example

```lua
local prefix = sfutil.initSystemMsgPrefix("MyAddon")
```

Produces something similar to

```
[MyAddon]
```

with color formatting applied.

---

## `systemMsg(prefix, text[, color])`

Displays a colored message in the ESO system chat.

### Example

```lua
sfutil.systemMsg(prefix, "Settings loaded.")
```

---

# `addonChatter`

`addonChatter` is a lightweight helper object that manages normal and debug output in ESO chat.

It automatically applies colors and prefixes to messages.

---

## Creating an Instance

```lua
local chat = sfutil.addonChatter:New("MyAddon")
```

---

## Normal Messages

```lua
chat:systemMessage("Addon initialized.")
```

---

## Debug Messages

Enable debugging

```lua
chat:enableDebug()
```

Disable debugging

```lua
chat:disableDebug()
```

Toggle debugging

```lua
chat:toggleDebug()
```

Print a debug message

```lua
chat:debugMsg("Loaded profile.")
```

---

## Debug State

### `isDebugEnabled()`

Returns

```lua
true
```

or

```lua
false
```

---

### `getDebugState()`

Returns the string

```
true
```

or

```
false
```

---

## Changing Colors

```lua
chat:setNormalColor(sfutil.hex.white)

chat:setDebugColor(sfutil.hex.orange)
```

---

## Slash Command Help

### `slashHelp(title, commands)`

Displays a formatted list of slash commands.

Example

```lua
chat:slashHelp("Commands", {
    {"/my reload", "Reload settings"},
    {"/my reset", "Reset profile"},
})
```

Produces

```
Commands

/my reload = Reload settings
/my reset  = Reset profile
```

---

# Summary

These utility functions provide convenient wrappers around many common Lua and ESO programming tasks, including:

- Safe function invocation
- Argument iteration
- Closure creation
- Function wrapping
- Boolean conversion
- Default value handling
- Addon metadata collection
- Time formatting
- System chat output
- Debug message management

They are intended to reduce boilerplate while providing consistent behavior throughout an addon.
````
