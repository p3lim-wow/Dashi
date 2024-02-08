local _, addon = ...

-- game version API
local _, _, _, interfaceVersion = GetBuildInfo()
function addon:IsRetail()
	return interfaceVersion >= 10000
end

function addon:IsClassic()
	return interfaceVersion >= 20000 and interfaceVersion < 10000
end

function addon:IsClassicEra()
	return interfaceVersion < 20000
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
		object.SetParent = nop

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
		return npcGUID and addon:ExtractIDFromGUID(npcGUID), npcGUID
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

function addon:tsize(tbl)
	-- would really like Lua 5.2 for this
	local size = 0
	for _ in next, tbl do
		size = size + 1
	end
	return size
end

do
	local function auraSlotsWrapper(unit, spellID, token, ...)
		local slot, data
		for index = 1, select('#', ...) do
			slot = select(index, ...)
			data = C_UnitAuras.GetAuraDataBySlot(unit, slot)
			if spellID == data.spellId and data.sourceUnit and (UnitIsUnit('player', data.sourceUnit) or UnitIsOwnerOrControllerOfUnit('player', data.sourceUnit)) then
				return nil, data
			end
		end

		return token
	end

	--[[ addon:GetUnitAura(_unitID_, _spellID_, _filter_)
	Returns the aura by spellID on the unit, if it exists.

	* [`unitID`](https://wowpedia.fandom.com/wiki/UnitId)
	* `spellID` - spell ID to check for
	* `filter` - aura filter, see [UnitAura](https://warcraft.wiki.gg/wiki/API_UnitAura#Filters)
	--]]
	function addon:GetUnitAura(unit, spellID, filter)
		local token, data
		repeat
			token, data = auraSlotsWrapper(unit, spellID, UnitAuraSlots(unit, filter, nil, token))
		until token == nil

		return data
	end
end

function addon:GetPlayerPosition(mapID)
	local pos = C_Map.GetPlayerMapPosition(mapID, 'player')
	return pos and pos:GetXY()
end
