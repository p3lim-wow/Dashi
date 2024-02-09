std = 'lua51'

quiet = 1 -- suppress report output for files without warnings

-- see https://luacheck.readthedocs.io/en/stable/warnings.html#list-of-warnings
-- and https://luacheck.readthedocs.io/en/stable/cli.html#patterns
ignore = {
	'212/self', -- unused argument self
	'212/event', -- unused argument event
	'212/unit', -- unused argument unit
	'212/element', -- unused argument element
	'312/event', -- unused value of argument event
	'312/unit', -- unused value of argument unit
	'431', -- shadowing an upvalue
	'614', -- trailing whitespace in comment (we use this for docs)
	'631', -- line is too long
}

globals = {
	-- FrameXML objects we mutate
	'SlashCmdList', -- FrameXML/ChatFrame.lua
}

read_globals = {
	table = {fields = {'wipe'}},

	-- FrameXML objects
	'DEFAULT_CHAT_FRAME', -- FrameXML/ChatFrame.lua

	-- FrameXML functions
	'DisplayTableInspectorWindow', -- AddOns/Blizzard_DebugTools/Blizzard_TableInspector.lua
	'UIParentLoadAddOn', -- FrameXML/UIParent.lua
	'nop', -- FrameXML/UIParent.lua

	-- SharedXML objects
	'MinimalSliderWithSteppersMixin', -- SharedXML/Slider/MinimalSlider.lua
	'Settings', -- SharedXML/Settings/Blizzard_Settings.lua
	'SettingsPanel', -- SharedXML/Settings/Blizzard_SettingsPanel.xml

	-- SharedXML functions
	'DevTools_Dump', -- SharedXML/Dump.lua
	'GenerateClosure', -- SharedXML/FunctionUtil.lua
	'Mixin', -- SharedXML/Mixin.lua

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
	'IsAddOnLoaded', -- until wrath classic bumps API
	'UnitAuraSlots',
	'UnitGUID',
	'UnitIsOwnerOrControllerOfUnit',
	'UnitIsUnit',
}
