local SF = LibSFUtils

local unpack = unpack

--=====================================================================
-- SingleHook – a tiny wrapper around ZO_PreHook / ZO_PostHook /
--                SecurePostHook
--=====================================================================
local SingleHookArgs = {}
SingleHookArgs.__index = SingleHookArgs
SF.SingleHookArgs = SingleHookArgs

--- Helper that builds the argument list for the user callback.
--- It concatenates: self, extraArgs..., originalParams..., (optionally) originalReturns...
--- returns a table of arguments
local function buildCallbackArgs(selfObj, extra, origParams, origRets)
    local args = { selfObj }               -- first argument is always the target (self)

    if extra then
        for i = 1, #extra do
            args[#args + 1] = extra[i]
        end
    end

    if origParams then
        for i = 1, #origParams do
            args[#args + 1] = origParams[i]
        end
    end

    if origRets then
        for i = 1, #origRets do
            args[#args + 1] = origRets[i]
        end
    end

    return args
end



--- Creates a new hook object.
--- @param target   table|string    The object that owns the method (e.g. MAIL_INBOX)
--- @param method   string   Name of the method to hook (case‑sensitive)
--- @param kind     string|function   "pre", "post", or "secure"
--- @param fn       function? Your callback. Signature depends on the kind:
---                     * pre‑hook:          (self, extra..., …) → return true to cancel original
---                     * post‑hook / secure: (self, extra..., …, originalRet…) → return new values
--- @param ... any     *(optional)* Extra arguments you want the hook to receive.
---                         Can be a single table or a vararg list.
--- @return table   A SingleHook instance.
function SingleHookArgs:New(target, method, kind, fn, ...)

    local targ = target
    local meth = method
    local knd = kind
    local func = fn
    local args
    if type(target) == string then
        -- target had been skipped in the argument list, so we are starting with "method"
        meth = target
        knd = method
        func = kind
        targ = _G       -- since not specified, assume _G
        args = {fn , ...}

    else
        args = {...}
    end


    assert(type(targ) == "table",   "SingleHookArgs: target must be a table")
    assert(type(meth) == "string",  "SingleHookArgs: method must be a string")
    assert(knd == "pre" or knd == "post" or knd == "secure",
           "SingleHookArgs: kind must be 'pre', 'post', or 'secure'")
    assert(type(fn) == "function",    "SingleHookArgs: fn must be a function")

    -- Normalise extra arguments into a flat list.
    local extra = args
    if #extra == 1 and type(extra[1]) == "table" then
        extra = extra[1]               -- treat a single table as the list of extras
    end

    -- create hook object
    local o = {
        target   = targ,        -- The object that owns the method (e.g. MAIL_INBOX)
        method   = meth,        -- Name of the method to hook (case‑sensitive)
        fn       = func,        -- Function signature depends on the kind
        extra    = extra,       -- stored extra arguments for the function
        original = targ[meth],  -- the original function that is being hooked
        enabled  = false,       -- has the hook been registered?
        hooked   = false,       -- have we already called the ESO hook API?
    }
    setmetatable(o, self)
    return o
end

function SingleHookArgs:NewPreHook(target, method, fn, ...)
    return self:New(target, method, "pre", fn, ...)
end

function SingleHookArgs:NewPostHook(target, method, fn, ...)
    return self:New(target, method, "post", fn, ...)
end
function SingleHookArgs:NewSecurePostHook(target, method, fn, ...)
    return self:New(target, method, "secure", fn, ...)
end

--- Enables (registers) the hook. Safe to call multiple times.
function SingleHookArgs:enable()
    if self.enabled then return end               -- already active, nothing to do

    -- *** Lazy registration ***
    -- The first time we enable the hook we actually call the ESO hook API.
    -- After that we only flip the `enabled` flag.
    if not self.hooked then
        local target = self.target
        local method = self.method
        local extra  = self.extra
        local cb     = self.fn

        if self.kind == "pre" then
            ZO_PreHook(target, method,
                function(...)
                    if not self.enabled then return end   -- guard against race‑conditions
                    local args = buildCallbackArgs(target, extra, { ... })
                    return cb(unpack(args))               -- true → cancel original
                end)

        elseif self.kind == "post" then
            ZO_PostHook(target, method,
                function(...)
                    if not self.enabled then return end
                    local origParams = { ... }
                    local origRets   = { target[method](target, unpack(origParams)) }
                    local args       = buildCallbackArgs(target, extra, origParams, origRets)
                    return cb(unpack(args))               -- replace returns
                end)

        elseif self.kind == "secure" then
            SecurePostHook(target, method,
                function(...)
                    if not self.enabled then return end
                    local origParams = { ... }
                    local origRets   = { target[method](target, unpack(origParams)) }
                    local args       = buildCallbackArgs(target, extra, origParams, origRets)

                    -- Use pcall to swallow errors (replace SF.safeCall if you have one)
                    local ok, ret = SF.safeCall(cb, unpack(args))
                    if not ok then
                        d("[SingleHook] secure post‑hook error: " .. tostring(ret))
                    end
                    return unpack(origRets)                -- always return original values
                end)

        else
            error("Unsupported hook kind: " .. tostring(self.kind))
        end

        self.hooked = true                         -- we have now called the ESO API once
    end

    self.enabled = true
end

--- Enables (registers) the hook. Safe to call multiple times.
--- Disables (unregisters) the hook. Safe to call multiple times.
function SingleHookArgs:disable()
    if not self.enabled then return end

    -- There is no native “unhook” call in the ESO API.  We simply mark the
    -- wrapper as disabled; the underlying hook stays registered but will
    -- ignore its result because our wrapper no longer forwards anything.
    self.enabled = false
end

--- Calls the *original* (unhooked) method directly.
--- Useful when you need the vanilla behaviour from inside your hook.
function SingleHookArgs:callOriginal(...)
    return self.original(self.target, ...)
end

--- Convenience: toggle the hook on/off.
function SingleHookArgs:toggle()
    if self.enabled then
        self:disable()

    else
        self:enable()
    end
end

--- Debug helper – prints a one‑liner describing the hook.
function SingleHookArgs:describe()
    local status = self.enabled and "ENABLED" or "DISABLED"
    d(string.format("[SingleHookArgs] %s %s.%s (%s)",
        status, tostring(self.target), self.method, self.kind))
end


--[[
Usage Example:

local function OnHealthChange(self, newHealth)
    d("[MyAddon] Health will become " .. tostring(newHealth))
    return false               -- do not cancel the original change
end

local healthHook = SingleHookArgs:NewPreHook(PLAYER, "SetHealth", OnHealthChange)

healthHook:enable()   -- registers the hook (only once)
healthHook:describe() -- prints "[SingleHookArgs] ENABLED PLAYER.SetHealth (pre)"

-- Later you can turn it off/on:
healthHook:disable()
healthHook:enable()


Now the heavy lifting (calling the ESO hook API) happens a single time per SingleHookArgs
instance, while you can freely enable/disable the wrapper as often as you like.
--]]