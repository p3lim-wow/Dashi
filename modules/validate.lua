local _, namespace = ...

--[[ namespace:ArgCheck(_arg_, _argIndex_, _types_[, _message_][, _..._]) ![](https://img.shields.io/badge/function-blue)
Checks if the argument `arg` at position `argIndex` is of `types`.  
Types can be one or multiple types, separated by |.

The `message` will be formatted with the variable arguments if provided.
--]]
function namespace:ArgCheck(arg, argIndex, expected, message, ...)
	assert(type(argIndex) == 'number', "Bad argument #2 to 'ArgCheck' (number expected, got " .. type(argIndex) .. ')')
	assert(type(expected) == 'string', "Bad argument #3 to 'ArgCheck' (string expected, got " .. type(expected) .. ')')

	for expectedType in expected:gmatch('[^|]+') do
		if type(arg) == expectedType then
			return
		end
	end

	local name = debugstack(2, 2, 0):match(": in function ['`<](.-)['>]")
	if message then
		error(string.format("Bad argument #%d to '%s' (%s)", argIndex, name, message:format(...)), 3)
	end

	local types = expected:gsub('|', '/')
	error(string.format("Bad argument #%d to '%s' (%s expected, got %s)", argIndex, name, types, type(arg)), 3)
end

--[[ namespace:ArgAssert(_state_, _argIndex_, _message_[, _..._]) ![](https://img.shields.io/badge/function-blue)
If state is false; throw an error for arg at index `argIndex` with a `message`.

The `message` will be formatted with the variable arguments if provided.
--]]
function namespace:ArgAssert(state, argIndex, message, ...)
	assert(type(state) == 'boolean', "Bad argument #1 to 'ArgAssert' (boolean expected, got " .. type(state) .. ')')
	assert(type(argIndex) == 'number', "Bad argument #2 to 'ArgAssert' (number expected, got " .. type(argIndex) .. ')')
	assert(type(message) == 'string', "Bad argument #3 to 'ArgAssert' (string expected, got " .. type(message) .. ')')

	if not state then
		local name = debugstack(2, 2, 0):match(": in function ['`<](.-)['>]")
		error(string.format("Bad argument #%d to '%s' (%s)", argIndex, name, message:format(...)), 3)
	end
end

--[[ namespace:Assert(_state_, _message_[, _..._]) ![](https://img.shields.io/badge/function-blue)
If state is false; throw an error with a `message`.

The `message` will be formatted with the variable arguments if provided.
--]]
function namespace:Assert(state, message, ...)
	assert(type(state) == 'boolean', "Bad argument #1 to 'Assert' (boolean expected, got " .. type(state) .. ')')
	assert(type(message) == 'string', "Bad argument #2 to 'Assert' (string expected, got " .. type(message) .. ')')

	if not state then
		local name = debugstack(2, 2, 0):match(": in function ['`<](.-)['>]")
		error(string.format("Error in '%s' (%s)", name, message:format(...)), 3)
	end
end
