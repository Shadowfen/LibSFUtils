--[[
    HookManager is a registry-based utility designed to manage multiple ESO API hooks efficiently. 
    Instead of managing individual hook variables scattered throughout your code, this library allows 
    you to store hooks in a central manager instance. This enables powerful features like:

        Batch Control: Enable or disable all hooks at once (useful for toggling features).
        Dynamic State: Toggle individual hooks on/off without removing and re-registering them.
        Safety: Wraps callbacks in LibSFUtils.safeCall10 (for secure hooks) to prevent errors from breaking the game UI.
        Identification: Assigns unique IDs to every hook for easy retrieval and manipulation.
--]]
-- Dependencies
local SF = LibSFUtils
assert(SF, "LibSFUtils_Global must be loaded before this file")

local SF_safeCall10 = SF.safeCall10 
assert(SF_safeCall10, "LibSFUtils must be loaded before this file")
local SF_str = SF.str       -- also loaded with LibSFUtils.lua


local function createHook(manager, kind, target, method, fn)
    local id = SF_str(manager.base, manager.cnt)

    manager.cnt = manager.cnt + 1

    local hook = {
        id      = id,
        target  = target,
        method  = method,
        fn      = fn,
        kind    = kind,
        enabled = false,
    }

    manager.hooks[id] = hook
    return hook
end

local function wrapFunc(hook, invoke)
    return function(...)
        if not hook.enabled then
            return
        end
        return invoke(...)
    end
end
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
    local hook = createHook(self, "pre", target, method, fn)

    ZO_PreHook(target, method, wrapFunc(hook, hook.fn))

    hook.enabled = true
    return hook
end

--[[
    manager:PostHook(target, method, fn)

    Registers a Post-Hook. The callback runs after the original function. 
        The return value of the callback is ignored (cannot cancel the original).

    Parameters: Same as PreHook.
    Returns: A hooktable object with kind ("post").
--]]
function HookManager:PostHook(target, method, fn)
    local hook = createHook(self, "post", target, method, fn)

    ZO_PostHook(target, method, wrapFunc(hook, hook.fn))

    hook.enabled = true
    return hook
end

--[[
    manager:SecurePostHook(target, method, fn)

    Registers a Secure Post-Hook. Used for secure functions (often related to combat or UI security). Errors in the callback are swallowed via SF_safeCall10 to prevent script errors.

    Parameters: Same as PreHook.
    Returns: A hooktable object with kind ("secure").
--]]
function HookManager:SecurePostHook(target, method, fn)
    local hook = createHook(self, "secure", target, method, fn)

    --wrap the callback function with a disable
    SecurePostHook(target, method, wrapFunc(hook,
        function(...)
            SF_safeCall10(hook.fn, ...)
        end))

    hook.enabled = true
    return hook
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

