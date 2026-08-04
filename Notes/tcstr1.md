This function is a **non-recursive table-to-string collector**. It walks through a set of pending values, expands tables, detects circular references, evaluates functions, and appends string representations into `rslt`.

It is likely intended as a helper for debugging or pretty-printing complex Lua structures.

## Markdown Documentation

````markdown
# `tcstr()`

## Purpose

`tcstr()` converts a collection of Lua values into a list of string representations.

It is designed for safely inspecting complex data structures without using recursive table traversal.

Features:

- Handles nested tables.
- Detects circular references.
- Handles `nil` values.
- Evaluates function values.
- Avoids recursive stack growth by using a pending work list.

---

# Syntax

```lua
local result = tcstr(pending, rslt, seen)
```

---

# Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `pending` | table | Stack of values waiting to be processed. |
| `rslt` | table | Output table receiving string representations. |
| `seen` | table | Tracks tables already processed to detect cycles. |

---

# Returns

| Return | Type | Description |
|--------|------|-------------|
| `rslt` | table | The populated result table containing string fragments. |

The caller can combine the results:

```lua
local text = table.concat(rslt, ", ")
```

---

# Processing Rules

`tcstr()` processes values according to their type.

## `nil`

Nil values are represented as:

```text
(nil)
```

Example:

```lua
nil
```

becomes:

```text
(nil)
```

---

## Tables

Tables are expanded and their contents are added back into the processing queue.

Example:

```lua
{
    name = "Bob",
    level = 10
}
```

will process:

```text
name
Bob
level
10
```

---

## Circular References

The function tracks tables already visited using `seen`.

Example:

```lua
local t = {}
t.self = t
```

The circular reference becomes:

```text
<cycle>
```

This prevents infinite loops.

---

## Functions

Function values are called:

```lua
v()
```

The return value is added to the output.

Example:

```lua
{
    value = function()
        return "dynamic"
    end
}
```

produces:

```text
dynamic
```

If the function returns `nil`:

```text
(nil)
```

is added.

---

## Other Values

All other values are converted using:

```lua
tostring(v)
```

Examples:

```text
string
number
boolean
userdata
thread
```

---

# Algorithm

The function uses an explicit stack instead of recursion.

Processing loop:

```lua
while true do

    remove next pending value

    if value is nil
        add "(nil)"

    elseif value is table
        if already seen
            add "<cycle>"
        else
            add contents back to pending list
        end

    elseif value is function
        call function and add result

    else
        add tostring(value)

    end
end
```

---

# Example

```lua
local pending =
{
    {
        name = "Player",
        level = 50
    }
}

local result = {}

local seen = {}

tcstr(
    pending,
    result,
    seen
)

print(table.concat(result, ", "))
```

Possible output:

```text
level, 50, name, Player
```

(The order may vary because tables are traversed using `pairs()`.)

---

# Notes

## Table Ordering

Because this function uses:

```lua
pairs(v)
```

the output order is not guaranteed.

For deterministic output, keys would need to be sorted before traversal.

---

## Function Evaluation Warning

Function values are executed:

```lua
v()
```

This means:

- Side effects may occur.
- Errors may be raised.
- Execution time may vary.

For debugging untrusted data, functions should usually be displayed using:

```lua
tostring(v)
```

instead.

---

## Cycle Detection

The `seen` table uses table identity:

```lua
seen[v]
```

Two different tables containing identical data are treated as separate objects.

---

# Intended Use

`tcstr()` is useful for:

- Debug output.
- Inspecting saved variables.
- Logging complex Lua structures.
- Building diagnostic messages.

It is not intended as a serializer because:

- Table ordering is undefined.
- Functions are executed.
- Metatables are ignored.
- Keys and values are flattened into the output stream.
````

### Additional observation

There is one subtle bug/behavior issue:

```lua
if v == nil then
```

will never execute for values pulled from `pending[n]` because the length operator `#pending` cannot reliably represent holes. If you intentionally want to preserve `nil` arguments, `pending` needs to use an explicit count (similar to `select("#", ...)` or `table.pack()` in Lua 5.2+).

For normal table traversal, this function is fine because table fields with `nil` values do not exist anyway.
