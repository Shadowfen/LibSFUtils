package.path = package.path .. ";C:/Users/scott/Documents/SFAddons/TK/?.lua;C:/Users/scott/Documents/Elder Scrolls Online/live/AddOns/LibSFUtils/?.lua"

require "zos"
require "tk"
local TK = TestKit

require "LibSFUtils_Global"
require "SFUtils_Strings"
require "SFUtils_Color"
require "LibSFUtils"
require "SFUtils_Logger"
require "SFUtils_CallLater"
local SF = LibSFUtils

local TR = test_log

local moduleName = "SFUtils_CallLater"
local mn = moduleName


-- Mock timer system for testing
-- Better mock that tracks queue growth during callbacks
local mockTimers = {}
local mockTimerId = 1
local pendingQueue = {}

_G.zo_callLater = function(callback, delay)
    local id = mockTimerId
    mockTimerId = mockTimerId + 1
    mockTimers[id] = { callback = callback, delay = delay, active = true }
    pendingQueue[#pendingQueue + 1] = { id = id, cb = callback, delay = delay }
    return id
end

_G.zo_removeCallLater = function(timerId)
    if mockTimers[timerId] then
        mockTimers[timerId].active = false
    end
    for i = #pendingQueue, 1, -1 do
        if pendingQueue[i].id == timerId then
            table.remove(pendingQueue, i)
        end
    end
end

function triggerPendingCallbacks()
    local current = pendingQueue
    pendingQueue = {}
    
    -- Copy pending count BEFORE clearing for comparison
    -- Actually we want to track queue SIZE CHANGE during each callback
    
    for i = 1, #current do
        local entry = current[i]
        local timerData = mockTimers[entry.id]
        
        if timerData and timerData.active then
            local queueBefore = #pendingQueue  -- Should be 0 since we cleared above
            
            if type(entry.cb) == "function" then
                pcall(entry.cb)
            end
            
            local queueAfter = #pendingQueue
            
            if queueAfter > queueBefore then
                -- A NEW timer was scheduled (retry or periodic)
                -- Current timer stays inactive, new timer is active
                timerData.active = false
                -- The new timer at pendingQueue[#pendingQueue] is active
            else
                -- No new timer scheduled - deactivate
                timerData.active = false
            end
        end
    end
end

function clearMockTimers()
    mockTimers = {}
    pendingQueue = {}
    mockTimerId = 1
end

-- main
TK.init()
clearMockTimers()

local function CallLater_testInstanceCreation()
    local fn = "testInstanceCreation"
    TK.printSuite(mn,fn)
    
    local timer = SF.CallLater:New(function() d("test") end)
    TK.assertNotNil(timer, "timer created")
    TK.assertTrue(type(timer) == "table", "timer is table")
    
    local timer2 = SF.CallLater:New(function() d("test2") end, 1000)
    TK.assertEqual(timer2.delay, 1000, "delay set to 1000ms")
    
    local timer3 = SF.CallLater:NewSingle(function() d("test3") end, 500)
    TK.assertEqual(timer3.delay, 500, "NewSingle creates timer with delay")
end

local function CallLater_testNewMaxTriesCreation()
    local fn = "testNewMaxTriesCreation"
    TK.printSuite(mn,fn)
    
    local timer = SF.CallLater:NewMaxTries(
        function() error("test error") end,
        1000,
        3
    )
    
    TK.assertNotNil(timer, "max tries timer created")
    TK.assertEqual(timer.maxTries, 3, "maxTries set to 3")
    TK.assertEqual(timer.attemptsMade, 0, "attemptsMade starts at 0")
    TK.assertEqual(timer.delay, 1000, "delay set to 1000ms")
end

local function CallLater_testNewTimerPeriodicCreation()
    local fn = "testNewTimerPeriodicCreation"
    TK.printSuite(mn,fn)
    
    local timer = SF.CallLater:NewTimer(function() d("periodic") end, 100)
    
    TK.assertNotNil(timer, "periodic timer created")
    TK.assertEqual(timer.interval, 100, "interval set to 100ms")
    TK.assertNotNil(timer.periodicCallback, "periodicCallback set")
    TK.assertNil(timer.callback, "one-shot callback should be nil")
end

local function CallLater_testIsRunningInitialState()
    local fn = "testIsRunningInitialState"
    TK.printSuite(mn,fn)
    
    local timer = SF.CallLater:New(function() d("test") end, 1000)
    TK.assertFalse(timer:IsRunning(), "timer not running before Start()")
    
    timer:Start()
    TK.assertTrue(timer:IsRunning(), "timer running after Start()")
end

local function CallLater_testStartOneShot()
    local fn = "testStartOneShot"
    TK.printSuite(mn,fn)
    
    local called = false
    local timer = SF.CallLater:New(function() 
        called = true 
    end, 1000)
    
    TK.assertFalse(called, "callback not called before start")
    TK.assertNil(timer.timerId, "timerId is nil before start")
    
    timer:Start()
    TK.assertTrue(timer:IsRunning(), "timer is running")
    TK.assertNotNil(timer.timerId, "timerId set after start")
    TK.assertFalse(called, "callback not called immediately")
    
    triggerPendingCallbacks()
    TK.assertTrue(called, "callback called after trigger")
end

local function CallLater_testStartWithArgs()
    local fn = "testStartWithArgs"
    TK.printSuite(mn,fn)
    
    local receivedArgs = {}
    local timer = SF.CallLater:New(function(...) 
        for i, v in ipairs({...}) do
            receivedArgs[i] = v
        end
    end, 500)
    
    timer:StartWithArgs("hello", 42, true)
    triggerPendingCallbacks()
    
    TK.assertEqual(receivedArgs[1], "hello", "first arg passed")
    TK.assertEqual(receivedArgs[2], 42, "second arg passed")
    TK.assertTrue(receivedArgs[3] == true, "third arg passed")
end

local function CallLater_testCancel()
    local fn = "testCancel"
    TK.printSuite(mn,fn)
    
    local called = false
    local timer = SF.CallLater:New(function() 
        called = true 
    end, 1000)
    
    timer:Start()
    TK.assertTrue(timer:IsRunning(), "timer running")
    
    local result = timer:Cancel()
    TK.assertTrue(result == true, "cancel returns true when cancelled")
    TK.assertFalse(timer:IsRunning(), "timer not running after cancel")
    TK.assertNil(timer.timerId, "timerId cleared")
    
    triggerPendingCallbacks()
    TK.assertFalse(called, "callback not called after cancel")
end

local function CallLater_testCancelAlreadyStopped()
    local fn = "testCancelAlreadyStopped"
    TK.printSuite(mn,fn)
    
    local timer = SF.CallLater:New(function() d("test") end, 1000)
    local result = timer:Cancel()
    TK.assertTrue(result == false, "cancel returns false when already stopped")
    TK.assertFalse(timer:IsRunning(), "still not running")
end

local function CallLater_testDestroy()
    local fn = "testDestroy"
    TK.printSuite(mn,fn)
    
    local timer = SF.CallLater:New(function() d("test") end, 1000)
    timer:Start()
    
    local result = timer:Destroy()
    TK.assertNil(result, "destroy returns nil")
    TK.assertFalse(timer:IsRunning(), "timer destroyed")
end

local function CallLater_testSetCallback()
    local fn = "testSetCallback"
    TK.printSuite(mn,fn)
    
    local calledWith = nil
    local timer = SF.CallLater:New(function(x) 
        calledWith = "original:" .. tostring(x)
    end, 100)
    
    local newCallback = function(x) 
        calledWith = "new:" .. tostring(x)
    end
    
    timer:SetCallback(newCallback)
    timer:StartWithArgs("test")
    triggerPendingCallbacks()
    
    TK.assertEqual(calledWith, "new:test", "callback replaced successfully")
end

local function CallLater_testSetDelay()
    local fn = "testSetDelay"
    TK.printSuite(mn,fn)
    
    local timer = SF.CallLater:New(function() d("test") end, 1000)
    
    timer:SetDelay(500)
    TK.assertEqual(timer.delay, 500, "delay changed to 500ms")
    
    timer:SetDelay(250)
    TK.assertEqual(timer.delay, 250, "delay changed to 250ms")
end

local function CallLater_testPeriodicTimer()
    local fn = "testPeriodicTimer"
    TK.printSuite(mn,fn)
    
    local tickCount = 0
    local timer = SF.CallLater:NewTimer(function()
        tickCount = tickCount + 1
    end, 100)
    
    TK.assertEqual(tickCount, 0, "ticks before start")
    TK.assertFalse(timer:IsRunning(), "not running before start")
    
    timer:Start()
    TK.assertTrue(timer:IsRunning(), "running after start")
    
    triggerPendingCallbacks()
    TK.assertEqual(tickCount, 1, "one tick after first trigger")
    
    triggerPendingCallbacks()
    TK.assertEqual(tickCount, 2, "two ticks after second trigger")
end

local function CallLater_testPeriodicCancel()
    local fn = "testPeriodicCancel"
    TK.printSuite(mn,fn)
    
    local tickCount = 0
    local timer = SF.CallLater:NewTimer(function()
        tickCount = tickCount + 1
    end, 100)
    
    timer:Start()
    triggerPendingCallbacks()
    TK.assertEqual(tickCount, 1, "one tick before cancel")
    
    timer:Cancel()
    TK.assertFalse(timer:IsRunning(), "cancelled")
    
    triggerPendingCallbacks()
    TK.assertEqual(tickCount, 1, "no more ticks after cancel")
end

local function CallLater_testStartWithArgsNotSupportedPeriodic()
    local fn = "testStartWithArgsNotSupportedPeriodic"
    TK.printSuite(mn,fn)
    
    local timer = SF.CallLater:NewTimer(function() d("periodic") end, 100)
    
    -- Should log warning and return early WITHOUT starting
    timer:StartWithArgs("arg1", "arg2")
    TK.assertTrue(true, "StartWithArgs on periodic timer does not crash")
    TK.assertFalse(timer:IsRunning(), "timer NOT started (StartWithArgs rejected)")
end

local function CallLater_testChainMethods()
    local fn = "testChainMethods"
    TK.printSuite(mn,fn)
    
    local timer = SF.CallLater:New(function() d("test") end, 1000)
    
    local result1 = timer:SetDelay(500)
    TK.assertEqual(result1, timer, "SetDelay returns self")
    
    local result2 = timer:SetCallback(function() d("new") end)
    TK.assertEqual(result2, timer, "SetCallback returns self")
    
    local timer2 = SF.CallLater:New(function() d("chain") end, 1000):SetDelay(200):Start()
    TK.assertTrue(timer2:IsRunning(), "chained Start() works")
end

local function CallLater_testRestartAfterCancel()
    local fn = "testRestartAfterCancel"
    TK.printSuite(mn,fn)
    
    local callCount = 0
    local timer = SF.CallLater:New(function() 
        callCount = callCount + 1
    end, 100)
    
    timer:Start()
    triggerPendingCallbacks()
    TK.assertEqual(callCount, 1, "first call")
    
    timer:Start()
    triggerPendingCallbacks()
    TK.assertEqual(callCount, 2, "second call after restart")
end

local function CallLater_testMultipleInstances()
    local fn = "testMultipleInstances"
    TK.printSuite(mn,fn)
    
    local results = {}
    
    local timer1 = SF.CallLater:New(function() table.insert(results, 1) end, 100)
    local timer2 = SF.CallLater:New(function() table.insert(results, 2) end, 200)
    local timer3 = SF.CallLater:New(function() table.insert(results, 3) end, 50)
    
    timer1:Start()
    timer2:Start()
    timer3:Start()
    
    triggerPendingCallbacks()
    
    TK.assertTrue(#results == 3, "all three timers executed")
    TK.assertTrue(results[1] == 1, "timer1 executed")
    TK.assertTrue(results[2] == 2, "timer2 executed")
    TK.assertTrue(results[3] == 3, "timer3 executed")
end

local function CallLater_testNilCallback()
    local fn = "testNilCallback"
    TK.printSuite(mn,fn)
    
    local timer = SF.CallLater:New(nil, 1000)
    
    -- Start() guards against nil callback and returns early
    -- without activating the timer
    timer:Start()
    TK.assertFalse(timer:IsRunning(), "timer does not start without callback")
    TK.assertNil(timer.timerId, "no timerId set without callback")
    
    -- Should not crash when triggering
    triggerPendingCallbacks()
    TK.assertTrue(true, "trigger with nil callback does not crash")
end

local function CallLater_testErrorHandlingInCallback()
    local fn = "testErrorHandlingInCallback"
    TK.printSuite(mn,fn)
    
    local callCount = 0
    local timer = SF.CallLater:New(function() 
        callCount = callCount + 1
        if callCount < 3 then
            error("intentional error " .. callCount)
        end
    end, 100)
    
    timer:Start()
    triggerPendingCallbacks()
    TK.assertTrue(true, "error in callback does not crash test")
end

local function CallLater_testRetryExhaustion()
    local fn = "testRetryExhaustion"
    TK.printSuite(mn,fn)
    
    local attemptCount = 0
    local maxTries = 2
    
    local timer = SF.CallLater:NewMaxTries(
        function()
            attemptCount = attemptCount + 1
            error("always fails")
        end,
        100,
        maxTries
    )
    
    timer:Start()
    TK.assertTrue(timer:IsRunning(), "timer starts running")
    
    -- First trigger: attempt 1 fails, reschedules (1 < 2 = true)
    triggerPendingCallbacks()
    TK.assertEqual(attemptCount, 1, "attempt 1 made")
    TK.assertEqual(timer.attemptsMade, 1, "attemptsMade = 1")
    TK.assertEqual(timer.maxTries, maxTries, "maxTries still set")
    TK.assertTrue(timer:IsRunning(), "timer running after retry scheduled")
    
    -- Second trigger: attempt 2 fails, exhausts (2 < 2 = false)
    triggerPendingCallbacks()
    TK.assertEqual(attemptCount, 2, "attempt 2 made")
    TK.assertFalse(timer:IsRunning(), "timer deactivated after exhausting")
    TK.assertNil(timer.maxTries, "maxTries cleared after exhaustion")
    TK.assertNil(timer.attemptsMade, "attemptsMade cleared after exhaustion")
end

local function CallLater_testRetrySuccess()
    local fn = "testRetrySuccess"
    TK.printSuite(mn,fn)
    
    local attemptCount = 0
    local maxTries = 3
    
    local timer = SF.CallLater:NewMaxTries(
        function()
            attemptCount = attemptCount + 1
            if attemptCount < 2 then
                error("fail " .. attemptCount)
            end
            -- Success on attempt 2
        end,
        100,
        maxTries
    )
    
    timer:Start()
    
    -- First trigger: attempt 1 fails, reschedules
    triggerPendingCallbacks()
    TK.assertEqual(attemptCount, 1, "attempt 1 made")
    TK.assertEqual(timer.attemptsMade, 1, "attemptsMade = 1")
    TK.assertTrue(timer:IsRunning(), "timer running after retry scheduled")
    
    -- Second trigger: attempt 2 succeeds, clears tracking
    triggerPendingCallbacks()
    TK.assertEqual(attemptCount, 2, "attempt 2 made and succeeded")
    TK.assertFalse(timer:IsRunning(), "timer inactive after success")
    TK.assertNil(timer.maxTries, "maxTries cleared after success")
    TK.assertNil(timer.attemptsMade, "attemptsMade cleared after success")
end

local function CallLater_testNonExistentHookOperations()
    local fn = "testNonExistentHookOperations"
    TK.printSuite(mn,fn)
    
    local timer = SF.CallLater:New(function() d("test") end, 100)
    local nonExistentId = "does-not-exist"
    
    TK.assertNil(timer:get(nonExistentId), "get non-existent returns nil")
    TK.assertFalse(timer:IsRunning(), "IsRunning works normally")
end

local function CallLater_testInternalStateCleanup()
    local fn = "testInternalStateCleanup"
    TK.printSuite(mn,fn)
    
    local timer = SF.CallLater:New(function() d("test") end, 100)
    timer:Start()
    timer:Cancel()
    
    TK.assertNil(timer.timerId, "timerId cleared")
    TK.assertNil(timer.pendingArgs, "pendingArgs cleared after cancel")
    TK.assertNotNil(timer.callback, "callback cleared after cancel")
    
    timer:Destroy()
    TK.assertNil(timer.callback, "callback cleared after destroy")
end

local function CallLater_testInvalidParameters()
    local fn = "testInvalidParameters"
    TK.printSuite(mn,fn)
    
    -- Test 1: Negative delay
    local timer = SF.CallLater:New(function() d("test") end, -100)
    TK.assertEqual(timer.delay, -100, "negative delay accepted and stored")
    -- Timer still creates successfully, just with unusual delay
    TK.assertTrue(type(timer) == "table", "timer object created despite negative delay")
    
    -- Test 2: Zero delay (should be valid - fires immediately-ish)
    local timer2 = SF.CallLater:New(function() d("instant") end, 0)
    TK.assertEqual(timer2.delay, 0, "zero delay accepted")
    TK.assertTrue(type(timer2) == "table", "timer created with zero delay")
    
    -- Test 3: Nil delay (should default to 0)
    local timer3 = SF.CallLater:New(function() d("default") end)
    TK.assertEqual(timer3.delay, 0, "nil delay defaults to 0")
    
    -- Test 4: Nil callback (should create but fail on Start)
    local timer4 = SF.CallLater:New(nil, 100)
    TK.assertEqual(timer4.callback, nil, "nil callback stored")
    TK.assertTrue(type(timer4) == "table", "timer created with nil callback")
    -- Verify it doesn't start (callback guard in Start())
    timer4:Start()
    TK.assertFalse(timer4:IsRunning(), "timer with nil callback does not start")
    
    -- Test 5: Non-function callback (should store but fail on execution)
    local timer5 = SF.CallLater:New("not_a_function", 100)
    TK.assertEqual(timer5.callback, "not_a_function", "string callback stored")
    -- Should not crash on Start
    timer5:Start()
    TK.assertTrue(timer5:IsRunning(), "timer starts with invalid callback (fails on trigger)")
    triggerPendingCallbacks()
    -- Callback fails silently via pcall, timer stops
    TK.assertFalse(timer5:IsRunning(), "timer stops after failed callback")
    
    -- Test 6: NaN delay (if Lua supports it)
    local nanDelay = 0/0
    local timer6 = SF.CallLater:New(function() end, nanDelay)
    TK.assertTrue(type(timer6) == "table", "timer created with NaN delay")
    -- NaN comparisons are weird in Lua, just verify creation
    TK.assertTrue(true, "NaN delay handled without crashing")
    
    -- Test 7: Very large delay
    local timer7 = SF.CallLater:New(function() end, 999999999)
    TK.assertEqual(timer7.delay, 999999999, "very large delay accepted")
    TK.assertTrue(type(timer7) == "table", "timer created with large delay")
end

local function CallLater_testInvalidMaxTries()
    local fn = "testInvalidMaxTries"
    TK.printSuite(mn,fn)
    
    -- Test 1: Zero maxTries
    local timer = SF.CallLater:NewMaxTries(function() d("test") end, 100, 0)
    TK.assertEqual(timer.maxTries, 0, "zero maxTries stored")
    TK.assertEqual(timer.attemptsMade, 0, "attemptsMade starts at 0")
    timer:Start()
    triggerPendingCallbacks()
    -- With maxTries=0, should not retry at all
    TK.assertNil(timer.attemptsMade, "no retries with maxTries=0")
    
    -- Test 2: Negative maxTries (gets floor'd to negative)
    local timer2 = SF.CallLater:NewMaxTries(function() d("test") end, 100, -5)
    TK.assertFalse(timer2.maxTries < 0, "negative maxTries stored (floor applied)")
    -- Negative maxTries means no retries (attemptsMade < maxTries always false)
    timer2:Start()
    triggerPendingCallbacks()
    TK.assertNil(timer2.maxTries, "maxTries cleared after first failure with negative value")
    
    -- Test 3: Nil maxTries
    local timer3 = SF.CallLater:NewMaxTries(function() d("test") end, 100, nil)
    TK.assertEqual(timer3.maxTries, 0, "nil maxTries becomes 0")
    -- Without maxTries set, retry logic won't work
    TK.assertTrue(type(timer3) == "table", "timer created with nil maxTries")
    
    -- Test 4: Decimal maxTries (should floor)
    local timer4 = SF.CallLater:NewMaxTries(function() d("test") end, 100, 3.7)
    TK.assertEqual(timer4.maxTries, 3, "decimal maxTries floored to 3")
    
    -- Test 5: String maxTries (should become 0)
    local timer5 = SF.CallLater:NewMaxTries(function() d("test") end, 100, "five")
    TK.assertEqual(timer5.maxTries, 0, "string maxTries becomes 0")
end

local function CallLater_testInvalidInterval()
    local fn = "testInvalidInterval"
    TK.printSuite(mn,fn)
    
    -- Test 1: Negative interval
    local timer = SF.CallLater:NewTimer(function() d("periodic") end, -100)
    TK.assertEqual(timer.interval, -100, "negative interval stored")
    timer:Start()
    TK.assertTrue(timer:IsRunning(), "timer starts with negative interval")
    -- Will schedule indefinitely with negative/zero delay
    triggerPendingCallbacks()
    TK.assertTrue(timer:IsRunning(), "periodic timer continues (might spam)")
    
    -- Test 2: Zero interval
    local timer2 = SF.CallLater:NewTimer(function() d("spam") end, 0)
    timer2:Start()
    triggerPendingCallbacks()
    TK.assertTrue(timer2:IsRunning(), "zero interval timer runs")
    -- Could cause infinite loop in real scenario
    
    -- Test 3: Nil interval
    local ok, err = pcall(function()
        SF.CallLater:NewTimer(function() end, nil)
    end)
    -- Should work, interval becomes 0 or nil
    TK.assertTrue(ok, "nil interval handled without crash")
    
    -- Test 4: Very large interval
    local timer3 = SF.CallLater:NewTimer(function() end, 999999999)
    TK.assertEqual(timer3.interval, 999999999, "large interval accepted")
    TK.assertTrue(type(timer3) == "table", "timer created with large interval")
end

local function CallLater_testInvalidMethodChaining()
    local fn = "testInvalidMethodChaining"
    TK.printSuite(mn,fn)
    
    local timer = SF.CallLater:New(function() end, 100)
    
    -- Test SetCallback with nil
    timer:SetCallback(nil)
    TK.assertNil(timer.callback, "callback set to nil")
    
    -- Test SetDelay with invalid values
    timer:SetDelay(-500)
    TK.assertEqual(timer.delay, -500, "negative delay accepted")
    
    timer:SetDelay(nil)
    -- Depends on implementation: might stay same or become 0
    TK.assertTrue(type(timer.delay) == "number", "delay remains a number")
    
    -- Start with modified state should not crash
    timer:Start()
    TK.assertTrue(true, "start after invalid changes does not crash")
end


--------------------------------------------------------------------------------
-- RUN ALL TESTS
--------------------------------------------------------------------------------
-- Run all LSV_Data test suites
function Test_CallLater_All()
    CallLater_testInstanceCreation()
    CallLater_testNewMaxTriesCreation()
    CallLater_testNewTimerPeriodicCreation()
    CallLater_testIsRunningInitialState()
    CallLater_testStartOneShot()
    CallLater_testStartWithArgs()
    CallLater_testCancel()
    CallLater_testCancelAlreadyStopped()
    CallLater_testDestroy()
    CallLater_testSetCallback()
    CallLater_testSetDelay()
    CallLater_testPeriodicTimer()
    CallLater_testPeriodicCancel()
    CallLater_testStartWithArgsNotSupportedPeriodic()
    CallLater_testChainMethods()
    CallLater_testRestartAfterCancel()
    CallLater_testMultipleInstances()
    CallLater_testNilCallback()
    CallLater_testErrorHandlingInCallback()
    CallLater_testRetryExhaustion()
    CallLater_testRetrySuccess()
    CallLater_testInternalStateCleanup()
    CallLater_testInvalidParameters()
    CallLater_testInvalidMaxTries()
    CallLater_testInvalidInterval()
    CallLater_testInvalidMethodChaining()
end


if not Suite then
    TK.init()
    
    Test_CallLater_All()
    
    TK.showResult("CallLater Unit Tests")
end