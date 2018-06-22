local addonInfo, private = ...
local kAlert = private.kAlert
local kUtils = private.kUtils
local kAlertTexts = private.kAlertTexts

local function logmsg(...)
	if kAlert.debug then print(string.format(...)) end
end

local function subscribeResourceEvents(resourceList)
	kUtils.attachEventEx(Event.Unit.Detail.Health, kAlert.changeHandler.resHealthChanged, "healthChanged", resourceList[1])
	kUtils.attachEventEx(Event.Unit.Detail.Mana, kAlert.changeHandler.resManaChanged, "manaChanged", resourceList[2])
	kUtils.attachEventEx(Event.Unit.Detail.Energy, kAlert.changeHandler.resEnergyChanged, "energyChanged", resourceList[3])
	kUtils.attachEventEx(Event.Unit.Detail.Power, kAlert.changeHandler.resPowerChanged, "powerChanged", resourceList[4])
	kUtils.attachEventEx(Event.Unit.Detail.Charge, kAlert.changeHandler.resChargeChanged, "chargeChanged", resourceList[5])
	kUtils.attachEventEx(Event.Unit.Detail.Combo, kAlert.changeHandler.resComboChanged, "comboChanged", resourceList[6])
	kUtils.attachEventEx(Event.Unit.Detail.Planar, kAlert.changeHandler.resPlanarChanged, "planarChanged", resourceList[7])
	
	kUtils.attachEventEx(Event.Unit.Detail.HealthMax, kAlert.changeHandler.resMaxChanged, "maxChanged", resourceList[1])
	kUtils.attachEventEx(Event.Unit.Detail.ManaMax, kAlert.changeHandler.resMaxChanged, "maxChanged", resourceList[2])
	kUtils.attachEventEx(Event.Unit.Detail.EnergyMax, kAlert.changeHandler.resMaxChanged, "maxChanged", resourceList[3])
	kUtils.attachEventEx(Event.Unit.Detail.PlanarMax, kAlert.changeHandler.resMaxChanged, "maxChanged", resourceList[7])
end

local function subscribeAbilityEvents(subscribe)
	kUtils.attachEventEx(Event.Ability.New.Cooldown.Begin, kAlert.changeHandler.abilityCooldownChanged, "cooldownBegin", subscribe)
	kUtils.attachEventEx(Event.Ability.New.Cooldown.End, kAlert.changeHandler.abilityCooldownChanged, "cooldownEnd", subscribe)
	kUtils.attachEventEx(Event.Ability.New.Usable.False, kAlert.changeHandler.abilityUsableChanged, "unusableFalse", subscribe)
	kUtils.attachEventEx(Event.Ability.New.Usable.True, kAlert.changeHandler.abilityUsableChanged, "unusableTrue", subscribe)
	kUtils.attachEventEx(Event.Ability.New.Add, kAlert.changeHandler.abilityUsableChanged, "abilityAdd", subscribe)
	kUtils.attachEventEx(Event.Ability.New.Remove, kAlert.changeHandler.abilityUsableChanged, "abilityRemove", subscribe)
end

local function subscribeBuffEvents(subscribe)
	kUtils.attachEventEx(Event.Buff.Add, kAlert.changeHandler.buffsAdded, "buffsAdded", subscribe)
	kUtils.attachEventEx(Event.Buff.Remove, kAlert.changeHandler.buffsRemoved, "buffsRemoved", subscribe)
	kUtils.attachEventEx(Event.Buff.Change, kAlert.changeHandler.buffsChanged, "buffsChanged", subscribe)
end

local function updateBuffInGlobalItems(details)
	-- Passive buff discovery. Add new buffs and buff that require updating to kAlertGlobalItems.
	if kAlertGlobalItems[details.name] == nil or kAlertGlobalItems[details.name].update then
		kAlertGlobalItems[details.name] = {ability = details.abilityNew, name = details.name, icon = details.icon, update = false}
		if kAlert.systemScanner.activeScanning then
			print(string.format(kAlertTexts.msgNewBuff, details.name))
		else
			logmsg(kAlertTexts.msgNewBuff, details.name)
		end
	end
end

function kAlert.cache.unitState:updateUnits(unitsToUpdate)
	local relationChanges = false
	
	for key, value in pairs(unitsToUpdate) do
		local unit
		if string.sub(key, 1, 1) ~= "u" then
			unit = value
		else
			unit = key
		end
		
		local unitDetail = Inspect.Unit.Detail(unit)
		if unitDetail ~= nil then
			local oldState = self[unit]
			local relation = kAlert.unitRelation[unitDetail.relation] or 0
			local live = (unitDetail.health and unitDetail.health > 0)
			
			if oldState == nil then
				self[unit] = {relation = relation, live = live}
				relationChanges = true
			else
				if live ~= oldState.live then
					oldState.live = live
					-- Only buff alerts care if a unit is alive or not
					kAlert.changeHandler.buffChanged = true
				end
				if oldState.relation ~= relation then
					oldState.relation = relation
					relationChanges = true
				end
			end
		else
			if self[unit] ~= nil then
				relationChanges = true
			end
			self[unit] = nil
		end
	end
	
	if relationChanges then
		kAlert.changeHandler.buffChanged = true
		kAlert.changeHandler.resourceChanged = true
		kAlert.changeHandler.castingChanged = true					
	end	
end

function kAlert.cache.unitState:updateNeutralUnits()
	local neutralUnits = nil
	for unitId, state in pairs(self) do
		if type(state) == "table" and state.relation == 0 then
			neutralUnits = neutralUnits or {}
			neutralUnits[unitId] = unitId
		end
	end
	
	if neutralUnits then
		self:updateUnits(neutralUnits)
	end
end

function kAlert.cache.buffs:addBuff(unitId, details)
	local cache = self[unitId]
	local buffEntry
	local durationRounded
	if details.remaining == nil then
		buffEntry = {expires = 0, stacks = details.stack or 1, caster = details.caster}
		durationRounded = "0"
	else
		buffEntry = {expires = details.begin + details.duration, stacks = details.stack or 1, caster = details.caster}
		durationRounded = tostring(math.floor(details.duration + 0.5))
	end
	
	local names = {}
	names[details.name] = true
	names[details.name .. durationRounded] = true
	if details.caster == kAlert.unitSpecs.player then
		names[details.name .. "S"] = true
		names[details.name .. durationRounded .. "S"] = true
	end			
	
	cache.byId[details.id] = { names = names, entry = buffEntry }
	for name, _ in pairs(names) do
		cache.byName[name] = buffEntry
	end
	
	kAlert.changeHandler.buffChanged = true
end

function kAlert.cache.buffs:updateBuff(unitId, details)
	local buffById = self[unitId].byId[details.id]
	if buffById == nil then	return false end
	
	local buffEntry = buffById.entry
	-- Note that updating duration is currently not supported
	buffEntry.expires = details.remaining and (details.begin + details.duration) or 0
	buffEntry.stacks = details.stack or 1

	return true
end

function kAlert.cache.buffs:initializeUnitTask(unitId)
	local buffs = Inspect.Buff.List(unitId)
	if buffs == nil then return end
	
	for buffId, _ in pairs(buffs) do
		-- Handle case where the unit is removed from the cache before this task is finished executing
		if self[unitId] == nil then return end
		
		local buffDetail = Inspect.Buff.Detail(unitId, buffId)
		if buffDetail ~= nil then
			updateBuffInGlobalItems(buffDetail)
			if kAlert.screenObjects.buffList[buffDetail.name] then
				self:addBuff(unitId, buffDetail)
			end
		end
		kUtils.taskYield("initializeUnitTask")
	end
end

