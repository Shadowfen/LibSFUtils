-- LibSFUtils is already defined in prior loaded file

LibSFUtils = LibSFUtils or {}
local sfutil = LibSFUtils

--[[ ---------------------
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
--[[ ---------------------
    Concatenate varargs to a string.
--]]
-- Tail‑recursive worker: `pending` is a list of values still to process.
local function tcstr_tail(pending, rslt, seen)
    -- If there is nothing left, we are done.
    if #pending == 0 then return rslt end

    -- Pull the first element (Lua tables are 1‑based).
    local v = table.remove(pending, 1)

    if v == nil then
        rslt[#rslt + 1] = "(nil)"
        return tcstr_tail(pending, rslt, seen)               -- tail call

    elseif type(v) == "table" then
        if seen[v] then
            rslt[#rslt + 1] = "<cycle>"
            return tcstr_tail(pending, rslt, seen)
        end
        seen[v] = true
        -- Enqueue the table’s contents (key, value pairs) *after* the
        -- current pending items so they are processed depth‑first.
        for k, v1 in pairs(v) do
            table.insert(pending, 1, k)    -- then the key
            table.insert(pending, 1, v1)   -- then value
        end
        return tcstr_tail(pending, rslt, seen)               -- tail call

    else
        rslt[#rslt + 1] = tostring(v)
        return tcstr_tail(pending, rslt, seen)               -- tail call
    end
end

-- Public wrapper – builds the initial pending list from the varargs.
--[[
local function tcstr(rslt, ...)
    local pending = {...}               -- start with the arguments themselves
    return tcstr_tail(pending, rslt)   -- tail‑call entry point
end
--]]
-- create a table of strings to concatenate togeether from the input params
--[[
local function tcstr(rslt, ...)

    -- append another value to the result table
    local function appendVal(val)
        rslt[#rslt+1] = tostring(val)
    end

    for _, v in sfutil.iter_args(...) do
        local t_v = type(v)
        if (v == nil) then
            appendVal( "(nil)" )

        elseif (t_v == "table") then
            for k, v1 in pairs(v) do
                appendVal(k)
                if type(v1) ~= "table" then
                  appendVal(v1)
                else
                  return tcstr(rslt, v1)
                end
            end
        else
            appendVal(v)
        end
    end
end
--]]
-- all of the strings that are passed in are concatenated
-- the contents of tables passed in are concatenated with their keys
-- a nil arg is converted to "(nil)"
-- numbers are converted with tostring()
function sfutil.str(...)
    local rslt = {}
    --tcstr(rslt, ...)
    local pending = {...}               -- start with the arguments themselves
    tcstr_tail(pending, rslt, {})   -- tail‑call entry point
    return table.concat(rslt)
end

-- old non-tail call version
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


--[[ ---------------------
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
]]
local function tclstr(rslt, ...)

    -- append another value to the result table
    local function appendVal(val)
        rslt[#rslt+1] = tostring(val)
    end

    --local nargs = select("#", ...)
    --for i = 1, nargs do
    for _, v in sfutil.iter_args(...) do
        local t_v = type(v)
        if not v then
            appendVal( "(nil)" )

        elseif t_v == "number" then
            appendVal(GetString(v))

        elseif t_v == "table" then
            for k, v1 in pairs(v) do
                appendVal(k)
                if type(v1) ~= "table" then
                  appendVal(v1)
                else
                  return tclstr(rslt, v1)
                end
            end
        elseif t_v ~= "function" then
            appendVal(v)
        end
    end
end

function sfutil.lstr(...)
    local rslt = {}
    tclstr(rslt, ...)
    return table.concat(rslt)
end

--[[ ---------------------
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

--[[ ---------------------
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
    if #pending == 0 then return rslt end
    local v = table.remove(pending, 1)

    if v == nil then
        rslt[#rslt + 1] = "(nil)"
    elseif type(v) == "table" then
        if seen[v] then
            rslt[#rslt + 1] = "<cycle>"
        else
            seen[v] = true
            for k, v1 in pairs(v) do
                table.insert(pending, 1, v1)
                table.insert(pending, 1, k)
            end
        end
    elseif type(v) ~= "function" then
        rslt[#rslt + 1] = tostring(v)
    end

    return tcdstr_tail(pending, delim, rslt, seen)
end

-- create a table of strings to concatenate togeether from the input params
--[[
local function tcdstr(delim, rslt, ...)
    -- append another value to the result table
    local function appendVal(val)
        rslt[#rslt+1] = tostring(val)
    end

    for _, v in sfutil.iter_args(...) do
        local t_v = type(v)
        if (v == nil) then
            appendVal( "(nil)" )

        elseif (t_v == "table") then
            for k, v1 in pairs(v) do
                appendVal(k)
                if type(v1) ~= "table" then
                  appendVal(v1)
                else
                  return tcdstr(delim, rslt, v1)
                end
            end
        elseif t_v ~= "function" then
            appendVal(v)
        end
    end
end
--]]

function sfutil.dstr(delim, ...)
    --local arg = {}
    --tcdstr(delim, arg, ...)
    local pending = {...}
    local flat = tcdstr_tail(pending, delim, {}, {})
    return table.concat(flat, delim)
end

-- old version
function sfutil.dstr1(delim, ...)
    local nargs = select("#", ...)
    local arg = {}
    local sf_str = sfutil.dstr

    for i = 1, nargs do
        local v = select(i, ...)
        local t = type(v)
        if (v == nil) then
            arg[#arg + 1] = "(nil)"
        elseif (t == "table") then
            for k, v1 in pairs(v) do
                arg[#arg + 1] = k
                arg[#arg + 1] = sf_str(delim, v1)
            end
        else
            arg[#arg + 1] = tostring(v)
        end
    end
    return table.concat(arg, delim)
end

--[[ ---------------------
    Get the appropriate text string based on a variety
	of input types.
	    Type		Returns
		nil			empty string ""
		string 		textEntry
		number		returns GetString(textEntry)
		function    returns the return value of the textEntry function
		               with whatever args were provided
	(Note that any args after textEntry are ignored unless textEntry is a function.)
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

--[[ ---------------------
	Split a string into smaller chunks if necessary.
	If maxlen is not provided, it defaults to 1800 bytes.

	Returns the string (if less than the maxlen), or a table of strings (less than maxlen)
	that would concatenate into the original string.
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

--[[ ---------------------
	Concatenate a table of strings of any length into a string (or table of strings) that are
	no longer than maxlen.
	If maxlen is not provided, this function will always return a single string.
	If maxlen is provided, this function may return another table of strings which are not
	to exceed maxlen bytes in length or a single string that's length <= maxlen
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

--[[ ---------------------
	Create a string containing an optional icon (of optional color) followed by a text
	prompt (specified either as a string itself or as a localization string id)
	(Without the  parameters, it simply prepares and optionally colorizes text.)
	The color parameters are all hex colors.
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

--[[ ---------------------
	Create a string containing a text prompt (specified either as a string itself
	or as a localization string id) and a text color. The text color is optional, but
	if you do not provide it, you just get the same text back that you put in.
	The color parameters are all hex colors.
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
