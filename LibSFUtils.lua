local MAJOR, MINOR = "LibSFUtils", 15
local sfutil, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if(not sfutil) then return end --the same or newer version of this lib is already loaded into memory

-- prep for no longer using LibStub. provides hybrid support during transition
LibSFUtils = sfutil

---------------------
-- convenience color tables
sfutil.colors = {
    gold        = {hex ="FFD700", rgb = {255/255, 215/255, 0}, },
    red         = {hex ="FF0000", rgb = {255/255, 0, 0}, },
    teal        = {hex ="00EFBB", rgb = {0, 239/255, 187/255}, },
    lime        = {hex ="00E600", rgb = {0, 230/255, 0}, },
    goldenrod   = {hex ="EECA00", rgb = {238/255, 202/255, 0}, },
    blue        = {hex ="0000FF", rgb = {0, 0, 255/255}, },
    purple      = {hex ="b000ff", rgb = {176/255,0,255/255}, },
    bronze      = {hex ="ff9900", rgb = {255/255, 153/255, 0}, },
	ltskyblue   = {hex ="87cefa", rgb = {135/255, 206/255, 250/255}, },
	lemon		= {hex ="FFFACD", rgb = {255/255, 250/255, 205/255}, },
	mocassin	= {hex ="FFE4B5", rgb = {255/255, 228/255, 181/255}, },

    junk        = {hex = "7f7f7f", rgb = {127/255, 127/255, 127/255}, },
    normal      = {hex = "FFFFFF", rgb = {255/255, 255/255, 255/255}, },
    fine        = {hex = "2dc50e", rgb = {45/255, 197/255, 14/255}, },
    superior    = {hex = "3a92ff", rgb = {58/255, 146/255,255/255}, },
    epic        = {hex = "a02ef7", rgb = {160/255, 46/255, 247/255}, },
    legendary   = {hex = "EECA00", rgb = {238/255, 202/255, 0}, },
}
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

    junk = sfutil.colors.junk.hex,
    normal = sfutil.colors.normal.hex,
    fine = sfutil.colors.fine.hex,
    superior = sfutil.colors.superior.hex,
    epic = sfutil.colors.epic.hex,
    legendary = sfutil.colors.legendary.hex,
}
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

    junk = sfutil.colors.junk.rgb,
    normal = sfutil.colors.normal.rgb,
    fine = sfutil.colors.fine.rgb,
    superior = sfutil.colors.superior.rgb,
    epic = sfutil.colors.epic.rgb,
    legendary = sfutil.colors.legendary.rgb,
}

