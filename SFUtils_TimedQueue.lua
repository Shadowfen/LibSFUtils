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

--- Constructor
--- @param initialMax   number  Starting active limit (≥1)
--- @param maxPossible  number|nil  Hard ceiling for the limit (≥initialMax). If nil, defaults to initialMax.
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

--- Adjust the active limit (`maxEntries`) at runtime.
--- The new limit is clamped to [1, _maxPossible].
--- If the new limit is smaller than the current count, the oldest
--- entries are discarded immediately.
--- @param newMax number
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

function TimedQueue:getMax()
    return self._max
end

--- Push a new payload onto the queue.
--- Stores `{ ts = GetGameTimeMilliseconds(), payload = payload }`.
--- If the queue is already at its active limit, the oldest entry is overwritten.
--- @param payload any
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

--- Return the newest entry (or nil if empty).
function TimedQueue:peek()
    if self._count == 0 then return nil end
    return self._data[self._tail]
end

--- Return **all** entries as a plain array, sorted newest → oldest.
--- The returned array is a copy; mutating it does not affect the queue.
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

function TimedQueue:size() return self._count end

--- Clear the whole queue.
function TimedQueue:clear()
    self._head  = 1
    self._tail  = 0
    self._count = 0
    ZO_ClearTable(self._data)
end

-----------------------------------------------------------------------
-- ★★ Removal API ★★
-----------------------------------------------------------------------

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

--- Remove a specific entry **by reference** (the exact table returned by `push` or `list`).
--- Returns `true` if something was removed, `false` otherwise.
--- @param entry table
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

--- Remove the **first entry whose payload equals** the supplied value.
--- Returns `true` if something was removed.
--- @param payload any
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

--- Remove the **first entry that satisfies a predicate**.
--- `predicate(entry)` should return `true` for the entry you want to delete.
--- Returns `true` if something was removed.
--- @param predicate fun(entry:table):boolean
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

--- Discard the **oldest** entry (the one at the head of the queue).
--- Returns the removed entry or `nil` if the queue is empty.
function TimedQueue:popOldest()
    if self._count == 0 then return nil end
    local oldest = self._data[self._head]
    self._head = inc(self._head, self._maxPossible)
    self._count = self._count - 1
    return oldest
end

--- Discard the **newest** entry (the one at the tail of the queue).
--- Returns the removed entry or `nil` if the queue is empty.
function TimedQueue:popNewest()
    if self._count == 0 then return nil end
    local newest = self._data[self._tail]
    self._tail = dec(self._tail, self._maxPossible)
    self._count = self._count - 1
    return newest
end

-----------------------------------------------------------------------
