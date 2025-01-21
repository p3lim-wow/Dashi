local _, addon = ...

--[[ namespace:tsize(_tbl_) ![](https://img.shields.io/badge/function-blue)
Returns the number of entries in the table `tbl`.  
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

--[[ namespace:startswith(_str_, _contents_) ![](https://img.shields.io/badge/function-blue)
Checks if the first string starts with the 2nd string.
--]]
function addon:startswith(str, contents)
	return str:sub(1, contents:len()) == contents
end

--[[ namespace:T(_tbl_[, _mixin_, ...]) ![](https://img.shields.io/badge/function-blue)
Returns the table _`tbl`_ with meta methods.

Included are all meta methods from the `table` library, as well as a few extra handy methods:

- `tbl:size()` returns the length of the table irregardless if it's indexed or associative
- `tbl:contains(value)` returns `true` if the table contains the given `value`, otherwise `false`
- `tbl:merge(t)` merges (and returns) the table with the supplied table `t`
    - can also be used by using an addition arithmetic metamethod

It's also possible to add extra meta methods by supplying mixins through the variable argument.

Example usage:

```lua
local t = namespace:T{'one', 'two'}
t:insert('three')
t:size() --> 3
t:contains('four') --> false
t + {'five', 'six'} --> {'one', 'two', 'three', 'five', 'six'}
```
--]]
do
	local tableMixin = {}
	function tableMixin:size()
		local n = 0
		for _ in next, self do
			n = n + 1
		end
		return n
	end

	function tableMixin:merge(t)
		for k, v in next, t do
			if type(self[k] or false) == 'table' then
				tableMixin.merge(self[k], t[k])
			else
				self[k] = v
			end
		end
		return self
	end

	function tableMixin:contains(value)
		for _, v in next, self do
			if value == v then
				return true
			end
		end
		return false
	end

	function addon:T(tbl, ...)
		return setmetatable(tbl or {}, {
			__index = Mixin(table, tableMixin, ...),
			__add = tableMixin.merge,
		})
	end
end
