GhostPlayback = {}
GhostPlayback.__index = GhostPlayback

addEvent( "onClientGhostDataReceive", true )
addEvent( "clearMapGhost", true )

function GhostPlayback:create( recording, ped, vehicle, racer, time, playbackID )
	local result = {
		ped = nil,
		vehicle = nil,
		blip = nil,
		recording = recording,
		racer = racer,
		time = time,
		isPlaying = false,
		startTick = nil,
		disableCollision = true,
		lastData = {},
		playbackID = playbackID,
		last = nil,
		error2 = nil,
	}

	-- Move this client side so the server doesn't create unused ghost drivers for every player for every player
	result.ped = createPed( ped.p, ped.x, ped.y, ped.z )
	result.vehicle = createVehicle( vehicle.m or 400, vehicle.x, vehicle.y, vehicle.z, vehicle.rx, vehicle.ry, vehicle.rz )
	setElementCollisionsEnabled( result.ped, false )
	setElementCollisionsEnabled( result.vehicle, false )
	if (vehicle.m) then
		warpPedIntoVehicle( result.ped, result.vehicle )
		setElementAlpha( result.vehicle, g_GameOptions.alphavalue or 100 )
	else
		setElementAlpha( result.vehicle, 187 )
	end
	result.blip = createBlipAttachedTo( result.ped, 0, 1, 150, 150, 150, 50 )
	setElementParent( result.blip, result.ped )
	
	setElementFrozen( result.vehicle, true )
	setElementAlpha( result.ped, g_GameOptions.alphavalue or 100 )
	setHeliBladeCollisionsEnabled( result.vehicle, false)
	return setmetatable( result, self )
end

function GhostPlayback:destroy( finished )
	self:stopPlayback( finished )
	if self.checkForCountdownEnd_HANDLER then removeEventHandler( "onClientRender", root, self.checkForCountdownEnd_HANDLER ) self.checkForCountdownEnd_HANDLER = nil end
	if self.updateGhostState_HANDLER then removeEventHandler( "onClientRender", root, self.updateGhostState_HANDLER ) self.updateGhostState_HANDLER = nil end
	if isTimer( self.ghostFinishTimer ) then
		killTimer( self.ghostFinishTimer )
		self.ghostFinishTimer = nil
	end
	destroyElement(self.blip)
	destroyElement(self.ped)
	destroyElement(self.vehicle)
end

function GhostPlayback:preparePlayback()
	self.checkForCountdownEnd_HANDLER = function() self:checkForCountdownEnd() end
	addEventHandler( "onClientRender", root, self.checkForCountdownEnd_HANDLER )
	self:createNametag()
end

function GhostPlayback:createNametag()
	self.nametagInfo = {
		name = "Ghost - " .. self.playbackID .. " (" .. removeColorCoding(self.racer) .. ")",
		time = msToTimeStr( self.time )
	}
	self.drawGhostNametag_HANDLER = function() self:drawGhostNametag( self.nametagInfo ) end
	addEventHandler( "onClientRender", root, self.drawGhostNametag_HANDLER )
end

function GhostPlayback:destroyNametag()
	if self.drawGhostNametag_HANDLER then removeEventHandler( "onClientRender", root, self.drawGhostNametag_HANDLER ) self.drawGhostNametag_HANDLER = nil end
end

