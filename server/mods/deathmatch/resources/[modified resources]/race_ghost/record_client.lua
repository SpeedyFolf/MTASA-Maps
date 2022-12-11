GhostRecord = {}
GhostRecord.__index = GhostRecord

addEvent"onClientMapStarting"
addEvent"onClientPlayerOutOfTime"
addEvent( "onClientPlayerPickUpRacePickup", true )
addEvent( "onClientPlayerRaceWasted", true )
addEvent( "onClientPlayerFinished", true )

function GhostRecord:create()
	local result = {
		positionTimer = nil,
		recording = {},
		isRecording = false,
		currentMapName = nil,
		keyStates = {},
		lastPressed = {},
		vehicleType = nil,
		last = {}
	}
	return setmetatable( result, self )
end

function GhostRecord:init( mapName )
	self.currentMapName = mapName
	self.checkForCountdownEnd_HANDLER = function() self:checkForCountdownEnd() end
	addEventHandler( "onClientRender", root, self.checkForCountdownEnd_HANDLER )
	outputDebug( "Waiting for start..." )
end

function GhostRecord:destroy()
	self:stopRecording()
	if self.checkForCountdownEnd_HANDLER then removeEventHandler( "onClientRender", root, self.checkForCountdownEnd_HANDLER ) self.checkForCountdownEnd_HANDLER = nil end
	if self.waitForNewVehicle_HANDLER then removeEventHandler( "onClientRender", root, self.waitForNewVehicle_HANDLER ) self.waitForNewVehicle_HANDLER = nil end
	if self.checkStateChanges_HANDLER then removeEventHandler( "onClientRender", root, self.checkStateChanges_HANDLER ) self.checkStateChanges_HANDLER = nil end
	if self.playerRaceWasted_HANDLER then removeEventHandler( "onClientPlayerRaceWasted", localPlayer, self.playerRaceWasted_HANDLER ) self.playerRaceWasted_HANDLER = nil end
	if self.playerFinished_HANDLER then removeEventHandler( "onClientPlayerFinished", localPlayer, self.playerFinished_HANDLER ) self.playerFinished_HANDLER = nil end
	if self.playerPickUpRacePickup_HANDLER then removeEventHandler( "onClientPlayerPickUpRacePickup", localPlayer, self.playerPickUpRacePickup_HANDLER ) self.playerPickUpRacePickup_HANDLER = nil end
	if self.playerOutOfTime_HANDLER then removeEventHandler( "onClientPlayerOutOfTime", localPlayer, self.playerOutOfTime_HANDLER ) self.playerOutOfTime_HANDLER = nil end
	if isTimer( self.positionTimer ) then
		killTimer( self.positionTimer )
		self.positionTimer = nil
		self.updateExactPosition_HANDLER = nil
	end
	if isTimer( self.flushTimer ) then
		killTimer( self.flushTimer )
	end
	self.flushTimer = nil
	self.timeToSend = nil
	self.currentMapName = self.currentMapName .. "deleted"
end

function GhostRecord:checkForCountdownEnd()
	local vehicle = getPedOccupiedVehicle( localPlayer )
	if vehicle then
		local frozen = isElementFrozen( vehicle )
		if not frozen then
			self.currentVehicleType = getElementModel( vehicle )
			local pedModel = getElementModel( localPlayer )
			local x, y, z = getElementPosition( vehicle )
			local rX, rY, rZ = getElementRotation( vehicle )
			table.insert( self.recording, { ty = "st", m = self.currentVehicleType, p = pedModel, x = x, y = y, z = z, rX = rX, rY = rY, rZ = rZ, t = 0 } )
			if self.checkForCountdownEnd_HANDLER then removeEventHandler( "onClientRender", root, self.checkForCountdownEnd_HANDLER ) self.checkForCountdownEnd_HANDLER = nil end
			self:startRecording()
		end
	else
		local frozen = isElementFrozen( localPlayer ) or getElementData(localPlayer, "race rank") == ""
		if not frozen then
			self.currentVehicleType = false
			local pedModel = getElementModel( localPlayer )
			local x, y, z = getElementPosition( localPlayer )
			local rX, rY, rZ = getElementRotation( localPlayer )
			table.insert( self.recording, { ty = "st", m = self.currentVehicleType, p = pedModel, x = x, y = y, z = z, rX = rX, rY = rY, rZ = rZ, t = 0 } )
			if self.checkForCountdownEnd_HANDLER then removeEventHandler( "onClientRender", root, self.checkForCountdownEnd_HANDLER ) self.checkForCountdownEnd_HANDLER = nil end
			self:startRecording()
		end
	end
