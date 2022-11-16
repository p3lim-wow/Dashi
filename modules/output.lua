local addonName, addon = ...

function addon:Print(...)
	-- can't use string join, it fails on nil values
	local msg = ''
	for index = 1, select('#', ...) do
		local arg = select(index, ...)
		if arg == nil then
			arg = 'nil'
		end

		msg = msg .. arg .. ' '
	end

	DEFAULT_CHAT_FRAME:AddMessage('|cff33ff99' .. addonName .. '|r: ' .. msg:trim())
end

function addon:Printf(fmt, ...)
	self:Print(fmt:format(...))
end

function addon:Dump(value, startKey)
	DevTools_Dump(value, startKey)
end
