## Overview
This is a library of common convenience functionality that I use with most of my addons. It is installed as a standalone library/addon. Load the library within your addon code using the global variable LibSFUtils
```
local SF = LibSFUtils
```
and then use the variables and functions defined in here with your local variable as the prefix for them. For example:
```
d(SF.bool2str(true))
```

## Strings

`function LibSFUtils.str(...) `<br>
Concatenate varargs to a string. Uses table concatenation to combine the parameters to be slightly more efficient to multiple uses of the `..` string concatenator. 

`function LibSFUtils.dstr(delim, ...) `<br>
Concatenate varargs to a delimited string. Uses table concatenation to combine the parameters separated by the specified delimiter to be slightly more efficient to multiple uses of the .. string concatenator. 

`function LibSFUtils.GetIconized(prompt, promptcolor, texturefile, texturecolor) `<br>
Create a string containing an optional icon (of optional color) followed by a text prompt. (Without the parameters, it simply prepares and optionally colorizes text.) The prompt parameter is a string or a localization string id. The color parameters are all hex colors. 

`function LibSFUtils.ColorText(prompt, promptcolor)` <br>
Create a string containing a text prompt and a text color. The text color is optional, but if you do not provide it, you just get the same text back that you put in. The prompt parameter is a string or a localization string id. The color parameter is a hex color. 

`function LibSFUtils.bool2str(bool) `<br>
Turn a boolean value into a string suitable for display. Returns the string "true" or "false". This function uses `LibSFUtils.isTrue()` to decide if bool is true - which will have different results from the lua standard definition of "true". Lua decides that anything not false (or nil) must be true (including 0). This function decides that anything not true (or 1) is false.

## Function Wrapping

`function LibSFUtils.WrapFunction(namespace, functionName, wrapper) `<br>
Used to be able to wrap an existing function with another so that subsequent calls to the function will actually invoke the wrapping function.

The wrapping function should accept a function as the first parameter, followed
by the parameters expected by the original function. It will be passed in the
original function so the wrapping function can call it (if it chooses).

Can be called with or without the namespace parameter (which defines the namespace
where the original function is defined). If the namespace parameter is not provided
then assume the global namespace _G.

Examples:
`WrapFunction(myfunc, mywrapper)`<br>
  will wrap the global function myfunc to call mywrapper

`WrapFunction(TT, myfunc, mywrapper)`<br>
  will wrap TT.myfunc with a call to mywrapper


## Basic Utility Functions

`function LibSFUtils.isTrue(val)` <br>
Returns true if val was some value equivalent to true or 1. Any other value will return false. (This is different from the lua standard definition of "true". Lua decides that anything not false (or nil) must be true (including 0). This function decides that anything not true (or 1) is false.) 

`function LibSFUtils.nilDefault( val, defaultval ) `<br>
Return the value of val; unless it is nil when we then will return defaultval instead of the nil.

The lua standard "`var = val or default`" does not do the same job,
because if val evaluates to false according to lua then the default 
value would still be assigned.
Here we specifically only want the default value if val == nil.

## Messages and Debug

`function LibSFUtils.initSystemMsgPrefix(addon_name, hexcolor)` <br>
Create a prefix to use in front of your messages (so that users can tell your messages from some other addon's). (If you are not using addonChatter.) 

`function LibSFUtils.systemMsg(prefix, text, hexcolor) `<br>
Send a message to the chat window prefixed by the prefix that you pass in. 

`function LibSFUtils.addonChatter:New(addon_name) `<br>
Create an addonChatter table and set up the prefix to use in front of your messages (so that users can tell your messages from some other addon's). 

`function LibSFUtils.addonChatter:systemMessage(...) `<br>
Print normal messages to chat function 

`LibSFUtils.addonChatter:debugMsg(...) `<br>
Print debug messages to chat if debug messages are enabled. 

`function LibSFUtils.addonChatter:enableDebug() `<br>
Turn on the printing of debug messages. 

`function LibSFUtils.addonChatter:disableDebug() `<br>
Turn off the printing of debug messages. 

`function LibSFUtils.addonChatter:toggleDebug() `<br>
Toggle on/off the printing of debug messages 

`function LibSFUtils.addonChatter:getDebugState()`<br>
Tell me if debug is currently on or off.

## Slash Commands

`function LibSFUtils.addonChatter:slashHelp(title, cmdstable)` <br>
Display in chat a table of slash commands with descriptions (using the addonChatter you have previously created)


