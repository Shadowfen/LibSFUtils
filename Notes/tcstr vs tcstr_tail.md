Between the two implementations, the original **iterative `tcstr()` implementation is better** for Lua 5.1/ESO addon development.

The tail-recursive version is an interesting exercise, but it does not provide a practical advantage in this environment and introduces performance and correctness issues.

## Comparison

| Feature                  | `tcstr()` (loop) | `tcstr_tail()` (tail recursion)      |
| ------------------------ | ---------------- | ------------------------------------ |
| Correct nested traversal | ✅ Yes            | ❌ Currently broken                   |
| Cycle detection          | ✅ Yes            | ⚠️ Only partially works              |
| Handles deep tables      | ✅ Yes            | ⚠️ Depends on Lua tail-call behavior |
| Performance              | ✅ O(n)           | ❌ O(n²) with `table.remove()`        |
| Lua 5.1 compatible       | ✅ Yes            | ✅ Yes                                |
| Easy to maintain         | ✅ Yes            | ❌ More complex                       |
| Debugging friendly       | ✅ Yes            | ⚠️ Harder                            |
| Stack usage              | ✅ Constant       | ✅ Constant (if true tail calls)      |

---

# Why `tcstr()` is better

Your original version:

```lua
local function tcstr(pending, rslt, seen)
    while true do
        ...
    end
end
```

has several advantages.

## 1. No recursion overhead

Lua function calls are more expensive than loop iterations.

A large saved variable table:

```lua
SavedVars
    -> account
        -> characters
            -> settings
```

may contain thousands of values.

The loop version handles this naturally.

---

## 2. Correct stack behavior

Both versions avoid stack overflow, but for different reasons.

The loop version:

```lua
while true do
```

never grows the call stack.

The tail-recursive version relies on Lua's tail-call optimization:

```lua
return tcstr_tail(...)
```

Lua 5.1 supports this, but it is more fragile. A future modification such as:

```lua
local result = tcstr_tail(...)
return result
```

would remove the optimization.

---

## 3. Better queue handling

Your original version:

```lua
local n = #pending
local v = pending[n]
pending[n] = nil
```

is efficient.

Removing from the end of an array is:

```
O(1)
```

The tail version:

```lua
table.remove(pending, 1)
```

requires shifting:

```
1 2 3 4 5
  ↓
2 3 4 5
```

Every removal costs:

```
O(n)
```

For large structures, this becomes expensive.

---

# The one improvement I would make to `tcstr()`

The only real weakness is this:

```lua
local args = {...}
```

or any table containing nils cannot reliably preserve nil values.

However, your `tcstr()` is not really intended to process argument lists; it processes table contents. Tables do not store nil entries anyway.

So this is not a problem.

---

# One improvement: function handling

Your original:

```lua
elseif type(v) == "function" then
    rslt[#rslt + 1] = v() or "(nil)"
```

is potentially dangerous.

A function stored in a debug table may:

* Modify state.
* Require arguments.
* Throw an error.
* Cause unexpected side effects.

For a debugging utility, I would normally change it to:

```lua
elseif type(v) == "function" then
    rslt[#rslt + 1] = tostring(v)
```

or:

```lua
rslt[#rslt + 1] = "<function>"
```

unless you specifically want lazy evaluation.

---

# Recommended Version

I would keep your original architecture and make only small changes:

```lua
local function tcstr(pending, rslt, seen)
    while #pending > 0 do

        local v = pending[#pending]
        pending[#pending] = nil

        if v == nil then

            rslt[#rslt + 1] = "(nil)"

        elseif type(v) == "table" then

            if seen[v] then

                rslt[#rslt + 1] = "<cycle>"

            else

                seen[v] = true

                for k, v1 in pairs(v) do
                    pending[#pending + 1] = v1
                    pending[#pending + 1] = k
                end
            end

        elseif type(v) == "function" then

            rslt[#rslt + 1] = "<function>"

        else

            rslt[#rslt + 1] = tostring(v)

        end
    end

    return rslt
end
```

---

## Final Recommendation

For **LibSFUtils / ESO Lua utilities**:

✅ Use `tcstr()`
❌ Do not use `tcstr_tail()`

The iterative version is:

* Faster.
* Simpler.
* Easier to debug.
* More idiomatic Lua.
* Better suited for addon debugging utilities.

The tail-recursive version is a useful demonstration of Lua tail calls, but it is not an improvement for this particular problem.
