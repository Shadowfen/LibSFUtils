package.path = package.path .. ";C:/Users/scott/Documents/SFAddons/TK/?.lua;C:/Users/scott/Documents/Elder Scrolls Online/live/AddOns/LibSFUtils/?.lua"

require "zos"
require "tk"
local TK = TestKit

require "LibSFUtils_Global"
require "SFUtils_Strings"
require "SFUtils_Color"
require "LibSFUtils"
require "SFUtils_Logger"
require "SFUtils_Queue"
local SF = LibSFUtils

local TR = test_log

local moduleName = "SFUtils_Queue"
local mn = moduleName

local Queue = SF.Queue

-- ============================================================================
-- Queue Tests
-- ============================================================================

local function Entry(name, value)
    return {
        name = name,
        value = value,
    }
end


-- ============================================================================
-- Construction
-- ============================================================================

function TestQueue_New()
    TK.printSuite(mn, "Queue_New")
    local q = Queue:New()

    TK.assertNotNil(q, "Queue created")
    TK.assertTrue(q:IsEmpty(), "New queue is empty")
    TK.assertEquals(0, q:Count(), "New queue count is zero")
end


-- ============================================================================
-- Enqueue
-- ============================================================================

function TestQueue_Enqueue()
    TK.printSuite(mn, "Queue_Enqueue")
    local q = Queue:New()
    local entry = Entry("first", 10)

    local result = q:Enqueue("one", entry)

    TK.assertTrue(result, "Enqueue succeeds")
    TK.assertFalse(q:IsEmpty(), "Queue is not empty")
    TK.assertEquals(1, q:Count(), "Queue count is one")
    TK.assertTrue(q:Has("one"), "Queue has ID")
    TK.assertEquals(entry, q:Get("one"), "Get returns entry")
end


function TestQueue_EnqueueFIFO()
    TK.printSuite(mn, "Queue_EnqueueFIFO")
    local q = Queue:New()

    local a = Entry("a", 1)
    local b = Entry("b", 2)
    local c = Entry("c", 3)

    q:Enqueue("a", a)
    q:Enqueue("b", b)
    q:Enqueue("c", c)

    local id, value = q:Dequeue()

    TK.assertEquals("a", id, "First dequeue returns first ID")
    TK.assertEquals(a, value, "First dequeue returns first value")

    id, value = q:Dequeue()

    TK.assertEquals("b", id, "Second dequeue returns second ID")
    TK.assertEquals(b, value, "Second dequeue returns second value")

    id, value = q:Dequeue()

    TK.assertEquals("c", id, "Third dequeue returns third ID")
    TK.assertEquals(c, value, "Third dequeue returns third value")

    TK.assertTrue(q:IsEmpty(), "Queue is empty")
    TK.assertEquals(0, q:Count(), "Queue count is zero")
end


function TestQueue_EnqueueDuplicateID()
    TK.printSuite(mn, "Queue_EnqueueDuplicateID")
    local q = Queue:New()

    local first = Entry("first", 1)
    local second = Entry("second", 2)

    TK.assertTrue(
        q:Enqueue("same", first),
        "First enqueue succeeds"
    )

    TK.assertFalse(
        q:Enqueue("same", second),
        "Duplicate enqueue fails"
    )

    TK.assertEquals(1, q:Count(), "Duplicate does not increase count")
    TK.assertEquals(
        first,
        q:Get("same"),
        "Original value is preserved"
    )
end


function TestQueue_EnqueueNilID()
    TK.printSuite(mn, "Queue_EnqueueNilID")
    local q = Queue:New()
    local entry = Entry("test", 1)

    TK.assertFalse(
        q:Enqueue(nil, entry),
        "Nil ID is rejected"
    )

    TK.assertTrue(q:IsEmpty(), "Queue remains empty")
    TK.assertEquals(0, q:Count(), "Queue count remains zero")
end


function TestQueue_EnqueueNilValue()
    TK.printSuite(mn, "Queue_EnqueueNilValue")
    local q = Queue:New()

    TK.assertFalse(
        q:Enqueue("id", nil),
        "Nil value is rejected"
    )

    TK.assertTrue(q:IsEmpty(), "Queue remains empty")
    TK.assertEquals(0, q:Count(), "Queue count remains zero")
end


-- ============================================================================
-- Get
-- ============================================================================

