local REQUIRED, NOT_REQUIRED, LOADED = 0, 1, 2

local interface = {
	editor_main = REQUIRED,
	mapmanager = NOT_REQUIRED,
}

local interface_mt = {
	__index = function(t, k)
		return function(...) return call(t.res, k, ...) end
	end
}

addEventHandler("onResourceStart", getRootElement(),
	function(resource)
		local name = getResourceName(resource)
		if interface[name] then
			_G[name] = setmetatable({res=resource}, interface_mt)
			interface[name] = LOADED
		end
	end
)

addEventHandler("onResourceStart", getResourceRootElement(getThisResource()),
	function()
		for name in pairs(interface) do
			local resource = getResourceFromName(name)
			if resource then
				_G[name] = setmetatable({res=resource}, interface_mt)
				interface[name] = LOADED
			end
		end
	end
)

function isInterfaceLoaded()
	local isLoaded = true
	for name, state in pairs(interface) do
		if state == REQUIRED then
			isLoaded = false
			break
		end
	end
	return isLoaded
end