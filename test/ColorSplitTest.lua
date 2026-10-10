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

local moduleName = "ColorSplit"
local mn = moduleName


-- -------------------------------------------------------
-- helpers
-- -------------------------------------------------------
local function assertFragments(actual, expected, message)
    TK.assertNotNil(actual, message .. " - result")

    TK.assertTrue( #actual == #expected,
        message .. " - fragment count: "
            .. #actual .. " expected " .. #expected)

    for i = 1, #expected do
        TK.assertTrue( actual[i] == expected[i],
            message .. " - fragment " .. i
                .. ": [" .. tostring(actual[i])
                .. "] expected [" .. tostring(expected[i]) .. "]")
    end
end


-- -------------------------------------------------------
-- tests
-- -------------------------------------------------------


-- -------------------------------------------------------
-- nil / empty input
-- -------------------------------------------------------

local function test_colorsplitNil()
    TK.printSuite(mn, "testing colorsplit nil...")

    local result = SF.colorsplit(nil, nil)

    TK.assertNotNil(result, "nil result")
    TK.assertTrue(#result == 0, "nil produces empty table")
end


local function test_colorsplitEmpty()
    TK.printSuite(mn, "testing colorsplit empty string...")

    local result = SF.colorsplit({}, "")

    TK.assertNotNil(result, "empty result")
    TK.assertTrue(#result == 0, "empty string produces empty table")
end


-- -------------------------------------------------------
-- no markers
-- -------------------------------------------------------

local function test_colorsplitNoMarkers()
    TK.printSuite(mn, "testing colorsplit no markers...")

    local str = "plain text"
    local result = SF.colorsplit(nil, str)

    assertFragments(result,
        { "plain text" },
        "no markers")

    TK.assertTrue(table.concat(result) == str,
        "no markers reconstruct original")
end


local function test_colorsplitEmptyMarkers()
    TK.printSuite(mn, "testing colorsplit empty marker table...")

    local str = "plain text"
    local result = SF.colorsplit({}, str)

    assertFragments(result,
        { "plain text" },
        "empty markers")

    TK.assertTrue(table.concat(result) == str,
        "empty markers reconstruct original")
end


-- -------------------------------------------------------
-- ordinary color marker
-- -------------------------------------------------------

local function test_colorsplitColor()
    TK.printSuite(mn, "testing colorsplit color marker...")

    local str = "Hello |cFF0000red|r world"
    local markers = SF.getAllColorDelim(str)

    local result = SF.colorsplit(markers, str)

    assertFragments(result,
        {
            "Hello ",
            "|cFF0000",
            "red",
            "|r",
            " world",
        },
        "ordinary color")

    TK.assertTrue(table.concat(result) == str,
        "ordinary color reconstructs")
end


-- -------------------------------------------------------
-- uppercase marker is canonicalized
-- -------------------------------------------------------

local function test_colorsplitUppercaseMarker()
    TK.printSuite(mn, "testing colorsplit uppercase marker...")

    local str = "Hello |CFF0000red|R world"
    local markers = SF.getAllColorDelim(str)

    local result = SF.colorsplit(markers, str)

    assertFragments(
        result,
        {
            "Hello ",
            "|cFF0000",
            "red",
            "|r",
            " world",
        },
        "uppercase marker"
    )

    TK.assertTrue(
        table.concat(result) == "Hello |cFF0000red|r world",
        "uppercase markers canonicalized"
    )
end


-- -------------------------------------------------------
-- multiple colors
-- -------------------------------------------------------

local function test_colorsplitMultipleColors()
    TK.printSuite(mn, "testing colorsplit multiple colors...")

    local str =
        "A |cFF0000red|r B |c00FF00green|r C"

    local markers = SF.getAllColorDelim(str)
    local result = SF.colorsplit(markers, str)

    assertFragments(
        result,
        {
            "A ",
            "|cFF0000",
            "red",
            "|r",
            " B ",
            "|c00FF00",
            "green",
            "|r",
            " C",
        },
        "multiple colors"
    )

    TK.assertTrue(table.concat(result) == str,
        "multiple colors reconstruct")
end


-- -------------------------------------------------------
-- unnecessary reset
-- -------------------------------------------------------

local function test_colorsplitUnnecessaryReset()
    TK.printSuite(mn, "testing colorsplit unnecessary reset...")

    local str = "Hello|rWorld"

    local markers = SF.getAllColorDelim(str)
    markers = SF.regularizeColors(markers, str)

    local result = SF.colorsplit(markers, str)

    assertFragments(
        result,
        {
            "Hello",
            "World",
        },
        "unnecessary reset removed"
    )

    TK.assertTrue(table.concat(result) == "HelloWorld",
        "unnecessary reset stripped")
end


-- -------------------------------------------------------
-- empty color
-- -------------------------------------------------------

local function test_colorsplitEmptyColor()
    TK.printSuite(mn, "testing colorsplit empty color...")

    local str = "before|cFF0000|rafter"

    local markers = SF.getAllColorDelim(str)
    markers = SF.regularizeColors(markers, str)

    local result = SF.colorsplit(markers, str)

    assertFragments(
        result,
        {
            "before",
            "after",
        },
        "empty color removed"
    )

    TK.assertTrue(table.concat(result) == "beforeafter",
        "empty color stripped")
end


-- -------------------------------------------------------
-- adjacent colors
-- -------------------------------------------------------

local function test_colorsplitAdjacentColors()
    TK.printSuite(mn, "testing colorsplit adjacent colors...")

    local str = "|cFF0000|c00FF00green"

    local markers = SF.getAllColorDelim(str)
    markers = SF.regularizeColors(markers, str)

    local result = SF.colorsplit(markers, str)

    assertFragments(
        result,
        {
            "|c00FF00",
            "green",
            "|r",
        },
        "adjacent colors"
    )

    TK.assertTrue(table.concat(result) == "|c00FF00green|r",
        "adjacent colors normalized")
end


-- -------------------------------------------------------
-- missing reset
-- -------------------------------------------------------

local function test_colorsplitMissingReset()
    TK.printSuite(mn, "testing colorsplit missing reset...")

    local str = "before|cFF0000red"

    local markers = SF.getAllColorDelim(str)
    markers = SF.regularizeColors(markers, str)

    local result = SF.colorsplit(markers, str)

    assertFragments(
        result,
        {
            "before",
            "|cFF0000",
            "red",
            "|r",
        },
        "missing reset"
    )

    TK.assertTrue(
        table.concat(result) == "before|cFF0000red|r",
        "missing reset inserted"
    )
end


-- -------------------------------------------------------
-- missing reset before another color
-- -------------------------------------------------------

local function test_colorsplitMissingResetBeforeColor()
    TK.printSuite(mn, "testing colorsplit missing reset before color...")

    local str = "A|cFF0000redB|c00FF00green"

    local markers = SF.getAllColorDelim(str)
    markers = SF.regularizeColors(markers, str)

    local result = SF.colorsplit(markers, str)

    assertFragments(
        result,
        {
            "A",
            "|cFF0000",
            "redB",
            "|r",
            "|c00FF00",
            "green",
            "|r",
        },
        "missing reset before color"
    )

    TK.assertTrue(
        table.concat(result) ==
            "A|cFF0000redB|r|c00FF00green|r",
        "missing reset before color inserted"
    )
end


-- -------------------------------------------------------
-- synthetic + marker directly
-- -------------------------------------------------------

local function test_colorsplitSyntheticReset()
    TK.printSuite(mn, "testing colorsplit synthetic reset...")

    local str = "abcdef"

    local markers = {
        {
            start = 4,
            estr = 4,
            code = "r",
            action = "+",
        },
    }

    local result = SF.colorsplit(markers, str)

    assertFragments(
        result,
        {
            "abc",
            "|r",
            "def",
        },
        "synthetic reset"
    )

    TK.assertTrue(
        table.concat(result) == "abc|rdef",
        "synthetic reset does not consume source text"
    )
end


-- -------------------------------------------------------
-- synthetic reset at end of string
-- -------------------------------------------------------

local function test_colorsplitSyntheticResetAtEnd()
    TK.printSuite(mn, "testing colorsplit synthetic reset at end...")

    local str = "abcdef"

    local markers = {
        {
            start = #str + 1,
            estr = #str + 1,
            code = "r",
            action = "+",
        },
    }

    local result = SF.colorsplit(markers, str)

    TK.assertNotNil(result, "synthetic end result")

    TK.assertTrue(
        table.concat(result) == "abcdef|r",
        "synthetic reset at end"
    )
end


-- -------------------------------------------------------
-- action '-' color
-- -------------------------------------------------------

local function test_colorsplitRemovedColor()
    TK.printSuite(mn, "testing colorsplit removed color...")

    local str = "A|cFF0000B|c00FF00C"

    local markers = SF.getAllColorDelim(str)

    -- Remove the first color explicitly.
    markers[1].action = "-"

    local result = SF.colorsplit(markers, str)

    TK.assertTrue(
        table.concat(result) == "AB|c00FF00C",
        "removed color marker"
    )
end


-- -------------------------------------------------------
-- action '-' reset
-- -------------------------------------------------------

local function test_colorsplitRemovedReset()
    TK.printSuite(mn, "testing colorsplit removed reset...")

    local str = "A|cFF0000B|rC"

    local markers = SF.getAllColorDelim(str)

    -- Remove the reset explicitly.
    markers[2].action = "-"

    local result = SF.colorsplit(markers, str)

    TK.assertTrue(
        table.concat(result) == "A|cFF0000BC",
        "removed reset marker"
    )
end


-- -------------------------------------------------------
-- skipped marker
-- -------------------------------------------------------

local function test_colorsplitSkippedMarker()
    TK.printSuite(mn, "testing colorsplit skipped marker...")

    local str = "A|cFF0000B|rC"

    local markers = SF.getAllColorDelim(str)

    -- A skipped color marker should not be processed.
    markers[1].start = -1
    markers[1].action = "-"

    local result = SF.colorsplit(markers, str)

    TK.assertNotNil(result, "skipped marker result")
end


-- -------------------------------------------------------
-- mixed text and colors
-- -------------------------------------------------------

local function test_colorsplitMixed()
    TK.printSuite(mn, "testing colorsplit mixed string...")

    local str =
        "one |cFF0000red|r two |c00FF00green|r three"

    local markers = SF.getAllColorDelim(str)
    markers = SF.regularizeColors(markers, str)

    local result = SF.colorsplit(markers, str)

    TK.assertTrue(
        table.concat(result) == str,
        "mixed string reconstructs"
    )

    TK.assertTrue(
        #result == 9,
        "mixed string fragment count"
    )
end


-- -------------------------------------------------------
-- malformed color marker
-- -------------------------------------------------------

local function test_colorsplitMalformedColor()
    TK.printSuite(mn, "testing colorsplit malformed color...")

    local str = "before|cGGGGGGafter"

    local markers = {
        {
            start = 7,
            estr = 14,
            code = "c",
        },
    }

    local result = SF.colorsplit(markers, str)

    TK.assertNotNil(result, "malformed result")

    TK.assertTrue(
        table.concat(result) == str,
        "malformed marker leaves remainder unchanged"
    )
end


-- -------------------------------------------------------
-- run all colorsplit tests
-- -------------------------------------------------------

function test_runAllColorSplit()
    test_colorsplitNil()
    test_colorsplitEmpty()
    test_colorsplitNoMarkers()
    test_colorsplitEmptyMarkers()

    test_colorsplitColor()
    test_colorsplitUppercaseMarker()
    test_colorsplitMultipleColors()

    test_colorsplitUnnecessaryReset()
    test_colorsplitEmptyColor()
    test_colorsplitAdjacentColors()

    test_colorsplitMissingReset()
    test_colorsplitMissingResetBeforeColor()

    test_colorsplitSyntheticReset()
    test_colorsplitSyntheticResetAtEnd()

    test_colorsplitRemovedColor()
    test_colorsplitRemovedReset()
    test_colorsplitSkippedMarker()

    test_colorsplitMixed()
    test_colorsplitMalformedColor()
end



if not Suite then
    TK.init()
    test_runAllColorSplit()
    TK.showResult("sfutil.colorsplit Tests")
end
