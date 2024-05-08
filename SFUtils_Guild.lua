local sfutil = LibSFUtils


-- ------------------------------------------------------
-- Guild helper functions



-- SafeGetGuildName(index)
--    where index is 1..5
--
-- returns: guild name, guild Id
--     or  "Invalid guild x", nil if no such guild
--
-- does not return nil for name! - if bad then return nil for guildId
function sfutil.SafeGetGuildName(index)

    -- Guildname
    local guildId = GetGuildId(index)
    if not guildId then 
        return ("Invalid guild " .. index),nil
    end
    local guildName = GetGuildName(guildId)

    -- Occurs sometimes
    if(not guildName or (guildName):len() < 1) then
        guildName = "Guild " .. guildId
    end
    return guildName, guildId
end


-- Get list of all active guild names in index order (1..5)
function sfutil.GetActiveGuildNames()
	local guildList = {}
	local numGuilds = GetNumGuilds()
	if numGuilds > 0 then
		local name, id
		for guild = 1, numGuilds do
			name, id = sfutil.SafeGetGuildName(guild)
			table.insert(guildList, name)
		end
	end	
	return guildList
end


-- Get list of all active guild ids in index order (1..5)
function sfutil.GetActiveGuildIds()
	local guildList = {}
	local numGuilds = GetNumGuilds()
	if numGuilds > 0 then
		local name, id
		for guild = 1, numGuilds do
			name, id = sfutil.SafeGetGuildName(guild)
			table.insert(guildList, id)
		end
	end	
	return guildList
end

