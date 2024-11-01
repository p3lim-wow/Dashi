local addonName, addon = ...

local function onSettingChanged(setting, value)
	addon:TriggerOptionCallback(setting.variableKey, value)
end

-- local function onOptionChanged(setting, value)
-- 	setting:SetValue(value, true)
-- end

local createCanvas
do
	local canvasMixin = {}
	function canvasMixin:SetDefaultsHandler(callback)
		local button = self:GetParent().Header.DefaultsButton
		button:Show()
		button:SetScript('OnClick', callback)
	end

	function createCanvas(name)
		local frame = CreateFrame('Frame')

		-- replicate header from SettingsListTemplate
		local header = CreateFrame('Frame', nil, frame)
		header:SetPoint('TOPLEFT')
		header:SetPoint('TOPRIGHT')
		header:SetHeight(50)
		frame.Header = header

		local title = header:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightHuge')
		title:SetPoint('TOPLEFT', 7, -22)
		title:SetJustifyH('LEFT')
		title:SetText(string.format('%s - %s', addonName, name))
		header.Title = title

		local defaults = CreateFrame('Button', nil, header, 'UIPanelButtonTemplate')
		defaults:SetPoint('TOPRIGHT', -36, -16)
		defaults:SetSize(96, 22)
		defaults:SetText(SETTINGS_DEFAULTS)
		defaults:Hide()
		header.DefaultsButton = defaults

		local divider = header:CreateTexture(nil, 'ARTWORK')
		divider:SetPoint('TOP', 0, -50)
		divider:SetAtlas('Options_HorizontalDivider', true)

		-- exposed container the addon can use
		local canvas = Mixin(CreateFrame('Frame', nil, frame), canvasMixin)
		canvas:SetPoint('BOTTOMLEFT', 0, 5)
		canvas:SetPoint('BOTTOMRIGHT', -12, 5)
		canvas:SetPoint('TOP', 0, -56)

		return frame, canvas
	end
end

local createColorPicker -- I wish Settings.CreateColorPicker was a thing
do
	local colorPickerMixin = {}
	function colorPickerMixin:OnSettingValueChanged(setting, value)
		local r, g, b, a = addon:CreateColor(value):GetRGBA()
		self.Swatch:SetColorRGB(r, g, b)

		-- modify colorInfo for next run
		self.colorInfo.r = r
		self.colorInfo.g = g
		self.colorInfo.b = b
		self.colorInfo.a = a
	end

	local function onClick(self)
		local parent = self:GetParent()
		local info = parent.colorInfo
		if info.hasOpacity then
			parent.oldValue = CreateColor(info.r, info.g, info.b, info.a):GenerateHexColor()
		else
			parent.oldValue = CreateColor(info.r, info.g, info.b):GenerateHexColorNoAlpha()
		end

		ColorPickerFrame:SetupColorPickerAndShow(info)
	end

	local function onColorChanged(self, setting)
		local r, g, b = ColorPickerFrame:GetColorRGB()
		if self.colorInfo.hasOpacity then
			local a = ColorPickerFrame:GetColorAlpha()
			setting:SetValue(CreateColor(r, g, b, a):GenerateHexColor())
		else
			setting:SetValue(CreateColor(r, g, b):GenerateHexColorNoAlpha())
		end
	end

	local function onColorCancel(self, setting)
		setting:SetValue(self.oldValue)
	end

	local function initFrame(initializer, self)
		SettingsListElementMixin.OnLoad(self)
		SettingsListElementMixin.Init(self, initializer)
		Mixin(self, colorPickerMixin)

		self:SetSize(280, 26) -- templates have a size

		-- creating widgets would be equal to :OnLoad()
		self.Swatch = CreateFrame('Button', nil, self, 'ColorSwatchTemplate')
		self.Swatch:SetSize(30, 30)
		self.Swatch:SetPoint('LEFT', self, 'CENTER', -80, 0)
		self.Swatch:SetScript('OnClick', onClick)

		-- setting up state would be equal to :Init()
		local setting = initializer:GetSetting()
		local value = setting:GetValue()
		local r, g, b, a = addon:CreateColor(value):GetRGBA()

		self.colorInfo = {
			swatchFunc = GenerateClosure(onColorChanged, self, setting),
			opacityFunc = GenerateClosure(onColorChanged, self, setting),
			cancelFunc = GenerateClosure(onColorCancel, self, setting),
			r = r,
			g = g,
			b = b,
			opacity = a,
			hasOpacity = #value == 8
		}

		self.Swatch:SetColorRGB(r, g, b)

		-- set up callbacks, see SettingsControlMixin.Init as an example
		-- this is used to change common values, and is triggered by setting:SetValue(), thus also from defaults
		self.cbrHandles:SetOnValueChangedCallback(setting:GetVariable(), self.OnSettingValueChanged, self)
	end

	function createColorPicker(category, setting, options, tooltip)
		local data = Settings.CreateSettingInitializerData(setting, options, tooltip)
		local init = Settings.CreateElementInitializer('SettingsListElementTemplate', data)
		init.InitFrame = initFrame
		init:AddSearchTags(setting:GetName())
		SettingsPanel:GetLayout(category):AddInitializer(init)
	end
