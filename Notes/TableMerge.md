## Evaluation of `sfutil.tableMerge()`

`sfutil.tableMerge()` is a clean and useful utility. The behavior is clearly defined:

> Create a new table containing keys from both tables. If the same key exists in both tables, the value from `table1` wins.

This is a **left-biased shallow merge**.

Overall, this is a good implementation for ESO addon configuration/default handling.

---

# Summary Rating

| Area               | Rating |
| ------------------ | ------ |
| Correctness        | ⭐⭐⭐⭐⭐  |
| Performance        | ⭐⭐⭐⭐⭐  |
| ESO compatibility  | ⭐⭐⭐⭐⭐  |
| API clarity        | ⭐⭐⭐⭐   |
| Edge-case handling | ⭐⭐⭐⭐   |
| Documentation      | ⭐⭐⭐⭐   |

---

# Behavior

Example:

```lua
local defaults =
{
    enabled = true,
    color = "yellow",
    size = 10,
}

local settings =
{
    color = "red",
    alpha = 50,
}
```

Call:

```lua
local result = sfutil.tableMerge(defaults, settings)
```

Result:

```lua
{
    enabled = true,
    color = "yellow",
    size = 10,
    alpha = 50,
}
```

Because:

```lua
table1 wins
```

---

# Strengths

## 1. Correct left-biased merge

This is the important part:

```lua
if merged[key2] == nil then
    merged[key2] = value2
end
```

It preserves table1 values.

Example:

```lua
table1 =
{
    x = 10
}

table2 =
{
    x = 20
}
```

Result:

```lua
{
    x = 10
}
```

Correct.

---

## 2. Does not modify inputs

This is good:

```lua
merged = ZO_ShallowTableCopy(table1)
```

The caller's table is not changed.

That is what a merge function should normally do.

---

## 3. Efficient implementation

The algorithm:

1. Copy table1.
2. Iterate table2 once.
3. Add missing keys.

Complexity:

```
O(table1 + table2)
```

Good.

---

## 4. Good handling of missing tables

This is useful:

```lua
sfutil.tableMerge(nil, settings)
```

returns:

```lua
{
    -- copy of settings
}
```

and:

```lua
sfutil.tableMerge(nil, nil)
```

returns:

```lua
{}
```

This makes it convenient for optional configuration tables.

---

# Issues / Possible Improvements

## 1. The name could be more explicit

"Merge" can mean different things.

Possible interpretations:

### Current behavior:

```text
table1 overrides table2
```

### Alternative:

```text
table2 overrides table1
```

Many libraries call that:

```lua
merge(defaults, overrides)
```

where the second table wins.

Your behavior is actually:

```lua
merge(preferred, fallback)
```

A clearer name might be:

```lua
tableMergePreferFirst()
```

or:

```lua
tableMergeLeft()
```

However, if this is existing API, keeping `tableMerge()` is reasonable.

---

## 2. Shallow copy behavior should be documented more prominently

The documentation says:

> Performs shallow copies

Good.

But users need to understand:

```lua
local a =
{
    options =
    {
        enabled = true
    }
}

local b = sfutil.tableMerge(a, {})
```

The result:

```lua
result.options == a.options
```

They are the same table.

Changing:

```lua
result.options.enabled = false
```

also changes:

```lua
a.options.enabled
```

This is expected for shallow merge, but worth highlighting.

---

## 3. Type checking style could be simplified

Current:

```lua
if not table2 or type(table2) ~= "table" then
```

works.

But:

```lua
if type(table2) ~= "table" then
```

already catches nil:

```lua
type(nil)
```

returns:

```text
nil
```

So:

```lua
if type(table2) ~= "table" then
```

is enough.

Same here:

```lua
if not table1 or type(table1) ~= "table"
```

could become:

```lua
if type(table1) ~= "table"
```

---

## 4. Could accept metatables?

`ZO_ShallowTableCopy()` behavior matters.

If table1 has:

```lua
__index
```

or other metatable behavior, the copy probably does not preserve it.

Usually correct for saved variables, but worth noting.

---

## 5. `ZO_ShallowTableCopy()` dependency

Because this is LibSFUtils, depending on ESO's:

```lua
ZO_ShallowTableCopy()
```

is appropriate.

If this utility were moved outside ESO, you would need:

```lua
local function shallowCopy(tbl)
    local result = {}
    for k,v in pairs(tbl) do
        result[k]=v
    end
    return result
end
```

For ESO this is fine.

---

# Possible Revised Implementation

Slightly cleaner:

```lua
function sfutil.tableMerge(table1, table2)

    local merged = {}

    if type(table1) == "table" then
        merged = ZO_ShallowTableCopy(table1)
    end

    if type(table2) == "table" then
        for key, value in pairs(table2) do
            if merged[key] == nil then
                merged[key] = value
            end
        end
    end

    return merged
end
```

Advantages:

* One exit point.
* Easier to read.
* Same behavior.

---

# ESO Use Cases

This function is particularly useful for:

## Defaults

```lua
settings = sfutil.tableMerge(
    userSettings,
    defaultSettings
)
```

where existing user choices win.

---

## Profile overlays

Example:

```lua
activeProfile =
    sfutil.tableMerge(
        characterSettings,
        accountDefaults
    )
```

---

## Migration helpers

Combining old and new structures:

```lua
newSettings =
    sfutil.tableMerge(
        oldSettings,
        migrationDefaults
    )
```

---

# Final Recommendation

I would keep this function.

The only changes I would consider:

1. Simplify the type checks.
2. Expand documentation to emphasize **shallow copy**.
3. Consider documenting the precedence rule prominently:

```markdown
When a key exists in both tables, table1 always wins.
```

The implementation is already suitable for LibSFUtils and fits ESO addon patterns well.
