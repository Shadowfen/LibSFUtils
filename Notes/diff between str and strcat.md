With this implementation of `sfutil.str()`, the difference between `str()` and `strcat()` is **almost nonexistent**. In fact, the two functions are now doing the same job.

The earlier distinction I described assumed `str()` was a simple concatenator. Your actual `str()` implementation is a **deep string formatter built on `tcstr()`**, just like `strcat()`.

## Current Relationship

Your `str()`:

```lua
function sfutil.str(...)
    ...
    tcstr(pending, rslt_pool, {})
    return table.concat(rslt_pool)
end
```

and your `strcat()`:

```lua
function strcat(...)
    ...
    tcstr(pending, rslt_pool, {})
    return table.concat(rslt_pool)
end
```

have the same architecture:

```
arguments
    |
    v
pending stack
    |
    v
tcstr()
    |
    v
rslt_pool
    |
    v
table.concat()
    |
    v
string
```

They are effectively aliases.

---

# The Actual Difference

The difference is likely **historical naming**, not behavior.

## `str()`

`str()` is a general-purpose string conversion utility.

Typical usage:

```lua
local msg = sfutil.str(
    "Loaded character:",
    characterName
)
```

Because it is short and commonly used, it is convenient for normal addon code.

Example:

```lua
chat:systemMessage(
    sfutil.str("Loaded ", count, " items")
)
```

---

## `strcat()`

`strcat()` communicates a more explicit purpose:

> "Concatenate these values into a string."

Example:

```lua
local debugText = sfutil.strcat(
    "SavedVars:",
    savedVars
)
```

The name suggests:

* joining values
* debugging
* producing a text representation

---

# Current Functional Comparison

| Feature         | `str()` | `strcat()` |
| --------------- | ------- | ---------- |
| Uses `tcstr()`  | ✅       | ✅          |
| Handles tables  | ✅       | ✅          |
| Handles cycles  | ✅       | ✅          |
| Reuses buffer   | ✅       | ✅          |
| Returns string  | ✅       | ✅          |
| Deep formatting | ✅       | ✅          |
| Performance     | Same    | Same       |

There is no meaningful runtime difference.

---

# Recommendation

You should probably keep **one implementation** and make the other a wrapper.

For example:

```lua
function sfutil.str(...)
    return strcat(...)
end
```

or:

```lua
sfutil.strcat = sfutil.str
```

Then document one canonical function.

---

# Which Name Should Be Primary?

I would make:

```lua
sfutil.str()
```

the primary public API.

Reasons:

* It is shorter.
* It matches common ESO addon style (`zo_strformat`, `str` helpers).
* It reads naturally:

```lua
chat.d(sfutil.str("Value:", value))
```

rather than:

```lua
chat.d(sfutil.strcat("Value:", value))
```

---

# Documentation Change

I would document it as:

````markdown
# `sfutil.str()`

Converts one or more Lua values into a single string.

Unlike normal Lua concatenation (`..`), `sfutil.str()` can process tables and nested values using `tcstr()`.

Use for:

- Chat messages.
- Debug output.
- Diagnostic logging.

Example:

```lua
chat.d(sfutil.str(
    "Settings:",
    settings
))
````

`sfutil.str()` is equivalent to `sfutil.strcat()`; both use the same internal table traversal and formatting logic.

````

---

One thing I would fix in your implementation: it references `pending`, but the snippet only declares `rslt_pool`:

```lua
pending[#pending + 1] = select(i, ...)
````

If `pending` is also a module-level reusable table, it should be cleared before reuse. Otherwise arguments from previous calls may remain. A safer pattern is:

```lua
local rslt_pool = {}
local pending = {}
```

and clear both at the beginning of `str()`.
