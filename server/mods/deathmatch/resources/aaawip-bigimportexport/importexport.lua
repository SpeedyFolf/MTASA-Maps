MARKER_TANKER = getElementByID("_MARKER_EXPORT_TANKER")
CRANE1_STATE = "init"
CRANE2_STATE = "init"
BOAT_DETECTOR = createColCuboid(-476, -966, -5, 1145, 839, 15)
-- ENDCAR_DETECTOR	= createColCuboid(-1644, -17, 16, 200, 200, 20)
LAST_CAR = false

CRANE_HOOK_VERTICAL_SPEED = 131
CRANE_HOOK_HORIZONTAL_SPEED = 181
CRANE_TURN_SPEED = 220
CRANE_TURN_ODDS = 5
HOOK_BOAT_HEIGHT_OFFSET = 6

BOATS = {
	[472] = true,
	[473] = true,
	[493] = true,
	[595] = true,
	[484] = true,
	[430] = true,
	[453] = true,
	[452] = true,
	[446] = true,
	[454] = true
}

function shuffleCars(cars)
	shuffledCars = {}
	for i = #cars, 1, -1 do
		randomIndex = math.random(1,i)
		shuffledCars[i] = cars[randomIndex]
		table.remove(cars, randomIndex)
	end
	triggerServerEvent("shuffleDone", resourceRoot, shuffledCars)
end

function makeMarkerVisible(oldModel, newModel)
	if (getVehicleOccupant(source) ~= localPlayer) then
		return
	end
	if (newModel == 514) then
		-- setMarkerColor(MARKER_TANKER, 255, 3, 3, 0)
	else
		-- setMarkerColor(MARKER_TANKER, 255, 3, 3, 0)
	end
end
addEventHandler("onClientElementModelChange", root, makeMarkerVisible)

addEvent("shuffle", true)
addEventHandler("shuffle", resourceRoot, shuffleCars)

function craneDetectTanker(element, matchingDimension)
	if (element ~= localPlayer) then
		return
	end
	vehicle = getPedOccupiedVehicle(element)
	if (not vehicle or getElementModel(vehicle) ~= 514) then
		if (LAST_CAR and CRANE_STATE == "unavailable" and vehicle and getElementModel(vehicle) ~= 522) then
			moveCraneIntoEndPositionNoTanker()
		end
		return
	end
	if (CRANE_STATE == "unavailable") then
		prepareCrane()
	elseif (CRANE_STATE == "finished") then
		resetCrane()
	end
end
-- addEventHandler("onClientColShapeHit", TANKER_DETECTOR, craneDetectTanker)

function prepareCrane()
	CRANE_STATE = "lowering"
	magnet = getElementByID("_CRANE_MAGNET")
	x,y,z = getElementPosition(magnet)
	moveObject(magnet, 3000, x, y, z - 4, 0, 0, 0, "InOutQuad")
	setTimer(function()
		CRANE_STATE = "available"
	end, 3000, 1)
end

function craneDetectFinalCar(theElement, matchingDimension)
	if (theElement ~= localPlayer) then
		return
	end
	if (CRANE_STATE == "finished" and LAST_CAR) then
		CRANE_STATE = "endgame"
		crane = {}
		crane["base"] = getElementByID("_CRANE_BASE")
		crane["head"] = getElementByID("_CRANE_HEAD")
		crane["arm"] = getElementByID("_CRANE_ARM")
		crane["magnet"] = getElementByID("_CRANE_MAGNET")
		x,y,z = getElementPosition(crane["magnet"])
		x1,y1,z1 = getElementPosition(crane["arm"])
		x2,y2,z2 = getElementPosition(crane["head"])
		wait = 1
		if (getElementModel(getPedOccupiedVehicle(localPlayer)) ~= 514) then
			wait = 4000
		end
		setTimer(function()
			moveObject(crane["magnet"], 3000, x - 0.5, y - 11.5, z - 2, 0, 0, 0, "InOutQuad")
			moveObject(crane["arm"], 3000, x1, y1, z1, -10, 0, -7, "InOutQuad")
			moveObject(crane["head"], 3000, x2, y2, z2, 0, 0, -7, "InOutQuad")
		end, wait, 1)
	end
