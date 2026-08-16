local _, addon = ...

local queue = {}
local function iterate()
	for _, info in next, queue do
		if info.callback then
			info.callback(unpack(info.args))
		elseif info.object and info.args then
			info.object[info.method](info.object, unpack(info.args))
		end
	end

	table.wipe(queue)

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
			args = {...},
		})
	else
		callback(...)
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
			method = method,
			args = {...},
		})
	else
		object[method](object, ...)
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

--[[ namespace:DeferUnitEvent(_event_, _unit_[, _unitN,..._], _callback_[, _..._]) ![](https://img.shields.io/badge/function-blue)
Defers a function `callback` (with optional arguments) until after combat ends and `event` has triggered for _unit_(s).
Triggers when `event` triggers if not in combat.
--]]
function addon:DeferUnitEvent(event, ...)
	local args = {} -- we need to pack the args, sadly Lua 5.1 doesn't have table.pack
	local callback, unitindexlast, argindexfirst, lastindex
	for i = 1, select('#', ...) do
		local arg = select(i, ...)
		if not callback and type(arg) == 'function' then
			-- assume it's the callback
			callback = arg

			unitindexlast = i - 1
			argindexfirst = i + 1
		end

		args[i] = arg -- pack
		lastindex = i -- need to supply `last` to unpack since it'd stop unpacking when hitting nil
	end

	assert(callback, 'no callback provided')
	assert(unitindexlast > 0, 'no units provided')

	local closure = GenerateClosure(deferEventCallback, callback, unpack(args, argindexfirst, lastindex))
	addon:RegisterUnitEvent(event, unpack(args, 1, unitindexlast), closure)
end
