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

local moduleName = "regularizeColors"
local mn = moduleName


-- -------------------------------------------------------
-- helpers
-- -------------------------------------------------------

local function assertMarkersEqual(actual, expected, message)
    TK.assertEqual(#actual, #expected,
        message .. " (marker count)")

    for i = 1, #expected do
        local a = actual[i]
        local e = expected[i]
        local prefix = message .. " marker " .. i

        TK.assertEqual(a.start, e.start,
            prefix .. " start")

        TK.assertEqual(a.estr, e.estr,
            prefix .. " estr")

        TK.assertEqual(a.code, e.code,
            prefix .. " code")

        if e.action == nil then
            TK.assertTrue(a.action == nil,
                prefix .. " action should be nil")
        else
            TK.assertEqual(a.action, e.action,
                prefix .. " action")
        end
    end
end

local function marker(start, estr, code, action)
    return {
        start = start,
        estr = estr,
        code = code,
        action = action,
    }
end

-- -------------------------------------------------------
-- tests
-- -------------------------------------------------------


-- -------------------------------------------------------
-- Empty / invalid input
-- -------------------------------------------------------

local function testRegularizeColors_nilString()
    TK.printSuite(mn,"nilString")
    local markers = {
        marker(1, 8, "c"),
    }

    local result = SF.regularizeColors(markers, nil)

    assertMarkersEqual(result, {},
        "nil string should return an empty table")
end


local function testRegularizeColors_nilMarkers()
    TK.printSuite(mn,"nilMarkers")
    local result = SF.regularizeColors(nil, "abc")

    assertMarkersEqual(result, {},
        "nil markers should return an empty table")
end


local function testRegularizeColors_emptyMarkers()
    TK.printSuite(mn,"emptyMarkers")
    local result = SF.regularizeColors({}, "abc")

    assertMarkersEqual(result, {},
        "empty markers should return an empty table")
end

local function testRegularizeColors_emptyString()
    TK.printSuite(mn,"emptyString")

    local result = SF.regularizeColors({}, "")

    assertMarkersEqual(result, {},
        "empty string with no markers should return an empty table")
end

-- -------------------------------------------------------
-- Unnecessary reset markers
-- -------------------------------------------------------

local function testRegularizeColors_unnecessaryReset()
    TK.printSuite(mn,"unnecessaryReset")
    local markers = {
        marker(1, 2, "r"),
    }

    local result = SF.regularizeColors(markers, "|rabc")

    assertMarkersEqual(result, {
        marker(1, 2, "r", "-"),
    }, "unnecessary reset should be removed")
end


local function testRegularizeColors_multipleUnnecessaryResets()
    TK.printSuite(mn,"multipleUnnecessaryResets")
    local markers = {
        marker(1, 2, "r"),
        marker(4, 5, "r"),
        marker(7, 8, "r"),
    }

    local result = SF.regularizeColors(markers, "|rabc|rdef|r")

    assertMarkersEqual(result, {
        marker(1, 2, "r", "-"),
        marker(4, 5, "r", "-"),
        marker(7, 8, "r", "-"),
    }, "all unnecessary resets should be removed")
end


-- -------------------------------------------------------
-- Normal color / reset pairs
-- -------------------------------------------------------

function testRegularizeColors_validColor()
    TK.printSuite(mn,"validColor")
    local markers = {
        marker(1, 8, "c"),
        marker(12, 13, "r"),
    }

    local result = SF.regularizeColors(markers, "|cFFFFFFabc|r")

    assertMarkersEqual(result, {
        marker(1, 8, "c"),
        marker(12, 13, "r"),
    }, "valid color should remain unchanged")
end


-- -------------------------------------------------------
-- Empty colors
-- -------------------------------------------------------

local function testRegularizeColors_emptyColor()
    TK.printSuite(mn,"emptyColor")
    local markers = {
        marker(1, 8, "c"),
        marker(9, 10, "r"),
    }

    local result = SF.regularizeColors(markers, "|cFFFFFF|r")

    assertMarkersEqual(result, {
        marker(1, 8, "c", "-"),
        marker(9, 10, "r", "-"),
    }, "empty color should be removed")
end


local function testRegularizeColors_emptyColorFollowedByText()
    TK.printSuite(mn,"emptyColorFollowedByText")
    local markers = {
        marker(1, 8, "c"),
        marker(9, 10, "r"),
        marker(11, 18, "c"),
        marker(22, 23, "r"),
    }

    local result = SF.regularizeColors(
        markers,
        "|cFFFFFF|r|cFF0000abc|r"
    )

    assertMarkersEqual(result, {
        marker(1, 8, "c", "-"),
        marker(9, 10, "r", "-"),
        marker(11, 18, "c", nil),
        marker(22, 23, "r", nil),
    }, "only the empty color should be removed")
