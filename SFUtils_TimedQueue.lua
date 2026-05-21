--[[
    TimedQueue is a specialized data structure that maintains a fixed-size history of entries, 
    each tagged with a timestamp (GetGameTimeMilliseconds()). It implements a circular buffer 
    algorithm, allowing for constant-time insertion and efficient memory usage. When the queue 
    reaches its capacity, the oldest entry is automatically overwritten by the newest.

    Key Features:
        Timestamped Entries: Every item pushed is automatically paired with the current game time.
        Circular Buffer: Prevents memory leaks by reusing array slots; no shifting of elements required on push.
        Dynamic Resizing: Adjust the active limit (setMax) at runtime without recreating the queue.
        Advanced Removal: Supports removal by reference, payload value, or custom predicate.
        Order Preservation: list() returns entries sorted from newest to oldest.

    Dependencies: Requires LibSFUtils (for ZO_ClearTable) and the ESO API function GetGameTimeMilliseconds.

    Technical Implementation Details

    Circular Buffer: Uses _head and _tail indices wrapping around _maxPossible. This ensures O(1) insertion.
    Entry Structure: Every stored item is a table { ts = number, payload = any }.
    Rebuilding: Removal methods (remove, removeByPayload, removeIf) convert the circular buffer to a linear 
            array, perform the removal, and rebuild the buffer. This is O(N) but necessary to maintain the 
            circular structure integrity after arbitrary deletions.
    Thread Safety: Not explicitly thread-safe (Lua is single-threaded in ESO, so this is not an issue).
--]]

-- LibSFUtils is already defined in prior loaded file
LibSFUtils = LibSFUtils or {}
local sfutil = LibSFUtils

--[[=====================================================================
    TimedQueue – Fixed‑size FIFO with timestamps.
    Includes features:
      • Dynamic resizing (setMax / getMax)
      • Removal of entries:
          – remove(entry)               – exact table reference
          – removeByPayload(payload)    – first entry whose payload matches
          – removeIf(predicate)         – first entry satisfying a predicate
          – popOldest() / popNewest()  – discard the oldest / newest entry
=====================================================================]]--

local TimedQueue = {}
TimedQueue.__index = TimedQueue

sfutil.TimedQueue = TimedQueue

--- Helper: circular increment (1‑based)
local function inc(idx, limit)
    idx = idx + 1
    if idx > limit then idx = 1 end
    return idx
end

--- Helper: circular decrement (1‑based)
local function dec(idx, limit)
    idx = idx - 1
    if idx < 1 then idx = limit end
    return idx
end

--[[
    TimedQueue:New(initialMax, maxPossible)

    Creates a new TimedQueue instance.

        Parameters:
            initialMax (number): The starting maximum number of entries the queue can hold. Must be ≥ 1.
            maxPossible (number, optional): The absolute hard ceiling for the queue size. 
                            If omitted, defaults to initialMax. Must be ≥ initialMax.
        Returns: A new TimedQueue object.

    Example:
        local SF = LibSFUtils
        -- Create a queue that starts with 10 entries but can grow to 50
        local myQueue = SF.TimedQueue:New(10, 50)
--]]
--- Constructor
function TimedQueue:New(initialMax, maxPossible)
    assert(type(initialMax) == "number" and initialMax >= 1,
           "initialMax must be a positive integer")

    if maxPossible == nil then maxPossible = initialMax end
    assert(type(maxPossible) == "number" and maxPossible >= initialMax,
           "maxPossible must be ≥ initialMax")

    local obj = {
        _maxPossible = maxPossible,   -- absolute ceiling (never exceeded)
        _max         = initialMax,    -- current active limit
        _head        = 1,             -- points to the *oldest* element
        _tail        = 0,             -- points to the *newest* element
        _count       = 0,             -- number of stored entries
        _data        = {}             -- raw circular buffer (size = _maxPossible)
    }
    setmetatable(obj, self)
    return obj
end

--[[
    queue:setMax(newMax)

    Dynamically adjusts the active size limit of the queue.

    Behavior:
        Clamps newMax between 1 and _maxPossible.
        Shrinking: If newMax is smaller than the current count, the oldest entries are immediately
             discarded until the count matches newMax.
        Growing: If newMax is larger, the queue simply allows more entries before overwriting begins.
    Parameters: newMax (number).
--]]
function TimedQueue:setMax(newMax)
    assert(type(newMax) == "number", "newMax must be a number")

    if newMax < 1 then newMax = 1 end
    if newMax > self._maxPossible then newMax = self._maxPossible end

    if newMax < self._count then
        local excess = self._count - newMax
        for _ = 1, excess do
            self._head = inc(self._head, self._maxPossible)
        end
        self._count = newMax
    end

    self._max = newMax
end

--[[
    queue:getMax()

    Returns the current active limit (not necessarily the hard ceiling).

    Returns: Number.
--]]
function TimedQueue:getMax()
    return self._max
end

