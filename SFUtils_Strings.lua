--[[ This module provides high-performance string construction and formatting tools. It 
    addresses common ESO addon challenges such as:

        Performance: Avoiding slow string concatenation loops by using table.concat.
        Localization: Automatically resolving numeric string IDs via GetString.
        Safety: Handling nil values, circular table references, and oversized strings.
        Rich Text: Easily generating ESO color tags (|c...|r) and icon tags (|t...|t).

    Technical Notes

    Pooled Memory: Functions like sfutil.str, sfutil.lstr, and sfutil.dstr use a global rslt_pool 
        table to reduce allocations. They manually clear this table before use. This is safe in 
        single-threaded Lua but requires care if used in a multi-threaded environment (not applicable to ESO).
    Circular Reference Handling: sfutil.str and sfutil.dstr track visited tables in a seen table. 
        If a cycle is detected, it outputs "<cycle>" instead of crashing or looping infinitely.
    Table Expansion: When a table is passed to str/lstr/dstr, it is flattened. Keys and values 
        are appended sequentially.
        { a = 1, b = 2 } becomes "a1b2".
    Function Ignoring: Functions are never executed in str/lstr/dstr. If you need to execute a 
        function, use sfutil.GetText or call it manually before passing to str.
--]]

local sfutil = LibSFUtils
assert(sfutil, "LibSFUtils_Global must be loaded before this file")

--[[ --------------------- sfutil.NilPack() packs a variable number of arguments into a table while preserving 
    both the number of arguments and any nil values.

    Unlike a simple table constructor ({...}), which loses trailing nil values and cannot 
    distinguish between omitted arguments and explicit nil arguments, NilPack() records the 
    original argument count so the values can later be restored exactly using protected.NilUnpack().

    Returns a table containing:
        Field	Description
        n	    The original number of arguments passed.
        1...n	The packed argument values.

    The n field is essential because Lua's length operator (#) cannot reliably determine the 
    length of tables containing nil values.
--]]
function sfutil.NilPack(...) 
    return {n=select('#', ...), ...}
end

function sfutil.NilUnpack(t) 
    return unpack(t, 1, t.n)
end