function kAlert.cache.buffs:initializeUnit(unitId)
	self[unitId] = 
	{
		byId = {},
		byName = {}
	}

	if not kAlert.unitAvailability[unitId] then
		logmsg("initializeUnitBuffs: Unit unavailable!")
		kAlert.cache.buffsPending[unitId] = true
		return
	end

	-- Querying all buffs was giving performance warnings on some systems, so use a coroutine
	-- Event.Buff.Add, Event.Buff.Remove and Event.Buff.Change events occurring in the mean time
	-- should not cause problems due to way they are implemented.
	kUtils.queueTaskWithParams(kAlert.cache.buffs.initializeUnitTask, {self, unitId})
end

-- Helper function for use of LibUnitChange, adding the unit specifier to the parameters
local function registerUnitChange(unitSpec, func, addonIdentifier, text)
	local eventTable = Library.LibUnitChange.Register(unitSpec)
	local function handler(unitId)
		func(unitSpec, unitId)
	end
	
	kUtils.subscribeEvent(eventTable, handler, addonIdentifier, text)
end

local function unregisterUnitChange(unitSpec, addonIdentifier, text)
	local eventTable = Event.LibUnitChange[unitSpec]
	if eventTable then
		kUtils.unsubscribeEvent(eventTable.Change, addonIdentifier, text)
	end
end

function kAlert.main()
	Command.Event.Attach(Event.Addon.SavedVariables.Load.End, kAlert.settingsHandler, "variablesLoaded")
	
	Command.Event.Attach(Event.Unit.Availability.Full, kAlert.playerAvailableHandler, "playerAvailable")
	
	Command.Event.Attach(Event.Unit.Availability.None, kAlert.changeHandler.unitAvailabilityNone, "availabilityNone")
	Command.Event.Attach(Event.Unit.Availability.Partial, kAlert.changeHandler.unitAvailabilityPartial, "availabilityPartial")
	Command.Event.Attach(Event.Unit.Availability.Full, kAlert.changeHandler.unitAvailabilityFull, "availabilityFull")
	
	Command.Event.Attach(Event.Unit.Detail.Name, kAlert.changeHandler.unitName, "unitName")

	table.insert(Command.Slash.Register("KAlert"), {kAlert.commandHandler, "kAlert", "config"})
	table.insert(Command.Slash.Register("KaruulAlert"), {kAlert.commandHandler, "kAlert", "config"})

	Command.Event.Attach(Event.System.Secure.Enter, kAlert.changeHandler.secureEnter, "enterCombat")
	Command.Event.Attach(Event.System.Secure.Leave, kAlert.changeHandler.secureLeave, "exitCombat")

	Command.Event.Attach(Event.Unit.Castbar, kAlert.changeHandler.checkCasting, "castDetected")
	
	if Event.TEMPORARY and Event.TEMPORARY.Role then
		Command.Event.Attach(Event.TEMPORARY.Role, kAlert.changeHandler.roleChanged, "roleChanged")
	end
end

function kAlert.effectiveAlertSet(role)
	if kAlertSet == "auto" then
		return role or Inspect.TEMPORARY.Role()
	else
		return kAlertSet
	end
end

-- Checks if the alert set is a currently active set or subset
function kAlert.isAlertSetActive(alertSet)
	return
		(alertSet.setsTable == kAlertAlerts.sets and kAlert.alertSet.active == alertSet.active) or
		(alertSet.setsTable == kAlertAlerts.subSets and kAlertSubset == alertSet.active)
end

function kAlert.effectiveUnit(alert)
	local unitId = kAlert.unitSpecs[alert.unit]

	if kAlert.cache.unitState[unitId] == nil then
		return nil
	elseif alert.unitRelation ~= 0 and alert.unitRelation ~= kAlert.cache.unitState[unitId].relation then
		local totUnitId = kAlert.unitSpecs["player.target.target"]
		if totUnitId and alert.unit == "player.target" and kAlert.cache.unitState[totUnitId] ~= nil and kAlert.cache.unitState[totUnitId].relation == alert.unitRelation then
			unitId = totUnitId
		else
			return nil
		end
	end
	
	if alert.type == 1 and not kAlert.cache.unitState[unitId].live then
		return nil
	else
		return unitId
	end
end

function kAlert.commandHandler(commandline)
	
	if string.len(commandline) == 0 then
		kAlert.screenObjects.hide()
		kAlert.config.main()
	else
		local key, value = string.match(commandline,"(%a+)=(%w+)")
		if key == "subset" then
			local setNumber = tonumber(value)
			if setNumber >= 0 and setNumber <= 10 then
				kAlertSubSet = setNumber
				kAlert.alertSubSet:Load(kAlertSubSet)
				kAlert.screenObjects:refresh()
			end
			kAlert.printActiveSets()
		elseif key == "set" then
			local setNumber = tonumber(value)
			if setNumber and setNumber >= 1 and setNumber <= kAlert.rolesMax then
				kAlertSet = setNumber
				kAlert.alertSet:Load(kAlertSet)
				kAlert.screenObjects:refresh()
			elseif value == "auto" then
				kAlertSet = value
				kAlert.alertSet:Load(kAlert.effectiveAlertSet())
				kAlert.screenObjects:refresh()
			end
			kAlert.printActiveSets()
		elseif string.match(commandline, "config") == "config" then
			kAlert.config.generalConfiguration()
		elseif string.match(commandline, "help") == "help" then
			kAlert.config.help()
		elseif string.match(commandline, "tutorial") == "tutorial" then
			kAlert.gettingStarted(false)
		elseif string.match(commandline, "debug") == "debug" then
			kAlert.debug = not kAlert.debug
			if kAlert.debug then
				print("Debug ON")
			else
				print("Debug OFF")
			end
		elseif string.match(commandline, "profile") == "profile" then
			if not Library or not Library.LibPerfORate then
				print("LibPerfORate is required for profiling.")
			else
				local perf = Library.LibPerfORate
				if not kAlert.profiling then
					kAlert.profiling = true
					kAlert.processAbilities = perf.hook(kAlert.processAbilities, "kAlert.processAbilities")
					kAlert.processBuffs = perf.hook(kAlert.processBuffs, "kAlert.processBuffs")
					kAlert.processCasting = perf.hook(kAlert.processCasting, "kAlert.processCasting")
					kAlert.processResources = perf.hook(kAlert.processResources, "kAlert.processResources")
					
					kAlert.changeHandler.resHealthChanged =  perf.hook(kAlert.changeHandler.resHealthChanged, "kAlert.changeHandler.resHealthChanged")
					kAlert.changeHandler.resManaChanged =  perf.hook(kAlert.changeHandler.resManaChanged, "kAlert.changeHandler.resManaChanged")
					kAlert.changeHandler.resEnergyChanged =  perf.hook(kAlert.changeHandler.resEnergyChanged, "kAlert.changeHandler.resEnergyChanged")
					kAlert.changeHandler.resPowerChanged =  perf.hook(kAlert.changeHandler.resPowerChanged, "kAlert.changeHandler.resPowerChanged")
					kAlert.changeHandler.resChargeChanged =  perf.hook(kAlert.changeHandler.resChargeChanged, "kAlert.changeHandler.resChargeChanged")
					kAlert.changeHandler.resComboChanged =  perf.hook(kAlert.changeHandler.resComboChanged, "kAlert.changeHandler.resComboChanged")
					
					kAlert.changeHandler.buffsAdded = perf.hook(kAlert.changeHandler.buffsAdded, "kAlert.changeHandler.buffsAdded")
					kAlert.changeHandler.buffsRemoved = perf.hook(kAlert.changeHandler.buffsRemoved, "kAlert.changeHandler.buffsRemoved")
					kAlert.changeHandler.buffsChanged = perf.hook(kAlert.changeHandler.buffsChanged, "kAlert.changeHandler.buffsChanged")
					
					Command.Event.Detach(Event.System.Update.Begin, nil, "eventHandler", nil, addonInfo.identifier)
					Command.Event.Attach(Event.System.Update.Begin, perf.hook(kAlert.eventHandler, "kAlert.eventHandler"), "eventHandler")
					
					subscribeResourceEvents(kAlert.screenObjects.resourceList)
					subscribeAbilityEvents(true)
					subscribeBuffEvents(true)
				else
					print("\nProfiling is already enabled. Reload the UI to stop profiling.")
				    for k, v in kUtils.pairsByKeys(perf.timers) do
				    	if string.prefix(k, "kAlert") then
				    		perf.showstate(k)
				    	end
    				end
				end
			end
		else
			print("Karuul Alert Commands")
			print("Usage: /KaruulAlert {command}")
			print("Commands:")
			print("set={number|auto} - to change current alert set")
			print("subset={number} - to change current alert sub set")
			print("config - to open the general configuration dialog")
			print("help - to display addon help file")
			print("tutorial - to restart the tutorial for new users")
		end
	end
	
