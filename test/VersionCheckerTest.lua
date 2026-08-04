package.path = package.path .. ";C:/Users/scott/Documents/SFAddons/TK/?.lua;C:/Users/scott/Documents/Elder Scrolls Online/live/AddOns/LibSFUtils/?.lua"

require "zos"
require "tk"
local TK = TestKit

require "LibSFUtils_Global"
require "SFUtils_Color"
require "SFUtils_VersionChecker"
require "LibSFUtils"
local SF = LibSFUtils

local TR = test_run

local moduleName = "VersionChecker"
local mn = moduleName

function VCTest_notNil()
  local vc = SF.VersionChecker("testVC")
  TK.assertNotNil(vc,"VC call create 1")
  TK.assertTrue(vc.addonName == "testVC","Addon name set 1")
  TK.assertTrue(vc.enabled,"Created, so enabled 1")
  vc = nil        
end

function VCTest_CreateEnabled()
    local vc = SF.VersionChecker("testVC")
    TK.assertNotNil(vc,"VC call create 2")
    TK.assertTrue(vc.addonName == "testVC","Addon name set 2")
    TK.assertTrue(vc.enabled,"created, so enabled 2")
end

function VCTest_EnableDisable()
    local vc = SF.VersionChecker("testVC")
    vc:Enable()
    TK.assertTrue(vc.enabled,"testVC enabled")

    vc:Disable()
    TK.assertFalse(vc.enabled,"disabled testVC, so not enabled 3")
end

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
  

function VCTest_NoVersion()
    local vc = SF.VersionChecker("testVC", testlogger)
    vc:NoVersion("blah")
    TK.assertTrue(testlogger.msg.info == "Library \"blah\" does not provide version information", testlogger.msg.info or "test No Version failed")
end

function VCTest_CheckVer()
    local vc = SF.VersionChecker("testVC", testlogger)
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
end

function VCTest_runAll()
    TK.init()

    VCTest_notNil()
    VCTest_CreateEnabled()
    VCTest_EnableDisable()
    --VCTest_NoVersion()
    --VCTest_CheckVer()
    
    TK.showResult()
end

if not Suite then
    VCTest_runAll()
end