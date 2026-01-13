local SF = LibSFUtils

-------------------------------------------------
-- Constants
-------------------------------------------------
local ACCOUNT_WIDE = "Account-Wide"
local DEFAULT      = "Default"

-- default structure for addon savedtbl variables
local default = {
	--profile = ACCOUNT_WIDE,
}

-- default structure for saved variables profile tables
local default_profiles = {
	profiles = {
	},
	uses = {
	},
}

-- defaults of values that would be saved in a profile
local default_profile = {
	profileName = ACCOUNT_WIDE,

	-- addon-specific vars
	general = {
		closeLootWindow = false,
		turnOffGmAS = true,
		turnOffGmAL = false,
	},
}

local ProfMgmt = ZO_Object:Subclass()
SF.ProfileMgmt = ProfMgmt

-- convenience function for a call to Logger():Debug(SF.str(...))
-- only done for Debug() because there is no special handling for the other message levels
-- always returns nil
function ProfMgmt:logDebug(...)
    local n = select("#", ...)
    if n == 0 then return end

    local logger = self.Logger
    if not logger then return end
    -- skip parameter processing if they are not going to be used.
    if not logger.enabled or not logger.SFenableDebug then return end

    if n == 1 then
        logger:Debug(...)

    else
        logger:Debug(SF.str(...))
   end
end



function ProfMgmt:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end


-- addontbl - the table (namespace) for the parent addon
-- saved - the table for the addon's saved variables (used to save current profile name)
-- profSVname - the name for the profile saved variables (must add to parent .addon manifest)
-- default_profile - defaults of values that would be saved in a profile
function ProfMgmt:Initialize(addontbl, savedtbl, profSVname, def_profile, logger)
	self.parentns = addontbl
	self.parentsv = savedtbl
	self.profSVnm = profSVname
	self.default_profile = def_profile
    if not logger then logger = SF.logger end
    self.logger = logger
	return self
end

-- allows you to change the logger to be used by the profile
-- logger can be a function (a la the SF.SafeLoggerFunction()) where it will use the
-- provided function to create (or reference an already created) logger
-- if the logger is a table, we presume a well-formed logger class with the
-- standard methods. (See SFUtils_Logger.lua)
function ProfMgmt:SetLogger(logger)
    if type(logger) == "function" then
        self.logger = logger()
        return self.logger
    end
    if type(logger) == "table" then
        self.logger = logger
        return self.logger
    end

    self.logger = SF.logger
    return self.logger
end

-- Iterate through the list of profile names according to
-- a particular filter-function and collect the names of
-- the profiles that applies.
function ProfMgmt:_iterProfileNames(filterFn)
    local list = {}
    for name in pairs(self.profTbl.profiles) do
        if filterFn(name) then table.insert(list, name) end
    end
    return list
end

-- get a list of currently defined profile names
-- Includes "Account-Wide"
function ProfMgmt:getProfileNames()
    return self:_iterProfileNames(function(_) return true end)
end

-- Creates a list of names of existing profiles which
-- also includes "Default" and "Account-Wide"
function ProfMgmt:getCopyableProfileNames()
    return self:_iterProfileNames(function(name) return name ~= "" end) -- prepend static entries later
end

-- get a list of current user-created defined profile names
function ProfMgmt:getUserProfileNames()
    return self:_iterProfileNames(function(name)
        return name ~= "Account-Wide" and name ~= DEFAULT
    end)
end


-- is the profile name already in use?
function ProfMgmt:isNewProfileName(name)
    return self.profTbl.profiles[name] == nil
end

-- create a profile with the specified name and default values
function ProfMgmt:createProfile(name, from)
    assert(self:isNewProfileName(name),
           ("Profile %q already exists"):format(name))

    self.logger:Info("createProfile(): creating profile "..name)
    local profiles = self.profTbl.profiles
	local fromprof
	if from == nil or from == DEFAULT then
		from = DEFAULT
		fromprof = default_profile

	else
		fromprof = profiles[from]
		if not fromprof then
			from = DEFAULT
			fromprof = default_profile
		end
	end
	profiles[name] = SF.deepCopy(fromprof)
	if profiles[name] then
		self.logDebug("profTbl.profiles[", name, "] set to values from ", from)
		profiles[name].profileName = name

	else
		self.logDebug("profTbl.profiles[", name, "] set to nil")
	end
end

-- create a profile with the specified name and default values
function ProfMgmt:loadProfile(name, fromtbl)
    self.logger:Info("loadProfile(): loading profile "..name)
    local profiles = self.profTbl.profiles

    self:_log("Info", "Loaded profile %s from supplied table", name)

    name = name or DEFAULT
	if profiles[name] ~= nil then
		assert(profiles[name] ~= nil, "loadProfile(): trying to REload "..name)
	end

    profiles[name] = SF.deepCopy(fromtbl)
	if profiles[name] then
		self.logger:Debug(SF.str("profTbl.profiles[", name, "] set to values from ", fromtbl))
		profiles[name].profileName = name

	else
		self.logger:Debug("profTbl.profiles["..name.."] set to nil")
	end
end

-- delete the profile with the specified name
function ProfMgmt:deleteProfile(name)
	self.profTbl.profiles[name] = nil
	self.logger:Info("deleteProfile(): deleted profile "..name)
end

-- load saved variables
--    saved = character settings
--    profTbl = profiles settings
function ProfMgmt:loadsv()
    self.logger:Info("Starting ProfMgmt.loadsv")


    -- load our saved variables
	SF.saved = ZO_SavedVars:NewCharacterIdSettings(self.profSVnm.."C", 1, nil, default, GetWorldName())
	local prfnm = SF.saved.profileName

	self.profTbl = ZO_SavedVars:NewAccountWide(self.profSVnm, 1, nil, default_profiles, GetWorldName())
	SF.defaultMissing(self.profTbl, default_profiles)

	-- create a profTbl.profiles table if it does not exist
	self.profTbl.profiles = SF.safeTable(self.profTbl.profiles)
    local profiles = self.profTbl.profiles

	-- Create an Account-Wide profile if the profiles table is empty
	-- (and set it to the current profile for the character loaded in).
	if not next(self.profTbl.profiles) then
		self.logger:Warn("empty profiles table - creating a profile 'Account-Wide'")
		self:createProfile(ACCOUNT_WIDE)
		SF.saved.profileName = ACCOUNT_WIDE
		SF.currentProfile = profiles[ACCOUNT_WIDE]
		return

	-- if the character does not have an assigned profile then
	-- create "Account-Wide" and assign it.
	-- Should probably check first if "Account-Wide" already exists!
	elseif SF.saved.profileName == nil then
		self.logger:Warn("empty acct profile for character - looking for 'Account-Wide'")
		if not profiles[ACCOUNT_WIDE] then
			-- Create the Account-Wide profile
			self:createProfile(ACCOUNT_WIDE)
		end
		SF.saved.profileName = ACCOUNT_WIDE
		SF.currentProfile = ProfMgmt.profTbl.profiles[ACCOUNT_WIDE]
		return

	-- character assigned profile no longer exists, create it
	elseif profiles[SF.saved.profileName] == nil then
		self.logger:Warn(SF.str("acct profile ",prfnm, " not found - creating a profile ", SF.saved.profile))
		self:createProfile(prfnm)
		SF.currentProfile = profiles[prfnm]

	else
		self.logger:Info(SF.str("loading profile ", prfnm))
		SF.currentProfile = profiles[prfnm]
	end

end