end

function kAlert.settingsHandler(handle, identifier)
	if identifier ~= "kAlert" then return end
	
	local tutorial = false

	if kAlertVersion == nil then
		kAlertVersion = 1.00
	end
	
	if kAlertGlobalVersion == nil then
		kAlertGlobalVersion = 1.00
	end
	
	if kAlertSet == nil then
		kAlertSet = 1
	elseif kAlertSet == "auto" and (Inspect.TEMPORARY == nil or Inspect.TEMPORARY.Role == nil) then
		kAlertSet = 1
	end
	
	if kAlertSubSet == nil then
		kAlertSubSet = 0
	end
	
	if kAlertAlerts == nil then
		kAlertAlerts = {}
		tutorial = true
	end
	
	if kAlertGlobalItems == nil then
		kAlertGlobalItems = {}
	end
	
	if kAlertGlobalSettings == nil then
		kAlertGlobalSettings =
		{
			textTextEffects = 0,
			counterTextEffects = 0,
			yieldThreshold = 0.03
		}
	else
		if kAlertGlobalSettings.textTextEffects == nil then
			kAlertGlobalSettings.textTextEffects = kAlertGlobalSettings.counterTextEffects
		end
	end
	
	if tutorial then
		kAlert.gettingStarted(true)
	end
end

function kAlert.initializationHandler(handle)
	kUtils.runTasks()
end

function kAlert.eventHandler(handle)
	kUtils.queueTask(function()
		local scanTime = Inspect.Time.Frame()
		if kAlert.systemScanner.nextScan < scanTime then
			kAlert.systemScanner.nextScan = scanTime + 0.1

			-- We need to poll for changes to unit relation, because there is currently no event for this
			kAlert.cache.unitState:updateNeutralUnits()
	
			if not kAlert.config.active then
				for id, details in pairs(kAlert.screenObjects.object) do
					if details.timerEnd > 0 then
						local remaining = details.timerEnd - scanTime
						details.setTimer(remaining)
						if details.type == 1 then -- Buff Timer
							if remaining < details.timerLength and details.timer and not details.typeToggle then details:SetVisible(true) end
						elseif details.type == 2 then -- Ability Timer
							if remaining < details.timerLength and details.timer and details.typeToggle then details:SetVisible(true) end
						end
					end
				end
				if kAlert.changeHandler.buffChanged then
					kAlert.processBuffs()
					kUtils.taskYield("processBuffs")
				end
				if kAlert.changeHandler.abilityChanged then
					kAlert.processAbilities()
					kUtils.taskYield("processAbilities")
				end
				if kAlert.changeHandler.resourceChanged then
					kAlert.processResources()
					kUtils.taskYield("processResources")
				end
				if kAlert.changeHandler.castingChanged then
					kAlert.processCasting()
					kUtils.taskYield("processCasting")
				end
			end
		end
	end, kAlert.debug and kAlert.profiling, "eventHandler")
	
	if not kAlert.combat and table.getn(kAlert.sharedAlerts) > 0 then
		kAlert.config.sharedAlert()
	end
	
	kUtils.runTasks()
end

function kAlert.printActiveSets()
	if kAlertSet == "auto" then
		print("Set=" .. tostring(kAlert.alertSet.active) .. " (" .. tostring(kAlertSet) .. "), Sub Set=" .. tostring(kAlertSubSet))
	else
		print("Set=" .. tostring(kAlert.alertSet.active) .. ", Sub Set=" .. tostring(kAlertSubSet))
	end
end

function kAlert.convertAbilityId(id)
	if string.len(id) == 17 and string.sub(id, 1, 1) == "A" then
		return id, true
	elseif string.sub(id, 1, 9) == "a00000000" then
	    -- Update ability to new Rift 1.9 ID
	    local ability = Inspect.Ability.New.Detail(id)
	    if ability and ability.idNew then
	    	return ability.idNew, true
	    else
	    	logmsg("Unable to convert ability ID: " .. id)
	    	return id, false
	    end
	else
		logmsg("Invalid ability ID: " .. id)
		return id, false
	end
end

local function validateAlert(details)
	return
		(type(details.type) == "number") and
		(type(details.active) == "boolean") and
		(type(details.combatOnly) == "boolean") and
		(type(details.image) == "string") and
		(type(details.imageHeight) == "number") and
		(type(details.imageOpacity) == "number" and details.imageOpacity >= 0 and details.imageOpacity <= 1) and
		(type(details.imageScale) == "number") and
		(type(details.imageSource) == "string") and
		(type(details.imageWidth) == "number") and
		(type(details.imageX) == "number") and
		(type(details.imageY) == "number") and
		(type(details.interruptibleCast) == "boolean" or details.type ~= 4) and
		((type(details.itemId) == "string" and details.type ~= 3) or (type(details.itemId) == "number" and details.type == 3) or (details.itemId == nil and details.type == 4)) and
		(type(details.itemLength) == "number") and
		(type(details.itemName) == "string") and
		(type(details.itemValue) == "number") and
		(type(details.itemValuePercent) == "boolean" or details.itemValuePercent == nil) and
		(type(details.layer) == "number") and
		(type(details.name) == "string") and
		(type(details.range) == "boolean") and
		(type(details.rangeHigh) == "number") and
		(type(details.rangeLow) == "number") and
		(type(details.selfCast) == "boolean") and
		(type(details.set) == "number") and
		(type(details.sound) == "boolean") and
		(type(details.text) == "string") and
		(type(details.textBlue) == "number" and details.textBlue >= 0 and details.textBlue <= 1) and
		(type(details.textFont) == "string") and
		(type(details.textGreen) == "number" and details.textGreen >= 0 and details.textGreen <= 1) and
		(type(details.textInside) == "boolean") and
		(type(details.textLocation) == "string") and
		(type(details.textOpacity) == "number" and details.textOpacity >= 0 and details.textOpacity <= 1) and
		(type(details.textRed) == "number" and details.textRed >= 0 and details.textRed <= 1) and
		(type(details.textSize) == "number" and details.textSize >= 0) and
		(type(details.timer) == "boolean") and
		(type(details.timerInside) == "boolean") and
		(type(details.timerLength) == "number") and
		(type(details.timerLocation) == "string") and
		(type(details.timerSize) == "number" and details.timerSize >= 0) and
		(type(details.typeToggle) == "boolean") and
		(type(details.unit) == "string") and
		(type(details.unitRelation) == "number")
end

