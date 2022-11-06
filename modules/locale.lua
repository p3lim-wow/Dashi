local _, addon = ...

-- localization
local localizations = {}
local locale = GetLocale()

-- usage:
--        set: addon.L('deDE')['New string'] = 'Neue Saite'
--        get: addon.L['New string']
addon.L = setmetatable({}, {
	__index = function(_, key)
		local localeTable = localizations[locale]
		return localeTable and localeTable[key] or tostring(key)
	end,
	__call = function(_, newLocale)
		localizations[newLocale] = localizations[newLocale] or {}
		return localizations[newLocale]
	end,
})
