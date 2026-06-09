--[[
    HookManager is a registry-based utility designed to manage multiple ESO API hooks efficiently. 
    Instead of managing individual hook variables scattered throughout your code, this library allows 
    you to store hooks in a central manager instance. This enables powerful features like:

        Batch Control: Enable or disable all hooks at once (useful for toggling features).
        Dynamic State: Toggle individual hooks on/off without removing and re-registering them.
        Safety: Wraps callbacks in LibSFUtils.safeCall (for secure hooks) to prevent errors from breaking the game UI.
        Identification: Assigns unique IDs to every hook for easy retrieval and manipulation.

    Dependencies: Requires LibSFUtils (accessed via the global SF variable).
--]]
local SF = LibSFUtils


--=====================================================================
-- HookManager – a tiny registry that owns many hooks.
--=====================================================================

local HookManager = {}
HookManager.__index = HookManager
SF.HookManager = HookManager

--[[
    HookManager:New(basenm)

    Creates a new HookManager instance.

    Parameters:
        basenm (string, optional): A prefix string used to generate unique hook IDs. Defaults to "HookManager".
    Returns: A new HookManager table instance.
--]]
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
--[[
    Hook Creation Methods

    These methods register hooks immediately upon creation. 
    They return a hook table (an object representing the hook) which contains metadata and state.

    Note: All hooks are created with enabled = true by default, meaning they are active immediately 
        after registration.
--]]
--[[
    manager:PreHook(target, method, fn)

    Registers a Pre-Hook. The callback runs before the original function. 
        Returning true from the callback cancels the original function execution.

    Parameters:
        target (table): The object containing the method (e.g., MAIL_INBOX, _G).
        method (string): The name of the method to hook (case-sensitive).
        fn (function): The callback function. Signature matches the original 
            function.
    Returns: A hooktable object with properties: id, target, method, fn, 
        kind ("pre"), enabled.
--]]
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

--[[
    manager:PostHook(target, method, fn)

    Registers a Post-Hook. The callback runs after the original function. 
        The return value of the callback is ignored (cannot cancel the original).

    Parameters: Same as PreHook.
    Returns: A hooktable object with kind ("post").
--]]
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

--[[
    manager:SecurePostHook(target, method, fn)

    Registers a Secure Post-Hook. Used for secure functions (often related to combat or UI security). Errors in the callback are swallowed via SF.safeCall10 to prevent script errors.

    Parameters: Same as PreHook.
    Returns: A hooktable object with kind ("secure").
--]]
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
--[[
    Hook Table Properties

    The object returned by the creation methods contains:

        id: Unique string identifier (e.g., "HookManager_1").
        target: The target table.
        method: The method name.
        fn: The original callback function.
        kind: The hook type ("pre", "post", or "secure").
        enabled: Boolean indicating if the hook is currently active.
--]]

--[[
    manager:get(id)

    Retrieves the hook table for a specific ID.

    Returns: The hooktable or nil if not found.
--]]
function HookManager:get(id)
    --if not id then return nil end
    return self.hooks[id] or nil
end

--[[
    manager:enable(id)

    Activates a specific hook by hook id.

    Effect: Sets enabled = true. The callback will now fire.
--]]
function HookManager:enable(id)
    local h = self:get(id)
    if h then h.enabled = true end
end

--[[
    manager:disable(id)

    Deactivates a specific hook by hook id.

    Effect: Sets enabled = false. The callback is skipped, but the hook remains registered.
--]]
function HookManager:disable(id)
    local h = self:get(id)
    if h then h.enabled = false end
end

--[[
    manager:toggle(id)

    Switches the state of a specific hook by id.

    Effect: If active, disables it. If inactive, enables it.
--]]
function HookManager:toggle(id)
    local h = self:get(id)
    if h then h.enabled = not h.enabled end
end

--[[
    manager:remove(id)

    Completely removes a hook from the registry.

    Effect: Disables the hook (if active) and deletes it from the internal hooks table. 
    The ID becomes available for reuse.
--]]
function HookManager:remove(id)
    local h = self:get(id)
    if not h then return end
    if h.enabled then h.enabled = false end
    self.hooks[id] = nil
end

--[[
    manager:enableAll()

    Activates all registered hooks in the manager.
--]]
function HookManager:enableAll()
    for _, h in pairs(self.hooks) do
        h.enabled = true
    end
end


--[[
    manager:disableAll()

    Deactivates all registered hooks. 
    Useful for temporarily pausing all addon hook logic without unregistering hooks.
--]]
function HookManager:disableAll()
    for _, h in pairs(self.hooks) do
        h.enabled = false
    end
end

--[[
    manager:toggleAll()

    Flips the state of all registered hooks (active ↔ inactive).
--]]
function HookManager:toggleAll()
    for _, h in pairs(self.hooks) do
        h.enabled = not h.enabled
    end
end

--[[
    manager:describeAll()

    Prints a debug log for every registered hook.

        Output Format: [HookManager] <id> – <kind>.<method> (<status>)
        Status: ACTIVE or INACTIVE.
    Note: Uses AutoCategory.logDebug, so ensure that logging system is initialized.
    
function HookManager:describeAll()
    for id, h in pairs(self.hooks) do
        local status = h.enabled and "ACTIVE" or "INACTIVE"
        AutoCategory.logDebug(string.format("[HookManager] %s – %s.%s (%s)", tostring(id), tostring(h.kind), h.method, status))
    end
end
--]]

