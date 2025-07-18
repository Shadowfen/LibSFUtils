-- LibSFUtils is already defined in prior loaded file
local sfutil = LibSFUtils or {}
local SF_Color = sfutil.SF_Color

--[[ ---------------------
	convenience color tables
		These tables contain definitions for commonly used colors along with
		names to easily indicate the color. 

		Using these can somewhat reduce your addon's computational load as 
		these are calculated once, when the library is loaded instead of 
		whenever you go from hex to ZO_ColorDef/rgb or from ZO_ColorDef/rgb 
		to hex again. It might be miniscule, but when you are doing the 
		ZO_ColorDef creations and conversions with a lot of colors many many 
		times, it all adds up.

	SF_Color is defined in SFUtils_Color.lua
--]]
sfutil.colors = {
    gold = SF_Color:New("FFD700"), -- {hex ="FFD700", rgb = {1, 215/255, 0}, },
    red = SF_Color:New("FF0000"), -- {hex ="FF0000", rgb = {1, 0, 0}, },
    teal = SF_Color:New("00EFBB"), -- {hex ="00EFBB", rgb = {0, 239/255, 187/255}, },
    lime = SF_Color:New("00E600"), -- {hex ="00E600", rgb = {0, 230/255, 0}, },
    green = SF_Color:New("2dc50e"), -- {hex ="2dc50e", rgb = {45/255, 197/255, 14/255}, },
    goldenrod = SF_Color:New("EECA00"), -- {hex ="EECA00", rgb = {238/255, 202/255, 0}, },
    blue = SF_Color:New("0000FF"), -- {hex ="0000FF", rgb = {0, 0, 1}, },
    purple = SF_Color:New("b000ff"), -- {hex ="b000ff", rgb = {176/255, 0, 1}, },
    bronze = SF_Color:New("ff9900"), -- {hex ="ff9900", rgb = {1, 153/255, 0}, },
    ltskyblue = SF_Color:New("87cefa"), -- {hex ="87cefa", rgb = {135/255, 206/255, 250/255}, },
    lemon = SF_Color:New("FFFACD"), -- {hex ="FFFACD", rgb = {1, 250/255, 205/255}, },
    mocassin = SF_Color:New("FFE4B5"), -- {hex ="FFE4B5", rgb = {1, 228/255, 181/255}, },
    frangipani = SF_Color:New("fad7a0"),
    --brick       = SF_Color:New("cb4154"),
    aquamarine = SF_Color:New("7fffd4"), -- {hex ="7fffd4", rgb = {127/255, 1, 212/255}, },
    lightsalmon = SF_Color:New("FFA07A"), -- {hex ="FFA07A", rgb = {1, 160/255, 122/255}, },
    junk = SF_Color:New("7f7f7f"), -- {hex = "7f7f7f", rgb = {127/255, 127/255, 127/255}, },
    normal = SF_Color:New("FFFFFF"), -- {hex = "FFFFFF", rgb = {1, 1, 1}, },
    fine = SF_Color:New("2dc50e"), -- {hex = "2dc50e", rgb = {45/255, 197/255, 14/255}, },
    superior = SF_Color:New("3a92ff"), -- {hex = "3a92ff", rgb = {58/255, 146/255, 1}, },
    epic = SF_Color:New("a02ef7"), -- {hex = "a02ef7", rgb = {160/255, 46/255, 247/255}, },
    legendary = SF_Color:New("EECA00"), -- {hex = "EECA00", rgb = {238/255, 202/255, 0}, },
    mythic = SF_Color:New("ffaa00") -- {hex = "ffaa00", rgb = {1, 170/255, 0}, },
    --violet  = GetItemQualityColor(ITEM_DISPLAY_QUALITY_ARTIFACT),
    --gold    = GetItemQualityColor(ITEM_DISPLAY_QUALITY_LEGENDARY),
    --mythic  = GetItemQualityColor(ITEM_DISPLAY_QUALITY_MYTHIC_OVERRIDE),
}
-- convenience lookup table for hex-value colors
sfutil.hex = {
    gold = sfutil.colors.gold.hex,
    red = sfutil.colors.red.hex,
    teal = sfutil.colors.teal.hex,
    lime = sfutil.colors.lime.hex,
    goldenrod = sfutil.colors.goldenrod.hex,
    blue = sfutil.colors.blue.hex,
    purple = sfutil.colors.purple.hex,
    bronze = sfutil.colors.bronze.hex,
    ltskyblue = sfutil.colors.ltskyblue.hex,
    lemon = sfutil.colors.lemon.hex,
    mocassin = sfutil.colors.mocassin.hex,
    frangipani = sfutil.colors.frangipani.hex,
    --brick = sfutil.colors.brick.hex,

    junk = sfutil.colors.junk.hex,
    normal = sfutil.colors.normal.hex,
    fine = sfutil.colors.fine.hex,
    superior = sfutil.colors.superior.hex,
    epic = sfutil.colors.epic.hex,
    legendary = sfutil.colors.legendary.hex,
    mythic = sfutil.colors.mythic.hex
}
-- convenience lookup table for rgb-value colors
sfutil.rgb = {
    gold = sfutil.colors.gold.rgb,
    red = sfutil.colors.red.rgb,
    teal = sfutil.colors.teal.rgb,
    lime = sfutil.colors.lime.rgb,
    goldenrod = sfutil.colors.goldenrod.rgb,
    blue = sfutil.colors.blue.rgb,
    purple = sfutil.colors.purple.rgb,
    bronze = sfutil.colors.bronze.rgb,
    ltskyblue = sfutil.colors.ltskyblue.rgb,
    lemon = sfutil.colors.lemon.rgb,
    mocassin = sfutil.colors.mocassin.rgb,
    frangipani = sfutil.colors.frangipani.rgb,
    --brick = sfutils.colors.brick.rgb,

    junk = sfutil.colors.junk.rgb,
    normal = sfutil.colors.normal.rgb,
    fine = sfutil.colors.fine.rgb,
    superior = sfutil.colors.superior.rgb,
    epic = sfutil.colors.epic.rgb,
    legendary = sfutil.colors.legendary.rgb,
    mythic = sfutil.colors.mythic.rgb
}

