Here's a Markdown documentation section in the same style as the rest of your LibSFUtils documentation.

````markdown
## `closure(callback, tblself, ...)`

Creates a closure that binds a callback function to a specific `self` table and optionally pre-binds one or more leading arguments.

The returned function behaves like a partially applied function. When it is called, the bound arguments are supplied first, followed by any arguments passed to the returned function.

This is useful for:

- Registering callbacks that require a specific object as `self`.
- Creating event handlers with preconfigured arguments.
- Implementing partial function application.

### Syntax

```lua
local fn = sfutil.closure(callback, tblself, ...)
```

### Parameters

| Parameter | Description |
|-----------|-------------|
| `callback` | Function to invoke when the closure is called. |
| `tblself` | Table passed as the first argument to `callback`. May be `nil` for normal functions. |
| `...` | Optional arguments to bind to the callback. These are inserted before the arguments supplied when the returned function is called. |

### Returns

A function that calls:

```lua
callback(tblself, boundArgs..., runtimeArgs...)
```

### Examples

### Bind only `self`

```lua
local update = sfutil.closure(MyObject.Update, MyObject)

update(10, 20)
```

Equivalent to:

```lua
MyObject.Update(MyObject, 10, 20)
```

---

### Bind `self` and leading arguments

```lua
local addFive = sfutil.closure(MyObject.AddValue, MyObject, 5)

addFive(10)
```

Equivalent to:

```lua
MyObject.AddValue(MyObject, 5, 10)
```

---

### Bind a normal function

`tblself` may be `nil` when binding a regular function.

```lua
local greet = sfutil.closure(print, nil, "Hello")

greet("World")
```

Equivalent to:

```lua
print("Hello", "World")
```

### Notes

- Bound arguments are supplied before any arguments provided when the returned function is invoked.
- The callback is not executed until the returned function is called.
- This function provides a simple form of **partial application**, allowing commonly used arguments to be fixed in advance.
- Intended for Lua 5.1 compatibility and does not require `table.pack()`.
````