end


-- -------------------------------------------------------
-- Missing final reset
-- -------------------------------------------------------

local function testRegularizeColors_missingFinalReset()
    TK.printSuite(mn,"missingFinalReset")
    local markers = {
        marker(1, 8, "c"),
    }

    local result = SF.regularizeColors(
        markers,
        "|cFFFFFFabc"
    )

    assertMarkersEqual(result, {
        marker(1, 8, "c", nil),
        marker(12, 12, "r", "+"),
    }, "missing final reset should be added")
end


local function testRegularizeColors_missingFinalResetAfterText()
    TK.printSuite(mn,"missingFinalResetAfterText")
    local markers = {
        marker(1, 8, "c"),
    }

    local str = "|cFFFFFFhello"

    local result = SF.regularizeColors(markers, str)

    assertMarkersEqual(result, {
        marker(1, 8, "c", nil),
        marker(#str + 1, #str + 1, "r", "+"),
    }, "final reset should be positioned after the string")
end


-- -------------------------------------------------------
-- Adjacent colors
-- -------------------------------------------------------

local function testRegularizeColors_adjacentColors()
    TK.printSuite(mn,"adjacentColors")
    local markers = {
        marker(1, 8, "c"),
        marker(9, 16, "c"),
    }

    local result = SF.regularizeColors(
        markers,
        "|cAAAAAA|cBBBBBB"
    )

    assertMarkersEqual(result, {
        marker(1, 8, "c", "-"),
        marker(9, 16, "c", nil),
        marker(17, 17, "r", "+"),
    }, "adjacent colors should discard the previous color")
end


local function testRegularizeColors_adjacentColorsWithReset()
    TK.printSuite(mn,"adjacentColorsWithReset")
    local markers = {
        marker(1, 8, "c"),
        marker(9, 16, "c"),
        marker(17, 18, "r"),
    }

    local result = SF.regularizeColors(
        markers,
        "|cAAAAAA|cBBBBBB|r"
    )

    assertMarkersEqual(result, {
        marker(1, 8, "c", "-"),
        marker(9, 16, "c", "-"),
        marker(17, 18, "r", "-"),
    }, "adjacent empty colors should all be removed")
end


-- -------------------------------------------------------
-- New color before previous color is closed
-- -------------------------------------------------------

local function testRegularizeColors_unclosedColor()
    TK.printSuite(mn,"unclosedColor")
    local markers = {
        marker(1, 8, "c"),
        marker(12, 19, "c"),
    }

    local result = SF.regularizeColors(
        markers,
        "|cAAAAAAabc|cBBBBBB"
    )

    assertMarkersEqual(result, {
        marker(1, 8, "c", nil),
        marker(12, 12, "r", "+"),
        marker(12, 19, "c", nil),
        marker(20, 20, "r", "+"),
    }, "missing reset should be inserted before new color")
end


function testRegularizeColors_unclosedColorThenReset()
    TK.printSuite(mn,"unclosedColorThenReset")
    local markers = {
        marker(1, 8, "c"),
        marker(12, 19, "c"),
        marker(20, 21, "r"),
    }

    local result = SF.regularizeColors(
        markers,
        "|cAAAAAAabc|cBBBBBB|r"
    )

    assertMarkersEqual(result, {
        marker(1, 8, "c"),
        marker(12, 12, "r", "+"),
        marker(12, 19, "c", "-"),
        marker(20, 21, "r", "-"),
    }, "empty new color should be removed after closing previous color")
end


-- -------------------------------------------------------
-- Multiple colors
-- -------------------------------------------------------

local function testRegularizeColors_multipleColors()
    TK.printSuite(mn,"multipleColors")
    local markers = {
        marker(1, 8, "c"),
        marker(12, 19, "c"),
        marker(23, 30, "c"),
    }

    local result = SF.regularizeColors(
        markers,
        "|cAAAAAAabc|cBBBBBBdef|cCCCCCC"
    )

    assertMarkersEqual(result, {
        marker(1, 8, "c", nil),
        marker(12, 12, "r", "+"),
        marker(12, 19, "c", nil),
        marker(23, 23, "r", "+"),
        marker(23, 30, "c", nil),
        marker(31, 31, "r", "+"),
    }, "each unclosed color should receive a reset")
end

local function testRegularizeColors_multipleClosedColors()
    TK.printSuite(mn,"multipleClosedColors")

    local markers = {
        marker(1, 8, "c"),
        marker(12, 19, "c"),
        marker(23, 30, "c"),
        marker(34, 35, "r"),
    }

    local result = SF.regularizeColors(
        markers,
        "|cAAAAAAabc|cBBBBBBdef|cCCCCCCghi|r"
    )

    assertMarkersEqual(result, {
        marker(1, 8, "c"),
        marker(12, 12, "r", "+"),
        marker(12, 19, "c"),
        marker(23, 23, "r", "+"),
        marker(23, 30, "c"),
        marker(34, 35, "r"),
    }, "multiple closed colors should insert resets between color transitions")
end


function testRegularizeColors_mixedAdjacentAndUnclosed()
    TK.printSuite(mn,"mixedAdjacentAndUnclosed")
    local markers = {
        marker(1, 8, "c"),
        marker(9, 14, "c"),
        marker(18, 25, "c"),
    }

    local result = SF.regularizeColors(
        markers,
        "|cAAAAAA|cBBBBabc|cCCCCCC"
    )

    assertMarkersEqual(result, {
        marker(1, 8,   "c", "-"),
        marker(9, 14,  "c"),
        marker(18, 18, "r", "+"),
        marker(18, 25, "c"),
        marker(26, 26, "r", "+"),
    }, "adjacent and non-adjacent colors should be handled independently")
end


-- -------------------------------------------------------
-- Empty color between colors
-- -------------------------------------------------------

local function testRegularizeColors_emptyColorBetweenColors()
    TK.printSuite(mn,"emptyColorBetweenColors")
    local markers = {
        marker(1, 8, "c"),
        marker(9, 10, "r"),
        marker(11, 18, "c"),
        marker(19, 20, "r"),
        marker(21, 28, "c"),
    }

    local result = SF.regularizeColors(
        markers,
        "|cAAAAAA|r|cBBBBBB|r|cCCCCCC"
    )

    assertMarkersEqual(result, {
        marker(1, 8, "c", "-"),
        marker(9, 10, "r", "-"),
        marker(11, 18, "c", "-"),
        marker(19, 20, "r", "-"),
        marker(21, 28, "c", nil),
        marker(29, 29, "r", "+"),
    }, "empty colors should be removed while final color remains")
end

-- -------------------------------------------------------
-- Reset after colored text
-- -------------------------------------------------------

local function testRegularizeColors_colorThenExtraReset()
    TK.printSuite(mn,"colorThenExtraReset")

    local markers = {
        marker(1, 8, "c"),
        marker(12, 13, "r"),
        marker(14, 15, "r"),
    }

    local result = SF.regularizeColors(
        markers,
        "|cFF0000abc|r|r"
    )

    assertMarkersEqual(result, {
        marker(1, 8, "c"),
        marker(12, 13, "r"),
        marker(14, 15, "r", "-"),
    }, "only the reset outside the color should be removed")
end


local function testRegularizeColors_colorThenText()
    TK.printSuite(mn,"colorThenText")

    local markers = {
        marker(1, 8, "c"),
        marker(12, 13, "r"),
    }

    local result = SF.regularizeColors(
        markers,
        "|cFF0000abc|rdef"
    )

    assertMarkersEqual(result, {
        marker(1, 8, "c"),
        marker(12, 13, "r"),
    }, "reset should remain when colored text is followed by plain text")
end


-- -------------------------------------------------------
-- Adjacent colors
-- -------------------------------------------------------

local function testRegularizeColors_adjacentColorsWithText()
    TK.printSuite(mn,"adjacentColorsWithText")

    local markers = {
        marker(1, 8, "c"),
        marker(9, 16, "c"),
        marker(25, 26, "r"),
    }

    local result = SF.regularizeColors(
        markers,
        "|cAAAAAA|cBBBBBBBlue text|r"
    )

    assertMarkersEqual(result, {
        marker(1, 8, "c", "-"),
        marker(9, 16, "c"),
        marker(25, 26, "r"),
    }, "previous adjacent color should be removed while active color remains")
end


local function testRegularizeColors_adjacentEmptyColorThenText()
    TK.printSuite(mn,"adjacentEmptyColorThenText")

    local markers = {
        marker(1, 8, "c"),
        marker(9, 16, "c"),
        marker(20, 21, "r"),
    }

    local result = SF.regularizeColors(
        markers,
        "|cAAAAAA|cBBBBBBabc|r"
    )

    assertMarkersEqual(result, {
        marker(1, 8, "c", "-"),
        marker(9, 16, "c"),
        marker(20, 21, "r"),
    }, "empty previous adjacent color should be removed")
end


-- -------------------------------------------------------
-- Color transitions
-- -------------------------------------------------------

local function testRegularizeColors_colorTransitionThenReset()
    TK.printSuite(mn,"colorTransitionThenReset")

    local markers = {
        marker(1, 8, "c"),
        marker(12, 19, "c"),
        marker(26, 27, "r"),
    }

    local result = SF.regularizeColors(
        markers,
        "|cAAAAAAabc|cBBBBBBdef|r"
    )

    assertMarkersEqual(result, {
        marker(1, 8, "c"),
        marker(12, 12, "r", "+"),
        marker(12, 19, "c"),
        marker(26, 27, "r"),
    }, "color transition should add a reset before the new color")
end


local function testRegularizeColors_emptyColorDuringTransition()
    TK.printSuite(mn,"emptyColorDuringTransition")

    local markers = {
        marker(1, 8, "c"),
        marker(12, 19, "c"),
        marker(20, 21, "r"),
    }

    local result = SF.regularizeColors(
        markers,
        "|cAAAAAAabc|cBBBBBB|r"
    )

    assertMarkersEqual(result, {
        marker(1, 8, "c"),
        marker(12, 12, "r", "+"),
        marker(12, 19, "c", "-"),
        marker(20, 21, "r", "-"),
    }, "empty replacement color should be removed after closing previous color")
end


local function testRegularizeColors_transitionToUnclosedColor()
    TK.printSuite(mn,"transitionToUnclosedColor")

    local markers = {
        marker(1, 8, "c"),
        marker(12, 19, "c"),
    }

    local str = "|cAAAAAAabc|cBBBBBBdef"

    local result = SF.regularizeColors(markers, str)

    assertMarkersEqual(result, {
        marker(1, 8, "c"),
        marker(12, 12, "r", "+"),
        marker(12, 19, "c"),
        marker(#str + 1, #str + 1, "r", "+"),
    }, "unclosed replacement color should receive a reset")
end


-- -------------------------------------------------------
-- Marker positions / codes
-- -------------------------------------------------------

local function testRegularizeColors_preservesMarkerPositions()
    TK.printSuite(mn,"preservesMarkerPositions")

    local markers = {
        marker(5, 12, "c"),
        marker(18, 19, "r"),
    }

    local result = SF.regularizeColors(
        markers,
        "abcd|cFFFFFFabc|r"
    )

    assertMarkersEqual(result, {
        marker(5, 12, "c"),
        marker(18, 19, "r"),
    }, "existing marker positions and codes should be preserved")
end

-- -------------------------------------------------------
-- Run all tests
-- -------------------------------------------------------

function testRegularizeColors_runAll()

    testRegularizeColors_nilString()
    testRegularizeColors_nilMarkers()
    testRegularizeColors_emptyMarkers()
    testRegularizeColors_emptyString()

    testRegularizeColors_unnecessaryReset()
    testRegularizeColors_multipleUnnecessaryResets()

    testRegularizeColors_validColor()


    testRegularizeColors_emptyColor()
    testRegularizeColors_emptyColorFollowedByText()
    testRegularizeColors_emptyColorBetweenColors()

    testRegularizeColors_missingFinalReset()
    testRegularizeColors_missingFinalResetAfterText()

    testRegularizeColors_adjacentColors()
    testRegularizeColors_adjacentColorsWithReset()
    testRegularizeColors_adjacentColorsWithText()
    testRegularizeColors_adjacentEmptyColorThenText()

    testRegularizeColors_unclosedColor()
    testRegularizeColors_unclosedColorThenReset()
    testRegularizeColors_colorTransitionThenReset()
    testRegularizeColors_emptyColorDuringTransition()
    testRegularizeColors_transitionToUnclosedColor()
    testRegularizeColors_multipleColors()
    testRegularizeColors_multipleClosedColors()
    testRegularizeColors_mixedAdjacentAndUnclosed()
    testRegularizeColors_colorThenExtraReset()
    testRegularizeColors_colorThenText()

    testRegularizeColors_preservesMarkerPositions()
end


if not Suite then
    TK.init()
    testRegularizeColors_runAll()
    TK.showResult("sfutil.regularizeColors Tests")
end
