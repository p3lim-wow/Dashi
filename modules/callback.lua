local _, addon = ...

local callbacks = {}
--[[ namespace:RegisterCallback(_event_, _callback_) ![](https://img.shields.io/badge/function-blue)
Registers a `callback` with an `event` in the [CallbackRegistry](https://warcraft.wiki.gg/wiki/EventRegistry#CallbackRegistry)..
--]]
function addon:RegisterCallback(event, callback)
	addon:ArgCheck(event, 1, 'string')
	addon:ArgCheck(callback, 2, 'function')

	if not callbacks[event] then
		callbacks[event] = {}
	end

	table.insert(callbacks[event], {
		callback = callback,
		owner = EventRegistry:RegisterCallback(event, callback),
	})
end

--[[ namespace:UnregisterCallback(_event_, _callback_) ![](https://img.shields.io/badge/function-blue)
Unregisters an existing `callback` with an `event` in the [CallbackRegistry](https://warcraft.wiki.gg/wiki/EventRegistry#CallbackRegistry)..
--]]
function addon:UnregisterCallback(event, callback)
	addon:ArgCheck(event, 1, 'string')
	addon:ArgCheck(callback, 2, 'function')

	if callbacks[event] then
		for index, data in next, callbacks[event] do
			if data.callback == callback then
				EventRegistry:UnregisterCallback(event, data.owner)
				callbacks[event][index] = nil
				break
			end
		end
	end
end

--[[ namespace:UnregisterAllCallbacks(_event_) ![](https://img.shields.io/badge/function-blue)
Unregisters all callbacks registered with the `event` in the [CallbackRegistry](https://warcraft.wiki.gg/wiki/EventRegistry#CallbackRegistry)..
--]]
function addon:UnregisterAllCallbacks(event)
	addon:ArgCheck(event, 1, 'string')

	if callbacks[event] then
		for _, data in next, callbacks[event] do
			EventRegistry:UnregisterCallback(event, data.owner)
		end

		table.wipe(callbacks[event])
	end
end

--[[ namespace:IsCallbackRegistered(_event_, _callback_) ![](https://img.shields.io/badge/function-blue)
Checks if the `event` is registered with the `callback` in the [CallbackRegistry](https://warcraft.wiki.gg/wiki/EventRegistry#CallbackRegistry)..
--]]
function addon:IsCallbackRegistered(event, callback)
	addon:ArgCheck(event, 1, 'string')
	addon:ArgCheck(callback, 2, 'function')

	if callbacks[event] then
		for _, cbs in next, EventRegistry:GetCallbacksByEvent('Function') do
			for _, cb in next, cbs do
				if cb == callback then
					return true
				end
			end
		end

		-- for index, data in next, callbacks[event] do
		-- 	if data.callback == callback then
		-- 		return true
		-- 	end
		-- end
	end

	return false
end

--[[ namespace:TriggerCallback(_event_[, _..._]) ![](https://img.shields.io/badge/function-blue)
Trigger the callback `event` (with optional arguments) in the [CallbackRegistry](https://warcraft.wiki.gg/wiki/EventRegistry#CallbackRegistry)..
--]]
function addon:TriggerCallback(event, ...)
	addon:ArgCheck(event, 1, 'string')
	EventRegistry:TriggerEvent(event, ...)
end
