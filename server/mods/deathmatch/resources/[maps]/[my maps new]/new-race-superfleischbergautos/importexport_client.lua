local RACE_RESOURCE = getResourceDynamicElementRoot(getResourceFromName("race"))

MARKER_EXPORT = getElementByID("_MARKER_EXPORT_PARK")
MARKER_BOAT = getElementByID("_MARKER_EXPORT_BOAT")

BOAT_DETECTOR = createColCuboid(-476, -966, -5, 929, 839, 15)
GODMODE_REGION_BOAT = createColCircle(-12.5, -342.0, 30)
GODMODE_REGION_PLANE = createColCuboid(-61, -233, 0, 30, 29, 25)
SPAWN_AREA = createColCuboid(20, -329, 1, 91, 34, 23)

PARTY_PRESENT = false
PARTY_LIGHTS = {getElementByID("PARTY_LIGHTS_1"),
				getElementByID("PARTY_LIGHTS_2"),
				getElementByID("PARTY_LIGHTS_3"),
				getElementByID("PARTY_LIGHTS_4"),
				getElementByID("PARTY_LIGHTS_5"),
				getElementByID("PARTY_LIGHTS_6"),
				getElementByID("PARTY_LIGHTS_7")}



LOW_DAMAGE_DIVISOR = 2

LOW_DAMAGE = false
CAR_DELIVERING = false

PLAYER_CURRENT_TARGET = 1
-- LAST_CAR = false

RACE_STARTED_ALREADY = 0


VEHICLE_WEAPONS = {
	[28] = true, --predator
	[31] = true, --rustler, seasparrow, rc baron
	[37] = true, --heat seeking missiles I think
	[38] = true, --hunter minigun
	[51] = true  --hunter missiles, tank
}

HELICOPTERS = {
	[417] = true, -- leviathn
	[425] = true, -- hunter
	[447] = true, -- seaspar
	[469] = true, -- sparrow
	[487] = true, -- maverick
	[488] = true, -- vcnmav
	[497] = true, -- polmav
	[548] = true, -- cargobob
	[563] = true, -- raindanc

	[465] = true, -- rcraider
	[501] = true, -- rcgoblin

	[460] = true, -- skimmer
	[511] = true, -- beagle
	[519] = true, -- shamal

	[553] = true, -- nevada
	[577] = true, -- at400
	[592] = true  -- androm
}

MEDIUM_PLANES = {
	[476] = true, -- rustler
	[512] = true, -- cropdust
	[513] = true, -- stunt
	[520] = true, -- hydra
	[593] = true, -- dodo

	[460] = true, -- skimmer
	[511] = true, -- beagle
	[519] = true, -- shamal

	[553] = true, -- nevada
	[577] = true, -- at400
	[592] = true  -- androm
}

BIG_PLANES = {
	[553] = true, -- nevada
	[577] = true, -- at400
	[592] = true  -- androm
}

VEHICLES_WITH_GUNS = {
	[425] = true, -- hunter
	[430] = true, -- predator
	[447] = true, -- seaspar
	[464] = true, -- rcbaron
	[476] = true  -- rustler
}

-- HELICOPTERS = {
-- 	[417] = true, -- leviathn
-- 	[425] = true, -- hunter
-- 	[447] = true, -- seaspar
-- 	[465] = true, -- rcraider
-- 	[469] = true, -- sparrow
-- 	[487] = true, -- maverick
-- 	[488] = true, -- vcnmav
-- 	[497] = true, -- polmav
-- 	[501] = true, -- rcgoblin
-- 	[548] = true, -- cargobob
-- 	[563] = true  -- raindanc
-- }

BOATS = {
	[476] = {41, 67}, -- rustler
	[512] = {41, 67}, -- cropdust
	[513] = {41, 67}, -- stunt
	[520] = {41, 67}, -- hydra
	[593] = {41, 67}, -- dodo

	[460] = {41, 67}, -- skimmer
	[511] = {41, 67}, -- beagle
	[519] = {41, 67}, -- shamal

	[553] = {41, 67}, -- nevada
	[577] = {41, 67}, -- at400
	[592] = {41, 67}, -- androm

	[430] = {41, 46}, -- predator
	[446] = {42, 44}, -- squalo
	[452] = {41, 43}, -- speeder
	[453] = {42, 47}, -- reefer
	[454] = {42, 45}, -- tropic
	[472] = {41, 41}, -- coastg
	[473] = {41, 42}, -- dinghy
	[484] = {42, 45}, -- marquis
	[493] = {42, 43}, -- jetmax
	[595] = {42, 44}, -- launch

	[435] = {42, 42}, -- artict1
	[450] = {45, 45}, -- artict2
	[584] = {42, 42}, -- petrotr
	[591] = {25, 29}, -- artict3
	[608] = {18, 26}, -- tugstair
	[610] = {0, 16}, -- farmtr1
	[611] = {0, 18}, -- utiltr1

	[449] = {0, 42}, -- tram
	[537] = {0, 41}, -- freight
	[538] = {0, 66}, -- streak
	[569] = {0, 30}, -- freiflat
	[570] = {0, 22}, -- streakc
	[590] = {0, 46} -- freibox
}

