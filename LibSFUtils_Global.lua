-- This is always the first source file loaded so that
-- it can create the addon table/namespace.

LibSFUtils = {
    name = "LibSFUtils",
    LibVersion = 50,    -- change this with every release!
    author = "Shadowfen",
}
if not LibDebugLogger then
	error("[LibSFUtils] LibDebugLogger has not yet been loaded. Cannot continue.")
end
LibSFUtils.logger = LibDebugLogger.Create("SFUtils")
LibSFUtils.logger:SetEnabled(true)
