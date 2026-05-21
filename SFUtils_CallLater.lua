--[[
    CallLater is a robust timer utility library designed to manage delayed and periodic function execution. 
        It wraps the native zo_callLater API to provide features like automatic retry on failure, argument passing, 
        periodic scheduling, and safe cleanup.

    Key Features:

        One-shot Timers: Execute a function once after a delay.
        Periodic Timers: Execute a function repeatedly at fixed intervals.
        Retry Logic: Automatically retry failed callbacks up to a maximum number of attempts.
        Argument Passing: Support for passing dynamic arguments to one-shot callbacks.
        Safe Execution: Wraps callbacks in LibSFUtils.safeCall to prevent script errors from crashing the addon.
        Lifecycle Management: Methods to start, cancel, and destroy timers cleanly.
    
    Usage Examples
        1. Simple One-Shot Timer

            Execute a function 2 seconds later.

            local timer = CallLater:New(function()
                d("Hello from 2 seconds ago!")
            end, 2000)

            timer:Start()

        2. Passing Arguments

            Pass data to the callback dynamically.

            local timer = CallLater:New(function(playerName, score)
                d(string.format("%s scored %d!", playerName, score))
            end, 1000)

            timer:StartWithArgs("Lumo", 9999)

        3. Retry Logic

            Attempt to run a risky function up to 3 times if it fails.

            local timer = CallLater:NewMaxTries(function()
                -- Simulate a failure
                error("Something went wrong!")
            end, 500, 3)

            timer:Start()
            -- This will log the error 3 times, then stop retrying.

        4. Periodic Timer

            Run a function every 1 second indefinitely.

            local timer = CallLater:NewTimer(function()
                d("Tick...")
            end, 1000)

            timer:Start()

            -- Later, to stop:
            -- timer:Cancel()

        5. Chaining & Cleanup

            local timer = CallLater:New(function() d("Done") end, 5000)
                :SetDelay(1000) -- Change delay before starting
                :Start()

            if timer:IsRunning() then
                -- ... some logic ...
                timer:Cancel()
            end

    Error Handling

    The library uses LibSFUtils.safeCall to wrap all callback executions.

    If a callback throws an error:
        One-shot with retries: The timer waits for the delay and retries until maxTries is reached.
        Periodic: Logs the error via d("[PeriodicTimer] callback error: ...") and continues the next tick.
        Standard One-shot: The error is logged, and the timer stops without retrying.

--]]
local SF = LibSFUtils
SF.CallLater = {}
local CallLater = SF.CallLater
CallLater.__index = CallLater

--------------------------------------------------------------------
-- Internal helper that runs the user callback and handles retries.
--------------------------------------------------------------------
local function invokeLater(self)
    -- Timer fired – clear handle and mark inactive.
    self.timerId = nil
    self.active  = false

    local args = self.pendingArgs or {}
    self.pendingArgs = nil

    if not self.callback then return end

    local ok, err = SF.safeCall(self.callback, unpack(args))

    if not ok then
        if self.maxTries and self.attemptsMade < self.maxTries then
            self.attemptsMade = self.attemptsMade + 1
            self.timerId = zo_callLater(function() invokeLater(self) end,
                                         self.delay)
            self.active = true
        else
            self.maxTries     = nil
            self.attemptsMade = nil
        end
    else
        self.maxTries     = nil
        self.attemptsMade = nil
    end
end

--------------------------------------------------------------------
-- Constructors
--------------------------------------------------------------------
--[[
    CallLater:New(callback, delayMs)
    or 
    CallLater:NewSingle(callback, delayMs)

    Creates a new one-shot timer instance.
    After running, it will not run again until you restart it with the Start() method.

    Parameters:
        callback (function): The function to execute.
        delayMs (number, optional): Delay in milliseconds before execution. Defaults to 0.
    Returns: A new CallLater instance.
--]]
function CallLater:New(callback, delayMs)
    return setmetatable({
        callback      = callback,
        delay         = delayMs or 0,
        timerId       = nil,
        active        = false,
    }, self)
end

CallLater.NewSingle = CallLater.New

--[[
    CallLater:NewMaxTries(callback, delayMs, maxTries)

    Creates a one-shot timer with automatic retry logic if the callback fails.

    Parameters:
        callback (function): The function to execute.
        delayMs (number, optional): Delay in milliseconds.
        maxTries (number): Maximum number of retry attempts if the callback throws an error.
    Returns: A new CallLater instance configured for retries.
--]]
function CallLater:NewMaxTries(callback, delayMs, maxTries)
    return setmetatable({
        callback      = callback,
        delay         = delayMs or 0,
        timerId       = nil,
        active        = false,
        maxTries      = math.floor(maxTries),
        attemptsMade  = 0,
        pendingArgs   = nil,
    }, self)
