The difference between `d()` and `debugMsg()` is mostly **convenience and performance intent**. They both ultimately send a debug message through the same mechanism, but they are meant for different usage patterns.

## `debugMsg()`

`debugMsg()` is the explicit debug output function.

### Usage

```lua
chat:debugMsg("Loading saved variables")
```

It:

1. Checks whether debugging is enabled.
2. Formats the message.
3. Sends it to ESO chat if enabled.

### Best used for:

* User-facing debug commands.
* Occasional diagnostic output.
* Code where readability is more important than minimizing calls.
* Places where the caller wants to make the debug intent obvious.

Example:

```lua
SLASH_COMMANDS["/myaddon"] = function(cmd)

    if cmd == "debug" then
        chat:toggleDebug()
        chat:debugMsg("Debug mode changed")
    end

end
```

Here, `debugMsg()` clearly communicates that this is a deliberate debug message.

---

# `d()`

`d()` is a short alias optimized for frequent internal tracing.

Example:

```lua
chat.d("Entering LoadProfile()")
chat.d("Profile:", profileName)
```

When debugging is disabled, `d()` is replaced with an empty function:

```lua
self.d = function(...)
end
```

When debugging is enabled:

```lua
self.d = function(...)
    local msg = sfutil.ColorText(
        sfutil.dstr(" ", ...),
        self.debugcolor
    )
    ZOS_addSystemMsg(self.prefix .. msg)
end
```

This means code does not need to do:

```lua
if chat:isDebugEnabled() then
    chat:debugMsg(...)
end
```

every time.

---

# Performance Difference

The difference is small, but the intent is different.

## Using `debugMsg()`

```lua
chat:debugMsg("Value:", value)
```

Always calls the function and checks:

```lua
if self.isdbgon then
```

internally.

---

## Using `d()`

```lua
chat.d("Value:", value)
```

When disabled:

```lua
function(...)
end
```

Nothing happens.

No:

* Boolean check.
* Message formatting.
* Color processing.
* Chat call.

---

# Recommended Usage

## Use `d()` for development tracing

Examples:

```lua
chat.d("Starting initialization")
chat.d("Loaded settings:", settings)
chat.d("Migration complete")
```

Good locations:

* Function entry/exit points.
* Variable inspection.
* State changes.
* Troubleshooting complex logic.

---

## Use `debugMsg()` for intentional debug messages

Examples:

```lua
chat:debugMsg("Debug mode enabled")
chat:debugMsg("Database reset requested")
```

Good locations:

* Slash commands.
* Settings panels.
* User-controlled debug features.
* Messages that explain a state change.

---

# Example: Both Together

```lua
local chat = sfutil.addonChatter:New("MyAddon")

function MyAddon:Initialize()

    chat.d("Initialize started")

    self.settings = LoadSettings()

    chat.d("Settings loaded")

    if self.settings.debug then
        chat:debugMsg("Debug mode is active")
    end

end
```

Here:

* `d()` is developer tracing.
* `debugMsg()` is an explicit debug notification.

---

# Rule of Thumb

| Situation                                                    | Use          |
| ------------------------------------------------------------ | ------------ |
| "I am temporarily tracing code execution"                    | `d()`        |
| "I want to inspect values while developing"                  | `d()`        |
| "I expect this message to be useful when debugging an addon" | `debugMsg()` |
| "A user enabled debug mode and should see this message"      | `debugMsg()` |
| "Many debug statements throughout the code"                  | `d()`        |
| "A few important debug messages"                             | `debugMsg()` |

For LibSFUtils itself, I would generally recommend:

* Internal library/addon developers: use `chat.d()`.
* Public addon diagnostics: use `chat:debugMsg()`.

`d()` is essentially the **developer trace channel**, while `debugMsg()` is the **explicit debug message API**.
