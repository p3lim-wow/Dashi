local addonName, addon = ...

--[[ namespace.eventMixin ![](https://img.shields.io/badge/object-teal)
A multi-purpose [event](https://warcraft.wiki.gg/wiki/Events)-[mixin](https://en.wikipedia.org/wiki/Mixin).

These methods are mixed into `namespace`, and thus are available directly, e.g:

```lua
namespace:RegisterEvent('BAG_UPDATE', function(self, ...)
    -- do something
end)
```
--]]

local eventHandler = CreateFrame('Frame')
local callbacks = {}

local IsEventValid
if addon:IsRetail() then
	IsEventValid = C_EventUtils.IsEventValid
else
	local eventValidator = CreateFrame('Frame')
	function IsEventValid(event)
		local isValid = pcall(eventValidator.RegisterEvent, eventValidator, event)
		if isValid then
			eventValidator:UnregisterEvent(event)
		end
		return isValid
	end
end

local unitEventValidator = CreateFrame('Frame')
local function IsUnitEventValid(event, unit)
	-- C_EventUtils.IsEventValid doesn't cover unit events, so we'll have to do this the old fashioned way
	local isValid = pcall(unitEventValidator.RegisterUnitEvent, unitEventValidator, event, unit)
	if isValid then
		unitEventValidator:UnregisterEvent(event)
	end
	return isValid
end

local unitValidator = CreateFrame('Frame')
local function IsUnitValid(unit)
	local success = pcall(unitValidator.RegisterUnitEvent, unitValidator, 'UNIT_HEALTH', unit)
	if not success then
		return false
	end

	local isRegistered, registeredUnit = unitValidator:IsEventRegistered('UNIT_HEALTH')
	unitValidator:UnregisterEvent('UNIT_HEALTH')

	return isRegistered and registeredUnit == unit
end

local eventMixin = {}
--[[ namespace.eventMixin:RegisterEvent(_event_, _callback_) ![](https://img.shields.io/badge/function-blue)
Registers a [frame `event`](https://warcraft.wiki.gg/wiki/Events) with the `callback` function.  
If the callback returns truthy it will be unregistered.
--]]
function eventMixin:RegisterEvent(event, callback)
	addon:ArgCheck(event, 1, 'string')
	addon:ArgCheck(callback, 2, 'function')
	addon:ArgAssert(IsEventValid(event), 1, 'invalid event')

	if not callbacks[event] then
		callbacks[event] = {}
	end

	table.insert(callbacks[event], {
		callback = callback,
		owner = self,
	})

	if not eventHandler:IsEventRegistered(event) then
		eventHandler:RegisterEvent(event)
	end
end

--[[ namespace.eventMixin:UnregisterEvent(_event_, _callback_) ![](https://img.shields.io/badge/function-blue)
Unregisters a [frame `event`](https://warcraft.wiki.gg/wiki/Events) from the `callback` function.
--]]
function eventMixin:UnregisterEvent(event, callback)
	addon:ArgCheck(event, 1, 'string')
	addon:ArgCheck(callback, 2, 'function')
	addon:ArgAssert(IsEventValid(event), 1, 'invalid event')

	if callbacks[event] then
		for index, data in next, callbacks[event] do
			if data.owner == self and data.callback == callback then
				callbacks[event][index] = nil
				break
			end
		end

		if #callbacks[event] == 0 then
			eventHandler:UnregisterEvent(event)
		end
	end
end

--[[ namespace.eventMixin:UnregisterAllEvents([_callback_]) ![](https://img.shields.io/badge/function-blue)
Unregisters all [frame events](https://warcraft.wiki.gg/wiki/Events), or specifically from the `callback` function.
--]]
function eventMixin:UnregisterAllEvents(callback)
	addon:ArgCheck(callback, 2, 'function|nil')

	for event, cbs in next, callbacks do
		for _, data in next, cbs do
			if data.owner == self then
				if callback then
					if data.callback == callback then
						self:UnregisterEvent(event, data.callback)
					end
				else
					self:UnregisterEvent(event, data.callback)
				end
			end
		end
	end
end

--[[ namespace.eventMixin:IsEventRegistered(_event_, _callback_) ![](https://img.shields.io/badge/function-blue)
Checks if the [frame `event`](https://warcraft.wiki.gg/wiki/Events) is registered with the `callback` function.
--]]
function eventMixin:IsEventRegistered(event, callback)
	addon:ArgCheck(event, 1, 'string')
	addon:ArgCheck(callback, 2, 'function')
	addon:ArgAssert(IsEventValid(event), 1, 'invalid event')

	if callbacks[event] then
		for _, data in next, callbacks[event] do
			if data.callback == callback then
				return true
			end
		end
	end
end

--[[ namespace.eventMixin:TriggerEvent(_event_[, _..._]) ![](https://img.shields.io/badge/function-blue)
Manually trigger the `event` (with optional arguments) on all registered callbacks.  
If the callback returns truthy it will be unregistered.
--]]
function eventMixin:TriggerEvent(event, ...)
	addon:ArgCheck(event, 1, 'string')
	addon:ArgAssert(IsEventValid(event), 1, 'invalid event')

	local callbacksForEvent = callbacks[event]
	if callbacksForEvent then
		for _, data in next, callbacksForEvent do
			if data.callback(data.owner, ...) then
				-- callbacks can unregister themselves by returning truthy,
				eventMixin.UnregisterEvent(data.owner, event, data.callback)
			end
		end
	end
end

eventHandler:SetScript('OnEvent', function(_, event, ...)
	eventMixin:TriggerEvent(event, ...)
end)

-- special handling for unit events
local unitEventHandlers = {}
local function getUnitEventHandler(unit)
	if not unitEventHandlers[unit] then
		local unitEventHandler = CreateFrame('Frame')
		unitEventHandler:SetScript('OnEvent', function(_, event, ...)
			eventMixin:TriggerUnitEvent(event, unit, ...)
		end)
		unitEventHandlers[unit] = unitEventHandler
	end
	return unitEventHandlers[unit]
end

local unitEventCallbacks = {}
--[[ namespace.eventMixin:RegisterUnitEvent(_event_, _unit_[, _unitN,..._], _callback_) ![](https://img.shields.io/badge/function-blue)
Registers a [`unit`](https://warcraft.wiki.gg/wiki/UnitId)-specific [frame `event`](https://warcraft.wiki.gg/wiki/Events) with the `callback` function.  
If the callback returns truthy it will be unregistered for that unit.
--]]
function eventMixin:RegisterUnitEvent(event, ...)
	addon:ArgCheck(event, 1, 'string')
	addon:ArgAssert(IsEventValid(event), 1, 'invalid event')

	local numArgs = select('#', ...)
	local callback = select(numArgs, ...)
	addon:ArgCheck(callback, numArgs + 1, 'function')

	local numUnits = numArgs - 1
	addon:ArgAssert(numUnits > 0, 2, 'invalid event')

	for i = 1, numUnits do
		local unit = select(i, ...)
		addon:ArgCheck(unit, i + 1, 'string')
		addon:ArgAssert(IsUnitValid(unit), i + 1, 'invalid unit')
		addon:ArgAssert(IsUnitEventValid(event, unit), i + 1, "event '" .. event .. "' is invalid for the unit '" .. unit .. "'")
	end

	for i = 1, numUnits do
		local unit = select(i, ...)
		if not unitEventCallbacks[unit] then
			unitEventCallbacks[unit] = {}
		end

		if not unitEventCallbacks[unit][event] then
			unitEventCallbacks[unit][event] = {}
		end

		local callbackIsRegisteredForUnitEvent
		local callbacksForUnitEvent = unitEventCallbacks[unit][event]
		for _, data in next, callbacksForUnitEvent do
			if data.owner == self and data.callback == callback then
				callbackIsRegisteredForUnitEvent = true
				break
			end
		end

		table.insert(callbacksForUnitEvent, {
			callback = callback,
			owner = self,
		})

		local unitEventHandler = getUnitEventHandler(unit)
		local isRegistered, registeredUnit = unitEventHandler:IsEventRegistered(event)
		if not isRegistered then
			unitEventHandler:RegisterUnitEvent(event, unit)
		elseif registeredUnit ~= unit then
			error('unit event somehow registered with the wrong unit')
		end
	end
end

--[[ namespace.eventMixin:UnregisterUnitEvent(_event_, _unit_[, _unitN,..._], _callback_) ![](https://img.shields.io/badge/function-blue)
Unregisters a [`unit`](https://warcraft.wiki.gg/wiki/UnitId)-specific [frame `event`](https://warcraft.wiki.gg/wiki/Events) from the `callback` function.
--]]
function eventMixin:UnregisterUnitEvent(event, ...)
	addon:ArgCheck(event, 1, 'string')
	addon:ArgAssert(IsEventValid(event), 1, 'invalid event')

	local numArgs = select('#', ...)
	local callback = select(numArgs, ...)
	addon:ArgCheck(callback, numArgs + 1, 'function')

	local numUnits = numArgs - 1
	addon:ArgAssert(numUnits > 0, 2, 'invalid event')

	for i = 1, numUnits do
		local unit = select(i, ...)
		addon:ArgCheck(unit, i + 1, 'string')
		addon:ArgAssert(IsUnitValid(unit), i + 1, 'invalid unit')
		addon:ArgAssert(IsUnitEventValid(event, unit), i + 1, "event '" .. event .. "' is invalid for the unit '" .. unit .. "'")
	end

	for i = 1, numUnits do
		local unit = select(i, ...)
		local callbackEventsForUnit = unitEventCallbacks[unit]
		local callbacksForUnitEvent = callbackEventsForUnit and callbackEventsForUnit[event]
		if callbacksForUnitEvent then
			for index, data in next, callbacksForUnitEvent do
				if data.owner == self and data.callback == callback then
					callbacksForUnitEvent[index] = nil
					break
				end
			end

			if #unitEventCallbacks[unit][event] == 0 then
				getUnitEventHandler(unit):UnregisterEvent(event)
			end
		end
	end
end

--[[ namespace.eventMixin:IsUnitEventRegistered(_event_, _unit_[, _unitN,..._], _callback_) ![](https://img.shields.io/badge/function-blue)
Checks if the [`unit`](https://warcraft.wiki.gg/wiki/UnitId)-specific [frame `event`](https://warcraft.wiki.gg/wiki/Events) is registered with the `callback` function.
--]]
function eventMixin:IsUnitEventRegistered(event, ...)
	addon:ArgCheck(event, 1, 'string')
	addon:ArgAssert(IsEventValid(event), 1, 'invalid event')

	local numArgs = select('#', ...)
	local callback = select(numArgs, ...)
	addon:ArgCheck(callback, numArgs + 1, 'function')

	local numUnits = numArgs - 1
	addon:ArgAssert(numUnits > 0, 2, 'invalid event')

	for i = 1, numUnits do
		local unit = select(i, ...)
		addon:ArgCheck(unit, i + 1, 'string')
		addon:ArgAssert(IsUnitValid(unit), i + 1, 'invalid unit')
		addon:ArgAssert(IsUnitEventValid(event, unit), i + 1, "event '" .. event .. "' is invalid for the unit '" .. unit .. "'")
	end

	for i = 1, numUnits do
		local unit = select(i, ...)
		local callbackEventsForUnit = unitEventCallbacks[unit]
		local callbacksForUnitEvent = callbackEventsForUnit and callbackEventsForUnit[event]
		if callbacksForUnitEvent then
			for _, data in next, callbacksForUnitEvent do
				if data.callback == callback then
					return true
				end
			end
		end
	end
end

--[[ namespace.eventMixin:TriggerEvent(_event_, _unit_[, _..._]) ![](https://img.shields.io/badge/function-blue)
Manually trigger the [`unit`](https://warcraft.wiki.gg/wiki/UnitId)-specific `event` (with optional arguments) on all registered callbacks.  
If the callback returns truthy it will be unregistered.
--]]
function eventMixin:TriggerUnitEvent(event, unit, ...)
	addon:ArgCheck(event, 1, 'string')
	addon:ArgAssert(IsEventValid(event), 1, 'invalid event')
	addon:ArgAssert(IsUnitValid(unit), 2, 'invalid unit')
	addon:ArgAssert(IsUnitEventValid(event, unit), 2, "event '" .. event .. "' is invalid for the unit '" .. unit .. "'")

	local callbackEventsForUnit = unitEventCallbacks[unit]
	local callbacksForUnitEvent = callbackEventsForUnit and callbackEventsForUnit[event]
	if callbacksForUnitEvent then
		for _, data in next, callbacksForUnitEvent do
			if data.callback(data.owner, ...) then
				-- callbacks can unregister themselves by returning truthy
				eventMixin.UnregisterUnitEvent(data.owner, event, unit, data.callback)
			end
		end
	end
end

-- expose mixin
addon.eventMixin = eventMixin

-- anonymous event registration
addon = setmetatable(addon, {
	__newindex = function(t, key, value)
		if key == 'OnLoad' then
			--[[ namespace:OnLoad() ![](https://img.shields.io/badge/function-blue)
			Shorthand for the [`ADDON_LOADED`](https://warcraft.wiki.gg/wiki/ADDON_LOADED) event for the addon.

			Usage:
			```lua
			function namespace:OnLoad()
			    -- I'm loaded!
			end
			```
			--]]
			addon:RegisterEvent('ADDON_LOADED', function(self, name)
				if name == addonName then
					if value(self) then
						return true -- pass along unregistration state
					end
				end
			end)
		elseif key == 'OnLogin' then
			--[[ namespace:OnLogin() ![](https://img.shields.io/badge/function-blue)
			Shorthand for the [`PLAYER_LOGIN`](https://warcraft.wiki.gg/wiki/PLAYER_LOGIN) event.

			Usage:
			```lua
			function namespace:OnLogin()
			    -- player has logged in!
			end
			```
			--]]
			addon:RegisterEvent('PLAYER_LOGIN', function(self)
				if value(self) then
					return true -- pass along unregistration state
				end
			end)
		elseif key == 'OnLogout' then
			--[[ namespace:OnLogout() ![](https://img.shields.io/badge/function-blue)
			Shorthand for the [`PLAYER_LOGOUT`](https://warcraft.wiki.gg/wiki/PLAYER_LOGOUT) event.

			Usage:
			```lua
			function namespace:OnLogout()
			    -- player has logged in!
			end
			```
			--]]
			addon:RegisterEvent('PLAYER_LOGOUT', function(self)
				if value(self) then
					return true -- pass along unregistration state
				end
			end)
		elseif type(key) == 'string' and IsEventValid(key) then
			--[[ namespace:_event_ ![](https://img.shields.io/badge/function-blue)
			Registers a  to an anonymous function.

			Usage:
			```lua
			function namespace:BAG_UPDATE(bagID)
			    -- do something
			end
			-- or
			namespace.BAG_UPDATE = function(self, bagID)
			    -- do something
			end
			```
			--]]
			eventMixin.RegisterEvent(t, key, value)
		else
			-- default table behaviour
			rawset(t, key, value)
		end
	end,
})

-- mixin to namespace
Mixin(addon, eventMixin)
