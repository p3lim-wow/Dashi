local _, addon = ...

--[[ namespace:IsRetail()
Checks if the current client is running the "retail" version.
--]]
function addon:IsRetail()
	return WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
end

--[[ namespace:IsClassicEra()
Checks if the current client is running the "classic era" version (e.g. vanilla).
--]]
function addon:IsClassicEra()
	return WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
end

--[[ namespace:IsClassic()
Checks if the current client is running the "classic" version.
--]]
function addon:IsClassic()
	-- instead of using the floating constant for classic we'll just NOR the other two,
	-- as they are static
	return not addon:IsRetail() and not addon:IsClassicEra()
end

local _, buildVersion, _, interfaceVersion = GetBuildInfo()
--[[ namespace:HasBuild(_buildNumber_[, _interfaceVersion_])
Checks if the current client is running a build equal to or newer than the specified.  
Optionally also check against the interface version.
--]]
function addon:HasBuild(build, interface)
	if interface and interfaceVersion < interface then
		return
	end

	return tonumber(buildVersion) >= build
end
