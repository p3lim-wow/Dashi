local _, addon = ...

-- localization
local localizations = {}
local locale = GetLocale()

--[[ namespace.L(_locale_)[`string`]
Sets a localization `string` for the given `locale`.

Usage:
```lua
local L = namespace.L('deDE')
L['New string'] = 'Neue saite'
```
--]]
--[[ namespace.L[`string`]
Reads a localized `string` for the active locale.  
If a localized string for the active locale is not available the `string` will be read back.

Usage:
```lua
print(namespace.L['New string']) --> "Neue saite" on german clients, "New string" on all others
print(namespace.L['Unknown']) --> "Unknown" on all clients since there are no localizations
```
--]]
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
