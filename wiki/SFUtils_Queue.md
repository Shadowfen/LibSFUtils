# SFUtils_Queue

`SFUtils_Queue` provides a keyed **FIFO (First In, First Out) queue** for storing table values.

Each queue entry has a unique ID and a non-nil value. Entries are maintained in insertion order while also being indexed by ID, allowing efficient lookup and removal of specific entries.

The queue uses a linked-node implementation internally. This provides FIFO queue operations while allowing an entry to be removed directly by ID without traversing the queue.

## Features

* FIFO ordering for `Enqueue()` and `Dequeue()`.
* Unique ID for every entry.
* Fast lookup by ID with `Get()` and `Has()`.
* Removal of a specific entry with `Remove()`.
* Inspection of the next entry with `Peek()`.
* Entry count with `Count()`.
* Empty-state check with `IsEmpty()`.
* Efficient clearing with `Clear()`.
* Table values are stored by reference; not copied.

---

## Creating a Queue

Create a new queue with:

```lua
local queue = SF.Queue:New()
```

A newly created queue is empty:

```lua
queue:IsEmpty()       -- true
queue:Count()         -- 0
```

---

# API

## Queue:Enqueue()

Adds a value to the back of the queue using a unique ID.

```lua
Queue:Enqueue(id, value)
```

### Parameters

| Parameter | Type  | Description                            |
| --------- | ----- | -------------------------------------- |
| `id`      | any   | Unique identifier for the queue entry. |
| `value`   | any   | Value to store in the queue.           |

### Returns

`boolean`

* `true` if the entry was successfully added.
* `false` if `id` or `value` is `nil`.
* `false` if an entry with the specified ID already exists.

### Behavior

`Enqueue()` adds the entry to the **back** of the queue.

Entries are subsequently returned by `Dequeue()` in the order in which they were successfully added.

This is standard FIFO behavior:

```text
Enqueue A
Enqueue B
Enqueue C

Dequeue → A
Dequeue → B
Dequeue → C
```

The ID must be unique within the queue. Attempting to enqueue an existing ID does not modify the existing entry.

The supplied value table is stored by reference and is not copied.

### Example

```lua
local queue = SF.Queue:New()

local entry = {
    name = "Example",
    value = 123,
}

if queue:Enqueue("example", entry) then
    -- Entry was added successfully.
end
```

A duplicate ID is rejected:

```lua
queue:Enqueue("example", entry)

local result = queue:Enqueue("example", {
    name = "Another entry",
})

-- result == false
```

---

## Queue:Dequeue()

Removes and returns the entry at the front of the queue.

```lua
Queue:Dequeue()
```

### Parameters

None.

### Returns

Two values:

1. `id` — ID of the removed entry.
2. `value` — Table associated with the removed entry.

If the queue is empty, both return values are `nil`.

### Behavior

`Dequeue()` removes the entry at the **front** of the queue.

Entries are removed in FIFO order.

The removed entry is also removed from the queue's ID index, so `Get(id)` and `Has(id)` will no longer find it.

### Example

```lua
queue:Enqueue("one", {
    name = "First",
})

queue:Enqueue("two", {
    name = "Second",
})

local id, value = queue:Dequeue()

-- id == "one"
-- value == { name = "First" }
```

Calling `Dequeue()` on an empty queue returns `nil`:

```lua
local id, value = queue:Dequeue()

-- id == nil
-- value == nil
```

The returned value is the same table supplied to `Enqueue()`; it is not copied.

---

## Queue:Get()

Returns the table associated with a specified queue entry ID without removing the entry.

```lua
Queue:Get(id)
```

### Parameters

| Parameter | Type | Description                        |
| --------- | ---- | ---------------------------------- |
| `id`      | any  | ID of the queue entry to retrieve. |

### Returns

`table|nil`

* The table associated with `id` if the entry exists.
* `nil` if no entry with the specified ID exists.

### Behavior

`Get()` performs a keyed lookup.

It does not remove the entry, change its position, or otherwise modify the queue.

The returned table is the same table supplied to `Enqueue()`.

### Example

```lua
local entry = {
    name = "Example",
    value = 123,
}

queue:Enqueue("example", entry)

local value = queue:Get("example")

-- value == entry
```

