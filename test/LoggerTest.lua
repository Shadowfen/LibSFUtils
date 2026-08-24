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
local mn = moduleName

test_log = {}


function testLogger_Env()
    local fn = "testing environment..."
    TK.printSuite(mn,fn)
    TK.assertTrue(type(SF) == "table","verify SF")
    TK.assertTrue(type(SF.SafeLogger) == "function","verify SF.SafeLogger")
    d("-----------------------")
end

function testLogger_Creation()
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

function testLogger_LogFunc()
    local fn = "testing logger function creation..."
    TK.printSuite(mn,fn)
    _G["test_log1"] = nil
    TK.assertTrue(not _G["test_log1"],"_G[test_log1] is nil - clean environment")
    d("-----------------------")
end

function testLogger_SafeFunction1()
    local fn = "testing safe logger function creation...1"
    TK.printSuite(mn,fn)
    local lgfn = SF.SafeLoggerFunction("test_log1","logger1")
    TK.assertTrue(type(lgfn)=="function","created logger function lgfn")
    TK.assertTrue(_G["test_log1"],"_G[test_log1] is created")
    TK.assertTrue(not _G["test_log1"]["logger1"],"_G[test_log1][logger1] is not created")
    TK.assertFalse(test_log1.logger1, "did not create logger1 yet")
    d("-----------------------")
end

function testLogger_SafeFunction2()
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

function testLogger_DebugFiltering()
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

function testLogger_InitialState()
    local fn = "testing initial logger state..."
    TK.printSuite(mn, fn)

    local lg = SF.Createlogger("test_initial")

    TK.assertFalse(lg.enabled, "logger initially disabled")
    TK.assertFalse(lg.SFenableDebug, "debug initially disabled")
    TK.assertTrue(type(lg.Debug) == "function", "Debug method exists")

    d("-----------------------")
end

function testLogger_EnabledState()
    local fn = "testing logger enabled state..."
    TK.printSuite(mn, fn)

    local lg = SF.Createlogger("test_enabled")

    TK.assertFalse(lg.enabled, "initially disabled")

    lg:SetEnabled(true)
    TK.assertTrue(lg.enabled, "enabled after SetEnabled(true)")

    lg:SetEnabled(false)
    TK.assertFalse(lg.enabled, "disabled after SetEnabled(false)")

    d("-----------------------")
end

function testLogger_DebugStateMachine()
    local fn = "testing logger debug state machine..."
    TK.printSuite(mn, fn)

    local lg = SF.Createlogger("test_state")

    -- disabled / debug disabled
    TK.assertFalse(lg.enabled, "initially disabled")
    TK.assertFalse(lg.SFenableDebug, "initially debug disabled")

    local initialDebug = lg.Debug

    -- debug enabled, logger disabled
    lg:SetDebug(true)

    TK.assertTrue(lg.SFenableDebug, "debug enabled")
    TK.assertFalse(lg.enabled, "logger still disabled")

    local disabledDebug = lg.Debug

    -- logger enabled, debug enabled
    lg:SetEnabled(true)

    TK.assertTrue(lg.enabled, "logger enabled")
    TK.assertTrue(lg.SFenableDebug, "debug still enabled")

    local activeDebug = lg.Debug

    TK.assertTrue(
        disabledDebug ~= activeDebug,
        "Debug method changes when logger becomes enabled"
    )

    -- debug disabled again
    lg:SetDebug(false)

    TK.assertFalse(lg.SFenableDebug, "debug disabled")

    local debugOff = lg.Debug

    TK.assertTrue(
        debugOff == disabledDebug,
        "Debug method returns to disabled implementation"
    )

    d("-----------------------")
end

function testLogger_EnabledDebugInteraction()
    local fn = "testing enabled/debug interaction..."
    TK.printSuite(mn, fn)

    local lg = SF.Createlogger("test_interaction")

    lg:SetEnabled(true)

    TK.assertTrue(lg.enabled, "enabled")
    TK.assertFalse(lg.SFenableDebug, "debug disabled")

    local noDebug = lg.Debug

    lg:SetDebug(true)

    TK.assertTrue(lg.SFenableDebug, "debug enabled")

    local activeDebug = lg.Debug

    TK.assertTrue(
        activeDebug ~= noDebug,
        "Debug method becomes active"
    )

    lg:SetEnabled(false)

    TK.assertFalse(lg.enabled, "logger disabled")
    TK.assertTrue(
        lg.Debug ~= activeDebug,
        "Debug method disabled with logger"
    )

    lg:SetEnabled(true)

    TK.assertTrue(lg.enabled, "logger re-enabled")
    TK.assertTrue(
        lg.Debug == activeDebug,
        "Debug method restored"
    )

    d("-----------------------")
end

function testLogger_SetEnabledIdempotent()
    local fn = "testing SetEnabled idempotence..."
    TK.printSuite(mn, fn)

    local lg = SF.Createlogger("test_idempotent")

    lg:SetEnabled(true)
    local err = lg.Error
    local warn = lg.Warn
    local info = lg.Info
    local debug = lg.Debug

    lg:SetEnabled(true)

    TK.assertTrue(lg.Error == err, "Error unchanged")
    TK.assertTrue(lg.Warn == warn, "Warn unchanged")
    TK.assertTrue(lg.Info == info, "Info unchanged")
    TK.assertTrue(lg.Debug == debug, "Debug unchanged")

    d("-----------------------")
end

function testLogger_NilLogger()
    local fn = "testing nil logger..."
    TK.printSuite(mn, fn)

    -- This doesn't prove the methods don't print unless you capture 
    -- print, but it at least exercises the API.
    local lg = SF.CreateNilLogger("test_nil")

    TK.assertTrue(lg ~= nil, "nil logger created")
    TK.assertTrue(type(lg.Info) == "function", "Info exists")
    TK.assertTrue(type(lg.Warn) == "function", "Warn exists")
    TK.assertTrue(type(lg.Error) == "function", "Error exists")
    TK.assertTrue(type(lg.Debug) == "function", "Debug exists")

    lg:SetEnabled(true)
    lg:SetDebug(true)

    -- These should produce no output.
    lg:Error("nil logger error")
    lg:Warn("nil logger warning")
    lg:Info("nil logger info")
    lg:Debug("nil logger debug")

    TK.assertTrue(lg.SFenableDebug, "SetDebug state retained")

    d("-----------------------")
end

function testLogger_SafeLoggerExisting()
    local fn = "testing SafeLogger existing instance..."
    TK.printSuite(mn, fn)

    _G.test_log2 = {}

    local lg1 = SF.SafeLogger("test_log2", "logger")
    local lg2 = SF.SafeLogger("test_log2", "logger")

    TK.assertTrue(lg1 == lg2, "existing logger is returned")

    _G.test_log2 = nil

    d("-----------------------")
end

function Logger_runTests()
    testLogger_Env()
    testLogger_Creation()
    testLogger_InitialState()
    testLogger_LogFunc()
    testLogger_SafeFunction1()
    testLogger_SafeFunction2()
    testLogger_DebugFiltering()
    testLogger_EnabledState()
    testLogger_DebugStateMachine()
    testLogger_EnabledDebugInteraction()
    testLogger_SetEnabledIdempotent()
    testLogger_NilLogger()
    testLogger_SafeLoggerExisting()
end

if not Suite then
    TK.init()
    
    Logger_runTests()
    
    TK.showResult()
end