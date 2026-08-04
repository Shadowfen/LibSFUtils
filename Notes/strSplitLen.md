## Evaluation of `sfutil.strSplitLen()`

Overall, `strSplitLen()` is a useful and simple utility, but there are a few design choices that are worth reconsidering before making it part of a public library API.

The implementation is **good for ESO chat/debug output**, but it has limitations around **string length semantics**, **return consistency**, and **message splitting behavior**.

---

# Strengths

## 1. Good fast path

This is a good optimization:

```lua
local length = zo_strlen(str)
if length <= maxlen then
    return str
end
```

Most chat messages are short. Avoiding table allocation for normal messages is worthwhile.

---

## 2. Sensible default

```lua
maxlen = maxlen or 1800
```

Using `1800` is reasonable for ESO chat.

ESO's actual limits can vary depending on the API and context, so leaving some margin is safer than using the maximum.

---

## 3. Simple and predictable behavior

The splitting algorithm:

```lua
while i <= length do
    j = math.min(i + maxlen - 1, length)
    table.insert(result, zo_strsub(str, i, j))
    i = j + 1
end
```

is easy to understand.

It guarantees:

```text
table.concat(result) == original string
```

assuming `zo_strsub()` uses the same indexing behavior as expected.

---

## 4. ESO API compatibility

Using:

```lua
zo_strlen()
zo_strsub()
```

is appropriate for an ESO library.

ESO has historically had special handling around UTF-8 strings, so using ZOS functions is preferable to raw Lua string functions in addon code.

---

# Issues / Improvements

## 1. Return type inconsistency

Currently:

```lua
return str
```

for short strings.

but:

```lua
return result
```

for long strings.

This means callers must always check:

```lua
if type(result) == "table" then
```

That makes the API less convenient.

A cleaner API would always return a table:

```lua
{
    "message"
}
```

or always return an iterator.

Example:

```lua
for _, part in ipairs(sfutil.strSplitLen(msg)) do
    send(part)
end
```

works regardless of length.

### Recommendation

Change:

```lua
if length <= maxlen then
    return str
end
```

to:

```lua
if length <= maxlen then
    return {str}
end
```

---

## 2. Name suggests length, but it is byte/character ambiguous

Your documentation says:

> bytes

but the implementation uses:

```lua
zo_strlen()
```

ESO string functions are UTF-8 aware, but the exact behavior matters.

For example:

```lua
"é"
```

may occupy:

* 1 displayed character
* 2 UTF-8 bytes

Chat limits may care about encoded size rather than displayed characters.

The documentation should say either:

* "characters according to ESO string functions"

or

* "string length as reported by `zo_strlen()`"

rather than "bytes".

---

## 3. Splits in the middle of words

Example:

```text
This is a very long message about saved variables...
```

could become:

```
This is a very long message about sav
ed variables...
```

For debug output this is acceptable.

For user-facing messages, it is less ideal.

A better version could optionally support:

```lua
sfutil.strSplitLen(text, 1800, true)
```

where it searches backward for:

* space
* newline
* punctuation

before splitting.

---

## 4. Error handling is questionable

Currently:

```lua
if type(str) ~= "string" then
    str = "sfutil.strSplitLen: first argument must be a string"
end
```

This silently converts an error into output.

Example:

```lua
sfutil.strSplitLen(nil)
```

returns:

```
sfutil.strSplitLen: first argument must be a string
```

This may hide programming mistakes.

Other options:

### Option A: Assert

```lua
assert(type(str) == "string",
       "sfutil.strSplitLen requires a string")
```

Better for development.

---

### Option B: Return nil/error

```lua
if type(str) ~= "string" then
    return nil, "string expected"
end
```

Better for library code.

---

### Option C: Keep current behavior

Acceptable for chat/debug utilities.

---

## 5. Minor allocation issue

This:

```lua
table.insert(result, ...)
```

is slower than:

```lua
result[#result + 1] = ...
```

For a frequently called utility:

Prefer:

```lua
result[#result + 1] = zo_strsub(str, i, j)
```

---

# Suggested Revised Version

For a library, I would lean toward:

```lua
function sfutil.strSplitLen(str, maxlen)

    if type(str) ~= "string" then
        return nil, "sfutil.strSplitLen: expected string"
    end

    maxlen = tonumber(maxlen) or 1800

    if maxlen <= 0 then
        maxlen = 1800
    end

    local result = {}

    local length = zo_strlen(str)

    if length <= maxlen then
        result[1] = str
        return result
    end

    local i = 1

    while i <= length do
        local j = math.min(i + maxlen - 1, length)

        result[#result + 1] =
            zo_strsub(str, i, j)

        i = j + 1
    end

    return result
end
```

---

# Overall Rating

| Area                 | Rating |
| -------------------- | ------ |
| Simplicity           | ⭐⭐⭐⭐⭐  |
| ESO compatibility    | ⭐⭐⭐⭐⭐  |
| Performance          | ⭐⭐⭐⭐   |
| API consistency      | ⭐⭐⭐    |
| User-facing messages | ⭐⭐⭐    |
| Debug/log output     | ⭐⭐⭐⭐⭐  |

## Recommendation

For **LibSFUtils**, I would keep it but make two changes:

1. **Always return a table** (`{str}` for short strings).
2. Clarify documentation: it splits according to `zo_strlen()` units, not necessarily bytes.

For an ESO addon debugging utility, the current implementation is already very practical. For a general-purpose public API, the return-type inconsistency is the main thing I would fix.