local function updateAlert(details, fromVersion)
	if details.layer == nil then details.layer = 1 end
	if details.combatOnly == nil then details.combatOnly = false end
	if details.itemValue == nil then details.itemValue = 1 end
	if details.itemLength == nil then details.itemLength = 0 end
	if details.type == 1 and details.imageSource == "Rift" then
		local itemNames = string.split(details.itemName, ",")
		if table.getn(itemNames) > 1 then
			if kAlertGlobalItems[itemNames[1]] ~= nil then
				details.image = kAlertGlobalItems[itemNames[1]].icon
			end
		end
	elseif details.type == 3 and type(details.itemId) == "string" then
		details.itemId = tonumber(details.itemId)
	end
	if details.imageSource == "kAlert" and string.match(details.image, "images\\Aura%-(%d+)%.tga") then
		details.image = string.sub(details.image, 1, string.len(details.image) - 3) .. "dds"
	end
	if details.imageOpacity == nil then details.imageOpacity = 1 end
	if details.text == nil then details.text = "" end
	if details.textOpacity == nil then details.textOpacity = 1 end
	if details.textFont == nil then
		if details.timerFont ~= nil then
			details.textFont = details.timerFont
			details.timerFont = nil
		else
			details.textFont = ""
		end
	end
	if details.textRed == nil then details.textRed = 1 end
	if details.textGreen == nil then details.textGreen = 1 end
	if details.textBlue == nil then details.textBlue = 1 end
	if details.textSize == nil then details.textSize = 30 end
	if details.textLocation == nil then details.textLocation = "CENTER" end
	if details.textInside == nil then details.textInside = true end
	if details.timerLength == nil then details.timerLength = 5 end
	if details.selfCast == nil then details.selfCast = false end
	if details.range == nil then details.range = false end
	if details.rangeLow == nil then details.rangeLow = 0 end
	if details.rangeHigh == nil then details.rangeHigh = 0 end
	if details.unitRelation == nil then details.unitRelation = 0 end
	
	if details.unit == "player.target.target" then
		-- Bug in 1.30.x inadvertently converted focus alerts to target of target
		details.unit = "focus"
	end
	
	if (details.type == 1 or details.type == 2) and details.itemId then
		details.itemId = kAlert.convertAbilityId(details.itemId)
	elseif details.type == 2 and details.itemId == nil then
		-- Attempt to add missing ability IDs (caused by a bug in v1.26 - v1.27)
		local globalItem = kAlertGlobalItems[details.itemName]
		if globalItem and globalItem.ability then
			details.itemId = globalItem.ability
		end
	elseif details.type == 4 and details.interruptibleCast == nil then
		details.interruptibleCast = false
	end
end

function kAlert.updateAlerts(fromVersion)
	if kUtils.compareVersions(fromVersion, "1.37.1") >= 0 then
		local updatedSets = { sets = {}, subSets = {} }
		local tempSets = {}
	
		for id, details in pairs(kAlertAlerts) do
			updateAlert(details, fromVersion)
			id = details.name
			local index = details.set
			
			if tempSets[index] == nil then
				if index <= 6 then
					tempSets[index] = private.AlertSet.Create(updatedSets.sets, index)
				else
					tempSets[index] = private.AlertSet.Create(updatedSets.subSets, index - 6)
				end
			end
			
			local result = tempSets[index]:Add(details)
			
			kUtils.taskYield("updateAlerts - " .. id)
		end
		
		for _, set in pairs(tempSets) do
			set:Save()
		end
		
		kAlertAlerts = updatedSets
	else
		local function updateSet(set)
			for id, alertData in pairs(set.alerts) do
				updateAlert(alertData, fromVersion)
				
				-- Delete any alerts that do not pass basic validation
				if not validateAlert(alertData) then
					print(string.format(kAlertTexts.msgInvalidAlertDeleted, alertData.name))
					set.alerts[id] = nil
				end
				
				kUtils.taskYield("updateAlerts - " .. id)
			end
		end		
		for _, set in pairs(kAlertAlerts.sets) do updateSet(set) end
		for _, set in pairs(kAlertAlerts.subSets) do updateSet(set) end
	end
end

function kAlert.updateGlobalItems()
	kUtils.queueTask(function()
		for id, details in pairs(kAlertGlobalItems) do
			if id ~= details.name then
				kAlertGlobalItems[details.name] = details
				kAlertGlobalItems[id] = nil
			end
			if details.update == nil then details.update = true end
			if details.icon == nil then kAlertGlobalItems[details.name] = nil end
			if details.ability then
				details.ability = kAlert.convertAbilityId(details.ability)
			end
			
			kUtils.taskYield()
		end
	end, false, "updateGlobalItems")	
end

function kAlert.screenObjects.init()
	if kAlert.screenObjects.object then return end

	Command.Event.Attach(Event.System.Update.Begin, kAlert.initializationHandler, "eventHandler")
	kAlert.screenObjects.object = {}
	
	kUtils.queueTask(function()
		if kUtils.compareVersions(kAlertVersion, kAlert.version) > 0 then
			print("v" .. tostring(kAlertVersion) .. " -> v" .. tostring(kAlert.version))
		end
		
		print("v" .. tostring(kAlert.version))
		
		kAlert.updateGlobalItems(kAlertGlobalVersion)
		kAlertGlobalVersion = kAlert.version
		
		kAlert.updateAlerts(kAlertVersion)
		kAlertVersion = kAlert.version
		
		kAlert.alertSet = private.AlertSet.Create(kAlertAlerts.sets)
		kAlert.alertSet:Load(kAlert.effectiveAlertSet())

		kAlert.alertSubSet = private.AlertSet.Create(kAlertAlerts.subSets)
		kAlert.alertSubSet:Load(kAlertSubSet)
		kAlert.screenObjects:refresh()
		
		Command.Event.Detach(Event.System.Update.Begin, nil, "eventHandler", nil, addonInfo.identifier)
		Command.Event.Attach(Event.System.Update.Begin, kAlert.eventHandler, "eventHandler")
	end)

	if kAlertGlobalSettings.designer then
		kAlert.config.generalConfiguration()
		kAlert.config.main()
	end
end

function kAlert.screenObjects.addObject(id)

	local iID = tostring(id)
	local object = UI.CreateFrame("Frame", "objectFrame" .. iID, kAlert.context)
	object:SetWidth(75)
	object:SetHeight(75)
	object:SetPoint ("TOPLEFT", kAlert.context, "TOPLEFT")
	object:SetVisible(false)
	object:SetBackgroundColor(0, 0, 0, 0)
	object:SetLayer(-1)

	object.name = nil
	object.unit = nil
	object.unitRelation = 0
	object.type = nil
	object.typeToggle = nil
	object.range = false
	object.rangeLow = 0
	object.rangeHigh = 0
	object.itemId = nil
	object.itemName = nil
	object.itemValue = nil
	object.itemValuePercent = nil
	object.itemLength = 0
	object.timer = nil
	object.timerLength = 0
	object.combatOnly = nil
	object.timerEnd = 0
	object.selfCast = false
		
	object.image = UI.CreateFrame("Texture", "objectIcon" .. iID, object)
	object.image:SetPoint("CENTER", object, "CENTER", 0, 2)
	object.image:SetLayer(0)
	
	object.text = kUtils.createExtText("objectText" .. iID, object)
	object.text:SetShadow(kAlertGlobalSettings.counterTextEffects)
	object.text:SetText('')
	object.text:SetFontSize(object:GetWidth()/2)
	object.text:SetFontColor(1, 1, 1, 1)
	object.text:SetLayer(1)
	object.text:SetPoint("CENTER", object.image, "CENTER")
	
	kUtils.taskYield()
	object.counter = kUtils.createExtText("objectDuration" .. iID, object)
	object.counter:SetShadow(kAlertGlobalSettings.counterTextEffects)
	
	object.counter:SetText('')
	object.counter:SetFontSize(object:GetWidth()/2)	
	object.counter:SetFontColor(1, 1, 1, 1)
	object.counter:SetLayer(3)
	object.counter:SetPoint("CENTER", object.image, "CENTER")
	object.counter:SetVisible(false)
	
	-- Previous value of timer, to prevent redundant SetText calls
	local timerValue = -1
	
	function object.setDims(width, height)
		object:SetWidth(width)
		object:SetHeight(height)
		object.image:SetWidth(width)
		object.image:SetHeight(height)
	end
	
	function object.setTimer(value)
		if value == timerValue then	return end
		timerValue = value
		
		-- Marksman Bull's Eye ability reports a really long cooldown before a DPS skill is used. It looks silly.
		if value >= 0 and value < 100000 then
			object.counter:SetText(tostring(math.floor(value)))
		else
			object.counter:SetText("")
		end
	end
	
	function object.setText(value)
		object.text:SetText(value)
	end
	
	return object
	
