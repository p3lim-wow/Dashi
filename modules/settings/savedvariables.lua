local addonName, addon = ...

-- callback system that addons can use to detect when the player changes
-- any setting, but also used internally to update the settings panel
function addon:RegisterOptionCallback(key, callback, src)
	if not self.callbacks then
		self.callbacks = {}
	end

	if not self.callbacks[key] then
		self.callbacks[key] = {}
	end

	table.insert(self.callbacks[key], callback)
end

function addon:TriggerOptionCallbacks(key, value)
	if self.callbacks and self.callbacks[key] then
		for _, callback in next, self.callbacks[key] do
			callback(value)
		end
	end
end

function addon:GetOption(key)
	assert(self:AreOptionsLoaded(), "options aren't loaded")
	return _G[self.optionsName][key] or self.optionsDefaults[key]
end

function addon:GetOptionDefault(key)
	return self.optionsDefaults and self.optionsDefaults[key]
end

function addon:SetOption(key, value)
	assert(self:AreOptionsLoaded(), "options aren't loaded")
	_G[self.optionsName][key] = value
	self:TriggerOptionCallbacks(key, value)
end

function addon:LoadOptions(savedvariable, defaults)
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

function addon:AreOptionsLoaded()
	-- prevent API from trying to retrieve or set options before they are loaded
	return self.optionsName and _G[self.optionsName] ~= nil
end