TRAILERS = {
	[435] = {42, 42}, -- artict1
	[450] = {45, 45}, -- artict2
	[584] = {42, 42}, -- petrotr
	[591] = {25, 29}, -- artict3
	[608] = {18, 26}, -- tugstair
	[610] = {0, 16}, -- farmtr1
	[611] = {0, 18}, -- utiltr1

	[449] = {0, 42}, -- tram
	[537] = {0, 41}, -- freight
	[538] = {0, 66}, -- streak
	[569] = {0, 30}, -- freiflat
	[570] = {0, 22}, -- streakc
	[590] = {0, 46} -- freibox
}

TRAINS = {
	[449] = true, -- tram
	[537] = true, -- freight
	[538] = true, -- streak
	[569] = true, -- freiflat
	[570] = true, -- streakc
	[590] = true -- freibox
}

function deliverVehicle()
	local score = getElementData(localPlayer, "Money")
	if (not score) then
		score = 0
	end
	veh = getPedOccupiedVehicle(localPlayer)
	monetary = getVehicleHandling(veh)["monetary"]
	damage = getElementHealth(veh) / 1000
	reward = monetary * damage
	reward = math.floor(reward)
	score = score + reward
	setElementData(localPlayer, "Money", score, true)
	triggerServerEvent("updateProgress", resourceRoot, PLAYER_CURRENT_TARGET)
end

function playerStoppedInMarker()
	-- This function checks every frame if the player is stopped. If so, check conditions.
	if (CAR_DELIVERING) then
		return
	end
	
	local x, y, z = getElementPosition(localPlayer)
	if (z > 1000 or getElementData(localPlayer, "state") == "spectating") then
		-- When spectating the position is set to 30k. 1000 is the max flight limit. Do nothing
		return
	end
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if (not vehicle) then
		-- Unsure when this happens. Guessing it does in spectate mode. Either way, do nothing
		return
	end
	x, y, z = getElementVelocity(vehicle)
	shittyVelocity = x*x + y*y + z*z
	if (shittyVelocity > 0.0001) then
		-- We are not actually stopped
		return
	end
	if (getElementAttachedTo(vehicle) ~= false) then
		-- We are attached to a crane, do nothing
		return
	end
	if (isElementWithinMarker(vehicle, MARKER_EXPORT)) then
		-- We are in the export marker
		CAR_DELIVERING = true
		outputConsole("Delivering vehicle")
		deliverVehicle()
		return
	end

	-- Check if the player is stopped by any of the cranes. Check crane 2 first because 1 doesnt need to do anything if 2 can handle it.
	if (BOATS[getElementModel(vehicle)] and isElementWithinColShape(vehicle, REACH_CRANE2)) then
		craneGrab(2)
	elseif (BOATS[getElementModel(vehicle)] and isElementWithinColShape(vehicle, REACH_CRANE1)) then
		craneGrab(1)
	end
end
setTimer(playerStoppedInMarker, 1, 0)

function bigPlaneDelivery()
	veh = getPedOccupiedVehicle(localPlayer)
	if (not veh) then
		return
	end
	if (veh ~= getPedOccupiedVehicle(localPlayer)) then
		return
	end
	if (not MEDIUM_PLANES[getElementModel(veh)]) then
		return
	end
	if (CRANE_STATE[2] == "sleeping") then
		-- Deliver because we used the crane to drop us off
		outputConsole("Delivering plane due to CRANE_STATE 2 == sleeping")
		deliverVehicle()
		return
	end

	if (not BIG_PLANES[getElementModel(veh)]) then
		return
	end
	if (not isElementWithinColShape(veh, GODMODE_REGION_PLANE)) then
		return
	end
	if (getElementAttachedTo(veh) ~= false) then
		return
	end
	x, y, z = getElementVelocity(veh)
	shittyVelocity = x*x + y*y + z*z
	if (shittyVelocity > 0.001) then
		return
	end
	-- collectCheckpoints(PLAYER_CURRENT_TARGET)
	outputConsole("Delivering big plane")
	deliverVehicle()
end
setTimer(bigPlaneDelivery, 100, 0)

