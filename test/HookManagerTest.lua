package.path = package.path .. ";C:/Users/scott/Documents/SFAddons/TK/?.lua;C:/Users/scott/Documents/Elder Scrolls Online/live/AddOns/LibSFUtils/?.lua"

require "zos"
require "tk"
local TK = TestKit

require "LibSFUtils_Global"
require "SFUtils_Strings"
require "SFUtils_Color"
require "LibSFUtils"
require "SFUtils_Logger"
require "SFUtils_HookManager"
local SF = LibSFUtils

local TR = test_log

local moduleName = "SFUtils_HookManager"
local mn = moduleName


--[[
    HookManager Unit Test Suite
    ==========================
    Tests for LibSFUtils HookManager using TestKit framework.
    
    Note: Many tests below check object structure and method existence.
    Full functional testing requires an ESO game environment with ZO_SavedVars.
]]

local function HookManager_testInstanceCreation()
    local fn = "testInstanceCreation"
    TK.printSuite(mn,fn)
    
    -- Test basic creation
    local hm = SF.HookManager:New()
    TK.assertNotNil(hm, "HookManager created")
    TK.assertTrue(type(hm) == "table", "HookManager is table")
    
    -- Test with custom base name
    local hm2 = SF.HookManager:New("CustomHook")
    TK.assertEqual(hm2.base, "CustomHook", "custom base name")
    
    -- Test default base name
    TK.assertEqual(hm.base, "HookManager", "default base name")
end

local function HookManager_testPreHookCreation()
    local fn = "testPreHookCreation"
    TK.printSuite(mn,fn)
    
    -- Create test target object
    _G["HM_TestTarget"] = {
        value = 0,
        testMethod = function(self, val) 
            self.value = val 
            return "original:" .. val
        end
    }
    
    local hm = SF.HookManager:New("TestHM")
    
    -- Track hook results
    local hookCalled = false
    local hookValue = nil
    
    -- Create pre-hook
    local hook = hm:PreHook(HM_TestTarget, "testMethod", function(...)
        hookCalled = true
        hookValue = ...
        -- Return true to cancel original
        return false  -- Let original run
    end)
    
    TK.assertNotNil(hook, "hook created")
    TK.assertTrue(hook.id ~= nil, "hook has id")
    TK.assertEqual(hook.kind, "pre", "hook kind is pre")
    TK.assertTrue(hook.enabled == true, "hook starts enabled")
    TK.assertEqual(hook.target, HM_TestTarget, "hook target set")
    TK.assertEqual(hook.method, "testMethod", "hook method set")
    
    -- Verify hook is in manager
    local retrieved = hm:get(hook.id)
    TK.assertNotNil(retrieved, "hook retrievable from manager")
    TK.assertEqual(retrieved.id, hook.id, "hook ids match")
end

local function HookManager_testPostHookCreation()
    local fn = "testPostHookCreation"
    TK.printSuite(mn,fn)
    
    local hm = SF.HookManager:New("TestHM2")
    
    local hook = hm:PostHook(HM_TestTarget, "testMethod", function(...)
        d("post hook called")
    end)
    
    TK.assertNotNil(hook, "post hook created")
    TK.assertEqual(hm:get(hook.id), hook, "post hook registered")
    TK.assertEqual(hook.kind, "post", "post hook kind is correct")
    TK.assertTrue(hook.enabled == true, "post hook starts enabled")
end

local function HookManager_testSecurePostHookCreation()
    local fn = "testSecurePostHookCreation"
    TK.printSuite(mn,fn)
    
    local hm = SF.HookManager:New("TestHM3")
    
    local hook = hm:SecurePostHook(HM_TestTarget, "testMethod", function(...)
        d("secure post hook called")
    end)
    
    TK.assertNotNil(hook, "secure post hook created")
    TK.assertEqual(hm:get(hook.id), hook, "secure post hook registered")
    TK.assertEqual(hook.kind, "secure", "secure post hook kind is correct")
end

