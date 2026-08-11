package.path = package.path .. ";C:/Users/scott/Documents/SFAddons/TK/?.lua;C:/Users/scott/Documents/Elder Scrolls Online/live/AddOns/LibSFUtils/?.lua"

require "zos"
require "tk"
local TK = TestKit

require "LibSFUtils_Global"
require "SFUtils_Logger"
require "SFUtils_Color"
require "LibSFUtils"
local SF = LibSFUtils

local TR = test_run


local moduleName = "ColorDelim"
local mn = "ColorDelim"

function testNilEmpty()
    TK.printSuite(mn, "testNilEmpty")

    local t = SF.getAllColorDelim(nil)

    TK.assertEqual(#t, 0, "nil returns empty table")
    
    local t1 = SF.getAllColorDelim("")

    TK.assertEqual(#t1, 0, "empty string returns empty table")

    d("-----------------------")
end

function testNoMarkers()
    TK.printSuite(mn,"testing no marksers")
    TK.assertEqual(#SF.getAllColorDelim("hello"), 0, "no colors returns 0 delims")
    d("-----------------------")
end

function test_colorOnly()
    TK.printSuite(mn,"color only")
    
    local t = SF.getAllColorDelim("|cFF0000red")

    TK.assertEqual(#t, 1, "found color marker")
    TK.assertEqual(t[1].start, 1, "start of delim is correct")
    TK.assertEqual(t[1].estr, 8, "end of delim is correct")
    TK.assertEqual(t[1].code, "c", "delim code is correct")
    d("-----------------------")
end

function test_resetOnly()
    TK.printSuite(mn,"reset only")
    
    local t = SF.getAllColorDelim("hello|r")
    
    TK.assertEqual(#t, 1, "found reset marker")
    TK.assertEqual(t[1].start, 6, "reset start position")
    TK.assertEqual(t[1].estr, 7, "reset end position")
    TK.assertEqual(t[1].code, "r", "reset code is correct")
    d("-----------------------")
end

function testMixedColors()
    TK.printSuite(mn, "testMixedColors")

    local t = SF.getAllColorDelim("|cFF0000Red|r normal |c00FF00Green|r")

    TK.assertEqual(#t, 4, "found all markers")

    TK.assertEqual(t[1].code, "c")
    TK.assertEqual(t[2].code, "r")
    TK.assertEqual(t[3].code, "c")
    TK.assertEqual(t[4].code, "r")
end

function testUppercase()
    TK.printSuite(mn, "testUppercase")

    local t = SF.getAllColorDelim("|CFF0000Hello|R")

    TK.assertEqual(#t, 2, "found uppercase markers")

    TK.assertEqual(t[1].code, "c", "uppercase C normalized")
    TK.assertEqual(t[2].code, "r", "uppercase R normalized")
end

function testMultipleColors()
    TK.printSuite(mn, "testGetAllColorDelimMultipleColors")

    local t = SF.getAllColorDelim("|cFF0000One|r|c00FF00Two|r")

    TK.assertEqual(#t, 4, "got 4 delimiters")

    TK.assertEqual(t[1].start, 1, "start c found")
    TK.assertEqual(t[2].code, "r", "r1 found")
    TK.assertEqual(t[3].code, "c", "c2 found")
    TK.assertEqual(t[4].code, "r", "r2 found")
end

function testMalformedColor()
    TK.printSuite(mn, "testMalformedColor")

    local t = SF.getAllColorDelim("|c")

    -- decide expected behavior:
    -- either 0 (ignore malformed)
    -- or 1 (report marker)
    TK.assertEqual(#t, 1, "report marker")
end

function testMalformedPipe()
    TK.printSuite(mn, "testMalformedPipe")

    local t = SF.getAllColorDelim("hello|xworld")

    TK.assertEqual(#t, 0, "invalid delimiter ignored")
end

local function marker(code, start, estr, action)
    return {
        code = code,
        start = start,
        estr = estr,
        action = action
    }
end


function testRegularizeColorsNil()
    TK.printSuite("regularizeColors", "testRegularizeColorsNil")

    local result = SF.regularizeColors(nil, "hello")

    TK.assertEqual(#result, 0, "nil markers returns empty table")
end


function testRegularizeColorsEmpty()
    TK.printSuite("regularizeColors", "testRegularizeColorsEmpty")

    local markers = {}

    local result = SF.regularizeColors(markers, "hello")

    TK.assertEqual(#result, 0, "empty markers returns empty table")
end


function testRegularizeColorsBalanced()
    TK.printSuite("regularizeColors", "testRegularizeColorsBalanced")

    local str = "|cFF0000Red|r"

    local markers = SF.getAllColorDelim(str)
    local result = SF.regularizeColors(markers, str)

    TK.assertEqual(#result, 2, "balanced colors unchanged")

    TK.assertEqual(result[1].code, "c", "got c")
    TK.assertNil(result[1].action, "nil action")

    TK.assertEqual(result[2].code, "r", "got reset")
    TK.assertNil(result[2].action, "another nil action")
end


function testRegularizeColorsExtraReset()
    TK.printSuite("regularizeColors", "testRegularizeColorsExtraReset")

    local str = "Hello|r"

    local markers = SF.getAllColorDelim(str)
    local result = SF.regularizeColors(markers, str)

    TK.assertEqual(#result, 1, "got 1 result")

    TK.assertEqual(result[1].code, "r", "got reset")
    TK.assertEqual(result[1].action, "-", "got action = -")
end


function testRegularizeColorsMissingReset()
    TK.printSuite("regularizeColors", "testRegularizeColorsMissingReset")

    local str = "|cFF0000Red"

    local markers = SF.getAllColorDelim(str)
    local result = SF.regularizeColors(markers, str)

    TK.assertEqual(#result, 2, "missing reset added")

    TK.assertEqual(result[1].code, "c", "got color marker")
    TK.assertNil(result[1].action, "no action")

    TK.assertEqual(result[2].code, "r", "got reset marker")
    TK.assertEqual(result[2].action, "+", "action = + (ie added)")
end


function testRegularizeColorsColorTransition()
    TK.printSuite("regularizeColors", "testRegularizeColorsColorTransition")

    local str = "|cFF0000Red|c00FF00Green|r"

    local markers = SF.getAllColorDelim(str)
    local result = SF.regularizeColors(markers, str)

    TK.assertEqual(#result, 4, "inserted reset between colors")

    TK.assertEqual(result[1].code, "c", "got color marker")

    TK.assertEqual(result[2].code, "r", "got added reset marker")
    TK.assertEqual(result[2].action, "+", "action = +")

    TK.assertEqual(result[3].code, "c", "got color marker")

    TK.assertEqual(result[4].code, "r", "got reset marker")
end


function testRegularizeColorsEmptyColor()
    TK.printSuite("regularizeColors", "testRegularizeColorsEmptyColor")

    local str = "|cFF0000|r"

    local markers = SF.getAllColorDelim(str)
    local result = SF.regularizeColors(markers, str)

    TK.assertEqual(#result, 2, "got 2 results")

    TK.assertEqual(result[1].action, "-", "remove for action 1")
    TK.assertEqual(result[2].action, "-", "remove for action 2")
end


function testRegularizeColorsTrailingColor()
    TK.printSuite("regularizeColors", "testRegularizeColorsTrailingColor")

    local str = "Normal |cFF0000Red"

    local markers = SF.getAllColorDelim(str)
    local result = SF.regularizeColors(markers, str)

    local last = result[#result]

    TK.assertEqual(last.code, "r", "last code is r")
    TK.assertEqual(last.action, "+", "last action is +")

    TK.assertEqual(last.start, #str + 1, "last start")
    TK.assertEqual(last.estr, #str + 1, "last estr")
end


function test_runAllColorDelim()
    testNilEmpty()
    testNoMarkers()
    test_colorOnly()
    test_resetOnly()
    testMixedColors()
    testUppercase()
    testMultipleColors()
    testMalformedColor()
    testMalformedPipe()
    
    testRegularizeColorsNil()
    testRegularizeColorsEmpty()
    testRegularizeColorsBalanced()
    testRegularizeColorsExtraReset()
    testRegularizeColorsMissingReset()
    testRegularizeColorsColorTransition()
    testRegularizeColorsEmptyColor()
    testRegularizeColorsTrailingColor()

end

if not Suite then
    TK.init()
  
    test_runAllColorDelim()
    
    TK.showResult()
end
