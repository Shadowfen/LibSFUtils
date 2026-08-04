# LibSFUtils Library Documentation

## Overview

**LibSFUtils** is a comprehensive utility library for Elder Scrolls Online (ESO) addons. It provides performance-optimized functions for common addon tasks including color management, event handling, string manipulation, table operations, logging, and hook management.

### Key Features

- **Performance Optimization**: Minimizes runtime calculations through caching and pooled memory
- **Safety**: Handles nil values, circular references, and edge cases gracefully
- **Flexibility**: Multiple ways to handle the same operation (strings, numbers, localization IDs)
- **Registry-Based Management**: Centralized tracking of hooks, events, and timers
- **Lightweight**: Designed for ESO's Lua environment with minimal overhead

### Dependencies

- Requires ESO API (ZO_Functions, EVENT_MANAGER, etc.)
- Optional: [LibDebugLogger](https://www.esoui.com/downloads/info68-LibDebugLogger.html) for advanced logging
- Other SFUtils modules depend on LibSFUtils core

---

## Installationlua
local sfutil = LibStub:GetLibrary("LibSFUtils")
--  or
local sfutil = LibSFUtils
Ensure all modules are loaded in your addon's manifest.xml before use.

Module StructureLibSFUtils/
├── SFUtils_Core.lua          -- Base utilities (colors, iteration, closures)
├── SFUtils_Color.lua         -- Color conversion and SF_Color class
├── SFUtils_Strings.lua       -- String manipulation and formatting
├── SFUtils_Tables.lua        -- Table operations and safety checks
├── SFUtils_LoadLanguage.lua  -- Localization and SafeAddString
├── SFUtils_HookManager.lua   -- Hook registry and management
├── SFUtils_Events.lua        -- Event and timer registration
├── SFUtils_Logger.lua        -- Logger utilities
└── SFUtils_Guild.lua         -- Guild-related helpers

## Core Utilities
### Color Management
Color Tables (sfutil.colors)
Predefined color objects optimized for quick lookup:
```lua
-- Named colors
sfutil.colors.gold      -- "FFD700"
sfutil.colors.red       -- "FF0000"
sfutil.colors.purple    -- "b000ff"

-- Item quality colors
sfutil.colors.normal    -- "FFFFFF"
sfutil.colors.fine      -- "2dc50e"
sfutil.colors.superior  -- "3a92ff"
sfutil.colors.epic      -- "a02ef7"
sfutil.colors.legendary -- "EECA00"
sfutil.colors.mythic    -- "ffaa00"Quick Lookupssfutil.hex.gold      -- Returns hex string
sfutil.rgb.gold      -- Returns rgb table {r, g, b}
```
### SF_Color Class
Lightweight color object with cached hex representation:
Method|Description
-- | --
SF_Color:New(pr, pg, pb, pa)|Create new color object
SF_Color:Initialize(...)|Reset existing object to new color
SF_Color:SetColor(...)|Set color from various formats
SF_Color:Colorize(text)|Wrap text with `
SF_Color:Clone()|Deep copy of color
SF_Color:IsEqual(other)|Compare with another color
SF_Color:ToHex()|Get cached hex string
SF_Color:ToZO_ColorDef()|Convert to ZO_ColorDef
SF_Color:UnpackRGB()|Get r, g, b float values
SF_Color:UnpackRGBA()|Get r, g, b, a float values
SF_Color:SetAlpha(a)|Update alpha channel

Usage Example:
```lua
local myColor = sfutil.SF_Color:New("FF0000")
print(myColor:Colorize("Red Text"))  -- "|cFF0000Red Text|r"

-- Create from floats
local blue = sfutil.SF_Color:New(0, 0, 1)

-- Chain operations
local green = sfutil.SF_Color:New():SetColor(0, 1, 0)
```
### Color Conversion Functions
Function|Description
sfutil.color:RGBToHex(r, g, b)|RGB floats (0-1) → 6-char hex
sfutil.color:HexToRGBA(colourString)|Hex → RGBA floats (0-1)
sfutil.ConvertRGBToHex(r, g, b)|RGB floats → 
sfutil.ConvertHexToRGBA(colourString)|Various formats → RGBA floats
sfutil.ConvertHexToRGBAPacked(colourString)|Hex → {r,g,b,a} table

Supported Hex Formats:

`|crrggbb` - ESO tag format
`aarrggbb` - 8-char with alpha
`rrggbb` - Standard 6-char

## String Utilities
### Concatenation Functions
Function|Description
--|--
sfutil.str(...)|Fast concatenation with circular reference protection
sfutil.lstr(...)|Like str() but treats numbers as localization IDs
sfutil.dstr(delim, ...)|Concatenation with delimiter between elements
sfutil.str1(...)|Legacy version (prefer sfutil.str)
sfutil.lstr1(...)|Legacy version (prefer sfutil.lstr)

Features:

Numbers → tostring() (or GetString() for lstr)
Tables → Recursively expanded (keys + values)
nil → "(nil)"
Functions → Ignored (not executed)
Circular references → "<cycle>"
```lua
-- Basic concatenation
local msg = sfutil.str("Hello", " ", "World")

-- With localization
local localized = sfutil.lstr(SI_CHAT_CHANNEL_SAY, ": ", message)

-- With delimiter
local csv = sfutil.dstr(",", "a", "b", "c")  -- "a,b,c"
```
### Text Helpers
Function|Descriptions
--|--
futil.GetText(textEntry, ...)|Resolve text from string/number/function
sfutil.ColorText(prompt, hexcolor)|Apply color to text
sfutil.GetIconized(prompt, color, texturefile, texColor)|Add icon with optional coloring
sfutil.strSplitLen(str, maxlen)|Split string into chunks ≤ maxlen
sfutil.tblJoinLen(tbl, maxlen)|Join table, split if exceeds maxlen

```lua
-- Color text in chat
local colored = sfutil.ColorText("Warning!", sfutil.hex.gold)

-- Iconized message
local msg = sfutil.GetIconized("Level Up", sfutil.hex.green, 
                               "Interface\\Icons\\Ability_Warrior_BattleRoar")
```
## Table Utilities
Function|Description
sfutil.safeTable(tbl)|Return table or empty {}
sfutil.safeClearTable(tbl)|Clear all entries safely
sfutil.deepCopy(orig, seen)|Deep copy with circular reference protection
sfutil.defaultMissing(saved, defaults)|Fill missing keys without overwriting
sfutil.getSize(tbl)|Count keys (handles non-contiguous tables)
sfutil.isEmpty(tbl)|Check if table has no keys (returns nil for non-tables)
sfutil.RemainsInList(listA, listB)|Find items in A not present in B
sfutil.dTable(vtable, depth, name)|Debug string representation

Configuration Merging Example:
```lua
local defaults = {
    soundEnabled = true,
    volume = 0.8,
    settings = {
        showTooltip = true,
        position = "bottom"
    }
}

-- Merge saved settings with defaults
userSettings = sfutil.defaultMissing(savedSettings, defaults)
```
## Iteration & Closure Helpers
Function|Description
--|--
sfutil.iter_args(...)|Iterator yielding index, value, total
sfutil.closure(callback, tblself, ...)|Create closure with pre-bound self
sfutil.safeCall(fn, ...)|Protected call returning all results
sfutil.safeCall10(fn, ...)|Protected call returning max 10 results
sfutil.WrapFunction(namespace, functionName, wrapper)|Wrap existing function

```lua
-- Safe function call
local ok, result1, result2 = sfutil.safeCall(myFunc, arg1, arg2)
if not ok then
    warn("Error:", result1)  -- result1 is the error message
end

-- Iterator with count
for idx, value, total in sfutil.iter_args(10, 20, 30) do
    d(idx, value, total)  -- 1, 10, 3
                           -- 2, 20, 3
                           -- 3, 30, 3
end
```
## Boolean/String Conversions
Function|Description
--|--
sfutil.isTrue(val)|Strict true check (accepts 1, "1", true, "true")
sfutil.bool2str(bool)|Boolean → "true" or "false"
sfutil.str2bool(str)|String → boolean
sfutil.nilDefault(val, defaultval)|Return val unless nil
sfutil.nilDefaultStr(val, defaultval)|Return val unless nil or empty string

## Advanced Modules
### Hook Manager (sfutil.HookManager)
Centralized hook registry for managing multiple ESO hooks efficiently.
Instance Creationlocal manager = sfutil.HookManager:New("MyAddonHooks")Hook Registration
MethodDescriptionmanager:PreHook(target, method, fn)Run callback before original (return true to cancel)manager:PostHook(target, method, fn)Run callback after originalmanager:SecurePostHook(target, method, fn)Secure post-hook with error swallowing
Hook Object Properties:
PropertyTypeDescriptionidstringUnique identifiertargettableTarget containing the methodmethodstringMethod name (case-sensitive)fnfunctionCallback functionkindstring"pre", "post", or "secure"enabledbooleanWhether hook is active
Hook Management
MethodDescriptionmanager:get(id)Retrieve hook by IDmanager:enable(id)Activate specific hookmanager:disable(id)Deactivate specific hookmanager:toggle(id)Flip hook statemanager:remove(id)Remove hook from registrymanager:enableAll()Activate all hooksmanager:disableAll()Deactivate all hooksmanager:toggleAll()Flip all hook states
Usage Example:-- Create manager
local hookMgr = sfutil.HookManager:New("MyAddon")

-- Register hook
local mailHook = hookMgr:PreHook(MAIL_INBOX, "SendMail", function(...)
    -- Validate mail before sending
    return false  -- Allow original to run
end)

-- Later disable temporarily
hookMgr:disable(mailHook.id)
hookMgr:enable(mailHook.id)

-- On addon unload
hookMgr:disableAll()Event Manager (sfutil.EvtMgr)
Event and update timer registry for automatic cleanup and management.
Instance Creationlocal evtMgr = sfutil.EvtMgr:New("MyAddonName")Event Registration
MethodDescriptionmanager:registerEvt(event, callback)Register standard game eventmanager:filterEvt(event, callback)Add filter to registered eventmanager:registerUpdateEvt(name, interval, callback)Register periodic update timer
Cleanup Methods
MethodDescriptionmanager:unregEvt(event)Unregister specific eventmanager:unregUpdateEvt(name)Unregister specific timermanager:unregAllEvt()Unregister all tracked eventsmanager:unregAllUpdateEvt()Unregister all tracked timers
Best Practices:
```lua
-- Register on ADD_ON_LOADED
local function OnAddonLoaded(eventCode, addonName)
    if addonName ~= MY_ADDON_NAME then return end
    
    MY_EVT_MGR = sfutil.EvtMgr:New(MY_ADDON_NAME)
    
    MY_EVT_MGR:registerEvt(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventoryUpdate)
    MY_EVT_MGR:registerUpdateEvt("MyAddon_Timer", 1000, OnTimerTick)
end

-- Unregister on unload
local function OnAddonUnload(eventCode, addonName)
    if addonName ~= MY_ADDON_NAME then return end
    
    if MY_EVT_MGR then
        MY_EVT_MGR:unregAllEvt()
        MY_EVT_MGR:unregAllUpdateEvt()
        MY_EVT_MGR = nil
    end
end

EVENT_MANAGER:RegisterForEvent(MY_ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)
EVENT_MANAGER:RegisterForEvent(MY_ADDON_NAME, EVENT_ADD_ON_UNLOADING, OnAddonUnload)Event Name Lookup:local eventName = sfutil.EvtMgr_evtnames[EVENT_LOOT_RECEIVED]
-- "EVENT_LOOT_RECEIVED"
d("Event: " .. eventName)Logger System (sfutil.SafeLogger)
```

## Flexible logging system with multiple output modes.
### Logger Creation
Function|Description
sfutil.Createlogger(addonName)|Create logger instance
sfutil.SafeLogger(namespace, loggervar, addonname)|Get/create logger with safety checks
sfutil.SafeLoggerFunction(namespace, loggervar, addonname)|Return factory function for lazy creation
sfutil.CreateNilLogger(addonName)|Create disabled logger (no output)

### Logger API:
Method|Description
logger:Error(...)|Error level message
logger:Warn(...)|Warning level message
logger:Info(...)|Info level message
logger:Debug(...)|Debug level message (requires SetDebug(true))
logger:SetEnabled(bool)|Enable/disable all output
logger:SetDebug(bool)|Enable/disable debug output

Usage Example:
```lua
-- Recommended: Create factory function
local GetLogger = sfutil.SafeLoggerFunction(MyAddon, "logger", MyAddonName)

-- Later use
GetLogger():Info("Addon loaded successfully")
GetLogger():Debug("Detailed debug info")

-- Enable debug mode
GetLogger():SetDebug(true)
GetLogger():SetEnabled(true)Output Modes:
```
printDebug: Outputs to chat when enabled
LibDebugLogger: If available, integrates with LibDebugLogger addon
nilPrintDebug: Silent logger (useful for disabling all logging)

## Language Loading (sfutil.LoadLanguage)
Enhanced localization loading with SafeAddString support.
```lua
-- Enhanced SafeAddString
function sfutil.SafeAddString(stringId, stringValue, stringVersion)
    -- Handles string IDs, numeric IDs, and creation of new strings
endUsage Example:-- Define localization tables
local LOCALIZATION = {
    en = {
        [SI_MY_STRING_1] = "English text",
        [SI_MY_STRING_2] = "More English",
    },
    de = {
        [SI_MY_STRING_1] = "Deutscher Text",
        [SI_MY_STRING_2] = "Mehr Deutsch",
    },
}

-- Load based on client language
sfutil.LoadLanguage(LOCALIZATION, "en")  -- "en" is fallback

-- After loading
local text = GetString(SI_MY_STRING_1)  -- Returns correct language textGuild Helper Functions (sfutil.Guild)
```
Function|Description
--|--
sfutil.SafeGetGuildName(index)|Get guild name and ID (1–5), returns safe name on error
sfutil.GetActiveGuildNames()|Table of guild names indexed by position
sfutil.GetActiveGuildIds()|Table of guild IDs indexed by position

```lua
-- Get all guild information
local guildNames = sfutil.GetActiveGuildNames()
local guildIds = sfutil.GetActiveGuildIds()

for i = 1, #guildNames do
    d(i, guildNames[i], guildIds[i])
end
```
## Performance Considerations
### Memory Pooling
Several functions use pooled tables to reduce garbage collection:

sfutil.str() - Uses rslt_pool
sfutil.lstr() - Uses rslt_pool
sfutil.dstr() - Uses rslt_pool

These pools are cleared internally before each call, making them safe for single-threaded use but unsuitable for multi-threaded environments (not applicable to ESO).

## Optimizations

* Caching: SF_Color caches hex strings to avoid repeated formatting
* Early Exit: Guard clauses prevent unnecessary processing
* Tail Recursion: tcstr_tail avoids stack overflow on deep tables
* Safe Defaults: Nil inputs handled gracefully without errors



## Contributing
### When contributing to LibSFUtils:

* Follow existing naming conventions (sfutil.FunctionName)
* Include comprehensive documentation comments
* Test with nil inputs and edge cases
* Preserve backward compatibility where possible
* Add performance benchmarks for optimization changes
