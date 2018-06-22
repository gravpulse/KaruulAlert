local addon, private = ...

private.AlertSet = {}
local AlertSet = private.AlertSet
AlertSet.__index = AlertSet

function AlertSet.Create(setsTable, active)
	local obj =	{ setsTable = setsTable }
	setmetatable(obj, AlertSet)
	obj:Clear()
	obj.active = active
	return obj
end

function AlertSet:Load(setNumber, setsTable)
	if setsTable then
		self.setsTable = setsTable
	end
	
	self:Clear()
	if setNumber == 0 then return end
	self.active = setNumber
	
	if self.setsTable[setNumber] == nil then return end
	
	for id, details in pairs(self.setsTable[setNumber].alerts) do
		self.alerts[details.name] = details
		self.count = self.count + 1
	end
end

function AlertSet:Save()
	self.setsTable[self.active] = { alerts = {} }
	for id, details in pairs(self.alerts) do
		self.setsTable[self.active].alerts[details.name] = details
	end
end

function AlertSet:Add(alert)
	if alert ~= nil and (self.count < private.kAlert.screenObjects.max or self.alerts[alert.name] ~= nil) then
		alert.set = self.active
		self.alerts[alert.name] = alert
		self.count = self.count + 1
		return true
	end
	
	return false
end

function AlertSet:Delete(name)
	if self.alerts[name] ~= nil then
		self.alerts[name] = nil
		self.count = self.count - 1
		return true
	end
	
	return false
end


function AlertSet:Clear()
	self.count = 0
	self.alerts = {}
	self.active = nil
end


