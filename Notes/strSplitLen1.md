````markdown id="84291"
# `sfutil.strSplitLen()`

## Overview

`sfutil.strSplitLen()` splits a long string into smaller chunks that do not exceed a specified maximum length.

This utility is designed primarily for **ESO chat output**, where messages have a maximum size limit. It allows large debug messages, logs, or reports to be divided into multiple messages before being displayed.

---

## Syntax

```lua
local result = sfutil.strSplitLen(str, maxlen)
````

---

## Parameters

| Parameter | Type              | Description                                       |
| --------- | ----------------- | ------------------------------------------------- |
| `str`     | string            | The string to split into chunks.                  |
| `maxlen`  | number (optional) | Maximum length of each chunk. Defaults to `1800`. |

---

## Returns

| Return Type | Description                                                                  |
| ----------- | ---------------------------------------------------------------------------- |
| string      | Returned unchanged when the string length is less than or equal to `maxlen`. |
| table       | A table containing string chunks when the input exceeds `maxlen`.            |

---

# Behavior

## Short Strings

If the string already fits within the limit:

```lua
local result = sfutil.strSplitLen(
    "Hello World",
    1800
)
```

returns:

```lua
"Hello World"
```

No table is created.

---

## Long Strings

When the input exceeds `maxlen`, the string is split:

```lua
local chunks = sfutil.strSplitLen(
    longMessage,
    1800
)
```

returns:

```lua
{
    "first 1800 characters...",
    "next 1800 characters...",
    "remaining characters..."
}
```

The chunks can be sent individually:

```lua
for _, msg in ipairs(chunks) do
    ZOS_addSystemMsg(msg)
end
```

---

# Default Length

If `maxlen` is omitted:

```lua
sfutil.strSplitLen(message)
```

the default is:

```lua
1800
```

This leaves room below ESO's chat message limit.

---

# Invalid Parameters

## Invalid String

If the first argument is not a string:

```lua
sfutil.strSplitLen(123)
```

the function replaces it with:

```text
sfutil.strSplitLen: first argument must be a string
```

---

## Invalid Maximum Length

If `maxlen` is:

* Not a number.
* Zero.
* Negative.

the default value is used:

```lua
1800
```

Examples:

```lua
sfutil.strSplitLen(text, 0)
```

```lua
sfutil.strSplitLen(text, "abc")
```

Both use:

```lua
1800
```

---

# Examples

## Sending a Large Chat Message

```lua
local text = sfutil.strcat(
    "Saved Variables:",
    savedVars
)

local parts = sfutil.strSplitLen(text)

if type(parts) == "table" then
    for _, msg in ipairs(parts) do
        ZOS_addSystemMsg(msg)
    end
else
    ZOS_addSystemMsg(parts)
end
```

---

## Custom Chunk Size

Split into 500-character pieces:

```lua
local chunks = sfutil.strSplitLen(
    logText,
    500
)
```

---

# Implementation Notes

## Uses ESO String Functions

The function uses:

```lua
zo_strlen()
```

instead of Lua:

```lua
#str
```

and:

```lua
zo_strsub()
```

instead of:

```lua
string.sub()
```

This keeps behavior consistent with ESO's string handling functions.

---

## Return Type Consideration

The function intentionally returns two different types:

| Input Size          | Return |
| ------------------- | ------ |
| Fits in one message | string |
| Requires splitting  | table  |

Callers should handle both cases:

```lua
local result = sfutil.strSplitLen(text)

if type(result) == "table" then
    for _, chunk in ipairs(result) do
        send(chunk)
    end
else
    send(result)
end
```

---

# Intended Usage

Recommended uses:

* Splitting debug output.
* Sending large saved variable dumps.
* Displaying addon reports.
* Sending generated help text.

Not intended for:

* Word wrapping.
* Sentence-aware formatting.
* Unicode-aware grapheme splitting.

---

# Summary

`sfutil.strSplitLen()` provides a simple way to safely divide large strings for ESO chat output.

Features:

* Configurable maximum length.
* ESO-compatible string handling.
* Efficient short-string path.
* Preserves original text when chunks are recombined.

Example:

```lua
local chunks = sfutil.strSplitLen(message)

for _, chunk in ipairs(chunks) do
    ZOS_addSystemMsg(chunk)
end
```

