package.path = package.path .. ";C:/Users/scott/Documents/SFAddons/TK/?.lua;C:/Users/scott/Documents/Elder Scrolls Online/live/AddOns/LibSFUtils/?.lua"

require "zos"
require "tk"
local TK = TestKit

require "LibSFUtils_Global"
require "SFUtils_Logger"
require "SFUtils_Color"
require "LibSFUtils"
local SF = LibSFUtils

local TR = test_log

local moduleName = "SF_Logger"
local mn = "SF_Logger"

test_log = {}

-- main
TK.init()

do
    local fn = "testing environment..."
    TK.printSuite(mn,fn)
    TK.assertTrue(type(SF) == "table","verify SF")
    TK.assertTrue(type(SF.SafeLogger) == "function","verify SF.SafeLogger")
    d("-----------------------")
end

do
    local fn = "testing logger creation..."
    TK.printSuite(mn,fn)
    --_G["test_log"] = {}
    test_log.logger = nil
    local lg = SF.SafeLogger("test_log","logger")
    TK.assertTrue(lg,"create logger object")
    TK.assertTrue(lg == test_log.logger, "logger assigned to addon")
    _G["test_log"] = nil
    d("-----------------------")
end

do
    local fn = "testing logger function creation..."
    TK.printSuite(mn,fn)
    _G["test_log1"] = nil
    TK.assertTrue(not _G["test_log1"],"_G[test_log1] is nil - clean environment")
    d("-----------------------")
end

do
    local fn = "testing safe logger function creation...1"
    TK.printSuite(mn,fn)
    local lgfn = SF.SafeLoggerFunction("test_log1","logger1")
    TK.assertTrue(type(lgfn)=="function","created logger function lgfn")
    TK.assertTrue(_G["test_log1"],"_G[test_log1] is created")
    TK.assertTrue(not _G["test_log1"]["logger1"],"_G[test_log1][logger1] is not created")
    TK.assertFalse(test_log1.logger1, "did not create logger1 yet")
    d("-----------------------")
end

do
    local fn = "testing safe logger function creation...2"
    TK.printSuite(mn,fn)
    local lgfn = SF.SafeLoggerFunction("test_log1","logger1")
    local lg1 = lgfn()
    TK.assertTrue(lg1, "created logger1")
    TK.assertTrue(_G["test_log1"],"_G[test_log1] is created")
    TK.assertTrue(_G["test_log1"]["logger1"],"_G[test_log1][logger1] is created")
    lg1:Info("This is a test")
    TK.assertTrue(lg1 == lgfn(),"second call returns first object")
    d("-----------------------")
end

do
    local fn = "testing debug filtering"
    TK.printSuite(mn,fn)
    local lgfn = SF.SafeLoggerFunction("test_log1","logger1")
    local lg1 = lgfn()
    lg1:Info("\tThis is a debug test - debug is currently "..tostring(lg1.SFenableDebug))
    lg1:SetDebug(lg1.SFenableDebug)
    lg1:Debug("\tThis is a debug test - should not see this")
    lg1:SetDebug(true)
    lg1:Debug("\tThis is a debug test - is currently "..tostring(lg1.SFenableDebug))
    lg1:Debug("\tThis is a debug test 2 - set true")
    lg1:SetDebug(false)
    lg1:Info("\tThis is a debug test - is currently "..tostring(lg1.SFenableDebug))
    lg1:Debug("\tThis is a debug test 3 - set false")
    d("-----------------------")
end

d("\n")
TK.showResult()
d()