end

function kAlert.screenObjects.clear()
	for i, object in ipairs(kAlert.screenObjects.object) do
		object:SetVisible(false)
		object:SetLayer(1)
		object.name = nil
		object.unit = nil
		object.unitRelation = 0
		object.type = nil
		object.typeToggle = nil
		object.itemId = nil
		object.itemName = nil
		object.itemValue = nil
		object.itemValuePercent = nil
		object.itemLength = 0
		object.setDims(10,10)
		object.timer = nil
		object.timerLength = 0
		object.combatOnly = nil
		object.timerEnd = 0
		object.setTimer(-1)
		object.dynamicText = nil
		object.setText("")
		object.selfCast = false	
	end

	kAlert.cache.abilities = {}
end

function kAlert.screenObjects.setTextsShadow(shadow)
	for _, obj in pairs(kAlert.screenObjects.object) do
		obj.text:SetShadow(shadow)
		kUtils.taskYield()
	end
end
function kAlert.screenObjects.setCountersShadow(shadow)
	for _, obj in pairs(kAlert.screenObjects.object) do
		obj.counter:SetShadow(shadow)
		kUtils.taskYield()
	end
end

local function positionScreenObjectText(textFrame, imageFrame, location, textInside)
	if textInside or location == "CENTER" then
		textFrame:SetPoint(location, imageFrame, location)
	elseif location == "TOPCENTER" then
		textFrame:SetPoint("BOTTOMCENTER", imageFrame, "TOPCENTER")
	elseif location == "BOTTOMCENTER" then
		textFrame:SetPoint("TOPCENTER", imageFrame, "BOTTOMCENTER")
	elseif location == "LEFTCENTER" then
		textFrame:SetPoint("RIGHTCENTER", imageFrame, "LEFTCENTER")
	elseif location == "RIGHTCENTER" then
		textFrame:SetPoint("LEFTCENTER", imageFrame, "RIGHTCENTER")
	end
end

function kAlert.screenObjects.add(alert)
	if not alert.active then return end
	
	kAlert.screenObjects.objectCount = kAlert.screenObjects.objectCount + 1
	local i = kAlert.screenObjects.objectCount
	if i > table.getn(kAlert.screenObjects.object) then
		kAlert.screenObjects.object[i] = kAlert.screenObjects.addObject(i)
		kUtils.taskYield()
	end		
	local screenObject = kAlert.screenObjects.object[i]
	
	-- Copy Data
	screenObject.name = alert.name
	screenObject:SetLayer(alert.layer)
	screenObject.unit = alert.unit
	screenObject.unitRelation = alert.unitRelation
	screenObject.type = alert.type
	screenObject.typeToggle = alert.typeToggle
	screenObject.range = alert.range
	screenObject.rangeLow = alert.rangeLow
	screenObject.rangeHigh = alert.rangeHigh
	screenObject.itemLength = alert.itemLength
	screenObject.selfCast = alert.selfCast
	screenObject.itemName = alert.itemName
	
	if alert.type == 1 then
		screenObject.itemName = string.split(alert.itemName, ",")

		for id, itemName in pairs(screenObject.itemName) do
			kAlert.screenObjects.buffList[itemName] = true
		end
		if screenObject.itemLength ~= 0 then
			for id, itemName in pairs(screenObject.itemName) do
				screenObject.itemName[id] = itemName .. tostring(screenObject.itemLength)
			end
		end
		if screenObject.selfCast then
			for id, itemName in pairs(screenObject.itemName) do
				screenObject.itemName[id] = itemName .. "S"
			end
		end
	elseif alert.type == 2 then
		if kAlertGlobalItems[alert.itemName] ~= nil then
			if kAlertGlobalItems[alert.itemName].ability ~= nil and kAlertGlobalItems[alert.itemName].ability ~= "none" then
				local abilityDetails = Inspect.Ability.New.Detail(kAlertGlobalItems[alert.itemName].ability)
				if abilityDetails ~= nil then
					kAlert.cache.abilities[abilityDetails.idNew] =
					{
						cooldownEnd = abilityDetails.currentCooldownBegin and (abilityDetails.currentCooldownBegin + abilityDetails.currentCooldownDuration) or -1,
						unusable = abilityDetails.unusable or false
					}
				end
			end
			if alert.itemId == nil then
				-- Attempt to add missing ability IDs (caused by a bug in v1.26 - v1.27)
				alert.itemId = kAlertGlobalItems[alert.itemName].ability
			end
		end
	elseif alert.type == 4 then
		screenObject.interruptibleCast = alert.interruptibleCast
	end
	
	screenObject.itemId = alert.itemId
	screenObject.itemValue = alert.itemValue
	screenObject.itemValuePercent = alert.itemValuePercent
	screenObject.combatOnly = alert.combatOnly
	screenObject.timerLength = alert.timerLength
	
	-- Image
	kUtils.taskYield("screenObjects.add - image texture")
	screenObject.setDims(alert.imageWidth,alert.imageHeight)
	screenObject.image:SetTexture(alert.imageSource, alert.image)
	kUtils.taskYield("screenObjects.add - image alpha")
	screenObject.image:SetAlpha(alert.imageOpacity)
	screenObject:SetPoint("TOPLEFT", kAlert.context, "TOPLEFT", alert.imageX, alert.imageY)
	
	-- Text
	if string.find(alert.text, "{") then
		screenObject.dynamicText = alert.text
		screenObject.text:SetText("")
	else
		screenObject.text:SetText(alert.text)
	end
	
	screenObject.text:ClearAll()
	screenObject.text:SetFontColor(alert.textRed,alert.textGreen,alert.textBlue)
	screenObject.text:SetAlpha(alert.textOpacity)
	if string.len(alert.textFont) > 0 then
		screenObject.text:SetFont("kAlert",alert.textFont)
	else
		screenObject.text:SetFont("Rift","$Flareserif_medium")
	end
	screenObject.text:SetFontSize(alert.textSize)
	screenObject.text:SetHeight(alert.textSize + 5)
	positionScreenObjectText(screenObject.text, screenObject.image, alert.textLocation, alert.textInside)
	
	-- Timer
	screenObject.timer = alert.timer
	screenObject.counter:SetVisible(alert.timer)
	screenObject.counter:ClearAll()
	if string.len(alert.textFont) > 0 then
		screenObject.counter:SetFont("kAlert",alert.textFont)
	else
		screenObject.counter:SetFont("Rift","$Flareserif_medium")
	end
	screenObject.counter:SetFontSize(alert.timerSize)
	screenObject.counter:SetHeight(alert.timerSize + 5)
	screenObject.counter:SetFontColor(alert.textRed,alert.textGreen,alert.textBlue)
	screenObject.counter:SetAlpha(alert.textOpacity)
	positionScreenObjectText(screenObject.counter, screenObject.image, alert.timerLocation, alert.timerInside)
	
	screenObject:SetVisible(false)
