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

--[[ namespace:T([_tbl_[, _mixin_, ...] ]) ![](https://img.shields.io/badge/function-blue)
Returns the table _`tbl`_ with meta methods. If _`tbl`_ is not provided a new empty table is used.

Included are all meta methods from the `table` library, as well as a few extra handy methods:

- `tbl:size()` returns the number of entries in the table
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
		return addon:tsize(self)
	end

	function tableMixin:merge(tbl)
		addon:ArgCheck(tbl, 1, 'table')

		for k, v in next, tbl do
			if type(self[k] or false) == 'table' then
				tableMixin.merge(self[k], tbl[k])
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
		addon:ArgCheck(tbl, 1, 'table', 'nil')

		return setmetatable(tbl or {}, {
			__index = Mixin(table, tableMixin, ...),
			__add = tableMixin.merge,
		})
	end
end