function GhostPlayback:checkForCountdownEnd()
	local vehicle = getPedOccupiedVehicle( localPlayer )
	if vehicle then
		local frozen = isElementFrozen( vehicle )
		if not frozen then
			outputDebug( "Playback started." )
			setElementFrozen( self.vehicle, false )
			if self.checkForCountdownEnd_HANDLER then removeEventHandler( "onClientRender", root, self.checkForCountdownEnd_HANDLER ) self.checkForCountdownEnd_HANDLER = nil end
			self:startPlayback()
			setElementAlpha( self.vehicle, g_GameOptions.alphavalue )
			setElementAlpha( self.ped, g_GameOptions.alphavalue )
		end

        -- If at the start and ghost is very close to a player vehicle, make it invisible
		-- This is nonsense. The ghost already is a ghost and making it invisible defeats the purpose of a ghost
		if g_GameOptions.hideatstart and frozen and not self.isPlaying then
			local x, y, z = getElementPosition(self.vehicle)
			for _,player in ipairs(getElementsByType('player')) do
				local plrveh = getPedOccupiedVehicle( player )
				if plrveh then
					local dist = getDistanceBetweenPoints3D(x, y, z, getElementPosition(plrveh))
					if dist < 0.1 then
						setElementAlpha( self.vehicle, 0 )
						setElementAlpha( self.ped, 0 )
						break
					end
				end
			end
		end
	else
		local frozen = isElementFrozen( localPlayer ) or getElementData(localPlayer, "race rank") == ""
		if not frozen then
			outputDebug( "Playback started." )
			setElementFrozen( self.vehicle, false )
			if self.checkForCountdownEnd_HANDLER then removeEventHandler( "onClientRender", root, self.checkForCountdownEnd_HANDLER ) self.checkForCountdownEnd_HANDLER = nil end
			self:startPlayback()
			setElementAlpha( self.vehicle, 187 )
			setElementAlpha( self.ped, g_GameOptions.alphavalue )
		end
	end
end

function GhostPlayback:startPlayback()
	self.startTick = getTickCount()
	self.isPlaying = true
	self.updateGhostState_HANDLER = function() self:updateGhostState() end
	addEventHandler( "onClientRender", root, self.updateGhostState_HANDLER )
end

function GhostPlayback:stopPlayback( finished )
	self:destroyNametag()
	self:resetKeyStates()
	self.isPlaying = false
	if self.updateGhostState_HANDLER then removeEventHandler( "onClientRender", root, self.updateGhostState_HANDLER ) self.updateGhostState_HANDLER = nil end
	if finished then
		self.ghostFinishTimer = setTimer(
			function()
				local blip = getBlipAttachedTo( self.ped )
				if blip then
					setBlipColor( blip, 0, 0, 0, 0 )
				end
				setElementPosition( self.vehicle, 0, 0, 0 )
				setElementFrozen( self.vehicle, true )
				setElementAlpha( self.vehicle, 0 )
				setElementAlpha( self.ped, 0 )
			end, 5000, 1
		)
	end
end

function GhostPlayback:getNextIndexOfType( reqType, start, dir )
	local idx = start
	while (self.recording[idx] and self.recording[idx].ty ~= reqType ) do
		idx = idx + dir
	end
	return self.recording[idx] and idx
end

