local _, addon = ...

-- hidden dummy frame we anchor regions we want to hide to
local hidden = CreateFrame('Frame')
hidden:Hide()

--[[ namespace:Hide(_object_[, _child_, _..._]) ![](https://img.shields.io/badge/function-blue)
Forcefully hide an `object`, or its `child`.  
It will recurse down to the last child if provided.

Usage:
```lua
namespace:Hide('ChatFrame2')
namespace:Hide('MinimapCluster', 'InstanceDifficulty')
namespace:Hide(someFrame, 'ResetButton')
```
--]]
function addon:Hide(object, ...)
	if type(object) == 'string' then
		object = _G[object]
	end

	if ... then
		-- iterate through arguments, they're children referenced by key
		for index = 1, select('#', ...) do
			object = object[select(index, ...)]
		end
	end

	if object then
		if object.SetRolesets then
			object:SetRolesets('alwaysBlocked')
		else
			object:Hide()
			object:SetParent(hidden)
		end
	end
end
