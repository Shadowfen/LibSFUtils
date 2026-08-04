## Evaluation of `sfutil.RemainsInList()`

`sfutil.RemainsInList()` is a small but useful **set difference** helper. It determines which values from `listA` are not represented in `listB`.

Conceptually:

```text
result = listA - listB
```

The implementation is efficient because it treats `listB` as a lookup set rather than searching it repeatedly.

---

# Summary Rating

| Area               | Rating |
| ------------------ | ------ |
| Correctness        | ⭐⭐⭐⭐   |
| Performance        | ⭐⭐⭐⭐⭐  |
| API clarity        | ⭐⭐⭐    |
| Edge-case handling | ⭐⭐⭐    |
| ESO usefulness     | ⭐⭐⭐⭐⭐  |

Overall: **good utility, but the name and documentation could be improved.**

---

# Current Behavior

Example:

```lua
local listA =
{
    "sword",
    "shield",
    "potion",
}

local listB =
{
    sword = true,
    potion = true,
}

local result = sfutil.RemainsInList(listA, listB)
```

Result:

```lua
{
    shield = 1,
}
```

Because:

```text
listA:
    sword   -> excluded
    shield  -> remains
    potion  -> excluded
```

---

# Strengths

## 1. Efficient set lookup

This is the best part:

```lua
if not listB[v] then
```

The function assumes:

```lua
listB =
{
    [value] = true
}
```

so lookup is:

```text
O(1)
```

The entire operation is:

```text
O(#listA)
```

Very efficient.

A slower implementation would be:

```lua
for each item in listA
    search listB
```

which becomes:

```text
O(#listA * #listB)
```

Your implementation is much better.

---

## 2. Does not modify inputs

This:

```lua
local newList = {}
```

creates a new result.

`listA` and `listB` remain unchanged.

Good.

---

## 3. Handles missing inputs safely

This:

```lua
if listA == nil or listB == nil then return newList end
```

prevents errors.

Examples:

```lua
sfutil.RemainsInList(nil, {})
```

returns:

```lua
{}
```

Good for utility code.

---

# Issues

## 1. The function name is unclear

`RemainsInList` is understandable, but not immediately obvious.

The actual operation is:

```text
set difference
```

Better names:

```lua
sfutil.listDifference()
```

or:

```lua
sfutil.setDifference()
```

or:

```lua
sfutil.itemsNotIn()
```

Example:

```lua
sfutil.itemsNotIn(listA, listB)
```

is immediately clear.

---

# 2. The documentation says "values are treated as keys"

This is correct, but important enough to emphasize.

The function does **not** compare:

```lua
listB values
```

It compares:

```lua
listB keys
```

Example:

This does **not** work:

```lua
local listB =
{
    "sword",
    "potion",
}
```

because:

```lua
listB["sword"]
```

is:

```lua
nil
```

The caller must create:

```lua
local listB =
{
    sword = true,
    potion = true,
}
```

or:

```lua
{
    sword = 1,
    potion = 1,
}
```

---

# 3. The result format is slightly unusual

The function returns:

```lua
{
    ["shield"] = 1
}
```

rather than:

```lua
{
    "shield"
}
```

This is intentional because it creates another set.

That is useful, but should be named/documented.

Possible alternatives:

## Current

```lua
{
    shield = 1,
    armor = 1,
}
```

Good for:

```lua
if result[item] then
```

---

## Array result

```lua
{
    "shield",
    "armor",
}
```

Good for:

```lua
for _, item in ipairs(result)
```

---

I would keep your current behavior because it is optimized for membership tests.

---

# 4. `not listB[v]` has a subtle issue

Current:

```lua
if not listB[v] then
```

means:

```lua
false
```

and:

```lua
nil
```

both mean "not found".

Example:

```lua
listB =
{
    sword = false
}
```

Then:

```lua
listB["sword"]
```

returns:

```lua
false
```

and the function incorrectly treats it as missing.

For a set, this is usually okay because keys should contain `true`/`1`.

But a safer check is:

```lua
if listB[v] == nil then
```

That checks existence instead of truthiness.

---

# Recommended Implementation

I would change only that:

```lua
function sfutil.RemainsInList(listA, listB)

    local newList = {}

    if type(listA) ~= "table" or type(listB) ~= "table" then
        return newList
    end

    for _, value in pairs(listA) do
        if listB[value] == nil then
            newList[value] = 1
        end
    end

    return newList
end
```

Benefits:

* accepts any invalid input safely
* correctly handles false values
* same performance

---

# Possible Helper for Building Sets

Since this function depends on set-style tables, a companion helper would be useful:

```lua
function sfutil.listToSet(list)
    local set = {}

    for _, value in ipairs(list) do
        set[value] = true
    end

    return set
end
```

Then:

```lua
local excluded = sfutil.listToSet(
{
    "sword",
    "potion",
})

local remaining =
    sfutil.RemainsInList(items, excluded)
```

This makes the intended usage much clearer.

---

# ESO Use Cases

This pattern is common in ESO addons.

Examples:

## Missing saved variable keys

```lua
missing =
    sfutil.RemainsInList(
        requiredKeys,
        existingKeys
    )
```

---

## Account permissions

```lua
available =
    sfutil.RemainsInList(
        allCharacters,
        disabledCharacters
    )
```

---

## Migration validation

```lua
unmigrated =
    sfutil.RemainsInList(
        expectedFields,
        migratedFields
    )
```

---

# Final Recommendation

Keep the function. It is efficient and useful.

I would make three changes:

1. Change:

```lua
if not listB[v]
```

to:

```lua
if listB[v] == nil
```

2. Consider renaming it to something like:

```lua
sfutil.listDifference()
```

3. Clarify that the return value is a **set table**, not a list.

The underlying algorithm is exactly the right approach for Lua/ESO addon work.