function TestQueue_Get()
    TK.printSuite(mn, "Queue_Get")
    local q = Queue:New()
    local entry = Entry("test", 42)

    q:Enqueue("id", entry)

    local result = q:Get("id")

    TK.assertEquals(entry, result, "Get returns entry")
    TK.assertEquals(1, q:Count(), "Get does not change count")
    TK.assertTrue(q:Has("id"), "Get does not remove entry")
end


function TestQueue_GetMissing()
    TK.printSuite(mn, "Queue_GetMissing")
    local q = Queue:New()

    TK.assertNil(
        q:Get("missing"),
        "Get missing ID returns nil"
    )
end


-- ============================================================================
-- Has
-- ============================================================================

function TestQueue_Has()
    TK.printSuite(mn, "Queue_Has")
    local q = Queue:New()

    q:Enqueue("id", Entry("test", 1))

    TK.assertTrue(q:Has("id"), "Has finds existing ID")
    TK.assertFalse(q:Has("missing"), "Has rejects missing ID")
end


-- ============================================================================
-- Peek
-- ============================================================================

function TestQueue_Peek()
    TK.printSuite(mn, "Queue_Peek")
    local q = Queue:New()

    local a = Entry("a", 1)
    local b = Entry("b", 2)

    q:Enqueue("a", a)
    q:Enqueue("b", b)

    local id, value = q:Peek()

    TK.assertEquals("a", id, "Peek returns first ID")
    TK.assertEquals(a, value, "Peek returns first value")
    TK.assertEquals(2, q:Count(), "Peek does not change count")

    id, value = q:Peek()

    TK.assertEquals("a", id, "Second Peek returns same ID")
    TK.assertEquals(a, value, "Second Peek returns same value")
end


function TestQueue_PeekEmpty()
    TK.printSuite(mn, "Queue_PeekEmpty")
    local q = Queue:New()

    local id, value = q:Peek()

    TK.assertNil(id, "Empty Peek returns nil ID")
    TK.assertNil(value, "Empty Peek returns nil value")
end


-- ============================================================================
-- Dequeue
-- ============================================================================

function TestQueue_Dequeue()
    TK.printSuite(mn, "Queue_Dequeue")
    local q = Queue:New()

    local a = Entry("a", 1)
    local b = Entry("b", 2)

    q:Enqueue("a", a)
    q:Enqueue("b", b)

    local id, value = q:Dequeue()

    TK.assertEquals("a", id, "Dequeue returns first ID")
    TK.assertEquals(a, value, "Dequeue returns first value")
    TK.assertEquals(1, q:Count(), "Dequeue decrements count")
    TK.assertFalse(q:Has("a"), "Dequeue removes first entry")
    TK.assertTrue(q:Has("b"), "Dequeue preserves remaining entry")
end


function TestQueue_DequeueEmpty()
    TK.printSuite(mn, "Queue_DequeueEmpty")
    local q = Queue:New()

    local id, value = q:Dequeue()

    TK.assertNil(id, "Empty Dequeue returns nil ID")
    TK.assertNil(value, "Empty Dequeue returns nil value")
    TK.assertTrue(q:IsEmpty(), "Queue remains empty")
end


function TestQueue_DequeueLast()
    TK.printSuite(mn, "Queue_DequeueLast")
    local q = Queue:New()
    local entry = Entry("only", 1)

    q:Enqueue("only", entry)

    local id, value = q:Dequeue()

    TK.assertEquals("only", id, "Dequeue returns only ID")
    TK.assertEquals(entry, value, "Dequeue returns only value")
    TK.assertTrue(q:IsEmpty(), "Queue becomes empty")
    TK.assertEquals(0, q:Count(), "Queue count becomes zero")

    id, value = q:Peek()

    TK.assertNil(id, "Peek after final Dequeue returns nil ID")
    TK.assertNil(value, "Peek after final Dequeue returns nil value")
end


-- ============================================================================
-- Remove
-- ============================================================================

function TestQueue_Remove()
    TK.printSuite(mn, "Queue_Remove")
    local q = Queue:New()
    local entry = Entry("test", 42)

    q:Enqueue("id", entry)

    local result = q:Remove("id")

    TK.assertEquals(entry, result, "Remove returns entry")
    TK.assertFalse(q:Has("id"), "Remove removes entry")
    TK.assertNil(q:Get("id"), "Removed entry cannot be retrieved")
    TK.assertTrue(q:IsEmpty(), "Queue becomes empty")
    TK.assertEquals(0, q:Count(), "Queue count becomes zero")
end


function TestQueue_RemoveMissing()
    TK.printSuite(mn, "Queue_RemoveMissing")
    local q = Queue:New()

    TK.assertNil(
        q:Remove("missing"),
        "Remove missing ID returns nil"
    )

    TK.assertTrue(q:IsEmpty(), "Queue remains empty")
