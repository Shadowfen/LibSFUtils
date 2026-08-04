````markdown
# SFUtils.CallLater

`SFUtils.CallLater` is a lightweight timer utility for **The Elder Scrolls Online** that extends the native `zo_callLater` API with a higher-level object-oriented interface.

It supports:

- One-shot timers
- Periodic timers
- Automatic retry on callback failure
- Callback argument passing
- Safe callback execution through `LibSFUtils.safeCall`
- Runtime timer management (start, cancel, destroy)

---

# Creating Timers

## One-Shot Timer

Creates a timer that executes once.

```lua
local timer = SF.CallLater:New(function()
    d("Executed")
end, 1000)

timer:Start()
```

### Syntax

```lua
CallLater:New(callback, delayMs)
```

### Parameters

| Parameter | Type | Description |
|----------|------|-------------|
| callback | function | Function to execute. |
| delayMs | number | Delay in milliseconds before execution. Default is `0`. |

### Returns

A new `CallLater` timer object.

---

## NewSingle()

`NewSingle()` is simply an alias for `New()`.

```lua
local timer = SF.CallLater:NewSingle(callback, 500)
```

---

## Timer With Retry Support

Creates a one-shot timer that automatically retries if the callback throws an error.

```lua
local timer = SF.CallLater:NewMaxTries(function()
    error("Failure")
end, 1000, 3)

timer:Start()
```

### Syntax

```lua
CallLater:NewMaxTries(callback, delayMs, maxTries)
```

### Parameters

| Parameter | Type | Description |
|----------|------|-------------|
| callback | function | Function to execute. |
| delayMs | number | Delay between attempts. |
| maxTries | number | Maximum retry attempts. |

### Notes

- Retries only occur when the callback throws an error.
- Successful execution clears retry tracking.
- Retry count includes the initial execution attempt.

---

## Periodic Timer

Creates a timer that repeats indefinitely until cancelled.

```lua
local timer = SF.CallLater:NewTimer(function()
    d("Tick")
end, 1000)

timer:Start()
```

### Syntax

```lua
CallLater:NewTimer(callback, intervalMs)
```

### Parameters

| Parameter | Type | Description |
|----------|------|-------------|
| callback | function | Function called every interval. |
| intervalMs | number | Interval in milliseconds. |

---

# Starting Timers

## Start()

Starts a timer.

```lua
timer:Start()
```

Optionally override the default delay.

```lua
timer:Start(500)
```

### Syntax

```lua
timer:Start(delayMs)
```

### Parameters

| Parameter | Type | Description |
|----------|------|-------------|
| delayMs | number | Optional delay override for one-shot timers. |

### Behavior

For one-shot timers:

- Cancels any currently running instance.
- Starts a new delayed callback.

For periodic timers:

- Begins the recurring timer loop.

Returns the timer instance to allow chaining.

---

## StartWithArgs()

Starts a one-shot timer while supplying arguments to the callback.

```lua
local timer = SF.CallLater:New(function(name, score)
    d(string.format("%s scored %d", name, score))
end, 1000)

timer:StartWithArgs("Lumo", 9000)
```

### Syntax

```lua
timer:StartWithArgs(...)
```

### Notes

- Only available for one-shot timers.
- Arguments are stored until execution.
- Calling this on a periodic timer logs a warning.

---

# Managing Timers

## Cancel()

Stops a running timer.

```lua
timer:Cancel()
```

### Returns

- `true` if the timer was cancelled.
- `false` if it was not running.

### Effects

Cancelling also clears:

- callback
- pending arguments
- retry information
- periodic callback
- interval
- timer handle

After cancellation the timer object cannot simply be restarted; create a new timer or assign a new callback before reuse.

---

## Destroy()

Alias for `Cancel()`.

```lua
timer = timer:Destroy()
```

Returns `nil`, making cleanup convenient.

---

# Querying State

## IsRunning()

Returns whether the timer is currently active.

```lua
if timer:IsRunning() then
    d("Still running")
end
```

### Returns

```lua
true
```

or

```lua
false
```

---

# Modifying Timers

## SetCallback()

Replaces the callback.

```lua
timer:SetCallback(function()
    d("New callback")
end)
```

### Syntax

```lua
timer:SetCallback(callback)
```

Returns the timer instance.

---

## SetDelay()

Changes the default delay used by one-shot timers.

```lua
timer:SetDelay(2000)
```

### Syntax

```lua
timer:SetDelay(delayMs)
```

Changing the delay does **not** affect a currently running timer.

Returns the timer instance.

---

# Error Handling

All callbacks execute through:

```lua
LibSFUtils.safeCall()
```

This prevents Lua errors from propagating into the addon.

## One-Shot Timers

If the callback fails:

- retry counter increments
- timer is rescheduled if retries remain
- retry tracking is cleared once exhausted

## Periodic Timers

If the callback fails:

- error is logged
- next interval continues normally

The periodic timer is **not** cancelled by callback errors.

---

# Method Chaining

Most methods return the timer instance.

```lua
local timer =
    SF.CallLater:New(callback, 1000)
        :SetDelay(500)
        :Start()
```

---

# Typical Usage

## Execute Once

```lua
SF.CallLater:New(function()
    d("Finished")
end, 2000):Start()
```

---

## Delayed Function With Arguments

```lua
SF.CallLater:New(function(player, gold)
    d(player .. " has " .. gold)
end, 500):StartWithArgs("@Player", 25000)
```

---

## Retry Until Success

```lua
local timer = SF.CallLater:NewMaxTries(function()
    assert(IsPlayerActivated())
end, 1000, 5)

timer:Start()
```

---

## Heartbeat Timer

```lua
local heartbeat = SF.CallLater:NewTimer(function()
    d("Heartbeat")
end, 1000)

heartbeat:Start()
```

Later:

```lua
heartbeat:Cancel()
```

---

# API Summary

| Method | Description |
|---------|-------------|
| `New()` | Creates a one-shot timer. |
| `NewSingle()` | Alias for `New()`. |
| `NewMaxTries()` | Creates a retrying one-shot timer. |
| `NewTimer()` | Creates a periodic timer. |
| `Start()` | Starts the timer. |
| `StartWithArgs()` | Starts with callback arguments. |
| `Cancel()` | Stops and cleans up the timer. |
| `Destroy()` | Alias for `Cancel()`, returns `nil`. |
| `IsRunning()` | Returns whether the timer is active. |
| `SetCallback()` | Replaces the callback. |
| `SetDelay()` | Changes the default delay. |

---

# Implementation Notes

- One-shot timers use the native `zo_callLater`.
- Periodic timers are implemented by rescheduling themselves after each execution.
- All callback execution is protected by `LibSFUtils.safeCall`.
- Retry logic is available only for one-shot timers.
- `StartWithArgs()` is supported only for one-shot timers.
- Timer objects maintain their own execution state, making multiple concurrent timers independent of one another.
````
