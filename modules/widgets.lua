local _, addon = ...

local KEY_DIRECTION_CVAR = 'ActionButtonUseKeyDown'

local function updateKeyDirection(self)
	if C_CVar.GetCVarBool(KEY_DIRECTION_CVAR) then
		self:RegisterForClicks('AnyDown')
	else
		self:RegisterForClicks('AnyUp')
	end
end

local function onCVarUpdate(self, cvar)
	if not cvar or cvar == KEY_DIRECTION_CVAR then
		addon:Defer(updateKeyDirection, self)
	end
end

function addon:CreateButton(...)
	local button = CreateFrame(...)
	Mixin(button, addon.eventMixin)

	button:RegisterEvent('CVAR_UPDATE', onCVarUpdate)

	return button
end