end

local function formatCustom(fmt, value)
	return fmt:format(value)
end

local function registerSetting(category, savedvariable, info)
	addon:ArgCheck(info.key, 3, 'string')
	addon:ArgCheck(info.title, 3, 'string')
	addon:ArgCheck(info.type, 3, 'string')
	assert(info.default ~= nil, "default must be set")

	local uniqueKey = savedvariable .. '_' .. info.key
	local setting = Settings.RegisterAddOnSetting(category, uniqueKey, info.key, _G[savedvariable], type(info.default), info.title, info.default)

	if info.type == 'toggle' then
		Settings.CreateCheckbox(category, setting, info.tooltip)
	elseif info.type == 'slider' then
		addon:ArgCheck(info.minValue, 3, 'number')
		addon:ArgCheck(info.maxValue, 3, 'number')
		addon:ArgCheck(info.valueFormat, 3, 'string', 'function')

		local options = Settings.CreateSliderOptions(info.minValue, info.maxValue, info.valueStep or 1)
		if type(info.valueFormat) == 'string' then
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, GenerateClosure(formatCustom, info.valueFormat))
		elseif type(info.valueFormat) == 'function' then
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, info.valueFormat)
		end

		Settings.CreateSlider(category, setting, options, info.tooltip)
	elseif info.type == 'menu' then
		addon:ArgCheck(info.options, 3, 'table')
		local options = function()
			local container = Settings.CreateControlTextContainer()
			for _, option in next, info.options do
				container:Add(option.value, option.label)
			end
			return container:GetData()
		end
		Settings.CreateDropdown(category, setting, options, info.tooltip)
	elseif info.type == 'color' or info.type == 'colorpicker' then -- TODO: remove in 12.x, compat
		createColorPicker(category, setting, nil, info.tooltip)
	else
		error('type is invalid') -- TODO: make this prettier
		return
	end

	if info.firstInstall then
		-- we don't want to add "new" tags to a freshly installed addon
		_G[savedvariable][info.key .. '_seen'] = true
	elseif not _G[savedvariable][info.key .. '_seen'] then
		-- add new tag to the settings panel until it's been observed by the player
		-- possibly tainty, definitely  ugly
		local version = GetBuildInfo()
		if not NewSettings[version] then
			NewSettings[version] = {}
		end

		table.insert(NewSettings[version], uniqueKey)

		-- remove once seen
		EventRegistry:RegisterCallback('Settings.CategoryChanged', function(_, cat)
			if cat == category and not _G[savedvariable][info.key .. '_seen'] then
				_G[savedvariable][info.key .. '_seen'] = true

				local settingIndex
				for index, key in next, NewSettings[version] do
					if key == uniqueKey then
						settingIndex = index
						break
					end
				end

				if settingIndex then
					table.remove(NewSettings[version], settingIndex)
				end
			end
		end)
	end

	-- callback when settings change something
	setting:SetValueChangedCallback(onSettingChanged)

	-- callback when we change settings elsewhere
	-- TODO: reconsider this usecase
	-- addon:RegisterOptionCallback(info.key, GenerateClosure(onOptionChanged, setting))

	-- trigger load callback
	addon:TriggerOptionCallback(info.key, setting:GetValue())
end