end

function GhostRecord:waitForNewVehicle()
	local vehicle = getPedOccupiedVehicle( localPlayer )
	if vehicle then
		local vHealth = getElementHealth( vehicle )
		local pHealth = getElementHealth( localPlayer )
		local frozen = isElementFrozen( vehicle )
		if vHealth > 99 and pHealth > 99 and not frozen then
			local ticks = getTickCount() - self.startTick
			table.insert( self.recording, { ty = "sp", t = ticks } )
			if self.waitForNewVehicle_HANDLER then removeEventHandler( "onClientRender", root, self.waitForNewVehicle_HANDLER ) self.waitForNewVehicle_HANDLER = nil end
			self:resumeRecording()
		end
	end
end

function GhostRecord:startRecording()
	if not self.isRecording then
		outputDebug( "Recording started." )
		self.startTick = getTickCount()
		self:resetKeyStates()
		self.isRecording = true
		self.checkStateChanges_HANDLER = function() self:checkStateChanges() end
		addEventHandler( "onClientRender", root, self.checkStateChanges_HANDLER )
		self.playerRaceWasted_HANDLER = function( ... ) self:playerRaceWasted( ... ) end
		addEventHandler( "onClientPlayerRaceWasted", localPlayer, self.playerRaceWasted_HANDLER )
		self.playerFinished_HANDLER = function( ... ) self:playerFinished( ... ) end
		addEventHandler( "onClientPlayerFinished", localPlayer, self.playerFinished_HANDLER )
		self.playerPickUpRacePickup_HANDLER = function( ... ) self:playerPickUpRacePickup( ... ) end
		addEventHandler( "onClientPlayerPickUpRacePickup", localPlayer, self.playerPickUpRacePickup_HANDLER )
		self.playerOutOfTime_HANDLER = function() self:playerOutOfTime() end
		addEventHandler( "onClientPlayerOutOfTime", localPlayer, self.playerOutOfTime_HANDLER )
		self.updateExactPosition_HANDLER = function() self:updateExactPosition() end
		self.positionTimer = setTimer( self.updateExactPosition_HANDLER, POSITION_PULSE, 0 )
	end
end

function GhostRecord:pauseRecording()
	if self.isRecording then
		outputDebug( "Recording paused." )
		self.isRecording = false
		if self.checkStateChanges_HANDLER then removeEventHandler( "onClientRender", root, self.checkStateChanges_HANDLER ) self.checkStateChanges_HANDLER = nil end
		if isTimer( self.positionTimer ) then
			killTimer( self.positionTimer )
			self.positionTimer = nil
			self.updateExactPosition_HANDLER = nil
		end
		self.waitForNewVehicle_HANDLER = function() self:waitForNewVehicle() end
		addEventHandler( "onClientRender", root, self.waitForNewVehicle_HANDLER )
	end
end

function GhostRecord:resumeRecording()
	if not self.isRecording then
		outputDebug( "Recording resumed." )
		self.isRecording = true
		self:resetKeyStates()
		self.checkStateChanges_HANDLER = function() self:checkStateChanges() end
		addEventHandler( "onClientRender", root, self.checkStateChanges_HANDLER )
		self.updateExactPosition_HANDLER = function() self:updateExactPosition() end
		self.positionTimer = setTimer( self.updateExactPosition_HANDLER, POSITION_PULSE, 0 )
	end
