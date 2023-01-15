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
	if cvar == KEY_DIRECTION_CVAR then
		addon:Defer(updateKeyDirection, self)
	end
end

function addon:CreateButton(...)
	local button = CreateFrame(...)
	Mixin(button, addon.eventMixin)

	button:RegisterEvent('CVAR_UPDATE', onCVarUpdate)

	-- the CVar doesn't trigger during login, so we'll have to trigger the handlers ourselves
	onCVarUpdate(button, KEY_DIRECTION_CVAR)

	return button
end

local backdropMixin = {} -- custom "backdrop" with offset edges, instead of inset
function backdropMixin:SetBackgroundColor(...)
	self.backdropBackground:SetColorTexture(...)
end

function backdropMixin:SetBorderColor(...)
	for _, edge in next, self.backdropEdges do
		edge:SetColorTexture(...)
	end
end

function addon:AddBackdrop(frame)
	Mixin(frame, backdropMixin)
	frame.backdropEdges = {}

	local borderLeft = frame:CreateTexture(nil, 'BACKGROUND')
	borderLeft:SetPoint('TOPLEFT', -1, 1)
	borderLeft:SetPoint('BOTTOMLEFT', -1, -1)
	borderLeft:SetWidth(1)
	addon:SetPixelScale(borderLeft)
	table.insert(frame.backdropEdges, borderLeft)

	local borderRight = frame:CreateTexture(nil, 'BACKGROUND')
	borderRight:SetPoint('TOPRIGHT', 1, 1)
	borderRight:SetPoint('BOTTOMRIGHT', 1, -1)
	borderRight:SetWidth(1)
	addon:SetPixelScale(borderRight)
	table.insert(frame.backdropEdges, borderRight)

	local borderTop = frame:CreateTexture(nil, 'BACKGROUND')
	borderTop:SetPoint('TOPLEFT', -1, 1)
	borderTop:SetPoint('TOPRIGHT', 1, 1)
	borderTop:SetHeight(1)
	addon:SetPixelScale(borderTop)
	table.insert(frame.backdropEdges, borderTop)

	local borderBottom = frame:CreateTexture(nil, 'BACKGROUND')
	borderBottom:SetPoint('BOTTOMLEFT', -1, -1)
	borderBottom:SetPoint('BOTTOMRIGHT', 1, -1)
	borderBottom:SetHeight(1)
	addon:SetPixelScale(borderBottom)
	table.insert(frame.backdropEdges, borderBottom)

	local background = frame:CreateTexture(nil, 'BACKGROUND')
	background:SetAllPoints()
	addon:SetPixelScale(background)
	frame.backdropBackground = background

	-- set defaults
	frame:SetBackgroundColor(0, 0, 0, 0.3)
	frame:SetBorderColor(0, 0, 0)
end