local function registerSettings(savedvariable, settings)
	local categoryName = C_AddOns.GetAddOnMetadata(addonName, 'Title')
	local category = Settings.RegisterVerticalLayoutCategory(categoryName)
	Settings.RegisterAddOnCategory(category)

	local firstInstall
	if not _G[savedvariable] then
		-- for some dumb reason RegisterAddOnSetting doesn't initialize the savedvariables table
		_G[savedvariable] = {}
		firstInstall = true
	end

	for _, setting in next, settings do
		if firstInstall then
			setting.firstInstall = true
		end

		registerSetting(category, savedvariable, setting)
	end

	-- sub-categories
	for _, info in next, addon.settingsChildren do
		if info.settings then
			local child = Settings.RegisterVerticalLayoutSubcategory(category, info.name)
			for _, setting in next, info.settings do
				registerSetting(child, savedvariable, setting)
			end
			Settings.RegisterAddOnCategory(child)
		elseif info.callback then
			local frame, canvas = createCanvas(info.name)
			local child = Settings.RegisterCanvasLayoutSubcategory(category, frame, info.name)
			Settings.RegisterAddOnCategory(child)

			-- delay callback until settings are shown
			local shown
			SettingsPanel:HookScript('OnShow', function()
				if not shown then
					info.callback(canvas)
					shown = true
				end
			end)
		end
	end
end

--[[ namespace:RegisterSettings(_savedvariables_, _settings_)
Registers a set of `settings` with the interface options panel.  
The values will be stored by the `settings`' objects' `key` in `savedvariables`.

Should be used with the options methods below.

Usage:
```lua
namespace:RegisterSettings('MyAddOnDB', {
    {
        key = 'myToggle',
        type = 'toggle',
        title = 'My Toggle',
        tooltip = 'Longer description of the toggle in a tooltip',
        default = false,
    },
    {
        key = 'mySlider',
        type = 'slider',
        title = 'My Slider',
        tooltip = 'Longer description of the slider in a tooltip',
        default = 0.5,
        minValue = 0.1,
        maxValue = 1.0,
        valueStep = 0.01,
        valueFormat = formatter, -- callback function or a string for string.format
    },
    {
        key = 'myMenu',
        type = 'menu',
        title = 'My Menu',
        tooltip = 'Longer description of the menu in a tooltip',
        default = 'key1',
        options = {
            {value = key1, label = 'First option'},
            {value = key2, label = 'Second option'},
            {value = key3, label = 'Third option'},
        },
    },
    {
        key = 'myColor',
        type = 'color',
        title = 'My Color',
        tooltip = 'Longer description of the color in a tooltip',
        default = 'ff00ff', -- either "RRGGBB" or "AARRGGBB" format
    }
})
```
--]]
function addon:RegisterSettings(savedvariable, settings)
	addon:ArgCheck(savedvariable, 1, 'string')
	addon:ArgCheck(settings, 2, 'table')
	assert(not self.registeredVariables, "can't register settings more than once")
	self.registeredVariables = savedvariable

	if not self.settingsChildren then
		self.settingsChildren = {}
	end

	-- ensure we only add the settings after savedvariables are available to the client
	local _, isReady = C_AddOns.IsAddOnLoaded(addonName)
	if isReady then
		registerSettings(savedvariable, settings)
	else
		-- don't abuse OnLoad internally
		addon:RegisterEvent('ADDON_LOADED', function(_, name)
			if name == addonName then
				registerSettings(savedvariable, settings)
				return true -- unregister
			end
		end)
	end
end

--[[ namespace:RegisterSubSettings(_name_, _settings_)
Registers a set of `settings` as a sub-category. `name` must be unique.  
The savedvariables will be stored under the main savedvariables in a table entry named after `name`.

The `settings` are identical to that of `namespace:RegisterSettings`.
--]]
function addon:RegisterSubSettings(name, settings)
	addon:ArgCheck(name, 1, 'string')
	addon:ArgCheck(settings, 2, 'table')
	assert(not not self.settingsChildren, "can't register sub-settings without root settings")
	assert(not self.settingsChildren[name], "can't register two sub-settings with the same name")
	self.settingsChildren[name] = {
		name = name,
		settings = settings,
	}
end

--[[ namespace:RegisterSubSettingsCanvas(_name_, _callback_)
Registers a canvas sub-category. This does not handle savedvariables.

`name` must be unique, and `callback` is called with a canvas `frame` as payload.

Canvas frame has a custom method `SetDefaultsHandler` which takes a callback as arg1.
This callback is triggered when the "Defaults" button is clicked.
--]]
function addon:RegisterSubCanvas(name, callback)
	addon:ArgCheck(name, 1, 'string')
	addon:ArgCheck(callback, 2, 'function')
	assert(not not self.settingsChildren, "can't register sub-settings without root settings")
	assert(not self.settingsChildren[name], "can't register two sub-settings with the same name")
	self.settingsChildren[name] = {
		name = name,
		callback = callback,
	}