end

function GhostRecord:stopRecording()
	if self.isRecording then
		outputDebug( "Recording finished." )
		self.isRecording = false
		if self.checkForCountdownEnd_HANDLER then removeEventHandler( "onClientRender", root, self.checkForCountdownEnd_HANDLER ) self.checkForCountdownEnd_HANDLER = nil end
		if self.waitForNewVehicle_HANDLER then removeEventHandler( "onClientRender", root, self.waitForNewVehicle_HANDLER ) self.waitForNewVehicle_HANDLER = nil end
		if self.checkStateChanges_HANDLER then removeEventHandler( "onClientRender", root, self.checkStateChanges_HANDLER ) self.checkStateChanges_HANDLER = nil end
		if self.playerRaceWasted_HANDLER then removeEventHandler( "onClientPlayerRaceWasted", localPlayer, self.playerRaceWasted_HANDLER ) self.playerRaceWasted_HANDLER = nil end
		if self.playerFinished_HANDLER then removeEventHandler( "onClientPlayerFinished", localPlayer, self.playerFinished_HANDLER ) self.playerFinished_HANDLER = nil end
		if self.playerPickUpRacePickup_HANDLER then removeEventHandler( "onClientPlayerPickUpRacePickup", localPlayer, self.playerPickUpRacePickup_HANDLER ) self.playerPickUpRacePickup_HANDLER = nil end
		if self.playerOutOfTime_HANDLER then removeEventHandler( "onClientPlayerOutOfTime", localPlayer, self.playerOutOfTime_HANDLER ) self.playerOutOfTime_HANDLER = nil end
		if isTimer( self.positionTimer ) then
			killTimer( self.positionTimer )
			self.positionTimer = nil
			self.updateExactPosition_HANDLER = nil
		end
	end
end

function GhostRecord:saveGhost( rank, time )
	local newTop = time < globalInfo.bestTime and rank == 1
	local newPB = time < globalInfo.personalBest
	if (not newTop and not newPB) then return end -- Don't store if this isn't a PB or WR
	if (not newTop and not g_GameOptions.recordpersonalbests) then return end -- Don't store if recording PBs is disabled
	outputDebug( "Improved ghost time." )
	triggerServerEvent( "onDebug", resourceRoot, "Want to send ghost file", self.currentMapName )
	-- Send the data right away to prevent data loss when a player immediately quits after finishing
	triggerServerEvent( "onGhostDataReceive", localPlayer, self.recording, time, removeColorCoding( getPlayerName( localPlayer ) ), self.currentMapName, newTop, newPB )
end

function GhostRecord:checkStateChanges()
	-- Keys
	for _, v in ipairs( keyNames ) do
		local state = getPedControlState( v )
		if not state and analogNames[v] then
			-- Not a really good implementation, but didn't think if anything else
			state = getAnalogControlState( v ) >= 0.5
		end
		if state ~= self.keyStates[v] then
			local ticks = getTickCount() - self.startTick
			if (state and ticks - (self.lastPressed[v] or 0) >= KEYSPAM_LIMIT) or not state then
				-- Don't record shooting for hydra/hunter/seasparrow/rhino & rcbaron/predator/rustler
				local vehicle = getPedOccupiedVehicle( localPlayer )
				local donotrecord = false
				if isElement( vehicle ) then
					local model = getElementModel( vehicle )
					if (model == 520 or model == 425 or model == 447 or model == 432 or model == 464 or model == 430 or model == 476) and (v == "vehicle_fire" or v == "vehicle_secondary_fire") and state then
						donotrecord = true
					end
				end

				if not donotrecord then
					table.insert( self.recording, { ty = "k", k = v, s = state, t = ticks } )
					self.keyStates[v] = state
					outputDebug( "Key state change: " .. v .. " = " .. tostring( state ) )
					if state then
						self.lastPressed[v] = ticks
					end
				end
			end
		end
	end

	-- Vehicle change
	local vehicle = getPedOccupiedVehicle( localPlayer )
	local vehicleType = self.currentVehicleType
	if vehicle then
		vehicleType = getElementModel( vehicle )
	else
		vehicleType = false
	end
	if self.currentVehicleType ~= vehicleType then
		local ticks = getTickCount() - self.startTick
		table.insert( self.recording, { ty = "v", m = vehicleType, t = ticks } )
		outputDebug( "Vehicle change: " .. (self.currentVehicleType or "none") .. " -> " .. (vehicleType or "none"))
		self.currentVehicleType = vehicleType
	end