function GhostPlayback:updateGhostState()
	if not self.currentIndex then
		Interpolator.Reset(self)
	end
	self.currentIndex = self.currentIndex or 1
	local ticks = getTickCount() - self.startTick
	setElementHealth( self.ped, 100 ) -- we don't want the ped to die
	while (self.recording[self.currentIndex] and self.recording[self.currentIndex].t < ticks) do
		local theType = self.recording[self.currentIndex].ty
		-- if theType == "st" then
		--	-- Skip
		if theType == "po" then
			local x, y, z = self.recording[self.currentIndex].x, self.recording[self.currentIndex].y, self.recording[self.currentIndex].z
			local rX, rY, rZ = self.recording[self.currentIndex].rX, self.recording[self.currentIndex].rY, self.recording[self.currentIndex].rZ
			local vX, vY, vZ = self.recording[self.currentIndex].vX, self.recording[self.currentIndex].vY, self.recording[self.currentIndex].vZ
			-- Interpolate with next position depending on current time
			local idx = self:getNextIndexOfType( "po", self.currentIndex + 1, 1 )
			local period = nil
			if idx then
				local other = self.recording[idx]
				local alpha = math.unlerp( self.recording[self.currentIndex].t, other.t, ticks )
				period = other.t - ticks
				x = math.lerp( x, other.x, alpha )
				y = math.lerp( y, other.y, alpha )
				z = math.lerp( z, other.z, alpha )
				vX = math.lerp( vX, other.vX, alpha )
				vY = math.lerp( vY, other.vY, alpha )
				vZ = math.lerp( vZ, other.vZ, alpha )
				Interpolator.SetPoints( self, self.recording[self.currentIndex], other )
			else
				Interpolator.Reset(self)
			end
			local lg = self.recording[self.currentIndex].lg
			local health = self.recording[self.currentIndex].h or 1000
			if self.disableCollision then
				health = 1000
				self.lastData.vZ = vZ
				self.lastData.time = getTickCount()
			end
			if (getPedOccupiedVehicle(self.ped)) then
				ErrorCompensator.handleNewPosition( self, self.vehicle, x, y, z, period )
				setElementRotation( self.vehicle, rX, rY, rZ )
				setElementVelocity( self.vehicle, vX, vY, vZ )
				setElementHealth( self.vehicle, health )
				if lg then setVehicleLandingGearDown( self.vehicle, lg ) end
			else
				-- ErrorCompensator.handleNewPosition( self, self.ped, x, y, z, period )
				setElementRotation( self.ped, rX, rY, rZ )
				setElementVelocity( self.ped, vX, vY, vZ )
				setElementHealth( self.ped, health )
			end
		elseif theType == "k" then
			local control = self.recording[self.currentIndex].k
			local state = self.recording[self.currentIndex].s
			setPedControlState( self.ped, control, state )
		elseif theType == "pi" then
			local item = self.recording[self.currentIndex].i
			if item == "n" then
				addVehicleUpgrade( self.vehicle, 1010 )
			elseif item == "r" then
				fixVehicle( self.vehicle )
			end
		elseif theType == "sp" then
			fixVehicle( self.vehicle )
			-- Respawn clears the control states
			for _, v in ipairs( keyNames ) do
				setPedControlState( self.ped, v, false )
			end
			setPedAnimation( self.ped )
		elseif theType == "v" then
			local vehicleType = self.recording[self.currentIndex].m
			if vehicleType then
				setElementAlpha( self.vehicle, g_GameOptions.alphavalue )
				setElementModel( self.vehicle, vehicleType )
				if (not getPedOccupiedVehicle(self.ped)) then
					warpPedIntoVehicle( self.ped, self.vehicle )
				end
			else
				removePedFromVehicle( self.ped )
			end
		end
		self.currentIndex = self.currentIndex + 1

		if not self.recording[self.currentIndex] then
			self:stopPlayback( true )
			self.fadeoutStart = getTickCount()
		end
	end
	if (getPedOccupiedVehicle(self.ped)) then
		ErrorCompensator.updatePosition( self, self.vehicle )
	end
	Interpolator.Update( self, ticks, self.vehicle )
end

function GhostPlayback:resetKeyStates()
	if isElement( self.ped ) then
		for _, v in ipairs( keyNames ) do
			setPedControlState( self.ped, v, false )
		end
	end
end

addEventHandler( "onClientGhostDataReceive", root,
	function( recording, time, racer, ped, vehicle, playbackID )
		if not playbackID then playbackID = "top" end

		if not playbacks then playbacks = {} end
		if playbacks[playbackID] then
			playbacks[playbackID]:destroy()
			playbacks[playbackID] = nil
		end
		
		if (playbackID == "top") then
			globalInfo.bestTime = time
			globalInfo.racer = racer
		elseif (playbackID == "pb") then
			globalInfo.personalBest = time
		end

		playbacks[playbackID] = GhostPlayback:create( recording, ped, vehicle, racer, time, playbackID )
		playbacks[playbackID]:preparePlayback()
	end
)

addEventHandler( "clearMapGhost", root,
	function()
		if playbacks then
			for i, v in pairs(playbacks) do
				v:destroy()
				v = nil
			end
			playbacks = {}
			globalInfo.bestTime = math.huge
			globalInfo.racer = ""
			globalInfo.personalBest = math.huge
		end
	end
)