end
-- addEventHandler("onClientColShapeHit", ENDCAR_DETECTOR, craneDetectFinalCar)

function lastCar()
	LAST_CAR = true
end
addEvent("lastCar", true)
addEventHandler("lastCar", resourceRoot, lastCar)

function resetCrane()
	CRANE_STATE = "resetting"
	crane = {}
	crane["base"] = getElementByID("_CRANE_BASE")
	crane["head"] = getElementByID("_CRANE_HEAD")
	crane["arm"] = getElementByID("_CRANE_ARM")
	crane["magnet"] = getElementByID("_CRANE_MAGNET")
	
	wait = 0
	if (LAST_CAR) then
		x,y,z = getElementPosition(crane["magnet"])
		x1,y1,z1 = getElementPosition(crane["arm"])
		x2,y2,z2 = getElementPosition(crane["head"])		
		moveObject(crane["magnet"], 3000, x + 0.5, y + 11.5, z + 2, 0, 0, 0, "InOutQuad")
		moveObject(crane["arm"], 3000, x1, y1, z1, -10, 0, 7, "InOutQuad")
		moveObject(crane["head"], 3000, x2, y2, z2, 0, 0, 7, "InOutQuad")
		wait = 3000
	end
	
	-- rotate the crane back
	x,y,z = getElementPosition(crane["magnet"])
	x1,y1,z1 = getElementPosition(crane["arm"])
	x2,y2,z2 = getElementPosition(crane["head"])
	moveObject(crane["magnet"], 3000 + wait, x - 16.6, y + 5.1, z, 0, 0, 0, "InOutQuad")
	moveObject(crane["arm"], 3000 + wait, x1, y1, z1, 30, 0, -43, "InOutQuad")
	moveObject(crane["head"], 3000 + wait, x2, y2, z2, 0, 0, -43, "InOutQuad")
	-- move the crane back
	setTimer(function()
		for i,v in pairs(crane) do
			x,y,z = getElementPosition(v)
			moveObject(v, 5000 + wait, x - 24.5, y - 24.5, z, 0, 0, 0, "InOutQuad")
		end
	end, 3000, 1)
	-- lower the magnet
	setTimer(function()
		x,y,z = getElementPosition(crane["magnet"])
		moveObject(crane["magnet"], 2000 + wait, x, y, z - 15.5, 0, 0, 0, "InOutQuad")
	end, 8000, 1)
	-- make available
	setTimer(function()
		CRANE_STATE = "available"
	end, 10000, 1)
end

function moveCraneIntoEndPositionNoTanker()
	CRANE_STATE = "endgame"
	crane = {}
	crane["base"] = getElementByID("_CRANE_BASE")
	crane["head"] = getElementByID("_CRANE_HEAD")
	crane["arm"] = getElementByID("_CRANE_ARM")
	crane["magnet"] = getElementByID("_CRANE_MAGNET")
	
	-- move the whole crane by -24.5
	for i,v in pairs(crane) do
		x,y,z = getElementPosition(v)
		moveObject(v, 5000, x + 24.5, y + 24.5, z, 0, 0, 0, "InOutQuad")
	end
	
	-- raise the magnet
	setTimer(function()
		x,y,z = getElementPosition(crane["magnet"])
		moveObject(crane["magnet"], 2000, x, y, z + 9.5, 0, 0, 0, "InOutQuad")
	end, 5000, 1)

	-- rotate stuff (The complicated step) 
	setTimer(function()
		x,y,z = getElementPosition(crane["magnet"])
		x1,y1,z1 = getElementPosition(crane["arm"])
		x2,y2,z2 = getElementPosition(crane["head"])
		moveObject(crane["magnet"], 3000, x + 16.1, y - 16.6, z, 0, 0, 0, "InOutQuad")
		moveObject(crane["arm"], 3000, x1, y1, z1, -30, 0, 36, "InOutQuad")
		moveObject(crane["head"], 3000, x2, y2, z2, 0, 0, 36, "InOutQuad")
	end, 10000, 1)
