Yes. `addonChatter` supports changing the colors used for normal messages and debug messages.

## Change Normal Message Color

Use:

```lua
chat:setNormalColor(hexcolor)
```

Example:

```lua
chat:setNormalColor(sfutil.hex.white)
```

This changes the color used by:

```lua
chat:systemMessage("Message")
```

---

## Change Debug Message Color

Use:

```lua
chat:setDebugColor(hexcolor)
```

Example:

```lua
chat:setDebugColor(sfutil.hex.orange)
```

This changes the color used by:

```lua
chat.d("Debug message")
```

and:

```lua
chat:debugMsg("Debug message")
```

---

## Change the Addon Name Prefix Color

The addon prefix color is set when the object is created:

```lua
chat = sfutil.addonChatter:New("MyAddon")
```

Internally it uses:

```lua
o.namecolor = sfutil.hex.goldenrod
```

If you want to change it after creation:

```lua
chat.namecolor = sfutil.hex.cyan
chat.prefix = sfutil.initSystemMsgPrefix(
    "MyAddon",
    chat.namecolor
)
```

---

## Example Custom Colors

```lua
local chat = sfutil.addonChatter:New("MyAddon")

-- Prefix color
chat.namecolor = sfutil.hex.cyan
chat.prefix = sfutil.initSystemMsgPrefix(
    "MyAddon",
    chat.namecolor
)

-- Normal messages
chat:setNormalColor(sfutil.hex.white)

-- Debug messages
chat:setDebugColor(sfutil.hex.yellow)
```

---

## Recommended Documentation Addition

The `addonChatter` page should include a **Color Configuration** section:

````markdown
# Color Configuration

`addonChatter` supports customizing the colors used for:

- Addon prefix text.
- Normal messages.
- Debug messages.

## Normal Message Color

```lua
chat:setNormalColor(color)
````

## Debug Message Color

```lua
chat:setDebugColor(color)
```

## Prefix Color

The prefix color is set during initialization but can be changed by rebuilding the prefix:

```lua
chat.prefix = sfutil.initSystemMsgPrefix(
    "MyAddon",
    color
)
```

````

One possible improvement to the API would be adding:

```lua
chat:setNameColor(hexcolor)
````

so all three colors (`namecolor`, `normalcolor`, and `debugcolor`) are configurable through methods instead of directly modifying the object fields.
