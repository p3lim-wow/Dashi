local _, namespace = ...

--[[ namespace:IsRetail() ![](https://img.shields.io/badge/function-blue)
Checks if the current client is running the "retail" version.
--]]
function namespace:IsRetail()
	return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
end

--[[ namespace:IsVanilla() ![](https://img.shields.io/badge/function-blue)
Checks if the current client vanilla.
--]]
function namespace:IsVanilla()
	return WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
end

--[[ namespace:IsBurningCrusade() ![](https://img.shields.io/badge/function-blue)
Checks if the current client is tbc.
--]]
function namespace:IsBurningCrusade()
	return WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
end

--[[ namespace:IsWrath() ![](https://img.shields.io/badge/function-blue)
Checks if the current client is wrath.
--]]
function namespace:IsWrath()
	return WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
end

--[[ namespace:IsCataclysm() ![](https://img.shields.io/badge/function-blue)
Checks if the current client is cataclysm.
--]]
function namespace:IsCataclysm()
	return WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC
end

--[[ namespace:IsMists() ![](https://img.shields.io/badge/function-blue)
Checks if the current client is mists.
--]]
function namespace:IsMists()
	return WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC
end

--[[ namespace:IsClassic() ![](https://img.shields.io/badge/function-blue)
Alias for the latest classic version method from the above.
--]]
function namespace:IsClassic()
	return namespace:IsMists()
end

local _, _, _, interfaceVersion = GetBuildInfo()
--[[ namespace:HasVersion(_interfaceVersion_) ![](https://img.shields.io/badge/function-blue)
Checks if the current client is running an interface version equal to or newer than the specified.
--]]
function namespace:HasVersion(interface)
	namespace:ArgCheck(interface, 1, 'number')
	return interfaceVersion >= interface
end
