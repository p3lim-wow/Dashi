local _, addon = ...

--[[ namespace:CreateFrame(_..._)
A wrapper for [`CreateFrame`](https://warcraft.wiki.gg/wiki/API_CreateFrame), mixed in with `namespace.eventMixin`.
--]]
function addon:CreateFrame(...)
	return Mixin(CreateFrame(...), addon.eventMixin)
end

local KEY_DIRECTION_CVAR = 'ActionButtonUseKeyDown'

local function updateKeyDirection(self)
	if C_CVar.GetCVarBool(KEY_DIRECTION_CVAR) then
		self:RegisterForClicks('AnyDown')
	else
		self:RegisterForClicks('AnyUp')
	end
end

local function onCVarUpdate(self, cvar)
	if cvar == KEY_DIRECTION_CVAR then
		addon:Defer(updateKeyDirection, self)
	end
end

--[[ namespace:CreateButton(...)
A wrapper for `namespace:CreateFrame(...)`, but will handle key direction preferences of the client.  
Use this specifically to create clickable buttons.
--]]
function addon:CreateButton(...)
	local button = addon:CreateFrame(...)
	button:RegisterEvent('CVAR_UPDATE', onCVarUpdate)

	-- the CVar doesn't trigger during login, so we'll have to trigger the handlers ourselves
	onCVarUpdate(button, KEY_DIRECTION_CVAR)

	return button
end


local scrollDataMixin = {}
function scrollDataMixin:AddData(...)
	self._provider:Insert(...)
end
function scrollDataMixin:RemoveData(...)
	self._provider:Remove(...)
end
function scrollDataMixin:ResetData()
	self._provider:Flush()
end

local scrollMixin = {}
function scrollMixin:SetElementType(kind)
	self._elementType = kind
end
function scrollMixin:SetElementHeight(height)
	self._view:SetElementExtent(height)
	self._elementHeight = height
end
function scrollMixin:SetElementWidth(width)
	self._view:SetStrideExtent(width)
	self._elementWidth = width
end
function scrollMixin:SetElementSize(width, height)
	self:SetElementWidth(width)
	self:SetElementHeight(height or width)
end
function scrollMixin:SetElementCallback(callback)
	-- assert(self.elementType)
	self._view:SetElementInitializer(self._elementType, function(element, data)
		if self._elementWidth then
			element:SetWidth(self._elementWidth)
		end
		if self._elementHeight then
			element:SetHeight(self._elementHeight)
		end

		callback(element, data)
	end)
end
function scrollMixin:SetElementSortingMethod(callback)
	self._provider:SetSortComparator(callback)
end

local function createScrollWidget(parent, kind, ...)
	local box = CreateFrame('Frame', nil, parent, 'WowScrollBoxList')
	box:SetPoint('TOPLEFT')
	box:SetPoint('BOTTOMRIGHT', -8, 0) -- offset to not overlap scrollbar

	local bar = CreateFrame('EventFrame', nil, parent, 'MinimalScrollBar')
	bar:SetPoint('TOPLEFT', box, 'TOPRIGHT')
	bar:SetPoint('BOTTOMLEFT', box, 'BOTTOMRIGHT')

	local provider = CreateDataProvider()
	provider:SetSortComparator(function(a, b)
		-- convert to string first so we can sort mixed types
		return tostring(a) > tostring(b)
	end, true)
	box._provider = provider

	local view
	if kind == 'list' then
		view = CreateScrollBoxListLinearView(...)
	elseif kind == 'grid' then
		view = CreateScrollBoxListGridView(...)
	end
	view:SetDataProvider(provider)
	box._view = view

	ScrollUtil.InitScrollBoxListWithScrollBar(box, bar, view)
	ScrollUtil.AddManagedScrollBarVisibilityBehavior(box, bar) -- auto-hide the scroll bar

	return Mixin(box, scrollMixin, scrollDataMixin)
end

--[[ namespace:CreateScrollList(_parent_, [...])
Creates and returns a scroll box with scroll bar and a data provider in a list representation.

The variable arguments are passed straight to `CreateScrollBoxListLinearView`.

To initialize it you'll want to use the following methods to define the list elements:

* `list:SetElementType(type)` - where `type` is either a [frame type](https://warcraft.wiki.gg/wiki/API_CreateFrame) or a [template](https://warcraft.wiki.gg/wiki/Virtual_XML_template) (required)
* `list:SetElementHeight(height)` - set the height of each list element (required)
* `list:SetElementCallback(callback)` - the `callback` is triggered whenever data is added to the list (required)
    * the callback signature is `(element, data)`, see below for the `data`
* `list:SetElementSortingMethod(callback)` - sorting function to override the default

There are methods available for manipulating the data in the list:

* `list:AddData(...)`
* `list:RemoveData(...)`
* `list:ResetData()`
--]]
function addon:CreateScrollList(parent, ...)
	return createScrollWidget(parent, 'list', ...)
end

--[[ namespace:CreateScrollGrid(_parent_, [...])
Creates and returns a scroll box with scroll bar and a data provider in a list representation.

The variable arguments are passed straight to `CreateScrollBoxListGridView`.

To initialize it you'll want to use the following methods to define the list elements:

* `list:SetElementType(type)` - where `type` is either a [frame type](https://warcraft.wiki.gg/wiki/API_CreateFrame) or a [template](https://warcraft.wiki.gg/wiki/Virtual_XML_template) (required)
* `list:SetElementWidth(width)` - set the height of each list element (required)
* `list:SetElementHeight(height)` - set the height of each list element (required)
* `list:SetElementSize(width, height)` - same as running the above two methods
* `list:SetElementCallback(callback)` - the `callback` is triggered whenever data is added to the list (required)
    * the callback signature is `(element, data)`, see below for the `data`
* `list:SetElementSortingMethod(callback)` - sorting function to override the default

There are methods available for manipulating the data in the list:

* `list:AddData(...)`
* `list:RemoveData(...)`
* `list:ResetData()`
--]]
function addon:CreateScrollGrid(parent, ...)
	return createScrollWidget(parent, 'grid', ...)
end
