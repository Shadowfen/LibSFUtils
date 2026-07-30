# TimedQueue Documentation

## Overview

**TimedQueue** is a specialized data structure that maintains a fixed-size history of entries, each tagged with a timestamp from `GetGameTimeMilliseconds()`. It implements a circular buffer algorithm, allowing for constant-time insertion and efficient memory usage in Elder Scrolls Online (ESO) addons.

### Key Features

| Feature | Benefit |
|---------|---------|
| **Timestamped Entries** | Every item is automatically paired with game time on insertion |
| **Circular Buffer** | Prevents memory leaks by reusing array slots; no element shifting required |
| **Dynamic Resizing** | Adjust the active limit at runtime without recreating the queue |
| **Advanced Removal** | Remove by reference, payload value, or custom predicate |
| **Order Preservation** | `list()` returns entries sorted from newest to oldest |

### Technical Characteristics

| Aspect | Implementation |
|--------|----------------|
| **Insertion Complexity** | O(1) - Constant time |
| **Removal Complexity** | O(N) - Requires rebuilding the buffer |
| **Memory Usage** | Fixed-size allocation based on `_maxPossible` |
| **Thread Safety** | Not required (Lua is single-threaded in ESO) |
| **Overflow Handling** | Oldest entries are automatically overwritten |

### Dependencies

- Requires [LibSFUtils](./README.md) (accessed via global `LibSFUtils` or `SF`)
- Requires ESO API: `GetGameTimeMilliseconds()` and `ZO_ClearTable()`

---

## Installationlua
```lua
-- Access the module through LibSFUtils
local sfutil = LibSFUtils
local TimedQueue = sfutil.TimedQueue
-- Or directly if already in global scope
local TimedQueue = LibSFUtils.TimedQueue

Quick Start-- Create a queue with 10 entries, can grow to 50 max
local myQueue = TimedQueue:New(10, 50)

-- Add entries
myQueue:push("Action 1")
myQueue:push("Action 2")
myQueue:push("Action 3")

-- View entries (newest first)
for _, entry in ipairs(myQueue:list()) do
    zo_dlog(string.format("[%d ms] %s", entry.ts, entry.payload))
end

-- Check size
zo_dlog("Queue size:", myQueue:size())  -- 3

-- Get current max
zo_dlog("Max capacity:", myQueue:getMax())  -- 10

-- Remove oldest entry
local oldest = myQueue:popOldest()

-- Clear everything
myQueue:clear()
```
###Constructor
Creating a New Instance
```lua
local queue = TimedQueue:New(initialMax, maxPossible)
```
Parameter|Type|Default|Description
--|--|--|--
initialMax|number|required|Starting maximum number of entries. Must be ≥ 1
maxPossible|number|initial|Max|Absolute hard ceiling for queue size. Must be ≥ initialMax

Returns: 
```lua
New TimedQueue instance with internal state:{
    _maxPossible = 50,    -- absolute ceiling
    _max = 10,            -- current active limit
    _head = 1,            -- points to oldest element
    _tail = 0,            -- points to newest element
    _count = 0,           -- number of stored entries
    _data = {}            -- raw circular buffer array
}
```
Example:
```lua
-- Queue with 10 entries, can expand to 50
local combatLog = TimedQueue:New(10, 50)

-- Queue with same initial and max (fixed size)
local inventoryHistory = TimedQueue:New(20)  -- maxPossible defaults to 20
Validation:-- Will throw assertion error
TimedQueue:New(-5, 10)  -- Error: initialMax must be positive
TimedQueue:New(10, 5)   -- Error: maxPossible must be ≥ initialMax
```
### Queue Management Methods
Set Active Maximum
queue:setMax(newMax)|Dynamically adjusts the active size limit of the queue.

Parameter|Type|Description
--|--|--
newMax|number|The new active limit (clamped between 1 and _maxPossible)

Behavior:
* Clamps newMax between 1 and _maxPossible
* Shrinking: If newMax < current count, oldest entries are immediately discarded until count matches newMax
* Growing: If newMax > current count, queue allows more entries before overwriting begins

