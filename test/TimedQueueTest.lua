package.path = package.path .. ";C:/Users/scott/Documents/SFAddons/TK/?.lua;C:/Users/scott/Documents/Elder Scrolls Online/live/AddOns/LibSFUtils/?.lua"

require "zos"
require "tk"
local TK = TestKit

require "LibSFUtils_Global"
require "SFUtils_Strings"
require "SFUtils_Color"
require "LibSFUtils"
require "SFUtils_Logger"
require "SFUtils_TimedQueue"
local SF = LibSFUtils

local TR = test_log

local moduleName = "SFUtils_TimedQueue"
local mn = moduleName

-- Mock GetGameTimeMilliseconds for deterministic testing
local mockTime = 1000
_G.GetGameTimeMilliseconds = function()
    return mockTime
end

function advanceMockTime(ms)
    mockTime = mockTime + ms
end



local function TimedQueue_testInstanceCreation()
    local fn = "testInstanceCreation"
    TK.printSuite(mn,fn)
    
    -- Test basic creation
    local q = SF.TimedQueue:New(5)
    TK.assertNotNil(q, "queue created")
    TK.assertTrue(type(q) == "table", "queue is table")
    TK.assertEqual(q:getMax(), 5, "initialMax set to 5")
    TK.assertEqual(q:size(), 0, "starts empty")
    
    -- Test with explicit maxPossible
    local q2 = SF.TimedQueue:New(5, 10)
    TK.assertEqual(q2:getMax(), 5, "initialMax is 5")
    -- Note: _maxPossible is internal, we can't directly test it
end

local function TimedQueue_testPushAndPeek()
    local fn = "testPushAndPeek"
    TK.printSuite(mn,fn)
    
    local q = SF.TimedQueue:New(5)
    
    TK.assertNil(q:peek(), "peek on empty returns nil")
    
    q:push("item1")
    local entry = q:peek()
    TK.assertNotNil(entry, "peek returns entry")
    TK.assertEqual(entry.payload, "item1", "payload is item1")
    TK.assertEqual(q:size(), 1, "size is 1")
    
    q:push("item2")
    q:push("item3")
    
    entry = q:peek()
    TK.assertEqual(entry.payload, "item3", "newest entry is item3")
    TK.assertEqual(q:size(), 3, "size is 3")
end

