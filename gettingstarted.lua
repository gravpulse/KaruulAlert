local addonInfo, private = ...
local kAlert = private.kAlert
local kUtils = private.kUtils
local kAlertTexts = private.kAlertTexts

local roleChanges = 0
local steps = {}

function steps.step01()
	kAlert.config.messageBox(
		kAlertTexts.msgTutorialStep01,
		{ kAlertTexts.btYes, kAlertTexts.btNo },
		steps.step02)
end

function steps.step02(button)
	if button and button ~= 1 then return end
	
	kAlert.systemScanner.start()
	
	roleChanges = 0
	if Event.TEMPORARY and Event.TEMPORARY.Role then
		Command.Event.Attach(Event.TEMPORARY.Role, function() roleChanges = roleChanges + 1 end, "gettingStarted")
	end	
	
	kAlert.config.messageBox(
		kAlertTexts.msgTutorialStep02,
		{ kAlertTexts.btContinue, kAlertTexts.btCancel },
		steps.step03)
end

function steps.step03(button)
	if Event.TEMPORARY and Event.TEMPORARY.Role then
		Command.Event.Detach(Event.TEMPORARY.Role, nil, "gettingStarted", nil, addonInfo.identifier)
	end
	
	if button and button ~= 1 then return end
	
	if roleChanges == 0 then
		kAlert.config.messageBox(
			kAlertTexts.msgTutorialStep03Retry,
			{ kAlertTexts.btTryAgain, kAlertTexts.btContinue, kAlertTexts.btCancel },
			steps.step03b)
	else
		kAlert.config.messageBox(
			kAlertTexts.msgTutorialStep03,
			{ kAlertTexts.btContinue, kAlertTexts.btCancel },
			steps.step04)
	end
end

function steps.step03b(button)
	if button == 1 then
		steps.step02()
	elseif button == 2 then
		roleChanges = -1
		steps.step03()
	end
end

function steps.step04(button)
	if button and button ~= 1 then return end

	kAlert.config.messageBox(
		kAlertTexts.msgTutorialStep04,
		{ kAlertTexts.btOK, kAlertTexts.btCancel },
		steps.step05)
end

function steps.step05(button)
	if button == 1 then
		kAlert.config.main()
	end

	kAlert.config.messageBox(
		kAlertTexts.msgTutorialStep05,
		{ kAlertTexts.btContinue, kAlertTexts.btCancel },
		steps.step06)
end

function steps.step06(button)
	if button and button ~= 1 then return end

	kAlert.config.messageBox(
		kAlertTexts.msgTutorialStep06,
		{ kAlertTexts.btOK, kAlertTexts.btCancel },
		steps.step07)
end

function steps.step06(button)
	if button and button ~= 1 then return end

	kAlert.config.messageBox(
		kAlertTexts.msgTutorialStep07,
		{ kAlertTexts.btYes, kAlertTexts.btNo },
		steps.step08)
end

function steps.step08(button)
	if button and button ~= 1 then return end
	kAlert.config.help()
end

function kAlert.gettingStarted(firstTime)
	if firstTime then
		steps.step01()
	else
		steps.step02()
	end
end

