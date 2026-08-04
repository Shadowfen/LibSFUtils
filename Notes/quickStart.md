````markdown
# Quick Start

`addonChatter` provides a simple way to add consistent chat messages and debug output to an ESO addon.

The basic workflow is:

1. Create an `addonChatter` object.
2. Send normal messages with `systemMessage()`.
3. Add debug output with `d()` or `debugMsg()`.
4. Display command help with `slashHelp()`.

---

# Creating an addonChatter Object

Create a chat handler when your addon initializes:

```lua
local chat = sfutil.addonChatter:New("MyAddon")
````

The addon name is used as the message prefix:

```
[MyAddon]
```

All messages sent through this object will automatically include the prefix.

---

# Sending Messages

## Normal Messages

Use `systemMessage()` for messages that should always be displayed.

```lua
chat:systemMessage("Addon initialized.")
```

Output:

```
[MyAddon] Addon initialized.
```

Use this for:

* Initialization messages.
* Important status updates.
* User-visible notifications.

---

# Adding Debug Output

## Using `d()`

For frequent development tracing, use `d()`:

```lua
chat.d("Loading saved variables")
chat.d("Current profile:", profileName)
```

When debugging is disabled, `d()` becomes a no-operation function and does not perform message formatting or chat output.

This makes it suitable for leaving debug statements in production code.

---

## Using `debugMsg()`

For explicit debug messages, use:

```lua
chat:debugMsg("Migration completed")
```

`debugMsg()` checks whether debugging is enabled before displaying the message.

Use it for:

* Important diagnostic messages.
* User-enabled debug output.
* Messages triggered by debug commands.

---

# Enabling Debug Output

Debug output is disabled by default.

Enable it:

```lua
chat:enableDebug()
```

Now:

```lua
chat.d("Debug information")
```

will appear in chat.

Disable it:

```lua
chat:disableDebug()
```

Toggle it:

```lua
chat:toggleDebug()
```

Check the current state:

```lua
if chat:isDebugEnabled() then
    chat:debugMsg("Debug is active")
end
```

---

# Creating Slash Command Help

Define your command list:

```lua
local HELP_COMMANDS =
{
    {"/myaddon help", "Show available commands"},
    {"/myaddon debug", "Toggle debug output"},
    {"/myaddon reset", "Reset settings"},
}
```

Display the help:

```lua
chat:slashHelp(
    "MyAddon Commands",
    HELP_COMMANDS
)
```

Output:

```
[MyAddon] MyAddon Commands

/myaddon help = Show available commands
/myaddon debug = Toggle debug output
/myaddon reset = Reset settings
```

---

# Complete Example

A typical addon setup:

```lua
local chat = sfutil.addonChatter:New("MyAddon")

local HELP_COMMANDS =
{
    {"/myaddon help", "Display help"},
    {"/myaddon debug", "Toggle debugging"},
}


function MyAddon:Initialize()

    chat:systemMessage("Initializing...")

    chat.d("Starting initialization")

    -- addon initialization code

    chat.d("Initialization complete")

end


SLASH_COMMANDS["/myaddon"] = function(command)

    if command == "debug" then

        chat:toggleDebug()

        chat:debugMsg(
            "Debug state:",
            chat:getDebugState()
        )

    else

        chat:slashHelp(
            "MyAddon Commands",
            HELP_COMMANDS
        )

    end

end
```

---

# Recommended Usage

| Purpose                    | Function          |
| -------------------------- | ----------------- |
| User-visible messages      | `systemMessage()` |
| Frequent developer tracing | `d()`             |
| Explicit debug messages    | `debugMsg()`      |
| Turn debugging on          | `enableDebug()`   |
| Turn debugging off         | `disableDebug()`  |
| Toggle debugging           | `toggleDebug()`   |
| Display command help       | `slashHelp()`     |

`addonChatter` is designed so debug statements can remain in addon code while having almost no cost when debugging is disabled.

