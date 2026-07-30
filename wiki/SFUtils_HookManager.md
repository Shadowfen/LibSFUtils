# SFUtils.HookManager

`SFUtils.HookManager` is a lightweight registry for managing multiple **ESO API hooks** from a single object.

Rather than tracking hook handles throughout your addon, `HookManager` stores each hook in a central registry, allowing you to enable, disable, retrieve, or remove hooks individually or as a group.

Hooks created by `HookManager` remain permanently registered with the game just as the ESO hooks do.  ESO's hook APIs do not provide any mechanism to unregister or remove a hook once it has been installed.

The HookManager-created hook wraps the hook function with an enable/disable capability. Enabling or disabling a hook simply determines whether its callback can execute.

---

# Features

- Centralized hook registry
- Unique hook identifiers
- Pre-hooks
- Post-hooks
- Secure post-hooks
- Enable or disable individual hooks
- Enable or disable all hooks simultaneously
- Toggle hook state without re-registering
- Safe execution for secure hooks using `LibSFUtils.safeCall10`

---

# Creating a Hook Manager

Create a manager instance before registering hooks.

```lua
local hooks = SF.HookManager:New()
```

Optionally specify a base name used when generating hook IDs.

```lua
local hooks = SF.HookManager:New("Inventory")
```

Generated IDs look like:

```
Inventory1
Inventory2
Inventory3
```

## Syntax

```lua
HookManager:New(baseName)
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `baseName` | string | Optional prefix used when generating hook IDs. Defaults to `"HookManager"`. |

### Returns

A new `HookManager` instance.

---

# Registering Hooks

Hooks are registered immediately when created and are enabled by default.

---

## PreHook()

Registers a callback that executes **before** the original function.

Returning `true` prevents the original function from executing.

```lua
hooks:PreHook(MAIL_INBOX, "RefreshMailList", function(...)
    d("Refreshing mail")

    return false
end)
```

### Syntax

```lua
manager:PreHook(target, method, callback)
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `target` | table | Object containing the method. |
| `method` | string | Method name. |
| `callback` | function | Callback executed before the original function. |

### Returns

A hook object.

---

## PostHook()

Registers a callback that executes **after** the original function.

The callback's return value is ignored.

```lua
hooks:PostHook(ZO_PlayerInventory, "RefreshInventory", function(...)
    d("Inventory refreshed")
end)
```

### Syntax

```lua
manager:PostHook(target, method, callback)
```

Returns a hook object.

---

## SecurePostHook()

Registers a secure post-hook.

The callback executes through `LibSFUtils.safeCall10()`, preventing Lua errors from propagating into the game UI.

```lua
hooks:SecurePostHook(ZO_PlayerInventory, "RefreshInventory", function(...)
    UpdateAddonUI()
end)
```

### Syntax

```lua
manager:SecurePostHook(target, method, callback)
```

Returns a hook object.

---

# Hook Objects

Every registration function returns a hook object.

Example:

```lua
local hook = hooks:PostHook(...)
```

The returned object contains the following fields.

| Property | Description |
|----------|-------------|
| `id` | Unique hook identifier. |
| `target` | Object being hooked. |
| `method` | Hooked method name. |
| `fn` | Original callback function. |
| `kind` | `"pre"`, `"post"`, or `"secure"`. |
| `enabled` | Indicates whether the callback executes. |

---

# Retrieving Hooks

Retrieve a hook by its identifier.

```lua
local hook = hooks:get(id)
```

## Syntax

```lua
manager:get(id)
```

### Returns

The hook object or `nil`.

---

# Enabling and Disabling Hooks

## enable()

Enables a hook.

```lua
hooks:enable(id)
```

The callback will execute the next time the hooked function is called.

---

## disable()

Disables a hook.

```lua
hooks:disable(id)
```

The underlying ESO hook remains registered, but the callback execution is skipped.

---

## toggle()

Toggles the enabled state.

```lua
hooks:toggle(id)
```

---

# Batch Operations

## enableAll()

Enables every registered hook.

```lua
hooks:enableAll()
```

---

## disableAll()

Disables every registered hook.

```lua
hooks:disableAll()
```

Useful for temporarily suspending addon functionality.

---

## toggleAll()

Flips the enabled state of every hook.

```lua
hooks:toggleAll()
```

---

# Removing Hooks

## remove()

Removes a hook from the manager registry.

```lua
hooks:remove(id)
```

### Behavior

Removing a hook:

- disables it
- removes it from the registry

### Important

Removing a hook **does not unregister the underlying ESO hook**.

Because ESO's hook APIs do not provide an unregister mechanism, the wrapper callback remains installed. Since the hook object is removed from the registry and marked disabled, the callback immediately exits without executing user code.

---

# Hook Lifecycle

```
Create Manager
      │
      ▼
Register Hook
      │
      ▼
Enabled
      │
      ├─────────────┐
      │             │
      ▼             ▼
 Disabled       Callback Executes
      │             │
      └──────┬──────┘
             ▼
          remove()
             │
             ▼
      Removed from Registry
```

---

# Error Handling

## PreHook

Callbacks execute directly.

Any Lua errors propagate normally.

---

## PostHook

Callbacks execute directly.

Any Lua errors propagate normally.

---

## SecurePostHook

Callbacks execute through

```lua
LibSFUtils.safeCall10()
```

Errors are trapped and do not interrupt game execution.

---

# Typical Usage

## Enable and Disable Features

```lua
local hooks = SF.HookManager:New()

local inventoryHook =
    hooks:PostHook(
        ZO_PlayerInventory,
        "RefreshInventory",
        function()
            UpdateInventoryDisplay()
        end
    )

hooks:disable(inventoryHook.id)

-- Later...

hooks:enable(inventoryHook.id)
```

---

## Temporarily Disable an Addon

```lua
hooks:disableAll()

-- ...

hooks:enableAll()
```

---

## PreHook Example

```lua
hooks:PreHook(MAIL_INBOX, "Delete", function(...)
    if not CanDeleteMail() then
        return true
    end
end)
```

Returning `true` prevents the original function from executing.

---

## Secure Hook Example

```lua
hooks:SecurePostHook(ZO_PlayerInventory, "RefreshInventory", function(...)
    RefreshCustomUI()
end)
```

---

# API Summary

## Constructors

| Method | Description |
|--------|-------------|
| `New()` | Creates a hook manager. |

## Registration

| Method | Description |
|--------|-------------|
| `PreHook()` | Registers a pre-hook. |
| `PostHook()` | Registers a post-hook. |
| `SecurePostHook()` | Registers a secure post-hook. |

## Hook Management

| Method | Description |
|--------|-------------|
| `get()` | Retrieves a hook by ID. |
| `enable()` | Enables a hook. |
| `disable()` | Disables a hook. |
| `toggle()` | Toggles a hook. |
| `remove()` | Removes a hook from the registry. |

## Batch Operations

| Method | Description |
|--------|-------------|
| `enableAll()` | Enables all hooks. |
| `disableAll()` | Disables all hooks. |
| `toggleAll()` | Toggles all hooks. |

---

# Implementation Notes

- Hooks are registered immediately when created.
- Hooks cannot be unregistered because the ESO API does not provide an unregister mechanism.
- Enabling or disabling only controls whether the callback executes.
- Every hook receives a unique identifier generated from the manager's base name.
- `SecurePostHook()` protects callbacks using `LibSFUtils.safeCall10()`.
- `PreHook()` may cancel the original function by having the callback returning `true`.
- `PostHook()` ignores callback return values.
```