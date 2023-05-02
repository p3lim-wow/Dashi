local _, addon = ...

function addon:OpenSettings(name)
	if addon:IsRetail() then
		Settings.OpenToCategory(name)
	else
		InterfaceOptionsFrame_OpenToCategory(name)
		InterfaceOptionsFrame_OpenToCategory(name) -- load twice due to an old bug
	end
end

function addon:HookSettings(callback)
	if addon:IsRetail() then
		SettingsPanel:HookScript('OnShow', callback)
	else
		InterfaceOptionsFrameAddOns:HookScript('OnShow', function(frame)
			callback(frame)

			-- we load too late, so we have to manually refresh the list
			InterfaceAddOnsList_Update()
		end)
	end
end
