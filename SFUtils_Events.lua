--[[
    EvtMgr is a utility class that acts as a registry for all events and update timers associated with 
        a specific addon instance. By centralizing event management, it eliminates the need to manually 
        track every RegisterForEvent or RegisterForUpdate call, significantly reducing the risk of "ghost" 
        event handlers that persist after an addon is disabled.

    Key Features:
        Automatic Tracking: Automatically records every event and update timer registered via the manager.
        Bulk Unregistration: One command (unregAllEvt) to unregister all events for the addon.
        Event Name Lookup: Provides a mapping of event codes to human-readable names for debugging.
        Separation of Concerns: Distinguishes between standard events (EVENT_*) and update 
            timers (RegisterForUpdate).
        Multiple Instances: Supports multiple managers per addon (e.g., one for core logic, one for UI) 
            by using unique names.

    Dependencies: Requires LibSFUtils and the ESO EVENT_MANAGER API. Inherits from ZO_Object.

    Best Practices

    Always Unregister: Always call unregAllEvt() and unregAllUpdateEvt() when your addon is 
        disabled or unloaded to prevent memory leaks and duplicate event firing if the addon 
        is reloaded.
    Unique Names for Updates: Ensure the name passed to registerUpdateEvt is unique across your 
        entire addon to avoid conflicts.
    Filters: Remember that filterEvt does not track the filter itself, but the filter is tied to 
        the event. If you unregister the event, the filter goes away automatically.
    Multiple Managers: If your addon has distinct modules (e.g., CombatModule, UIModule), consider 
        creating separate EvtMgr instances for each to manage their lifecycles independently.
--]]

-- LibSFUtils is already defined in prior loaded file
local sfutil = LibSFUtils or {}