Example:
```lua
local queue = TimedQueue:New(10, 50)
queue:push("item 1")
queue:push("item 2")

-- Expand the queue
queue:setMax(25)  -- Now can hold up to 25 entries

-- Shrink beyond current count (discards oldest)
queue.push("a"); queue.push("b"); queue.push("c"); queue.push("d")  -- Now has 6 entries
queue:setMax(3)  -- Immediately discards 3 oldest entries
```
Get Current Maximum
`local limit = queue:getMax()`
Returns the current active limit (not necessarily the hard ceiling _maxPossible).
Returns: Number representing the current active maximum.
Example:
```lua
local queue = TimedQueue:New(10, 50)
d(queue:getMax())  -- 10

queue:setMax(25)
d(queue:getMax())  -- 25

-- _maxPossible remains unchanged
d(queue._maxPossible)  -- 50
```
Push Entry
`queue:push(payload)` Adds a new entry to the queue.

Parameter|Type|Description
--|--|--
payload|any|The data to store (anything: string, number, table, etc.)

Behavior:
* Creates an entry table: { ts = GetGameTimeMilliseconds(), payload = payload }
* Places the entry at the tail (newest position)
* Overflow: If queue is at active limit (_max), oldest entry (at head) is overwritten and head pointer advances
* Complexity: O(1) - Constant time insertion

Example:
```lua
local queue = TimedQueue:New(5, 10)

-- Add entries
queue:push("Ability Cast")
queue:push({action = "Damage", value = 150})
queue:push(SI_CHAT_MESSAGE_SENT)  -- String ID

-- Check latest
local newest = queue:peek()
d(newest.payload)  -- SI_CHAT_MESSAGE_SENT
d(newest.ts)       -- Timestamp in milliseconds
```
Peek Latest Entry
```lua
local entry = queue:peek()
```
Returns the newest entry table { ts, payload } without removing it.
Returns: Entry table or nil if empty.
Example:
```lua
local queue = TimedQueue:New(10, 50)
queue:push("First")
queue:push("Second")
queue:push("Third")

local latest = queue:peek()
d(latest.payload)  -- "Third"
d(latest.ts)       -- Timestamp

-- Queue still has 3 entries
d(queue:size())  -- 3
```
List All Entries
`local entries = queue:list()`   Returns a snapshot of all entries as a standard Lua array.
Returns: Table of entry tables.
Order: Sorted newest → oldest (descending timestamp).
Important: Returns a copy (snapshot), not a live reference to the internal buffer. Modifications to this table won't affect the queue.
Example:
```lua
local queue = TimedQueue:New(5, 10)
queue:push("A")
queue:push("B")
queue:push("C")

local entries = queue:list()

-- Iterate newest to oldest
for i, entry in ipairs(entries) do
    zo_dlog(i, entry.ts, entry.payload)
end
-- Output:
-- 1  1234567890  C  (newest)
-- 2  1234567880  B
-- 3  1234567870  A  (oldest)

-- Modify the returned table doesn't affect queue
entries[1] = nil
d(queue:size())  -- Still 3
```
Get Size
`local count = queue:size()`  Returns the current number of entries in the queue.
Returns: Number representing the count.
Complexity: O(1) - Direct property access
Example:
```lua
local queue = TimedQueue:New(10, 50)

d(queue:size())   -- 0 (empty)
queue:push("a")
d(queue:size())   -- 1
queue:push("b")
d(queue:size())   -- 2
```
Clear Queue
`queue:clear()`   Empties the queue completely.
Behavior:
* Resets all pointers (_head = 1, _tail = 0, _count = 0)
* Clears the internal _data table using ZO_ClearTable()
* Preserves _max and _maxPossible settings

Example:
```lua
local queue = TimedQueue:New(10, 50)
queue:push("a")
queue:push("b")
queue:push("c")

d(queue:size())  -- 3

queue:clear()
d(queue:size())  -- 0
d(queue:getMax())  -- Still 10 (capacity preserved)
```
## Removal Methods

⚠️ Note: All removal operations involve rebuilding the internal buffer, which is O(N) (linear complexity). For high-frequency removals, consider using popOldest()/popNewest() instead.

###Remove by Reference
`local success = queue:remove(entry)`  Removes a specific entry by table reference.

Parameter|Type|Description
--|--|--
entry|table|The exact table object returned by push() or list()