end

-- New Crane Stuff
-- New Crane Stuff
-- New Crane Stuff
-- New Crane Stuff

-- Initialize all the crane stuff
function configureCrane()
	crane = {}
	crane["base1"] = getElementByID("_CRANE1_POLE")
	crane["base2"] = getElementByID("_CRANE2_POLE")
	crane["bar1"] = getElementByID("_CRANE1_BAR")
	crane["bar2"] = getElementByID("_CRANE2_BAR")
	crane["hook1"] = getElementByID("_CRANE1_HOOK")
	crane["hook2"] = getElementByID("_CRANE2_HOOK")
	crane["rope1"] = getElementByID("_CRANE1_ROPE")
	crane["rope2"] = getElementByID("_CRANE2_ROPE")

	-- Make the cranes visibile from afar by spawning a LowLOD version (TODO: someone pls tell me what model to use)
	lowLOD3 = createObject(1391, -61.9, -286.4, 51.7, 0, 0, 0, true)
	lowLOD4 = createObject(1391, 72.4, -339.4, 26.9, 0, 0, 0, true)
	setObjectScale ( lowLOD3, 1.5)
	setObjectScale ( lowLOD4, 1.5)
	local a, b, c = getElementPosition(crane["bar1"])
	local a2, b2, c2 = getElementPosition(crane["bar2"])
	lowLOD1 = createObject(1394, a, b, c, 0, 0, 0, true)
	lowLOD2 = createObject(1394, a2, b2, c2, 0, 0, 0, true)
	setObjectScale ( lowLOD1, 1.5)
	setObjectScale ( lowLOD2, 1.5)
	attachElements ( lowLOD1, crane["bar1"], 0, 0, 0 )
	attachElements ( lowLOD2, crane["bar2"], 0, 0, 0 )

	-- attach crane 1
	local barX, barY, barZ = getElementPosition(crane["bar1"])
	local ropeX, ropeY, ropeZ = getElementPosition(crane["rope1"])
	local hookX, hookY, hookZ = getElementPosition(crane["hook1"])
	attachElements ( crane["hook1"], crane["rope1"], hookX-ropeX, hookY-ropeY, hookZ-ropeZ )
	attachElements ( crane["rope1"], crane["bar1"], ropeX-barX, ropeY-barY, ropeZ-barZ )
	
	-- attach crane 2
	local barX, barY, barZ = getElementPosition(crane["bar2"])
	local ropeX, ropeY, ropeZ = getElementPosition(crane["rope2"])
	local hookX, hookY, hookZ = getElementPosition(crane["hook2"])
	attachElements ( crane["hook2"], crane["rope2"], hookX-ropeX, hookY-ropeY, hookZ-ropeZ )
	attachElements ( crane["rope2"], crane["bar2"], ropeX-barX, ropeY-barY, ropeZ-barZ )
	
	-- done
	CRANE1_STATE = "available"
	CRANE2_STATE = "available"

	setTimer(craneTimerTick, 1000, 0)

	createBlip(99.4, -414.6, 0, 9)
end
addEvent("configureCrane", true)
addEventHandler("configureCrane", resourceRoot, configureCrane)

