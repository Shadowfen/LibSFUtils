## String Utilities
### Concatenation Functions
Function|Description
--|--
sfutil.str(...)|Fast concatenation with circular reference protection
sfutil.lstr(...)|Like str() but treats numbers as localization IDs
sfutil.dstr(delim, ...)|Concatenation with delimiter between elements
sfutil.str1(...)|Legacy version (prefer sfutil.str)
sfutil.lstr1(...)|Legacy version (prefer sfutil.lstr)

#### Features:

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