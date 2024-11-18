local SF = LibSFUtils

local L = GetString

local profMgmt = ZO_Object:Subclass()
SF.ProfileMgmt = profMgmt

function profMgmt:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

-- addontbl - the table (namespace) for the parent addon
-- saved - the table for the addon's saved variables (used to save current profile name)
-- profSVname - the name for the profile saved variables (must add to parent .txt manifest)
-- default_profile - defaults of values that would be saved in a profile
function profMgmt:Initialize(addontbl, savedtbl, profSVname, default_profile)
	self.parentns = addontbl
	self.parentsv = savedtbl
	self.profSVnm = profSVname
	self.default_profile = default_profile
end


-- default structure for addon savedtbl variables
local default = {
	--profile = "Account-Wide",
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
	profileName = "Account-Wide",

	-- addon-specific vars
	general = {
		closeLootWindow = false,
		turnOffGmAS = true,
		turnOffGmAL = false,
	},
}


-- get a list of currently defined profile names
-- Includes "Account-Wide"
function profMgmt:getProfileNames()
	local nameList = {}
	for k,v in pairs(self.profTbl.profiles) do
		table.insert(nameList,k)
	end
	return nameList
end

-- Creates a list of names of existing profiles which
-- also includes "Default" and "Account-Wide"
function profMgmt:getCopyableProfileNames()
	local nameList = {"Default"}
	for k,v in pairs(self.profTbl.profiles) do
		table.insert(nameList,k)
	end
	return nameList
end

-- get a list of current user-created defined profile names
function profMgmt:getUserProfileNames()
	local nameList = {}
	for k,v in pairs(self.profTbl.profiles) do
		if not (k == "Account-Wide" or k == "Default") then
			table.insert(nameList,k)
		end
	end
	return nameList
end

-- is the profile name already in use?
function profMgmt:isNewProfileName(name)
	for k,v in pairs(self.profTbl.profiles) do
		if k == name then return false end
	end
	return true
end

-- create a profile with the specified name and default values
function profMgmt:createProfile(name, from)
    SF.logger:Info("createProfile(): creating profile "..name)
	local fromprof
	if from == nil or from == "Default" then
		from = "Default"
		fromprof = default_profile

	else
		fromprof = self.profTbl.profiles[from]
		if not fromprof then 
			from = "Default"
			fromprof = default_profile 
		end
	end
	self.profTbl.profiles[name] = SF.deepCopy(fromprof)
	if self.profTbl.profiles[name] then
		SF.logger:Debug("profTbl.profiles["..name.."] set to values from ",from)
		self.profTbl.profiles[name].profileName = name

	else
		SF.logger:Debug("profTbl.profiles["..name.."] set to nil")
	end
end

-- create a profile with the specified name and default values
function profMgmt:loadProfile(name, fromtbl)
    SF.logger:Info("loadProfile(): loading profile "..name)
	local fromprof
	if name == nil then
		name = "Default"
	end
	if self.profTbl.profiles[name] ~= nil then
		assert(self.profTbl.profiles[name] ~= nil, "loadProfile(): trying to REload "..name)
	end

	self.profTbl.profiles[name] = SF.deepCopy(fromtbl)
	if self.profTbl.profiles[name] then
		SF.logger:Debug("profTbl.profiles["..name.."] set to values from ",from)
		self.profTbl.profiles[name].profileName = name

	else
		SF.logger:Debug("profTbl.profiles["..name.."] set to nil")
	end
end

-- delete the profile with the specified name
function profMgmt:deleteProfile(name)
	self.profTbl.profiles[name] = nil
	SF.logger:Info("deleteProfile(): deleted profile "..name)
end

-- load saved variables
--    saved = character settings
--    profTbl = profiles settings
function profMgmt:loadsv()
    SF.logger:Info("Starting profMgmt.loadsv")

	local prfnm = SF.saved.profileName

    -- load our saved variables
	--SF.saved = ZO_SavedVars:NewCharacterIdSettings("TTFAS_VARS", 1, nil, default, GetWorldName())

	self.profTbl = ZO_SavedVars:NewAccountWide(self.profSVnm, 1, nil, default_profiles, GetWorldName())
	SF.defaultMissing(self.profTbl, default_profiles)

	-- create a profTbl.profiles table if it does not exist
	self.profTbl.profiles = SF.safeTable(self.profTbl.profiles)

	-- Create an Account-Wide profile if the profiles table is empty
	-- (and set it to the current profile for the character loaded in).
	if not next(self.profTbl.profiles) then
		SF.logger:Warn("empty profiles table - creating a profile 'Account-Wide'")
		self:createProfile("Account-Wide")
		SF.saved.profileName = "Account-Wide"
		SF.currentProfile = self.profTbl.profiles["Account-Wide"]
		return
		
	-- if the character does not have an assigned profile then
	-- create "Account-Wide" and assign it.
	-- Should probably check first if "Account-Wide" already exists!
	elseif SF.saved.profileName == nil then
		SF.logger:Warn("empty acct profile for character - looking for 'Account-Wide'")
		if not self.profTbl.profiles["Account-Wide"] then
			-- Create the Account-Wide profile
			self:createProfile("Account-Wide")
		end
		SF.saved.profileName = "Account-Wide"
		SF.currentProfile = profMgmt.profTbl.profiles["Account-Wide"]
		return

	-- character assigned profile no longer exists, create it
	elseif self.profTbl.profiles[SF.saved.profileName] == nil then
		SF.logger:Warn(SF.str("acct profile ",prfnm, " not found - creating a profile ", SF.saved.profile))
		self:createProfile(prfnm)
		SF.currentProfile = self.profTbl.profiles[prfnm]

	else
		SF.logger:Info(SF.str("loading profile ", prfnm))
		SF.currentProfile = self.profTbl.profiles[prfnm]
	end

end