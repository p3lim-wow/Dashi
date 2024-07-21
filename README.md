# Dashi

Dashi is a boilerplate that simplifies addon creation.

Yes, the name is a pun.  
Yes, you can use this if you want.  
No, you should not depend on it being stable.

## Legal

This repository is dedicated to the [public domain](https://en.wikipedia.org/wiki/Public-domain_software).

## Documentation

List of what this brings to the addon loading it.

In each example `namespace` refers to the 2nd value of the addon vararg, e.g:
```lua
local _, namespace = ...
```

***

<!-- DOCSTART -->
### namespace:RegisterSlash(_command_[, _commandN,..._], _callback_)

Registers chat slash `command`(s) with a `callback` function.

Usage:
```lua
namespace:RegisterSlash('/hello', '/hi', function(input)
    print('Hi')
end)
```

***

### namespace.eventMixin

A multi-purpose [event](https://warcraft.wiki.gg/wiki/Events)-[mixin](https://en.wikipedia.org/wiki/Mixin).

These methods are also available as methods directly on `namespace`.

***

### namespace.eventMixin:RegisterEvent(_event_, _callback_)

Registers a [frame `event`](https://warcraft.wiki.gg/wiki/Events) with the `callback` function.  
If the callback returns positive it will be unregistered.

***

### namespace.eventMixin:UnregisterEvent(_event_, _callback_)

Unregisters a [frame `event`](https://warcraft.wiki.gg/wiki/Events) from the `callback` function.

***

### namespace.eventMixin:IsEventRegistered(_event_, _callback_)

Checks if the [frame `event`](https://warcraft.wiki.gg/wiki/Events) is registered with the `callback` function.

***

### namespace.eventMixin:TriggerEvent(_event_[, _..._])

Manually trigger the `event` (with optional arguments) on all registered callbacks.  
If the callback returns positive it will be unregistered.

***

### namespace.eventMixin:RegisterUnitEvent(_event_, _unit_[, _unitN,..._], _callback_)

Registers a [`unit`](https://warcraft.wiki.gg/wiki/UnitId)-specific [frame `event`](https://warcraft.wiki.gg/wiki/Events) with the `callback` function.  
If the callback returns positive it will be unregistered for that unit.

***

### namespace.eventMixin:UnregisterUnitEvent(_event_, _unit_[, _unitN,..._], _callback_)

Unregisters a [`unit`](https://warcraft.wiki.gg/wiki/UnitId)-specific [frame `event`](https://warcraft.wiki.gg/wiki/Events) from the `callback` function.

***

### namespace.eventMixin:IsUnitEventRegistered(_event_, _unit_[, _unitN,..._], _callback_)

Checks if the [`unit`](https://warcraft.wiki.gg/wiki/UnitId)-specific [frame `event`](https://warcraft.wiki.gg/wiki/Events) is registered with the `callback` function.

***

### namespace.eventMixin:TriggerEvent(_event_, _unit_[, _unitN,..._][, _..._])

Manually trigger the [`unit`](https://warcraft.wiki.gg/wiki/UnitId)-specific `event` (with optional arguments) on all registered callbacks.  
If the callback returns positive it will be unregistered.

***

### namespace.eventMixin:RegisterCombatEvent(_subEvent_, _callback_)

Registers a [combat `subEvent`](https://warcraft.wiki.gg/wiki/COMBAT_LOG_EVENT) with the `callback` function.  
If the callback returns positive it will be unregistered.

***

### namespace.eventMixin:UnregisterCombatEvent(_subEvent_, _callback_)

Unregisters a [combat `subEvent`](https://warcraft.wiki.gg/wiki/COMBAT_LOG_EVENT) from the `callback` function.

***

### namespace.eventMixin:TriggerCombatEvent(_subEvent_)

Manually trigger the [combat `subEvent`](https://warcraft.wiki.gg/wiki/COMBAT_LOG_EVENT) on all registered callbacks.  
If the callback returns positive it will be unregistered.

* Note: this is pretty useless on it's own, and should only ever be triggered by the event system.

***

### namespace:OnLoad()

Shorthand for the [`ADDON_LOADED`](https://warcraft.wiki.gg/wiki/ADDON_LOADED) for the addon.

Usage:
```lua
function namespace:OnLoad()
    -- I'm loaded!
end
```

***

### namespace:_event_

Registers a  to an anonymous function.

Usage:
```lua
function namespace:BAG_UPDATE(bagID)
    -- do something
end
```

***

### namespace:_event_([_..._])

Manually trigger all registered anonymous `event` callbacks, with optional arguments.

Usage:
```lua
namespace:BAG_UPDATE(1) -- triggers the above example
```

***

### namespace:IsRetail()

Checks if the current client is running the "retail" version.

***

### namespace:IsClassicEra()

Checks if the current client is running the "classic era" version (e.g. vanilla).

***

### namespace:IsClassic()

Checks if the current client is running the "classic" version.

***

### namespace:ArgCheck(arg, argIndex, type[, type...])

Checks if the argument `arg` at position `argIndex` is of type(s).

***

### namespace:Hide(_object_[, _child_,...])

Forcefully hide an `object`, or its `child`.  
It will recurse down to the last child if provided.

***

### namespace:ExtractIDFromGUID(_guid_)

Returns the integer `id` from the given [`guid`](https://warcraft.wiki.gg/wiki/GUID).

***

### namespace:GetNPCID(_unit_)

Returns the integer `id` of the given [`unit`](https://warcraft.wiki.gg/wiki/UnitId).

***

### namespace:GetItemLinkFromID(_itemID_)

Generates an [item link](https://warcraft.wiki.gg/wiki/ItemLink) from an `itemID`.  
This is a crude generation and won't have valid data for complex items.

***

### namespace:GetPlayerMapID()

Returns the ID of the current map the zone the player is located in.

***

### namespace:GetPlayerPosition(_mapID_)

Returns the `x` and `y` coordinates for the player in the given `mapID` (if they are valid).

***

### namespace:tsize(_table_)

Returns the number of entries in the `table`.  
Works for associative tables as opposed to `#table`.

***

### namespace:GetUnitAura(_unit_, _spellID_, _filter_)

Returns the aura by `spellID` on the [`unit`](https://warcraft.wiki.gg/wiki/UnitId), if it exists.

* [`unitID`](https://warcraft.wiki.gg/wiki/UnitId)
* `spellID` - spell ID to check for
* `filter` - aura filter, see [UnitAura](https://warcraft.wiki.gg/wiki/API_C_UnitAuras.GetAuraDataByIndex#Filters)

***

### namespace:CreateFrame(_..._)

A wrapper for [`CreateFrame`](https://warcraft.wiki.gg/wiki/API_CreateFrame), mixed in with `namespace.eventMixin`.

***

### namespace:CreateButton(...)

A wrapper for `namespace:CreateFrame(...)`, but will handle key direction preferences of the client.  
Use this specifically to create clickable buttons.

***

### namespace:CreateScrollList(_parent_, [...])

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

***

### namespace:CreateScrollGrid(_parent_, [...])

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

***

### namespace:Print(_..._)

Prints out a message in the chat frame, prefixed with the addon name in color.

***

### namespace:Printf(_fmt_, _..._)

Wrapper for `namespace:Print(...)` and `string.format`.

***

### namespace:Dump(_object_[, _startKey_])

Wrapper for `DevTools_Dump`.

***

### namespace:DumpUI(_object_)

Similar to `namespace:Dump(object)`; a wrapper for the graphical version.

***

### namespace:Defer(_callback_[, _..._])

Defers a function `callback` (with optional arguments) until after combat ends.  
Immediately triggers if player is not in combat.

***

### namespace:Defer(_object_, _method_[, _..._])

Defers a method `method` on `object` (with optional arguments) until after combat ends.  
Immediately triggers if player is not in combat.

***

### namespace.L(_locale_)[`string`]

Sets a localization `string` for the given `locale`.

Usage:
```lua
local L = namespace.L('deDE')
L['New string'] = 'Neue saite'
```

***

### namespace.L[`string`]

Reads a localized `string` for the active locale.  
If a localized string for the active locale is not available the `string` will be read back.

Usage:
```lua
print(namespace.L['New string']) --> "Neue saite" on german clients, "New string" on all others
print(namespace.L['Unknown']) --> "Unknown" on all clients since there are no localizations
```

***

### namespace:HookAddOn(_addonName_, _callback_)

Registers a hook for when an addon with the name `addonName` loads with a `callback` function.

***

### namespace:OnLogin()

Shorthand for the [`PLAYER_LOGIN`](https://warcraft.wiki.gg/wiki/PLAYER_LOGIN).

Usage:
```lua
function namespace:OnLogin()
    -- player has logged in!
end
```

***

### namespace:LoadOptions(_savedvariables_, _defaults_)

Loads a set of `savedvariables`, with `defaults` being set if they don't exist.

Will trigger `namespace:TriggerOptionCallback(key, value)` for each pair.

***

### namespace:LoadExtraOptions(_defaults_)

Loads a set of extra savedvariables, with `defaults` being set if they don't exist.  
Requires options to be loaded.

Will trigger `namespace:TriggerOptionCallback(key, value)` for each pair.

***

### namespace:GetOption(_key_)

Returns the value for the given option `key`.

***

### namespace:GetOptionDefault(_key_)

Returns the default value for the given option `key`.

***

### namespace:SetOption(_key_, _value_)

Sets a new `value` to the given options `key`.

***

### namespace:AreOptionsLoaded()

Checks to see if the savedvariables has been loaded in the game.

***

### namespace:RegisterOptionCallback(_key_, _callback_)

Register a `callback` function with the option `key`.

***

### namespace:TriggerOptionCallbacks(_key_, _value_)

Trigger all registered option callbacks for the given `key`, supplying the `value`.

***

### namespace:RegisterSettings(_savedvariables_, _settings_)

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

***

### namespace:RegisterSubSettings(_name_, _settings_)

Registers a set of `settings` as a sub-category. `name` must be unique.  
The values will be stored by the `settings`' objects' `key` in the previously created savedvariables.

The `settings` are identical to that of `namespace:RegisterSettings`.

***

### namespace:RegisterSubSettingsCanvas(_name_, _callback_)

Registers a canvas sub-category. This does not handle savedvariables.

`name` must be unique, and `callback` is called with a canvas `frame` as payload.

Canvas frame has a custom method `SetDefaultsHandler` which takes a callback as arg1.
This callback is triggered when the "Defaults" button is clicked.

***

### namespace:RegisterSettingsSlash(_..._)

Wrapper for `namespace:RegisterSlash(...)`, except the callback is provided and will open the interface options for this addon.
<!-- DOCEND -->
