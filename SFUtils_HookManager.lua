local SF = LibSFUtils
--=====================================================================
-- HookManager – a tiny registry that owns many SingleHook objects.
--=====================================================================

local HookManager = {}
HookManager.__index = HookManager
SF.HookManager = HookManager

local SingleHookArgs = SF.SingleHookArgs    -- local alias

--- Creates a fresh manager instance.
--- @return table  A new HookManager.
function HookManager:New()
    local o = {
        hooks = {},          -- id → SingleHook instance
    }
    setmetatable(o, self)
    return o
end

-----------------------------------------------------------------------
-- INTERNAL HELPERS
-----------------------------------------------------------------------

--- Normalises the identifier (allows numbers, strings, or any hashable value).
local function normId(id)
    assert(id ~= nil, "HookManager: id cannot be nil")
    return id
end

-----------------------------------------------------------------------
-- PUBLIC API
-----------------------------------------------------------------------

--- Adds a new SingleHook and stores it under *id*.
--- @param id          any        Identifier you will use later (string is typical)
--- @param kind        string     "pre", "post", or "secure"
--- @param target      table      Object that owns the method (e.g. MAIL_INBOX)
--- @param method      string     Name of the method to hook
--- @param fn          function   Your callback (signature follows SingleHookArg docs)
--- @param ...         any        *(optional)* Extra arguments you want the hook to receive
---
--- @return id         The id assigned to the created SingleHookArg (also stored internally)
--- @return table      The created SingleHookArg (also stored internally)
function HookManager:add(id, kind, target, method, fn, ...)
    id = normId(id)

    assert(not self.hooks[id], ("HookManager: Hook with id '%s' already exists"):format(tostring(id)))

    local hook = SingleHookArgs:New(target, method, kind, fn, ...)
    self.hooks[id] = hook
    return id, hook
end

--- Adds a new SingleHook and stores it under *id*.
--- @param id          any        Identifier you will use later (string is typical)
--- @param singlehook  table      Instance of a pre-created SingleHookArgs
---
--- @return id         The id assigned to the stored SingleHookArg (also stored internally)
--- @return table      The provided SingleHookArg (also stored internally)
function HookManager:addHook(id, singlehook)
    id = normId(id)

    assert(not self.hooks[id], ("HookManager: Hook with id '%s' already exists"):format(tostring(id)))

    self.hooks[id] = singlehook
    return id, singlehook
end

--- Retrieves a stored hook (or nil if it doesn't exist).
--- @param id any
--- 
--- @return table|nil
function HookManager:get(id)
    return self.hooks[normId(id)]
end

--- Enables a single hook by *id*.
function HookManager:enable(id)
    local h = self:Get(id)
    if h then h:enable() end
end

--- Disables a single hook by *id*.
function HookManager:disable(id)
    local h = self:Get(id)
    if h then h:disable() end
end

--- Toggles a single hook by *id* (registered ↔ unregistered).
function HookManager:toggle(id)
    local h = self:Get(id)
    if h then h:toggle() end
end

--- Removes a hook completely. If it is active it will be disabled first.
--- After removal the *id* is free to be reused.
function HookManager:remove(id)
    local h = self:Get(id)
    if not h then return end
    if h:isActive() then h:disable() end
    self.hooks[id] = nil
end

--- Registers **all** collected hooks.
function HookManager:enableAll()
    for _, h in pairs(self.hooks) do
        h:enable()
    end
end

--- Disables **all** registered hooks.
function HookManager:disableAll()
    for _, h in pairs(self.hooks) do
        h:disable()
    end
end

--- Toggles **all** hooks (registered → unregistered, unregistered → registered).
function HookManager:toggleAll()
    for _, h in pairs(self.hooks) do
        h:toggle()
    end
end

--- Prints a short description for every stored hook.
--- Useful for debugging or confirming that hooks are correctly registered.
function HookManager:describeAll()
    for id, h in pairs(self.hooks) do
        local status = h:isActive() and "ACTIVE" or "INACTIVE"
        d(string.format("[HookManager] %s – %s.%s (%s)", tostring(id), tostring(h.target), h.method, status))
    end
end
