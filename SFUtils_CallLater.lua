local SF = LibSFUtils
--========================================================
-- CallLater – a tiny wrapper around zo_callLater / zo_removeCallLater
--=========================================================
SF.CallLater = {}
local CallLater = SF.CallLater
CallLater.__index = CallLater

--- Internal wrapper that clears the state *before* invoking the user callback.
-- This mirrors the behaviour of `zo_callLater`: the timer is considered
-- finished the instant the callback begins.
--- Internal helper invokes the user callback with the stored args.
local function invokeLater(self, ...)
    -- clear the stored handle first – the timer is no longer pending
    self.timerId = nil
    self.active  = false

    local args = self.pendingArgs or {}
    self.pendingArgs = nil   -- clear so a stale argument list isn’t reused

    -- protect the user callback from errors so the add‑on doesn’t explode
    if not self.callback then return end
    local ok, err = SF.safeCall(self.callback, unpack(args))
    if not ok then
        d("[CallLater] callback error: " .. tostring(err))
   end
end

--- Constructor.
-- @param callback  function to be executed after the delay or nil
-- @param delayMs   delay in milliseconds (default 0 → immediate).
-- @return a new CallLater instance (not started yet).
function CallLater:New(callback, delayMs)
    local o = setmetatable({
        callback = callback,
        delay    = delayMs or 0,
        timerId  = nil,          -- nil → no pending timer
        active  = false,        -- true while a timer is pending
    }, CallLater)
    return o
end

--- Starts (or restarts) the timer.
-- If a timer is already pending it is cancelled first.
-- @param delayMs (optional) override the delay for this start only.
function CallLater:Start(delayMs)
    -- Cancel any existing pending timer
    if self.active then self:Cancel() end
    if not self.callback then return end

    local ms = delayMs or self.delay
    self.active = true

    -- Store the handle so we can cancel later
    self.timerId = zo_callLater(function() invokeLater(self) end, ms)
    return self
end

--- Start the timer **and** remember any arguments you pass.
--- Those arguments will be forwarded to the user callback when it runs.
--- @param ... any number of arguments that will be passed to the callback
function CallLater:StartWithArgs(...)
    self.pendingArgs = { ... }   -- stash them in the object
    return self:Start()           -- reuse the existing start logic
end

--- Cancels the pending timer, if any.
-- After calling this the object is in a “not‑running” state.
function CallLater:Cancel()
    if not self.active then return false end
    if self.timerId then
        zo_removeCallLater(self.timerId)
    end
    self.timerId = nil
    self.active  = false
    return true
end

--- Destructor‑style helper – call this from your add‑on’s Shutdown /
--- OnAddOnUnloaded to guarantee no stray callbacks remain.
function CallLater:Destroy()
    self:Cancel()
    self.callback = nil
    return nil
end

--- Returns true if a timer is currently scheduled.
function CallLater:IsRunning()
    return self.active
end

--- Convenience: replace the stored callback (keeps the same delay).
-- Useful when you want to reuse the same CallLater object for several
-- different actions.
-- @param newCallback  function
function CallLater:SetCallback(newCallback)
    assert(type(newCallback) == "function", "SetCallback needs a function")
    self.callback = newCallback
    return self
end

--- Convenience: change the default delay (does not affect a timer that is
--- already running – you must call :Start() again to use the new delay).
-- @param newDelayMs  number
function CallLater:SetDelay(newDelayMs)
    assert(type(newDelayMs) == "number" and newDelayMs >= 0,
           "SetDelay neds a non‑negative number")
    self.delay = newDelayMs
    return self
end

