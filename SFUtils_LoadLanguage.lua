-- LibSFUtils is already defined in prior loaded file

local sfutil = LibSFUtils
assert(sfutil, "LibSFUtils_Global must be loaded before this file")



-- -------------------------------------------------------

--[[
    sfutil.SafeAddString - Enhanced String Registration (Corrected)

    Safely adds string resources with support for both string names and numeric IDs.
    Implements ZOS version-protection logic with additional safety features.

    Parameters:
        stringId - Can be a string name ("SI_MY_STRING") or numeric ID (10001)
        stringValue - The text value to associate with this ID
        stringVersion - Version number for update protection

    Returns:
        boolean - true if string was added/updated, false if rejected (older version)
        number/string - The resolved string ID (or nil if failed)
--]]
function sfutil.SafeAddString(stringId, stringValue, stringVersion)
    -- Validate required parameters
    if not stringId or not stringValue then
        --d("[SFUtils] SafeAddString: missing required parameters (stringId, stringValue)")
        return false, nil
    end

    -- Normalize stringVersion to number (default to 1 if nil)
    local version = tonumber(stringVersion) or 1

    -- Resolve stringId to numeric ID
    local id
    if type(stringId) == "string" then
        -- String name: check if global exists, create if not
        id = _G[stringId]

        if not id then
            -- Create the string name and ID using native ZOS API
            ZO_CreateStringId(stringId, stringValue)
            id = _G[stringId]
            
            if not id then
                --d("[SFUtils] SafeAddString: failed to create ID for string name: " .. tostring(stringId))
                return false, nil
            end

            -- Register version immediately since this is first creation
            SafeAddVersion(id, version)

        else
            -- Name exists, use SafeAddString for version protection
            -- Call native ESO SafeAddString (not this function!)
            SafeAddString(id, stringValue, version)
        end

    elseif type(stringId) == "number" then
        -- Numeric ID: verify it exists before attempting to use
        local existingValue = GetString(stringId)
        if not existingValue then
            -- Log warning but don't crash - caller can handle this
            --d("[SFUtils] SafeAddString: numeric ID not registered: " .. tostring(stringId))
            return false, nil
        end

        -- Use native SafeAddString for version protection
        -- This calls ESO's native SafeAddString, not this function (avoids recursion)
        SafeAddString(stringId, stringValue, version)
        id = stringId

    else
        --d("[SFUtils] SafeAddString: invalid stringId type: " .. type(stringId))
        return false, nil
    end

    -- Verify the string was added by checking current value
    local currentValue = GetString(id)
    
    -- Return success if value exists now
    return currentValue ~= nil, id
end

--[[
    Helper function to check if a string was successfully added
--]]
function sfutil.StringExists(stringId)
    local id = type(stringId) == "string" and _G[stringId] or stringId
    if not id then return false end
    return GetString(id) ~= nil
end

--[[
    Helper function to get string value by name or ID
--]]
function sfutil.GetStringById(stringId)
    local id = type(stringId) == "string" and _G[stringId] or stringId
    if not id then return nil end
    return GetString(id)
end


-- load strings for the client language (or default if the
-- client language is not supported)
--
function sfutil.LoadLanguage(lang_strings, defaultLang)
    if lang_strings == nil or type(lang_strings) ~= "table"then 
        -- invalid parameter
        --d("LoadLanguage: Invalid lang_strings parameter")
        return 
    end
    defaultLang = sfutil.nilDefault(defaultLang, "en")

    -- get current language
    local lang = GetCVar("language.2")

    --check for supported languages
    local chosen = lang
    if lang_strings[lang] == nil then
        chosen = defaultLang
    end

    if( lang_strings[chosen] == nil or type(lang_strings[chosen]) ~= "table" ) then
        -- chosen language is not in lang_strings table
        --d("LoadLanguage: Chosen language is not in lang_strings table")
        assert(false,"Could not find localization tables for default ("..defaultLang..") or current ("..lang..") languages")
        return
    end

    -- load strings for default language
    local dlocalstr = lang_strings[defaultLang]
    if lang_strings[defaultLang] then
        for stringId, stringValue in pairs(dlocalstr) do
            sfutil.SafeAddString(stringId, stringValue, 1)
        end

    --else
        -- default language is not in lang_strings table
        --d("LoadLanguage: Default language ("..defaultLang..") is not in lang_strings table")
    end

    -- load strings for current language
    if lang ~= defaultLang then
        local localstr = lang_strings[lang]
        if lang_strings[lang] then
            for stringId, stringValue in pairs(localstr) do
                sfutil.SafeAddString(stringId, stringValue, 2)
            end

        --else
            -- current language is not in lang_strings table
            --d("LoadLanguage: Current language ("..lang..") is not in lang_strings table")
        end
    end
end
