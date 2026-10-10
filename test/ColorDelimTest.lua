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

-- -------------------------------------------------------
-- Empty / no-marker input
-- -------------------------------------------------------

function testNilEmpty()
    TK.printSuite(mn, "NilEmpty")

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

-- -------------------------------------------------------
-- Individual markers
-- -------------------------------------------------------

function testColorOnly()
    TK.printSuite(mn,"color only")
    
    local t = SF.getAllColorDelim("|cFF0000red")

    TK.assertEqual(#t, 1, "found color marker")
    TK.assertEqual(t[1].start, 1, "start of delim is correct")
    TK.assertEqual(t[1].estr, 8, "end of delim is correct")
    TK.assertEqual(t[1].code, "c", "delim code is correct")
    d("-----------------------")
end

function testResetOnly()
    TK.printSuite(mn,"reset only")
    
    local t = SF.getAllColorDelim("hello|r")
    
    TK.assertEqual(#t, 1, "found reset marker")
    TK.assertEqual(t[1].start, 6, "reset start position")
    TK.assertEqual(t[1].estr, 7, "reset end position")
    TK.assertEqual(t[1].code, "r", "reset code is correct")
    d("-----------------------")
end

-- -------------------------------------------------------
-- Mixed markers
-- -------------------------------------------------------

local function testMixedColors()
    TK.printSuite(mn, "mixedColors")

    local str = "|cFF0000Red|r normal |c00FF00Green|r"
    local t = SF.getAllColorDelim(str)

    TK.assertEqual(#t, 4, "found all markers")

    TK.assertEqual(t[1].start, 1, "color 1 start")
    TK.assertEqual(t[1].estr, 8, "color 1 end")
    TK.assertEqual(t[1].code, "c", "color 1 code")

    TK.assertEqual(t[2].start, 12, "reset 1 start")
    TK.assertEqual(t[2].estr, 13, "reset 1 end")
    TK.assertEqual(t[2].code, "r", "reset 1 code")

    TK.assertEqual(t[3].start, 22, "color 2 start")
    TK.assertEqual(t[3].estr, 29, "color 2 end")
    TK.assertEqual(t[3].code, "c", "color 2 code")

    TK.assertEqual(t[4].start, 35, "reset 2 start")
    TK.assertEqual(t[4].estr, 36, "reset 2 end")
    TK.assertEqual(t[4].code, "r", "reset 2 code")
end

--[[
function testUppercase()
    TK.printSuite(mn, "testUppercase")

    local t = SF.getAllColorDelim("|CFF0000Hello|R")

    TK.assertEqual(#t, 2, "found uppercase markers")

    TK.assertEqual(t[1].code, "c", "uppercase C normalized")
    TK.assertEqual(t[2].code, "r", "uppercase R normalized")
end
--]]
local function testUppercase()
    TK.printSuite(mn, "uppercase")

    local t = SF.getAllColorDelim("|CFF0000Hello|R")

    TK.assertEqual(#t, 2, "found uppercase markers")

    TK.assertEqual(t[1].start, 1, "uppercase color start")
    TK.assertEqual(t[1].estr, 8, "uppercase color end")
    TK.assertEqual(t[1].code, "c", "uppercase C normalized")

    TK.assertEqual(t[2].start, 14, "uppercase reset start")
    TK.assertEqual(t[2].estr, 15, "uppercase reset end")
    TK.assertEqual(t[2].code, "r", "uppercase R normalized")
end


--[[
function testMultipleColors()
    TK.printSuite(mn, "testGetAllColorDelimMultipleColors")

    local t = SF.getAllColorDelim("|cFF0000One|r|c00FF00Two|r")

    TK.assertEqual(#t, 4, "got 4 delimiters")

    TK.assertEqual(t[1].start, 1, "start c found")
    TK.assertEqual(t[2].code, "r", "r1 found")
    TK.assertEqual(t[3].code, "c", "c2 found")
    TK.assertEqual(t[4].code, "r", "r2 found")
end
--]]
local function testMultipleColors()
    TK.printSuite(mn, "multipleColors")

    local str = "|cFF0000One|r|c00FF00Two|r"
    local t = SF.getAllColorDelim(str)

    TK.assertEqual(#t, 4, "found all delimiters")

    TK.assertEqual(t[1].start, 1, "c1 start")
    TK.assertEqual(t[1].estr, 8, "c1 end")
    TK.assertEqual(t[1].code, "c", "c1 code")

    TK.assertEqual(t[2].start, 12, "r1 start")
    TK.assertEqual(t[2].estr, 13, "r1 end")
    TK.assertEqual(t[2].code, "r", "r1 code")

    TK.assertEqual(t[3].start, 14, "c2 start")
    TK.assertEqual(t[3].estr, 21, "c2 end")
    TK.assertEqual(t[3].code, "c", "c2 code")

    TK.assertEqual(t[4].start, 25, "r2 start")
    TK.assertEqual(t[4].estr, 26, "r2 end")
    TK.assertEqual(t[4].code, "r", "r2 code")
end

-- -------------------------------------------------------
-- Malformed / incomplete markers
-- -------------------------------------------------------

local function testMalformedColor()
    TK.printSuite(mn, "malformedColor")

    local t = SF.getAllColorDelim("|c")

    -- The parser recognizes |c as a color delimiter and reserves
    -- six characters for the color payload without validating them.
    TK.assertEqual(#t, 1, "incomplete color delimiter is reported")

    TK.assertEqual(t[1].start, 1, "incomplete color start")
    TK.assertEqual(t[1].estr, 8, "incomplete color end")
    TK.assertEqual(t[1].code, "c", "incomplete color code")
end

function testMalformedPipe()
    TK.printSuite(mn, "testMalformedPipe")

    local t = SF.getAllColorDelim("hello|xworld")

    TK.assertEqual(#t, 0, "invalid delimiter ignored")
end

-- -------------------------------------------------------
-- Multiple pipes
-- -------------------------------------------------------

local function testMultiplePipes()
    TK.printSuite(mn, "multiplePipes")

    local t = SF.getAllColorDelim("||cFF0000red||r")

    TK.assertEqual(#t, 2, "multiple-pipe delimiters are recognized")

    TK.assertEqual(t[1].start, 1, "color starts at first pipe")
    TK.assertEqual(t[1].estr, 9, "color ends after six color characters")
    TK.assertEqual(t[1].code, "c", "color code normalized")

    TK.assertEqual(t[2].start, 13, "reset starts at first pipe")
    TK.assertEqual(t[2].estr, 15, "reset ends after both pipes and r")
    TK.assertEqual(t[2].code, "r", "reset code normalized")
end

function test_runAllColorDelim()
    testNilEmpty()
    testNoMarkers()

    testColorOnly()
    testResetOnly()

    testMixedColors()
    testUppercase()
    testMultipleColors()

    testMalformedColor()
    testMalformedPipe()
    testMultiplePipes()
end


if not Suite then
    TK.init()

    test_runAllColorDelim()

    TK.showResult()
end