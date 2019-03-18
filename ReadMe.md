LibSFUtils
A library of common convenience functionality that I use with most of my addons.


Colors

Convenience color tables
Defines values for : junk, normal, fine, superior, epic, legendary
as well as some other colors that I commonly use

sfutil.colors - master table of colors in both hex and rgb
sfutil.hex - an alias table for just the hex color values
sfutil.rgb - an alias table for just the rgb color values


Strings

function sfutil.str(...)
    Concatenate varargs to a string. Uses table concatenation to combine the parameters
    to be slightly more efficient to multiple uses of the .. string concatenator.
function sfutil.dstr(delim, ...)
    Concatenate varargs to a delimited string. Uses table concatenation to combine the 
    parameters separated by the specified delimiter to be slightly more efficient to 
    multiple uses of the .. string concatenator.
function sfutil.GetIconized(prompt, promptcolor, texturefile, texturecolor)
    Create a string containing an optional icon (of optional color) followed by a text
    prompt. (Without the  parameters, it simply prepares and optionally colorizes text.)
    The prompt parameter is a string or a localization string id.
    The color parameters are all hex colors.
function sfutil.ColorText(prompt, promptcolor)
    Create a string containing a text prompt and a text color. The text color is optional, but
    if you do not provide it, you just get the same text back that you put in.
    The prompt parameter is a string or a localization string id.
    The color parameter is a hex color.
function sfutil.bool2str(bool)
    Turn a boolean value into a string suitable for display. Returns the string "true" or "false".
    This function uses sfutil.isTrue() to decide if bool is true - which will have different
    results from the lua standard definition of "true". Lua decides that anything not false (or nil) must
    be true (including 0). This function decides that anything not true (or 1) is false.


Function Wrapping

function sfutil.WrapFunction(namespace, functionName, wrapper)
    Used to be able to wrap an existing function with another so that subsequent
    calls to the function will actually invoke the wrapping function.

    The wrapping function should accept a function as the first parameter, followed
    by the parameters expected by the original function. It will be passed in the
    original function so the wrapping function can call it (if it chooses).

    Can be called with or without the namespace parameter (which defines the namespace
    where the original function is defined). If the namespace parameter is not provided
    then assume the global namespace _G.

    Examples:
    WrapFunction(myfunc, mywrapper)
      will wrap the global function myfunc to call mywrapper

    WrapFunction(TT, myfunc, mywrapper)
      will wrap TT.myfunc with a call to mywrapper

      
Saved Variables and Defaults

(All of the Saved Variables functions work on the variables for the 
current server that you are logged in on.)

Note: You should only ever use one of the functions getToonSavedVars(), getAcctSavedVars(), 
or getAllSavedVars() because they are loading saved variables from files (that only get changed
when you log out or /reloadui) and so are very slow and you don't want to waste time doing it
multiple times for no good reason.

function sfutil.getToonSavedVars(saveFile, saveVer, saveDefaults)
    Get saved variables table toon only. In addition to calling the appropriate ZO_SavedVars function,
    it will call sfutil.defaultMissing().
    Note: This does NOT automatically add an accountWide variable to the
       table if it is not already there!
function sfutil.getAcctSavedVars(saveFile, saveVer, saveDefaults)
    Get saved variables table account-wide only. In addition to calling the appropriate 
    ZO_SavedVars function, it will call sfutil.defaultMissing().
function sfutil.getAllSavedVars(saveFileName, saveVer, saveAWDefaults, saveToonDefaults)
    Get saved variables tables when we deal with both toon and account-wide settings.
    
    Toon and account-wide can have different default tables (but don't have to).
    If you only specify one default table it will be used for both account-wide and toon.
    
    An "accountWide" variable will be automatically added to the toon table if it 
    does not already exist, because the currentSavedVars() function works off of that.
    It is used to designate whether the settings for account-wide are currently in effect
    or the toon settings are in effect.
function sfutil.currentSavedVars(aw, toon, newAcctWideVal)
    Return the currently active table of saved variables.
    If newAcctWideVal is not nil, then the toon.accountWide value will be set to the new value 
    before deciding which of the tables aw or toon will be returned (based on if toon.accountWide 
    evaluates to true or false).
function sfutil.defaultMissing(svtable, defaulttable)
    Recursively initialize missing values in a table from a defaults table. Existing values in the 
    svtable will remain unchanged. This function is needed because the ZO_SavedVars functions do not
    recurse into a table inside the defaulttable if the table itself exists in svtable.

    
Basic Utility Functions

function sfutil.isTrue(val)
    Returns true if val was some value equivalent to true or 1.
    Any other value will return false.
    (This is different from the lua standard definition of "true". 
    Lua decides that anything not false (or nil) must be true (including 0). 
    This function decides that anything not true (or 1) is false.)
function sfutil.nilDefault( val, defaultval )
    Return the value of val; unless it is nil when we then will 
    return defaultval instead of the nil.
    
    The lua standard "var = val or default" does not do the same job,
    because if val evaluates to false according to lua then the default 
    value would still be assigned.
    Here we specifically only want the default value if val == nil.

    
Messages and Debug

function sfutil.initSystemMsgPrefix(addon_name, hexcolor)
    Create a prefix to use in front of your messages (so that users can tell your
    messages from some other addon's). (If you are not using addonChatter.)
function sfutil.systemMsg(prefix, text, hexcolor)
    Send a message to the chat window prefixed by the prefix that you pass in.
function sfutil.addonChatter:New(addon_name)
    Create an addonChatter table and set up the prefix to use
    in front of your messages (so that users can tell your
    messages from some other addon's).
function sfutil.addonChatter:systemMessage(...)
    Print normal messages to chat
function sfutil.addonChatter:debugMsg(...)
    Print debug messages to chat if debug messages are enabled.
function sfutil.addonChatter:enableDebug()
    Turn on the printing of debug messages.
function sfutil.addonChatter:disableDebug()
    Turn off the printing of debug messages.
function sfutil.addonChatter:toggleDebug()
    Toggle on/off the printing of debug messages
function sfutil.addonChatter:getDebugState()


Slash Commands

function sfutil.addonChatter:slashHelp(title, cmdstable)
    Display in chat a table of slash commands with descriptions
    (using the addonChatter you have previously created)

