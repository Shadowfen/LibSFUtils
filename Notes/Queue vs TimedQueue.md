Given this implementation, I would **not call `TimedQueue` a scheduling queue** like I described earlier. Your `TimedQueue` is really a **timestamped, bounded history/ring buffer**.

The two structures serve quite different purposes:

|                   | `SF.Queue`           | `SF.TimedQueue`                      |
| ----------------- | -------------------- | ------------------------------------ |
| Primary purpose   | Pending work         | Recent history                       |
| Ordering          | FIFO                 | Newest → oldest for `list()`         |
| Capacity          | Unlimited            | Fixed/bounded                        |
| Overflow          | No automatic removal | Oldest automatically discarded       |
| Timestamp         | No                   | Yes                                  |
| ID                | Yes                  | No                                   |
| Arbitrary removal | O(1) by ID           | O(n)                                 |
| `Peek`            | Next/oldest          | Newest                               |
| Remove oldest     | `Dequeue()`          | `popOldest()`                        |
| Remove newest     | —                    | `popNewest()`                        |
| Payload           | Any non-nil value    | Any value, including potentially nil |
| Dynamic capacity  | —                    | Yes                                  |
| Best use          | Work to be processed | Recent events/history                |

### Use `Queue` when...

You have work that **must eventually be processed**:

```lua
queue:Enqueue("refresh", refreshData)
queue:Enqueue("update", updateData)
queue:Enqueue("save", saveData)
```

You don't want old work disappearing simply because the queue got full.

```text
refresh → update → save
   ↓         ↓        ↓
process    process  process
```

The ID also makes it particularly useful when you need to cancel or replace specific pending work.

---

### Use your `TimedQueue` when...

You want to retain **the most recent N events/values**, with timestamps attached automatically:

```lua
history:push({
    action = "playerMoved",
    x = 100,
    y = 200,
})
```

As new entries arrive:

```text
oldest                              newest
  ↓                                   ↓
[A] → [B] → [C] → [D] → [E]
```

Once capacity is reached:

```text
push F

[B] → [C] → [D] → [E] → [F]
 ↑
 A discarded
```

That's excellent for things like:

* Debug/event history
* Recent API calls
* Recent player actions
* Combat/event history
* Performance samples
* Recent error records
* Diagnostic information
* "Last N events" displays
* Undo/history-like functionality
* Keeping a bounded history without accumulating memory

The timestamp makes the history especially useful:

```lua
local entries = history:list()

for _, entry in ipairs(entries) do
    d(entry.ts, entry.payload)
end
```

---

## One important naming point

I'd describe your `TimedQueue` as:

> **A bounded timestamped history queue implemented as a circular buffer.**

rather than:

> A timed queue.

"TimedQueue" commonly suggests:

> "Execute this item at time X."

Your implementation doesn't do that. The timestamp is **metadata about when the item was added**, not a condition determining when it can be removed.

So conceptually:

```text
SF.Queue
    ↓
pending work

SF.TimedQueue
    ↓
timestamped recent history
```

That's actually a very useful distinction for LibSFUtils.

### One thing I'd reconsider

Your `TimedQueue` currently has:

```lua
push()
peek()       -- newest
popOldest()
popNewest()
list()       -- newest → oldest
```

That's internally consistent if you think of it as **history**, but it isn't a conventional queue API.

I'd document it explicitly as a **bounded history/ring buffer**, because otherwise someone seeing:

```lua
local entry = queue:peek()
```

may reasonably expect the oldest item, whereas your `peek()` returns the **newest**.
