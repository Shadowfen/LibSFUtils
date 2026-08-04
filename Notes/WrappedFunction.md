````markdown
## `WrapFunction([namespace], functionName, wrapper)`

Wraps an existing function so that all future calls are redirected through a wrapper function.

The wrapper receives the original function as its first argument, followed by the arguments supplied by the caller. This allows the wrapper to intercept, modify, extend, or completely replace the original function's behavior.

If no namespace is supplied, the function is assumed to exist in the global namespace (`_G`).

This utility is useful for:

- Hooking existing functions
- Logging or debugging function calls
- Profiling execution time
- Injecting additional behavior before or after a function executes
- Temporarily overriding existing implementations

### Syntax

Wrap a global function:

```lua
sfutil.WrapFunction(functionName, wrapper)
```

Wrap a function in a table (namespace):

```lua
sfutil.WrapFunction(namespace, functionName, wrapper)
```

### Parameters

| Parameter | Description |
|-----------|-------------|
| `namespace` | *(Optional)* Table containing the function to wrap. If omitted, `_G` is used. |
| `functionName` | Name of the function to wrap. |
| `wrapper` | Function that will replace the original function. It receives the original function as its first argument. |

### Wrapper Signature

```lua
function wrapper(originalFunction, ...)
```

| Parameter | Description |
|-----------|-------------|
| `originalFunction` | The original function being wrapped. |
| `...` | Arguments passed by the caller. |

The wrapper may:

- Call the original function.
- Modify the arguments before calling it.
- Modify the return values.
- Skip calling the original function entirely.

### Returns

Nothing.

The specified function is replaced with a wrapped version.

### Examples

### Wrap a Global Function

```lua
function SayHello(name)
    d("Hello " .. name)
end

sfutil.WrapFunction("SayHello",
    function(original, name)
        d("Before")
        original(name)
        d("After")
    end)

SayHello("Alice")
```

Output:

```
Before
Hello Alice
After
```

---

### Wrap a Namespaced Function

```lua
MyAddon = {}

function MyAddon.Update(value)
    d("Updating:", value)
end

sfutil.WrapFunction(MyAddon, "Update",
    function(original, value)
        d("Intercepted")
        return original(value)
    end)

MyAddon.Update(42)
```

Output:

```
Intercepted
Updating: 42
```

---

### Modify Arguments

The wrapper can alter the arguments before forwarding them.

```lua
sfutil.WrapFunction(MyAddon, "Update",
    function(original, value)
        return original(value * 2)
    end)
```

Calling

```lua
MyAddon.Update(10)
```

actually invokes

```lua
original(20)
```

---

### Replace the Original Function

The wrapper is not required to call the original function.

```lua
sfutil.WrapFunction("DangerousFunction",
    function(original, ...)
        d("DangerousFunction has been disabled.")
    end)
```

Every call to `DangerousFunction()` now prints a message without executing the original implementation.

### Notes

- Wrapping affects all subsequent calls to the function.
- The original function is preserved only within the wrapper as the first parameter.
- Wrappers can modify arguments, return values, or completely replace the original behavior.
- Multiple calls to `WrapFunction()` on the same function create nested wrappers, with the most recently installed wrapper executing first.
- This utility is particularly useful for debugging, instrumentation, and extending third-party code without modifying its source.
````
