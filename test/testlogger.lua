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


local moduleName = "SF_Logger"
local mn = "SF_Logger"

test_log = {}

-- main
TK.init()

d("testing environment...")
d("-----------------------")
TK.assertTrue(type(SF) == "table","verify SF")
TK.assertTrue(type(SF.SafeLogger) == "function","verify SF.SafeLogger")


d("testing logger creation...")
d("-----------------------")
--_G["test_log"] = {}
test_log.logger = nil
local lg = SF.SafeLogger("test_log","logger")
TK.assertTrue(lg,"create logger object")
TK.assertTrue(lg == test_log.logger, "logger assigned to addon")
_G["test_log"] = nil
d()

d("testing logger function creation...")
d("-----------------------")
_G["test_log1"] = nil
TK.assertTrue(not _G["test_log1"],"_G[test_log1] is nil - clean environment")

local lgfn = SF.SafeLoggerFunction("test_log1","logger1")
TK.assertTrue(type(lgfn)=="function","created logger function lgfn")
TK.assertTrue(_G["test_log1"],"_G[test_log1] is created")
TK.assertTrue(not _G["test_log1"]["logger1"],"_G[test_log1][logger1] is not created")
TK.assertFalse(test_log1.logger1, "did not create logger1 yet")
d()

local lg1 = lgfn()
TK.assertTrue(lg1, "created logger1")
TK.assertTrue(_G["test_log1"],"_G[test_log1] is created")
TK.assertTrue(_G["test_log1"]["logger1"],"_G[test_log1][logger1] is created")
lg1:Info("This is a test")
TK.assertTrue(lg1 == lgfn(),"second call returns first object")
d()

d("testing debug filtering")
lg1:Info("This is a debug test - debug is currently "..tostring(lg1.SFenableDebug))
lg1:SetDebug(lg1.SFenableDebug)
lg1:Debug("This is a debug test - should not see this")
lg1:SetDebug(true)
lg1:Debug("This is a debug test - is currently "..tostring(lg1.SFenableDebug))
lg1:Debug("This is a debug test 2 - set true")
lg1:SetDebug(false)
lg1:Info("This is a debug test - is currently "..tostring(lg1.SFenableDebug))
lg1:Debug("This is a debug test 3 - set false")


d("\n")
TK.showResult()
d()