-- LibSFUtils is already defined in prior loaded file

LibSFUtils = LibSFUtils or {}
local sfutil = LibSFUtils



-- -------------------------------------------------------

-- This enhanced version of ESO's SafeAddString() will create the
-- string if it does not already exist (new behaviour) and overwrite
-- the string if it does exist and is not an older version (original
-- behaviour).
-- in the first use case, stringId is a "string" type
-- in the second use case, stringId is a "number" type (the actual ID)
-- a third use case allows using SafeAddString to overwrite an existing
--   string definition with the "name" of the id passed in vs the numeric id
--
-- Note that based on testing of the 100026 version of ZOS's SafeAddString(),
-- it does NOT properly enforce version protection.
function sfutil.SafeAddString(stringId, stringValue, stringVersion)
    if not stringId then return end
    
    local id = stringId
    if type(stringId) == "string" then
        id = _G[stringId]
        if not id then
            ZO_CreateStringId(stringId, stringValue)
            id = _G[stringId]
            SafeAddVersion(id, stringVersion)
        else
            SafeAddString(id, stringValue, stringVersion)
        end
    elseif type(stringId) == "number" then
        if not GetString(stringId) then
            -- It's really a bad idea to add this without first doing the ZO_CreateString
            -- although ZOS allows it.
            assert(false,"Tried to use LibSFUtils.SafeAddString on a numeric stringId that a string had not been created for.")
        else
            SafeAddString(stringId, stringValue, stringVersion)
        end
    else
        assert(false,"Tried to use LibSFUtils.SafeAddString on a stringId that was not a string or a number(id)")
    end
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
    else
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
        else
            -- current language is not in lang_strings table
            --d("LoadLanguage: Current language ("..lang..") is not in lang_strings table")
        end
    end
end
