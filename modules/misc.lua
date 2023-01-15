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

	if object then
		object:SetParent(hidden)

		if object.UnregisterAllEvents then
			object:UnregisterAllEvents()
		end
	end
end

-- random utilities
do
	local GUID_PATTERN = '%w+%-.-%-.-%-.-%-.-%-(.-)%-'
	function addon:ExtractIDFromGUID(guid)
		return tonumber(guid:match(GUID_PATTERN))
	end
end

function addon:GetNPCID(unit)
	if unit then
		local npcGUID = UnitGUID(unit)
		return npcGUID and addon:ExtractIDFromGUID(npcGUID)
	end
end

do
	local ITEM_LINK_FORMAT = '|Hitem:%d|h'
	function addon:GetItemLinkFromID(itemID)
		return ITEM_LINK_FORMAT:format(itemID)
	end
end

function addon:GetPlayerMapID()
	-- TODO: maybe use HBD data if it's available
	return C_Map.GetBestMapForUnit('player') or -1
end

function addon:SetPixelScale(object)
	local _, screenHeight = GetPhysicalScreenSize()
	object:SetIgnoreParentScale(true)
	object:SetScale(768 / screenHeight)
end
