local addonName, addon = ...

function addon:Print(...)
	local msg = ... -- TODO: join message
	DEFAULT_CHAT_FRAME:AddMessage('|cff33ff99' .. addonName .. '|r: ' .. msg)
end

function addon:Printf(fmt, ...)
	self:Print(fmt:format(...))
end

function addon:Dump(value, startKey)
	DevTools_Dump(value, startKey)
end
