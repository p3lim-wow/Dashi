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
}

read_globals = {
	-- library
	table = {fields = {'wipe', 'count'}},
	string = {fields = {'join'}},
	'strlenutf8',

	-- FrameXML objects
	'ColorPickerFrame',
	'EventRegistry',
	'GameEvent',
	'GameTooltip',
	'Menu',
	'MinimalSliderWithSteppersMixin',
	'ScrollUtil',
	'Settings',
	'SettingsPanel',
	'TextureLoadingGroupMixin',
	'TooltipComparisonManager',
	'UIParent',

	-- FrameXML functions
	'CreateColor',
	'CreateDataProvider',
	'CreateScrollBoxListGridView',
	'CreateScrollBoxListLinearView',
	'DevTools_Dump',
	'DisplayTableInspectorWindow',
	'GameTooltipDefaultContainer',
	'GameTooltip_Hide',
	'GenerateClosure',
	'GenerateFlatClosure',
	'SecondsFormatter',
	'SecondsFormatterMixin',

	-- FrameXML constants
	'DEFAULT_CHAT_FRAME',
	'WOW_PROJECT_BURNING_CRUSADE_CLASSIC',
	'WOW_PROJECT_CATACLYSM_CLASSIC',
	'WOW_PROJECT_CLASSIC',
	'WOW_PROJECT_ID',
	'WOW_PROJECT_MAINLINE',
	'WOW_PROJECT_MISTS_CLASSIC',
	'WOW_PROJECT_WRATH_CLASSIC',

	-- GlobalStrings
	'HEADER_COLON',
	'SETTINGS_DEFAULTS',

	-- namespaces
	'C_AddOns',
	'C_CVar',
	'C_Container',
	'C_EventUtils',
	'C_Map',
	'C_SettingsUtil',
	'C_TooltipComparison',
	'C_TooltipInfo',
	'Constants',
	'Enum',

	-- API
	'CreateFrame',
	'CreateFromMixins',
	'GetBuildInfo',
	'GetLocale',
	'InCombatLockdown',
	'Mixin',
	'UnitName',
	'debugstack',
	'geterrorhandler',
}
