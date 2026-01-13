-- LibSFUtils is already defined in prior loaded file

LibSFUtils = LibSFUtils or {}
local sfutil = LibSFUtils

----------------------------
-- Character helpers
----------------------------

-- populate table of all character names on the current account indexed by unique ID
-- returns the server name, the account name, and the list of toons belonging to the account
function sfutil.LoadAcctChars( )
	local server = GetWorldName()
	local acct = GetDisplayName()

	local chars = {}

	-- Create entries for every character on the account
	for i = 1, GetNumCharacters() do
		local name, gender, level, classId, raceId, alliance, id, locationId = GetCharacterInfo(i)
		chars[id] = sfutil.SafeTable(chars[id])
		chars[id].server = server
		chars[id].account = acct
		chars[id].id = id
		chars[id].name = zo_strformat("<<1>>", name)
	end

	return server, acct, chars
end