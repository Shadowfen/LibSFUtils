package.path = package.path .. ";C:/Users/scott/Documents/SFAddons/TK/?.lua;C:/Users/scott/Documents/Elder Scrolls Online/live/AddOns/LibSFUtils/?.lua"

require "zos"
require "tk"
local TK = TestKit

require "LibSFUtils_Global"
require "SFUtils_Strings"
require "SFUtils_Color"
require "LibSFUtils"
require "SFUtils_LoadLanguage"
local SF = LibSFUtils

local TR = test_log

local moduleName = "SFUtils_LoadLanguage"
local mn = moduleName

local TEST_NUMERIC_ID = 10001

-- Helper to reset string tables
function resetStringTables()
    ZO_StringTable = {}
    EsoStrings = {}
    EsoStringNames = {}
    EsoStringVersions = {}
    SetCVar("language.2", "en")
end

local function LoadLanguage_testSafeAddStringWithStringId()
    local fn = "testSafeAddStringWithStringId"
    TK.printSuite(mn,fn)
    
    resetStringTables()
    
    local stringName = "TEST_STRING_1"
    local value = "Test Value 1"
    
    -- Should create the string since it doesn't exist
    local id = _G[stringName]
    TK.assertNil(id, "string name not defined yet")
    
    SF.SafeAddString(stringName, value, 1)
    
    id = _G[stringName]
    TK.assertNotNil(id, "string ID created")
    TK.assertTrue(type(id) == "number", "ID is a number")
    TK.assertEqual(GetString(id), value, "string value set correctly")
end

local function LoadLanguage_testSafeAddStringWithNumericId()
    local fn = "testSafeAddStringWithNumericId"
    TK.printSuite(mn,fn)
    
    resetStringTables()
    
    -- First create a string ID normally
    ZO_CreateStringId("TEST_NUMERIC_ID", "Initial Value")
    local id = _G.TEST_NUMERIC_ID
    
    -- Now use SafeAddString with the numeric ID
    local newValue = "Updated Value"
    SF.SafeAddString(id, newValue, 2)
    
    TK.assertEqual(GetString(id), newValue, "value updated via numeric ID")
end

local function LoadLanguage_testSafeAddStringOverwritesLowerVersion()
    new_fn = "testSafeAddStringOverwritesLowerVersion"
    TK.printSuite(mn,new_fn)
    
    resetStringTables()
    
    local stringName = "TEST_VERSION"
    local value1 = "Version 1"
    local value2 = "Version 2"
    
    -- Add version 1
    SF.SafeAddString(stringName, value1, 1)
    local id = _G[stringName]
    
    TK.assertEqual(GetString(id), value1, "version 1 set")
    
    -- Add version 2 (higher) - should overwrite
    SF.SafeAddString(stringName, value2, 2)
    TK.assertEqual(GetString(id), value2, "version 2 overwrote version 1")
end

local function LoadLanguage_testSafeAddStringKeepsHigherVersion()
    local fn = "testSafeAddStringKeepsHigherVersion"
    TK.printSuite(mn,fn)
    
    resetStringTables()
    
    local stringName = "TEST_VERSION_KEEP"
    local value1 = "Version 1"
    local value2 = "Old Version"
    
    -- Add version 2 first (higher)
    SF.SafeAddString(stringName, value1, 2)
    local id = _G[stringName]
    
    TK.assertEqual(GetString(id), value1, "version 2 set first")
    
    -- Try to add version 1 (lower) - should NOT overwrite
    SF.SafeAddString(stringName, value2, 1)
    TK.assertEqual(GetString(id), value1, "version 2 kept, version 1 rejected")
end

local function LoadLanguage_testLoadEnglishOnly()
    local fn = "testLoadEnglishOnly"
    TK.printSuite(mn,fn)
    
    resetStringTables()
    SetCVar("language.2", "de")  -- Client language is German
    
    local lang_strings = {
        en = {
            ENG_TXT_1 = "English Text 1",
            ENG_TXT_2 = "English Text 2",
        }
    }
    
    SF.LoadLanguage(lang_strings, "en")
    TK.assertEqual(GetString(ENG_TXT_1), "English Text 1", "english string 1 loaded")
    TK.assertEqual(GetString(ENG_TXT_2), "English Text 2", "english string 2 loaded")
