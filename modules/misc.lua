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
