## Evaluation of `sfutil.arrayMerge()`

`sfutil.arrayMerge()` is a good companion to `sfutil.tableMerge()`, but it solves a different problem. This function performs an **array concatenation with a copied first array**, not a key-based merge.

The intended behavior:

```text
table1 values
      +
table2 values
      |
      v
new array
```

Example:

```lua
local a =
{
    "one",
    "two",
}

local b =
{
    "three",
    "four",
}

local c = sfutil.arrayMerge(a, b)
```

Result:

```lua
{
    "one",
    "two",
    "three",
    "four",
}
```

---

# Summary Rating

| Area              | Rating |
| ----------------- | ------ |
| Correctness       | ⭐⭐⭐⭐⭐  |
| Performance       | ⭐⭐⭐⭐⭐  |
| ESO compatibility | ⭐⭐⭐⭐⭐  |
| API clarity       | ⭐⭐⭐⭐   |
| Edge cases        | ⭐⭐⭐    |
| Documentation     | ⭐⭐⭐⭐   |

---

# Strengths

## 1. Correct non-destructive behavior

This is the right design:

```lua
merged = ZO_ShallowTableCopy(table1)
```

The original table is not modified.

Example:

```lua
local original =
{
    1,
    2,
}

local result = sfutil.arrayMerge(original, {3})
```

`original` remains:

```lua
{
    1,
    2,
}
```

Good.

---

## 2. Efficient append implementation

This is efficient:

```lua
local cnt = #merged

for idx, value2 in ipairs(table2) do
    merged[cnt + idx] = value2
end
```

It avoids repeated:

```lua
table.insert(merged, value)
```

which has function-call overhead.

The indexing approach is the preferred Lua style for performance-sensitive code.

---

## 3. Correctly preserves table1 precedence

Unlike `tableMerge()`, this function does not care about keys.

It simply appends.

Example:

```lua
table1 =
{
    [1] = "A",
    [2] = "B",
}

table2 =
{
    [1] = "C",
}
```

Result:

```lua
{
    [1] = "A",
    [2] = "B",
    [3] = "C",
}
```

Correct.

---

# Issues

## 1. The word "merge" may be misleading

This function is really:

```text
array concatenation
```

not merging.

The name:

```lua
sfutil.arrayMerge()
```

is acceptable, but alternatives might be clearer:

```lua
sfutil.arrayAppend()
```

or:

```lua
sfutil.arrayConcat()
```

Lua already has the concept:

```lua
table.concat()
```

though that is string-only, so `arrayConcat()` may be slightly confusing.

For consistency with:

```lua
sfutil.tableMerge()
```

keeping `arrayMerge()` is reasonable.

---

# 2. It assumes sequential arrays

This line:

```lua
for idx, value2 in ipairs(table2) do
```

only processes contiguous numeric keys.

Example:

```lua
local t =
{
    [1] = "a",
    [3] = "c",
}
```

`ipairs()` returns only:

```text
1 -> a
```

It ignores index 3.

That is correct for an array utility, but should be documented.

---

# 3. It does not handle holes in table1 well

Example:

```lua
local t =
{
    "a",
    nil,
    "c",
}
```

Then:

```lua
#merged
```

is undefined.

The append position:

```lua
cnt = #merged
```

may not be what the caller expects.

For proper arrays this is fine.

For arbitrary tables, it is not.

---

# 4. Nested tables remain shared

Like `tableMerge()`:

```lua
ZO_ShallowTableCopy()
```

is shallow.

Example:

```lua
local a =
{
    {
        value = 10
    }
}

local b = sfutil.arrayMerge(a, {})
```

Now:

```lua
b[1] == a[1]
```

Changing:

```lua
b[1].value = 20
```

also changes:

```lua
a[1].value
```

Expected, but worth documenting.

---

# 5. Slightly unnecessary branch

Current:

```lua
if not table1 or type(table1) ~= "table" then
```

can simply be:

```lua
if type(table1) ~= "table" then
```

because:

```lua
type(nil)
```

is already safe.

---

# Suggested Version

A slightly cleaner version:

```lua
function sfutil.arrayMerge(table1, table2)

    local merged = {}

    if type(table1) == "table" then
        merged = ZO_ShallowTableCopy(table1)
    end

    if type(table2) == "table" then

        local offset = #merged

        for i, value in ipairs(table2) do
            merged[offset + i] = value
        end

    end

    return merged
end
```

Same behavior, simpler flow.

---

# Comparison with `tableMerge()`

| Function           | Behavior      |
| ------------------ | ------------- |
| `tableMerge()`     | Combine keys  |
| `arrayMerge()`     | Append values |
| Conflict handling  | table1 wins   |
| Key preservation   | yes           |
| Order preservation | no            |
| Array order        | yes           |

Example:

### `tableMerge`

```lua
{
    a = 1,
    b = 2
}
+
{
    b = 3,
    c = 4
}
```

Result:

```lua
{
    a = 1,
    b = 2,
    c = 4
}
```

---

### `arrayMerge`

```lua
{
    "a",
    "b"
}
+
{
    "c",
    "d"
}
```

Result:

```lua
{
    "a",
    "b",
    "c",
    "d"
}
```

---

# Recommended Documentation Addition

I would add:

```markdown
## Notes

- `arrayMerge()` expects sequential numeric arrays.
- The returned table is a shallow copy.
- Nested tables are shared between the original and merged arrays.
- The original tables are not modified.
- Values from `table2` are always appended after values from `table1`.
```

---

# Final Recommendation

`sfutil.arrayMerge()` is a solid utility and fits well beside `tableMerge()`.

I would keep it with only minor changes:

1. Simplify the type checks.
2. Document that it only supports sequential arrays.
3. Consider renaming to `arrayAppend()` if you want the behavior to be immediately obvious.

For ESO addon work (saved variables, dropdown lists, command lists, defaults), this implementation is efficient and appropriate.
