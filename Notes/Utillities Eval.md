This is a solid general-purpose utility library, especially for an ESO/Lua 5.1 environment. It has a lot of practical helpers that avoid allocations where possible and work around the limitations of Lua 5.1. After reading through it, here are the things that stand out.

## Overall Assessment

**Strengths**

* Consistent coding style.
* Good inline documentation.
* Written for Lua 5.1 instead of assuming 5.2+ features.
* Several functions intentionally avoid unnecessary allocations (`safeCall10`, `iter_args`).
* Good separation between generic utilities and ESO-specific helpers.
* Most functions are small and focused.

**Areas I'd improve**

* A few functions contain bugs.
* Some implementations can be simplified.
* A few names don't match Lua conventions.
* There is some duplicated code.

---

# High Priority Issues

## 1. `closure()` ignores the extra arguments

The function signature is

```lua
function sfutil.closure(callback, tblself, ...)
```

but the extra arguments are never used.

```lua
return function(...)
    return callback(tblself, ...)
end
```

Either remove the unused `...`

```lua
function sfutil.closure(callback, tblself)
```

or make it support partial application.

Example:

```lua
function sfutil.closure(callback, tblself, ...)
    local bound = {...}

    return function(...)
        local args = {}

        local n = #bound
        for i=1,n do
            args[i] = bound[i]
        end

        local m = select("#", ...)
        for i=1,m do
            args[n+i] = select(i,...)
        end

        return callback(tblself, unpack(args))
    end
end
```

---

## 2. `str2bool()` crashes on nil

Current implementation:

```lua
string.lower(str)
```

If

```lua
str=nil
```

you get

```
attempt to index a nil value
```

Safer:

```lua
function sfutil.str2bool(str)
    if type(str) ~= "string" then
        return false
    end

    str = string.lower(str)

    return str=="true" or str=="1"
end
```

---

## 3. `secondsToClock()`

If

```lua
seconds=nil
```

then

```lua
tonumber(nil)
```

returns nil

and

```lua
seconds <= 0
```

throws an error.

Safer:

```lua
seconds = tonumber(seconds) or 0
```

---

## 4. `WrapFunction()`

This assumes

```lua
namespace[functionName]
```

is a function.

It should verify it.

```lua
assert(type(namespace[functionName])=="function")
```

Otherwise strange errors occur later.

---

# Medium Priority

## `iter_args()`

Very nice.

I like that it returns

```
index
value
total
```

every iteration.

One tiny optimization:

```lua
local unpack = unpack
```

is unnecessary since you're not unpacking.

Nothing I'd change here.

---

## `safeCall10`

This is clever.

Avoiding the temporary table is worthwhile in ESO.

The only drawback is obvious:

```
11th return value disappears.
```

That's already documented.

I'd keep it.

---

## `safeCall`

Good implementation.

One thing I'd do:

```lua
local unpack = unpack
```

at module scope.

Lua global lookup is slightly slower.

---

## `bool2str`

Could simply be

```lua
return sfutil.isTrue(bool) and "true" or "false"
```

although yours is perfectly readable.

---

## `isTrue`

This is intentionally different from Lua semantics.

I like the documentation.

I'd perhaps rename it

```
isExplicitTrue
```

or

```
isTruthyValue
```

because

```
isTrue()
```

suggests Lua truthiness.

---

## `nilDefault`

Very useful.

Equivalent to

```lua
if val==nil then
```

Exactly what you want.

---

## `nilDefaultStr`

Could simply be

```lua
if val==nil or val=="" then
```

---

# `addonChatter`

This class is nice.

I especially like

```lua
o.d=function(...)
end
```

instead of testing

```lua
if debug then
```

every call.

That's a classic optimization.

---

One thing:

`debugMsg()` duplicates almost all the code in

```
enableDebug()
```

Instead:

```lua
function sfutil.addonChatter:enableDebug()

    self.isdbgon=true

    function self.d(...)
        ...
    end
end

function sfutil.addonChatter:debugMsg(...)
    self.d(...)
end
```

Then all formatting lives in one place.

---

# String splitting

`gsplit()` is well written.

I especially like that it handles

```
"a,,b"
```

correctly.

Many split implementations don't.

---

# Color parser

This is the most interesting part of the library.

You've clearly spent time dealing with ESO's

```
|cXXXXXX
|r
```

markers.

The pipeline

```
getAllColorDelim()

↓

regularizeColors()

↓

stripColors()

↓

colorsplit()
```

is clean.

I'd probably make these local/private if they aren't intended as public API.

---

# DDValueTable

This is another nice abstraction.

Instead of managing

```
choices
choiceValues
tooltips
```

independently,

everything lives in one table.

That's a good design.

---

The downside is code duplication.

These functions are almost identical:

```
choices()

choicesAll()

choiceValues()

choiceValuesAll()

choiceTooltips()

choiceTooltipsAll()

choicesNvalues()

choicesNvaluesAll()
```

They could probably be reduced to two or three generic helper functions.

---

# Minor Style Suggestions

Instead of

```lua
if (condition) then
```

Lua style is usually

```lua
if condition then
```

Likewise

```lua
return (a)
```

↓

```lua
return a
```

This is purely stylistic.

---

Instead of

```lua
function(...)
    end
```

I'd write

```lua
function() end
```

when arguments aren't used.

---

Avoid repeated globals:

```lua
local table_insert = table.insert
local string_find = string.find
local string_sub = string.sub
```

inside hot functions.

You've already done this in several places.

---

# Things I Particularly Like

Some utilities are especially nice and not commonly seen:

* `iter_args()` — lightweight vararg iterator for Lua 5.1.
* `safeCall10()` — avoids table allocation while preserving multiple returns.
* `WrapFunction()` — useful for instrumentation and hook systems.
* `DDValueTable` — a clean solution for managing LibAddonMenu dropdown metadata.
* `addonChatter` — encapsulates colored chat output and debug handling.
* The color parsing pipeline — sophisticated handling of nested ESO chat color markers.

# Overall Rating

For an ESO utility library targeting Lua 5.1, I'd rate it:

| Category              | Rating |
| --------------------- | -----: |
| API design            | 9.5/10 |
| Readability           |   9/10 |
| Documentation         |   9/10 |
| Lua 5.1 compatibility |  10/10 |
| Performance           | 9.5/10 |
| Robustness            |   8/10 |
| Maintainability       | 8.5/10 |

**Overall: 9.2/10**

The library reflects a mature codebase with thoughtful utilities for the ESO addon ecosystem. My primary recommendations would be to fix the handful of robustness issues (`str2bool`, `secondsToClock`, `WrapFunction` validation), eliminate some duplicated code (particularly in `DDValueTable`), and tighten a few APIs such as `closure()`. Those changes would improve maintainability without changing the public behavior.
