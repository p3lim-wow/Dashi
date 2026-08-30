local _, addon = ...

--[[ namespace:startswith(_str_, _contents_) ![](https://img.shields.io/badge/function-blue)
Checks if the first string starts with the 2nd string.
--]]
function addon:startswith(str, prefix)
	return str:sub(1, #prefix) == prefix
end

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

--[[ namespace:pack(_..._) ![](https://img.shields.io/badge/function-blue)
Packs variable arguments into a table, along with a field `n` which holds the number of arguments.

Functionally equivalent to [table.pack](https://www.luadocs.com/docs/functions/table/pack) from Lua 5.2.
--]]
function addon:pack(...)
	-- functionally equivalent to SafePack from TableUtil
	return {
		n = select('#', ...),
		...
	}
end

--[[ namespace:unpack(_tbl_[, _first_][, _last_]) ![](https://img.shields.io/badge/function-blue)
Unpacks an indexed table `tbl`.
By default it will start at the first index unless `first` is provided, and the last index defined
by addon:pack or `last if provided.

Functionally equivalent to [table.unpack](https://www.luadocs.com/docs/functions/table/unpack) from Lua 5.2.
--]]
function addon:unpack(tbl, first, last)
	return unpack(tbl, first or 1, last or tbl.n)
end

--[[ namespace:T([_tbl_]) ![](https://img.shields.io/badge/function-blue)
Returns the table _`tbl`_ with meta methods. If _`tbl`_ is not provided a new table is created.

Included are all meta methods from the [`table` library](https://warcraft.wiki.gg/wiki/Lua_functions#Table_library), as well as a few extra handy methods:

- `tbl:size()` returns the number of entries in the table
- `tbl:contains(value)` returns `true` if the table contains the given `value`, otherwise `false`
- `tbl:merge(t)` merges (and returns) the table with the supplied table `t`
    - can also be used by using an addition arithmetic metamethod
- `tbl:random()` returns a random value from the table
- `tbl:copy(shallow)` creates and returns a copy of the table
- `tbl:removeValue(value)` removes an entry from the table that matches the value

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
	local tableMethods = CreateFromMixins(table)
	function tableMethods:size()
		return addon:tsize(self)
	end

	function tableMethods:merge(tbl)
		addon:ArgCheck(tbl, 1, 'table')

		for k, v in next, tbl do
			if type(self[k]) == 'table' and type(v) == 'table' then
				tableMethods.merge(self[k], tbl[k])
			else
				self[k] = v
			end
		end

		return self
	end

	function tableMethods:contains(value)
		for _, v in next, self do
			if value == v then
				return true
			end
		end

		return false
	end

	function tableMethods:random()
		local size = self:size()
		if size > 0 then
			return self[math.random(size)]
		end
	end

	function tableMethods:copy(shallow)
		local tbl = addon:T()
		for k, v in next, self do
			if type(v) == 'table' and not shallow then
				tbl[k] = tableMethods.copy(v)
			else
				tbl[k] = v
			end
		end
		return tbl
	end

	function tableMethods:removeValue(value)
		for index = #self, 1, -1 do
			if self[index] == value then
				table.remove(self, index)
				return index
			end
		end
	end

	local function newIndex(self, key, value)
		-- turn child tables into this metatable too
		if type(value) == 'table' and not getmetatable(value) then
			rawset(self, key, addon:T(value))
		else
			rawset(self, key, value)
		end
	end

	local meta = {
		__index = tableMethods,
		__newindex = newIndex,
		__add = tableMethods.merge,
	}

	function addon:T(tbl)
		addon:ArgCheck(tbl, 1, 'table|nil')
		return setmetatable(tbl or {}, meta)
	end
end
