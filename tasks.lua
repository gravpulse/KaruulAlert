local addonInfo, private = ...
local kAlert = private.kAlert
local kUtils = private.kUtils
local kAlertTexts = private.kAlertTexts
local taskErrors = {}

local taskCoroutine
local tasks = {}

function kUtils.queueTask(func, verbose, name)
	if name ~= nil then
		for _, task in ipairs(tasks) do
			if task[3] == name then	return end
		end
	end

	table.insert(tasks, {func, verbose, name})
end

function kUtils.queueTaskWithParams(func, params, verbose, name)
	kUtils.queueTask(function() func(unpack(params)) end, verbose, name)
end

function kUtils.taskYield(id)
	if id == nil then id = "" end
	
	local remaining = Inspect.System.Watchdog()
	if remaining <= kAlertGlobalSettings.yieldThreshold then
		if tasks.verbose then
			print(string.format("yield: %s (%fs)", id, remaining))			
		end
		coroutine.yield()
	elseif tasks.verbose then
		print(string.format("no yield: %s (%fs)", id, remaining))
	end
end

local function getStackTrace(err)
	return debug.traceback(err, 2)
end

local function taskRunner()
	while tasks do
		if #tasks == 0 then
			coroutine.yield()
		else
			local func = tasks[1][1]
			tasks.verbose = tasks[1][2]
			local result, err = xpcall(func, getStackTrace)
			if not result then
				if not taskErrors[err] then
					local taskName = tasks[1][3] or "unnamed background task"
					Utility.Dispatch(function() error(err) end, "kAlert", taskName)
					taskErrors[err] = { 1, Inspect.Time.Real() + 3 }
				else
					taskErrors[err][1] = taskErrors[err][1] + 1
					if Inspect.Time.Real() >= taskErrors[err][2] then
						taskErrors[err][2] = Inspect.Time.Real() + 30
						print(kAlertTexts.msgTaskRecurringError)
					end
				end
			end
			table.remove(tasks, 1)
			coroutine.yield()
		end
	end
end

local function suggestReconfiguration()
	local current
	for i, value in ipairs(kAlert.config.yieldThresholds) do
		if kAlertGlobalSettings.yieldThreshold < value then	break end
		current = i
	end
	
	if current < table.getn(kAlert.config.yieldThresholds) then
		local function adjustCallback(button)
			if button ~= 1 then return end
			
			kAlertGlobalSettings.yieldThreshold = kAlert.config.yieldThresholds[current + 1]
		end
	
		kAlert.config.messageBoxTop(
			"Your system seems to be running slower than expected.\rWould you like to adjust your settings to prevent performance warnings?",
			{"Yes", "No"},
			adjustCallback)
	end
end

function kUtils.runTasks()
	if not taskCoroutine then
		taskCoroutine = coroutine.create(taskRunner)
	end
	
	local result, err = coroutine.resume(taskCoroutine)
	if Inspect.System.Watchdog() == 0 then
		suggestReconfiguration()
	end
	
	if not result then
		print(err .. " " .. coroutine.status(taskCoroutine))
		taskCoroutine = nil
	end
end