function updateTarget(new)
	iprint("Update Target")
	CAR_DELIVERING = false
	-- Autoload
	if (new > PLAYER_CURRENT_TARGET + 1) then
		PLAYER_CURRENT_TARGET = new - 1
		MID_PLAY_BLURB = "Your saved progress has been restored. Use /ie_resetprogress to undo."
		SHOW_MID_PLAY_TUTORIAL = true
		setTimer(function()
			SHOW_MID_PLAY_TUTORIAL = false
		end, 7000, 1)
	end
	-- Reset progress?
	if (new < PLAYER_CURRENT_TARGET) then
		PLAYER_CURRENT_TARGET = new - 1
	end
	-- Normal behavior
	collectCheckpoints(PLAYER_CURRENT_TARGET)
	PLAYER_CURRENT_TARGET = new
	resetDeliveryArea()
	if (new == 212 and not PARTY_PRESENT) then
		for i=#PARTY_LIGHTS,1,-1 do
			local x, y, z = getElementPosition(PARTY_LIGHTS[i])
			setElementPosition(PARTY_LIGHTS[i], x, y, z + 30)
		end
	end
end
addEvent("updateTarget", true)
addEventHandler("updateTarget", localPlayer, updateTarget)

function resetDeliveryArea()
	veh = getPedOccupiedVehicle(localPlayer)
	if (veh) then
		detachElements(veh)
		setHeliBladeCollisionsEnabled ( veh, false )
	end
	CRANE_STATE[1] = "available"
	CRANE_STATE[2] = "available"

	local carName = VEHICLE_NAMES[getElementModel(veh)]
	CAR_BLURB = carName
	setElementData(localPlayer, "Vehicle", carName, true)
	SHOW_CAR = true
	setTimer(function()
		SHOW_CAR = false
	end, 6500, 1)

	hideRamps()
	
	LOW_DAMAGE = false
	setElementCollisionsEnabled(BLOCKING_BRIDGE, true)
end

---- Prevent players from harming one another or themselves in certain cases
---- Prevent players from harming one another or themselves in certain cases
---- Prevent players from harming one another or themselves in certain cases
---- Prevent players from harming one another or themselves in certain cases
---- Prevent players from harming one another or themselves in certain cases

function enableGodMode(element, matchingDimension)
	if (getElementType(element) ~= "vehicle") then
		return
	end
	if (source == GODMODE_REGION_BOAT) then
		if (BOATS[getElementModel(element)]) then
			LOW_DAMAGE = true
			-- setVehicleDamageProof(element, true)
		end
	elseif (source == GODMODE_REGION_PLANE) then
		if (HELICOPTERS[getElementModel(element)]) then
			LOW_DAMAGE = true
			-- setVehicleDamageProof(element, true)
		end
	end

end
addEventHandler("onClientColShapeHit", GODMODE_REGION_BOAT, enableGodMode)
addEventHandler("onClientColShapeHit", GODMODE_REGION_PLANE, enableGodMode)

function disableGodMode(element, matchingDimension)
	if (getElementType(element) ~= "vehicle") then
		return
	end
	LOW_DAMAGE = false
	-- setVehicleDamageProof(element, false)
end
addEventHandler("onClientColShapeLeave", GODMODE_REGION_BOAT, disableGodMode)
addEventHandler("onClientColShapeLeave", GODMODE_REGION_PLANE, disableGodMode)

function handleVehicleDamage(attacker, weapon, loss, x, y, z, tire)
	-- if (HELICOPTERS[getElementModel(source)] and attacker ~= nil) then
	-- 	setHeliBladeCollisionsEnabled ( source, false )
	-- 	iprint("Cancelling helicopter blade attack")
	-- 	cancelEvent()
	-- end
	if (VEHICLE_WEAPONS[weapon] and attacker ~= localPlayer) then
		cancelEvent()
	elseif (LOW_DAMAGE) then
		setElementHealth(source, getElementHealth(source) - (loss / LOW_DAMAGE_DIVISOR))
		cancelEvent()
	end
end
addEventHandler("onClientVehicleDamage", root, handleVehicleDamage)

-- New Crane Stuff
-- New Crane Stuff
-- New Crane Stuff
-- New Crane Stuff

function playerDead(killer, weapon, bodypart)
	resetDeliveryArea()
end
addEventHandler("onClientPlayerWasted", localPlayer, playerDead)

function preRace()
	initCranes()
	if (RACE_STARTED_ALREADY > 0) then
		return
	end
	setTimer(function()
		if (RACE_STARTED_ALREADY > 0) then
			return
		end
		setCameraMatrix (  -213.5, -453.5, 63.5, -118.0, -353.8, 0.5)
	end, 1000, 1)
