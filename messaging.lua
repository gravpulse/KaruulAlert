local addonInfo, private = ...
local kAlert = private.kAlert
local kUtils = private.kUtils
local kAlertTexts = private.kAlertTexts
local LibSUnit = Inspect.Addon.Detail("SafesUnitLib").data

local playerName = Inspect.Unit.Detail("player").name
local latestVersionSeen = kAlert.versionStable
local addEvent = Utility.Event.Create("kAlert", "Users.Add")
local messageBuilders = {}

local function logmsg(msg)
	if kAlert.debug then print(msg) end
end

kAlert.messaging.users =
{
}

function messageBuilders.version()
	return "Version;" .. kAlert.version .. ";" .. kAlert.versionStable .. ";" .. kAlert.revision
end

function kAlert.messaging.discoverUsers()
	local message = messageBuilders.version()
	if LibSUnit.Raid.Grouped then
		Command.Message.Broadcast(LibSUnit.Raid.Mode, nil, "kAlert", message, function(failure, message) end)
	end
	Command.Message.Broadcast("guild", nil, "kAlert", message, function(failure, message) end)
	Command.Message.Broadcast("yell", nil, "kAlert", message, function(failure, message) end)
end


function kAlert.messaging.messageHandler(handle, from, type, channel, identifier, data)
	if identifier ~= "kAlert" then return end
	if from == playerName then return end
	
	local msg = string.split(data, ";") 
	
	if msg[1] == "Version" then
		logmsg(string.format("Player %s has KaruulAlert version %s", from, msg[2]))

		if msg[3] ~= nil and kUtils.compareVersions(latestVersionSeen, msg[3]) > 0 then
			print(string.format(kAlertTexts.msgNewVersion, msg[3]))
			latestVersionSeen = msg[3]
		end
		
		local reply = false
		local existingUser = kAlert.messaging.users[from]
		if existingUser then
			reply = Inspect.Time.Real() - (existingUser.discovered or 0) > 30
			existingUser.version = msg[2]
			existingUser.discovered = Inspect.Time.Real()
		else
			reply = true
			kAlert.messaging.addUser(from, msg[2])
		end
		
		if type ~= "send" and reply then
			Command.Message.Send(from, "kAlert", messageBuilders.version(), function(failure, message) end)
		end
	elseif msg[1] == "ShareAlert" then
		local data = table.concat(msg, ";",2)
		local alertData, err = kAlert.config.formatAlertImport(data, 41)
		if not err then
			table.insert(kAlert.sharedAlerts, {alertData, from})
		else
			print(string.format(kAlertTexts.msgSharedAlertCorrupt, from))
		end
	end
	
end

function kAlert.messaging.addUser(character, version)
	kAlert.messaging.users[character] =
	{
		version = version,
		discovered = Inspect.Time.Real()
	}
	
	addEvent(character, kAlert.messaging.users[character])
end

function kAlert.messaging.shareAlert(user, alertData, callback)
	Command.Message.Send(user, "kAlert", "ShareAlert;" .. alertData, callback)
end

Command.Event.Attach(Event.Message.Receive, kAlert.messaging.messageHandler, "messageHandler")

Command.Message.Accept(nil, "kAlert")