function craneBoatGrab()
	local vehicle = getPedOccupiedVehicle(localPlayer)
	x1,y1,z1 = getElementPosition(crane["bar1"])
	x2,y2,z2 = getElementPosition(vehicle)
	u1,v1,w1 = getElementRotation(crane["hook1"])
	u2,v2,w2 = getElementRotation(vehicle)
	if (CRANE1_STATE == "boat 0") then
		-- move bar above boat
		CRANE1_STATE = "boat 1"
		local r = findRotation(x1,y1,x2,y2)
		local duration = rotateCraneTo(1, r, nil, 0.25)
		setTimer(function()
			CRANE1_STATE = "boat 2"
		end, duration, 1)
	elseif (CRANE1_STATE == "boat 2") then
		-- move hook into boat
		CRANE1_STATE = "boat 3"
		local d = getDistanceBetweenPoints2D ( x1,y1,x2,y2 )
		local duration = moveHook(1, z2 + HOOK_BOAT_HEIGHT_OFFSET, d)
		setTimer(function()
			CRANE1_STATE = "boat 4"
		end, duration, 1)
	elseif (CRANE1_STATE == "boat 4") then
		-- move hook up with boat
		CRANE1_STATE = "boat 5"
		attachElements(vehicle, crane["rope1"], 0, 0, -HOOK_BOAT_HEIGHT_OFFSET, u2-u1, v2-v1, w2-w1)
		local duration = moveHook(1, 41, 87)
		setTimer(function()
			CRANE1_STATE = "boat 6"
		end, duration, 1)
	elseif (CRANE1_STATE == "boat 6") then
		-- rotate crane with boat
		CRANE1_STATE = "boat 7"
		local duration = rotateCraneTo(1, 94, nil, 0.5)
		setTimer(function()
			CRANE1_STATE = "boat 8"
		end, duration, 1)
	elseif (CRANE1_STATE == "boat 8") then
		-- drop boat
		CRANE1_STATE = "boat 9"
		detachElements(vehicle)
		setTimer(function()
			CRANE1_STATE = "boat 10"
		end, 500, 1)
	end
end

function craneTimerTick()
	
	if (CRANE1_STATE:find("^boat") ~= nil) then
		craneBoatGrab()
		return
	end
	
	local vehicle = getPedOccupiedVehicle(localPlayer)
	local vehicleModel = getElementModel(vehicle)
	if (BOATS[vehicleModel]) then
		if (CRANE1_STATE == "available") then
			CRANE1_STATE = "waiting for boat"
		end
		if (CRANE2_STATE == "available") then
			CRANE2_STATE = "waiting for boat"
		end
		return
	end

	local r = math.random(1,CRANE_TURN_ODDS)
	if (r > 1) then
		return
	end
	if (CRANE1_STATE == "available") then
		-- Crane 1 has free movement
		CRANE1_STATE = "rotating for fun"
		r = math.random(-270,270)
		rotateCraneRelative(1, r)
	elseif (CRANE2_STATE == "available") then
		-- Crane 2 is constrained between 36 - 376
		CRANE2_STATE = "rotating for fun"
		local u,v,w = getElementRotation(crane["bar2"])
		r = math.random(36,376)
		if (w <= 16) then
			r = r - 360
		end
		rotateCraneTo(2, r)
	end
end

function rotateCraneTo(craneID, wDest, time, speedMultiplier)
	local bar
	if (craneID == 1) then
		bar = crane["bar1"]
	elseif (craneID == 2) then
		bar = crane["bar2"]
	else
		return
	end
	local x,y,z = getElementPosition(bar)
	local u,v,w = getElementRotation(bar)
	wDiff = wDest - w
	local duration
	if (time == nil or time < 0) then
		duration = math.abs(wDiff * CRANE_TURN_SPEED)
	else
		duration = time
	end
	if (speedMultiplier ~= nil) then
		duration = duration * speedMultiplier
	end
	moveObject(bar, duration, x, y, z, 0, 0, wDiff, "InOutQuad")
	setTimer(makeCraneAvailable, duration, 1, craneID)
	return duration
	-- local duration = math.abs(wDiff * CRANE_TURN_SPEED)
	-- moveObject(bar, duration, x, y, z, 0, 0, wDiff, "InOutQuad")
	-- setTimer(makeCraneAvailable, duration, 1, craneID)
end

