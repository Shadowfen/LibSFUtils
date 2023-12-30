require "test.tk"
require "test.zos"
require "LibSFUtils_Global"
require "SFUtils_Color"
require "LibSFUtils"
require "SFUtils_VersionChecker"
local TK = TestKit
local SF = LibSFUtils

local TR = test_run
local d = print

local moduleName = "VersionChecker"
local mn = "VersionChecker"

-- main
TK.init()


local vc = SF.VersionChecker("testVC")
TK.assertNotNil(vc,"VC call create 1")
--d(vc.addonName or "nil")
TK.assertTrue(vc.addonName == "testVC","Addon name set 1")
TK.assertFalse(vc.enabled,"No LibDebugLogger, so not enabled 1")
vc = nil

vc = SF.VersionChecker("testVC")
TK.assertNotNil(vc,"VC call create 2")
--d(vc.addonName or "nil")
TK.assertTrue(vc.addonName == "testVC","Addon name set 2")
TK.assertFalse(vc.enabled,"No LibDebugLogger, so not enabled 2")

vc:Enable()
TK.assertTrue(vc.enabled,"LibDebugLogger enabled")

vc:Disable()
TK.assertFalse(vc.enabled,"No LibDebugLogger, so not enabled 3")

local testlogger = {
    msg = {},
    Error = function(self,...)  self.msg.error = string.format(...) end,
    Warn = function(self,...)  self.msg.warn = string.format(...) end,
    Info = function(self,...)  self.msg.info = string.format(...) end,
    Debug = function(self,...)  self.msg.debug = string.format(...) end,
}
setmetatable(testlogger, { __call = function(self,name,logger) 
            self.addonName = name 
            self.logger = logger
            return self
        end
    })
vc = SF.VersionChecker("testVC", testlogger)
vc:NoVersion("blah")
TK.assertTrue(testlogger.msg.info == "Library \"blah\" does not provide version information", testlogger.msg.info or "test No Version failed")

local function checkVer(libname)
    local libtab = {
        LibSFUtils = 23,
        ["LibAddonMenu-2.0"] = 30,
    }
    return libtab[libname] or -1
end
testlogger.msg.error = nil
vc:CheckVersion("LibSFUtils",checkVer, 24)
TK.assertNotNil(testlogger.msg.error, testlogger.msg.error or "LibSFUtils version is not correct")

testlogger.msg.error = nil
vc:CheckVersion("LibSF",checkVer, 24)
TK.assertNotNil(testlogger.msg.error, testlogger.msg.error or "LibSF was found")

testlogger.msg.error = nil
vc:CheckVersion("LibSFUtils",checkVer, 22)
TK.assertNil(testlogger.msg.error, testlogger.msg.error or "LibSFUtils version is correct")



d("\n")
TK.showResult()
d()