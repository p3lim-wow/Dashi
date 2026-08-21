local _, addon = ...

local queue = {}
local function iterate()
	local pending = queue
	queue = {}

	for _, info in ipairs(pending) do
		if info.callback then
			xpcall(info.callback, geterrorhandler(), addon:unpack(info.args))
		else
			xpcall(info.method, geterrorhandler(), info.object, addon:unpack(info.args))
		end
	end

	return true -- unregister event
end

local function defer(info)
	table.insert(queue, info)

	if not addon:IsEventRegistered('PLAYER_REGEN_ENABLED', iterate) then
		addon:RegisterEvent('PLAYER_REGEN_ENABLED', iterate)
	end
end

--[[ namespace:Defer(_callback_[, _..._]) ![](https://img.shields.io/badge/function-blue)
Defers a function `callback` (with optional arguments) until after combat ends.  
Callback can be the global name of a function.  
Triggers immediately if player is not in combat.
--]]
function addon:Defer(callback, ...)
	if type(callback) == 'string' then
		callback = _G[callback]
	end

	addon:ArgCheck(callback, 1, 'function')

	if InCombatLockdown() then
		defer({
			callback = callback,
			args = addon:pack(...),
		})
	else
		xpcall(callback, geterrorhandler(), ...)
	end
end

--[[ namespace:DeferMethod(_object_, _method_[, _..._]) ![](https://img.shields.io/badge/function-blue)
Defers a `method` on `object` (with optional arguments) until after combat ends.  
Triggers immediately if player is not in combat.
--]]
function addon:DeferMethod(object, method, ...)
	addon:ArgCheck(object, 1, 'table')
	addon:ArgCheck(method, 2, 'string')
	addon:ArgCheck(object[method], 2, 'function')

	if InCombatLockdown() then
		defer({
			object = object,
			method = object[method],
			args = addon:pack(...),
		})
	else
		xpcall(object[method], geterrorhandler(), object, ...)
	end
end

local function deferEventCallback(callback, ...)
	addon:Defer(callback, ...)
	return true -- always unregister, don't want this event to trigger multiple defers
end

--[[ namespace:DeferEvent(_event_, _callback_[, _..._]) ![](https://img.shields.io/badge/function-blue)
Defers a function `callback` (with optional arguments) until after combat ends and `event` has triggered.
Triggers when `event` triggers if not in combat.
--]]
function addon:DeferEvent(event, callback, ...)
	addon:ArgCheck(event, 1, 'string')
	addon:ArgCheck(callback, 2, 'function')
	addon:RegisterEvent(event, GenerateClosure(deferEventCallback, callback, ...))
end

--[[ namespace:DeferUnitEvent(_event_, _unit_[, ..., _unitN_], _callback_[, _..._]) ![](https://img.shields.io/badge/function-blue)
Defers a function `callback` (with optional arguments) until after combat ends and `event` has triggered for _unit_(s).
Triggers when `event` triggers if not in combat.
--]]
function addon:DeferUnitEvent(event, ...)
	addon:ArgCheck(event, 1, 'string')

	local args = addon:pack(...)
	local callback, callbackIndex

	for index = 1, args.n do
		if type(args[index]) == 'function' then
			callback = args[index]
			callbackIndex = index
			break
		else
			-- any vararg before the callback must be a unit
			addon:ArgCheck(args[index], index + 1, 'string')
		end
	end

	addon:ArgCheck(callback, 3, 'function', 'no callback provided')

	local closure = GenerateClosure(deferEventCallback, callback, unpack(args, callbackIndex + 1, args.n))
	addon:RegisterUnitEvent(event, unpack(args, 1, callbackIndex - 1), closure)
end