-- convert event codes to event "names"
--[[
    sfutil.EvtMgr_evtnames

    A global table mapping event codes to their string names.

    Usage: Useful for debugging or logging.
    Example:
        local eventName = sfutil.EvtMgr_evtnames[EVENT_LOOT_RECEIVED]
        -- eventName will be "EVENT_LOOT_RECEIVED"
        d("Received event: " .. eventName)

    Note: If the ESO API is not fully loaded (e.g., in a unit test environment 
        without the game), this table may be empty. The code includes a guard 
        if EVENT_ACTION_LAYER_PUSHED then to prevent errors in such environments.
--]]
local evtnames = {}
sfutil.EvtMgr_evtnames = evtnames
do
    -- protect unit tests from having to define all of these when ESO is not available
    if EVENT_ACTION_LAYER_PUSHED then
        evtnames = {
            [EVENT_ACTION_LAYER_PUSHED] = "EVENT_ACTION_LAYER_PUSHED",
            [EVENT_ACTION_LAYER_POPPED] = "EVENT_ACTION_LAYER_POPPED",
            [EVENT_ADD_ON_LOADED] = "EVENT_ADD_ON_LOADED",
            [EVENT_BANK_IS_FULL] = "EVENT_BANK_IS_FULL",
            [EVENT_CLOSE_BANK] = "EVENT_CLOSE_BANK",
            [EVENT_CLOSE_GUILD_BANK] = "EVENT_CLOSE_GUILD_BANK",
            [EVENT_CLOSE_STORE] = "EVENT_CLOSE_STORE",
            [EVENT_GUILD_BANK_SELECTED] = "EVENT_GUILD_BANK_SELECTED",
            [EVENT_GUILD_BANK_ITEMS_READY] = "EVENT_GUILD_BANK_ITEMS_READY",
            [EVENT_GUILD_BANK_ITEM_ADDED] = "EVENT_GUILD_BANK_ITEM_ADDED",
            [EVENT_GUILD_BANK_ITEM_REMOVED] = "EVENT_GUILD_BANK_ITEM_REMOVED",
            [EVENT_GUILD_MEMBER_NOTE_CHANGED] = "EVENT_GUILD_MEMBER_NOTE_CHANGED",
            [EVENT_GUILD_MEMBER_RANK_CHANGED] = "EVENT_GUILD_MEMBER_RANK_CHANGED",
            [EVENT_GUILD_MEMBER_REMOVED] = "EVENT_GUILD_MEMBER_REMOVED",
            [EVENT_GUILD_SELF_JOINED_GUILD] = "EVENT_GUILD_SELF_JOINED_GUILD",
            [EVENT_GUILD_SELF_LEFT_GUILD] = "EVENT_GUILD_SELF_LEFT_GUILD",
            [EVENT_ITEM_COMBINATION_RESULT] = "EVENT_ITEM_COMBINATION_RESULT",
            [EVENT_ITEM_LAUNDER_RESULT] = "EVENT_ITEM_LAUNDER_RESULT",
            [EVENT_ITEM_SLOT_CHANGED] = "EVENT_ITEM_SLOT_CHANGED",
            [EVENT_INTERACTION_ENDED] = "EVENT_INTERACTION_ENDED",
            [EVENT_INVENTORY_IS_FULL] = "EVENT_INVENTORY_IS_FULL",
            [EVENT_INVENTORY_ITEMS_AUTO_TRANSFERRED_TO_CRAFT_BAG]
                        = "EVENT_INVENTORY_ITEMS_AUTO_TRANSFERRED_TO_CRAFT_BAG",
            [EVENT_INVENTORY_ITEM_DESTROYED] = "EVENT_INVENTORY_ITEM_DESTROYED",
            [EVENT_INVENTORY_ITEM_USED] = "EVENT_INVENTORY_ITEM_USED",
            [EVENT_INVENTORY_SINGLE_SLOT_UPDATE] = "EVENT_INVENTORY_SINGLE_SLOT_UPDATE",
            [EVENT_INVENTORY_SLOT_LOCKED] = "EVENT_INVENTORY_SLOT_LOCKED",
            [EVENT_INVENTORY_SLOT_UNLOCKED] = "EVENT_INVENTORY_SLOT_UNLOCKED",
            [EVENT_JUSTICE_BOUNTY_PAYOFF_AMOUNT_UPDATED] = "EVENT_JUSTICE_BOUNTY_PAYOFF_AMOUNT_UPDATED",
            [EVENT_JUSTICE_STOLEN_ITEMS_REMOVED] = "EVENT_JUSTICE_STOLEN_ITEMS_REMOVED",
            [EVENT_LOOT_CLOSED] = "EVENT_LOOT_CLOSED",
            [EVENT_LOOT_RECEIVED] = "EVENT_LOOT_RECEIVED",
            [EVENT_LOOT_UPDATED] = "EVENT_LOOT_UPDATED",
            [EVENT_OPEN_FENCE] = "EVENT_OPEN_FENCE",
            [EVENT_PLAYER_ACTIVATED] = "EVENT_PLAYER_ACTIVATED",
            [EVENT_SELL_RECEIPT] = "EVENT_SELL_RECEIPT",
            [EVENT_RETICLE_HIDDEN_UPDATE] = "EVENT_RETICLE_HIDDEN_UPDATE",
            [EVENT_STACKED_ALL_ITEMS_IN_BAG] = "EVENT_STACKED_ALL_ITEMS_IN_BAG",
            [EVENT_STEALTH_STATE_CHANGED] = "EVENT_STEALTH_STATE_CHANGED",
            [EVENT_TRADING_HOUSE_RESPONSE_RECEIVED] = "EVENT_TRADING_HOUSE_RESPONSE_RECEIVED",
            [EVENT_LUA_ERROR] = "EVENT_LUA_ERROR",
        }
    end
end


-- -----------------------------------------------------------------------
--[[
    EvtMgr:New(addonName)

    Creates a new Event Manager instance.

    Parameters:
        addonName (string): The name of the addon. This string is passed to EVENT_MANAGER as the owner identifier.
            Important: If you need to register the same event twice with different callbacks, create two 
            separate instances of EvtMgr with different names (or use the same name but ensure the callbacks 
            are distinct, though the manager tracks by event code).
    Returns: A new EvtMgr instance.
--]]
sfutil.EvtMgr = ZO_Object:Subclass()
function sfutil.EvtMgr:New(addonName)
    local o = ZO_Object.New(self)
	o.name = addonName
	o.eventsList = {}
	o.updatesList = {}
	return o
end