end

function GhostRecord:updateExactPosition()
	local vehicle = getPedOccupiedVehicle( localPlayer )
	if isElement( vehicle ) then
		local x, y, z = getElementPosition( vehicle )
		if self.last.x then
			if math.abs( self.last.x - x ) < 0.1 and math.abs( self.last.y - y ) < 0.1 and math.abs( self.last.z - z ) < 0.1 then
				return
			end
		end
		local rX, rY, rZ = getElementRotation( vehicle )
		local vX, vY, vZ = getElementVelocity( vehicle )
		local lg = getVehicleLandingGearDown( vehicle )
		local health = getElementHealth( vehicle )
		local ticks = getTickCount() - self.startTick
		table.insert( self.recording, { ty = "po", x = x, y = y, z = z, rX = rX, rY = rY, rZ = rZ, vX = vX, vY = vY, vZ = vZ, lg = lg, h = health, t = ticks } )
		self.last = { x = x, y = y, z = z }
		outputDebug( "Pos update." )
	elseif not vehicle then
		local x, y, z = getElementPosition( localPlayer )
		if self.last.x then
			if math.abs( self.last.x - x ) < 0.1 and math.abs( self.last.y - y ) < 0.1 and math.abs( self.last.z - z ) < 0.1 then
				return
			end
		end
		local rX, rY, rZ = getElementRotation( localPlayer )
		local vX, vY, vZ = getElementVelocity( localPlayer )
		local lg = false
		local health = getElementHealth( localPlayer )
		local ticks = getTickCount() - self.startTick
		table.insert( self.recording, { ty = "po", x = x, y = y, z = z, rX = rX, rY = rY, rZ = rZ, vX = vX, vY = vY, vZ = vZ, lg = lg, h = health, t = ticks } )
		self.last = { x = x, y = y, z = z }
		outputDebug( "Pos update (on foot)." )
	end
end

function GhostRecord:playerFinished( rank, time )
	self:saveGhost( rank, time )
	self:stopRecording()
end

function GhostRecord:playerOutOfTime()
	self:stopRecording()
end

function GhostRecord:playerRaceWasted( vehicle )
	self:pauseRecording()
end

function GhostRecord:playerPickUpRacePickup( _, pickupType, model )
	if self.isRecording then
		if pickupType == "nitro" then
			local ticks = getTickCount() - self.startTick
			table.insert( self.recording, { ty = "pi", i = "n", t = ticks } )
			outputDebug( "Picked up 'nitro' pickup." )
		elseif pickupType == "repair" then
			local ticks = getTickCount() - self.startTick
			table.insert( self.recording, { ty = "pi", i = "r", t = ticks } )
			outputDebug( "Picked up 'repair' pickup." )
		end
	end
end

function GhostRecord:resetKeyStates()
	for _, v in ipairs( keyNames ) do
		self.keyStates[v] = false
	end
end

addEventHandler( "onClientMapStarting", root,
	function ( mapInfo )
		if recorder then
			recorder:stopRecording()
			recorder:destroy()
			recorder = nil
		end

		-- Check if the map is actually a racing map
		if mapInfo.modename == "Sprint" then
			recorder = GhostRecord:create()
			recorder:init( mapInfo.resname )
		end
	end
)
