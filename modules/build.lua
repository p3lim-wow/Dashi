local _, addon = ...

local _, buildVersion, _, interfaceVersion = GetBuildInfo()
--[[ namespace:IsRetail()
Checks if the current client is running the "retail" version.
--]]
function addon:IsRetail()
	return interfaceVersion > 100000
end

--[[ namespace:IsClassicEra()
Checks if the current client is running the "classic era" version (e.g. vanilla).
--]]
function addon:IsClassicEra()
	return interfaceVersion < 20000
end

--[[ namespace:IsClassic()
Checks if the current client is running the "classic" version.
--]]
function addon:IsClassic()
	return not addon:IsRetail() and not addon:IsClassicEra()
end

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