end

function kAlert.screenObjects:refresh()
	
	kUtils.queueTask(function()	
		self.objectCount = 0
		self.clear()
	
		kAlert.systemScanner.scanAbilities()

		-- Maintain some utility tables to see which events we're interested in.
		self.buffList = {}
		self.buffUnits = {}
		self.resourceList = { false, false, false, false, false, false, false }
		
		for id, details in pairs(kAlert.alertSet.alerts) do
			self.add(details)
		end
		kUtils.taskYield("refresh - addSet")
		
		for id, details in pairs(kAlert.alertSubSet.alerts) do
			self.add(details)
		end
		kUtils.taskYield("refresh - addSubSet")
		
		-- Create list of units that we need to monitor buffs for, as well
		-- as a list of resources we're interested in monitoring.
		for id, details in pairs(self.object) do
			if details.type == 1 then -- Buff
				self.buffUnits[details.unit] = true
			elseif details.type == 3 then
				self.resourceList[details.itemId] = true
			end
		end

		-- When using cast in target of target, we also need to track those buffs
		if kAlert.useTargetOfTarget and self.buffUnits["player.target"] then
			self.buffUnits["player.target.target"] = true
		end
		
		for unitSpec, _ in pairs(self.buffUnits) do
			local unitId = Inspect.Unit.Lookup(unitSpec)
			if unitId then 
				kAlert.cache.buffs:initializeUnit(unitId)
			end
		end
		
		subscribeResourceEvents(self.resourceList)
		subscribeAbilityEvents(true)
		subscribeBuffEvents(true)
		
		kAlert.processBuffs()
		kUtils.taskYield("refresh - processBuffs")
		kAlert.processAbilities()
		kUtils.taskYield("refresh - processAbilities")
		kAlert.processResources()
		kUtils.taskYield("refresh - processResources")

	end, kAlert.debug and kAlert.profiling)
end

function kAlert.screenObjects.hide()
	for id, details in pairs(kAlert.screenObjects.object) do
		details:SetVisible(false)
	end
end

function kAlert.changeHandler.roleChanged(handle, role)
	if kAlertSet ~= "auto" then return end
	if kAlert.config.active then return end

	-- This event seems to occur before Event.Unit.Availability.Full for "player",
	-- in which case we need to do some initialization.
	kAlert.screenObjects.init()
	
	if kAlert.rolesMax < role then
		kAlert.rolesMax = role
	end

	kUtils.queueTask(function()
		kAlert.alertSet:Load(kAlert.effectiveAlertSet(role))
		kAlert.screenObjects:refresh()	
		kAlert.printActiveSets()
	end)
end

function kAlert.changeHandler.checkCasting(handle, units)
	if kAlert.config.active or kAlert.changeHandler.castingChanged then return end
	
	for id, details in pairs(units) do
		if kAlert.unitIds[id] then
			kAlert.changeHandler.castingChanged = true
			return
		end
	end
end

function kAlert.processCasting()

	local unitsCasts = {}
	for _, unit in pairs(kAlert.units) do
		local unitId = kAlert.unitSpecs[unit]
		if unitId then
			local spellCast = Inspect.Unit.Castbar(unit)
			if spellCast ~= nil then
				unitsCasts[unitId] = { abilityName = spellCast.abilityName, uninterruptible = spellCast.uninterruptible }
			end
		end
	end
	
	for id, details in pairs(kAlert.screenObjects.object) do
		if details.type == 4 then -- Casting
			local showObject = false
			if not details.combatOnly or kAlert.combat then
				local unit = kAlert.effectiveUnit(details)
				if unit and unitsCasts[unit] then
					showObject =
						(string.len(details.itemName) == 0 or unitsCasts[unit].abilityName == details.itemName) and
						(not details.interruptibleCast or not unitsCasts[unit].uninterruptible)
				end
			end
			details:SetVisible(showObject and not kAlert.config.active)
		end
	end
	kAlert.changeHandler.castingChanged = false

end

local function updateUnitResources(unitId)
	local unitResources = Inspect.Unit.Detail(unitId)
	local resourceList = {}
	if unitResources ~= nil then
		if unitResources.health then
			resourceList[1] = {unitResources.health, (unitResources.health/unitResources.healthMax)*100, unitResources.healthMax}
		end
		if unitResources.mana then
			resourceList[2] = {unitResources.mana, (unitResources.mana/unitResources.manaMax)*100, unitResources.manaMax}
		end
		if unitResources.energy then
			resourceList[3] = {unitResources.energy, (unitResources.energy/unitResources.energyMax)*100, unitResources.energyMax}
		end
		if unitResources.power then
			resourceList[4] = {unitResources.power, unitResources.power}
		end
		if unitResources.charge then
			resourceList[5] = {unitResources.charge, unitResources.charge}
		end
		if unitResources.combo then
			resourceList[6] = {unitResources.combo, unitResources.combo}
		else
			resourceList[6] = {0, 0}
		end
		if unitResources.planar then
			resourceList[7] = {unitResources.planar, unitResources.planarMax}
		end
		
	end
	kAlert.cache.resources[unitId] = resourceList
end

function kAlert.changeHandler.secureEnter(handle)
	kAlert.combat = true

	kAlert.changeHandler.buffChanged = true
	kAlert.changeHandler.abilityChanged = true
	kAlert.changeHandler.resourceChanged = true
	kAlert.changeHandler.castingChanged = true
end

function kAlert.changeHandler.secureLeave(handle)
	kAlert.combat = false
	
	kAlert.changeHandler.buffChanged = true
	kAlert.changeHandler.abilityChanged = true
	kAlert.changeHandler.resourceChanged = true
	kAlert.changeHandler.castingChanged = true
end

-- LibUnitChange based unit change handler
function kAlert.changeHandler.unitChange(unitSpec, unitId)
	unitId = unitId or nil

	local oldId = kAlert.unitSpecs[unitSpec]
	if oldId then
		kAlert.unitIds[oldId][unitSpec] = nil
		if kUtils.tableIsEmpty(kAlert.unitIds[oldId]) then
			kAlert.unitIds[oldId] = nil
			kAlert.cache.removeUnit(oldId)
		end
	end
	
	if unitId then
		if kAlert.unitIds[unitId] == nil then
			kAlert.unitIds[unitId] = { [unitSpec] = true }
		else
			kAlert.unitIds[unitId][unitSpec] = true
		end
	end

	kAlert.unitSpecs[unitSpec] = unitId

	-- Do initialization for units
	if unitId ~= nil then
		updateUnitResources(unitId)
		kAlert.cache.buffs:initializeUnit(unitId)
	end
	kAlert.cache.unitState:updateUnits({[unitSpec] = unitId})
	
	-- Force alert updates
	kAlert.changeHandler.buffChanged = true
	kAlert.changeHandler.resourceChanged = true
end

function kAlert.changeHandler.unitName(handle, units)
	for id, name in pairs(units) do
		if kAlert.cache.unitName[id] then
			kAlert.cache.unitName[id] = name
		end
	end
end

function kAlert.cache.removeUnit(unitId)
	kAlert.cache.buffs[unitId] = nil
	kAlert.cache.resources[unitId] = nil
	kAlert.cache.unitState[unitId] = nil
	kAlert.cache.unitName[unitId] = nil
end


function kAlert.changeHandler.buffsAdded(handle, unit, buffs)
	if not kAlert.cache.buffs[unit] then return end
	
	local buffDetails = Inspect.Buff.Detail(unit, buffs)
	for id, details in pairs(buffDetails) do
		updateBuffInGlobalItems(details)

		-- Actual buff handling
		if kAlert.screenObjects.buffList[details.name] then
			kAlert.cache.buffs:addBuff(unit, details)
		end
	end	

	kAlert.changeHandler.buffChanged = true
