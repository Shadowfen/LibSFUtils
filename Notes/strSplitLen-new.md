To add:

```lua
sfutil.strSplitLen(text, 1800, true)
```

where the third argument enables **word-boundary splitting**, you would add an optional parameter such as `splitWords`.

The idea:

1. Split at `maxlen` normally.
2. If `splitWords == true`, look backward from the split point.
3. If a whitespace boundary exists nearby, split there instead.
4. Continue with the remaining text.

A simple implementation:

```lua
function sfutil.strSplitLen(str, maxlen, splitWords)

    if type(str) ~= "string" then
        return nil, "sfutil.strSplitLen: expected string"
    end

    maxlen = tonumber(maxlen) or 1800

    if maxlen <= 0 then
        maxlen = 1800
    end

    local result = {}
    local length = zo_strlen(str)

    local start = 1

    while start <= length do

        local remaining = length - start + 1

        -- Remaining text fits
        if remaining <= maxlen then
            result[#result + 1] =
                zo_strsub(str, start, length)
            break
        end

        local finish = start + maxlen - 1

        -- Try to split at whitespace
        if splitWords then

            local chunk = zo_strsub(str, start, finish)

            -- Find the last whitespace in the chunk
            local split = nil

            for i = #chunk, 1, -1 do
                local c = chunk:sub(i, i)

                if c == " " or c == "\n" or c == "\t" then
                    split = i
                    break
                end
            end

            if split then
                finish = start + split - 1
            end
        end

        result[#result + 1] =
            zo_strsub(str, start, finish)

        start = finish + 1

        -- Skip leading whitespace on next chunk
        if splitWords then
            while start <= length do
                local c = zo_strsub(str, start, start)

                if c ~= " " and c ~= "\n" and c ~= "\t" then
                    break
                end

                start = start + 1
            end
        end
    end

    return result
end
```

## Example

Input:

```lua
local text =
    "This is a very long debug message that contains saved variables and should be displayed in chat."
```

Without word splitting:

```lua
sfutil.strSplitLen(text, 30)
```

might produce:

```
This is a very long debug mess
age that contains saved varia
bles and should be displayed i
n chat.
```

With:

```lua
sfutil.strSplitLen(text, 30, true)
```

produces:

```
This is a very long debug
message that contains saved
variables and should be
displayed in chat.
```

---

## Improvements I would add for ESO

For a production ESO library, I would probably make the third parameter a table instead of a boolean:

```lua
sfutil.strSplitLen(text, 1800, {
    splitWords = true,
    preserveNewlines = true,
})
```

because future options are likely:

```lua
{
    splitWords = true,
    splitColorCodes = false,
    maxLines = 10,
    trimWhitespace = true,
}
```

The biggest ESO-specific issue is **color codes**. If the text contains:

```lua
"|cFFFF00Warning|r"
```

a naive split can break the color sequence. Since `sfutil` already has color parsing utilities (`getAllColorDelim`, `regularizeColors`, `colorsplit`), a robust `strSplitLen()` could preserve active color state across chunks. That would make it much safer for chat output.
