local addonName, addon = ...

function addon:RegisterSlash(...)
	local name = addonName .. 'Slash' .. math.random()
	local failed

	local numArgs = select('#', ...)
	local callback = select(numArgs, ...)
	if type(callback) ~= 'function' or numArgs < 2 then
		failed = true
	else
		for index = 1, numArgs - 1 do
			local slash = select(index, ...)
			if type(slash) ~= 'string' then
				failed = true
				break
			elseif not slash:match('^/%a+$') then
				failed = true
				break
			else
				_G['SLASH_' .. name .. index] = slash
			end
		end
	end

	if failed then
		error('Syntax: RegisterSlash("/slash1"[, "/slash2"[, ...]], callback)')
	else
		SlashCmdList[name] = callback
	end
end
