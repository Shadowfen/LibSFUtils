````markdown
# addonChatter

`addonChatter` is a lightweight chat messaging utility provided by **LibSFUtils** for ESO addons.

It provides a consistent way to send:

- Normal addon messages.
- Debug messages.
- Colored chat output.
- Slash command help information.

`addonChatter` removes repetitive chat formatting code by handling addon prefixes, colors, debug state management, and help display formatting.

---

# Overview

A typical addon creates one `addonChatter` object:

```lua
local chat = sfutil.addonChatter:New("MyAddon")
````

The object can then be used
