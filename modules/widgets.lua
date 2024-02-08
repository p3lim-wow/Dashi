local _, addon = ...

function addon:CreateFrame(...)
	return Mixin(CreateFrame(...), addon.eventMixin)
end

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

function addon:CreateButton(...)
	local button = addon:CreateFrame(...)
	button:RegisterEvent('CVAR_UPDATE', onCVarUpdate)

	-- the CVar doesn't trigger during login, so we'll have to trigger the handlers ourselves
	onCVarUpdate(button, KEY_DIRECTION_CVAR)

	return button
end
