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
		defaults:SetText(_G.SETTINGS_DEFAULTS)
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
			for key, name in next, info.options do
				container:Add(key, name)
			end
			return container:GetData()
		end
		Settings.CreateDropdown(category, setting, options, info.tooltip)
	elseif info.type == 'colorpicker' then
		createColorPicker(category, setting, nil, info.tooltip)
	else
		error('type is invalid') -- TODO: make this prettier
		return
	end

	if info.new then
		-- possibly tainty, and not that clean (it adds new tag to the category list too)
		local version = GetBuildInfo()
		if not NewSettings[version] then
			NewSettings[version] = {}
		end

		table.insert(NewSettings[version], uniqueKey)
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

	if not _G[savedvariable] then
		-- for some dumb reason RegisterAddOnSetting doesn't initialize the savedvariables table
		_G[savedvariable] = {}
	end

	for _, setting in next, settings do
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
        new = false,
    }
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
        new = true,
    },
    {
        key = 'myMenu',
        type = 'menu',
        title = 'My Menu',
        tooltip = 'Longer description of the menu in a tooltip',
        default = 'key1',
        options = {
            key1 = 'First option',
            key2 = 'Second option',
            key3 = 'Third option',
        },
        new = false,
    },
    {
        key = 'myColor',
        type = 'colorpicker',
        title = 'My Color',
        tooltip = 'Longer description of the color in a tooltip',
        default = 'ff00ff', -- either "RRGGBB" or "AARRGGBB" format
        new = false,
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