--[[ --------------------- tcstr_tail(pending, rslt, seen)
    Concatenate varargs to a string

	To improve speed of ".." concatenation, we add the
	arguments to a table and do a concat on it.

	Value conversions:
	* Numeric arguments are converted to string equivalents:
	  i.e 16 -> "16".
	* The elements of table arguments are recursively added.
	* nil is converted to "(nil)"
	* Everything else is run through tostring()
]]
-- Tail‑recursive worker: `pending` is a list of values still to process.
local function tcstr_tail(pending, rslt, seen)
    if pending.n == 0 then return rslt end

    local v = table.remove(pending, 1)
    pending.n = pending.n - 1

    if v == nil then
        rslt[#rslt + 1] = "(nil)"
        return tcstr_tail(pending, rslt, seen)

    elseif type(v) == "table" then
        if seen[v] then
            rslt[#rslt + 1] = "<cycle>"
        else
            seen[v] = true
            for k, v1 in pairs(v) do
                rslt[#rslt + 1] = tostring(k)   -- Always stringify key

                local vt = type(v1)
                if vt == "table" then
                    pending.n = pending.n + 1
                    pending[pending.n] = v1     -- Recurse on nested tables
                elseif vt == "nil" then
                    rslt[#rslt + 1] = "(nil)"
                elseif vt == "function" then
                    rslt[#rslt + 1] = "<function>"
                else
                    -- Primitives (string, number, boolean) → rslt
                    -- Functions skipped (contribute "")
                    rslt[#rslt + 1] = tostring(v1)
                end
            end
        end
        return tcstr_tail(pending, rslt, seen)

    elseif type(v) == "function" then
        rslt[#rslt + 1] = "<function>"
        return tcstr_tail(pending, rslt, seen)

    else
        rslt[#rslt + 1] = tostring(v)
        return tcstr_tail(pending, rslt, seen)
    end
end
--[[ --------------------- sfutil.str(...)

    Concatenates multiple arguments into a single string efficiently.

        Behavior:
            Numbers: Converted to strings via tostring.
            Tables: Recursively expanded. Keys and values are added to the output.
            Nil: Converted to the literal string "(nil)".
            Functions: Ignored (not executed).
            Circular References: Detected and replaced with "<cycle>" to prevent infinite loops.
        Optimization: Uses a tail-recursive helper and a pooled result table to minimize garbage collection.
        Returns: A single concatenated string.
---
	Similar to sfutil.str except that it will try to convert the
	numeric arguments in the argument list into strings using the
	GetString() function.

	To improve on the speed of ".." concatenation, we add the
	arguments to a table and do a concat on the table.

	Value conversions:
	* Numeric arguments are run through the GetString function:
	  i.e 16 -> GetString(16).
	* The elements of table arguments are recursively added.
	* nil is converted to "(nil)"
	* Everything else is run through tostring()
--]]
local rslt_pool = {}        -- Allocate the table ONCE at module load
function sfutil.str(...)
    -- Manually clear the reused table
    for k in pairs(rslt_pool) do
        rslt_pool[k] = nil
    end

    local pending = sfutil.NilPack(...)

    -- Pass the cleared table to the tail-call helper
    tcstr_tail(pending, rslt_pool, {})

    return table.concat(rslt_pool)
end

--[[ --------------------- sfutil.str1(...)

    Legacy version of sfutil.str. Uses a standard loop instead of tail recursion.

    Note: Prefer sfutil.str for better performance and circular reference safety.
--]]
function sfutil.str1(...)
    local nargs = select("#", ...)
    local arg = {}
    local sf_str = sfutil.str

    for i = 1, nargs do
        local v = select(i, ...)
        local t = type(v)
        if (v == nil) then
            arg[#arg + 1] = "(nil)"
        elseif (t == "table") then
            for k, v1 in pairs(v) do
                arg[#arg + 1] = k
                arg[#arg + 1] = sf_str(v1)
            end
        else
            arg[#arg + 1] = tostring(v)
        end
    end
    local s = table.concat(arg)
    return s
end

--[[ --------------------- tclstr(rslt, ...)
--]]
local function tclstr(rslt, ...)

    -- append another value to the result table
    local function appendVal(val)
        rslt[#rslt+1] = tostring(val)
    end

    for _, v in sfutil.iter_args(...) do
        local t_v = type(v)
        if v == nil then
            appendVal( "(nil)" )

        elseif t_v == "boolean" then
            appendVal(v)

        elseif t_v == "number" then
            appendVal(GetString(v))

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

--[[ --------------------- sfutil.lstr(...)

    Concatenates arguments, treating numbers as Localization IDs.

    Behavior:
        Numbers: Passed to GetString() to retrieve localized text.
        Tables: Recursively expanded (keys and values).
        Nil: Converted to "(nil)".
        Functions: Ignored.
    Use Case: Building debug logs or UI text where you want to mix raw strings and localized string IDs seamlessly.
---
	Similar to sfutil.str except that it will try to convert the
	numeric arguments in the argument list into strings using the
	GetString() function.

	To improve on the speed of ".." concatenation, we add the
	arguments to a table and do a concat on the table.

	Value conversions:
	* Numeric arguments are run through the GetString function:
	  i.e 16 -> GetString(16).
	* The elements of table arguments are recursively added.
	* nil is converted to "(nil)"
	* Everything else is run through tostring()
--]]
function sfutil.lstr(...)
    -- Manually clear the reused table (no table.wipe)
    for k in pairs(rslt_pool) do
        rslt_pool[k] = nil
    end

    -- Pass the cleared table to the helper function
    tclstr(rslt_pool, ...)

    return table.concat(rslt_pool)
end

--[[ --------------------- sfutil.lstr1(...)

    Legacy version of sfutil.lstr.
]]
function sfutil.lstr1(...)
    local nargs = select("#", ...)
    local arg = {}
    local sf_str = sfutil.lstr1

    for i = 1, nargs do
        local v = select(i, ...)
        local t = type(v)
        if v == nil then
            arg[#arg + 1] = "(nil)"

        elseif t == "number" then
            arg[#arg + 1] = GetString(v)

        elseif t == "table" then
            for k, v1 in pairs(v) do
                arg[#arg + 1] = k
                arg[#arg + 1] = sf_str(v1)
            end
        else
            arg[#arg + 1] = tostring(v)
        end
    end
    return table.concat(arg)
end

--[[ --------------------- tcdstr_tail(pending, delim, rslt, seen)
    Concatenate varargs to a delimited string.
	Similar to sfutil.str() except that a delimiter is
	placed between each of the values of the string - the
	arguments to the function and also between the items within
	a table that was passed in.

  nil -> ""
  table -> k v k v k v...
  function -> ignored
  other -> tostring
--]]
local function tcdstr_tail(pending, delim, rslt, seen)
    if pending.n == 0 then return rslt end

    local v = table.remove(pending, 1)
    pending.n = pending.n - 1

    if v == nil then
        rslt[#rslt + 1] = "(nil)"

    elseif type(v) == "table" then
        if seen[v] then
            rslt[#rslt + 1] = "<cycle>"
        else
            seen[v] = true
            for k, v1 in pairs(v) do
                rslt[#rslt + 1] = tostring(k)

                local vt = type(v1)
                if vt == "table" then
                    pending[#pending + 1] = v1
                    pending.n = pending.n + 1  -- ← MUST update count!
                elseif vt ~= "function" then
                    rslt[#rslt + 1] = tostring(v1)
                end
            end
        end

    elseif type(v) ~= "function" then
        rslt[#rslt + 1] = tostring(v)
    end

    return tcdstr_tail(pending, delim, rslt, seen)
end

--[[ --------------------- sfutil.dstr(delim, ...)

    Concatenates arguments with a delimiter inserted between every element.

    Parameters:
        delim (string): The separator (e.g., ", ", "|", "\n").
        ...: Variable arguments.
    Behavior:
        Similar to sfutil.str but inserts delim between every processed item.
        Nil: Converted to "(nil)".
        Tables: Expanded recursively; delimiters are placed between keys and values as well.
        Functions: Ignored.
    Returns: A single string with delimiters.
--]]
function sfutil.dstr(delim, ...)
    local rslt = {}
    local pending = sfutil.NilPack(delim, ...)

    -- Skip the delimiter in processing - just use it for concat
    pending.n = pending.n - 1  -- Remove delimiter from count
    table.remove(pending, 1)   -- Remove delimiter from array

    tcdstr_tail(pending, delim, rslt, {})

    return table.concat(rslt, delim)
end


--[[ --------------------- sfutil.GetText(textEntry, ...)

    Retrieves text based on the input type.
    Get the appropriate text string based on a variety
	of input types.
	    Type		Returns
		nil			empty string ""
		string 		textEntry
		number		returns GetString(textEntry)
		function    Executes textEntry(...) and returns the result.

    Parameters:
        textEntry: Can be a string, number (ID), or function.
        ...: Arguments passed to textEntry if it is a function.
    
    Use Case: A unified helper for UI labels that might come from constants, 
        string IDs, or dynamic generators.
--]]
function sfutil.GetText(textEntry, ...)
    if textEntry == nil then return "" end

    local text
    local teType = type(textEntry)

    if teType == "string" then
        text = textEntry

    elseif teType == "function" then
        text = textEntry(...)

    else
        text = GetString(textEntry)
    end
    return text
end

--[[ --------------------- sfutil.strSplitLen(str, maxlen)

    Splits a long string into chunks that do not exceed maxlen bytes.

    Parameters:
        str: The input string.
        maxlen (number, optional): Max length per chunk. Defaults to 1800.
    Behavior:
        If str is shorter than maxlen, returns the string itself.
        Otherwise, returns a table of substrings that would concatenate into the original string.
    Use Case: ESO chat messages have a length limit (~2000 chars). Use this to split long logs before sending.
--]]
function sfutil.strSplitLen(str, maxlen)
    if type(str) ~= "string" then
        str = "sfutil.strSplitLen: first argument must be a string"
    end
    maxlen = maxlen or 1800
    if type(maxlen) ~= "number" or maxlen <= 0 then
        maxlen = 1800
    end

    -- ----- fast‑path for short strings ------------------------------------
    local length = zo_strlen(str)
    if length <= maxlen then
        return str
    end

    -- ----- split -----------------------------------------------------------
    local result = {}
    local i = 1
    local j
    while i <= length do
        j = math.min(i + maxlen - 1, length)
        table.insert(result, zo_strsub(str, i, j))
        i = j + 1
    end
    return result
end

--[[ --------------------- sfutil.tblJoinLen(tbl, maxlen)

    Joins a table of strings, splitting the result if it exceeds maxlen.

    Parameters:
        tbl: Table of strings (or convertible values).
        maxlen (number, optional): Max length. If nil, returns a single joined string.
    Behavior:
        Converts all table elements to strings.
        Joins them.
        If maxlen is set and the result is too long, calls sfutil.strSplitLen and returns the table of chunks.
    Returns: String (if short) or Table of strings (if long).
--]]
function sfutil.tblJoinLen(tbl, maxlen)
    if not tbl then return nil end
    if maxlen ~= nil then
        if type(maxlen) ~= "number" or maxlen < 1 then
            maxlen = nil
        end
    end

    local joined

    if type(tbl) == "string" then
        joined = tbl                                 -- already a string

    elseif type(tbl) == "table" then
        -- Ensure every element is a string (or convertible to one)
        for i = 1, #tbl do
            local v = tbl[i]
            if v == nil then
                tbl[i] = "(nil)"

            elseif type(v) == "string" then
                tbl[i] = v

            else
                -- Convert numbers/booleans/etc. to strings explicitly.
                tbl[i] = tostring(v)
            end
        end
        joined = table.concat(tbl, "")               -- fast concatenation

    else
        joined = nil
    end

    if joined and maxlen ~= nil then
        return sfutil.strSplitLen(joined, maxlen)
    end
    return joined
end

--[[ --------------------- sfutil.GetIconized(prompt, promptcolor, texturefile, texturecolor)

    Create a string containing an optional icon (of optional color) followed by a text
	prompt (specified either as a string itself or as a localization string id)
	(Without the  parameters, it simply prepares and optionally colorizes text.)

    Parameters:
        prompt: String or number (ID).
        promptcolor: Hex color string for the text.
        texturefile: Path to the texture (e.g., "Interface\\Icons\\Ability_Warrior_BattleRoar").
        texturecolor: Hex color for the icon (optional).
    Output Format:
        With Icon & Color: |c<texturecolor>|t24:24:<texturefile>:inheritColor|t|r<c<promptcolor><prompt>|r
        With Icon only: |t24:24:<texturefile>|t<prompt>
        With Color only: |c<promptcolor><prompt>|r
    Use Case: Creating chat messages or tooltip headers with icons.
--]]
function sfutil.GetIconized(prompt, promptcolor, texturefile, texturecolor)
    local strprompt

    -- get the prompt text
    if (prompt == nil) then
        strprompt = ""
    elseif (type(prompt) == "string") then
        strprompt = prompt
    else
        strprompt = GetString(prompt)
    end

    -- color the prompt text if required
    if (promptcolor) then
        strprompt = zo_strformat("|c<<1>> <<2>>|r", promptcolor, strprompt)
    end

    -- prepend the icon to the prepared prompt text
    if (texturefile ~= nil) then
        if (texturecolor ~= nil) then
            return zo_strformat("|c<<1>>|t24:24:<<2>>:inheritColor|t|r<<3>>", texturecolor, texturefile, strprompt)
        else
            return zo_strformat("|t24:24:<<1>>|t<<2>>", texturefile, strprompt)
        end
    end
    return strprompt
end

--[[ --------------------- sfutil.ColorText(prompt, promptcolor)

    Create a string containing a text prompt (specified either as a string itself
	or as a localization string id) and a text color. The text color is optional, but
	if you do not provide it, you just get the same text back that you put in.

    Parameters:
        prompt: String, number (ID), or nil.
        promptcolor: Hex color string (e.g., "FF0000").
    Behavior:
        Resolves prompt (via GetString if numeric).
        Wraps in |c<promptcolor>...|r if color is provided.
    Returns: Colorized string.
--]]
function sfutil.ColorText(prompt, promptcolor)
    local strprompt

    -- get the prompt text
    if (prompt == nil) then
        strprompt = ""
    elseif (type(prompt) == "string") then
        strprompt = prompt
    else
        strprompt = GetString(prompt)
    end

    -- color the prompt text if required
    if (promptcolor ~= nil) then
        strprompt = zo_strformat("|c<<1>> <<2>>|r", promptcolor, strprompt)
    end

    return strprompt
end