end

--[[
    CallLater:NewTimer(callback, intervalMs)

    Creates a periodic timer that executes repeatedly.

    Parameters:
        callback (function): The function to execute on every tick.
        intervalMs (number): Interval in milliseconds between executions.
    Returns: A new CallLater instance configured as a periodic timer.
--]]
function CallLater:NewTimer(callback, intervalMs)
    return setmetatable({
        periodicCallback = callback,   -- distinct from one‑shot `callback`
        interval         = intervalMs,
        timerId          = nil,
        active           = false,
    }, self)
end

--------------------------------------------------------------------
-- Internal periodic‑timer scheduler (private)
--------------------------------------------------------------------
function CallLater:_scheduleNext()
    if not self.active then return end

    self._tickWrapper = function()
        if not self.periodicCallback then return end
        local ok, err = SF.safeCall(self.periodicCallback)
        if not ok then
            d("[PeriodicTimer] callback error: " .. tostring(err))
        end
        self:_scheduleNext()
    end

    self.timerId = zo_callLater(self._tickWrapper, self.interval)
end

--------------------------------------------------------------------
-- Public start / start‑with‑args
--------------------------------------------------------------------
--[[
    timer:Start(delayMs)

    Starts the timer.

    Behavior:
        If the timer is already running, it cancels the current one before starting a new one.
        One-shot: Schedules the callback after delayMs (or the instance's default delay).
        Periodic: Starts the recurring loop.
    Parameters:
        delayMs (number, optional): Overrides the default delay for one-shot timers. Ignored for periodic timers.
    Returns: The timer instance (self) for chaining.
--]]
function CallLater:Start(delayMs)
    if self.active then self:Cancel() end

    -- Periodic timer path
    if self.interval then
        self.active = true
        self:_scheduleNext()
        return self
    end

    -- One‑shot timer path
    if not self.callback then return end
    local ms = delayMs or self.delay
    self.active = true
    self.timerId = zo_callLater(function() invokeLater(self) end, ms)
    return self
end

--[[
    timer:StartWithArgs(...)

    Starts a one-shot timer with specific arguments passed to the callback.

    Behavior: Stores the arguments and passes them to the callback upon execution.
    Restriction: Not supported for periodic timers (logs a warning if used).
    Parameters:
        ...: Variable arguments to pass to the callback.
    Returns: The timer instance.
--]]
function CallLater:StartWithArgs(...)
    if self.interval then
        d("[CallLater] StartWithArgs is not supported for periodic timers")
        return self
    end
    self.pendingArgs = { ... }
    return self:Start()
end

--------------------------------------------------------------------
-- Cancel / destroy
--------------------------------------------------------------------
--[[
    timer:Cancel()

    Stops the timer and clears all internal references.

    Behavior:
        Removes the underlying zo_callLater handle.
        Clears callback references, pending arguments, and retry counters.
    Returns: true if the timer was active and cancelled; false otherwise.
--]]
function CallLater:Cancel()
    if not self.active then return false end
    if self.timerId then zo_removeCallLater(self.timerId) end

    self.timerId          = nil
    self.active           = false
    self.maxTries         = nil
    self.attemptsMade     = nil
    self.pendingArgs      = nil
    self.callback         = nil
    self.periodicCallback = nil
    self.interval         = nil
    self._tickWrapper     = nil
    return true
end

--[[
    timer:Destroy()

    Alias for Cancel(). Returns nil after cleanup.
--]]
function CallLater:Destroy()
    self:Cancel()
    return nil
end

--------------------------------------------------------------------
-- Introspection & convenience
--------------------------------------------------------------------
--[[
    timer:IsRunning()

    Checks if the timer is currently active.

    Returns: true if active, false otherwise.
--]]
function CallLater:IsRunning()
    return self.active
end

--[[
    timer:SetCallback(newCallback)

    Replaces the callback function for future executions.

    Parameters: newCallback (function)
    Returns: The timer instance.
--]]
function CallLater:SetCallback(newCallback)
    self.callback = newCallback
    return self
end

--[[
    timer:SetDelay(newDelayMs)

    Updates the default delay for one-shot timers.

    Parameters: newDelayMs (number)
    Note: Changing the delay does not affect a currently running periodic timer.
    Returns: The timer instance.
--]]
function CallLater:SetDelay(newDelayMs)
    self.delay = newDelayMs
    -- Note: changing the delay does not affect a running periodic timer.
    return self
end