function rotateCraneRelative(craneID, wDiff)
	local bar
	if (craneID == 1) then
		bar = crane["bar1"]
	elseif (craneID == 2) then
		bar = crane["bar2"]
	else
		return
	end
	local x,y,z = getElementPosition(bar)
	local u,v,w = getElementRotation(bar)
	local duration = math.abs(wDiff * CRANE_TURN_SPEED)
	moveObject(bar, duration, x, y, z, 0, 0, wDiff, "InOutQuad")
	setTimer(makeCraneAvailable, duration, 1, craneID)
end

function makeCraneAvailable(craneID)
	if (craneID == 1) then
		if (CRANE1_STATE == "rotating for fun") then
			CRANE1_STATE = "available"
		end
	elseif (craneID == 2) then
		if (CRANE2_STATE == "rotating for fun") then
			CRANE2_STATE = "available"
		end
	end
end

-- attach the hook to the bar after moving it
function attachHook(craneID)
	if (craneID == 1) then
		local barX, barY, barZ = getElementPosition(crane["bar1"])
		local barU, barV, barW = getElementRotation(crane["rope1"])
		local ropeX, ropeY, ropeZ = getElementPosition(crane["rope1"])
		local ropeU, ropeV, ropeW = getElementRotation(crane["rope1"])
		attachElements ( crane["rope1"], crane["bar1"], 0, getDistanceBetweenPoints2D (barX,barY,ropeX,ropeY), ropeZ-barZ )
		CRANE1_STATE = "available"
	elseif (craneID == 2) then
		local barX, barY, barZ = getElementPosition(crane["bar2"])
		local ropeX, ropeY, ropeZ = getElementPosition(crane["rope2"])
		local ropeU, ropeV, ropeW = getElementRotation(crane["rope2"])
		attachElements ( crane["rope2"], crane["bar2"], 0, getDistanceBetweenPoints2D (barX,barY,ropeX,ropeY), ropeZ-barZ )
		CRANE2_STATE = "available"
	end
end

-- raise or lower the hook
function moveHook(craneID, destinationZ, destinationD)
	-- max values for crane 1: Z = 41, D = 89
	-- max values for crane 2: Z = 70.6, D = 89
	-- min D = 5ish
	
	local rope
	local base
	if (craneID == 1) then
		rope = crane["rope1"]
		base = crane["bar1"]
	elseif (craneID == 2) then
		rope = crane["rope2"]
		base = crane["bar2"]
	else
		return
	end
	detachElements(rope)
	u,v,w = getElementRotation(base)
	setElementRotation(rope,u,v,w)

	xBase, yBase, zBase = getElementPosition(base)
	xHook, yHook, zHook = getElementPosition(rope)
	aBar = findRotation( xBase, yBase, xHook, yHook ) 
	dHook = getDistanceBetweenPoints2D ( xBase, yBase, xHook, yHook )
	xNew, yNew = getPointFromDistanceRotation(xBase, yBase, destinationD, aBar)
	
	local zDiff = math.abs(zHook - destinationZ)
	local zDuration = zDiff * CRANE_HOOK_VERTICAL_SPEED
	local dDiff = math.abs(dHook - destinationD)
	local dDuration = dDiff * CRANE_HOOK_HORIZONTAL_SPEED
	
	local duration = math.max(dDuration, zDuration)
	moveObject(rope, duration, xNew, yNew, destinationZ, 0, 0, 0, "InOutQuad")
	setTimer(attachHook, duration, 1, craneID)
	return duration
end

function hookTest(playerSource, commandName)
	moveHook(1, 41, 5)
end
addCommandHandler("hookTest", hookTest)

function hookTest2(playerSource, commandName)
	moveHook(1, 41, 89)
end
addCommandHandler("hookTest2", hookTest2)


