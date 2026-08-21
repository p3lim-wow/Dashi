local _, addon = ...

--[[ namespace:header
In each example `namespace` refers to the 2nd value of the addon vararg, e.g:

```lua
local _, namespace = ...
```
--]]

do
	-- hidden dummy frame we anchor regions we want to hide to
	local hidden = CreateFrame('Frame')
	hidden:Hide()

	--[[ namespace:Hide(_object_[, _child_, _..._]) ![](https://img.shields.io/badge/function-blue)
	Forcefully hide an `object`, or its `child`.  
	It will recurse down to the last child if provided.

	Usage:
	```lua
	namespace:Hide('ChatFrame2')
	namespace:Hide('MinimapCluster', 'InstanceDifficulty')
	namespace:Hide(someFrame, 'ResetButton')
	```
	--]]
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
			if object.SetRolesets then
				object:SetRolesets('alwaysBlocked')
			else
				object:Hide()
				object:SetParent(hidden)
			end
		end
	end
end

do
	local creatureNames = setmetatable({}, {
		__index = function(self, npcID)
			local data = C_TooltipInfo.GetHyperlink('unit:Creature-0-0-0-0-' .. npcID .. '-0')
			local name = data and data.lines and data.lines[1] and data.lines[1].leftText
			if name then
				rawset(self, npcID, name)
				return name
			end
		end
	})

	--[[ namespace:GetCreatureName(_creatureID_) ![](https://img.shields.io/badge/function-blue)
	Returns the name for the NPC by the given `npcID`.

	* Warning: this depends on the cache, and might not yield results the first time.
	--]]
	function addon:GetCreatureName(creatureID)
		return creatureNames[creatureID]
	end
end

do
	local ITEM_LINK_FORMAT = '|Hitem:%d|h'
	--[[ namespace:GetItemLinkFromID(_itemID_) ![](https://img.shields.io/badge/function-blue)
	Generates an [item link](https://warcraft.wiki.gg/wiki/ItemLink) from `itemID`.  
	This is a crude generation and won't have valid data for complex items.
	--]]
	function addon:GetItemLinkFromID(itemID)
		return ITEM_LINK_FORMAT:format(itemID)
	end
end

--[[ namespace:GetPlayerMapID() ![](https://img.shields.io/badge/function-blue)
Returns the ID of the current map/zone the player is located in.
--]]
function addon:GetPlayerMapID()
	-- TODO: maybe use HBD data if it's available
	return C_Map.GetBestMapForUnit('player') or -1
end

--[[ namespace:GetPlayerPosition(_mapID_) ![](https://img.shields.io/badge/function-blue)
Returns a position vector object of coordinates for the player in the given `mapID` (if they are valid).
--]]
function addon:GetPlayerPosition(mapID)
	return C_Map.GetPlayerMapPosition(mapID or addon:GetPlayerMapID(), 'player')
end

--[[ namespace:CreateColor(_r_, _g_, _b_[, _a_]) ![](https://img.shields.io/badge/function-blue)
Wrapper for CreateColor that can handle >1-255 range as well.  
Alpha (`a`) will always be in the 0-1 range.
--]]
--[[ namespace:CreateColor(_hex_) ![](https://img.shields.io/badge/function-blue)
Wrapper for CreateColor that can handle hex colors (both `RRGGBB` and `AARRGGBB`).
--]]
function addon:CreateColor(r, g, b, a)
	if type(r) == 'table' then
		return addon:CreateColor(r.r, r.g, r.b, r.a)
	elseif type(r) == 'string' then
		-- load from hex
		local hex = r:gsub('#', '')
		if #hex == 8 then
			-- prefixed with alpha
			a = tonumber(hex:sub(1, 2), 16) / 255
			r = tonumber(hex:sub(3, 4), 16) / 255
			g = tonumber(hex:sub(5, 6), 16) / 255
			b = tonumber(hex:sub(7, 8), 16) / 255
		elseif #hex == 6 then
			r = tonumber(hex:sub(1, 2), 16) / 255
			g = tonumber(hex:sub(3, 4), 16) / 255
			b = tonumber(hex:sub(5, 6), 16) / 255
		end
	elseif r > 1 or g > 1 or b > 1 then
		r = r / 255
		g = g / 255
		b = b / 255
	end

	return CreateColor(r, g, b, a)
end

do
	local timeFormatter = CreateFromMixins(SecondsFormatterMixin)
	timeFormatter:Init(1, SecondsFormatter.Abbreviation.OneLetter)
	timeFormatter:SetStripIntervalWhitespace(true)
	--[[ namespace:FormatTime(_timeInSeconds_) ![](https://img.shields.io/badge/function-blue)
	Formats the given `timeInSeconds` to a readable, but abbreviated format.
	--]]
	function addon:FormatTime(timeInSeconds)
		return timeFormatter:Format(tonumber(timeInSeconds))
	end
end

--[[ namespace:SafeSetTrue(_object_, _key_) ![](https://img.shields.io/badge/function-blue)
Safely set `object`'s `key` to `true` without tainting it.

Note: This is incredibly hacky and might be fixed.
--]]
function addon:SafeSetTrue(object, key)
	TextureLoadingGroupMixin.AddTexture({textures = object}, key)
end

--[[ namespace:SafeSetNil(_object_, _key_) ![](https://img.shields.io/badge/function-blue)
Safely set `object`'s `key` to `nil` without tainting it.

Note: This is incredibly hacky and might be fixed.
--]]
function addon:SafeSetNil(object, key)
	TextureLoadingGroupMixin.RemoveTexture({textures = object}, key)
end

--[[ namespace:GetEmptyBagSlot([_includeReagentBag_]) ![](https://img.shields.io/badge/function-blue)
Returns the bagID and slotIndex of the first empty bag slot, if any.
--]]
function addon:GetEmptyBagSlot(includeReagentBag)
	local numBags = Constants.InventoryConstants.NumBagSlots
	if includeReagentBag then
		numBags = numBags + Constants.InventoryConstants.NumReagentBagSlots
	end

	for bagID = Enum.BagIndex.Backpack, numBags do
		for slotIndex = 1, C_Container.GetContainerNumSlots(bagID) do
			if not C_Container.GetContainerItemInfo(bagID, slotIndex) then
				return bagID, slotIndex
			end
		end
	end
end
