local addonName, addon = ...

function addon:Print(...)
	DEFAULT_CHAT_FRAME:AddMessage('|cff33ff99' .. addonName .. '|r: ' .. string.join(' ', ...))
end

function addon:Printf(fmt, ...)
	self:Print(fmt:format(...))
end

function addon:Dump(value, startKey)
	DevTools_Dump(value, startKey)
end
