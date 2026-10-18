--[[ CallLater is a robust timer utility library designed to manage delayed 
        and periodic function execution. 
     It wraps the native zo_callLater API to provide features like automatic 
        retry on failure, argument passing, periodic scheduling, and safe cleanup.

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
        One-shot with retries: The timer waits for the delay and retries until maxTries (total executions) is reached.
        Periodic: Logs the error via d("[PeriodicTimer] callback error: ...") and continues the next tick.
        Standard One-shot: The error is logged, and the timer stops without retrying.

--]]
-- Dependencies
local SF = LibSFUtils
assert(SF, "LibSFUtils_Global must be loaded before this file")

local SF_safeCall = SF.safeCall       -- loaded with LibSFUtils.lua
assert(SF_safeCall, "LibSFUtils must be loaded before this file")

--
SF.CallLater = {}
local CallLater = SF.CallLater
CallLater.__index = CallLater

--------------------------------------------------------------------
-- Internal helper that runs the user callback and handles retries.
--------------------------------------------------------------------
--[[ invokeLater(self)

    Executes a one-shot timer's callback and handles automatic retries.

    Behavior:
        Clears the current timer handle and marks the timer inactive before
        invoking the callback.
        Increments attemptsMade for each callback execution.
        Passes pendingArgs to the callback, or no arguments if none were set.
        Executes the callback through SF.safeCall to catch and report errors.
        If the callback fails and maxTries has not been reached, schedules
        another attempt after the configured delay.

    Retry handling:
        maxTries specifies the maximum total number of callback executions,
        including the initial attempt.
        Retries preserve pendingArgs and the current attempt count.
        Successful execution or exhausted retries ends the current run.
        A callback may schedule another invocation; automatic retry scheduling
        must not replace an invocation already scheduled by the callback.

    State:
        Does not clear pendingArgs after execution, allowing Start() to reuse
        the last arguments.
        Does not reset attemptsMade after execution; Start() resets it when
        beginning a new run.

    Parameters:
        self (CallLater): The timer instance.

    Returns:
        Nothing.
--]]
local function invokeLater(self)
    -- This scheduled invocation has begun.
    self.timerId = nil
    self.active = false

    if self.destroyed or not self.callback then return end

    self.attemptsMade = (self.attemptsMade or 0) + 1

    -- Capture the callback and arguments for this invocation.
    local callback = self.callback
    local args = self.pendingArgs or {}

    local ok, err = SF_safeCall(callback, unpack(args))

    if not ok then
        d("[CallLater] callback error: " .. tostring(err))

        -- Retry only when explicitly configured to do so.
        -- Do not duplicate a timer already scheduled by the callback.
        if not self.destroyed
            and not self.active
            and self.maxTries ~= nil
            and self.attemptsMade < self.maxTries
        then
            self:_scheduleOneShot(self.delay)
        end
    end

    -- Do not clear pendingArgs: Start() reuses the last arguments.
    -- Do not reset attemptsMade here: a new Start() owns that reset.
end


--------------------------------------------------------------------
-- Constructors
--------------------------------------------------------------------
--[[ CallLater:New(callback, delayMs)
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
        destroyed    = false,
    }, self)
end

CallLater.NewSingle = CallLater.New

--[[ CallLater:NewMaxTries(callback, delayMs, maxTries)

    Creates a one-shot timer with automatic retry logic if the callback fails.

    Parameters:
        callback (function): The function to execute.
        delayMs (number, optional): Delay in milliseconds.
        maxTries (number): Maximum number of retry attempts if the callback throws an error.
    Returns: A new CallLater instance configured for retries.
--]]
function CallLater:NewMaxTries(callback, delayMs, maxTries)
    if type(maxTries) ~= "number" or maxTries < 0 then maxTries = 0 end
    if type(maxTries) ~= "number" or maxTries ~= maxTries or maxTries < 0
        or maxTries == math.huge or maxTries == -math.huge  
    then
        maxTries = 0
    end
    return setmetatable({
        callback      = callback,
        delay         = delayMs or 0,
        timerId       = nil,
        active        = false,
        maxTries      = math.floor(maxTries),
        attemptsMade  = 0,
        pendingArgs   = nil,
        destroyed    = false,
    }, self)
