std = 'lua51'

quiet = 1 -- suppress report output for files without warnings

-- see https://luacheck.readthedocs.io/en/stable/warnings.html#list-of-warnings
-- and https://luacheck.readthedocs.io/en/stable/cli.html#patterns
ignore = {
	'212/self', -- unused argument self
	'212/event', -- unused argument event
	'212/unit', -- unused argument unit
	'212/setting', -- unused argument unit
	'212/element', -- unused argument element
	'312/event', -- unused value of argument event
	'312/unit', -- unused value of argument unit
	'431', -- shadowing an upvalue
	'614', -- trailing whitespace in comment (we use this for docs)
	'631', -- line is too long
}

globals = {
	-- FrameXML objects we mutate
	'SlashCmdList',
	'NewSettings',
}

read_globals = {
	table = {fields = {'wipe'}},
	string = {fields = {'join'}},

	-- FrameXML objects
	'ColorPickerFrame',
	'EventRegistry',
	'Menu',
	'MinimalSliderWithSteppersMixin',
	'ScrollUtil',
	'Settings',
	'SettingsListElementMixin',
	'SettingsPanel',

	-- FrameXML functions
	'CreateColor',
	'CreateDataProvider',
	'CreateScrollBoxListLinearView',
	'CreateScrollBoxListGridView',
	'DisplayTableInspectorWindow',
	'GameTooltip_Hide',
	'UIParentLoadAddOn',
	'DevTools_Dump',
	'GenerateClosure',
	'Mixin',
	'nop',

	-- FrameXML constants
	'DEFAULT_CHAT_FRAME',

	-- GlobalStrings
	'HEADER_COLON',
	'SETTINGS_DEFAULTS',

	-- namespaces
	'C_AddOns',
	'C_CVar',
	'C_EventUtils',
	'C_Map',
	'C_UnitAuras',

	-- API
	'CombatLogGetCurrentEventInfo',
	'CreateFrame',
	'GetBuildInfo',
	'GetLocale',
	'InCombatLockdown',
	'UnitExists',
	'UnitGUID',
	'debugstack',
}
