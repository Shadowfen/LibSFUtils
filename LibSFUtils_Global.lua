-- This is always the first source file loaded so that
-- it can create the addon table/namespace.

LibSFUtils = {
    name = "LibSFUtils",
    LibVersion = 49,    -- change this with every release!
    author = "Shadowfen",
}

LibSFUtils.logger = LibDebugLogger.Create("SFUtils")
LibSFUtils.logger:SetEnabled(true)
