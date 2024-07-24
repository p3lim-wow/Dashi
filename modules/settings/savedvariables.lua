local _, addon = ...

-- callback system that addons can use to detect when the player changes
-- any setting, but also used internally to update the settings panel

--[[ namespace:LoadOptions(_savedvariables_, _defaults_)
Loads a set of `savedvariables`, with `defaults` being set if they don't exist.

Will trigger `namespace:TriggerOptionCallback(key, value)` for each pair.
--]]
function addon:LoadOptions(savedvariable, defaults)
	addon:ArgCheck(savedvariable, 1, 'string')
	addon:ArgCheck(defaults, 2, 'table')
	assert(not self.optionsName, "can't load options more than once")

	self.optionsDefaults = defaults
	self.optionsName = savedvariable

	if not _G[savedvariable] then
		-- set defaults
		_G[savedvariable] = {}
	end

	-- migrate savedvariables or load defaults
	for key, value in next, defaults do
		if _G[savedvariable][key] == nil then
			_G[savedvariable][key] = value
		end
	end

	-- trigger callbacks, this will write defaults to the savedvariable and update the settings panel
	for key, value in next, _G[savedvariable] do
		self:TriggerOptionCallbacks(key, value)
	end
end

--[[ namespace:LoadExtraOptions(_defaults_)
Loads a set of extra savedvariables, with `defaults` being set if they don't exist.  
Requires options to be loaded.

Will trigger `namespace:TriggerOptionCallback(key, value)` for each pair.
--]]
function addon:LoadExtraOptions(defaults)
	assert(self.optionsName, "options not loaded")
	addon:ArgCheck(defaults, 1, 'table')

	-- migrate or load defaults
	for key, value in next, defaults do
		if _G[self.optionsName][key] == nil then
			_G[self.optionsName][key] = value
		end
	end

	-- trigger callbacks
	for key, value in next, _G[self.optionsName] do
		if defaults[key] ~= nil then
			self:TriggerOptionCallbacks(key, value)
		end
	end
end

--[[ namespace:GetOption(_key_)
Returns the value for the given option `key`.
--]]
function addon:GetOption(key)
	assert(self:AreOptionsLoaded(), "options aren't loaded")
	addon:ArgCheck(key, 1, 'string')

	if _G[self.optionsName][key] ~= nil then
		return _G[self.optionsName][key]
	else
		return self.optionsDefaults[key]
	end
end

--[[ namespace:GetOptionDefault(_key_)
Returns the default value for the given option `key`.
--]]
function addon:GetOptionDefault(key)
	addon:ArgCheck(key, 1, 'string')

	return self.optionsDefaults ~= nil and self.optionsDefaults[key]
end

--[[ namespace:SetOption(_key_, _value_)
Sets a new `value` to the given options `key`.
--]]
function addon:SetOption(key, value)
	assert(self:AreOptionsLoaded(), "options aren't loaded")
	addon:ArgCheck(key, 1, 'string')

	_G[self.optionsName][key] = value
	self:TriggerOptionCallbacks(key, value)
end

function addon:SetOptionDefault(key, value)
	assert(self:AreOptionsLoaded(), "options aren't loaded")
	addon:ArgCheck(key, 1, 'string')

	self.optionsDefaults[key] = value

	if _G[self.optionsName][key] == nil then
		self:SetOption(key, value)
	end
end

do
	local function startswith(str, start)
		return str:sub(1, #start) == start
	end

	function addon:GetOptions(prefix)
		assert(self:AreOptionsLoaded(), "options aren't loaded")

		local options = {}
		for key, value in next, _G[self.optionsName] do
			if not prefix or startswith(key, prefix) then
				options[key] = value
			end
		end

		return options
	end
end

--[[ namespace:AreOptionsLoaded()
Checks to see if the savedvariables has been loaded in the game.
--]]
function addon:AreOptionsLoaded()
	-- prevent API from trying to retrieve or set options before they are loaded
	return self.optionsName and _G[self.optionsName] ~= nil
end

--[[ namespace:RegisterOptionCallback(_key_, _callback_)
Register a `callback` function with the option `key`.
--]]
function addon:RegisterOptionCallback(key, callback)
	addon:ArgCheck(key, 1, 'string')
	addon:ArgCheck(callback, 2, 'function')

	if not self.callbacks then
		self.callbacks = {}
	end

	if not self.callbacks[key] then
		self.callbacks[key] = {}
	end

	table.insert(self.callbacks[key], callback)
end

--[[ namespace:TriggerOptionCallbacks(_key_, _value_)
Trigger all registered option callbacks for the given `key`, supplying the `value`.
--]]
function addon:TriggerOptionCallbacks(key, value)
	addon:ArgCheck(key, 1, 'string')

	if self.callbacks and self.callbacks[key] then
		for _, callback in next, self.callbacks[key] do
			callback(value)
		end
	end
end