Returns: true if removed, false if not found.
Complexity: O(N) - Requires linear search and buffer rebuild
Example:
```lua
local queue = TimedQueue:New(10, 50)
queue:push("item1")
queue:push("item2")
queue:push("item3")

-- Get specific entry to remove
local toRemove = queue:list()[2]  -- Second newest (middle entry)
local found = queue:remove(toRemove)

d(found)  -- true
d(queue:size())  -- 2
```
Remove by Payload Value
`local success = queue:removeByPayload(payload)`  Removes the first entry whose payload matches the given value.

Parameter|Type|Description
--|--|--
payload|any|The value to match against entry.payload

Returns: true if removed, false if not found.
Behavior: Matches only the first occurrence (newest first). If multiple entries have the same payload, only the newest is removed.
Complexity: O(N)
Example:
```lua
local queue = TimedQueue:New(10, 50)
queue:push("error")
queue:push("success")
queue:push("error")  -- Duplicate payload

-- Remove the newest "error" entry
local removed = queue:removeByPayload("error")
d(removed)  -- true

-- Queue now has: ["success", "error"] (second one kept)
d(queue:size())  -- 2
```
Remove by Predicate Function
`local success = queue:removeIf(predicate)`  Removes the first entry that satisfies a custom condition.

Parameter|Type|Description
predicate|function|func(entry) that returns true to delete