end

local function LoadLanguage_testLoadFrenchFallback()
    local fn = "testLoadFrenchFallback"
    TK.printSuite(mn,fn)
    
    resetStringTables()
    SetCVar("language.2", "fr")  -- Client language is French
    
    local lang_strings = {
        en = {
            TEXT1 = "English Fallback 1",
            TEXT2 = "English Fallback 2",
        },
        fr = {
            TEXT1 = "Français Texte 1",
        }
    }
    
    SF.LoadLanguage(lang_strings, "en")   -- default language is english
    
    -- French string should be loaded
    TK.assertEqual(GetString(TEXT1), "Français Texte 1", "french string loaded")
    
    -- English string should also be loaded (both versions get added)
    TK.assertEqual(GetString(TEXT2), "English Fallback 2", "english string 2 loaded")
end

local function LoadLanguage_testLoadUnsupportedLanguage()
    local fn = "testLoadUnsupportedLanguage"
    TK.printSuite(mn,fn)
    
    resetStringTables()
    SetCVar("language.2", "de")  -- German is NOT in our lang_strings
    
    local lang_strings = {
        en = {
            VA_ONLY = "English Only",
        },
        fr = {
            VA_ONLY = "French Only",
        }
    }
    
    -- Should fall back to English and not crash
    SF.LoadLanguage(lang_strings, "en")
    
    TK.assertEqual(GetString(VA_ONLY), "English Only", "fallback to english")
end

local function LoadLanguage_testLoadGermanSupported()
    local fn = "testLoadGermanSupported"
    TK.printSuite(mn,fn)
    
    resetStringTables()
    SetCVar("language.2", "de")
    
    local lang_strings = {
        en = {
            TEXT1 = "English Text",
        },
        de = {
            TEXT1 = "Deutscher Text",
            TEXT2 = "No English Equivalent",
        }
    }
    
    SF.LoadLanguage(lang_strings, "en")
    
    TK.assertEqual(GetString(TEXT1), "Deutscher Text", "german string loaded")
    TK.assertEqual(GetString(TEXT2), "No English Equivalent", "german exclusive string loaded")
end

local function LoadLanguage_testNullLangStrings()
    local fn = "testNullLangStrings"
    TK.printSuite(mn,fn)
    
    resetStringTables()
    SetCVar("language.2", "en")
    
    local ok, err = pcall(function()
        SF.LoadLanguage(nil, "en")
    end)
    
    TK.assertTrue(ok, "loadLanguage with nil does not crash")
    -- Should return early without error
end

local function LoadLanguage_testInvalidLangStrings()
    local fn = "testInvalidLangStrings"
    TK.printSuite(mn,fn)
    
    resetStringTables()
    SetCVar("language.2", "en")
    
    local ok, err = pcall(function()
        SF.LoadLanguage("not_a_table", "en")
    end)
    
    TK.assertTrue(ok, "loadLanguage with string does not crash")
end

local function LoadLanguage_testMissingDefaultLanguage()
    local fn = "testMissingDefaultLanguage"
    TK.printSuite(mn,fn)
    
    resetStringTables()
    SetCVar("language.2", "en")
    
    -- Both en and fr are missing from lang_strings
    local lang_strings = {
        de = {
            [9001] = "German Only",
        }
    }
    
    local ok, err = pcall(function()
        SF.LoadLanguage(lang_strings, "en")
    end)
    
    TK.assertFalse(ok, "missing default language should raise error")
end

local function LoadLanguage_testSameLanguageClientAndDefault()
    local fn = "testSameLanguageClientAndDefault"
    TK.printSuite(mn,fn)
    
    resetStringTables()
    SetCVar("language.2", "en")
    
    local lang_strings = {
        en = {
            OE1 = "Only English",
        }
    }
    
    SF.LoadLanguage(lang_strings, "en")
    
    TK.assertEqual(GetString(OE1), "Only English", "english loaded")
    -- Should not attempt to load twice
end