--[[
    manager:registerEvt(event, callback)

    Registers a standard game event for this addon.

    Parameters:
        event (number): The event code (e.g., EVENT_ADD_ON_LOADED).
        callback (function): The function to execute when the event fires.
    Behavior:
        Registers the event with EVENT_MANAGER.
        Adds the event code to the internal eventsList for tracking.
--]]
function sfutil.EvtMgr:registerEvt(event, ...)
	local name = evtnames[event] or tostring(event)
	table.insert(self.eventsList, event)
	EVENT_MANAGER:RegisterForEvent(self.name, event, ...)
end

--[[
    manager:filterEvt(event, callback)

    Adds a filter to an already registered event.

    Parameters:
        event (number): The event code.
        callback (function): The filter function.
    Behavior:
        Calls EVENT_MANAGER:AddFilterForEvent.
        Note: Filters are not tracked in the internal list. They are automatically removed by 
            the game engine when the main event is unregistered via unregEvt or unregAllEvt.
--]]
function sfutil.EvtMgr:filterEvt(event, ...)
	EVENT_MANAGER:AddFilterForEvent(self.name, event, ...)
end

--[[
    manager:registerUpdateEvt(name, interval, callback)

    Registers a periodic update timer.

    Parameters:
        name (string): A unique name for the update timer (e.g., "MyAddon_UpdateLoop").
        interval (number): Minimum interval in milliseconds between callbacks.
        callback (function): The function to execute periodically.
    Behavior:
        Registers the update with EVENT_MANAGER.
        Adds the name to the internal updatesList for tracking.
--]]
-- * EVENT_MANAGER:RegisterForUpdate(*string* _name_, *integer* _minInterval_, *function* _callback_)
-- ** _Returns:_ *bool* _ret_
--
function sfutil.EvtMgr:registerUpdateEvt(name, interval, callback, ...)
	--local name = evtnames[event] or event
	table.insert(self.updatesList, name)
	EVENT_MANAGER:RegisterForUpdate(name, interval, callback, ...)
end

--[[
    manager:unregEvt(event)

    Unregisters (removes) a specific registered event for this addon.

    Parameters: event (number): The event code to remove.
    Behavior:
        Calls EVENT_MANAGER:UnregisterForEvent.
        Removes the event from the internal eventsList.
        Any filters associated with this event are automatically cleared by the game engine.
        Works with Update Events too.
--]]
function sfutil.EvtMgr:unregEvt(event)
	EVENT_MANAGER:UnregisterForEvent(self.name, event)
	-- remove the event from our tracking list
	for k,evt in ipairs(self.eventsList) do
		if evt == event then
			--local name = evtnames[event] or event
			table.remove(self.eventsList,k)
			return
		end
	end
end

--[[
manager:unregUpdateEvt(name)

Unregisters a specific update timer.

    Parameters: name (string): The unique name used during registration.
    Behavior:
        Calls EVENT_MANAGER:UnregisterForUpdate.
        Removes the name from the internal updatesList.
--]]
function sfutil.EvtMgr:unregUpdateEvt(name)
	EVENT_MANAGER:UnregisterForUpdate(name)
	-- remove the event from our tracking list
	for k,uname in ipairs(self.updatesList) do
		if uname == name then
			table.remove(self.updatesList,k)
			return
		end
	end
end

--[[
manager:unregAllEvt()

Crucial: Unregisters all standard events tracked by this instance.

    Behavior: Iterates through eventsList and calls UnregisterForEvent for each.
    Best Practice: Call this in your addon's EVENT_ADD_ON_LOADED handler when the 
        addon is being unloaded (detected by checking if the event is EVENT_ADD_ON_LOADED 
        and the addon name matches, or in a dedicated cleanup function).
--]]
function sfutil.EvtMgr:unregAllEvt()
	for _,evt in ipairs(self.eventsList) do
		EVENT_MANAGER:UnregisterForEvent(self.name, evt)
	end
end

--[[
    manager:unregAllUpdateEvt()

    Unregisters all update timers tracked by this instance.

    Behavior: Iterates through updatesList and calls UnregisterForUpdate for each.
--]]
function sfutil.EvtMgr:unregAllUpdateEvt()
	for _,uname in ipairs(self.updatesList) do
		EVENT_MANAGER:UnregisterForUpdate(uname)
	end
end
