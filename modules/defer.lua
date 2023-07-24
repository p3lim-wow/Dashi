local _, addon = ...

local queue = {}
local function iterateQueue()
	for _, info in next, queue do
		if info.callback then
			info.callback(unpack(info.args))
		elseif info.object then
			info.object[info.method](unpack(info.args))
		end
	end

	table.wipe(queue)
	return true -- unregister itself
end

local function deferFunction(callback, ...)
	if InCombatLockdown() then
		table.insert(queue, {
			callback = callback,
			args = {...},
		})

		if not addon:IsEventRegistered('PLAYER_REGEN_ENABLED', iterateQueue) then
			addon:RegisterEvent('PLAYER_REGEN_ENABLED', iterateQueue)
		end
	else
		callback(...)
	end
end

local function deferGlobalFunction(func, ...)
	deferFunction(_G[func], ...)
end

local function deferMethod(object, method, ...)
	if InCombatLockdown() then
		table.insert(queue, {
			object = object,
			method = method,
			args = {...},
		})

		if not addon:IsEventRegistered('PLAYER_REGEN_ENABLED', iterateQueue) then
			addon:RegisterEvent('PLAYER_REGEN_ENABLED', iterateQueue)
		end
	else
		object[method](...)
	end
end

-- defer execution until after combat, or immediately if not in combat
-- usage: addon:Defer(callback, arg1[, ...])
--        addon:Defer(object, 'method'[, arg1[, ...]])
function addon:Defer(...)
	if type(select(1, ...)) == 'table' then
		assert(type(select(2, ...)) == 'string', 'arg2 must be the name of a method')
		assert(type(select(1, ...)[select(2, ...)]) == 'function', 'arg2 must be the name of a method')
		deferMethod(...)
	elseif type(select(1, ...)) == 'function' then
		assert(type(select(1, ...)) == 'function', 'arg1 must be a function')
		deferFunction(...)
	elseif type(select(1, ...)) == 'string' and type(_G[select(1, ...)]) == 'function' then
		assert(type(_G[select(1, ...)]) == 'function', 'arg1 must be a function')
		deferGlobalFunction(...)
	else
		error('Invalid arguments passed to Defer')
	end
end