local function HookManager_testIdIncr()
  local hm = SF.HookManager:New("Test")

  local h1 = hm:PreHook(HM_TestTarget, "testMethod", function(...)
        hookCalled = true
        hookValue = ...
        -- Return true to cancel original
        return false  -- Let original run
    end)
  local h2 = hm:PreHook(HM_TestTarget, "testMethod", function(...)
        hookCalled = true
        hookValue = ...
        -- Return true to cancel original
        return false  -- Let original run
    end)
  local h3 = hm:PostHook(HM_TestTarget, "testMethod", function(...)
        hookCalled = true
        hookValue = ...
        -- Return true to cancel original
        return false  -- Let original run
    end)

  TK.assertEqual(h1.id, "Test1")
  TK.assertEqual(h2.id, "Test2")
  TK.assertEqual(h3.id, "Test3")
end

local function HookManager_testHookEnableDisable()
    local fn = "testHookEnableDisable"
    TK.printSuite(mn,fn)
    
    local hm = SF.HookManager:New("TestHM4")
    
    -- Create a hook
    local hook = hm:PreHook(HM_TestTarget, "testMethod", function() return true end)
    local hookId = hook.id
    
    -- Test initial state
    local retrieved = hm:get(hookId)
    TK.assertTrue(retrieved.enabled == true, "hook initially enabled")
    
    -- Disable the hook
    hm:disable(hookId)
    retrieved = hm:get(hookId)
    TK.assertTrue(retrieved.enabled == false, "hook disabled successfully")
    
    -- Re-enable the hook
    hm:enable(hookId)
    retrieved = hm:get(hookId)
    TK.assertTrue(retrieved.enabled == true, "hook re-enabled successfully")
end

local function HookManager_testHookToggle()
    local fn = "testHookToggle"
    TK.printSuite(mn,fn)
    
    local hm = SF.HookManager:New("TestHM5")
    local hook = hm:PreHook(HM_TestTarget, "testMethod", function() return true end)
    local hookId = hook.id
    
    -- Toggle twice should return to original state
    hm:toggle(hookId)
    local state1 = hm:get(hookId).enabled
    TK.assertTrue(state1 == false, "toggle disables enabled hook")
    
    hm:toggle(hookId)
    local state2 = hm:get(hookId).enabled
    TK.assertTrue(state2 == true, "toggle re-enables disabled hook")
end

local function HookManager_testHookRemove()
    local fn = "testHookRemove"
    TK.printSuite(mn,fn)
    
    local hm = SF.HookManager:New("TestHM6")
    local hook = hm:PreHook(HM_TestTarget, "testMethod", function() return true end)
    local hookId = hook.id
    
    -- Verify exists
    local retrieved = hm:get(hookId)
    TK.assertNotNil(retrieved, "hook exists before removal")
    
    -- Remove it
    hm:remove(hookId)
    retrieved = hm:get(hookId)
    TK.assertNil(retrieved, "hook removed from manager")
    
    -- Try to remove again (should not error)
    hm:remove(hookId)
    TK.assertTrue(true, "remove non-existent hook does not crash")
end

local function HookManager_testBulkOperations()
    local fn = "testBulkOperations"
    TK.printSuite(mn,fn)
    
    local hm = SF.HookManager:New("TestHM7")
    
    -- Create multiple hooks
    local hook1 = hm:PreHook(HM_TestTarget, "testMethod", function() return true end)
    local hook2 = hm:PostHook(HM_TestTarget, "testMethod", function() end)
    local hook3 = hm:SecurePostHook(HM_TestTarget, "testMethod", function() end)
    
    -- Verify all start enabled
    TK.assertTrue(hm:get(hook1.id).enabled, "hook1 enabled")
    TK.assertTrue(hm:get(hook2.id).enabled, "hook2 enabled")
    TK.assertTrue(hm:get(hook3.id).enabled, "hook3 enabled")
    
    -- Disable all
    hm:disableAll()
    TK.assertFalse(hm:get(hook1.id).enabled, "hook1 disabled")
    TK.assertFalse(hm:get(hook2.id).enabled, "hook2 disabled")
    TK.assertFalse(hm:get(hook3.id).enabled, "hook3 disabled")
    
    -- Enable all
    hm:enableAll()
    TK.assertTrue(hm:get(hook1.id).enabled, "hook1 enabled after enableAll")
    TK.assertTrue(hm:get(hook2.id).enabled, "hook2 enabled after enableAll")
    TK.assertTrue(hm:get(hook3.id).enabled, "hook3 enabled after enableAll")
    
    -- Toggle all
    hm:toggleAll()
    TK.assertFalse(hm:get(hook1.id).enabled, "hook1 disabled after toggleAll")
    TK.assertFalse(hm:get(hook2.id).enabled, "hook2 disabled after toggleAll")
    TK.assertFalse(hm:get(hook3.id).enabled, "hook3 disabled after toggleAll")
