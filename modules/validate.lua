local _, addon = ...

--[[ namespace:ArgCheck(arg, argIndex, types) ![](https://img.shields.io/badge/function-blue)
Checks if the argument `arg` at position `argIndex` is of `types`.  
Types can be one or multiple types, separated by |.
--]]
function addon:ArgCheck(arg, argIndex, expected)
	assert(type(argIndex) == 'number', "Bad argument #2 to 'ArgCheck' (number expected, got " .. type(argIndex) .. ')')
	assert(type(expected) == 'string', "Bad argument #3 to 'ArgCheck' (string expected, got " .. type(expected) .. ')')

	for expectedType in expected:gmatch('[^|]+') do
		if type(arg) == expectedType then
			return
		end
	end

	local name = debugstack(2, 2, 0):match(": in function [`<](.-)['>]")
	local types = expected:gsub('|', '/')
	error(string.format("Bad argument #%d to '%s' (%s expected, got %s)", argIndex, name, types, type(arg)), 3)
end