--[[
    queue:push(payload)

    Adds a new entry to the queue.

    Behavior:
        Creates an entry table: { ts = GetGameTimeMilliseconds(), payload = payload }.
        Places the entry at the tail (newest position).
        Overflow Handling: If the queue is at its active limit (_max), the oldest entry (at head) 
                is overwritten, and the head pointer advances.
    Parameters: payload (any): The data to store.
--]]
function TimedQueue:push(payload)
    local entry = {
        ts      = GetGameTimeMilliseconds(),
        payload = payload,
    }

    -- Advance tail (newest position)
    self._tail = inc(self._tail, self._maxPossible)
    self._data[self._tail] = entry

    if self._count < self._max then
        self._count = self._count + 1
    else
        -- Overwrite oldest entry → move head forward
        self._head = inc(self._head, self._maxPossible)
    end
end

--[[
    queue:peek()

    Returns the newest entry table { ts, payload } without removing it or nil if empty.
--]]
function TimedQueue:peek()
    if self._count == 0 then return nil end
    return self._data[self._tail]
end

--[[
    queue:list()

    Returns a snapshot of all entries as a standard Lua array.

        Order: Sorted newest → oldest.
        Returns: Table of entry tables.
--]]
function TimedQueue:list()
    local out = {}
    if self._count == 0 then return out end

    local idx = self._tail
    for i = 1, self._count do
        out[i] = self._data[idx]
        idx = dec(idx, self._maxPossible)
    end
    return out
end

--[[
    queue:size()

    Returns the current number of entries in the queue.

    Returns: Number.
--]]
function TimedQueue:size() return self._count end

--[[
    queue:clear()

    Empties the queue completely.

    Behavior: Resets pointers and clears the internal data table using ZO_ClearTable.
--]]
function TimedQueue:clear()
    self._head  = 1
    self._tail  = 0
    self._count = 0
    ZO_ClearTable(self._data)
end

-----------------------------------------------------------------------
-- ★★ Removal API ★★
-----------------------------------------------------------------------
--[[
    The queue offers flexible ways to remove specific entries. Note that removal operations 
    involve rebuilding the internal buffer, which is slightly more expensive than push or pop.
--]]

--- Internal helper: rebuild the circular buffer from a plain array.
--- The array must be ordered **newest → oldest**.
local function rebuildFromArray(q, arr)
    ZO_ClearTable(q._data)                 -- clear underlying storage
    q._head = 1
    q._tail = 0
    q._count = 0

    for i = #arr, 1, -1 do       -- iterate oldest → newest to preserve order
        q._tail = inc(q._tail, q._maxPossible)
        q._data[q._tail] = arr[i]
        q._count = q._count + 1
    end
    -- If we somehow ended up with more than the active limit (shouldn't happen),
    -- truncate the oldest excess entries.
    while q._count > q._max do
        q._head = inc(q._head, q._maxPossible)
        q._count = q._count - 1
    end
end

--[[
    queue:remove(entry)

    Removes a specific entry by reference.

    Parameters: entry (table): The exact table object **by reference** returned by push or list.
    Returns: true if removed, false if not found.
--]]
function TimedQueue:remove(entry)
    if self._count == 0 then return false end

    local all = self:list()   -- newest → oldest
    for i = 1, #all do
        if all[i] == entry then
            table.remove(all, i)          -- remove from the plain array
            rebuildFromArray(self, all)
            return true
        end
    end
    return false
end

--[[
    queue:removeByPayload(payload)

    Removes the first entry whose payload matches the given value.

    Parameters: payload (any): The value to match against entry.payload.
    Returns: true if removed, false if not found.
]]
function TimedQueue:removeByPayload(payload)
    if self._count == 0 then return false end

    local all = self:list()
    for i = 1, #all do
        if all[i].payload == payload then
            table.remove(all, i)
            rebuildFromArray(self, all)
            return true
        end
    end
    return false
end

--[[
    queue:removeIf(predicate)

    Removes the first entry that satisfies a custom condition.

    Parameters: predicate (function): A function func(entry) that returns true to delete the entry.
        entry is a table: { ts = ..., payload = ... }.
    Returns: true if removed, false if no entry matched.
--]]
function TimedQueue:removeIf(predicate)
    if self._count == 0 then return false end
    assert(type(predicate) == "function", "predicate must be a function")

    local all = self:list()
    for i = 1, #all do
        if predicate(all[i]) then
            table.remove(all, i)
            rebuildFromArray(self, all)
            return true
        end
    end
    return false
end

--[[
    queue:popOldest()

    Discards and returns the oldest entry (FIFO).

    Returns: The entry table or nil if empty.
    Use Case: Standard queue processing.
--]]
function TimedQueue:popOldest()
    if self._count == 0 then return nil end
    local oldest = self._data[self._head]
    self._head = inc(self._head, self._maxPossible)
    self._count = self._count - 1
    return oldest
end

--[[
    queue:popNewest()

    Discards and returns the newest entry (LIFO).

    Returns: The entry table or nil if empty.
    Use Case: Undo stacks or reverting the last action.
]]
function TimedQueue:popNewest()
    if self._count == 0 then return nil end
    local newest = self._data[self._tail]
    self._tail = dec(self._tail, self._maxPossible)
    self._count = self._count - 1
    return newest
end

-----------------------------------------------------------------------
