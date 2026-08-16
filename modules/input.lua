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
