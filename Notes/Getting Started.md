````markdown
# Getting Started

Welcome to **LibSFUtils**, a general-purpose utility library for **The Elder Scrolls Online** addon developers.

LibSFUtils provides a collection of reusable components that simplify common addon development tasks, allowing you to spend less time writing infrastructure code and more time building features.

Some of the utilities included are:

- String manipulation and formatting
- Table utilities
- Safe function execution
- Timers and delayed callbacks
- Hook management
- Version checking
- Queue management
- Logging and debugging helpers
- Color utilities
- File and path helpers
- Miscellaneous convenience functions

Most components are independent and can be used without learning the rest of the library.

---

# Installation

Install **LibSFUtils** like any other ESO library.

If your addon depends on LibSFUtils, list it in your addon's manifest (`.txt`) file.

```txt
## DependsOn: LibSFUtils
```

or

```txt
## OptionalDependsOn: LibSFUtils
```

if your addon can function without it.

---

# Accessing the Library

The library is available through the global variable:

```lua
local SF = LibSFUtils
```

Most examples in this documentation assume this alias.

---

# Library Organization

LibSFUtils is organized into small, focused modules.

For example:

| Module | Purpose |
|---------|---------|
| `CallLater` | Delayed and periodic timers |
| `HookManager` | Centralized management of ESO hooks |
| `VersionChecker` | Compare addon versions and compatibility |
| `Logger` | Debug and diagnostic output |
| `Queue` | FIFO queue implementation |
| `TimedQueue` | Queue with delayed processing |
| String utilities | Formatting and text manipulation |
| Table utilities | Searching, copying, and merging tables |

Each module has its own documentation page with complete API details and examples.

---

# Your First Timer

The simplest way to execute code after a short delay is with `CallLater`.

```lua
local SF = LibSFUtils

SF.CallLater:New(function()
    d("Hello, Tamriel!")
end, 1000):Start()
```

This creates a one-shot timer that executes once after one second.

---

# Your First Hook

To execute code whenever an ESO function runs:

```lua
local SF = LibSFUtils

local hooks = SF.HookManager:New()

hooks:PostHook(ZO_PlayerInventory, "RefreshInventory", function()
    d("Inventory refreshed.")
end)
```

The hook is registered immediately and will execute every time the inventory refreshes.

---

# Safe Function Calls

When executing user callbacks or potentially unsafe code, use `safeCall`.

```lua
local ok, result = SF.safeCall(function()
    -- risky code
end)

if not ok then
    d("Callback failed.")
end
```

This prevents Lua errors from propagating through the game UI.

---

# Finding the Right Tool

If you want to... | Use...
------------------|------------------------
Run code later | `CallLater`
Repeat a task | `CallLater:NewTimer()`
Hook an ESO function | `HookManager`
Safely execute callbacks | `safeCall`
Compare addon versions | `VersionChecker`
Manage queued work | `Queue` or `TimedQueue`
Write debug output | `Logger`

---

# Documentation Structure

Each module in LibSFUtils follows a consistent documentation format:

- Overview
- Constructors
- Public API
- Examples
- Notes
- API Reference

Once you understand one module, the others should feel familiar.

---

# Requirements

- The Elder Scrolls Online
- Lua 5.1
- LibSFUtils installed and loaded before your addon

---

# Next Steps

If you're new to LibSFUtils, these pages are a good place to start:

1. **CallLater** — Execute functions after a delay or at regular intervals.
2. **HookManager** — Manage ESO hooks from a central registry.
3. **VersionChecker** — Compare addon versions and detect compatibility.
4. **Logger** — Produce structured debug output.
5. **Queue** and **TimedQueue** — Process work sequentially.

Each page contains practical examples that can be copied directly into your addon.
````
