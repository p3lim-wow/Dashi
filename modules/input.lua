local addonName, addon = ...

local counter = 0

--[[ namespace:RegisterSlash(_command_[, _commandN,..._], _callback_) ![](https://img.shields.io/badge/function-blue)
Registers chat slash `command`(s) with a `callback` function.

Usage:
```lua
namespace:RegisterSlash('/hello', '/hi', function(input)
    print('Hi')
end)
```
--]]
function addon:RegisterSlash(...)
	counter = counter + 1
	local name = addonName .. 'Slash' .. counter

	local numArgs = select('#', ...)
	addon:ArgAssert(numArgs >= 2, 2, 'at least one slash command and a callback must be supplied')

	local callback = select(numArgs, ...)
	addon:ArgCheck(callback, numArgs, 'function')

	for index = 1, numArgs - 1 do
		local slash = select(index, ...)
		addon:ArgCheck(slash, index, 'string')
		addon:ArgAssert(not not slash:match('^/%a+$'), index, 'invalid slash command')
	end

	for index = 1, numArgs - 1 do
		_G['SLASH_' .. name .. index] = select(index, ...)
	end

	SlashCmdList[name] = callback
end
