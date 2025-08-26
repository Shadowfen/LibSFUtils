-- LibSFUtils is already defined in prior loaded file
local sfutil = LibSFUtils or {}

-- convert event codes to event "names"
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
-- A utility class to keep track of addOn-registered events, and make
-- it easy to unregister them all.
--
-- The instance of the class is created with the addon name, which is used
-- to register all tracked events under.
--
-- If you need to have multiple registrations of the same event (which need
-- different names), then create multiple instances of EvtMgr, each with a
-- different name.
sfutil.EvtMgr = ZO_Object:Subclass()
function sfutil.EvtMgr:New(addonName)
    local o = ZO_Object.New(self)
	o.name = addonName
	o.eventsList = {}
	o.updatesList = {}
	return o
end

-- Add an event to register for this addon, with the appropriate
-- parameters for it.
function sfutil.EvtMgr:registerEvt(event, ...)
	local name = evtnames[event] or tostring(event)
	table.insert(self.eventsList, event)
	EVENT_MANAGER:RegisterForEvent(self.name, event, ...)
end

-- Add a filter for a registered event for this addon, with the appropriate
-- parameters for it.  (Note that filters are not tracked.)
function sfutil.EvtMgr:filterEvt(event, ...)
	EVENT_MANAGER:AddFilterForEvent(self.name, event, ...)
end

-- Add an updating event to register for this addon, with the appropriate
-- parameters for it.
-- * RegisterForUpdate(*string* _name_, *integer* _minInterval_, *function* _callback_)
-- ** _Returns:_ *bool* _ret_
--
function sfutil.EvtMgr:registerUpdateEvt(name, interval, callback, ...)
	--local name = evtnames[event] or event
	table.insert(self.updatesList, name)
	EVENT_MANAGER:RegisterForUpdate(name, interval, callback, ...)
end

-- Unregister (remove) a particular registered event for this addon.
-- Associated filters will also go away when the event is unregistered
-- by the game. Works with Update Events too.
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

-- Unregister ALL events currently tracked by this EvtMgr instance.
function sfutil.EvtMgr:unregAllEvt()
	for _,evt in ipairs(self.eventsList) do
		--local name = evtnames[evt] or evt
		EVENT_MANAGER:UnregisterForEvent(self.name, evt)
	end
end

function sfutil.EvtMgr:unregAllUpdateEvt()
	for _,uname in ipairs(self.updatesList) do
		EVENT_MANAGER:UnregisterForUpdate(uname)
	end
end
