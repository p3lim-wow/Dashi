local _, addon = ...

local eventHandler = CreateFrame('Frame')
local callbacks = {}

local eventValidator = CreateFrame('Frame')
local function IsUnitEventValid(event, unit)
	-- C_EventUntils.IsEventValid doesn't cover unit events, so we'll have to do this the old fashioned way
	local isValid = pcall(eventValidator.RegisterUnitEvent, eventValidator, event, unit)
	if isValid then
		eventValidator:UnregisterEvent(event)
	end
	return isValid
end

local unitValidator = CreateFrame('Frame')
local function IsUnitValid(unit)
	if unit == nil or unit == '' then
		return false -- BUG: RegisterUnitEvent lets these through
	end

	local isValid = pcall(unitValidator.RegisterUnitEvent, unitValidator, 'UNIT_HEALTH', unit)
	if isValid then
		local _, registeredUnit = unitValidator:IsEventRegistered('UNIT_HEALTH')
		unitValidator:UnregisterEvent('UNIT_HEALTH')
		return not not registeredUnit -- it will be nil if the registered unit is invalid
	end
end

local eventMixin = {}
function eventMixin:RegisterEvent(event, callback)
	assert(C_EventUtils.IsEventValid(event), 'arg1 must be an event')
	assert(type(callback) == 'function', 'arg2 must be a function')

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

function eventMixin:UnregisterEvent(event, callback)
	assert(C_EventUtils.IsEventValid(event), 'arg1 must be an event')
	assert(type(callback) == 'function', 'arg2 must be a function')

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

function eventMixin:IsEventRegistered(event, callback)
	assert(C_EventUtils.IsEventValid(event), 'arg1 must be an event')
	assert(type(callback) == 'function', 'arg2 must be a function')

	if callbacks[event] then
		for _, data in next, callbacks[event] do
			if data.callback == callback then
				return true
			end
		end
	end
end

function eventMixin:TriggerEvent(event, ...)
	if callbacks[event] then
		for _, data in next, callbacks[event] do
			if data.callback(data.owner, ...) then
				-- callbacks can unregister themselves by returning positively
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
function eventMixin:RegisterUnitEvent(event, ...)
	assert(C_EventUtils.IsEventValid(event), 'arg1 must be an event')
	local callback = select(select('#', ...), ...)
	assert(type(callback) == 'function', 'last argument must be a function')

	for i = 1, select('#', ...) - 1 do
		local unit = select(i, ...)
		assert(IsUnitValid(unit), 'arg' .. (i + 1) .. ' must be a valid unit')
		assert(IsUnitEventValid(event, unit), 'event is not valid for the given unit')

		if not unitEventCallbacks[unit] then
			unitEventCallbacks[unit] = {}
		end
		if not unitEventCallbacks[unit][event] then
			unitEventCallbacks[unit][event] = {}
		end

		table.insert(unitEventCallbacks[unit][event], {
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

function eventMixin:UnregisterUnitEvent(event, ...)
	assert(C_EventUtils.IsEventValid(event), 'arg1 must be an event')
	local callback = select(select('#', ...), ...)
	assert(type(callback) == 'function', 'last argument must be a function')

	for i = 1, select('#', ...) - 1 do
		local unit = select(i, ...)
		assert(IsUnitValid(unit), 'arg' .. (i + 1) .. ' must be a valid unit')
		assert(IsUnitEventValid(event, unit), 'event is not valid for the given unit')

		if unitEventCallbacks[unit] and unitEventCallbacks[unit][event] then
			for index, data in next, unitEventCallbacks[unit][event] do
				if data.owner == self and data.callback == callback then
					callbacks[event][index] = nil
					break
				end
			end

			if #unitEventCallbacks[unit][event] then
				getUnitEventHandler(unit):UnregisterEvent(event)
			end
		end
	end
end

function eventMixin:IsUnitEventRegistered(event, ...)
	assert(C_EventUtils.IsEventValid(event), 'arg1 must be an event')
	local callback = select(select('#', ...), ...)
	assert(type(callback) == 'function', 'last argument must be a function')

	for i = 1, select('#', ...) - 1 do
		local unit = select(i, ...)
		assert(IsUnitValid(unit), 'arg' .. (i + 1) .. ' must be a valid unit')
		assert(IsUnitEventValid(event, unit), 'event is not valid for the given unit')

		if unitEventCallbacks[unit] and unitEventCallbacks[unit][event] then
			for index, data in next, unitEventCallbacks[unit][event] do
				if data.callback == callback then
					return true
				end
			end
		end
	end
end

function eventMixin:TriggerUnitEvent(event, unit, ...)
	if unitEventCallbacks[unit] and unitEventCallbacks[unit][event] then
		for _, data in next, unitEventCallbacks[unit][event] do
			if data.callback(data.owner, ...) then
				-- callbacks can unregister themselves by returning positively
				eventMixin.UnregisterUnitEvent(data.owner, event, unit, data.callback)
			end
		end
	end
end

-- expose mixin
addon.eventMixin = eventMixin

-- anonymous event registration
addon = setmetatable(addon, {
	__index = function(t, key)
		if C_EventUtils.IsEventValid(key) then
			-- addon:EVENT_NAME([arg1[, ...]])
			return function(_, ...)
				eventMixin.TriggerEvent(t, key, ...)
			end
		else
			-- default table behaviour
			return rawget(t, key)
		end
	end,
	__newindex = function(t, key, value)
		if C_EventUtils.IsEventValid(key) then
			-- addon:EVENT_NAME(...) = function() end
			eventMixin.RegisterEvent(t, key, value)
		else
			-- default table behaviour
			rawset(t, key, value)
		end
	end,
})

-- mixin to namespace
Mixin(addon, eventMixin)
