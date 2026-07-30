## Table Utilities

Function|Description
--|--
sfutil.safeTable(tbl)|Return table or empty {}
sfutil.safeClearTable(tbl)|Clear all entries safely
sfutil.deepCopy(orig, seen)|Deep copy with circular reference protection
sfutil.defaultMissing(saved, defaults)|Fill missing keys without overwriting
sfutil.getSize(tbl)|Count keys (handles non-contiguous tables)
sfutil.isEmpty(tbl)|Check if table has no keys (returns nil for non-tables)
sfutil.RemainsInList(listA, listB)|Find items in A not present in B
sfutil.dTable(vtable, depth, name)|Debug string representation

### Configuration Merging Example:
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