local addonName, addon = ...

--[[ namespace:CreateFrame(_..._) ![](https://img.shields.io/badge/function-blue)
A wrapper for [`CreateFrame`](https://warcraft.wiki.gg/wiki/API_CreateFrame), mixed in with `namespace.eventMixin`.
--]]
function addon:CreateFrame(...)
	return Mixin(CreateFrame(...), addon.eventMixin)
end

do
	local KEY_DIRECTION_CVAR = 'ActionButtonUseKeyDown'
	local function updateKeyDirection(self)
		if C_CVar.GetCVarBool(KEY_DIRECTION_CVAR) then
			self:RegisterForClicks('AnyDown')
		else
			self:RegisterForClicks('AnyUp')
		end
	end

	local function onCVarUpdate(self, cvar)
		if cvar == KEY_DIRECTION_CVAR then
			addon:Defer(updateKeyDirection, self)
		end
	end

	--[[ namespace:CreateButton(_..._) ![](https://img.shields.io/badge/function-blue)
	A wrapper for `namespace:CreateFrame(...)`, but will handle key direction preferences of the client.  
	Use this specifically to create clickable buttons.
	--]]
	function addon:CreateButton(...)
		local button = addon:CreateFrame(...)
		button:RegisterEvent('CVAR_UPDATE', onCVarUpdate)

		-- the CVar doesn't trigger during login, so we'll have to trigger the handlers ourselves
		onCVarUpdate(button, KEY_DIRECTION_CVAR)

		return button
	end
end

local tooltip; do
	local function refreshTooltip(self)
		-- we need this to refresh tooltips when cache gets updated from TOOLTIP_DATA_UPDATE,
		-- but we can't use GameTooltip_OnUpdate because it taints secrets
		local info = self:GetPrimaryTooltipInfo()
		if info and info.getterName then
			-- this is so stupidly janky lol
			if self[info.getterName:gsub('Get','Set')](self, unpack(info.getterArgs or {})) then
				self:Show() -- re-render
			end
		end
	end

	--[[ namespace:GetTooltip(_..._) ![](https://img.shields.io/badge/function-blue)
	Creates and returns a tooltip specific for the addon.  
	The variable arguments are passed to [SetOwner](https://warcraft.wiki.gg/wiki/API_GameTooltip_SetOwner) if provided.
	--]]
	function addon:GetTooltip(...)
		if not tooltip then
			tooltip = CreateFrame('GameTooltip', addonName .. 'Tooltip', UIParent, 'GameTooltipTemplate')
			tooltip:SetFrameStrata('DIALOG')
			-- tooltip:HookScript('OnShow', GenerateFlatClosure(GameTooltip.Hide, GameTooltip))
			tooltip.RefreshDataNextUpdate = refreshTooltip

			-- hide this tooltip whenever GameTooltip shows up
			GameTooltip:HookScript('OnShow', GenerateFlatClosure(addon.HideTooltip))

			local embeddedItemTooltip = CreateFrame('Frame', nil, tooltip, 'InternalEmbeddedItemTooltipTemplate')
			embeddedItemTooltip:SetPoint('BOTTOMLEFT', 10, 13)
			embeddedItemTooltip:SetSize(100, 100)
			embeddedItemTooltip:Hide()
			embeddedItemTooltip.yspacing = 13
			tooltip.ItemTooltip = embeddedItemTooltip
		end

		if ... then
			tooltip:SetOwner(...)
		end

		return tooltip
	end

	--[[ namespace:GetTooltipWithDefaultAnchor(_[owner]_) ![](https://img.shields.io/badge/function-blue)
	Calls GetTooltip and anchors it to the default anchor.  
	This is a safe alternate to GameTooltip_SetDefaultAnchor.
	--]]
	function addon:GetTooltipWithDefaultAnchor(owner)
		local tooltip = addon:GetTooltip()
		tooltip:SetOwner(owner or UIParent, 'ANCHOR_NONE')
		tooltip:SetPoint('BOTTOMRIGHT', GameTooltipDefaultContainer)
		return tooltip
	end
end

--[[ namespace:HideTooltip() ![](https://img.shields.io/badge/function-blue)
Hide the tooltip created above.
--]]
function addon:HideTooltip()
	if tooltip then
		tooltip:Hide()
	end
end
