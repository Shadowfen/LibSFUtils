## Evaluation of `tclstr()`

`tclstr()` appears to be another internal string-building helper, probably intended to support a function like `sfutil.str()` or `sfutil.dstr()` by recursively converting arguments into display text.

The intent is good, but the implementation has several correctness and design issues that make it fragile compared with your earlier `tcstr()` implementation.

---

# What it does

Conceptually:

```text
arguments
    |
    v
iterate values
    |
    +-- nil       -> "(nil)"
    |
    +-- number    -> GetString(number)
    |
    +-- table     -> append keys and values recursively
    |
    +-- function  -> ignored
    |
    +-- other     -> tostring()
```

Example:

```lua
tclstr(result, "Hello", 123, {a=5})
```

might produce:

```text
Hello<string 123>a5
```

(depending on ESO string IDs)

---

# Strengths

## 1. Uses your varargs iterator

This:

```lua
for _, v in sfutil.iter_args(...) do
```

is a good idea.

It preserves argument count and handles nil arguments better than:

```lua
for _,v in ipairs({...}) do
```

because `{...}` loses trailing nils.

---

## 2. Uses an output buffer

This is good:

```lua
rslt[#rslt+1] = ...
```

Building a string this way:

```lua
str = str .. value
```

would be much slower.

---

## 3. Ignores functions

This:

```lua
elseif t_v ~= "function" then
```

is reasonable.

Functions are usually not meaningful in chat/debug output.

Your earlier `tcstr()` actually called functions:

```lua
elseif type(v) == "function" then
    rslt[#rslt + 1] = v() or "(nil)"
```

which is risky because arbitrary functions can:

* throw errors
* have side effects
* take arguments

Ignoring them is safer.

---

# Problems

## 1. `if not v` incorrectly treats false as nil

This is the biggest bug.

Current:

```lua
if not v then
```

matches:

```lua
nil
false
```

So:

```lua
tclstr(rslt, false)
```

produces:

```
(nil)
```

which is wrong.

It should be:

```lua
if v == nil then
```

Then:

```lua
false
```

becomes:

```
false
```

---

## 2. Number handling is dangerous

Current:

```lua
elseif t_v == "number" then
    appendVal(GetString(v))
```

This assumes every number is a ZOS string ID.

Example:

```lua
tclstr(rslt, 100)
```

becomes:

```lua
GetString(100)
```

which is probably not what the caller expects.

For general string conversion:

```lua
appendVal(v)
```

is better.

If you want ESO string IDs, that should be explicit:

```lua
sfutil.strId(100)
```

or:

```lua
sfutil.getString(100)
```

---

## 3. Table recursion is incorrect

Current:

```lua
elseif t_v == "table" then
    for k, v1 in pairs(v) do
        appendVal(k)
        if type(v1) ~= "table" then
            appendVal(v1)
        else
            return tclstr(rslt, v1)
        end
    end
end
```

The problem:

```lua
return tclstr(rslt, v1)
```

exits immediately.

Example:

```lua
{
    a = 1,
    b = {
        c = 2
    },
    d = 3
}
```

Output may only contain:

```
a1bc2
```

and never reaches:

```
d3
```

because recursion returned.

It should recurse without returning:

```lua
tclstr(rslt, v1)
```

---

## 4. No cycle protection

This will infinite recurse:

```lua
local t = {}
t.self = t

tclstr(rslt, t)
```

The table handling needs a `seen` table.

Your earlier `tcstr()` already handled this:

```lua
if seen[v] then
    rslt[#rslt + 1] = "<cycle>"
end
```

That is the better approach.

---

## 5. Table traversal order is random

Using:

```lua
pairs(v)
```

means:

```lua
{
a=1,
b=2
}
```

may output:

```
b2a1
```

or:

```
a1b2
```

For debugging this may be acceptable, but deterministic output is often preferable.

---

## 6. Mixed responsibilities

This line:

```lua
appendVal(GetString(v))
```

means `tclstr()` is doing two jobs:

1. Convert Lua values to strings.
2. Interpret numbers as ESO string IDs.

Those should probably be separate.

---

# Comparison with `tcstr()`

Your previous `tcstr()` is significantly better.

| Feature           | `tclstr()`    | `tcstr()` |
| ----------------- | ------------- | --------- |
| Handles nil       | ⚠️ false bug  | ✅         |
| Handles tables    | ⚠️ incomplete | ✅         |
| Handles cycles    | ❌             | ✅         |
| Recursive         | ⚠️ broken     | ✅         |
| Stable behavior   | ⚠️            | ✅         |
| Function handling | ✅ safer       | ⚠️ risky  |
| Performance       | ✅             | ✅         |

---

# Recommended rewrite

I would make `tclstr()` a thin wrapper around your existing traversal:

```lua
local function tclstr(rslt, ...)
    tcstr(
        sfutil.iterToStack(...),
        rslt,
        {}
    )
end
```

or better, eliminate it and keep one canonical formatter.

---

# If you keep this implementation, minimum fixes

```lua
local function tclstr(rslt, ...)

    local function appendVal(val)
        rslt[#rslt+1] = tostring(val)
    end

    for _, v in sfutil.iter_args(...) do

        local t_v = type(v)

        if v == nil then
            appendVal("(nil)")

        elseif t_v == "table" then
            for k, v1 in pairs(v) do
                appendVal(k)
                if type(v1) == "table" then
                    tclstr(rslt, v1)
                else
                    appendVal(v1)
                end
            end

        elseif t_v ~= "function" then
            appendVal(v)
        end
    end
end
```

This fixes the major bugs, but it still lacks cycle detection.

---

## Recommendation for LibSFUtils

I would **not keep both `tclstr()` and `tcstr()`**.

`tcstr()` is the stronger foundation. I would:

* rename `tcstr()` to something internal like `_appendStringValues()`
* build `sfutil.str()` and `sfutil.dstr()` on top of it
* remove `tclstr()`

The duplicate string walkers will eventually diverge and produce inconsistent output.