end

function kAlert.changeHandler.buffsRemoved(handle, unit, buffs)
	if not kAlert.cache.buffs[unit] then return end
		
	local cache = kAlert.cache.buffs[unit]
	local keysToRemove = {}
	
	for id, _ in pairs(buffs) do
		if cache.byId[id] == nil then
			-- This is normally okay, because we only put buffs in there that we're interested in
			-- logmsg("Warning, buff was missing in cache: %s (unit %s)", id, unitSpec)
		else
			local buffById = cache.byId[id]
			local buffEntry = buffById.entry
			
			cache.byId[id] = nil
			
			for key, _ in pairs(buffById.names) do
				if cache.byName[key] == buffEntry then
					table.insert(keysToRemove, key)
				end
			end
		end
	end
	
	-- Remove the keys marked for deletion
	for _, key in ipairs(keysToRemove) do
		cache.byName[key] = nil
	end
			
	-- Attempt to readd the removed keys based on active buffs.
	-- I think this may only be needed in edge cases, since the longest lasting buff should already be in the cache.
	-- If there are multiple buffs with the same name but different duration, or
	-- when buffs are cancelled prematurely this may have an effect.
	for id, buffById in pairs(cache.byId) do
		for _, key in ipairs(keysToRemove) do
			if buffById.names[key] then
				-- This buff has the right key to be a candidate for adding. Check if we have already
				-- readded the key. If so, check if this buff expires after the already added one.
				if cache.byName[key] == nil or cache.byName[key].expires < buffById.entry.expires then
					cache.byName[key] = buffById.entry
				end
			end
		end
	end
	
	kAlert.changeHandler.buffChanged = true
end

function kAlert.changeHandler.buffsChanged(handle, unit, buffs)
	if not kAlert.cache.buffs[unit] then return end
	
	local buffDetails = Inspect.Buff.Detail(unit, buffs)
	for id, details in pairs(buffDetails) do
		if kAlert.cache.buffs:updateBuff(unit, details) then
			kAlert.changeHandler.buffChanged = true
		end
	end
end

local function updateScreenObjectText(obj, buffDetails)
	if obj.dynamicText == nil then return end

	local text = string.gsub(obj.dynamicText, "%b{}", function(var)
		if var == "{caster}" then
			if buffDetails and buffDetails.caster then
				local name = kAlert.cache.unitName[buffDetails.caster]
				if name == nil then
					name = (Inspect.Unit.Detail(buffDetails.caster) or {}).name
					kAlert.cache.unitName[buffDetails.caster] = name
				end
				return name
			else
				return ""
			end
		elseif var == "{stacks}" then
			if buffDetails and buffDetails.stacks then
				return tostring(buffDetails.stacks)
			else
				return ""
			end
			
		end
	end)

	obj.text:SetText(text)
end

function kAlert.processBuffs()
	local scanTime = Inspect.Time.Frame()
	
	for id, details in pairs(kAlert.screenObjects.object) do
		if details.type == 1 then -- Buff
			local showObject = false
			local timerValue = -1
			details.timerEnd = 0
			
			if not details.combatOnly or kAlert.combat then
				local unit = kAlert.effectiveUnit(details)

				if unit ~= nil and kAlert.cache.buffs[unit] ~= nil and kAlert.cache.buffs[unit].byName ~= nil then
					local cachedBuffs = kAlert.cache.buffs[unit].byName
					local buffDetails = nil
					for id, itemName in pairs(details.itemName) do
						buffDetails = cachedBuffs[itemName]
						if buffDetails then break end
					end
					
					updateScreenObjectText(details, buffDetails)					

					local timeLeft = details.timerLength
					if buffDetails ~= nil and buffDetails.stacks >= details.itemValue then
						details.timerEnd = buffDetails.expires
						timeLeft = details.timerEnd - scanTime
						timerValue = timeLeft
					end
					if timeLeft < details.timerLength and details.timer and not details.typeToggle then
						showObject = true
					else
						showObject = (((buffDetails ~= nil) and (buffDetails.stacks >= details.itemValue)) == details.typeToggle)
					end
				end
			end
			
			details.setTimer(timerValue)
			details:SetVisible(showObject and not kAlert.config.active)
		end
	end
	
	kAlert.changeHandler.buffChanged = false
end

function kAlert.changeHandler.abilityCooldownChanged(handle, abilities)
	for abilityId, value in pairs(abilities) do
		local ability = kAlert.cache.abilities[abilityId]

		if ability == nil then
			-- Do nothing
		elseif value > 1.5 then
			local details = Inspect.Ability.New.Detail(abilityId)
			if not details.currentCooldownPaused then
				ability.cooldownEnd = details.currentCooldownBegin + details.currentCooldownDuration
				ability.unusable = details.unusable or false
				kAlert.changeHandler.abilityChanged = true
			else
				logmsg("Received currentCooldownPaused for ability %s", details.name)
			end
		elseif value == 0 then
			ability.cooldownEnd = -1
			kAlert.changeHandler.abilityChanged = true
		end
	end
end

function kAlert.changeHandler.abilityUsableChanged(handle, abilities)
	for abilityId, value in pairs(abilities) do
		local ability = kAlert.cache.abilities[abilityId]

		if ability ~= nil then
			kAlert.cache.abilities[abilityId].unusable = not value
			kAlert.changeHandler.abilityChanged = true
		end
	end
end

function kAlert.processAbilities()
	if kAlert.config.active then return end

	local scanTime = Inspect.Time.Frame()

	for id, details in pairs(kAlert.screenObjects.object) do
		if details.type == 2 then -- Ability
			local showObject = false
			local timerValue = -1			
			details.timerEnd = 0
			if not details.combatOnly or kAlert.combat then
				local abilityDetails = kAlert.cache.abilities[details.itemId]

				if abilityDetails == nil then
					logmsg("Warning: Ability %s not found in cache", details.itemId)
				elseif abilityDetails.unusable and details.typeToggle then
					-- Ability Ready alert, ability currently unusable.
					timerValue = -1
					showObject = false
				else
					timerValue = abilityDetails.cooldownEnd - scanTime
					details.timerEnd = abilityDetails.cooldownEnd
					if details.timer and timerValue < details.timerLength and details.typeToggle then
						showObject = true
					elseif timerValue > 0 then
						showObject = not details.typeToggle
					else
						showObject = details.typeToggle
					end
				end
			end
			details.setTimer(timerValue)
			details:SetVisible(showObject and not kAlert.config.active)
			kUtils.taskYield()
		end
	end
	
	kAlert.changeHandler.abilityChanged = false
end

function kAlert.changeHandler.resMaxChanged(handle, units)
	for id, _ in pairs(units) do
		if kAlert.cache.resources[id] then
			updateUnitResources(id)
			kAlert.changeHandler.resourceChanged = true
		end
	end
end

function kAlert.changeHandler.resChanged(units, resourceIndex)
	local cache = kAlert.cache.resources

	for unitId, value in pairs(units) do
		if cache[unitId] then
			local resourceData = cache[unitId][resourceIndex]
			if resourceData == nil then
				updateUnitResources(unitId)
			else
				resourceData[1] = value
				if resourceIndex <= 3 then
					resourceData[2] = (value / resourceData[3]) * 100
				else
					resourceData[2] = value
				end
				kAlert.changeHandler.resourceChanged = true
			end
		end
	end
end


function kAlert.changeHandler.resHealthChanged(handle, units)
	kAlert.changeHandler.resChanged(units, 1)
end

function kAlert.changeHandler.resManaChanged(handle, units)
	kAlert.changeHandler.resChanged(units, 2)
end

