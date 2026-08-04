## Purpose of `slashHelp()`

`sfutil.addonChatter:slashHelp()` is a convenience function for displaying a formatted list of addon slash commands in the ESO chat window.

Its purpose is to avoid every addon implementing its own help display logic. Instead of manually formatting commands, coloring text, and sending multiple chat messages, an addon can maintain a simple command definition table and pass it to `slashHelp()`.

It is typically used when:

* A user enters `/addon help`.
* An addon registers multiple slash commands.
* An addon wants to provide discoverable command documentation in-game.
* Developers want consistent formatting across addon messages.

---

# Syntax

```lua
chat:slashHelp(title, cmdstable)
```

## Parameters

| Parameter   | Type   | Description                                 |
| ----------- | ------ | ------------------------------------------- |
| `title`     | string | Heading displayed before the command list.  |
| `cmdstable` | table  | Table containing slash command definitions. |

---

# Command Table Format

The command table is expected to contain entries where each entry is a two-element table:

```lua
{
    command,
    description
}
```

Example:

```lua
local commands =
{
    {"/myaddon help", "Display available commands"},
    {"/myaddon reload", "Reload saved settings"},
    {"/myaddon reset", "Reset all settings"},
}
```

Each entry contains:

| Index | Purpose                       |
| ----- | ----------------------------- |
| `[1]` | Slash command text            |
| `[2]` | Description shown to the user |

---

# Basic Usage Example

```lua
local chat = sfutil.addonChatter:New("MyAddon")

local commands =
{
    {"/myaddon help", "Show this help message"},
    {"/myaddon debug", "Toggle debug output"},
    {"/myaddon reset", "Restore default settings"},
}

chat:slashHelp("MyAddon Commands", commands)
```

The output in ESO chat will be formatted similar to:

```
[MyAddon] MyAddon Commands

/myaddon help = Show this help message
/myaddon debug = Toggle debug output
/myaddon reset = Restore default settings
```

The command text is displayed using the command color, and the descriptions use the normal message color.

---

# Using ESO String IDs

The description field can also contain an ESO string ID instead of a literal string.

Example:

```lua
local commands =
{
    {"/myaddon help", SI_MYADDON_HELP_TEXT},
}
```

`slashHelp()` detects numeric descriptions and automatically calls:

```lua
GetString(description)
```

This allows localization support.

Example:

```lua
{
    "/myaddon reset",
    SI_MYADDON_RESET_DESCRIPTION
}
```

will display the localized text instead of the numeric string ID.

---

# Typical Slash Command Implementation

A common pattern is:

```lua
SLASH_COMMANDS["/myaddon"] = function(command)

    if command == "help" then
        chat:slashHelp("MyAddon Commands", commands)

    elseif command == "debug" then
        chat:toggleDebug()

    elseif command == "reset" then
        ResetSettings()

    else
        chat:slashHelp("MyAddon Commands", commands)
    end
end
```

Now users can type:

```
/myaddon help
```

or just:

```
/myaddon
```

and receive the available command list.

---

# Implementation Behavior

Internally `slashHelp()` creates a small helper function:

```lua
local sysmsg = function(cmd, desc)
```

which:

1. Colors the command text.
2. Converts ESO string IDs to localized text.
3. Formats the `" = "` separator.
4. Sends the final message through `ZOS_addSystemMsg()`.

Then it loops through the command table:

```lua
for _, value in pairs(cmdstable) do
    sysmsg(value[1], value[2])
end
```

Each command entry becomes one chat line.

---

# Design Benefits

Using `slashHelp()` provides:

### Consistent formatting

All addon help output has the same appearance.

### Easy localization

Descriptions can use ESO string IDs.

### Centralized styling

Command colors and description colors are controlled by `addonChatter`.

### Easy maintenance

Adding a command only requires adding one table entry:

```lua
{"/myaddon newcommand", "Does something new"}
```

No additional formatting code is needed.

---

# Recommended Pattern

For larger addons, define the command table once:

```lua
local HELP_COMMANDS =
{
    {"/myaddon help", SI_MYADDON_HELP},
    {"/myaddon config", SI_MYADDON_CONFIG},
    {"/myaddon reset", SI_MYADDON_RESET},
}
```

Then reuse it:

```lua
chat:slashHelp("MyAddon", HELP_COMMANDS)
```

This keeps slash command registration and user documentation synchronized.
