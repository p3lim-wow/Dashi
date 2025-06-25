local addonName, addon = ...

do
	local function resetPin(_, pin)
		pin:Hide()
		pin:ClearAllPoints()
		pin:OnReleased()
	end

	local mixin = CreateFromMixins(MapCanvasPinMixin)
	function mixin:SetPassThroughButtons()
		-- don't let the protected method be called willy-nilly
		-- https://github.com/Stanzilla/WoWUIBugs/issues/453
	end

	function mixin:CheckMouseButtonPassthrough()
		-- don't let MapCanvas mess with protected methods willy-nilly
	end

	function mixin:SetPropagateMouseClicks()
		-- don't let MapCanvas mess with protected methods willy-nilly
	end

	--[[ namespace:CreateMapPinTemplate(_name_[, _pinMixin_]) ![](https://img.shields.io/badge/function-blue)
	Creates and returns a world map pin template and pool with safe passthrough button support.  
	The `pinMixin` inherits `MapCanvasPinMixin`.
	--]]
	function addon:CreateMapPinTemplate(name, pinMixin)
		-- TODO: assertions
		pinMixin = pinMixin or {}

		local templateName = addonName .. name .. 'PinTemplate'
		local pool = CreateUnsecuredRegionPoolInstance(templateName)
		pool.resetFunc = resetPin
		pool.createFunc = function()
			local pin = Mixin(CreateFrame('Button', nil, WorldMapFrame:GetCanvas()), mixin, pinMixin)
			pin:SetSize(1, 1) -- needs a size to even show up
			return pin
		end

		return templateName, pool
	end
end

do
	local mixin = {}
	function mixin:SetPinTemplate(templateName)
		self.pinTemplateName = templateName
	end

	function mixin:GetPinTemplate()
		return self.pinTemplateName
	end

	-- shorthands for pin handling
	function mixin:AcquirePin(...)
		return self:GetMap():AcquirePin(self:GetPinTemplate(), ...)
	end

	function mixin:RemoveAllPins()
		return self:GetMap():RemoveAllPinsByTemplate(self:GetPinTemplate())
	end

	function mixin:EnumeratePins()
		return self:GetMap():EnumeratePinsByTemplate(self:GetPinTemplate())
	end

	function mixin:GetNumPins()
		return self:GetMap():GetNumActivePinsByTemplate(self:GetPinTemplate())
	end

	function mixin:HasPins()
		return self:GetNumPins() > 0
	end

	-- taint-safe event handling
	function mixin:RegisterEvent(event)
		if not self.frameEvents then
			self.frameEvents = {}
		end

		if not self.frameEventsHandler then
			self.frameEventsHandler = CreateFrame('Frame')
			self.frameEventsHandler:SetScript('OnEvent', function(_, ...)
				self:OnEvent(...)
			end)
		end

		if not self.frameEvents[event] then
			self.frameEventsHandler:RegisterEvent(event)
			self.frameEvents[event] = true
		end
	end

	function mixin:UnregisterEvent(event)
		if not self.frameEvents then
			return
		end

		if self.frameEvents[event] then
			self.frameEvents[event] = nil
			self.frameEventsHandler:UnregisterEvent(event)
		end
	end

	--[=[ namespace:AddMapPinProvider(_name_[, _pinMixin_[, _providerMixin_]]) ![](https://img.shields.io/badge/function-blue)
	Creates, registers, and returns a world map pin provider (and pins) with a few features:

	* taint-safe passthrough right button for the pins (see [namespace:CreateMapPinTemplate()](#namespacecreatemappintemplate-name-pinmixin-))
	* taint-safe event handler (same API as `MapCanvasDataProviderMixin` which it inherits)
	* short-hands for pin management:
	  * `self:AcquirePin([...])`
	  * `self:RemoveAllPins()`
	  * `self:EnumeratePins()`
	  * `self:GetNumPins()`
	  * `self:HasPins()`
	--]=]
	function addon:AddMapPinProvider(name, providerMixin, pinMixin)
		-- TODO: assertions
		providerMixin = providerMixin or {}
		pinMixin = pinMixin or {}

		-- wrap super calls
		if providerMixin.OnAdded then
			local providerMixinOnAdded = providerMixin.OnAdded
			providerMixin.OnAdded = function(provider, ...)
				MapCanvasDataProviderMixin.OnAdded(provider, ...)
				providerMixinOnAdded(provider, ...)
			end
		end
		if providerMixin.OnRemoved then
			local providerMixinOnRemoved = providerMixin.OnRemoved
			providerMixin.OnRemoved = function(provider, ...)
				providerMixinOnRemoved(provider, ...)
				MapCanvasDataProviderMixin.OnRemoved(provider, ...)
			end
		end

		local provider = CreateFromMixins(MapCanvasDataProviderMixin, mixin, providerMixin)

		local pinTemplate, pinPool = addon:CreateMapPinTemplate(name, pinMixin)
		provider:SetPinTemplate(pinTemplate)

		if WorldMapFrame.pinPools[pinTemplate] then
			error('pinTemplate must be unique')
		end
		WorldMapFrame.pinPools[pinTemplate] = pinPool
		WorldMapFrame:AddDataProvider(provider)

		return provider
	end
end
