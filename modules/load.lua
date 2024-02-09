local _, addon = ...

local IsAddOnLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded

local addonCallbacks = {}
--[[ namespace:HookAddOn(_addonName_, _callback_)
Registers a hook for when an addon with the name `addonName` loads with a `callback` function.
--]]
function addon:HookAddOn(addonName, callback)
	if IsAddOnLoaded(addonName) then
		callback(self)
	else
		table.insert(addonCallbacks, {
			addonName = addonName,
			callback = callback,
		})
	end
end

function addon:ADDON_LOADED(addonName)
	for _, info in next, addonCallbacks do
		if info.addonName == addonName then
			info.callback()
		end
	end
end

function addon:PLAYER_LOGIN()
	--[[ namespace:OnLogin()
	Shorthand for the [`PLAYER_LOGIN`](https://warcraft.wiki.gg/wiki/PLAYER_LOGIN).

	Usage:
	```lua
	function namespace:OnLogin()
	    -- player has logged in!
	end
	```
	--]]
	if addon.OnLogin then
		addon:OnLogin()
	end

	return true
end