function craneGrab(craneID)
	if (craneID == 1) then
		if (CRANE1_STATE == "waiting for boat") then
			CRANE1_STATE = "boat 0"
		end
	end
	-- Move the crane bar above the boat
	-- Move the hook above the boat
	-- Lower hook
	-- Attach boat to hook
	-- Raise hook
	-- Move hook to correct distance from crane base
	-- Turn crane
	-- Drop boat
end
addEvent("craneGrab", true)
addEventHandler("craneGrab", root, craneGrab)

function moveCrane()
	-- get the crane
	-- if (CRANE_STATE ~= "available") then
	-- 	return
	-- end
	CRANE_STATE = "transporting"
	-- crane = {}
	-- crane["bar1"] = getElementByID("_CRANE1_BAR")
	-- crane["bar2"] = getElementByID("_CRANE2_BAR")
	-- crane["hook1"] = getElementByID("_CRANE1_HOOK")
	-- crane["hook2"] = getElementByID("_CRANE2_HOOK")
	-- crane["rope1"] = getElementByID("_CRANE1_ROPE")
	-- crane["rope2"] = getElementByID("_CRANE2_ROPE")

	-- local x, y, z = getElementPosition(crane["hook2"])
	-- local u, v, w = getElementPosition(crane["bar2"])
	-- attachElements ( crane["hook2"], crane["bar2"], x-u, y-v, z-w )
	-- crane["head"] = getElementByID("_CRANE_HEAD")
	-- crane["arm"] = getElementByID("_CRANE_ARM")
	-- crane["magnet"] = getElementByID("_CRANE_MAGNET")
	
	-- move the whole crane by -24.5
	for i,v in pairs(crane) do
		x,y,z = getElementPosition(v)
		moveObject(v, 1000, x, y, z, 0, 0, 180, "InOutQuad")
	end

	-- -- raise the magnet
	-- setTimer(function()
	-- 	x,y,z = getElementPosition(crane["magnet"])
	-- 	moveObject(crane["magnet"], 2000, x, y, z + 15.5, 0, 0, 0, "InOutQuad")
	-- end, 5000, 1)
	
	-- -- rotate stuff (The complicated step) 
	-- setTimer(function()
	-- 	x,y,z = getElementPosition(crane["magnet"])
	-- 	x1,y1,z1 = getElementPosition(crane["arm"])
	-- 	x2,y2,z2 = getElementPosition(crane["head"])
	-- 	moveObject(crane["magnet"], 3000, x + 16.6, y - 5.1, z, 0, 0, 0, "InOutQuad")
	-- 	moveObject(crane["arm"], 3000, x1, y1, z1, -30, 0, 43, "InOutQuad")
	-- 	moveObject(crane["head"], 3000, x2, y2, z2, 0, 0, 43, "InOutQuad")
	-- end, 7000, 1)
	
	-- vehicle = getPedOccupiedVehicle(localPlayer)
	-- setElementFrozen(vehicle, true)
	-- --setCameraClip(false)
	-- magnetTimer = setTimer(function()
	-- 	x,y,z = getElementPosition(crane["magnet"])
	-- 	setElementPosition(vehicle, x, y, z - 2.6)
	-- end, 1, 0)
	-- setTimer(function()
	-- 	setElementFrozen(vehicle, false)
	-- 	killTimer(magnetTimer)
	-- 	CRANE_STATE = "finished"
	-- 	craneDetectFinalCar(localPlayer, nil)
	-- end, 10000, 1)
	-- setTimer(function()
	-- 	--setCameraClip(true)
	-- end, 11000, 1)
end

function craneDetectBoat(element, matchingDimension)
	-- and not in spawn area
	if (element ~= localPlayer) then
		return
	end
	local vehicle = getElementModel(getPedOccupiedVehicle(localPlayer))
	if (not vehicle or not BOATS[vehicle]) then
		return
	end
	if (CRANE1_STATE ~= "waiting for boat") then
		CRANE1_STATE = "waiting for boat"
		iprint("Crane wasn't ready yet")
	end
	rotateCraneTo(1, 200, 20000)
end
addEventHandler("onClientColShapeHit", BOAT_DETECTOR, craneDetectBoat)










