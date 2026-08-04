package.path = package.path .. ";C:/Users/scott/Documents/SFAddons/TK/?.lua;C:/Users/scott/Documents/Elder Scrolls Online/live/AddOns/LibSFUtils/?.lua"

require "zos"
require "tk"
local TK = TestKit

require "LibSFUtils_Global"
require "SFUtils_Logger"
require "SFUtils_Tables"
require "SFUtils_Strings"
require "SFUtils_Color"
require "LibSFUtils"
local SF = LibSFUtils

local TR = test_log
local d = print


local moduleName = "SFUtils_Strings"
local mn = "SFUtils_Strings"

test_log = {}

local function Strings_testNilPack()
    local fn = "NilPack"
    TK.printSuite(mn,fn)
    
    local tbl1 = SF.NilPack(1,nil,"3",nil)
    TK.assertEquals(tbl1.n, 4, "counted trailing nil")
    TK.assertNil(tbl1[2], "first nil is saved")
    TK.assertNil(tbl1[4], "second nil is saved")
    TK.assertEquals(tbl1[1], 1, "first param was 1")
    TK.assertEquals(tbl1[3], "3", "third param was '3'")
end

local function Strings_testNilUnpack()
    local fn = "NilUnpack"
    TK.printSuite(mn,fn)
    
    local tbl1 = SF.NilPack(1,nil,"3",nil)
    local a1, a2, a3, a4 = SF.NilUnpack(tbl1)
    TK.assertTrue(a1 == 1, "got first arg")
    TK.assertNil(a2, "got nil second arg")
    TK.assertTrue(a3, "got third arg")
    TK.assertNil(a4, "got nil fourth arg")
end

local function Strings_testStr()
    local fn = "testStr"
    TK.printSuite(mn,fn)
    
    TK.assertTrue(SF.str("test", "1") == "test1", "str - str - "..SF.str("test", "1"))
    d("simple table  "..SF.str({ "A", "B", "C"} ))
    TK.assertTrue(SF.str({ "A", "B", "C"}) == "1A2B3C", "str - tbl")
    d( SF.str("AA", 22, "CA", {"Z", "Y", "X", "W"} ))
    TK.assertTrue(SF.str( "AA", 22, "CA", {"Z", "Y", "X", "W"} ) == "AA22CA1Z2Y3X4W", "str - single, tbl2")
    d( SF.str({"Z", "Y", "X", "W"} ))
    TK.assertTrue(SF.str( {"Z", "Y", "X", "W"} ) == "1Z2Y3X4W", "str - tbl2")
    d("nil="..SF.str(nil).."=")
    TK.assertTrue(SF.str(nil) == "(nil)", "str - nil")
    d("func="..SF.str(function() return "ha" end).."=")
    TK.assertTrue(SF.str(function() return "ha" end) == "", "str - function ignored")
end

local function Strings_testLStr()
    local fn = "testLStr"
    TK.printSuite(mn,fn)
    TK.assertTrue(SF.lstr("test", "1") == "test1", "str - str - "..SF.str("test", "1"))
    --d(SF.str({ "A", "B", "C"} ))
    TK.assertTrue(SF.lstr({ "A", "B", "C"}) == "1A2B3C", "str - tbl")
    --d( SF.str({ "AA", 22, "CA", {"Z", "Y", "X", "W"} } ))
    TK.assertTrue(SF.lstr({ "AA", 22, "CA", {"Z", "Y", "X", "W"} }) == "1AA2223CA41Z2Y3X4W", "str - tbl2")
    TK.assertTrue(SF.lstr(nil) == "(nil)", "str - nil")
    TK.assertTrue(SF.lstr(function() return "ha" end) == "", "str - function ignored")
end

local function Strings_testDstr()
    local fn = "testDstr"
    TK.printSuite(mn,fn)
    TK.assertTrue(SF.dstr(" ","test", "1") == "test 1", "dstr - str - "..SF.dstr(" ","test", "1"))
    --d(SF.dstr(" ", { "A", "B", "C"} ))
    TK.assertTrue(SF.dstr(" ",{ "A", "B", "C"}) == "3 C 2 B 1 A", "dstr - tbl")
    --d( SF.dstr( " ", { "AA", 22, "CA", {"Z", "Y", "X", "W"} } ))
    TK.assertTrue(SF.dstr(" ",{ "AA", 22, "CA", {"Z", "Y", "X", "W"} }) == "4 4 W 3 X 2 Y 1 Z 3 CA 2 22 1 AA", "dstr - tbl2")
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
    for _, v in pairs(rslt) do
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
    for _, v in pairs(rslt) do
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
    for _, v in pairs(rslt) do
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
    TK.assertTrue(rslt1 == "|cFF0000 red|r", "red - "..rslt1)
end

local function Strings_testBool2Str()
    local fn = "testBool2Str"
    TK.printSuite(mn,fn)
    TK.assertTrue("true" == SF.bool2str(true), "returns true")
    TK.assertTrue("false" == SF.bool2str(nil), "returns false")
    TK.assertTrue("false" == SF.bool2str(false), "returns false")
end

function Strings_runTests()
    TK.init()
    
    Strings_testNilPack()
    Strings_testNilUnpack()
    Strings_testStr()
    Strings_testLStr()
    Strings_testDstr()
    Strings_testGetText()
    Strings_testStrSplitLen()
    Strings_testTblJoinLen_tbl()
    Strings_testTblJoinLen_str()
    Strings_testColorText()
    Strings_testBool2Str()

    TK.showResult("Strings_Test")
end

-- main
if not Suite then
    Strings_runTests()
end
