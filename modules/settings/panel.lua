local addonName, addon = ...

local function onSettingChanged(owner, setting, value)
	if setting.owner ~= addonName then
		-- avoid phantom updates from addons having settings with the same key name
		return
	end

	if owner then
		-- triggered by player changing settings in the panel
		addon:SetOption(setting:GetVariable(), value)
	else
		-- triggered by addon.SetOption
		setting:SetValue(value)
	end
end

local function formatCustom(fmt, value)
	return fmt:format(value)
end

-- they removed the new flag for no apparent reason
local settingMixin = {}
function settingMixin:SetNewTagShown(state)
	self.newTagShown = state
end

function settingMixin:IsNewTagShown() -- override method
	return self.newTagShown
end

local function registerSetting(category, info)
	local setting = Settings.RegisterAddOnSetting(category, info.title, info.key, type(info.default), info.default)
	setting.owner = addonName -- unique flag on the setting per-addon to avoid phantom updates

	Mixin(setting, settingMixin)

	if info.type == 'toggle' then
		(Settings.CreateCheckBox or Settings.CreateCheckbox)(category, setting, info.tooltip) -- TODO: TWW cleanup
	elseif info.type == 'slider' then
		local sliderOptions = Settings.CreateSliderOptions(info.minValue, info.maxValue, info.valueStep or 1)
		local valueFormat
		if type(info.valueFormat) == 'string' then
			valueFormat = GenerateClosure(formatCustom, info.valueFormat)
		elseif type(info.valueFormat) == 'function' then
			valueFormat = info.valueFormat
		end
		sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, valueFormat)
		Settings.CreateSlider(category, setting, sliderOptions, info.tooltip)
	elseif info.type == 'menu' then
		local getMenuOptions = function()
			local container = Settings.CreateControlTextContainer()
			for key, name in next, info.options do
				container:Add(key, name)
			end
			return container:GetData()
		end
		(Settings.CreateDropDown or Settings.CreateDropdown)(category, setting, getMenuOptions, info.tooltip)
	end

	if info.new then
		setting:SetNewTagShown(true)
	end

	-- hook into both the Settings object and Dashi's option callback for value changes
	Settings.SetOnValueChangedCallback(info.key, onSettingChanged)
	addon:RegisterOptionCallback(info.key, GenerateClosure(onSettingChanged, nil, setting))
end

local canvasMixin = {}
function canvasMixin:SetDefaultsHandler(callback)
	local DefaultsButton = self:GetParent().Header.DefaultsButton
	DefaultsButton:Show()
	DefaultsButton:SetScript('OnClick', callback)
end

local function createCanvas(name)
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

local children = {}
local function internalRegisterSettings(savedvariable, settings)
	-- create a vertical layout category, handing off all elements to Blizzard
	local category = Settings.RegisterVerticalLayoutCategory(C_AddOns.GetAddOnMetadata(addonName, 'Title'))

	-- iterate through the provided settings table and generate settings objects and defaults
	local defaults = {}
	for _, setting in next, settings do
		registerSetting(category, setting)
		defaults[setting.key] = setting.default
	end

	-- register category and load the savedvariables
	Settings.RegisterAddOnCategory(category)
	addon:LoadOptions(savedvariable, defaults)

	-- deal with sub-categories
	for _, info in next, children do
		if info.kind == 'settings' then
			local sub = Settings.RegisterVerticalLayoutSubcategory(category, info.name)
			table.wipe(defaults)

			for _, setting in next, info.settings do
				registerSetting(sub, setting)
				defaults[setting.key] = setting.default
			end

			Settings.RegisterAddOnCategory(sub)
			addon:LoadExtraOptions(savedvariable, defaults)
		elseif info.kind == 'canvas' then
			local frame, canvas = createCanvas(info.name)
			local sub = Settings.RegisterCanvasLayoutSubcategory(category, frame, info.name)
			Settings.RegisterAddOnCategory(sub)

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

local isRegistered
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
    }
})
```
--]]
function addon:RegisterSettings(savedvariable, settings)
	assert(not isRegistered, "can't register settings more than once")
	isRegistered = true

	-- ensure we only add the panel after savedvariables are available to the client
	local _, isReady = C_AddOns.IsAddOnLoaded(addonName)
	if isReady then
		internalRegisterSettings(savedvariable, settings)
	else
		-- don't abuse OnLoad internally
		addon:RegisterEvent('ADDON_LOADED', function(_, name)
			if name == addonName then
				internalRegisterSettings(savedvariable, settings)
				return true -- unregister
			end
		end)
	end
end

--[[ namespace:RegisterSubSettings(_name_, _settings_)
Registers a set of `settings` as a sub-category. `name` must be unique.  
The values will be stored by the `settings`' objects' `key` in the previously created savedvariables.

The `settings` are identical to that of `namespace:RegisterSettings`.
--]]
function addon:RegisterSubSettings(name, settings)
	assert(isRegistered, "can't register sub-settings without main settings")

	table.insert(children, {
		kind = 'settings',
		name = name,
		settings = settings,
	})
end

--[[ namespace:RegisterSubSettingsCanvas(_name_, _callback_)
Registers a canvas sub-category. This does not handle savedvariables.

`name` must be unique, and `callback` is called with a canvas `frame` as payload.

Canvas frame has a custom method `SetDefaultsHandler` which takes a callback as arg1.
This callback is triggered when the "Defaults" button is clicked.
--]]
function addon:RegisterSubCanvas(name, callback)
	assert(isRegistered, "can't register sub-canvas without main settings")

	table.insert(children, {
		kind = 'canvas',
		name = name,
		callback = callback,
	})
end

--[[ namespace:RegisterSettingsSlash(_..._)
Wrapper for `namespace:RegisterSlash(...)`, except the callback is provided and will open the interface options for this addon.
--]]
function addon:RegisterSettingsSlash(...)
	-- gotta do this dumb shit because `..., callback` is not valid Lua
	local data = {...}
	table.insert(data, function()
		-- iterate over all categories until we find ours, since OpenToCategory only takes ID
		local categoryID
		local settingsName = C_AddOns.GetAddOnMetadata(addonName, 'Title')
		for _, category in next, SettingsPanel:GetAllCategories() do
			if category.name == settingsName then
				assert(not categoryID, 'found multiple instances of the same category')
				categoryID = category:GetID()
			end
		end

		Settings.OpenToCategory(categoryID)
	end)

	addon:RegisterSlash(unpack(data))
end