function teleportToCraneForFinish()
	vehicle = getPedOccupiedVehicle(localPlayer)
	magnet = getElementByID("_CRANE_MAGNET")
	x,y,z = getElementPosition(magnet)
	setElementFrozen(vehicle, true)
	vehicle = getPedOccupiedVehicle(localPlayer)
	a,b,c,d,e,f = getElementBoundingBox(vehicle)
	aa,bb,cc,dd,ee,ff = getElementBoundingBox(magnet)
	setElementPosition(vehicle, x, y, z - f + aa + 1)
end
addEvent("teleportToCraneForFinish", true)
addEventHandler("teleportToCraneForFinish", resourceRoot, teleportToCraneForFinish)

-- function disableCameraClip()
	-- setCameraClip(true)
-- end
-- addEventHandler( "onClientResourceStop", resourceRoot, disableCameraClip)

TEXT = ""
SHOW = false

function setScoreBoard(scores)
	text = "Top times for the Full Experience:\n_______________________________________\n"
	for i, v in pairs(scores) do
		time_ = v["score"]
	
		milliseconds = time_ % 1000
		seconds = ((time_ - milliseconds) % 60000) / 1000
		minutes = (time_ - milliseconds - (seconds * 1000)) / 60000

		zeroSeconds = ""
		zeroMinutes = ""
		zeroMilliseconds = ""
		if (seconds < 10) then
			zeroSeconds = "0"
		end
		if (minutes < 10) then
			zeroMinutes = "0"
		end
		if (milliseconds < 10) then
			zeroMilliseconds = "00"
		elseif (milliseconds < 100) then
			zeroMilliseconds = "0"
		end
		timeText = zeroMinutes .. minutes .. ":" .. zeroSeconds .. seconds .. "." .. zeroMilliseconds .. milliseconds
		
		zeroPos = ""
		if (i < 10) then
			zeroPos = "0"
		end
		text = text .. zeroPos .. i .. ".   " .. timeText .. "    " .. v["playername"] .. "\n"
	end
	if (#scores < 10) then
		for i = #scores + 1, 10, 1 do
			zeroPos = ""
			if (i < 10) then
				zeroPos = "0"
			end
			text = text .. zeroPos .. i .. ".   -- Empty --\n"
		end
	end
	TEXT = text
end
addEvent("setScoreBoard", true)
addEventHandler("setScoreBoard", root, setScoreBoard)

function showScoreBoardCmd()
	showScoreBoard(true, 15000)
end

function showScoreBoard(enabled, duration)
	SHOW = enabled
	if (duration) then
		setTimer(function()
			SHOW = false
		end, duration, 1)
	end
end
addEvent("showScoreBoard", true)
addEventHandler("showScoreBoard", root, showScoreBoard)
addCommandHandler("showtimes", showScoreBoardCmd)

function drawScoreBoard()
	if (SHOW) then
		local width,height = guiGetScreenSize()
		boxX = width * 0.275
		boxY = height * 0.015
		boxWidth = width * 0.18
		boxHeight = (boxWidth * 0.6875)
		dxDrawRectangle(boxX, boxY, boxWidth, boxHeight, tocolor(5, 33, 51, 127))
		dxDrawText(TEXT, width*0.28, height*0.025, width*0.8, height*0.9, tocolor(230, 245, 255, 255), width / 1600, "default-bold", "left", "top", false, true, false, false)
	end
end
addEventHandler("onClientRender", root, drawScoreBoard)

-- Helper functions

function findRotation( x1, y1, x2, y2 ) 
    local t = -math.deg( math.atan2( x2 - x1, y2 - y1 ) )
    return t < 0 and t + 360 or t
end

function getPointFromDistanceRotation(x, y, dist, angle)
    local a = math.rad(90 - angle);
    local dx = math.cos(a) * dist;
    local dy = math.sin(a) * dist;
    return x-dx, y+dy;
end