local function TimedQueue_testTimestampPreservation()
    local fn = "testTimestampPreservation"
    TK.printSuite(mn,fn)
    
    local q = SF.TimedQueue:New(5)
    
    mockTime = 1000
    q:push("a")
    
    mockTime = 2000
    q:push("b")
    
    mockTime = 3000
    q:push("c")
    
    local list = q:list()
    TK.assertEqual(#list, 3, "3 entries")
    
    -- List is newest to oldest
    TK.assertEqual(list[1].payload, "c", "newest is first")
    TK.assertEqual(list[1].ts, 3000, "timestamp correct for c")
    
    TK.assertEqual(list[2].payload, "b", "middle is second")
    TK.assertEqual(list[2].ts, 2000, "timestamp correct for b")
    
    TK.assertEqual(list[3].payload, "a", "oldest is third")
    TK.assertEqual(list[3].ts, 1000, "timestamp correct for a")
end

local function TimedQueue_testCircularBufferOverflow()
    local fn = "testCircularBufferOverflow"
    TK.printSuite(mn,fn)
    
    local q = SF.TimedQueue:New(3)  -- max 3 items
    
    q:push("1")
    q:push("2")
    q:push("3")
    TK.assertEqual(q:size(), 3, "size is 3 at capacity")
    
    -- Push 4th item - should overwrite oldest ("1")
    q:push("4")
    TK.assertEqual(q:size(), 3, "size remains 3 after overflow")
    
    local list = q:list()
    TK.assertEqual(#list, 3, "list has 3 items")
    TK.assertEqual(list[1].payload, "4", "newest is 4")
    TK.assertEqual(list[2].payload, "3", "middle is 3")
    TK.assertEqual(list[3].payload, "2", "oldest is 2 (1 was overwritten)")
end

local function TimedQueue_testSetMaxGrow()
    local fn = "testSetMaxGrow"
    TK.printSuite(mn,fn)
    
    -- Create with maxPossible = 10 so we can grow to 5
    local q = SF.TimedQueue:New(3, 10)
    
    q:push("1")
    q:push("2")
    
    TK.assertEqual(q:getMax(), 3, "initial max is 3")
    TK.assertEqual(q:size(), 2, "size is 2")
    
    q:setMax(5)
    TK.assertEqual(q:getMax(), 5, "max increased to 5")
    TK.assertEqual(q:size(), 2, "size unchanged after grow")
    
    q:push("3")
    q:push("4")
    TK.assertEqual(q:size(), 4, "can add more items after grow")
end

local function TimedQueue_testSetMaxShrink()
    local fn = "testSetMaxShrink"
    TK.printSuite(mn,fn)
    
    local q = SF.TimedQueue:New(5)
    
    q:push("1")
    q:push("2")
    q:push("3")
    q:push("4")
    q:push("5")
    TK.assertEqual(q:size(), 5, "filled to capacity")
    
    q:setMax(3)
    TK.assertEqual(q:getMax(), 3, "max reduced to 3")
    TK.assertEqual(q:size(), 3, "size reduced to 3 (oldest discarded)")
    
    local list = q:list()
    TK.assertEqual(list[1].payload, "5", "newest remains")
    TK.assertEqual(list[2].payload, "4", "middle remains")
    TK.assertEqual(list[3].payload, "3", "oldest is now 3 (1 and 2 discarded)")
end

local function TimedQueue_testSetMaxClamp()
    local fn = "testSetMaxClamp"
    TK.printSuite(mn,fn)
    
    local q = SF.TimedQueue:New(5, 10)  -- maxPossible = 10
    
    q:setMax(-5)  -- Too low
    TK.assertEqual(q:getMax(), 1, "clamped to minimum 1")
    
    q:setMax(15)  -- Above maxPossible
    TK.assertEqual(q:getMax(), 10, "clamped to maxPossible 10")
    
    q:setMax(0)
    TK.assertEqual(q:getMax(), 1, "zero clamped to 1")
end

local function TimedQueue_testClear()
    local fn = "testClear"
    TK.printSuite(mn,fn)
    
    local q = SF.TimedQueue:New(5)
    
    q:push("1")
    q:push("2")
    q:push("3")
    TK.assertEqual(q:size(), 3, "has 3 items")
    
    q:clear()
    TK.assertEqual(q:size(), 0, "size is 0 after clear")
    TK.assertNil(q:peek(), "peek returns nil after clear")
    TK.assertEqual(#q:list(), 0, "list is empty")
    
    -- Should still be usable after clear
    q:push("new")
    TK.assertEqual(q:size(), 1, "can push after clear")
    TK.assertEqual(q:peek().payload, "new", "new item added")
end

local function TimedQueue_testPopOldest()
    local fn = "testPopOldest"
    TK.printSuite(mn,fn)
    
    local q = SF.TimedQueue:New(5)
    
    q:push("1")
    q:push("2")
    q:push("3")
    
    local entry = q:popOldest()
    TK.assertEqual(entry.payload, "1", "popped oldest (1)")
    TK.assertEqual(q:size(), 2, "size reduced to 2")
    
    entry = q:popOldest()
    TK.assertEqual(entry.payload, "2", "popped next oldest (2)")
    TK.assertEqual(q:size(), 1, "size reduced to 1")
    
    entry = q:popOldest()
    TK.assertEqual(entry.payload, "3", "popped last item (3)")
    TK.assertEqual(q:size(), 0, "size is 0")
    
    entry = q:popOldest()
    TK.assertNil(entry, "pop on empty returns nil")
    TK.assertEqual(q:size(), 0, "still empty")
end

local function TimedQueue_testPopNewest()
    local fn = "testPopNewest"
    TK.printSuite(mn,fn)
    
    local q = SF.TimedQueue:New(5)
    
    q:push("1")
    q:push("2")
    q:push("3")
    
    local entry = q:popNewest()
    TK.assertEqual(entry.payload, "3", "popped newest (3)")
    TK.assertEqual(q:size(), 2, "size reduced to 2")
    
    entry = q:popNewest()
    TK.assertEqual(entry.payload, "2", "popped next newest (2)")
    TK.assertEqual(q:size(), 1, "size reduced to 1")
    
    entry = q:popNewest()
    TK.assertEqual(entry.payload, "1", "popped last item (1)")
    TK.assertEqual(q:size(), 0, "size is 0")
    
    entry = q:popNewest()
    TK.assertNil(entry, "pop on empty returns nil")
end

local function TimedQueue_testRemoveByReference()
    local fn = "testRemoveByReference"
    TK.printSuite(mn,fn)
    
    local q = SF.TimedQueue:New(5)
    
    q:push("1")
    q:push("target")
    q:push("3")
    
    local list = q:list()
    local targetEntry = nil
    for _, entry in ipairs(list) do
        if entry.payload == "target" then
            targetEntry = entry
            break
        end
    end
    
    TK.assertNotNil(targetEntry, "found target entry")
    
    local result = q:remove(targetEntry)
    TK.assertTrue(result, "remove returned true")
    TK.assertEqual(q:size(), 2, "size reduced to 2")
    
    -- Verify order preserved
    list = q:list()
    TK.assertEqual(list[1].payload, "3", "newest is 3")
    TK.assertEqual(list[2].payload, "1", "oldest is 1 (target removed)")
end

local function TimedQueue_testRemoveNotFound()
    local fn = "testRemoveNotFound"
    TK.printSuite(mn,fn)
    
    local q = SF.TimedQueue:New(5)
    q:push("1")
    q:push("2")
    
    -- Try to remove non-existent entry
    local fakeEntry = { payload = "fake" }
    local result = q:remove(fakeEntry)
    TK.assertFalse(result, "remove returned false")
    TK.assertEqual(q:size(), 2, "size unchanged")
end

local function TimedQueue_testRemoveByPayload()
    local fn = "testRemoveByPayload"
    TK.printSuite(mn,fn)
    
    local q = SF.TimedQueue:New(5)
    
    q:push("1")
    q:push("target")
    q:push("3")
    
    local result = q:removeByPayload("target")
    TK.assertTrue(result, "removeByPayload returned true")
    TK.assertEqual(q:size(), 2, "size reduced to 2")
    
    local list = q:list()
    TK.assertEqual(list[1].payload, "3", "newest is 3")
    TK.assertEqual(list[2].payload, "1", "oldest is 1 (target removed)")
end

local function TimedQueue_testRemoveByPayloadNotFound()
    local fn = "testRemoveByPayloadNotFound"
    TK.printSuite(mn,fn)
    
    local q = SF.TimedQueue:New(5)
    q:push("1")
    q:push("2")
    
    local result = q:removeByPayload("notfound")
    TK.assertFalse(result, "removeByPayload returned false")
    TK.assertEqual(q:size(), 2, "size unchanged")
end

local function TimedQueue_testRemoveByPayloadFirstMatchOnly()
    local fn = "testRemoveByPayloadFirstMatchOnly"
    TK.printSuite(mn,fn)
    
    local q = SF.TimedQueue:New(5)
    
    q:push("1")
    q:push("dup")
    q:push("dup")  -- Duplicate payload
    q:push("3")
    
    local result = q:removeByPayload("dup")
    TK.assertTrue(result, "removeByPayload returned true")
    TK.assertEqual(q:size(), 3, "size reduced by 1 only")
    
    local list = q:list()
    -- Should remove the NEWEST "dup" first (list is newest to oldest)
    TK.assertEqual(list[1].payload, "3", "newest is 3")
    TK.assertEqual(list[2].payload, "dup", "one dup remains")
    TK.assertEqual(list[3].payload, "1", "oldest is 1")
end

local function TimedQueue_testRemoveIf()
    local fn = "testRemoveIf"
    TK.printSuite(mn,fn)
    
    local q = SF.TimedQueue:New(5)
    
    q:push("1")
    q:push("target1")
    q:push("3")
    q:push("target2")
    q:push("5")
    
    local result = q:removeIf(function(entry)
        return entry.payload:find("target")
    end)
    
    TK.assertTrue(result, "removeIf returned true")
    TK.assertEqual(q:size(), 4, "size reduced by 1")
    
    local list = q:list()
    TK.assertEqual(list[1].payload, "5", "newest is 5")
    -- Only first match removed, so one "target" remains
    TK.assertEqual(#list, 4, "4 items remain")
end

local function TimedQueue_testRemoveIfPredicateError()
    local fn = "testRemoveIfPredicateError"
    TK.printSuite(mn,fn)
    
    local q = SF.TimedQueue:New(5)
    q:push("1")
    q:push("2")
    
    -- Predicate must be a function
    local caught = false
    local ok, err = pcall(function()
        q:removeIf("not_a_function")
    end)
    TK.assertFalse(ok, "removeIf with non-function raises error")
end

local function TimedQueue_testRemoveIfNoMatch()
    local fn = "testRemoveIfNoMatch"
    TK.printSuite(mn,fn)
    
    local q = SF.TimedQueue:New(5)
    q:push("1")
    q:push("2")
    q:push("3")
    
    local result = q:removeIf(function(entry)
        return entry.payload == "notfound"
    end)
    
    TK.assertFalse(result, "removeIf returned false")
    TK.assertEqual(q:size(), 3, "size unchanged")
end

local function TimedQueue_testListOrder()
    local fn = "testListOrder"
    TK.printSuite(mn,fn)
    
    local q = SF.TimedQueue:New(5)
    
    q:push("first")
    q:push("second")
    q:push("third")
    
    local list = q:list()
    
    -- List should be newest to oldest
    TK.assertEqual(list[1].payload, "third", "newest first")
    TK.assertEqual(list[2].payload, "second", "middle second")
    TK.assertEqual(list[3].payload, "first", "oldest last")
    TK.assertEqual(#list, 3, "3 items total")
end

local function TimedQueue_testListSnapshot()
    local fn = "testListSnapshot"
    TK.printSuite(mn,fn)
    
    local q = SF.TimedQueue:New(5)
    
    q:push("1")
    q:push("2")
    
    local snapshot1 = q:list()
    
    q:push("3")
    
    local snapshot2 = q:list()
    
    -- Snapshots are independent
    TK.assertEqual(#snapshot1, 2, "snapshot1 has 2 items")
    TK.assertEqual(#snapshot2, 3, "snapshot2 has 3 items")
    
    -- Modifying snapshot shouldn't affect queue
    snapshot1[1] = "modified"
    local fresh = q:list()
    TK.assertEqual(fresh[1].payload, "3", "queue unchanged by snapshot modification")
end

local function TimedQueue_testMixedOperations()
    local fn = "testMixedOperations"
    TK.printSuite(mn,fn)
    
    local q = SF.TimedQueue:New(5)
    
    -- Push items
    q:push("a")
    q:push("b")
    q:push("c")
    
    -- Pop oldest
    q:popOldest()  -- removes "a"
    TK.assertEqual(q:size(), 2, "size is 2")
    
    -- Push more
    q:push("d")
    TK.assertEqual(q:size(), 3, "size is 3")
    
    -- Remove by payload
    q:removeByPayload("b")
    TK.assertEqual(q:size(), 2, "size is 2")
    
    -- Clear and verify
    q:clear()
    TK.assertEqual(q:size(), 0, "queue cleared")
    TK.assertNil(q:peek(), "peek returns nil")
end

local function TimedQueue_testEdgeCases()
    local fn = "testEdgeCases"
    TK.printSuite(mn,fn)
    
    -- Empty queue operations
    local q = SF.TimedQueue:New(5)
    
    TK.assertNil(q:peek(), "peek empty")
    TK.assertNil(q:popOldest(), "popOldest empty")
    TK.assertNil(q:popNewest(), "popNewest empty")
    TK.assertEqual(#q:list(), 0, "list empty")
    TK.assertEqual(q:size(), 0, "size empty")
    
    -- Remove operations on empty
    TK.assertFalse(q:remove({}), "remove empty")
    TK.assertFalse(q:removeByPayload("x"), "removeByPayload empty")
    TK.assertFalse(q:removeIf(function() return true end), "removeIf empty")
end

local function TimedQueue_testLargeCapacity()
    local fn = "testLargeCapacity"
    TK.printSuite(mn,fn)
    
    local q = SF.TimedQueue:New(100, 200)
    
    -- Fill beyond initial max
    for i = 1, 150 do
        q:push(i)
    end
    
    TK.assertEqual(q:size(), 100, "size capped at initialMax 100")
    
    -- Oldest 50 should be overwritten
    local list = q:list()
    TK.assertEqual(list[1].payload, 150, "newest is 150")
    TK.assertEqual(list[#list].payload, 51, "oldest is 51 (1-50 overwritten)")
end

--------------------------------------------------------------------------------
-- RUN ALL TESTS
--------------------------------------------------------------------------------
-- Run all TimedQueue test suites
function Test_TimedQueue_All()
    TK.init()
    
    TimedQueue_testInstanceCreation()
    TimedQueue_testPushAndPeek()
    TimedQueue_testTimestampPreservation()
    TimedQueue_testCircularBufferOverflow()
    TimedQueue_testSetMaxGrow()
    TimedQueue_testSetMaxShrink()
    TimedQueue_testSetMaxClamp()
    TimedQueue_testClear()
    TimedQueue_testPopOldest()
    TimedQueue_testPopNewest()
    TimedQueue_testRemoveByReference()
    TimedQueue_testRemoveNotFound()
    TimedQueue_testRemoveByPayload()
    TimedQueue_testRemoveByPayloadNotFound()
    TimedQueue_testRemoveByPayloadFirstMatchOnly()
    TimedQueue_testRemoveIf()
    TimedQueue_testRemoveIfPredicateError()
    TimedQueue_testRemoveIfNoMatch()
    TimedQueue_testListOrder()
    TimedQueue_testListSnapshot()
    TimedQueue_testMixedOperations()
    TimedQueue_testEdgeCases()
    TimedQueue_testLargeCapacity()
    
    TK.showResult("TimedQueue Unit Tests")
end


if not Suite then
    Test_TimedQueue_All()
end