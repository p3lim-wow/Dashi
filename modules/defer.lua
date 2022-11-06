local _, addon = ...

local deferQueue = {}
local function iterateQueue()
	for _, info in next, deferQueue do
		if info.parent and info.method then
			info.parent[info.method](unpack(info.args))
		elseif info.callback then
			info.callback(unpack(info.args))
		end
	end

	table.wipe(deferQueue)
	return true -- unregister itself
end

local function deferFunction(callback, ...)
	if InCombatLockdown() then
		table.insert(deferQueue, {
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

local function deferMethod(parent, method, ...)
	if InCombatLockdown() then
		table.insert(deferQueue, {
			parent = parent,
			method = method,
			args = {parent, ...},
		})

		if not addon:IsEventRegistered('PLAYER_REGEN_ENABLED', iterateQueue) then
			addon:RegisterEvent('PLAYER_REGEN_ENABLED', iterateQueue)
		end
	else
		parent[method](parent, ...)
	end
end

-- defer execution until after combat, or immediately if not in combat
-- usage: addon:Defer(callback, arg1[, ...])
--        addon:Defer(parent, 'method', arg1[, ...])
function addon:Defer(...)
	if type(select(1, ...)) == 'table' then
		assert(type(select(2, ...)) == 'string', 'arg2 must be the name of a method')
		assert(type(select(1, ...)[select(2, ...)]) == 'function', 'arg2 must be the name of a method')
		deferMethod(...)
	elseif type(select(1, ...)) == 'function' then
		deferFunction(...)
	else
		error('Invalid arguments passed to Defer')
	end
end
