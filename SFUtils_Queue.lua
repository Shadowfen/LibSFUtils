local SF = LibSFUtils

local Queue = {}
Queue.__index = Queue
SF.Queue = Queue

function Queue:New()
    return setmetatable({
        first = nil,
        last = nil,
        entries = {},
        count = 0,
    }, self)
end

--[[ Queue:Enqueue(id, value)

Adds a table value to the back of the queue using a unique ID.

#### Parameters

| Parameter | Type  | Description                            |
| --------- | ----- | -------------------------------------- |
| `id`      | any   | Unique identifier for the queue entry. |
| `value`   | table | Table to store in the queue.           |

#### Returns

`boolean`

* `true` if the entry was successfully added.
* `false` if `id` or `value` is `nil`, or if an entry with the specified `id` already exists.

#### Behavior

`Enqueue()` adds the entry to the **back** of the queue. Entries are subsequently returned by `Dequeue()` 
in the order they were successfully enqueued (FIFO — First In, First Out).

The `id` must be unique within the queue. Attempting to enqueue an existing ID does not modify the existing 
entry and returns `false`.

The supplied `value` table is stored by reference; the queue does not copy the table.
--]]
function Queue:Enqueue(id, value)
    if id == nil or value == nil then
        return false
    end
    local entries = self.entries
    local last = self.last

    if entries[id] ~= nil then
        return false
    end

    local node = {
        id = id,
        value = value,
        prev = last,
        next = nil,
    }

    if last then
        last.next = node
    else
        self.first = node
    end

    self.last = node
    entries[id] = node
    self.count = self.count + 1

    return true
end

--[[ Queue:Dequeue()

Removes and returns the entry at the front of the queue.

#### Parameters
    None.

#### Returns Two values:
    1. `id` — The ID of the removed entry.
    2. `value` — The table associated with the removed entry.
If the queue is empty, both return values are `nil`.

#### Behavior

    `Dequeue()` removes the entry at the **front** of the queue and returns its ID and value.

    Entries are removed in the same order in which they were successfully added 
    with `Enqueue()` (FIFO — First In, First Out).

    The removed entry is also removed from the queue's ID index, so `Get(id)` 
    and `Has(id)` will no longer find it.


    Calling `Dequeue()` on an empty queue returns `nil`:

    `Dequeue()` does not modify or copy the returned value table. 
    The returned table is the same table that was supplied to `Enqueue()`.
--]]
function Queue:Dequeue()
    local node = self.first

    if not node then
        return nil
    end
    local next = node.next

    self.first = next

    if next then
        next.prev = nil
    else
        self.last = nil
    end

    self.entries[node.id] = nil
    self.count = self.count - 1

    node.prev = nil
    node.next = nil

    return node.id, node.value
end

--[[ Queue:Get(id)

Returns the table associated with a specified queue entry ID without removing the entry.

#### Parameters

| Parameter | Type | Description                        |
| --------- | ---- | ---------------------------------- |
| `id`      | any  | ID of the queue entry to retrieve. |

#### Returns

    `table|nil`

    * The table associated with `id` if the entry exists.
    * `nil` if no entry with the specified ID exists.

#### Behavior
    `Get()` performs a keyed lookup of an entry in the queue.
    It does **not** remove the entry, change its position, or otherwise modify the queue.
    The returned table is the same table that was supplied to `Enqueue()`; it is not copied.
    Use `Get()` when the ID of the entry is known and the entry needs to be inspected or modified.
    Use `Peek()` instead when the intention is to retrieve the entry currently at the front of the queue.

    * Modifying the returned table modifies the queued value because the table is stored by reference
    * If the specified ID does not exist, `Get()` returns `nil`:

--]]
function Queue:Get(id)
    local node = self.entries[id]
    return node and node.value
end

--[[ Queue:Has(id)

    Determines whether the queue contains an entry with the specified ID.

    #### Parameters

    | Parameter | Type | Description                    |
    | --------- | ---- | ------------------------------ |
    | `id`      | any  | ID of the queue entry to test. |

    #### Returns

    `boolean`

    * `true` if an entry with the specified ID exists in the queue.
    * `false` if no entry with the specified ID exists.

    #### Behavior

    `Has()` performs a keyed lookup without retrieving or removing the entry.

    It does not change the entry's position or otherwise modify the queue.

    `Has()` can be used to test for an entry before calling `Get()` or `Remove()`.

    An ID that is not present returns `false`:
    Calling `Has()` does not affect the queue:
--]]
function Queue:Has(id)
    return self.entries[id] ~= nil
end