end


function TestQueue_RemoveFirst()
     TK.printSuite(mn, "Queue_RemoveFirst")
   local q = Queue:New()

    local a = Entry("a", 1)
    local b = Entry("b", 2)
    local c = Entry("c", 3)

    q:Enqueue("a", a)
    q:Enqueue("b", b)
    q:Enqueue("c", c)

    TK.assertEquals(
        a,
        q:Remove("a"),
        "Remove first returns A"
    )

    local id, value = q:Dequeue()

    TK.assertEquals("b", id, "B becomes first")
    TK.assertEquals(b, value, "B is returned")

    id, value = q:Dequeue()

    TK.assertEquals("c", id, "C becomes second")
    TK.assertEquals(c, value, "C is returned")
end


function TestQueue_RemoveMiddle()
    TK.printSuite(mn, "Queue_RemoveMiddle")

    local q = Queue:New()

    local a = Entry("a", 1)
    local b = Entry("b", 2)
    local c = Entry("c", 3)

    q:Enqueue("a", a)
    q:Enqueue("b", b)
    q:Enqueue("c", c)

    TK.assertEquals(
        b,
        q:Remove("b"),
        "Remove middle returns B"
    )

    local id, value = q:Dequeue()

    TK.assertEquals("a", id, "A remains first")
    TK.assertEquals(a, value, "A is returned")

    id, value = q:Dequeue()

    TK.assertEquals("c", id, "C follows A")
    TK.assertEquals(c, value, "C is returned")
end


function TestQueue_RemoveLast()
    TK.printSuite(mn, "Queue_RemoveLast")
    local q = Queue:New()

    local a = Entry("a", 1)
    local b = Entry("b", 2)
    local c = Entry("c", 3)

    q:Enqueue("a", a)
    q:Enqueue("b", b)
    q:Enqueue("c", c)

    TK.assertEquals(
        c,
        q:Remove("c"),
        "Remove last returns C"
    )

    local id, value = q:Dequeue()

    TK.assertEquals("a", id, "A remains first")
    TK.assertEquals(a, value, "A is returned")

    id, value = q:Dequeue()

    TK.assertEquals("b", id, "B remains second")
    TK.assertEquals(b, value, "B is returned")
end


function TestQueue_RemoveOnly()
    TK.printSuite(mn, "Queue_RemoveOnly")
    local q = Queue:New()
    local entry = Entry("only", 1)

    q:Enqueue("only", entry)

    TK.assertEquals(
        entry,
        q:Remove("only"),
        "Remove only entry returns entry"
    )

    TK.assertTrue(q:IsEmpty(), "Queue is empty")
    TK.assertEquals(0, q:Count(), "Queue count is zero")
    TK.assertNil(q:Peek(), "Peek returns nil")
end


-- ============================================================================
-- Remove / Re-enqueue
-- ============================================================================

function TestQueue_RemoveReenqueue()
    TK.printSuite(mn, "Queue_RemoveReenqueue")
    local q = Queue:New()

    local first = Entry("first", 1)
    local second = Entry("second", 2)

    q:Enqueue("id", first)

    TK.assertEquals(
        first,
        q:Remove("id"),
        "Remove returns original entry"
    )

    TK.assertTrue(
        q:Enqueue("id", second),
        "Removed ID can be re-enqueued"
    )

    TK.assertEquals(
        second,
        q:Get("id"),
        "New entry is stored"
    )

    local id, value = q:Dequeue()

    TK.assertEquals("id", id, "Re-enqueued ID is dequeued")
    TK.assertEquals(second, value, "Re-enqueued value is dequeued")
end


function TestQueue_ReenqueueGoesToBack()
    TK.printSuite(mn, "Queue_ReenqueueGoesToBack")
    local q = Queue:New()

    local a = Entry("a", 1)
    local b = Entry("b", 2)
    local a2 = Entry("a2", 3)

    q:Enqueue("a", a)
    q:Enqueue("b", b)

    q:Remove("a")
    q:Enqueue("a", a2)

    local id, value = q:Dequeue()

    TK.assertEquals(
        "b",
        id,
        "B remains ahead of re-enqueued A"
    )

    TK.assertEquals(
        b,
        value,
        "B remains first"
    )

    id, value = q:Dequeue()

    TK.assertEquals(
        "a",
        id,
        "Re-enqueued A is last"
    )

    TK.assertEquals(
        a2,
        value,
        "Re-enqueued A has new value"
    )
