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
function CallLater:New(callback, delayMs)
    return setmetatable({
        callback      = callback,
        delay         = delayMs or 0,
        timerId       = nil,
        active        = false,
    }, self)
end

CallLater.NewSingle = CallLater.New

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

function CallLater:Destroy()
    self:Cancel()
    return nil
end

--------------------------------------------------------------------
-- Introspection & convenience
--------------------------------------------------------------------
function CallLater:IsRunning()
    return self.active
end

function CallLater:SetCallback(newCallback)
    self.callback = newCallback
    return self
end

function CallLater:SetDelay(newDelayMs)
    self.delay = newDelayMs
    -- Note: changing the delay does not affect a running periodic timer.
    return self
end