Entry Structure Passed to Predicate:
```lua
{
    ts = number,        -- Timestamp in milliseconds
    payload = any       -- The stored payload
}
```
Returns: true if removed, false if no entry matched.
Complexity: O(N)
Example:
```lua
local queue = TimedQueue:New(10, 50)
queue:push("ability_cast")
queue:push("damage_taken")
queue:push("ability_cast")
queue:push("movement")

-- Remove the first ability_cast entry
local removed = queue:removeIf(function(entry)
    return entry.payload == "ability_cast"
end)

d(removed)  -- true
d(queue:size())  -- 3

-- Remove all entries older than 5 seconds
local currentTime = GetGameTimeMilliseconds()
local fiveSeconds = 5000

while queue:removeIf(function(entry)
    return (currentTime - entry.ts) > fiveSeconds
end) do
    -- Keep removing old entries until none match
end
```
Pop Oldest Entry
`local entry = queue:popOldest()`  Discards and returns the oldest entry (FIFO - First In, First Out).
Returns: Entry table { ts, payload } or nil if empty.
Complexity: O(1) - Fast pointer adjustment (doesn't require rebuild)
Use Case: Standard queue processing, consuming history logs.
Example:
```lua
local queue = TimedQueue:New(5, 10)
queue:push("first")
queue:push("second")
queue:push("third")

-- Process in order (oldest first)
while queue:size() > 0 do
    local entry = queue:popOldest()
    zo_dlog("Processing:", entry.payload, entry.ts)
    -- Handle the entry...
end

d(queue:size())  -- 0 (queue exhausted)
```
Pop Newest Entry
`local entry = queue:popNewest()`  Discards and returns the newest entry (LIFO - Last In, First Out).
Returns: Entry table { ts, payload } or nil if empty.
Complexity: O(1) - Fast pointer adjustment
Use Case: Undo stacks, reverting the last action, LIFO processing.
Example:
```lua
local undoStack = TimedQueue:New(10, 50)

-- Record actions
undoStack:push({type = "move", x = 100, y = 200})
undoStack:push({type = "cast", spellId = 12345})
undoStack:push({type = "attack", target = "enemy1"})

-- Undo the most recent action
local undone = undoStack:popNewest()
d(undone.payload.type)  -- "attack"

-- Continue undoing
local nextUndo = undoStack:popNewest()
d(nextUndo.payload.type)  -- "cast"
```
## Complete Usage Examples
### Combat Log History
```lua
-- ============================================================
-- Combat Action Logging with TimedQueue
-- ============================================================

local combatLog = TimedQueue:New(50, 200)  -- Keep 50 actions, can expand to 200

-- Hook into combat events
local function OnCombatEvent(eventCode, ...)
    local action = parseCombatData(...)
    
    -- Log action with timestamp
    combatLog:push(action)
    
    -- Optional: Clean old entries periodically
    if combatLog:size() >= combatLog:getMax() * 0.9 then
        -- Trigger cleanup if near capacity
        trimOldCombatLogs(10000)  -- Remove entries older than 10 seconds
    end
end

-- Clean up old entries
local function trimOldCombatLogs(ageMs)
    local currentTime = GetGameTimeMilliseconds()
    
    while combatLog:removeIf(function(entry)
        return (currentTime - entry.ts) > ageMs
    end) do
        -- Keep removing old entries
    end
end

-- Analyze combat frequency in last 5 seconds
local function getLast5SecondsStats()
    local currentTime = GetGameTimeMilliseconds()
    local cutoff = currentTime - 5000
    
    local actions = {}
    for _, entry in ipairs(combatLog:list()) do
        if entry.ts >= cutoff then
            actions[entry.payload.actionType] = (actions[entry.payload.actionType] or 0) + 1
        end
    end
    return actions
end
```
### Input History Buffer
```lua
-- ============================================================
-- Player Input Tracking with Time-Aware Filtering
-- ============================================================

local inputHistory = TimedQueue:New(20, 100)

-- Record player actions
local function OnPlayerAction(actionType, metadata)
    inputHistory:push({
        type = actionType,
        data = metadata,
        sessionId = GetCurrentSessionId()
    })
end

-- Find duplicate rapid-fire inputs (potential spam detection)
local function detectSpam(windowMs, threshold)
    local currentTime = GetGameTimeMilliseconds()
    local windowStart = currentTime - windowMs
    
    local counts = {}
    for _, entry in ipairs(inputHistory:list()) do
        if entry.ts >= windowStart then
            counts[entry.payload.type] = (counts[entry.payload.type] or 0) + 1
        end
    end
    
    for actionType, count in pairs(counts) do
        if count >= threshold then
            zo_warn(string.format("SPAM DETECTED: %s (%d times in %dms)", 
                                  actionType, count, windowMs))
            return true
        end
    end
    return false
end

-- Remove corrupted entries (predicate-based cleanup)
local function cleanCorruptedEntries()
    inputHistory:removeIf(function(entry)
        return entry.payload.data == nil or entry.payload.type == "corrupt"
    end)
end
```
## Session Replay Buffer
```lua
-- ============================================================
-- Replay System with Undo/Redo Support
-- ============================================================

local replayBuffer = TimedQueue:New(30, 100)

-- Record state change
local function recordStateChange(state)
    replayBuffer:push({
        state = DeepCopy(state),
        ts = GetGameTimeMilliseconds(),
        userId = GetAccountId()
    })
end

-- Undo last N changes
local function undoSteps(n)
    for i = 1, n do
        local entry = replayBuffer:popNewest()
        if entry then
            restoreState(entry.payload.state)
        else
            break  -- No more entries to undo
        end
    end
end

-- Redo (would require separate forward buffer in practice)
-- For now, just keep track of what was undone

-- Export replay data
local function exportReplay()
    local entries = replayBuffer:list()
    local exportData = {
        startTime = entries[#entries].ts,  -- Oldest
        endTime = entries[1].ts,           -- Newest (list is newest→oldest)
        entries = entries
    }
    
    ZO_SaveToDisk(GetSavePath() .. "replay.json", exportData)
end
```
## Performance Considerations
### Time Complexity Summary
Operation|Complexity|Notes
--|--|--
push()|O(1)|Constant time circular buffer insertion
peek()|O(1)|Direct access to tail
list()|O(N)|Must iterate all entries
size()|O(1)|Property access
setMax()|O(excess)|Only if shrinking beyond current count
popOldest()|O(1)|Head pointer adjustment
popNewest()|O(1)|Tail pointer adjustment
remove()|O(N)|Search + buffer rebuild
removeByPayload()|O(N)|Search + buffer rebuild
removeIf()|O(N)|Search + buffer rebuild
clear()|O(N)|Clears _data table

### Memory Usage

Fixed Allocation: Internal _data table is pre-sized to _maxPossible
Entry Overhead: Each entry adds a small table { ts = number, payload = any }
No Garbage Spike: Circular buffer reuses slots, minimizing GC pressure during normal operation

Example:
```lua
-- Queue configured with 100 max possible entries
local queue = TimedQueue:New(50, 100)

-- Internal buffer pre-allocated to 100 slots
-- Actual entries tracked via _count
-- No reallocation needed when growing from 50 to 80 entries
```
## Best Practices
✅ Do:
* Use popOldest()/popNewest() for high-frequency removals (O(1) vs O(N))
* Set reasonable _maxPossible limits to prevent excessive memory usage
* Use removeIf() sparingly in performance-critical paths
* Monitor size() regularly to prevent overflow

❌ Don't:
* Call remove*() methods in tight loops (use pop instead)
* Set _maxPossible excessively high without justification
* Assume list() is cheap (it copies all entries)
* Modify entries returned by list() expecting changes to persist


## Edge Cases & Limitations
### Empty Queue Handling
```lua
local queue = TimedQueue:New(10, 50)

-- Safe operations on empty queue
local entry = queue:peek()     -- nil (safe)
local list = queue:list()      -- [] (empty table, safe)
local success = queue:remove(anyEntry)  -- false (not found)
local popped = queue:popOldest()  -- nil (empty)

-- All gracefully return nil/false/[]
Payload Type Flexibilitylocal queue = TimedQueue:New(10, 50)

-- Any type works as payload
queue:push("string")
queue:push(12345)
queue:push({complex = "table"})
queue:push(function() return true end)  -- Functions allowed (but not recommended)
queue:push(nil)  -- nil payloads work too

-- Access safely
for _, entry in ipairs(queue:list()) do
    d(entry.payload)  -- Works for all types
end
```

### Circular Buffer Wraparound
```lua
local queue = TimedQueue:New(3, 5)

-- Fill to capacity
queue:push("A"); queue:push("B"); queue:push("C")
d(queue:size())  -- 3
d(queue:getMax())  -- 3

-- Add more (wraps around, overwrites oldest)
queue:push("D")
queue:push("E")

-- Now contains: D, E (A, B, C were overwritten)
local list = queue:list()
-- Newest→Oldest: E, D
d(queue:size())  -- 3 (limited by _max)
Timestamp Granularity-- GetGameTimeMilliseconds() resolution
local queue = TimedQueue:New(10, 50)

local before = GetGameTimeMilliseconds()
queue:push("rapid")
local after = GetGameTimeMilliseconds()

d(after - before)  -- Typically 0-1ms (millisecond precision)

-- Note: Very rapid pushes may have identical timestamps
-- Use additional sequencing if ordering within same ms matters
```

## API Reference Summary
### Constructor
Method|Signature|Returns
--|--|--
New()|TimedQueue:New(initialMax, maxPossible)|New queue instance

### Queue Operations
Method|Signature|Returns|Complexity
--|--|--|--
push()|queue:push(payload)|void|O(1)
peek()|queue:peek()|entry or nil|O(1)
list()|queue:list()|Table of entries|O(N)
size()|queue:size()|Number|O(1)
clear()|queue:clear()|void|O(N)

### Capacity Management
Method|Signature|Returns|Complexity
--|--|--|--
setMax()|queue:setMax(newMax)|void|O(excess)
getMax()|queue:getMax()|Number|O(1)

### Removal Operations
Method|Signature|Returns|Complexity
--|--|--|--
remove()|queue:remove(entry)|boolean|O(N)
removeByPayload()|queue:removeByPayload(payload)|boolean|O(N)
removeIf()|queue:removeIf(predicate)|boolean|O(N)
popOldest()|queue:popOldest()|entry or nil|O(1)
popNewest()|queue:popNewest()|entry or nil|O(1)

## Entry Structure Reference
All entries in the queue follow this structure:
```lua
{
    ts = number,      -- Timestamp from GetGameTimeMilliseconds()
    payload = any     -- Your stored data (any Lua type)
}
```
### Access Example:
```lua
for _, entry in ipairs(queue:list()) do
    -- Access timestamp
    local gameTime = entry.ts
    
    -- Access your payload
    local data = entry.payload
    
    -- Example: conditional processing
    if typeof(data) == "table" then
        -- Handle complex objects
    elseif typeof(data) == "string" then
        -- Handle strings
    end
end
```
##Related Resources

Full LibSFUtils Documentation - Complete library reference
SFUtils_Events Module - Event management for queue callbacks
SFUtils_Tables Module - Table utilities for payload data
ESO API Reference - Official ESO addon documentation
TimedQueue Source - Raw implementation
