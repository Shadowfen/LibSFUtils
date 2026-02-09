local SF = LibSFUtils


--=====================================================================
-- HookManager – a tiny registry that owns many hooks.
--=====================================================================

local HookManager = {}
HookManager.__index = HookManager
SF.HookManager = HookManager

--- Creates a fresh manager instance.
--- @return table  A new HookManager.
function HookManager:New(basenm)
    local o = {
        base = basenm or "HookManager",
        cnt = 1,
        hooks = {},          -- id → hooktable instance
    }
    setmetatable(o, self)
    return o
end

-- ---------------------------------------------------------------------
-- PUBLIC API
-- ---------------------------------------------------------------------
--- @param target      table      Object that owns the method (e.g. MAIL_INBOX)
--- @param method      string     Name of the method to hook
--- @param fn          function   Your callback
--- @return hooktable  table      contains the id, the target, the method, the function, the type ("pre", "post", "secure") and if enabled
function HookManager:PreHook(target, method, fn)
    local id = SF.str(self.base, self.cnt)
    if self.hooks[id] then return nil end


    -- create hook object
    local o = {
        id       = id,
        target   = target,    -- The object that owns the method (e.g. MAIL_INBOX)
        method   = method,    -- Name of the method to hook (case‑sensitive)
        fn       = fn,        -- Function signature depends on the kind
        kind     = "pre",
        enabled  = false,     -- has the hook been registered?
    }
    setmetatable(o, self)

    --wrap the callback function with a disable
    ZO_PreHook(target, method,
        function(...)
            local enabled = o.enabled
            if not enabled then return end   -- guard against race‑conditions
            return fn(...)               -- true → cancel original
        end)
    self.hooks[id] = o
    self.cnt = self.cnt + 1
    o.enabled  = true       -- has the hook been registered?

    return o
end

--- @param target      table      Object that owns the method (e.g. MAIL_INBOX)
--- @param method      string     Name of the method to hook
--- @param fn          function   Your callback (signature follows SingleHookArg docs)
--- @return hooktable  table      contains the id, the target, the method, the function, the type ("pre", "post", "secure") and if enabled
function HookManager:PostHook(target, method, fn)
    local id = SF.str(self.base, self.cnt)
    if self.hooks[id] then return nil end
    self.cnt = self.cnt + 1


    -- create hook object
    local o = {
        id       = id,
        target   = target,        -- The object that owns the method (e.g. MAIL_INBOX)
        method   = method,        -- Name of the method to hook (case‑sensitive)
        fn       = fn,        -- Function signature depends on the kind
        kind     = "post",
        enabled  = false,       -- has the hook been registered?
    }
    setmetatable(o, self)

    if self.hooks[id] then return nil end
    --wrap the callback function with a disable
    ZO_PostHook(target, method,
        function(...)
            if not o.enabled then return end   -- guard against race‑conditions
            return fn(...)               -- true → cancel original
        end)
    self.hooks[id] = o
    o.enabled = true
    return o
end

--- @param target      table      Object that owns the method (e.g. MAIL_INBOX)
--- @param method      string     Name of the method to hook
--- @param fn          function   Your callback (signature follows SingleHookArg docs)
--- @return hooktable  table      contains the id, the target, the method, the function, the type ("pre", "post", "secure") and if enabled
function HookManager:SecurePostHook(target, method, fn)
    local id = SF.str(self.base, self.cnt)
    --if self.hooks[id] then return nil end
    self.cnt = self.cnt + 1


    -- create hook object
    local o = {
        id       = id,
        target   = target,        -- The object that owns the method (e.g. MAIL_INBOX or _G)
        method   = method,        -- Name of the method to hook (case‑sensitive)
        fn       = fn,            -- Function signature depends on the method being trailed
        kind     = "secure",
        enabled  = false,       -- has the hook been registered?
    }
    setmetatable(o, self)

    --if self.hooks[id] then return nil end
    --wrap the callback function with a disable
    SecurePostHook(target, method, 
        function(...)
            if not o.enabled then return end

            -- Use safeCall to swallow errors
            SF.safeCall10(fn, ...)
        end)--]]
    self.hooks[id] = o
    o.enabled  = true

    return o
end

--- Retrieves a stored hook (or nil if it doesn't exist).
--- @param id any
---
--- @return table|nil
function HookManager:get(id)
    --if not id then return nil end
    return self.hooks[id] or nil
end

--- Enables a single hook by *id*.
function HookManager:enable(id)
    local h = self:get(id)
    if h then h.enabled = true end
end

--- Disables a single hook by *id*.
function HookManager:disable(id)
    local h = self:get(id)
    if h then h.enabled = false end
end

--- Toggles a single hook by *id* (registered ↔ unregistered).
function HookManager:toggle(id)
    local h = self:get(id)
    if h then h.enabled = not h.enabled end
end

--- Removes a hook completely. If it is active it will be disabled first.
--- After removal the *id* is free to be reused.
function HookManager:remove(id)
    local h = self:get(id)
    if not h then return end
    if h.enabled then h.enabled = false end
    self.hooks[id] = nil
end

--- Registers **all** collected hooks.
function HookManager:enableAll()
    for _, h in pairs(self.hooks) do
        h.enabled = true
    end
end

--- Disables **all** registered hooks.
function HookManager:disableAll()
    for _, h in pairs(self.hooks) do
        h.enabled = false
    end
end

--- Toggles **all** hooks (registered → unregistered, unregistered → registered).
function HookManager:toggleAll()
    for _, h in pairs(self.hooks) do
        h.enabled = not h.enabled
    end
end

--- Prints a short description for every stored hook.
--- Useful for debugging or confirming that hooks are correctly registered.
function HookManager:describeAll()
    for id, h in pairs(self.hooks) do
        local status = h.enabled and "ACTIVE" or "INACTIVE"
        AutoCategory.logDebug(string.format("[HookManager] %s – %s.%s (%s)", tostring(id), tostring(h.kind), h.method, status))
    end
end