end

--[[ namespace:RegisterSettingsSlash(_..._)
Wrapper for `namespace:RegisterSlash(...)`, except the callback is provided and will open the settings panel for this addon.
--]]
function addon:RegisterSettingsSlash(...)
	-- gotta do this dumb shit because `..., callback` is not valid Lua
	local data = {...}
	table.insert(data, function()
		-- iterate over all categories until we find ours, since OpenToCategory only takes ID
		local categoryID
		local categoryName = C_AddOns.GetAddOnMetadata(addonName, 'Title')
		for _, category in next, SettingsPanel:GetAllCategories() do
			if category.name == categoryName then
				assert(not categoryID, 'found multiple instances of the same category')
				categoryID = category:GetID()
			end
		end

		Settings.OpenToCategory(categoryID)
	end)

	addon:RegisterSlash(unpack(data))
end

--[[ namespace:GetOption(_key_)
Returns the value for the given option `key`.
--]]
function addon:GetOption(key)
	addon:ArgCheck(key, 1, 'string')
	assert(addon:AreOptionsLoaded(), "options aren't loaded")
	assert(_G[self.registeredVariables][key] ~= nil, "key doesn't exist")
	return _G[self.registeredVariables][key]
end

--[[ namespace:SetOption(_key_, _value_)
Sets a new `value` to the given options `key`.
--]]
function addon:SetOption(key, value)
	addon:ArgCheck(key, 1, 'string')
	assert(addon:AreOptionsLoaded(), "options aren't loaded")
	assert(_G[self.registeredVariables][key] ~= nil, "key doesn't exist")

	_G[self.registeredVariables][key] = value -- this circumvents the setting system, bad?
	addon:TriggerOptionCallback(key, value)
end

--[[ namespace:AreOptionsLoaded()
Checks to see if the savedvariables has been loaded in the game.
--]]
function addon:AreOptionsLoaded()
	return (not not self.registeredVariables) and (not not _G[self.registeredVariables])
end

--[[ namespace:RegisterOptionCallback(_key_, _callback_)
Register a `callback` function with the option `key`.
--]]
function addon:RegisterOptionCallback(key, callback)
	addon:ArgCheck(key, 1, 'string')
	addon:ArgCheck(callback, 2, 'function')

	if not self.settingsCallbacks then
		self.settingsCallbacks = {}
	end

	if not self.settingsCallbacks[key] then
		self.settingsCallbacks[key] = {}
	end

	table.insert(self.settingsCallbacks[key], callback)
end

--[[ namespace:TriggerOptionCallbacks(_key_, _value_)
Trigger all registered option callbacks for the given `key`, supplying the `value`.
--]]
function addon:TriggerOptionCallback(key, value)
	addon:ArgCheck(key, 1, 'string')

	if self.settingsCallbacks and self.settingsCallbacks[key] then
		for _, callback in next, self.settingsCallbacks[key] do
			local successful, ret = pcall(callback, value)
			if not successful then
				error(ret)
			end
		end
	end
end

