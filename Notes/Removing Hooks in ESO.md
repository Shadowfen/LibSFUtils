No. **ESO's hook APIs do not provide any mechanism to unregister or remove a hook once it has been installed.**

The three primary hook functions behave as follows:

| Function           | Can be removed? | Notes                                      |
| ------------------ | --------------- | ------------------------------------------ |
| `ZO_PreHook()`     | ❌ No            | Permanently wraps the target function.     |
| `ZO_PostHook()`    | ❌ No            | Permanently appends the callback.          |
| `SecurePostHook()` | ❌ No            | Permanently registers the secure callback. |

Once one of these functions has been called, the wrapper remains attached for the lifetime of the UI session (until `/reloadui` or logging out).

### Common Practice

Because hooks cannot be removed, most addons simply guard their callbacks:

```lua
local enabled = true

ZO_PostHook(ZO_PlayerInventory, "RefreshInventory", function(...)
    if not enabled then
        return
    end

    -- Do work...
end)
```

Your `HookManager` follows exactly this pattern by storing an `enabled` flag in each hook object.

### What `remove()` Really Does

Your current implementation:

```lua
function HookManager:remove(id)
    local h = self:get(id)
    if not h then return end

    h.enabled = false
    self.hooks[id] = nil
end
```

does **not** remove the hook from ESO.

Instead it:

1. Disables the callback (`enabled = false`).
2. Removes the hook object from your registry.
3. Leaves the wrapper callback permanently installed.

Fortunately, because your wrapper closes over the hook object (`o`), the callback still exists and simply returns immediately:

```lua
function(...)
    if not o.enabled then
        return
    end

    return fn(...)
end
```

So the overhead becomes just a single boolean check.

### Documentation Suggestion

I would explicitly say something like:

> **Note:** The ESO API does not support unregistering hooks. Methods such as `disable()` and `remove()` only affect the HookManager's callback state. The underlying hook remains installed until the UI is reloaded.

This makes the behavior clear and avoids giving the impression that `remove()` undoes the hook registration.

For this reason, you might also consider renaming `remove()` to something like `forget()`, `release()`, or `removeFromRegistry()` to better reflect what it actually does, although `remove()` is acceptable if the documentation clearly explains its semantics.