--[[ Queue:Remove(id)

    Removes a specific entry from the queue by its ID.

    #### Parameters

    | Parameter | Type | Description                      |
    | --------- | ---- | -------------------------------- |
    | `id`      | any  | ID of the queue entry to remove. |

    #### Returns

    `table|nil`

    * The table associated with the removed entry if the entry exists.
    * `nil` if no entry with the specified ID exists.

    #### Behavior

    `Remove()` removes the entry identified by `id` regardless of its position in the queue.

    Unlike `Dequeue()`, which always removes the entry at the front of the queue, `Remove()` 
    can remove the first, last, or any intermediate entry.

    Removing an entry does not change the relative order of the remaining entries.

    The removed entry is also removed from the queue's ID index, so subsequent calls to `Get(id)` 
    and `Has(id)` return `nil` and `false`, respectively.

    The queue's entry count is decremented when an entry is successfully removed.

    After removing `"two"`, the remaining queue order is unchanged:
    The removed ID is no longer present.

    Removing an ID that does not exist has no effect and returns `nil`:
    The returned table is the same table that was supplied to `Enqueue()`; it is not copied.
--]]
function Queue:Remove(id)
    local node = self.entries[id]

    if not node then
        return nil
    end
    local prev = node.prev
    local next = node.next

    if prev then
        prev.next = next
    else
        self.first = next
    end

    if next then
        next.prev = prev
    else
        self.last = prev
    end

    self.entries[id] = nil
    self.count = self.count - 1

    node.prev = nil
    node.next = nil

    return node.value
end

--[[ Queue:Peek()

    Returns the entry at the front of the queue without removing it.

    #### Parameters

    None.

    #### Returns Two values:
        1. `id` — The ID of the entry at the front of the queue.
        2. `value` — The table associated with the entry.

    If the queue is empty, both return values are `nil`.

    #### Behavior

    `Peek()` examines the entry that would be returned by the next call to `Dequeue()` without removing it.
    It does not change the queue's contents, order, or count.

    Use `Peek()` when the next queued entry needs to be inspected before deciding whether to process it.
    Use `Get(id)` instead when the ID of a specific entry is known and its position in the queue is not relevant.
        The entry remains in the queue after `Peek()`.
        To actually remove the entry after inspecting it, use `Dequeue()`.
        Calling `Peek()` on an empty queue returns `nil`.
--]]
function Queue:Peek()
    local node = self.first

    if node then
        return node.id, node.value
    end

    return nil
end

--[[ Queue:IsEmpty() - Determines whether the queue contains any entries.
    #### Parameters
        None.

    #### Returns
        `boolean`
            * `true` if the queue contains no entries.
            * `false` if the queue contains one or more entries.

    #### Behavior

        `IsEmpty()` checks whether the queue's entry count is zero.
        It does not modify the queue or any of its entries.

        `IsEmpty()` is equivalent to testing whether `Count()` returns zero:
        Use `IsEmpty()` when only the empty/non-empty state is needed. Use `Count()` 
        when the number of entries is required.
--]]
function Queue:IsEmpty()
    return self.count == 0
end

--[[ Queue:Count() - Returns the number of entries currently contained in the queue.

    #### Parameters
        None.

    #### Returns
        `number` - The number of entries currently in the queue.
            An empty queue returns `0`.

    #### Behavior

    `Count()` returns the queue's current entry count.
    It does not modify the queue or any of its entries.

    The count is incremented when an entry is successfully added with `Enqueue()` 
    and decremented when an entry is removed with `Dequeue()` or `Remove()`.

    Calling `Get()`, `Has()`, or `Peek()` does not change the count.
    `Clear()` resets the count to `0`.

    `Count()` can be used to determine whether a queue contains entries, although `IsEmpty()` 
    is more expressive when only the empty/non-empty state is needed:
--]]
function Queue:Count()
    return self.count
end

--[[ ### Queue:Clear() - Remove all entries from the queue.

    #### Parameters
        None.

    #### Returns
        None.

    #### Behavior

        `Clear()` removes all entries from the queue and resets the queue to its initial empty state.

        After `Clear()`:

        * `IsEmpty()` returns `true`.
        * `Count()` returns `0`.
        * `Get(id)` returns `nil` for previously queued IDs.
        * `Has(id)` returns `false` for previously queued IDs.
        * `Peek()` returns `nil`.
        * `Dequeue()` returns `nil`.

        The queue can be reused normally after it has been cleared.

        `Clear()` does not modify the table values that were previously stored 
        in the queue. It removes the queue's references to those values; if no 
        other references remain, they become eligible for Lua garbage collection.
--]]
function Queue:Clear()
    self.first = nil
    self.last = nil
    self.entries = {}
    self.count = 0
end