Modifying the returned table modifies the queued value:

```lua
local value = queue:Get("example")

value.value = 456

-- queue:Get("example").value == 456
```

A missing ID returns `nil`:

```lua
queue:Get("missing")   -- nil
```

---

## Queue:Has()

Determines whether the queue contains an entry with the specified ID.

```lua
Queue:Has(id)
```

### Parameters

| Parameter | Type | Description                    |
| --------- | ---- | ------------------------------ |
| `id`      | any  | ID of the queue entry to test. |

### Returns

`boolean`

* `true` if the specified ID exists in the queue.
* `false` otherwise.

### Behavior

`Has()` performs a keyed lookup without retrieving or removing the entry.

It does not modify the queue or change the entry's position.

### Example

```lua
queue:Enqueue("example", {
    name = "Example",
})

if queue:Has("example") then
    -- Entry exists.
end
```

A missing ID returns `false`:

```lua
queue:Has("missing")   -- false
```

---

## Queue:Remove()

Removes a specific entry from the queue by its ID.

```lua
Queue:Remove(id)
```

### Parameters

| Parameter | Type | Description                      |
| --------- | ---- | -------------------------------- |
| `id`      | any  | ID of the queue entry to remove. |

### Returns

`table|nil`

* The table associated with the removed entry.
* `nil` if no entry with the specified ID exists.

### Behavior

`Remove()` removes an entry regardless of its position in the queue.

It can remove:

* The first entry.
* The last entry.
* An intermediate entry.
* The only entry in the queue.

Removing an entry does not change the relative order of the remaining entries.

The removed entry is deleted from the queue's ID index and the queue count is decremented.

### Example

```lua
queue:Enqueue("one", {
    name = "First",
})

queue:Enqueue("two", {
    name = "Second",
})

queue:Enqueue("three", {
    name = "Third",
})

local value = queue:Remove("two")

-- value == { name = "Second" }
```

The remaining order is:

```text
one → three
```

The removed ID is no longer present:

```lua
queue:Has("two")      -- false
queue:Get("two")      -- nil
queue:Count()         -- 2
```

Removing a nonexistent ID returns `nil` and has no effect:

```lua
local value = queue:Remove("missing")

-- value == nil
```

---

## Queue:Peek()

Returns the entry at the front of the queue without removing it.

```lua
Queue:Peek()
```

### Parameters

None.

### Returns

Two values:

1. `id` — ID of the entry at the front of the queue.
2. `value` — Table associated with the entry.

If the queue is empty, both return values are `nil`.

### Behavior

`Peek()` returns the entry that would be returned by the next call to `Dequeue()`.

It does not change the queue's contents, order, or count.

### Example

```lua
queue:Enqueue("one", {
    name = "First",
})

queue:Enqueue("two", {
    name = "Second",
})

local id, value = queue:Peek()

-- id == "one"
-- value == { name = "First" }
```

The entry remains in the queue:

```lua
queue:Peek()
queue:Peek()

-- Both calls return "one".
```

To remove the entry after inspecting it, use `Dequeue()`.

```lua
local id, value = queue:Peek()

if id then
    -- Inspect or process value.
    queue:Dequeue()
end
```

---

## Queue:IsEmpty()

Determines whether the queue contains any entries.

```lua
Queue:IsEmpty()
```

### Parameters

None.

### Returns

`boolean`

* `true` if the queue contains no entries.
* `false` if the queue contains one or more entries.

### Behavior

`IsEmpty()` does not modify the queue.

It is equivalent to testing whether `Count()` returns zero.

### Example

```lua
local queue = SF.Queue:New()

queue:IsEmpty()       -- true

queue:Enqueue("one", {
    value = 1,
})

queue:IsEmpty()       -- false
```

Use `IsEmpty()` when only the empty/non-empty state is needed.

---

## Queue:Count()

Returns the number of entries currently contained in the queue.

```lua
Queue:Count()
```

### Parameters

None.

### Returns

`number`

The number of entries currently in the queue.

An empty queue returns `0`.

### Behavior

`Count()` does not modify the queue.

The count is:

* Incremented by a successful `Enqueue()`.
* Decremented by `Dequeue()`.
* Decremented by `Remove()`.
* Reset to `0` by `Clear()`.