do
	-- sliders aren't supported in menus, so we create our own custom element
	local function resetSlider(frame)
		frame.slider:UnregisterCallback('OnValueChanged', frame)
		frame.slider:Release()
	end

	local function createSlider(root, name, getter, setter, minValue, maxValue, steps, formatter)
		local element = root:CreateButton(name):CreateFrame()
		if addon:HasBuild(57361, 110007) then
			element:AddResetter(resetSlider)
		end
		element:AddInitializer(function(frame)
			local slider = frame:AttachTemplate('MinimalSliderWithSteppersTemplate')
			slider:SetPoint('TOPLEFT', 0, -1)
			slider:SetSize(150, 25)
			slider:RegisterCallback('OnValueChanged', setter, frame)
			slider:Init(getter(), minValue, maxValue, (maxValue - minValue) / steps, {
				[MinimalSliderWithSteppersMixin.Label.Right] = formatter
			})
			frame.slider = slider -- ref for resetter

			if not addon:HasBuild(57361, 110007) then
				-- there's no way to properly reset an element from the menu, so we'll need to use
				-- a dummy element we can hook OnHide onto
				-- https://github.com/Stanzilla/WoWUIBugs/issues/652
				local dummy = frame:AttachFrame('Frame')
				dummy:SetScript('OnHide', function()
					resetSlider(frame)
				end)
			end

			local pad = 30 -- for the label
			return slider:GetWidth() + pad, slider:GetHeight()
		end)

		return element
	end

	local function colorPickerClick(data)
		ColorPickerFrame:SetupColorPickerAndShow(data)
	end
	local function colorPickerChange(setting)
		local r, g, b = ColorPickerFrame:GetColorRGB()
		if #setting.default == 8 then
			local a = ColorPickerFrame:GetColorAlpha()
			addon:SetOption(setting.key, addon:CreateColor(r, g, b, a):GenerateHexColor())
		else
			addon:SetOption(setting.key, addon:CreateColor(r, g, b):GenerateHexColorNoAlpha())
		end
	end
	local function colorPickerReset(setting, previousColor)
		local color = addon:CreateColor(previousColor)
		if #setting.default == 8 then
			addon:SetOption(setting.key, color:GenerateHexColor())
		else
			addon:SetOption(setting.key, color:GenerateHexColorNoAlpha())
		end
	end

	local function menuGetter(setting, value)
		return addon:GetOption(setting.key) == value
	end
	local function menuSetter(setting, value)
		addon:SetOption(setting.key, value)
	end

	local function registerMapSettings(savedvariable, settings)
		if not addon.registeredVariables then
			-- these savedvariables are not handled by other means, let's deal with defaults and
			-- merging ourselves
			if not _G[savedvariable] then
				_G[savedvariable] = {}
			end

			for _, setting in next, settings do
				-- merge or default
				if _G[savedvariable][setting.key] == nil then
					_G[savedvariable][setting.key] = setting.default
				end
			end

			addon.registeredVariables = savedvariable
		end

		-- TODO: menus also has "new feature" flags/textures, see if we can hook into that

		Menu.ModifyMenu('MENU_WORLD_MAP_TRACKING', function(_, root)
			root:CreateDivider()
			root:CreateTitle((addonName:gsub('(%l)(%u)', '%1 %2')) .. HEADER_COLON)

			for _, setting in next, settings do
				if setting.type == 'toggle' then
					root:CreateCheckbox(setting.title, function()
						return addon:GetOption(setting.key)
					end, function()
						addon:SetOption(setting.key, not addon:GetOption(setting.key))
					end)
				elseif setting.type == 'slider' then
					local formatter
					if type(setting.valueFormat) == 'string' then
						formatter = GenerateClosure(formatCustom, setting.valueFormat)
					elseif type(setting.valueFormat) == 'function' then
						formatter = setting.valueFormat
					end

					createSlider(root, setting.title, function()
						return addon:GetOption(setting.key)
					end, function(_, value)
						addon:SetOption(setting.key, value)
					end, setting.minValue, setting.maxValue, setting.valueStep or 1, formatter)
				elseif setting.type == 'color' then
					local value = addon:GetOption(setting.key)
					local r, g, b, a = addon:CreateColor(value):GetRGBA()
					root:CreateColorSwatch(setting.title, colorPickerClick, {
						swatchFunc = GenerateClosure(colorPickerChange, setting),
						opacityFunc = GenerateClosure(colorPickerChange, setting),
						cancelFunc = GenerateClosure(colorPickerReset, setting),
						r = r,
						g = g,
						b = b,
						opacity = a,
						hasOpacity = #value == 8,
					})
				elseif setting.type == 'menu' then
					local menu = root:CreateButton(setting.title)
					for _, option in next, setting.options do
						menu:CreateRadio(
							option.label,
							GenerateClosure(menuGetter, setting),
							GenerateClosure(menuSetter, setting),
							option.value
						)
					end
				end
			end
		end)
	end

	--[[ namespace:RegisterMapSettings(_savedvariable_, _settings_)
	Registers a set of `settings` to inject into the world map tracking menu.
	The values will be stored by the `settings`' objects' `key` in `savedvariables`.

	The `settings` object is identical to the one for [RegisterSetting](namespaceregistersettingssavedvariables-settings).  
	--]]
	function addon:RegisterMapSettings(savedvariable, settings)
		addon:ArgCheck(savedvariable, 1, 'string')
		addon:ArgCheck(settings, 2, 'table')

		-- ensure we only add the settings after savedvariables are available to the client
		local _, isReady = C_AddOns.IsAddOnLoaded(addonName)
		if isReady then
			registerMapSettings(savedvariable, settings)
		else
			-- don't abuse OnLoad internally
			addon:RegisterEvent('ADDON_LOADED', function(_, name)
				if name == addonName then
					registerMapSettings(savedvariable, settings)
					return true -- unregister
				end
			end)
		end
	end
end