---------------------
--[[
    Concatenate varargs to a string
]]
function sfutil.str(...)
   local nargs = select('#',...)
   local arg = {}

   for i = 1,nargs do
      local v = select(i,...)
      local t = type(v)
      if(v == nil) then
         arg[#arg+1] = "(nil)"
      elseif(t == "table") then
         arg[#arg+1] = sfutil.str(v)
      else
         arg[#arg+1] = tostring(v)
      end
   end
   return table.concat(arg)
end

---------------------
--[[
    Concatenate varargs to a delimited string
]]
function sfutil.dstr(delim, ...)
    local nargs = select('#',...)
    local arg = {}

    for i = 1,nargs do
        local v = select(i,...)
        local t = type(v)
        if(v == nil) then
            arg[#arg+1] = "(nil)"
        elseif(t == "table") then
            arg[#arg+1] = sfutil.str(v)
        else
            arg[#arg+1] = tostring(v)
        end
    end
    return table.concat(arg,delim)
end

---------------------
-- Create a string containing an optional icon (of optional color) followed by a text
-- prompt (specified either as a string itself or as a localization string id)
-- (Without the  parameters, it simply prepares and optionally colorizes text.)
-- The color parameters are all hex colors.
function sfutil.GetIconized(prompt, promptcolor, texturefile, texturecolor)
    local strprompt

    -- get the prompt text
    if( prompt == nil ) then
        strprompt = ""
    elseif( type(prompt) == "string") then
        strprompt = prompt
    else
        strprompt = GetString(prompt)
    end

    -- color the prompt text if required
    if( promptcolor ) then
        strprompt = zo_strformat("|c<<1>> <<2>>|r", promptcolor, strprompt)
    end

    -- prepend the icon to the prepared prompt text
    if( texturefile ~= nil ) then
        if( texturecolor ~= nil ) then
			return zo_strformat("|c<<1>>|t24:24:<<2>>:inheritColor|t|r<<3>>", texturecolor, texturefile, strprompt)
        else
			return zo_strformat("|t24:24:<<1>>|t<<2>>", texturefile, strprompt)
        end
    end
    return strprompt
end

---------------------
-- Create a string containing a text prompt (specified either as a string itself 
-- or as a localization string id) and a text color. The text color is optional, but
-- if you do not provide it, you just get the same text back that you put in.
-- The color parameters are all hex colors.
function sfutil.ColorText(prompt, promptcolor)
    local strprompt

    -- get the prompt text
    if( prompt == nil ) then
        strprompt = ""
    elseif( type(prompt) == "string") then
        strprompt = prompt
    else
        strprompt = GetString(prompt)
    end

    -- color the prompt text if required
    if( promptcolor ~= nil ) then
        strprompt = zo_strformat("|c<<1>> <<2>>|r", promptcolor, strprompt)
    end

    return strprompt
end

---------------------
--[[
  Used to be able to wrap an existing function with another so that subsequent
  calls to the function will actually invoke the wrapping function.
  
  The wrapping function should accept a function as the first parameter, followed
  by the parameters expected by the original function. It will be passed in the
  original function so the wrapping function can call it (if it chooses).
  
  Can be called with or without the namespace parameter (which defines the namespace
  where the original function is defined). If the namespace parameter is not provided
  then assume the global namespace _G.
  
  Examples:
    WrapFunction(myfunc, mywrapper)
      will wrap the global function myfunc to call mywrapper
    
    WrapFunction(TT, myfunc, mywrapper)
      will wrap TT.myfunc with a call to mywrapper
]]
function sfutil.WrapFunction(namespace, functionName, wrapper)
  
    if(type(namespace) == "string") then
        -- We did not get a namespace parameter,
        -- shift the values to their proper places.
        wrapper = functionName
        functionName = namespace
        namespace = _G
    end
    local originalFunction = namespace[functionName]
    namespace[functionName] = function(...) 
			return wrapper(originalFunction, ...) 
		end
end

---------------------
-- Recursively initialize missing values in a table from
-- a defaults table. Existing values in the svtable will
-- remain unchanged.
function sfutil.defaultMissing(svtable, defaulttable)
	if type(svtable) ~= 'table' then return end
	if type(defaulttable) ~= 'table' then return end
	
	for k,v in pairs(defaulttable) do
		if( svtable[k] == nil ) then 
			if( type( defaulttable[k] )=='table' ) then
				svtable[k] = {}
				sfutil.defaultMissing( svtable[k], defaulttable[k])
			else
				svtable[k] = defaulttable[k]
			end
		end
	end
end

---------------------
-- Recursively copy contents of a table into a new table
function sfutil.deepCopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[sfutil.deepCopy(orig_key)] = sfutil.deepCopy(orig_value)
		end
		setmetatable(copy, sfutil.deepCopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

---------------------
-- turn a boolean value into a string
-- suitable for display
function sfutil.bool2str(bool)
	if( sfutil.isTrue(bool) ) then
		return "true"
	end
	return "false"
end

---------------------
-- a non-lua default test for value is true where
-- the value true is only returned if val was some
-- value equivalent to true or 1
-- Any other value will return false
function sfutil.isTrue(val)
	-- must be a variety of true value
	if(val == 1 or val == "1" or val == true or val == "true") then
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
function sfutil.nilDefault( val, defaultval )
	if( val == nil ) then
		return defaultval
	end
	return val
end

----------------------------
-- Saved Variables helpers
----------------------------
-- Get saved variables table toon only
-- Note: This does NOT automatically add an accountWide variable to the
--    table if it is not already there!
--
-- SavedVars are retrieved for the current server that you are on.
function sfutil.getToonSavedVars(saveFile, saveVer, saveDefaults)
    local toon = ZO_SavedVars:NewCharacterIdSettings(saveFile, saveVer, GetWorldName(), saveDefaults)
    sfutil.defaultMissing(toon,saveDefaults)
    return toon
end

-- Get saved variables table account-wide only
--
-- SavedVars are retrieved for the current server that you are on.
function sfutil.getAcctSavedVars(saveFile, saveVer, saveDefaults)
    local aw = ZO_SavedVars:NewAccountWide(saveFile, saveVer, GetWorldName(), saveDefaults)
    sfutil.defaultMissing(aw,saveDefaults)
    return aw
end

-- Get saved variables tables when we deal with both toon and account-wide settings.
--
-- Toon and account-wide can have different default tables (but don't have too).
-- If you only specify one table it will be used for both account-wide and toon.
--
-- An accountWide variable will be automatically added to the toon table if it 
-- does not already exist, because the currentSavedVars() function works off of that.
-- It is used to designate whether the settings for account-wide are currently in effect
-- or the toon settings are in effect.
--
-- SavedVars are retrieved for the current server that you are on.
function sfutil.getAllSavedVars(saveFileName, saveVer, saveAWDefaults, saveToonDefaults)
    if saveAWDefaults == nil and saveToonDefaults == nil then
        local aw = ZO_SavedVars:NewAccountWide(saveFileName, saveVer, GetWorldName())
        local toon = ZO_SavedVars:NewCharacterIdSettings(saveFileName, saveVer, GetWorldName())
        toon.accountWide = sfutil.nilDefault(toon.accountWide, true)
        return aw, toon
    end
    
    if saveAWDefaults == nil then
        saveAWDefaults = saveToonDefaults
    end
    if saveToonDefaults == nil then
        saveToonDefaults = saveAWDefaults
    end
    local aw = ZO_SavedVars:NewAccountWide(saveFileName, saveVer, GetWorldName(), saveAWDefaults)
    local toon = ZO_SavedVars:NewCharacterIdSettings(saveFileName, saveVer, GetWorldName(), saveToonDefaults)
    sfutil.defaultMissing(aw, saveAWDefaults)
    sfutil.defaultMissing(toon, saveToonDefaults)
	toon.accountWide = sfutil.nilDefault(toon.accountWide,true)
    return aw, toon
end

--[[
    Return the currently active table of saved variables.
    If newAcctWideVal is not nil, then the toon.accountWide value will be set to the new value 
    before deciding which of the tables aw or toon will be returned (based on if toon.accountWide 
    evaluates to true or false).
--]]
function sfutil.currentSavedVars(aw, toon, newAcctWideVal)
    if newAcctWideVal ~= nil then
		toon.accountWide = newAcctWideVal
	end
	if( toon.accountWide ) then 
		return aw
	end
    return toon
end

---------------------
-- MESSAGE / DEBUG --
---------------------
function sfutil.initSystemMsgPrefix(addon_name, hexcolor)
	hexcolor = sfutil.nilDefault(hexcolor, sfutil.hex.goldenrod)
	local prefix = sfutil.ColorText(addon_name, hexcolor)
	return prefix
end

function sfutil.systemMsg(prefix, text, hexcolor)
	hexcolor = sfutil.nilDefault(hexcolor, sfutil.hex.normal)
	msg = prefix..sfutil.ColorText(text, hexcolor)
	CHAT_SYSTEM:AddMessage(msg)
end


sfutil.addonChatter = {}

function sfutil.addonChatter:New(addon_name)
	o = {} 
	setmetatable(o, self)
	self.__index = self
    
	o.prefix = sfutil.ColorText(sfutil.str("[",addon_name,"] "), sfutil.hex.goldenrod)
    o.namecolor = sfutil.hex.goldenrod
	o.normalcolor = sfutil.hex.mocassin
	o.debugcolor = sfutil.hex.ltskyblue
    o.d = function(...) end    -- debug messages off by default
	o.isdbgon = false
    return o
end

function sfutil.addonChatter:disableDebug()
	self.isdbgon = false
    self.d = function(...)
        end
end
-- print normal messages to chat
function sfutil.addonChatter:systemMessage(...)
	local msg = self.prefix..sfutil.ColorText(sfutil.dstr(" ",...), self.normalcolor)
	CHAT_SYSTEM:AddMessage(msg)
end

-- print debug messages to chat
function sfutil.addonChatter:debugMsg(...)
    if( self.isdbgon == true ) then
        local msg = sfutil.ColorText(sfutil.dstr(" ",...), self.debugcolor)
        CHAT_SYSTEM:AddMessage(self.prefix..msg)
    end
end

function sfutil.addonChatter:enableDebug()
	self.isdbgon = true
    self.d = function(...)
			local msg = sfutil.ColorText(sfutil.dstr(" ",...), self.debugcolor)
			CHAT_SYSTEM:AddMessage(self.prefix..msg)
        end
end

function sfutil.addonChatter:toggleDebug()
    if( self.isdbgon == true ) then
		self:disableDebug()
	else
		self:enableDebug()
	end
end

function sfutil.addonChatter:getDebugState()
	-- as a debug function, this returns a string
	return sfutil.bool2str(self.isdbgon)
end

-- -------------------------------------------------------
-- Slash utilities

-- display in chat a table of slash commands with descriptions
-- (using the addonChatter)
function sfutil.addonChatter:slashHelp(title, cmdstable)
	local sysmsg = function (cmd, desc) 
        cmd = sfutil.ColorText(cmd, sfutil.hex.teal)
        if( type(desc) == "number" ) then
        	desc = GetString(desc)
		end
        desc = sfutil.ColorText(" = "..sfutil.str(desc), self.normalcolor)
        local msg = sfutil.dstr( " ", self.prefix, cmd, desc )
        CHAT_SYSTEM:AddMessage(msg);
	end
	
    self:systemMessage(title)
    for index, value in pairs(cmdstable) do
        sysmsg(value[1], value[2])
    end
end



-- -------------------------------------------------------

-- load strings for the client language (or default if the
-- client language is not supported)
--
function sfutil.LoadLanguage(lang_strings, defaultLang)
    if lang_strings == nil or type(lang_strings) ~= "table"then 
        -- invalid parameter
        d("LoadLanguage: Invalid lang_strings parameter")
        return 
    end
    sfutil.nilDefault(defaultLang, "en")
    
    -- get current language
    local lang = GetCVar("language.2")

    --check for supported languages
    local chosen = lang
    if lang_strings[lang] == nil then
        chosen = defaultLang
    end
    
    if( lang_strings[chosen] == nil or type(lang_strings[chosen]) ~= "table" ) then
        -- chosen language is not in lang_strings table
        d("LoadLanguage: Chosen language is not in lang_strings table")
        return
    end
    
    -- load strings for chosen language
    local localstr = lang_strings[chosen]
    for stringId, stringValue in pairs(localstr) do
        ZO_CreateStringId(stringId, stringValue)
        SafeAddVersion(stringId, 1)
    end
end

-- -----------------------------------------------------------------------
-- experimental functions - not ready for prime-time
function sfutil.getDLCs()
	d("COLLECTIBLE_CATEGORY_TYPE_DLC = "..COLLECTIBLE_CATEGORY_TYPE_DLC)
    for categoryIndex = 1, GetNumCollectibleCategories() do
        local categoryName, numSubCategories, numCollectibles, unlockedCollectibles = 
				GetCollectibleCategoryInfo(categoryIndex)
		if(categoryName == "Stories") then
			d("Name: "..categoryName.."  Index: "..categoryIndex)
			d("Num subcategories: "..numSubCategories)
			for subcategoryIndex = 1, numSubCategories do
				local subCategoryName, subNumCollectibles, subNumUnlockedCollectibles = 
					GetCollectibleSubCategoryInfo(categoryIndex, subcategoryIndex)
				if( subCategoryName ~= nil ) then
					d("->SubName: "..subCategoryName.."  index: "..subcategoryIndex)
				else
					d("->Sub category Index: "..subcategoryIndex)
				end
				d("->Num subcollectibles: "..subNumCollectibles)	
				--
				local formattedSubcategoryName = 
					zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, subCategoryName)
				for coll=1, subNumCollectibles do
					local id = GetCollectibleId(categoryIndex, 
						subcategoryIndex, coll)
					local name, description, iconFile, deprecatedLockedIconFile, 
						unlocked, purchasable, active, categoryType, hint, 
						isPlaceholder = GetCollectibleInfo(id)
					local unlockState = GetCollectibleUnlockStateById(id)
					d("index: "..coll.."  id: "..id.."  Name: "..name.."  unlocked: "..sfutil.bool2str(unlocked).."  active: "..sfutil.bool2str(active))
 				end
				--]]
			end
		end
	end
end

-- -----------------------------------------------------------------------
-- experimental functions - not ready for prime-time
function sfutil.getChapters()
    local name, _, numCollectibles, unlockedCollectibles, _, _, collectibleCategoryType = GetCollectibleCategoryInfo(COLLECTIBLE_CATEGORY_TYPE_CHAPTER)
     d("Number of Chapters: ".. numCollectibles)
    for i=1, numCollectibles do
        local collectibleId = GetCollectibleId(COLLECTIBLE_CATEGORY_TYPE_CHAPTER, nil, i)
        local collectibleName, _, _, _, unlocked = GetCollectibleInfo(collectibleId) 
			-- Will return true or false. If the user unlocked through ESO+ without buying DLC it will return true.
        d(sfutil.str("DLC ", collectibleName, "( ", collectibleId, ") unlocked : ",
			tostring(unlocked)))
    end
end

-- -----------------------------------------------------------------------
-- experimental functions - not ready for prime-time
function sfutil.gettags(bagId,slotId)
	local itemLink = GetItemLink(bagId, slotId)
    for i=1, GetItemLinkNumItemTags(itemLink) do
        local itemTagDescription, itemTagCategory = GetItemLinkItemTagInfo(itemLink, i)
		d(sfutil.str("slot: ",slotId,"  category: ",itemTagCategory,"  desc: ",itemTagDescription))
    end
end