package.path = package.path .. ";C:/Users/scott/Documents/SFAddons/TK/?.lua;C:/Users/scott/Documents/Elder Scrolls Online/live/AddOns/LibSFUtils/?.lua"

require "zos"
require "tk"
local TK = TestKit

require "LibSFUtils_Global"
require "SFUtils_Logger"
require "SFUtils_Strings"
require "SFUtils_Color"
require "LibSFUtils"
local SF = LibSFUtils

local moduleName = "stripColors"
local mn = moduleName


-- -------------------------------------------------------
-- tests
-- -------------------------------------------------------

local function test_stripColorsNoMarkers()
    TK.printSuite(mn, "testing stripColors no markers...")

    local str = "Hello world"
    local markers = SF.getAllColorDelim(str)

    local result = SF.stripColors(markers, str)

    TK.assertTrue(result == str, "unchanged string")
end


local function test_stripColorsSingleColor()
    TK.printSuite(mn, "testing stripColors single color...")

    local str = "|cFF0000Hello|r"
    local markers = SF.getAllColorDelim(str)

    local result = SF.stripColors(markers, str)

    TK.assertTrue(result == "Hello", "stripped " .. result)
end


local function test_stripColorsMultipleColors()
    TK.printSuite(mn, "testing stripColors multiple colors...")

    local str = "|cFF0000Red|r and |c00FF00Green|r"
    local markers = SF.getAllColorDelim(str)

    local result = SF.stripColors(markers, str)

    TK.assertTrue(result == "Red and Green", "stripped " .. result)
end

local function test_stripColorsEscapedPipe()
    TK.printSuite(mn, "testing stripColors escaped pipe...")

    local str = "Price ||100|| gold"
    local markers = SF.getAllColorDelim(str)

    local result = SF.stripColors(markers, str)

    TK.assertTrue(result == str, "escaped pipes preserved")
end

local function test_stripColorsMixedPipes()
    TK.printSuite(mn, "testing stripColors mixed escaped pipes...")

    local str = "Value ||100|| |cFF0000red|r ||200||"
    local markers = SF.getAllColorDelim(str)

    local result = SF.stripColors(markers, str)

    TK.assertTrue(result == "Value ||100|| red ||200||",
        "mixed markers and escaped pipes")
end

local function test_stripColorsNil()
    TK.printSuite(mn, "testing stripColors nil...")

    TK.assertTrue(SF.stripColors(nil, nil) == nil,
        "nil string returns nil")
end

local function test_stripColorsEmptyMarkers()
    TK.printSuite(mn, "testing stripColors empty markers...")

    local str = "Hello world"

    TK.assertTrue(SF.stripColors({}, str) == str,
        "empty marker table")

    TK.assertTrue(SF.stripColors(nil, str) == str,
        "nil marker table")
end

local function test_stripColorsReset()
    TK.printSuite(mn, "testing stripColors reset...")

    local str = "Hello|rWorld"
    local markers = SF.getAllColorDelim(str)

    local result = SF.stripColors(markers, str)

    TK.assertTrue(result == "HelloWorld", "reset stripped")
end

local function test_stripColorsUnterminated()
    TK.printSuite(mn, "testing stripColors unterminated color...")

    local str = "|cFF0000Hello"
    local markers = SF.getAllColorDelim(str)

    local result = SF.stripColors(markers, str)

    TK.assertTrue(result == "Hello", "unterminated color stripped")
end

function StripColors_runAll()
    test_stripColorsNoMarkers()
    test_stripColorsSingleColor()
    test_stripColorsMultipleColors()
    test_stripColorsEscapedPipe()
    test_stripColorsMixedPipes()
    test_stripColorsNil()
    test_stripColorsEmptyMarkers()
    test_stripColorsReset()
    test_stripColorsUnterminated()
end


if not Suite then
    TK.init()
    StripColors_runAll()
    TK.showResult("sfutil.stripColors Tests")
end