end

local function HookManager_testNonExistentHook()
    local fn = "testNonExistentHook"
    TK.printSuite(mn,fn)
    
    local hm = SF.HookManager:New("TestHM8")
    
    -- Operations on non-existent hooks should not error
    TK.assertNil(hm:get("nonexistent"), "get non-existent returns nil")
    hm:disable("nonexistent")
    hm:enable("nonexistent")
    hm:toggle("nonexistent")
    hm:remove("nonexistent")
    
    TK.assertTrue(true, "operations on non-existent hooks do not crash")
end

local function HookManager_testUniqueIds()
    local fn = "testUniqueIds"
    TK.printSuite(mn,fn)
    
    local hm = SF.HookManager:New("TestHM9")
    
    -- Create first hook
    local hook1 = hm:PreHook(HM_TestTarget, "testMethod", function() return true end)
    local hookId1 = hook1.id
    
    -- The HookManager generates unique IDs, so we can't easily test
    -- duplicate prevention without manipulating internals. 
    -- But we verify each hook gets a unique ID
    local hook2 = hm:PreHook(HM_TestTarget, "testMethod", function() return true end)
    local hookId2 = hook2.id
    
    TK.assertNotEqual(hookId1, hookId2, "each hook gets unique ID")
end

local function HookManager_testHookObjectProperties()
    local fn = "testHookObjectProperties"
    TK.printSuite(mn,fn)
    
    local hm = SF.HookManager:New("TestHM10")
    local myFn = function() d("callback") end
    
    local preHook = hm:PreHook(HM_TestTarget, "testMethod", myFn)
    local postHook = hm:PostHook(HM_TestTarget, "testMethod", myFn)
    local secureHook = hm:SecurePostHook(HM_TestTarget, "testMethod", myFn)
    
    -- Test pre-hook properties
    TK.assertEqual(preHook.kind, "pre", "pre-hook kind")
    TK.assertEqual(preHook.fn, myFn, "pre-hook function reference")
    TK.assertEqual(preHook.target, HM_TestTarget, "pre-hook target")
    TK.assertEqual(preHook.method, "testMethod", "pre-hook method")
    
    -- Test post-hook properties
    TK.assertEqual(postHook.kind, "post", "post-hook kind")
    TK.assertEqual(postHook.fn, myFn, "post-hook function reference")
    
    -- Test secure-hook properties
    TK.assertEqual(secureHook.kind, "secure", "secure-hook kind")
    TK.assertEqual(secureHook.fn, myFn, "secure-hook function reference")
end

--------------------------------------------------------------------------------
-- RUN ALL TESTS
--------------------------------------------------------------------------------
-- Run all LSV_Data test suites
function Test_HookManager_All()
    HookManager_testInstanceCreation()
    HookManager_testPreHookCreation()
    HookManager_testPostHookCreation()
    HookManager_testSecurePostHookCreation()
    HookManager_testIdIncr()
    HookManager_testHookEnableDisable()
    HookManager_testHookToggle()
    HookManager_testHookRemove()
    HookManager_testBulkOperations()
    HookManager_testNonExistentHook()
    HookManager_testUniqueIds()
    HookManager_testHookObjectProperties()
end


if not Suite then
    TK.init()
    
    Test_HookManager_All()
    
    TK.showResult("HookManager Unit Tests")
end