end

--[[ CallLater:NewTimer(callback, intervalMs)

    Creates a periodic timer that executes repeatedly.

    Parameters:
        callback (function): The function to execute on every tick.
        intervalMs (number): Interval in milliseconds between executions.
    Returns: A new CallLater instance configured as a periodic timer.
--]]
function CallLater:NewTimer(callback, intervalMs)
    if type(intervalMs) ~= "number" or intervalMs ~= intervalMs or intervalMs < 0
    then
        d("[CallLater] NewTimer requires a positive, finite interval")
        return nil
    end
    return setmetatable({
        periodicCallback = callback,   -- distinct from one‑shot `callback`
        interval         = intervalMs,
        timerId          = nil,
        active           = false,
        destroyed    = false,
    }, self)
end

--[[ CallLater:ScheduleNext(delayMs)

    Schedules another one-shot callback within the current run without
    resetting the attempt counter.

    Behavior:
        Returns without scheduling if the timer has been destroyed or is a
        periodic timer.
        Returns without scheduling if the callback is missing.
        Enforces maxTries by refusing to schedule another invocation when
        the maximum total number of callback executions has been reached.
        Removes any previously scheduled invocation before scheduling the
        next one.
        Uses delayMs when provided; otherwise, uses the timer's configured
        default delay.

    Notes:
        Unlike Start(), this method does not reset attemptsMade.
        Scheduled invocations count toward maxTries when they execute.
        Intended for callback-driven rescheduling, such as readiness polling.

    Parameters:
        delayMs (number, optional): Delay in milliseconds before the next
            callback execution. Defaults to the timer's configured delay.

    Returns:
        The timer instance (self) for method chaining.
--]]
function CallLater:ScheduleNext(delayMs)
    if self.destroyed or self.interval ~= nil then
        return self
    end

    if not self.callback then return self end

    -- Respect the total execution limit.
    if self.maxTries ~= nil
        and (self.attemptsMade or 0) >= self.maxTries
    then
        self.active = false
        return self
    end

    -- Replace any already scheduled invocation.
    if self.timerId then
        zo_removeCallLater(self.timerId)
        self.timerId = nil
    end

    return self:_scheduleOneShot(delayMs)
end
--------------------------------------------------------------------
-- Internal periodic‑timer scheduler (private)
--------------------------------------------------------------------
--[[ CallLater:_scheduleNext()

    Schedules the next execution of a periodic timer's callback.

    Behavior:
        Returns immediately if the timer has been destroyed or is not active.
        Stops the timer if its periodic callback is missing.
        Schedules the callback using zo_callLater with the configured interval.
        Executes the callback through SF.safeCall and logs any errors.
        Automatically schedules the next tick after execution, unless the
        callback cancelled or restarted the timer, or the timer was destroyed.

    Reentrancy:
        The callback may call Cancel() or Start() while executing.
        Before scheduling another tick, this method checks the timer's state
        and verifies that no other tick has already been scheduled.

    Returns:
        Nothing.
--]]
function CallLater:_scheduleNext()
    if self.destroyed or not self.active then return end
    if not self.periodicCallback then
        self.active = false
        self.timerId = nil
        return
    end

    self.timerId = zo_callLater(function()
        self.timerId = nil

        if self.destroyed or not self.active then return end

        local callback = self.periodicCallback
        if not callback then
            self.active = false
            return
        end

        local ok, err = SF_safeCall(callback)
        if not ok then
            d("[PeriodicTimer] callback error: " .. tostring(err))
        end

        -- The callback may have cancelled or restarted the timer.
        -- Schedule another tick only if one wasn't already scheduled.
        if self.active and not self.destroyed and not self.timerId then
            self:_scheduleNext()
        end
    end, self.interval)
end

