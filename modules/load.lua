local _, addon = ...

local addonCallbacks = {}
function addon:HookAddOn(addonName, callback)
	if IsAddOnLoaded(addonName) then
		callback()
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
	if addon.OnLogin then
		addon:OnLogin()
	end

	return true
end