function kAlert.changeHandler.resEnergyChanged(handle, units)
	kAlert.changeHandler.resChanged(units, 3)
end

function kAlert.changeHandler.resPowerChanged(handle, units)
	kAlert.changeHandler.resChanged(units, 4)
end

function kAlert.changeHandler.resChargeChanged(handle, units)
	kAlert.changeHandler.resChanged(units, 5)
end

function kAlert.changeHandler.resComboChanged(handle, units)
	kAlert.changeHandler.resChanged(units, 6)
end

function kAlert.changeHandler.resPlanarChanged(handle, units)
	kAlert.changeHandler.resChanged(units, 7)
end

function kAlert.processResources()
	if kAlert.config.active then return end
	
	local cache = kAlert.cache.resources
	
	for id, details in pairs(kAlert.screenObjects.object) do
		if details.type == 3 then -- Resource
			local showObject = false
			if kAlert.combat or not details.combatOnly then
				local unit = kAlert.effectiveUnit(details)
				
				if unit ~= nil and cache[unit] ~= nil then
					if cache[unit][details.itemId] ~= nil then
						local checkValue
						if details.itemValuePercent then
							checkValue = cache[unit][details.itemId][2]
						else
							checkValue = cache[unit][details.itemId][1]
						end

						if details.range then
							showObject = (checkValue >= details.rangeLow and checkValue <= details.rangeHigh)
						else
							showObject = ((checkValue >= details.itemValue) == details.typeToggle)
						end
					end
				end
			end
			details:SetVisible(showObject and not kAlert.config.active)
		end
	end
	
	kAlert.changeHandler.resourceChanged = false

end

function kAlert.initializeUnitLookupTables(lookupTable)
	kAlert.unitSpecs = Inspect.Unit.Lookup(lookupTable)
	for spec, id in pairs(kAlert.unitSpecs) do
		if kAlert.unitIds[id] == nil then
			kAlert.unitIds[id] = { [spec] = true }
		else
			kAlert.unitIds[id][spec] = true
		end
	end
end

function kAlert.playerAvailableHandler(handle, units)
	if not kUtils.tableContainsValue(units, "player") then return end
	Command.Event.Detach(Event.Unit.Availability.Full, nil, "playerAvailable", nil, addonInfo.identifier)
	
	-- Initialize unit ID and specifier mappings
	if kUtils.tableIsEmpty(kAlert.unitIds) then
		local lookupTable = {}
		for _, spec in pairs(kAlert.units) do
			lookupTable[spec] = true
		end
		
		kAlert.initializeUnitLookupTables(lookupTable)

		for spec, id in pairs(kAlert.unitSpecs) do
			updateUnitResources(id)
		end
	end
	
	kAlert.cache.unitState:updateUnits(kAlert.unitSpecs)
	
	for _, spec in ipairs(kAlert.units) do
		registerUnitChange(spec, kAlert.changeHandler.unitChange, "kAlert", spec)
	end
	
	-- Detect the number of roles for this character (Rift 2.3)	
	if Inspect.Role and Inspect.Role.List then
		kAlert.rolesMax = 0
		for _, role in pairs(Inspect.Role.List()) do
			kAlert.rolesMax = kAlert.rolesMax + 1
		end
		-- Workaround for what seems to be a bug in the Rift API (Rift 2.3 hotfix 5)
		if kAlert.rolesMax == 0 then kAlert.rolesMax = 1 end
	end
	
	kAlert.screenObjects.init()
end

function kAlert.systemScanner.start()
	if kAlert.systemScanner.activeScanning then return end

	local lookupTable = {}
	for _, spec in pairs(kAlert.units) do
		lookupTable[spec] = true
	end	
	for i = 1, 20 do
		local spec = string.format("group%02d", i)
		lookupTable[spec] = true
		lookupTable[spec .. ".target"] = true
		registerUnitChange(spec, kAlert.changeHandler.unitChange, "kAlert", spec)
		registerUnitChange(spec .. ".target", kAlert.changeHandler.unitChange, "kAlert", spec .. ".target")
	end
	
	kAlert.initializeUnitLookupTables(lookupTable)
	
	for unitId, _ in pairs(kAlert.unitIds) do
		if kAlert.cache.buffs[unitId] == nil then
			if kAlert.cache.buffs[unitId] == nil then
				kAlert.cache.buffs:initializeUnit(unitId)
				logmsg("Initialize unit " .. unitId)
			end
		end
	end
	
	kAlert.systemScanner.activeScanning = true
	Command.Event.Attach(Event.Ability.New.Add, kAlert.systemScanner.abilitiesAdded, "systemScanner")
	kAlert.systemScanner.scanAbilities()
end

function kAlert.systemScanner.stop()
	if not kAlert.systemScanner.activeScanning then return end
	
	kAlert.systemScanner.activeScanning = false
	
	local function removeUnit(spec)
		unregisterUnitChange(spec, "kAlert", spec)
		local unitId = kAlert.unitSpecs[spec]
		if unitId then
			kAlert.unitSpecs[spec] = nil
			kAlert.unitIds[unitId][spec] = nil
			if kUtils.tableIsEmpty(kAlert.unitIds[unitId]) then
				kAlert.unitIds[unitId] = nil
				kAlert.cache.removeUnit(unitId)
				logmsg("Remove unit " .. unitId)
			end
		end
	end
	
	for i = 1, 20 do
		local spec = string.format("group%02d", i)
		removeUnit(spec)
		removeUnit(spec .. ".target")
	end
	
	Command.Event.Detach(Event.Ability.New.Add, nil, "systemScanner", nil, addonInfo.identifier)
end

function kAlert.systemScanner.scanAbilities()
	local abilityList = Inspect.Ability.New.List()
	if abilityList == nil then return end
	kAlert.systemScanner.addAbilities(abilityList)
end

function kAlert.systemScanner.addAbilities(abilities)
	kUtils.queueTask(function()
		for id, _ in pairs(abilities) do
			local details = Inspect.Ability.New.Detail(id)
			if details == nil or details.name == nil then
				logmsg("Ability details not available: " .. id)
			else
				local globalItem = kAlertGlobalItems[details.name]
				if globalItem == nil then
					kAlertGlobalItems[details.name] = {ability = id, name = details.name, icon = details.icon, update = false}
					if kAlert.systemScanner.activeScanning then
						print(kAlertTexts.msgNewAbility .. ': ' .. details.name)
					else
						logmsg(kAlertTexts.msgNewAbility .. ': ' .. details.name)
					end
				elseif globalItem.update or globalItem.ability ~= id then
					globalItem.ability = id
					globalItem.name = details.name
					globalItem.icon = details.icon
					globalItem.update = false
				end
			end
			kUtils.taskYield()
		end
	end, kAlert.debug and kAlert.profiling, "systemScanner.addAbilities")
end

function kAlert.systemScanner.abilitiesAdded(handle, abilities)
	kAlert.systemScanner.addAbilities(abilities)
end

function kAlert.changeHandler.unitAvailabilityNone(handle, units)
	for unitId, unitSpec in pairs(units) do
		kAlert.unitAvailability[unitId] = nil
	end
end

function kAlert.changeHandler.unitAvailabilityPartial(handle, units)
	for unitId, unitSpec in pairs(units) do
		kAlert.unitAvailability[unitId] = false
	end
end

function kAlert.changeHandler.unitAvailabilityFull(handle, units)
	for unitId, unitSpec in pairs(units) do
		kAlert.unitAvailability[unitId] = true
		if kAlert.cache.buffsPending[unitId] then
			logmsg("Performing pending buff update for " .. Inspect.Unit.Lookup(unitId))
			kAlert.cache.buffs:initializeUnit(unitId)
			kAlert.cache.buffsPending[unitId] = nil
		end
	end
end


kAlert.main()


