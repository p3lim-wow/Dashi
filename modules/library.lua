local _, addon = ...

--[[ namespace:tsize(_table_)
Returns the number of entries in the `table`.  
Works for associative tables as opposed to `#table`.
--]]
function addon:tsize(tbl)
	-- would really like Lua 5.2 for this
	local size = 0
	if tbl then
		for _ in next, tbl do
			size = size + 1
		end
	end
	return size
end

--[[ namespace:startswith(_str_, _contents_)
Checks if the first string starts with the 2nd string.
--]]
function addon:startswith(str, contents)
	return str:sub(1, contents:len()) == contents
end
