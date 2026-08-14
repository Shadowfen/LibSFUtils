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


local rslt_pool = {}        -- Allocate the table ONCE at module load

--[[ formatValue(val, opts, rslt, seen) - Recursively formats a Lua value and appends the resulting text fragments to `rslt`.

    Parameters:
    * val — Value to format. May be nil, a function, scalar value, or table.
    * opts — table - Formatting options:
        * `showFunctions` — If true, functions are represented as "<function>", and the "runFunctions" option is ignored..
                            If false, the string "<function>" is NOT added to the result.
        * `runFunctions` — If true, functions are executed and their output is formatted for addition to the results.
                            Note: if 'showFunctions' is true then this option is ignored.
                            If false, then functions are not executed.
        * `localizeNumbers` — If true, numeric values are passed to GetString() instead of tostring().
        * `seenText` — Text emitted when a table has already been encountered. Defaults to `"<seen>"`.
        * `tableOpen` — Optional text emitted before the contents of a table.
        * `tableClose` — Optional text emitted after the contents of a table.
        * `keyValueDelim - Optional text emitted between a key and a value in a table
    * `rslt` — Output array. Formatted fragments are appended using numeric indexing.
    * `seen` — Table used to track tables already visited during recursive traversal. 
                This prevents infinite recursion when tables contain references to themselves or to an ancestor table.

    Behavior:

    1. `nil` values - Appends `"(nil)"`.
    2. Functions - 
        * If `opts.showFunctions` is enabled, appends `"<function>"`.
        * Otherwise produces no output.
    3. Non-table values -
        * Numbers are localized with `GetString()` when `opts.localizeNumbers` is enabled.
        * All other scalar values are converted with `tostring()`.
    4. Tables - 
        * Checks `seen` before recursively processing the table.
        * If the table has already been visited, appends `opts.seenText` or `"<seen>"`.
        * Otherwise marks the table as seen and recursively formats each key/value pair.
        * Table iteration uses `pairs()`, so entry order is not guaranteed.
        * `tableOpen` and `tableClose` optionally surround the table contents.
        * `keyValueDelim` optionally separates each key from its corresponding value.

    Important implementation detail:
        * `seen` is intentionally shared by all recursive calls. Once a table has been encountered, 
            subsequent references to that same table are represented by the configured `seenText` 
            rather than being expanded again. This handles both circular references and repeated references 
            without infinite recursion or duplicate expansion.

    Output:
        The function does not return a formatted string. It appends fragments to `rslt`; the caller can 
        subsequently combine them with `table.concat(rslt)`.
--]]
local function formatValue(val, opts, rslt, seen)
    opts = opts or {}
    if val == nil then
        rslt[#rslt + 1] = "(nil)"
        return
    end

    local t = type(val)

    if t == "function" then
        if opts.showFunctions then
            rslt[#rslt + 1] = "<function>"
        elseif opts.runFunctions then
            formatValue(val(), opts, rslt, seen)
        end
        return
    end

    -- non-table, non-function values
    if t ~= "table" then
        if opts.localizeNumbers and t == "number" then
            rslt[#rslt + 1] = GetString(val)
        else
            rslt[#rslt + 1] = tostring(val)
        end
        return
    end

    -- process tables --

    -- repeated-view table?
    if seen[val] then
        rslt[#rslt + 1] = opts.seenText or "<seen>"
        return
    end
    seen[val] = true

    -- start processing the first-view table
    if opts.tableOpen then
        rslt[#rslt + 1] = opts.tableOpen
    end

    for k, value in pairs(val) do
        -- Key.
        rslt[#rslt + 1] = tostring(k)

        -- Delimiter between key and value.
        if opts.keyValueDelim then
            rslt[#rslt + 1] = opts.keyValueDelim
        end

        -- Value.
        formatValue(value, opts, rslt, seen)
    end

    if opts.tableClose then
        rslt[#rslt + 1] = opts.tableClose
    end
end

local function clear(t)
    for k in pairs(t) do
        t[k] = nil
    end
end

--[[ sfutil.str(...) - Create a string from the provided values. 
        Numbers are included as numeric strings, functions are replaced with "<function>"
        and repeated reference to tables will become "<cycle>" after the first time.
        No delimiters.
--]]
function sfutil.str(...)
    clear(rslt_pool)

    local opts = {
        localizeNumbers = false,
        showFunctions = true,
        seenText = "<cycle>",
    }

    local args = sfutil.NilPack(...)
    for i = 1, args.n do
        formatValue(args[i], opts, rslt_pool, {})
    end

    return table.concat(rslt_pool)
end

--[[ sfutil.optstr(opt, delim, ...) - Create a string from provided values using the provided options and delimiter

    Parameters:
        opt - table - option values - See formatValues() for recognized options to specify
        delim - a character or string - to be used as a delimiter between values 
                or nil for no delimiter
        ... - any - strings, numbers, booleans, nils, and/or tables of those

--]]
function sfutil.optstr(opt, delim, ...)
    clear(rslt_pool)

    local args = sfutil.NilPack(...)
    local seen = {}

    for i = 1, args.n do
        formatValue(args[i], opt, rslt_pool, seen)
    end

    return table.concat(rslt_pool, delim)
end

--[[ sfutil.lstr(...) - Create a string from the provided values. Numbers are looked up with GetString.
        Functions are replaced with "<function>" and repeated reference to tables will become "<cycle>" 
        after the first time. No delimiters.
--]]
function sfutil.lstr(...)
    clear(rslt_pool)

    local opts = {
        localizeNumbers = true,
        showFunctions = false,
        seenText = "<cycle>",
    }

    local args = sfutil.NilPack(...)
    for i = 1, args.n do
        formatValue(args[i], opts, rslt_pool, {})
    end

    return table.concat(rslt_pool)
end

--[[ sfutil.dstr(delim, ...) - Create a delimited string from the provided values.
        Numbers are included as numeric strings, functions are replaced with "<function>" 
        and repeated reference to tables will become "<cycle>" 
        after the first time.
        Delimiters are inserted between each of the values.
--]]
function sfutil.dstr(delim, ...)
    clear(rslt_pool)

    local opts = {
        localizeNumbers = false,
        showFunctions = true,
        seenText = "<cycle>",
    }

    local args = sfutil.NilPack(...)
    for i = 1, args.n do
        formatValue(args[i], opts, rslt_pool, {})
    end

    return table.concat(rslt_pool, delim)
end

--[[ sfutil.tblstr(delim, ...) - Create a delimited string from the provided values with "{" and "}" characters
        around the tables, and "-" delimiters between the keys and values.
        Numbers are included as numeric strings, functions are replaced with "<function>" 
        and repeated reference to tables will become "<cycle>" after the first time.
        Delimiters are inserted between each of the values.
--]]
function sfutil.tblstr(delim, ...)
    clear(rslt_pool)

    local opts = {
        localizeNumbers = false,
        showFunctions = true,
        seenText = "<seen>",
        tableOpen = "{",
        tableClose = "}",
        keyValueDelim = "-",
    }

    local args = sfutil.NilPack(...)
    for i = 1, args.n do
        formatValue(args[i], opts, rslt_pool, {})
    end

    return table.concat(rslt_pool, delim)
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