`Get()`, `Has()`, and `Peek()` do not change the count.

### Example

```lua
local queue = SF.Queue:New()

queue:Count()        -- 0

queue:Enqueue("one", {
    value = 1,
})

queue:Enqueue("two", {
    value = 2,
})

queue:Count()        -- 2
```

When only the empty/non-empty state is required, `IsEmpty()` is more expressive:

```lua
if not queue:IsEmpty() then
    -- Queue contains entries.
end
```

---

## Queue:Clear()

Removes all entries from the queue.

```lua
Queue:Clear()
```

### Parameters

None.

### Returns

None.

### Behavior

`Clear()` resets the queue to its initial empty state.

After `Clear()`:

```lua
queue:IsEmpty()      -- true
queue:Count()        -- 0
queue:Peek()         -- nil
queue:Dequeue()      -- nil
```

Previously queued IDs are no longer present:

```lua
queue:Has("one")     -- false
queue:Get("one")     -- nil
```

The queue can be reused normally after being cleared.

### Example

```lua
queue:Enqueue("one", {
    name = "First",
})

queue:Enqueue("two", {
    name = "Second",
})

queue:Clear()

queue:IsEmpty()      -- true
queue:Count()        -- 0
```

`Clear()` does not modify the table values that were previously stored in the queue. It removes the queue's references to those values. If no other references remain, they become eligible for Lua garbage collection.

---

# Operation Summary

| Method               | Purpose                     | Removes Entry | Lookup   |
| -------------------- | --------------------------- | ------------: | -------- |
| `Enqueue(id, value)` | Add entry to back           |            No | ID       |
| `Dequeue()`          | Remove front entry          |           Yes | Position |
| `Get(id)`            | Retrieve specific entry     |            No | ID       |
| `Has(id)`            | Test for specific entry     |            No | ID       |
| `Remove(id)`         | Remove specific entry       |           Yes | ID       |
| `Peek()`             | Inspect front entry         |            No | Position |
| `IsEmpty()`          | Test whether queue is empty |            No | —        |
| `Count()`            | Get number of entries       |            No | —        |
| `Clear()`            | Remove all entries          |           Yes | —        |

# FIFO Ordering

`SFUtils_Queue` maintains **FIFO ordering** for normal queue operations.

Given:

```lua
queue:Enqueue("A", valueA)
queue:Enqueue("B", valueB)
queue:Enqueue("C", valueC)
```

the queue is:

```text
Front                         Back
  ↓                             ↓
 [A] → [B] → [C]
```

Consequently:

```lua
queue:Dequeue()   -- A
queue:Dequeue()   -- B
queue:Dequeue()   -- C
```

`Remove()` is the exception to normal FIFO removal because it can explicitly remove an entry by ID. Removing an entry does not otherwise alter the ordering of the remaining entries.

# Keyed Access

Unlike a traditional queue, entries can be accessed directly by ID:

```lua
queue:Get("B")
```

This does not require traversing the queue.

Likewise:

```lua
queue:Has("B")
queue:Remove("B")
```

operate directly using the entry's ID.

This combination of a linked queue and ID index allows the queue to provide both:

* Efficient FIFO processing.
* Efficient keyed lookup and removal.

# Value References

Queue values are stored by reference.

For example:

```lua
local value = {
    count = 10,
}

queue:Enqueue("item", value)

value.count = 20

queue:Get("item").count   -- 20
```

Likewise, modifying the table returned by `Get()`, `Peek()`, `Dequeue()`, or `Remove()` modifies the same table originally supplied to `Enqueue()`.

The queue does not perform deep or shallow copies of values.

# Typical Usage

A common processing pattern is:

```lua
local queue = SF.Queue:New()

queue:Enqueue("first", {
    action = "process",
})

queue:Enqueue("second", {
    action = "update",
})

while not queue:IsEmpty() do
    local id, value = queue:Dequeue()

    -- Process value.
end
```

If an entry needs to be inspected without removing it:

```lua
local id, value = queue:Peek()

if id then
    -- Inspect the next entry.
end
```

If a specific entry needs to be accessed or cancelled:

```lua
if queue:Has(id) then
    local value = queue:Get(id)

    -- Inspect value...

    queue:Remove(id)
end
```
