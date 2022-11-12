local _, addon = ...

-- game version API
function addon:IsRetail()
	return _G.WOW_PROJECT_ID == 'WOW_PROJECT_MAINLINE'
end

function addon:IsClassic()
	return _G.WOW_PROJECT_ID == 'WOW_PROJECT_CLASSIC'
end

function addon:IsClassicTBC()
	return _G.WOW_PROJECT_ID == 'WOW_PROJECT_BURNING_CRUSADE_CLASSIC'
end

function addon:IsClassicWrath()
	return _G.WOW_PROJECT_ID == 'WOW_PROJECT_WRATH_CLASSIC'
end

-- easy frame "removal"
local hidden = CreateFrame('Frame')
hidden:Hide()

function addon:Hide(object, ...)
	if type(object) == 'string' then
		object = _G[object]
	end

	if ... then
		-- iterate through arguments, they're children referenced by key
		for index = 1, select('#', ...) do
			object = object[select(index, ...)]
		end
	end

	object:SetParent(hidden)

	if object.UnregisterAllEvents then
		object:UnregisterAllEvents()
	end
end

-- random utilities
do
	local NPC_ID_PATTERN = '%w+%-.-%-.-%-.-%-.-%-(.-)%-'
	function addon:GetNPCID(unit)
		if unit then
			local npcGUID = UnitGUID(unit)
			if npcGUID then
				return tonumber(npcGUID:match(NPC_ID_PATTERN))
			end
		end
	end
end

do
	local ITEM_LINK_FORMAT = '|Hitem:%d|h'
	function addon:GetItemLinkFromID(itemID)
		return ITEM_LINK_FORMAT:format(itemID)
	end
end