end


-- ============================================================================
-- Count / IsEmpty
-- ============================================================================

function TestQueue_Count()
    TK.printSuite(mn, "Queue_Count")
    local q = Queue:New()

    TK.assertEquals(0, q:Count(), "Initial count is zero")

    q:Enqueue("a", Entry("a", 1))
    TK.assertEquals(1, q:Count(), "Count after enqueue")

    q:Enqueue("b", Entry("b", 2))
    TK.assertEquals(2, q:Count(), "Count after second enqueue")

    q:Dequeue()
    TK.assertEquals(1, q:Count(), "Count after dequeue")

    q:Remove("b")
    TK.assertEquals(0, q:Count(), "Count after Remove")
end


-- ============================================================================
-- Table values
-- ============================================================================

function TestQueue_TableIdentity()
    TK.printSuite(mn, "Queue_TableIdentity")
    local q = Queue:New()

    local entry = {
        name = "test",
        nested = {
            value = 123,
        },
    }

    q:Enqueue("id", entry)

    local result = q:Get("id")

    TK.assertEquals(
        entry,
        result,
        "Get returns same table"
    )

    TK.assertEquals(
        entry.nested,
        result.nested,
        "Nested table is same reference"
    )

    TK.assertEquals(
        123,
        result.nested.value,
        "Nested value is preserved"
    )
end


function TestQueue_TableReference()
    TK.printSuite(mn, "Queue_TableReference")
    local q = Queue:New()

    local entry = {
        value = 10,
    }

    q:Enqueue("id", entry)

    entry.value = 20

    TK.assertEquals(
        20,
        q:Get("id").value,
        "Queue stores table by reference"
    )
end


-- ============================================================================
-- Clear
-- ============================================================================

function TestQueue_Clear()
    TK.printSuite(mn, "Queue_Clear")
    local q = Queue:New()

    q:Enqueue("a", Entry("a", 1))
    q:Enqueue("b", Entry("b", 2))
    q:Enqueue("c", Entry("c", 3))

    q:Clear()

    TK.assertTrue(q:IsEmpty(), "Queue is empty after Clear")
    TK.assertEquals(0, q:Count(), "Count is zero after Clear")
    TK.assertFalse(q:Has("a"), "A removed by Clear")
    TK.assertFalse(q:Has("b"), "B removed by Clear")
    TK.assertFalse(q:Has("c"), "C removed by Clear")

    local id, value = q:Dequeue()

    TK.assertNil(id, "Dequeue after Clear returns nil ID")
    TK.assertNil(value, "Dequeue after Clear returns nil value")
end


function TestQueue_ReuseAfterClear()
    TK.printSuite(mn, "Queue_ReuseAfterClear")
    local q = Queue:New()

    q:Enqueue("old", Entry("old", 1))
    q:Clear()

    local entry = Entry("new", 2)

    TK.assertTrue(
        q:Enqueue("new", entry),
        "Enqueue after Clear succeeds"
    )

    local id, value = q:Dequeue()

    TK.assertEquals("new", id, "New ID is dequeued")
    TK.assertEquals(entry, value, "New value is dequeued")
    TK.assertTrue(q:IsEmpty(), "Queue is empty")
end

--------------------------------------------------------------------------------
-- RUN ALL TESTS
--------------------------------------------------------------------------------
-- Run all Queue test suites
function Test_Queue_All()
    TestQueue_New()
    TestQueue_Enqueue()
    TestQueue_EnqueueFIFO()
    TestQueue_EnqueueNilID()
    TestQueue_EnqueueNilValue()

    TestQueue_Dequeue()
    TestQueue_DequeueEmpty()
    TestQueue_DequeueLast()

    TestQueue_Clear()
    TestQueue_Count()
    TestQueue_Get()
    TestQueue_GetMissing()
    TestQueue_Has()
    TestQueue_Peek()
    TestQueue_PeekEmpty()
    TestQueue_ReenqueueGoesToBack()
    
    TestQueue_Remove()
    TestQueue_RemoveFirst()
    TestQueue_RemoveLast()
    TestQueue_RemoveMiddle()
    TestQueue_RemoveMissing()
    TestQueue_RemoveOnly()
    TestQueue_RemoveReenqueue()
    TestQueue_ReuseAfterClear()
    
    TestQueue_TableIdentity()
    TestQueue_TableReference()
end


if not Suite then
    TK.init()
    
    Test_Queue_All()
    
    TK.showResult("Queue Unit Tests")
end