local function LoadLanguage_testVersionTracking()
    local fn = "testVersionTracking"
    TK.printSuite(mn,fn)
    
    resetStringTables()
    SetCVar("language.2", "en")
    
    local lang_strings = {
        en = {
            VER_1_STR = "Version 1 String",
        }
    }
    
    SF.LoadLanguage(lang_strings, "en")
    local id = _G.VER_1_STR
    
    TK.assertEqual(EsoStringVersions[id], 1, "version set to 1")
    TK.assertEqual(GetString(id), "Version 1 String", "value set")
end

local function LoadLanguage_testMultipleCalls()
    local fn = "testMultipleCalls"
    TK.printSuite(mn,fn)
    
    resetStringTables()
    SetCVar("language.2", "en")
    
    local lang_strings = {
        en = {
            ORTXT = "Original Text",
        }
    }
    
    -- Load twice
    SF.LoadLanguage(lang_strings, "en")
    SF.LoadLanguage(lang_strings, "en")
    
    TK.assertEqual(GetString(ORTXT), "Original Text", "text unchanged after reload")
    TK.assertEqual(_G.EsoStringVersions[ORTXT], 1, "version unchanged")
end

local function LoadLanguage_testDifferentLanguagesReload()
    local fn = "testDifferentLanguagesReload"
    TK.printSuite(mn,fn)
    
    resetStringTables()
    SetCVar("language.2", "en")
    
    local lang_strings = {
        en = {
            S14001 = "English Version",
        },
        fr = {
            S14001 = "French Version",
        }
    }
    
    -- Load English
    SF.LoadLanguage(lang_strings, "en")
    TK.assertEqual(GetString(S14001), "English Version", "english loaded first")
    
    -- Change language to French and reload
    SetCVar("language.2", "fr")
    SF.LoadLanguage(lang_strings, "fr")
    TK.assertEqual(GetString(S14001), "French Version", "french loaded second")
end

local function LoadLanguage_testEmptyLanguageTables()
    local fn = "testEmptyLanguageTables"
    TK.printSuite(mn,fn)
    
    resetStringTables()
    SetCVar("language.2", "en")
    
    local lang_strings = {
        en = {}
    }
    
    local ok, err = pcall(function()
        SF.LoadLanguage(lang_strings, "en")
    end)
    TK.assertTrue(ok, "empty language table does not crash")
end

local function LoadLanguage_testComplexLocalization()
    local fn = "testComplexLocalization"
    TK.printSuite(mn,fn)
    
    resetStringTables()
    SetCVar("language.2", "es")
    
    local lang_strings = {
        en = {
            q0001 = "Quest Started",
            i0002 = "Item Acquired: %s",
            g0003 = "Gold Found: %d",
        },
        es = {
            q0001 = "Misión Iniciada",
            i0002 = "Objeto Obtenido: %s",
        },
        fr = {
            q0001 = "Quête Démarrée",
        }
    }
    
    SF.LoadLanguage(lang_strings, "en")
    
    TK.assertEqual(GetString(q0001), "Misión Iniciada", "spanish loaded")
    TK.assertEqual(GetString(i0002), "Objeto Obtenido: %s", "spanish loaded")
    TK.assertEqual(GetString(g0003), "Gold Found: %d", "english fallback loaded")
end

function LoadLanguages_runTests()
    LoadLanguage_testSafeAddStringWithStringId()
    LoadLanguage_testSafeAddStringWithNumericId()
    LoadLanguage_testSafeAddStringOverwritesLowerVersion()
    LoadLanguage_testSafeAddStringKeepsHigherVersion()
    LoadLanguage_testLoadEnglishOnly()
    LoadLanguage_testLoadFrenchFallback()
    LoadLanguage_testLoadUnsupportedLanguage()
    LoadLanguage_testLoadGermanSupported()
    LoadLanguage_testNullLangStrings()
    LoadLanguage_testInvalidLangStrings()
    LoadLanguage_testMissingDefaultLanguage()
    LoadLanguage_testSameLanguageClientAndDefault()
    LoadLanguage_testVersionTracking()
    LoadLanguage_testMultipleCalls()
    LoadLanguage_testDifferentLanguagesReload()
    LoadLanguage_testEmptyLanguageTables()
    LoadLanguage_testComplexLocalization()
end

if not Suite then
    TK.init()
    
    LoadLanguages_runTests()
    
    TK.showResult("LoadLanguages_Test")
end
