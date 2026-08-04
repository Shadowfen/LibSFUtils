Not with the current implementation.

Your `WrapFunction()` replaces the original function with a new closure:

```lua
local originalFunction = namespace[functionName]

namespace[functionName] = function(...)
    return wrapper(originalFunction, ...)
end
```

After this assignment, the only reference to `originalFunction` exists inside the closure. Once `WrapFunction()` returns, there's no public way to retrieve it again.

## Making wrappers reversible

The simplest approach is to have `WrapFunction()` return the original function:

```lua
function sfutil.WrapFunction(namespace, functionName, wrapper)
    if type(namespace) == "string" then
        wrapper = functionName
        functionName = namespace
        namespace = _G
    elseif type(namespace) ~= "table" then
        return nil
    end

    local originalFunction = namespace[functionName]

    namespace[functionName] = function(...)
        return wrapper(originalFunction, ...)
    end

    return originalFunction
end
```

Then:

```lua
local original = sfutil.WrapFunction(MyAddon, "Update", wrapper)

-- later...
MyAddon.Update = original
```

This is the least intrusive change.

---

## Better: Provide an unwrap function

You can return a function that restores the original automatically:

```lua
function sfutil.WrapFunction(namespace, functionName, wrapper)
    ...

    local original = namespace[functionName]

    namespace[functionName] = function(...)
        return wrapper(original, ...)
    end

    return function()
        namespace[functionName] = original
    end
end
```

Usage:

```lua
local unwrap = sfutil.WrapFunction(MyAddon, "Update", wrapper)

...

unwrap()
```

I like this approach because the caller doesn't need to keep track of the original function itself.

---

## Best: Support nested wrappers

If multiple libraries may wrap the same function, consider maintaining a stack:

```lua
wrappedFunctions[namespace][functionName] = {
    original = ...,
    wrappers = {...}
}
```

Then `UnwrapFunction()` removes only the most recent wrapper (or a specific wrapper), leaving earlier wrappers intact.

Without this, consider:

```lua
LibraryA wraps Update
LibraryB wraps Update
```

If LibraryA restores the original function, LibraryB's wrapper disappears as well.

---

### My recommendation

For LibSFUtils, I'd add a companion function:

```lua
local unwrap = sfutil.WrapFunction(...)
...
unwrap()
```

It keeps the API simple, avoids global bookkeeping, and is sufficient for the vast majority of debugging, profiling, and temporary hook scenarios. If you later find you need multiple independent wrappers on the same function, you can extend the implementation to maintain a wrapper stack without changing the basic API.
