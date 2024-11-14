local _, addon = ...

--[[ namespace:IsAddOnEnabled(addonName)
Checks whether the addon exists and is enabled.
--]]
function addon:IsAddOnEnabled(name)
	local _, _, _, loadable = C_AddOns.GetAddOnInfo(name)
	return not not loadable -- will be false if the addon is missing or disabled
end


local addonCallbacks = {}
--[[ namespace:HookAddOn(_addonName_, _callback_)
Registers a hook for when an addon with the name `addonName` loads with a `callback` function.
--]]
function addon:HookAddOn(addonName, callback)
	if C_AddOns.IsAddOnLoaded(addonName) then
		callback(self)
	else
		table.insert(addonCallbacks, {
			addonName = addonName,
			callback = callback,
		})
	end
end

addon:RegisterEvent('ADDON_LOADED', function(self, addonName)
	for _, info in next, addonCallbacks do
		if info.addonName == addonName then
			local successful, err = pcall(info.callback)
			if not successful then
				error(err)
			end
		end
	end
end)