end
addEventHandler("onClientMapStarting", localPlayer, preRace)

function didWeStartYet(yes)
	RACE_STARTED_ALREADY = yes
	setCameraTarget ( localPlayer )
end
addEvent("didWeStartYet", true)
addEventHandler("didWeStartYet", localPlayer, didWeStartYet)

function introCutscene()
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if (vehicle) then
		setElementPosition(vehicle, 135.9, -309.1, 9.2)
	end
	setCameraMatrix ( -213.5, -453.5, 63.5, -118.0, -353.8, 0.5)
	setTimer(function()
		setCameraMatrix ( -4.6, -99.4, 38.0, -55.0, -233.0, 26.0)
		-- SHOW_TUTORIAL = true
	end, 6000, 1)
	setTimer(function()
		TUTORIAL_BLURB = "#E1E1E1Deliver all the #FDFEFDvehicles #E1E1E1to the #BAA861FleischBerg© factory#E1E1E1!"
		SHOW_TUTORIAL = true
	end, 7000, 1)
	setTimer(function()
		setCameraMatrix ( -27.7, -209.6, 10.9, -50.2, -222.3, 6.4)
		SHOW_TUTORIAL = false
	end, 11000, 1)
	setTimer(function()
		TUTORIAL_BLURB = "#E1E1E1Vehicles can be delivered by parking them in this marker."
		SHOW_TUTORIAL = true
	end, 11500, 1)
	setTimer(function()
		setCameraMatrix ( 150.0, -392.0, 55.0, -39.0, -293.0, 32.0)
		SHOW_TUTORIAL = false
	end, 16000, 1)
	setTimer(function()
		TUTORIAL_BLURB = "#E1E1E1These cranes will assist you with boats, trains, planes, and trailers."
		SHOW_TUTORIAL = true
	end, 16500, 1)
	setTimer(function()
		setCameraMatrix ( 170.5, -432.8, 18.0, 100.3, -399.5, 6.8)
		SHOW_TUTORIAL = false
	end, 22000, 1)
	setTimer(function()
		TUTORIAL_BLURB = "#E1E1E1Simply park these vehicles anywhere within the cranes' range, \nsuch as inside this #1925B8blue marker."
		SHOW_TUTORIAL = true
	end, 22500, 1)
	setTimer(function()
		SHOW_TUTORIAL = false
	end, 28000, 1)
	setTimer(function()
		if (getCameraTarget(localPlayer) ~= localPlayer) then
			setCameraTarget ( localPlayer )
		end
	end, 32000, 1)
end

function postCutsceneGameStart()
	iprint("even called yo?) ")
	resetDeliveryArea()
	-- SHOW_CAR = true
	-- setTimer(function()
	-- 	SHOW_CAR = false
	-- end, 6500, 1)
end
addEvent("postCutsceneGameStart", true)
addEventHandler("postCutsceneGameStart", localPlayer, postCutsceneGameStart)
	


-- Initialize all the crane stuff
function preCutsceneGameStart()
	introCutscene()
	initCranes()
	-- resetDeliveryArea()
	setElementData(localPlayer, "Money", 0, true)

	local x, y, z = getElementPosition(MARKER_BOAT)
	createBlip(x, y, z, 9) -- Boat blip

	-- Heli blades are scoffed in ghost mode and MTA does not support any way to fix them decently.
	-- However I can at least disable heliblade collisions of other players so they don't knock you out of the way
	-- You can still knock yourself out of the way by hitting other players with your blades though, despite them being ghost
	-- Update: Nope, that's annoying too. Disable player's blades too.
	local allVehicles = getElementsByType("vehicle")
	-- local myVehicle = getPedOccupiedVehicle(localPlayer)
	for i, v in ipairs(allVehicles) do
		-- if (v ~= myVehicle) then
			setHeliBladeCollisionsEnabled ( v, false )
		-- end
	end
end
addEvent("gridCountdownStarted", true)
addEventHandler("gridCountdownStarted", resourceRoot, preCutsceneGameStart)

function repairVehicleOnCrane()
	local veh = getPedOccupiedVehicle(localPlayer)
	if (veh and getElementAttachedTo(veh) ~= false and getElementHealth(veh) < 250) then
		setElementHealth(veh, 251)
	end
end
setTimer(repairVehicleOnCrane, 100, 0)


--- Other Stuff
--- Other Stuff
--- Other Stuff
--- Other Stuff
--- Other Stuff
--- Other Stuff
--- Other Stuff
--- Other Stuff

function playGoSound()
	playSoundFrontEnd(45)
end
addEvent("playGoSound", true)
addEventHandler("playGoSound", resourceRoot, playGoSound)



