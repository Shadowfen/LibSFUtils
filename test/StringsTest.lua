require "LibSFUtils.test.tk"
require "LibSFUtils.test.zos"

require "LibSFUtils.LibSFUtils_Global"
require "LibSFUtils.SFUtils_Logger"
require "LibSFUtils.SFUtils_Color"
require "LibSFUtils.LibSFUtils"
local TK = TestKit
local SF = LibSFUtils

local TR = test_log
local d = print


local moduleName = "SFUtils_Strings"
local mn = "SFUtils_Strings"

test_log = {}

-- main
TK.init()

local function Strings_testStr()
    local fn = "testStr"
    TK.printSuite(mn,fn)
    TK.assertTrue(SF.str("test", "1") == "test1", "str - str - "..SF.str("test", "1"))
    --d(SF.str({ "A", "B", "C"} ))
    TK.assertTrue(SF.str({ "A", "B", "C"}) == "1A2B3C", "str - tbl")
    --d( SF.str({ "AA", 22, "CA", {"Z", "Y", "X", "W"} } ))
    TK.assertTrue(SF.str({ "AA", 22, "CA", {"Z", "Y", "X", "W"} }) == "1AA2223CA41Z2Y3X4W", "str - tbl2")
    TK.assertTrue(SF.str(nil) == "(nil)", "str - nil")
    TK.assertTrue(SF.str(function() return "ha" end) == "", "str - function ignored")
end


local function Strings_testDstr()
    local fn = "testDstr"
    TK.printSuite(mn,fn)
    TK.assertTrue(SF.dstr(" ","test", "1") == "test 1", "dstr - str - "..SF.dstr(" ","test", "1"))
    --d(SF.dstr(" ", { "A", "B", "C"} ))
    TK.assertTrue(SF.dstr(" ",{ "A", "B", "C"}) == "1 A 2 B 3 C", "dstr - tbl")
    --d( SF.dstr( " ", { "AA", 22, "CA", {"Z", "Y", "X", "W"} } ))
    TK.assertTrue(SF.dstr(" ",{ "AA", 22, "CA", {"Z", "Y", "X", "W"} }) == "1 AA 2 22 3 CA 4 1 Z 2 Y 3 X 4 W", "dstr - tbl2")
    TK.assertTrue(SF.dstr(nil) == "", "dstr - nil")
end

local function Strings_testGetText()
    local fn = "testGetText"
    TK.printSuite(mn,fn)
    TK.assertTrue(SF.GetText("test 1") == "test 1", "GetText - str")
    TK.assertTrue(SF.GetText(nil) == "", "GetText - nil")
    local function rtntxt(t)
        return t
    end
    TK.assertTrue(SF.GetText(rtntxt,"woohoo") == "woohoo", "GetText - function")
    SafeAddString(50,"This is a test", 1)
    TK.assertTrue(GetString(50) == "This is a test", "GetText - number")
end

local function Strings_testStrSplitLen()
    local fn = "testStrSplitLen"
    TK.printSuite(mn,fn)
    local origtbl = "This is a test of the Emergency Broadcast System."
    local rslt = SF.tblJoinLen(origtbl, 10)
    TK.assertTrue(type(rslt) == "table", "rslt is table")
    TK.assertTrue(#rslt == 5, "rslt has entries "..#rslt)
    local lenok = true
    for k, v in pairs(rslt) do
        if #v > 10 then lenok = false end
        --d(v)
    end
    TK.assertTrue(lenok == true, "all entries lengths <= 10")
    TK.assertTrue(table.concat(rslt) == origtbl, "concat returns the original")
    
end


local function Strings_testTblJoinLen_tbl()
    local fn = "testTblJoinLen_tbl"
    TK.printSuite(mn,fn)
    local origtbl = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }
    local rslt = SF.tblJoinLen(origtbl, 3)
    TK.assertTrue(type(rslt) == "table", "rslt is table")
    TK.assertTrue(#rslt == 4, "rslt has entries "..#rslt)
    local lenok = true
    for k, v in pairs(rslt) do
        if #v > 3 then lenok = false end
    end
    TK.assertTrue(lenok == true, "all entries lengths <= 3")
    
end

local function Strings_testTblJoinLen_str()
    local fn = "testTblJoinLen_tbl"
    TK.printSuite(mn,fn)
    local origtbl = "This is a test of the Emergency Broadcast System."
    local rslt = SF.tblJoinLen(origtbl, 5)
    TK.assertTrue(type(rslt) == "table", "rslt is table")
    TK.assertTrue(#rslt == 10, "rslt has entries "..#rslt)
    local lenok = true
    for k, v in pairs(rslt) do
        if #v > 5 then lenok = false end
        --d(v)
    end
    TK.assertTrue(lenok == true, "all entries lengths <= 5")
    
end

local function Strings_testColorText()
    local fn = "testColorText"
    TK.printSuite(mn,fn)
    local rslt = SF.ColorText("no colors")
    TK.assertTrue(rslt == "no colors", "no color")
    
    local rslt1 = SF.ColorText("red",SF.hex.red)
    TK.assertNotNil(rslt1,"got good rslt1")
    TK.assertTrue(rslt1 == "|c<<1>> <<2>>|r FF0000 red", "red - "..rslt1)
end

local function Strings_testBool2Str()
    local fn = "testBool2Str"
    TK.printSuite(mn,fn)
    TK.assertTrue("true" == SF.bool2str(true), "returns true")
    TK.assertTrue("false" == SF.bool2str(nil), "returns false")
    TK.assertTrue("false" == SF.bool2str(false), "returns false")
end

local function Strings_testStr2Bool()
    local fn = "testStr2Bool"
    TK.printSuite(mn,fn)
    TK.assertTrue(true == SF.str2bool("true"), "returns true")
    --TK.assertTrue(false == SF.str2bool(nil), "returns false")
    TK.assertTrue(false == SF.str2bool("False"), "returns false")
end


function Strings_runTests()
    Strings_testStr()
    --Strings_testLstr()
    Strings_testDstr()
    --Strings_testDstr1()
    Strings_testGetText()
    Strings_testStrSplitLen()
    Strings_testTblJoinLen_tbl()
    Strings_testTblJoinLen_str()
    --Strings_testGetIconized()
    Strings_testColorText()
    Strings_testBool2Str()
    Strings_testStr2Bool()
end

-- main
if not Suite then
    Strings_runTests()
    d("\n")
    TK.showResult("Strings_Test")
end
