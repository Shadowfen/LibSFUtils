require "LibSFUtils.test.tk"
require "LibSFUtils.test.zos"

require "LibSFUtils.LibSFUtils_Global"
require "LibSFUtils.SFUtils_Logger"
require "LibSFUtils.SFUtils_Tables"
require "LibSFUtils.SFUtils_Color"
require "LibSFUtils.LibSFUtils"
local TK = TestKit
local SF = LibSFUtils

local TR = test_log
local d = print


local moduleName = "SFUtils_Tables"
local mn = "SFUtils_Tables"

test_log = {}

-- main
TK.init()

local function Tables_testdTable()
    local fn = "testdTable"
    TK.printSuite(mn,fn)
    local tbl = { "a", "b", "c" }
    local str = SF.dTable(tbl,5,"tbl")
    TK.assertTrue( str == "tbl : 1 -> a,  \ntbl : 2 -> b,  \ntbl : 3 -> c,  \n", "have tbl string")
    
    tbl = { {1,2,3}, { "a", "b", "c" } }
    str = SF.dTable(tbl,5,"tbl")
    TK.assertTrue( str == "tbl - [1] : 1 -> 1,  \ntbl - [1] : 2 -> 2,  \ntbl - [1] : 3 -> 3,  \ntbl - [2] : 1 -> a,  \ntbl - [2] : 2 -> b,  \ntbl - [2] : 3 -> c,  \n", "have recursive tbl string")
end

local function Tables_testDefaultMissing()
    local fn = "testDefaultMissing"
    TK.printSuite(mn,fn)
    local base = {
      aa = 41,
      bb = "trust",
      dd = "blah",
    }
    local def = {
        aa = 1,
        bb = "hope",
        cc = "luck",
        dd = "oops",
    }
    
    SF.defaultMissing(base, def)
    TK.assertFalse(base == def, "still have separate tables")
    TK.assertTrue(base.aa == 41, "base aa has not changed - 41")
    TK.assertTrue(base.bb == "trust", "base bb has not changed - trust")
    TK.assertTrue(base.cc == "luck", "base cc has been added - luck")
    TK.assertTrue(base.dd == "blah", "base dd has not changed blah")
    d()
    local tbl = {}
    local rslt1 = SF.defaultMissing(tbl, def)
    TK.assertFalse(rslt1 == def, "still have separate tables")
    TK.assertTrue(tbl.aa == 1, "tbl aa has been added - 1")
    TK.assertTrue(tbl.bb == "hope", "tbl bb has been added - hope")
    TK.assertTrue(tbl.cc == "luck", "tbl cc has been added - luck")
    TK.assertTrue(tbl.dd == "oops", "tbl dd has been added - oops")
end

local function Tables_testDeepCopy()
    local fn = "testDeepCopy"
    TK.printSuite(mn,fn)
    --TK.assertTrue(true == SF.str2bool("true"), "returns true")
end

local function Tables_testSafeTable()
    local fn = "testSafeTable"
    TK.printSuite(mn,fn)
    local tbl
    local atbl = SF.safeTable(tbl)
    TK.assertNil(tbl, "tbl is nil")
    TK.assertNotNil(atbl, "atbl is not nil")
    TK.assertTrue(type(atbl) == "table", "atbl is a table")
end

local function Tables_testSafeClearTable()
    local fn = "testSafeClearTable"
    TK.printSuite(mn,fn)
    local tbl
    TK.assertNotNil(SF.safeClearTable(tbl), "non-table gets created")
    TK.assertNil(next(SF.safeClearTable(tbl)), "created table is empty")
    tbl = {}
    local atbl = SF.safeClearTable(tbl)
    TK.assertTrue(tbl == atbl, "tbl ref remains the same")
    TK.assertTrue(SF.isEmpty(atbl), "atbl table is empty")
    tbl = { "monday" }
    atbl = SF.safeClearTable(tbl)
    TK.assertTrue(tbl == atbl, "tbl == atbl")
    TK.assertTrue(SF.isEmpty(atbl), "atbl table is empty again")
end

local function Tables_testRemainsInList()
    local fn = "testRemainsInList"
    TK.printSuite(mn,fn)
    local listA = {[1]=1,[2]=2,[3]=4,[4]=5,[5]=3}
    local listB = {[2]=1, [4]=1, [5] = 1}
    local remains = SF.RemainsInList(listA, listB)
    TK.assertTrue(type(remains) == "table", "remains is a table")
    TK.assertTrue(SF.GetSize(remains) == 2, "remains has 2 elements")
    d(SF.dTable(remains,5,"remains"))
    TK.assertTrue(remains[1] == 1, "first element is 1")
    TK.assertNil(remains[2], "second element is nil")
    TK.assertTrue(remains[3] == 1, "third element is 1")
end

local function Tables_testGetSize()
    local fn = "testGetSize"
    TK.printSuite(mn,fn)
    local tbl
    TK.assertTrue(SF.GetSize(tbl) == 0, "non-table has 0 size")
    tbl = {}
    TK.assertTrue(SF.isEmpty(tbl), "tbl is empty")
    TK.assertTrue(SF.GetSize(tbl) == 0, "tbl has 0 size")
    tbl = { 1,2,3,4,5}
    TK.assertTrue(SF.GetSize(tbl) == 5, "tbl has 5 size")
end

local function Tables_testIsEmpty()
    local fn = "testIsEmpty"
    TK.printSuite(mn,fn)
    local tbl
    TK.assertNil(SF.isEmpty(tbl), "non-table isEmpty returns nil")
    tbl = {}
    TK.assertTrue(SF.isEmpty(tbl), "empty table isEmpty returns true")
    tbl = { "monday" }
    TK.assertFalse(SF.isEmpty(tbl), "non-empty table isEmpty returns false")
end

function Tables_runTests()
    Tables_testdTable()
    Tables_testDefaultMissing()
    --Tables_testDeepCopy()
    Tables_testSafeTable()
    Tables_testSafeClearTable()
    Tables_testRemainsInList()
    Tables_testGetSize()
    Tables_testIsEmpty()
end

-- main
if not Suite then
    Tables_runTests()
    d("\n")
    TK.showResult("Tables_Test")
end
