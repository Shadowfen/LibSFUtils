-- LibSFUtils is already defined in prior loaded file

LibSFUtils = LibSFUtils or {}
local sfutil = LibSFUtils

----------------------------
-- Saved Variables helpers
----------------------------
-- Get saved variables table toon only
-- Note: This does NOT automatically add an accountWide variable to the
--    table if it is not already there!
--
-- SavedVars are retrieved for the current server that you are on.
function sfutil.getToonSavedVars(saveFile, saveVer, saveDefaults)
    local toon = ZO_SavedVars:NewCharacterIdSettings(saveFile, saveVer, 
					GetWorldName(), saveDefaults)
    sfutil.defaultMissing(toon, saveDefaults)
    return toon
end

-- Get saved variables table account-wide only
--
-- SavedVars are retrieved for the current server that you are on.
function sfutil.getAcctSavedVars(saveFile, saveVer, saveDefaults)
    local aw = ZO_SavedVars:NewAccountWide(saveFile, saveVer, 
					GetWorldName(), saveDefaults)
    sfutil.defaultMissing(aw, saveDefaults)
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
        local toon = ZO_SavedVars:NewCharacterIdSettings(saveFileName, saveVer, 
						GetWorldName())
        toon.accountWide = sfutil.nilDefault(toon.accountWide, true)
        return aw, toon
    end
    
    if saveAWDefaults == nil then
        saveAWDefaults = saveToonDefaults
    end
    if saveToonDefaults == nil then
        saveToonDefaults = saveAWDefaults
    end
    local aw = ZO_SavedVars:NewAccountWide(saveFileName, saveVer, 
					GetWorldName(), saveAWDefaults)
    local toon = ZO_SavedVars:NewCharacterIdSettings(saveFileName, saveVer, 
					GetWorldName(), saveToonDefaults)
    sfutil.defaultMissing(aw, saveAWDefaults)
    sfutil.defaultMissing(toon, saveToonDefaults)
	toon.accountWide = sfutil.nilDefault(toon.accountWide, true)
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

