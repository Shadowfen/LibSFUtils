## LoadLanguage()
`function LibSFUtils.LoadLanguage(localization_strings, defaultLang) `<br>
Add strings to the string table for the client language (or the default language if the client language did not have strings defined for it). The localization_strings parameter is a table of tables of localization strings, and defaultLang defaults to "en" if not provided.

For example: You could have the following string table defined:
```
local localization_strings = {
    de = {
        AC_IAKONI_TAG= "Iakoni's Gear Changer",
        AC_IAKONI_CATEGORY_SET_1= "Set#1",
        AC_IAKONI_CATEGORY_SET_1_DESC= "#1 Set aus dem AddOn Iakoni's Gear Changer",
        AC_IAKONI_CATEGORY_SET_2= "Set#2",
        AC_IAKONI_CATEGORY_SET_2_DESC= "#2 Set aus dem AddOn Iakoni's Gear Changer",
        AC_IAKONI_CATEGORY_SET_3= "Set#3",
        AC_IAKONI_CATEGORY_SET_3_DESC= "#3 Set aus dem AddOn Iakoni's Gear Changer",
        },
    
    en = {
        AC_IAKONI_TAG= "Iakoni's Gear Changer",
        AC_IAKONI_CATEGORY_SET_1= "Set#1",
        AC_IAKONI_CATEGORY_SET_1_DESC= "#1 Set from Iakoni's Gear Changer",
        AC_IAKONI_CATEGORY_SET_2= "Set#2",
        AC_IAKONI_CATEGORY_SET_2_DESC= "#2 Set from Iakoni's Gear Changer",
        AC_IAKONI_CATEGORY_SET_3= "Set#3",
        AC_IAKONI_CATEGORY_SET_3_DESC= "#3 Set from Iakoni's Gear Changer",
    },
       
    zh = {
        AC_IAKONI_TAG= "Iakoni's Gear Changer",
        AC_IAKONI_CATEGORY_SET_1= "装备配置#1",
        AC_IAKONI_CATEGORY_SET_1_DESC= "#1 号装备配置 Iakoni's Gear Changer",
        AC_IAKONI_CATEGORY_SET_2= "装备配置#2",
        AC_IAKONI_CATEGORY_SET_2_DESC= "#2 号装备配置 Iakoni's Gear Changer",
        AC_IAKONI_CATEGORY_SET_3= "装备配置#3",
        AC_IAKONI_CATEGORY_SET_3_DESC= "#3 号装备配置 Iakoni's Gear Changer",
    },
}
```
and then in your initialization function call:
```
    LibSFUtils.LoadLanguage(localization_strings,"en")
```    
or you can split the definitions of <br>
    `AC_localization_strings["en"]`, `AC_localization_strings["de"]`, and `AC_localization_strings["zh"]`
into separate files (strings.lua for the default, de.lua, zh.lua, etc) and then include your default 
language lua file (strings.lua), and $(language).lua in your addon manifest. This way you can only
load the strings for two languages (at most) instead of all of them you have available.

## SafeAddString()

`function sfutil.SafeAddString(stringId, stringValue, stringVersion)`

This enhanced version of ESO's SafeAddString() will create the
string if it does not already exist (new behaviour) and overwrite
the string if it does exist and is not an older version (original
behaviour).

* in the first use case, stringId is a "string" type
* in the second use case, stringId is a "number" type (the actual ID)
* a third use case allows using SafeAddString to overwrite an existing
  string definition with the "name" of the id passed in vs the numeric id

Note that based on testing of the 100026 version of ZOS's SafeAddString(),
it does NOT properly enforce version protection.

