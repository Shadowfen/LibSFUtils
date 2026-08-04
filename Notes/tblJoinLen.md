## Evaluation of `sfutil.tblJoinLen()`

`tblJoinLen()` is a useful companion to `strSplitLen()`, but the current implementation has a few API and design issues that are worth addressing before making it a library utility.

The overall concept is good:

```
table of fragments
        |
        v
normalize values
        |
        v
table.concat()
        |
        v
(optional) split into chunks
```

This is a common pattern for ESO chat/log output.

---

# Strengths

## 1. Good use case separation

The function has a clear purpose:

* `tblJoinLen()` → assemble fragments.
* `strSplitLen()` → split oversized output.

That makes code like this possible:

```lua
local chunks = sfutil.tblJoinLen(logLines, 1800)

for _, msg in ipairs(chunks) do
    ZOS_addSystemMsg(msg)
end
```

---

## 2. Efficient concatenation

This is correct:

```lua
joined = table.concat(tbl, "")
```

Using:

```lua
str = str .. value
```

inside a loop would repeatedly allocate strings.

`table.concat()` is the correct Lua approach.

---

## 3. Handles mixed value types

This:

```lua
tbl[i] = tostring(v)
```

allows:

```lua
{
    "Level:",
    50,
    true
}
```

to become:

```text
Level:50true
```

which is useful for diagnostic output.

---

## 4. Integrates well with `strSplitLen`

This is a good design:

```lua
return sfutil.strSplitLen(joined, maxlen)
```

It avoids duplicate splitting logic.

---

# Issues

## 1. It modifies the caller's table

This is the biggest issue.

The function does:

```lua
tbl[i] = tostring(v)
```

If the caller has:

```lua
local values =
{
    10,
    true,
    {}
}

sfutil.tblJoinLen(values)
```

after the call:

```lua
values =
{
    "10",
    "true",
    "table: 0x..."
}
```

The original data is changed.

That is surprising for a utility named `tblJoinLen()`.

---

## Recommendation

Do not modify the input table.

Instead:

```lua
local parts = {}

for i = 1, #tbl do
    local v = tbl[i]

    if v == nil then
        parts[i] = "(nil)"
    else
        parts[i] = tostring(v)
    end
end

joined = table.concat(parts, "")
```

---

# 2. Return type inconsistency

Like `strSplitLen()`, it returns different types:

Short:

```lua
"some text"
```

Long:

```lua
{
    "chunk1",
    "chunk2"
}
```

Caller must check:

```lua
if type(result) == "table" then
```

This makes chaining harder.

Example:

```lua
chat.d(sfutil.tblJoinLen(lines))
```

works sometimes, fails if the result becomes a table.

---

## Recommendation

Consider always returning a table when splitting is requested:

```lua
sfutil.tblJoinLen(lines, 1800)
```

returns:

```lua
{
    "message"
}
```

even if short.

---

# 3. `tbl` can be a string

Currently:

```lua
if type(tbl) == "string" then
```

accepts:

```lua
sfutil.tblJoinLen("hello")
```

This is convenient, but the name implies:

```
tblJoinLen()
```

expects a table.

Possible alternatives:

### Option A: Keep it

Document that strings are accepted.

### Option B: Rename

Something like:

```lua
sfutil.joinLen()
```

would better describe the behavior.

---

# 4. Nil table entries are not actually preserved

This code:

```lua
for i = 1, #tbl do
```

has a Lua limitation.

Example:

```lua
local t =
{
    "a",
    nil,
    "b"
}
```

Lua considers:

```lua
#t
```

undefined.

The loop may only process:

```text
a
```

depending on the table layout.

If preserving nils matters, the function needs an explicit length:

```lua
tbl.n
```

or use an iterator.

For normal string fragment arrays this is probably fine.

---

# 5. Empty separator is hardcoded

Currently:

```lua
table.concat(tbl, "")
```

Always joins with no separator.

That is fine for logs:

```lua
{
    "A",
    "B"
}
```

→

```
AB
```

But many callers might expect:

```lua
{
    "A",
    "B"
}
```

→

```
A B
```

or:

```
A\nB
```

---

A more flexible API:

```lua
sfutil.tblJoinLen(tbl, maxlen, separator)
```

Example:

```lua
sfutil.tblJoinLen(lines, 1800, "\n")
```

---

# Suggested Revised Version

I would write it like this:

```lua
function sfutil.tblJoinLen(tbl, maxlen, sep)

    if tbl == nil then
        return nil
    end

    sep = sep or ""

    if type(maxlen) ~= "number" or maxlen < 1 then
        maxlen = nil
    end

    local joined

    if type(tbl) == "string" then

        joined = tbl

    elseif type(tbl) == "table" then

        local parts = {}

        for i = 1, #tbl do
            local v = tbl[i]

            if v == nil then
                parts[i] = "(nil)"
            else
                parts[i] = tostring(v)
            end
        end

        joined = table.concat(parts, sep)

    else
        return nil
    end

    if maxlen then
        return sfutil.strSplitLen(joined, maxlen)
    end

    return joined
end
```

---

# Overall Rating

| Area               | Rating |
| ------------------ | ------ |
| Concept            | ⭐⭐⭐⭐⭐  |
| Performance        | ⭐⭐⭐⭐   |
| ESO usefulness     | ⭐⭐⭐⭐⭐  |
| API consistency    | ⭐⭐⭐    |
| Side-effect safety | ⭐⭐     |
| Robustness         | ⭐⭐⭐    |

---

## Recommendation

I would keep the function, but change:

1. **Do not modify the input table.**
2. Add optional separator support.
3. Decide whether split functions always return tables or mixed types.
4. Consider renaming to `joinLen()` if strings remain supported.

For ESO addon utilities, this function is a good companion to `strSplitLen()` and would be especially useful for building chat/log output from accumulated message fragments.
