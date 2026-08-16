local _, addon = ...

--[[ namespace:ArgCheck(arg, argIndex, type[, type...]) ![](https://img.shields.io/badge/function-blue)
Checks if the argument `arg` at position `argIndex` is of `type`(s).
--]]
function addon:ArgCheck(arg, argIndex, ...)
	assert(type(argIndex) == 'number', 'Bad argument #2 to \'ArgCheck\' (number expected, got ' .. type(argIndex) .. ')')

	for index = 1, select('#', ...) do
		if type(arg) == select(index, ...) then
			return
		end
	end

	local types = string.join(', ', ...)
	local name = debugstack(2, 2, 0):match(': in function [`<](.-)[\'>]')
	error(string.format('Bad argument #%d to \'%s\' (%s expected, got %s)', argIndex, name, types, type(arg)), 3)
end