--[[ CallLater:_scheduleOneShot(delayMs)

    Schedules a one-shot timer callback for execution after the specified
    delay.

    Behavior:
        Returns without scheduling if the timer has been destroyed or its
        callback is missing, marking the timer inactive.
        Otherwise, marks the timer active and schedules invokeLater(self)
        using zo_callLater.
        Uses delayMs when provided; otherwise, uses the timer's configured
        default delay.
        Does not reset attemptsMade, allowing retries and callback-driven
        scheduling to continue the current run's attempt count.

    Parameters:
        delayMs (number, optional): Delay in milliseconds before execution.
            Defaults to the timer's configured delay.

    Returns:
        The timer instance (self) for method chaining.
--]]
function CallLater:_scheduleOneShot(delayMs)
    if self.destroyed or not self.callback then
        self.active = false
        return self
    end

    self.active = true
    self.timerId = zo_callLater(function()
        invokeLater(self)
    end, delayMs or self.delay)

    return self
end

--------------------------------------------------------------------
-- Public start / start‑with‑args
--------------------------------------------------------------------
--[[ timer:Start(delayMs)

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
    if self.destroyed then return self end

    -- Cancel any currently scheduled invocation.
    if self.timerId then
        zo_removeCallLater(self.timerId)
        self.timerId = nil
    end

    self.active = false

    -- Periodic timer path.
    if self.interval ~= nil then
        if not self.periodicCallback then return self end

        self.active = true
        self:_scheduleNext()
        return self
    end

    -- One-shot timer path.
    if not self.callback then return self end

    -- Every Start() begins a new run.
    self.attemptsMade = 0

    -- Zero means no callback executions.
    if self.maxTries ~= nil and self.maxTries == 0 then
        return self
    end

    return self:_scheduleOneShot(delayMs)
end


--[[ timer:StartWithArgs(...)

    Starts a timer with specific arguments passed to the callback.

    Behavior: Stores the arguments and passes them to the callback upon execution.
    Restriction: Not supported for periodic timers (logs a warning if used).
    Parameters:
        ...: Variable arguments to pass to the callback.
    Returns: The timer instance.
--]]
function CallLater:StartWithArgs(...)
    if self.destroyed then return self end

    if self.interval then
        d("[CallLater] StartWithArgs is not supported for periodic timers")
        self.pendingArgs = nil
        return self
    end
    self.pendingArgs = { ... }
    return self:Start()
end

--------------------------------------------------------------------
-- Cancel / destroy
--------------------------------------------------------------------
--[[ timer:Cancel()

    Stops the timer. It can still be started again.

    Behavior:
        Removes the underlying zo_callLater handle.
    Returns: true if the timer was active and cancelled; false otherwise.
--]]
function CallLater:Cancel()
    local wasActive = self.active == true
    self.active = false

    if self.timerId then
        zo_removeCallLater(self.timerId)
        self.timerId = nil
    end

    self.attemptsMade = 0

    return wasActive
end

--[[ timer:Destroy()
    Stops the timer and destroys/clears the instance so that it cannot be reused.
--]]
function CallLater:Destroy()
    if self.timerId then zo_removeCallLater(self.timerId) end

    --  Can no longer start by design.
    self.timerId          = nil
    self.active           = false
    self.destroyed        = true
    self.maxTries         = nil
    self.attemptsMade     = nil
    self.pendingArgs      = nil
    self.callback         = nil
    self.periodicCallback = nil
    self.interval         = nil
    self._tickWrapper     = nil
    return nil
end


--------------------------------------------------------------------
-- Introspection & convenience
--------------------------------------------------------------------
--[[ timer:IsRunning()

    Checks if the timer is currently active.

    Returns: true if active, false otherwise.
--]]
function CallLater:IsRunning()
    return self.active
end

--[[ timer:SetCallback(newCallback)

    Replaces the callback function for future executions.

    Parameters: newCallback (function)
    Returns: The timer instance.
--]]
function CallLater:SetCallback(newCallback)
    self.callback = newCallback
    return self
end

--[[ timer:SetDelay(newDelayMs)

    Updates the default delay for one-shot timers.

    Parameters: newDelayMs (number)
    Note: Changing the delay does not affect a currently running periodic timer.
    Returns: The timer instance.
--]]
function CallLater:SetDelay(newDelayMs)
    if type(newDelayMs) == "number" then
        self.delay = newDelayMs
    end
    -- Note: changing the delay does not affect a running periodic timer.
    return self
end