function getBlipAttachedTo( elem )
	local elements = getAttachedElements( elem )
	for _, element in ipairs( elements ) do
		if getElementType( element ) == "blip" then
			return element
		end
	end
	return false
end


--------------------------------------------------------------------------
--Interpolator
--------------------------------------------------------------------------
Interpolator = {}
last = {}

function Interpolator.Reset(playback)
	if not playback.last then playback.last = { } end
	playback.last.from = nil
	playback.last.to = nil
end

function Interpolator.SetPoints( playback, from, to )
	-- if not getPedOccupiedVehicle(playback.ped) then return end
	if not playback.last then playback.last = { } end
	playback.last.from = from
	playback.last.to = to
end

function Interpolator.Update( playback, ticks, vehicle )
	if not playback.last then playback.last = { } end
	if not playback.last.from or not playback.last.to then return end
	local z,rX,rY,rZ
	local alpha = math.unlerp( playback.last.from.t, playback.last.to.t, ticks )
	x = math.lerp( playback.last.from.x, playback.last.to.x, alpha )
	y = math.lerp( playback.last.from.y, playback.last.to.y, alpha )
	z = math.lerp( playback.last.from.z, playback.last.to.z, alpha )
	rX = math.lerprot( playback.last.from.rX, playback.last.to.rX, alpha )
	rY = math.lerprot( playback.last.from.rY, playback.last.to.rY, alpha )
	rZ = math.lerprot( playback.last.from.rZ, playback.last.to.rZ, alpha )
	if getPedOccupiedVehicle(playback.ped) then 
		local ox,oy,oz = getElementPosition( vehicle )
		setElementPosition( vehicle, ox, oy, math.max( oz, z ) )
		setElementRotation( vehicle, rX, rY, rZ )
	else
		local ox,oy,oz = getElementPosition( playback.ped )
		setElementPosition( playback.ped, x, y, z )
		setElementRotation( playback.ped, rX, rY, rZ )
	end
end

--------------------------------------------------------------------------
-- Error Compensator
--------------------------------------------------------------------------
ErrorCompensator = {}
-- error2 = { timeEnd = 0 }
error2 = {}

function ErrorCompensator.handleNewPosition( playback, vehicle, x, y, z, period )
	if not playback.error then playback.error = { timeEnd = 0 } end

	local vx, vy, vz = getElementPosition( vehicle )
	-- Check if the distance to interpolate is too far.
	local dist = getDistanceBetweenPoints3D( x, y, z, vx, vy, vz )
	if dist > 5 or not period then
		-- Just do move if too far to interpolate or period is not valid
		setElementPosition( vehicle, x, y, z )
		playback.error.x = 0
		playback.error.y = 0
		playback.error.z = 0
		playback.error.timeStart = 0
		playback.error.timeEnd = 0
		playback.error.fLastAlpha = 0
	else
		-- Set error correction to apply over the next few frames
		playback.error.x = x - vx
		playback.error.y = y - vy
		playback.error.z = z - vz
		playback.error.timeStart = getTickCount()
		playback.error.timeEnd = playback.error.timeStart + period * 1.0
		playback.error.fLastAlpha = 0
	end
end


-- Apply a portion of the error
function ErrorCompensator.updatePosition( playback, vehicle )
	
	if not playback.error then playback.error = { timeEnd = 0 } end
	
	if playback.error.timeEnd == 0 then return end

	-- Grab the current game position
	local vx, vy, vz = getElementPosition( vehicle )

	-- Get the factor of time spent from the interpolation start to the current time.
	local fAlpha = math.unlerp ( playback.error.timeStart, playback.error.timeEnd, getTickCount() )

	-- Don't let it overcompensate the error too much
	fAlpha = math.clamp ( 0.0, fAlpha, 1.5 )

	if fAlpha == 1.5 then
		playback.error.timeEnd = 0
		return
	end

	-- Get the current error portion to compensate
	local fCurrentAlpha = fAlpha - playback.error.fLastAlpha
	playback.error.fLastAlpha = fAlpha

	-- Apply
	local nx = vx + playback.error.x * fCurrentAlpha
	local ny = vy + playback.error.y * fCurrentAlpha
	local nz = vz + playback.error.z * fCurrentAlpha
	setElementPosition( vehicle, nx, ny, nz )
