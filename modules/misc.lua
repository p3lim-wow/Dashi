local _, addon = ...

--[[ namespace:header
In each example `namespace` refers to the 2nd value of the addon vararg, e.g:

```lua
local _, namespace = ...
```
--]]

-- game version API
local _, _, _, interfaceVersion = GetBuildInfo()
--[[ namespace:IsRetail()
Checks if the current client is running the "retail" version.
--]]
function addon:IsRetail()
	return interfaceVersion > 100000
end

--[[ namespace:IsClassicEra()
Checks if the current client is running the "classic era" version (e.g. vanilla).
--]]
function addon:IsClassicEra()
	return interfaceVersion < 20000
end

--[[ namespace:IsClassic()
Checks if the current client is running the "classic" version.
--]]
function addon:IsClassic()
	return not addon:IsRetail() and not addon:IsClassicEra()
end

--[[ namespace:ArgCheck(arg, argIndex, type[, type...])
Checks if the argument `arg` at position `argIndex` is of type(s).
--]]
function addon:ArgCheck(arg, argIndex, ...)
	assert(type(argIndex) == 'number', 'Bad argument #2 to \'ArgCheck\' (number expected, got ' .. type(argIndex) .. ')')

	for index = 1, select('#', ...) do
		if type(arg) == select(index, ...) then
			return
		end
	end

	local types = string.join(', ', ...)
	local name = debugstack(2, 2, 0):match(': in function [`<](.-)[\'>]')
	error(string.format('Bad argument #%d to \'%s\' (%s expected, got %s)', argIndex, name, types, type(arg)), 3)
end

-- easy frame "removal"
local hidden = CreateFrame('Frame')
hidden:Hide()

--[[ namespace:Hide(_object_[, _child_,...])
Forcefully hide an `object`, or its `child`.  
It will recurse down to the last child if provided.
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
	--[[ namespace:ExtractIDFromGUID(_guid_)
	Returns the integer `id` from the given [`guid`](https://warcraft.wiki.gg/wiki/GUID).
	--]]
	function addon:ExtractIDFromGUID(guid)
		return guid and tonumber(guid:match(GUID_PATTERN))
	end
end

--[[ namespace:GetNPCID(_unit_)
Returns the integer `id` of the given [`unit`](https://warcraft.wiki.gg/wiki/UnitId).
--]]
function addon:GetNPCID(unit)
	if unit and UnitExists(unit) then
		local npcGUID = UnitGUID(unit)
		return npcGUID and addon:ExtractIDFromGUID(npcGUID), npcGUID
	end
end

do
	local ITEM_LINK_FORMAT = '|Hitem:%d|h'
	--[[ namespace:GetItemLinkFromID(_itemID_)
	Generates an [item link](https://warcraft.wiki.gg/wiki/ItemLink) from an `itemID`.  
	This is a crude generation and won't have valid data for complex items.
	--]]
	function addon:GetItemLinkFromID(itemID)
		return ITEM_LINK_FORMAT:format(itemID)
	end
end

--[[ namespace:GetPlayerMapID()
Returns the ID of the current map the zone the player is located in.
--]]
function addon:GetPlayerMapID()
	-- TODO: maybe use HBD data if it's available
	return C_Map.GetBestMapForUnit('player') or -1
end

--[[ namespace:GetPlayerPosition(_mapID_)
Returns the `x` and `y` coordinates for the player in the given `mapID` (if they are valid).
--]]
function addon:GetPlayerPosition(mapID)
	local pos = C_Map.GetPlayerMapPosition(mapID, 'player')
	if pos then
		return pos:GetXY()
	end
end

--[[ namespace:tsize(_table_)
Returns the number of entries in the `table`.  
Works for associative tables as opposed to `#table`.
--]]
function addon:tsize(tbl)
	-- would really like Lua 5.2 for this
	local size = 0
	if tbl then
		for _ in next, tbl do
			size = size + 1
		end
	end
	return size
end

do
	local function auraSlotsWrapper(unit, spellID, token, ...)
		local slot, data
		for index = 1, select('#', ...) do
			slot = select(index, ...)
			data = C_UnitAuras.GetAuraDataBySlot(unit, slot)
			if spellID == data.spellId and data.sourceUnit then
				return nil, data
			end
		end

		return token
	end

	--[[ namespace:GetUnitAura(_unit_, _spellID_, _filter_)
	Returns the aura by `spellID` on the [`unit`](https://warcraft.wiki.gg/wiki/UnitId), if it exists.

	* [`unitID`](https://warcraft.wiki.gg/wiki/UnitId)
	* `spellID` - spell ID to check for
	* `filter` - aura filter, see [UnitAura](https://warcraft.wiki.gg/wiki/API_C_UnitAuras.GetAuraDataByIndex#Filters)
	--]]
	function addon:GetUnitAura(unit, spellID, filter)
		local token, data
		repeat
			token, data = auraSlotsWrapper(unit, spellID, C_UnitAuras.GetAuraSlots(unit, filter, nil, token))
		until token == nil

		return data
	end
end

--[[ namespace:CreateColor(r, g, b[, a])
Wrapper for CreateColor that can handle >1-255 range as well.  
Alpha (`a`) will always be in the 0-1 range.
--]]
--[[ namespace:CreateColor(hex)
Wrapper for CreateColor that can handle hex colors (both `RRGGBB` and `AARRGGBB`).
--]]
function addon:CreateColor(r, g, b, a)
	if type(r) == 'string' then
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

--[[ namespace:IsAddOnEnabled(addonName)
Checks whether the addon exists and is enabled.
--]]
function addon:IsAddOnEnabled(name)
	local _, _, _, loadable = C_AddOns.GetAddOnInfo(name)
	return not not loadable -- will be false if the addon is missing or disabled
end