local function ZOS_addSystemMsg(msg)
    CHAT_ROUTER:AddSystemMessage(msg)
end

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
-- create a table of strings to concatenate togeether from the input params
local function tcstr(rslt, ...)
    local nargs = select("#", ...)

    -- convert result table into a string
    local function retval(rslt)
        return table.concat(rslt)
    end
    -- append another value to the result table
    local function appendVal(val)
        rslt[#rslt+1] = tostring(val)
    end

    for i = 1, nargs do
        local v = select(i, ...)
        local t = type(v)
        if (v == nil) then
            appendVal( "(nil)" )

        elseif (t == "table") then
            for k, v1 in pairs(v) do
                appendVal(k)
                if type(v1) ~= "table" then 
                  appendVal(v1)
                else
                  return tcstr(rslt, v1)
                end
            end
        elseif t == "function" then
            -- do nothing with it
        else
            appendVal(v)
        end
    end
end
-- all of the strings that are passed in are concatenated
-- the contents of tables passed in are concatenated with their keys
-- a nil arg is converted to "(nil)"
-- numbers are converted with tostring()
function sfutil.str(...)
    local nargs = select("#", ...)
    local arg = {}
    tcstr(arg, ...)
    return table.concat(arg)
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
    local nargs = select("#", ...)

    -- append another value to the result table
    local function appendVal(val)
        rslt[#rslt+1] = tostring(val)
    end

    for i = 1, nargs do
        local v = select(i, ...)
        local t = type(v)
        if (v == nil) then
            appendVal( "(nil)" )

        elseif t == "number" then
            appendVal(GetString(v))

        elseif (t == "table") then
            for k, v1 in pairs(v) do
                appendVal(k)
                if type(v1) ~= "table" then 
                  appendVal(v1)
                else
                  return tclstr(rslt, v1)
                end
            end
        elseif t == "function" then
            -- do nothing with the function
        else
            appendVal(v)
        end
    end
end

function sfutil.lstr(...)
    --local nargs = select("#", ...)
    local arg = {}
    tclstr(arg, ...)
    return table.concat(arg)
end

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
-- create a table of strings to concatenate togeether from the input params
local function tcdstr(delim, rslt, ...)
    local nargs = select("#", ...)

    -- append another value to the result table
    local function appendVal(val)
        rslt[#rslt+1] = tostring(val)
    end

    for i = 1, nargs do
        local v = select(i, ...)
        local t = type(v)
        if (v == nil) then
            appendVal( "(nil)" )

        elseif (t == "table") then
            for k, v1 in pairs(v) do
                appendVal(k)
                if type(v1) ~= "table" then 
                  appendVal(v1)
                else
                  return tcdstr(delim, rslt, v1)
                end
            end
        elseif t == "function" then
            -- do nothing with the function
        else
            appendVal(v)
        end
    end
end

function sfutil.dstr(delim, ...)
    local nargs = select("#", ...)
    local arg = {}
    tcdstr(" ", arg, ...)
    return table.concat(arg, delim)
end

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
    local text
    local teType = type(textEntry)

    if teType == "nil" then
        text = ""
    elseif teType == "string" then
        text = textEntry
    elseif teType == "function" then
        text = textEntry(...)
    else
        text = GetString(textEntry)
    end
    return text
end

--[[
	ternary trick
	
	(condition and {ifTrue} or {ifFalse})[1]
	
	ifTrue and ifFalse can be functions
	
--]]
--[[ ---------------------
	Split a string into smaller chunks if necessary.
	If maxlen is not provided, it defaults to 1800 bytes.
	
	Returns the string (if less than the maxlen), or a table of strings (less than maxlen)
	that would concatenate into the original string.
--]]
function sfutil.strSplitLen(str, maxlen)
    if maxlen == nil then
        maxlen = 1800
    end

    local length = zo_strlen(str)
    if (length <= maxlen) then
        return str
    end

    local result = {}
    local i, j = 1
    while (i <= length) do
        j = i + maxlen
        table.insert(result, zo_strsub(str, i, j - 1))
        i = j
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
    local str = ""
    if (type(tbl) == "string") then
        str = tbl
    elseif (type(tbl) == "table") then
        str = table.concat(tbl, "")
    end

    if maxlen ~= nil then
        return sfutil.strSplitLen(str, maxlen)
    end
    return str
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

--[[ ---------------------
  Used to be able to wrap an existing function with another so that subsequent
  calls to the function will actually invoke the wrapping function.
  
  The wrapping function should accept a function as the first parameter, followed
  by the parameters expected by the original function. It will be passed in the
  original function so the wrapping function can call it (if it chooses).
  
  Can be called with or without the namespace parameter (which defines the namespace
  where the original function is defined). If the namespace parameter is not provided
  then assume the global namespace _G.
  
  The wrapped function cannot be local - I mean, what's the point?
  
  Parameters:
    namespace - (optional) when provided, this is a table where the function to be wrapped resides. If not provided, the global namespace _G is assumed.
    functionName - a string with the name of the function to be wrapped (used as a key to the namespace table)
    wrapper - a function which accepts a function, followed by the parameters that the original function expects to be provided. Therefore the wrapped function can call the original function if it wishes to.
  
  Examples:
    WrapFunction(myfunc, mywrapper)
      will wrap the global function myfunc to call mywrapper
    
    WrapFunction(TT, myfunc, mywrapper)
      will wrap TT.myfunc with a call to mywrapper
--]]
function sfutil.WrapFunction(namespace, functionName, wrapper)
    if type(namespace) == "string" then
        -- We did not get a namespace parameter,
        -- shift the values to their proper places.
        wrapper = functionName
        functionName = namespace
        namespace = _G
    elseif type(namespace) ~= "table" then
        -- invalid parameters
        return nil
    end
    local originalFunction = namespace[functionName]
    namespace[functionName] = function(...)
        return wrapper(originalFunction, ...)
    end
end

---------------------
-- turn a boolean value into a string
-- suitable for display
function sfutil.bool2str(bool)
    if (sfutil.isTrue(bool)) then
        return "true"
    end
    return "false"
end

-- turn a string (hopefully containing a boolean value) into a boolean
function sfutil.str2bool(str)
    if (string.lower(str) == "true" or str == "1") then
        return true
    end
    return false
end

---------------------
-- a non-lua default test for value is true where
-- the value true is only returned if val was some
-- value equivalent to true or 1
-- Any other value will return false
function sfutil.isTrue(val)
    -- must be a variety of true value
    if (val == 1 or val == "1" or val == true or val == "true") then
        return true
    end
    return false
end

---------------------
-- return the value of val; unless it is nil when we
-- then will return defaultval instead of the nil.
--
-- The var = val or default does not do the same job,
-- because if val evaluates to false according to lua then
-- the default value would be assigned.
-- Here we specifically only want the default value if
-- val == nil.
function sfutil.nilDefault(val, defaultval)
    if val == nil then
        return defaultval
    end
    return val
end

---------------------
-- return the value of val; unless it is nil or an empty string
-- when we then will return defaultval instead of the nil.
--
function sfutil.nilDefaultStr(val, defaultval)
    if val == nil then
        return defaultval
    end
    if val == "" then
        return defaultval
    end
    return val
end

---------------------
-- Get various addon meta info
--  namespace is a table to add the info to,
--    if the namespace is not a table, create a table and return it.
-- Always returns a table with the info inside it
function sfutil.addonMeta(namespace, name)
    if type(namespace) == "string" then
        name = namespace
        namespace = nil
    end
    namespace = sfutil.safeTable(namespace)
    namespace.addonName = name -- addon name for these saved vars
    namespace.server = GetWorldName()
    namespace.account = GetDisplayName()
    namespace.charId = GetCurrentCharacterId()
    namespace.charName = GetUnitName("player")
    namespace.fmtCharName = zo_strformat(SI_UNIT_NAME, GetUnitName("player"))
    namespace.API = GetAPIVersion()
    return namespace
end

---------------------
-- Convert a number of seconds into an
-- HH:MM:SS string.
function sfutil.secondsToClock(seconds)
    local seconds = tonumber(seconds)

    if seconds <= 0 then
        return "00:00:00"
    else
        local hours = string.format("%02.f", math.floor(seconds / 3600))
        local mins = string.format("%02.f", math.floor(seconds / 60 - (hours * 60)))
        local secs = string.format("%02.f", math.floor(seconds - hours * 3600 - mins * 60))
        return hours .. ":" .. mins .. ":" .. secs
    end
end

---------------------
-- Addon Chat MESSAGE / DEBUG --
---------------------
-- Set the prefix msg  to be used for chat messages
function sfutil.initSystemMsgPrefix(addon_name, hexcolor)
    hexcolor = sfutil.nilDefault(hexcolor, sfutil.hex.goldenrod)
    return sfutil.ColorText(sfutil.str("[", addon_name, "] "), hexcolor)
end

-- Send a system message to chat with the specified prefix and the text in the specified color. (Standalone function - not part of addonChatter.)
function sfutil.systemMsg(prefix, text, hexcolor)
    hexcolor = sfutil.nilDefault(hexcolor, sfutil.hex.normal)
    msg = prefix .. sfutil.ColorText(text, hexcolor)
    ZOS_addSystemMsg(msg)
end

sfutil.addonChatter = {}

function sfutil.addonChatter:New(addon_name)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.namecolor = sfutil.hex.goldenrod
    o.normalcolor = sfutil.hex.mocassin
    o.debugcolor = sfutil.hex.ltskyblue
    o.prefix = sfutil.initSystemMsgPrefix(addon_name, o.namecolor)
    o.d = function(...)
        end -- debug messages off by default
    o.isdbgon = false
    return o
end

function sfutil.addonChatter:setNormalColor(hexcolor)
    self.normalcolor = hexcolor
end

function sfutil.addonChatter:setDebugColor(hexcolor)
    self.debugcolor = hexcolor
end

function sfutil.addonChatter:disableDebug()
    self.isdbgon = false
    self.d = function(...)
        end
end
-- print normal messages to chat
function sfutil.addonChatter:systemMessage(...)
    local msg = sfutil.str(self.prefix, sfutil.ColorText(sfutil.dstr(" ", ...), self.normalcolor))
    --local msg = self.prefix .. sfutil.ColorText(sfutil.dstr(" ", ...), self.normalcolor)
    ZOS_addSystemMsg(msg)
end

-- print debug messages to chat
function sfutil.addonChatter:debugMsg(...)
    if (self.isdbgon == true) then
        local msg = sfutil.ColorText(sfutil.dstr(" ", ...), self.debugcolor)
        ZOS_addSystemMsg(self.prefix .. msg)
    end
end

function sfutil.addonChatter:enableDebug()
    self.isdbgon = true
    self.d = function(...)
            local msg = sfutil.ColorText(sfutil.dstr(" ", ...), self.debugcolor)
            ZOS_addSystemMsg(self.prefix .. msg)
        end
end

function sfutil.addonChatter:toggleDebug()
    if (self.isdbgon == true) then
        self:disableDebug()
    else
        self:enableDebug()
    end
end

function sfutil.addonChatter:getDebugState()
    -- as a debug function, this returns a string
    return sfutil.bool2str(self.isdbgon)
end

function sfutil.addonChatter:isDebugEnabled()
    return self.isdbgon
end

-- -------------------------------------------------------
-- Slash utilities

-- display in chat a table of slash commands with descriptions
-- (using the addonChatter)
function sfutil.addonChatter:slashHelp(title, cmdstable)
    local sysmsg = function(cmd, desc)
        cmd = sfutil.ColorText(cmd, sfutil.hex.teal)
        if (type(desc) == "number") then
            desc = GetString(desc)
        end
        desc = sfutil.ColorText(" = " .. sfutil.str(desc), self.normalcolor)
        local msg = sfutil.dstr(" ", self.prefix, cmd, desc)
        ZOS_addSystemMsg(msg)
    end

    self:systemMessage(title)
    for index, value in pairs(cmdstable) do
        sysmsg(value[1], value[2])
    end
end

-- -----------------------------------------------------------------------
-- Utility for parsing delimited strings

-- Split a string into sections using a pattern as a delimiter
-- When delimiter starts or ends the string, an empty string is considered
-- to be before/after the delimiter. When two or more delimiters are together,
-- there is considered to be empty strings between them.
--   str = string
--   pat = delimiter pattern
--
-- Returns table of strings that were separated by delimiters
-- (The delimiters are NOT included in the table.)
function sfutil.gsplit(str, pat)
    local t1 = {}
    if not str then
        return {}
    end

    if not pat or pat == "" then
        -- special case - no delimiter
        return {str}
    end

    local fpat = "(.-)" .. pat
    local last_end = 1
    local s1, e1, cap = str:find(fpat, 1)
    local tbl_insert = table.insert
    if not s1 then
        -- special case - string does not contain delimiter
        tbl_insert(t1, str)
        return t1
    end

    while s1 do
        if not cap then
            -- delimiter was the beginning of the string
            -- so first capture is empty string
            cap = ""
        end
        -- save the front captured piece of the string
        tbl_insert(t1, cap)
        last_end = e1 + 1
        s1, e1, cap = str:find(fpat, last_end)
    end
    -- we have run out of delimiters to find
    if last_end - 1 <= #str then
        -- still have the last piece of string without delimiters
        cap = str:sub(last_end)
        tbl_insert(t1, cap)
    end
    return t1
end

-- -----------------------------------------------------------------------
-- Utilities for parsing colors in chat messages

-- Get the positions of all of the color markers (|c and |r) in a string
-- Return a table where each entry has the index into the string (start)
-- and the type of marker (code = "c" or "r", lower case)
-- Havok allows "|" escape character for "|" (user input) so we must handle doubled pipes for chat.
--
-- Returns the markertable for the markers that are in the string
--   (can be empty but never nil)
-- where table entry is { start, estr, code } and
--   start is the beginning of the string section for this entry
--   estr is the end of the string section for this entry (section includes the trailing color code for |c).
--   code is either "c" or "r" (lower case)
function sfutil.getAllColorDelim(str)
    if not str then
        return {}
    end

    -- get positions of all of the desired delimiters
    local t1 = {}

    local s1, e1, c = str:find("|+([CcRr])", 1)
    local strlen = #str
    local tbl_insert = table.insert
    while s1 do
        if s1 == strlen then
            break
        end

        local code = string.lower(c)
        if code == "c" then
            e1 = e1 + 6 -- include color code
        end
        tbl_insert(t1, {start = s1, estr = e1, code = code})
        -- look for next
        s1, e1, c = str:find("|+([CcRr])", e1)
    end
    -- we have run out of delimiters to find
    return t1
end

-- Evaluate and correct the color markers in the string so that
-- empty colors are marked for removal, "|c" markers are
-- always balanced by "|r" markers, and we don't have extra "|r"
-- markers
--
-- Uses the source string and a marker table as produced by
-- getAllColorDelim(). The marker table is modified by this function.
--
-- Returns the modified markertable for the markers that are in (or should be in) the string
-- where table entry is { start, estr, code, action } and
--   action is nil (keep), "+" (add), or "-" (remove);
--   estr is the end of the string section for this entry.
function sfutil.regularizeColors(markertable, str)
    if not str then
        return {}
    end
    if not markertable or #markertable == 0 then
        return {}
    end
    -- clean positions
    local prev_v, sv_start
    local needR = false
    local tbl_insert = table.insert
    for k, v in ipairs(markertable) do
        sv_start = v.start
        if v.code == "r" then
            if needR == false then
                -- don't need this |r so mark for removal
                v.action = "-"
            else
                needR = false
            end
        elseif v.code == "c" then
            if needR == true then
                -- the color we were processing has been bumped to next, so we will process it again.
                -- we are already in a color so we need to add a |r to close it
                v = {start = sv_start, estr = sv_start, code = "r", action = "+"}
                tbl_insert(markertable, k, v)
                needR = false
            else
                needR = true
            end
        end

        -- filter out empty colors. At this point if prev_v.code == "c" then v.code == "r".
        if prev_v and prev_v.code == "c" and prev_v.estr + 1 == sv_start then
            -- mark both this "|r" and the previous "|c" for removal
            prev_v.action = "-"
            v.action = "-"
        end
        prev_v = v
    end
    -- we've reached the end of the markertable
    if needR == true then
        -- we still need a |r, so append one
        tbl_insert(markertable, {start = #str + 1, estr = #str + 1, action = "+", code = "r"})
    end
    return markertable
end

function sfutil.applyColor(str, colorhex)
    if not str then
        return nil
    end
    if not colorhex then
        return str
    end

    local parsetbl = sfutil.getAllColorDelim(str)
    sfutil.regularizeColors(parsetbl, str)
    local newtbl = {}
    local incolor = false
    for k, v in ipairs(parsetbl) do
        if string.find(str, "|+[Cc]", v) then
            -- starting embedded color
            if incolor == true then
                newtbl[#newtbl] = "|r"
                incolor = false
            end
            newtbl[#newtbl] = v
        elseif string.find(str, "|+[Rr]", v) then
            -- exitting embedded color
            newtbl[#newtbl] = v
            newtbl[#newtbl] = string.format("|c%s", colorhex)
            incolor = true
        else
            if incolor == false then
                newtbl[#newtbl] = string.format("|c%s", colorhex)
                incolor = true
            end
            newtbl[#newtbl] = v
        end
    end
    return table.concat(new)
end

-- Strip all of the color markers out of the string.
-- Uses the source string and a marker table as produced by
-- getAllColorDelim().
--
-- Returns a string which is the source string with all of the color
-- markers removed.
--
-- Havok allows "|" escape character for "|" (user input) so we must handle doubled pipes.
function sfutil.stripColors(markertable, str)
    if not str then
        return nil
    end
    if not markertable or #markertable == 0 then
        return str
    end

    local t2 = {}
    local lastv = 0
    local tbl_insert = table.insert
    for k, v in ipairs(markertable) do
        local code = v.code
        local action = v.action
        if not action then
            -- it's a section we're keeping
            -- string fragment
            if code == "c" then
                if v.start > lastv + 1 then
                    tbl_insert(t2, str:sub(lastv + 1, v.start - 1))
                end
                ss, es = string.find(str, "|+[Cc]%x%x%x%x%x%x", v.start)
                lastv = es
            elseif code == "r" then
                -- end color
                if v.start > lastv + 1 then
                    tbl_insert(t2, str:sub(lastv + 1, v.start - 1))
                end
                ss, es = string.find(str, "|+[Rr]", v.start)
                lastv = es
            else
                -- uninteresting
            end
        elseif action == "+" then
            -- new string fragment (|r)
            if v.start > lastv + 1 then
                tbl_insert(t2, str:sub(lastv + 1, v.start - 1))
            end
            lastv = v.start + 1
        else -- action == "-"
            if code == "c" then
                ss, es = string.find(str, "|+[Cc]%x%x%x%x%x%x", v.start)
                lastv = es
            elseif code == "r" and v.start ~= -1 then
                ss, es = string.find(str, "|+[Rr]", v.start)
                lastv = es
            end
        end
    end
    if lastv and lastv <= #str then
        lastv = lastv + 1
        tbl_insert(t2, str:sub(lastv))
    end
    return table.concat(t2)
end

-- Splits the string into sections corresponding the color markers themselves
-- and the text around the markers. Doing a table.concat() will join the contents
-- of the returned table into a properly color-marked string.
-- Returns the table of sections
function sfutil.colorsplit(markertable, str)
    if not str then
        return {}
    end
    if not markertable or #markertable == 0 then
        -- no delimiters in string
        return {str}
    end

    -- break string into sections with color markers separated out
    local t2 = {}
    local lastv = 0
    local ss, es, cs
    local tbl_insert = table.insert
    for k, v in ipairs(markertable) do
        if v then
            local code = v.code
            local action = v.action
            if not action then
                -- it's a section we're keeping
                if v.start > lastv + 1 then
                    tbl_insert(t2, str:sub(lastv + 1, v.start - 1))
                end
                -- string fragment
                if code == "c" then
                    -- expect color
                    ss, es, cs = string.find(str, "|+[Cc](%x%x%x%x%x%x)", v.start)
                    if ss == nil or es == nil then
                        break
                    end
                    tbl_insert(t2, string.format("|c%s", cs))
                    lastv = es
                elseif code == "r" then
                    -- end color
                    ss, es = string.find(str, "|+[Rr]", v.start)
                    if ss == nil or es == nil then
                        break
                    end
                    tbl_insert(t2, "|r")
                    lastv = es
                end
            elseif action == "+" then
                -- new string fragment (|r)
                if v.start > lastv + 1 then
                    tbl_insert(t2, str:sub(lastv + 1, v.start - 1))
                end
                tbl_insert(t2, "|r")
                lastv = v.start + 1
            else -- action == "-"
                if code == "c" then
                    ss, es = string.find(str, "|+[Cc]%x%x%x%x%x%x", v.start)
                    if ss == nil or es == nil then
                        break
                    end
                    lastv = es
                elseif code == "r" and v.start ~= -1 then
                    ss, es = string.find(str, "|+[Rr]", v.start)
                    if ss == nil or es == nil then
                        break
                    end
                    lastv = es
                end
            end
        end
    end
    if lastv <= #str then
        lastv = lastv + 1
        tbl_insert(t2, str:sub(lastv))
    end
    return t2
end

-- -----------------------------------------------------------------------
-- temporary hacks
function sfutil.add2linesctl()
    --[[	-- only needed when LibAddonMenu is having clipping problems
	return 	{
				type = "description",
				title = " ",
				text = " ",
				disabled = true,
			}
--]]
end

function sfutil.addlinectl()
    --[[	-- only needed when LibAddonMenu is having clipping problems
	return 	{
				type = "description",
				text = " ",
				disabled = true,
			}
--]]
end

-- -----------------------------------------------------------------------
-- easily manage values and choice tables for dropdowns
-- creates a simple lookup table for potential choices
-- for dropdowns, each entry with an index key (ndx), a
-- choice (strId), and the optional choiceValue (val)
--
-- Then you can create choices and choiceValues lists
-- by passing in table indexes.
--
-- Elsewhere in your code, you can compare what was returned
-- from the dropdown to an indexed value of your lookup table,
-- thus avoiding the problem of tracking down the hardcoded
-- references to a value sprinkled throughout your code. Only
-- the table has to change, and everything else just works.

-- used by TTFAS
sfutil.DDValueTable = ZO_Object:Subclass()
function sfutil.DDValueTable:New()
    local o = ZO_Object.New(self)
    --o:initialize(...)
    return o
end

-- Append a value row to the end of the DDValueTable.
-- While it is prefered for the strId parameter to be a ZOS stringId,
-- it can be a string instead (not recommended).
-- The val parameter should either be nil (it is after all optional)
-- or it should be a string (not a stringId)
function sfutil.DDValueTable:append(val, strId, tooltip)
    if val == nil then
        if type(strId) == "string" then
            table.insert(self, {value = strId, strg = strId, tt = tooltip})
        else
            table.insert(self, {value = GetString(strId), strg = strId, tt = tooltip})
        end
    else
        table.insert(self, {value = val, strg = strId, tt = tooltip})
    end
    return #self
end

-- Add a value row to the DDValueTable.
-- While it is prefered for the strId parameter to be a ZOS stringId,
-- it can be a string instead (not recommended).
-- The val parameter should either be nil (it is after all optional)
-- or it should be a string (not a stringId)
function sfutil.DDValueTable:add(ndx, val, strId, tooltip)
    if val == nil then
        if type(strId) == "string" then
            self[ndx] = {value = strId, strg = strId, tt = tooltip}
        else
            self[ndx] = {value = GetString(strId), strg = strId, tt = tooltip}
        end
    else
        self[ndx] = {value = val, strg = strId, tt = tooltip}
    end
    return ndx
end

-- Get the choiceValue string for the specified index
function sfutil.DDValueTable:val(ndx)
    return self[ndx].value
end

-- Get the choice string for the specified index
function sfutil.DDValueTable:str(ndx)
    if type(self[ndx].strg) == "string" then
        return self[ndx].strg
    else
        return GetString(self[ndx].strg)
    end
end

-- Get the choice tooltip for the specified index
function sfutil.DDValueTable:tip(ndx)
    if type(self[ndx].tt) == "string" then
        return self[ndx].tt
    else
        return GetString(self[ndx].tt)
    end
end

-- returns choices table for use with dropdowns
function sfutil.DDValueTable:choices(...)
    local ac = select("#", ...)
    if ac == 0 then
        --error( string.format("error: %s(): require arguments." , fn))
        return self:choicesAll()
    end

    local choicetbl = {}
    for ax = 1, ac do
        local ndx = select(ax, ...)
        if not ndx then
            error(string.format("error: %s():  argument is nil.", fn))
        end
        --d("choicetbl: "..ndx.." "..self:str(ndx))
        table.insert(choicetbl, self:str(ndx))
    end
    return choicetbl
end

-- returns choices table for use with dropdowns
function sfutil.DDValueTable:choicesAll()
    local choicetbl = {}
    for ax = 1, #self do
        local ndx = self[ax]
        if not ndx then
            error(string.format("error: %s():  argument is nil.", fn))
        end
        --d("choicetbl: "..ndx.." "..self:str(ndx))
        table.insert(choicetbl, self:str(ax))
    end
    return choicetbl
end

-- returns (dropdown-optional) choicesValues table for use with dropdowns
function sfutil.DDValueTable:choiceValues(...)
    local ac = select("#", ...)
    if ac == 0 then
        --error( string.format("error: %s(): require arguments." , fn))
        return self:choiceValuesAll()
    end
    local valtbl = {}
    for ax = 1, ac do
        local ndx = select(ax, ...)
        if not ndx then
            error(string.format("error: %s():  argument is nil.", fn))
        end
        table.insert(valtbl, self:val(ndx))
    end
    return valtbl
end

-- returns choices table for use with dropdowns
function sfutil.DDValueTable:choiceValuesAll()
    local valtbl = {}
    for ax = 1, #self do
        local ndx = self[ax]
        if not ndx then
            error(string.format("error: %s():  argument is nil.", fn))
        end
        table.insert(valtbl, self:val(ax))
    end
    return valtbl
end

-- returns (dropdown-optional) choiceTooltips table for use with dropdowns
function sfutil.DDValueTable:choiceTooltips(...)
    local ac = select("#", ...)
    if ac == 0 then
        --error( string.format("error: %s(): require arguments." , fn))
        return self:choiceTooltipsAll()
    end
    local tiptbl = {}
    for ax = 1, ac do
        local ndx = select(ax, ...)
        if not ndx then
            error(string.format("error: %s():  argument is nil.", fn))
        end
        table.insert(tiptbl, self:tip(ndx))
    end
    return tiptbl
end

-- returns choices table for use with dropdowns
function sfutil.DDValueTable:choiceTooltipsAll()
    local tiptbl = {}
    for ax = 1, #self do
        local ndx = self[ax]
        if not ndx then
            error(string.format("error: %s():  argument is nil.", fn))
        end
        table.insert(tiptbl, self:tip(ax))
    end
    return tiptbl
end

-- returns choices and choicesValues tables for use with dropdowns
function sfutil.DDValueTable:choicesNvalues(...)
    local ac = select("#", ...)
    if ac == 0 then
        --error( string.format("error: %s(): require arguments." , fn))
        return self:choicesNvaluesAll()
    end
    local valtbl = {}
    local choicetbl = {}
    for ax = 1, ac do
        local ndx = select(ax, ...)
        if not ndx then
            error(string.format("error: %s():  argument is nil.", fn))
        end
        table.insert(choicetbl, self:str(ndx))
        local valstr = self:val(ndx)
        if valstr then
            table.insert(valtbl, self:val(ndx))
        else
            table.insert(valtbl, self:str(ndx))
        end
    end
    return choicetbl, valtbl
end

-- returns choices and choicesValues tables for use with dropdowns
function sfutil.DDValueTable:choicesNvaluesAll()
    local valtbl = {}
    local choicetbl = {}
    --d("cNv - self = "..#self)
    for ax = 1, #self do
        local ndx = self[ax]
        if not ndx then
            error(string.format("error: %s():  argument is nil.", fn))
        end
        --d("choicetbl: "..ax.." "..self:str(ax))
        table.insert(choicetbl, self:str(ax))
        local valstr = self:val(ax)
        if valstr then
            table.insert(valtbl, self:val(ax))
        else
            table.insert(valtbl, self:str(ndx))
        end
    end
    return choicetbl, valtbl
end