end


--------------------------------------------------------------------------
-- Update admin changing options
--------------------------------------------------------------------------
function GhostPlayback:onUpdateOptions()
	if isElement( self.vehicle ) and isElement( self.ped ) then
		setElementAlpha( self.vehicle, g_GameOptions.alphavalue )
		setElementAlpha( self.ped, g_GameOptions.alphavalue )
	end
end


--------------------------------------------------------------------------
-- Fade out ghost at end of race
--------------------------------------------------------------------------
addEventHandler('onClientPreRender', root,
	function()
		
		if (not playbacks) then return end
		for i, playback in pairs(playbacks) do
			if playback and playback.fadeoutStart and isElement( playback.vehicle ) and isElement( playback.ped ) then
				playback:updateFadeout()
			end
		end
	end
)

function GhostPlayback:updateFadeout()
	local alpha = math.unlerp( self.fadeoutStart+2000, self.fadeoutStart+500, getTickCount() )
	if alpha > -1 and alpha < 1 then
		alpha = math.clamp( 0, alpha, 1 )
		setElementAlpha( self.vehicle, alpha * g_GameOptions.alphavalue )
		setElementAlpha( self.ped, alpha * g_GameOptions.alphavalue )
	end
end


--------------------------------------------------------------------------
-- Counter side effects of having collisions disabled
--------------------------------------------------------------------------
addEventHandler('onClientPreRender', root,
	function()

		if (not playbacks) then return end
		for i, playback in pairs(playbacks) do
			if playback and playback.disableCollision and isElement( playback.vehicle ) and isElement( playback.ped ) then
				playback:disabledCollisionTick()
			end
		end
	end
)


local dampCurve = { { 0, 1 }, { 200, 1 }, { 15000, 0 } }

function GhostPlayback:disabledCollisionTick()
	setVehicleDamageProof( self.vehicle, true ) -- we don't want the vehicle to explode
	setElementCollisionsEnabled( self.ped, false )
	setElementCollisionsEnabled( self.vehicle, false  )
	
	if not getPedOccupiedVehicle(self.ped) then return end
	
	-- Slow down everything when its been more than 200ms since the last position change
	local timeSincePos = getTickCount() - ( self.lastData.time or 0 )
	local damp = math.evalCurve( dampCurve, timeSincePos )

	-- Stop air floating
	local vx, vy, vz = getElementVelocity ( self.vehicle )
	if vz < -0.01 then
		damp = 1	-- Always allow falling
		self.lastData.time = getTickCount()
	end
	vz = self.lastData.vZ or vz
	vx = vx * 0.999 * damp
	vy = vy * 0.999 * damp
	vz = vz * damp
	if vz > 0 then
		vz = vz * 0.999
	end
	if vz > 0 and getDistanceBetweenPoints2D(0, 0, vx, vy) < 0.001 then
		vz = 0
	end
	if self.lastData.vZ then
		self.lastData.vZ = vz
	end
	setElementVelocity( self.vehicle, vx, vy, vz  )

	-- Stop crazy spinning
	local vehicle = self.vehicle
	local ax, ay, az = getElementAngularVelocity ( self.vehicle )
	local angvel = getDistanceBetweenPoints3D(0, 0, 0, ax, ay, az )
	if angvel > 0.1 then
		ax = ax / 2
		ay = ay / 2
		az = az / 2
		setElementAngularVelocity( self.vehicle, ax, ay, az )
	end
end

