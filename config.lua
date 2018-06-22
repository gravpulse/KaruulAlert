local addonInfo, private = ...
local kAlert = private.kAlert
local kUtils = private.kUtils
local kAlertTexts = private.kAlertTexts

kAlert.config = {}
kAlert.config.movers = {object = {}}
kAlert.config.mainFrame = nil
kAlert.config.layoutFrame = nil
kAlert.config.importExportFrame = nil
kAlert.config.generalConfigFrame = nil
kAlert.config.helpFrame = nil
kAlert.config.aboutFrame = nil
kAlert.config.alertCopyFrame = nil
kAlert.config.messageBoxFrame = nil
kAlert.config.active = false
kAlert.config.tLocation = {"CENTER","TOPCENTER","BOTTOMCENTER","LEFTCENTER","RIGHTCENTER"}
kAlert.config.recources = { kAlertTexts.resHealth,
                            kAlertTexts.resMana,
                            kAlertTexts.resEnergy,
                            kAlertTexts.resPower,
                            kAlertTexts.resCharge,
                            kAlertTexts.resComboPoints,
                            kAlertTexts.resPlanar }
kAlert.config.units = {kAlertTexts.unitPlayer,kAlertTexts.unitTarget,kAlertTexts.unitFocus,kAlertTexts.unitPet}
kAlert.config.evaluationTypes = {kAlertTexts.buff,kAlertTexts.ability,kAlertTexts.resource,kAlertTexts.casting}

kAlert.config.yieldThresholds = { 0.03, 0.045, 0.07 }

local function getAlertSet(setNumber, setsTable)
	local targetSet
	
	if setsTable == kAlertAlerts.sets and kAlert.alertSet.active == setNumber then
		return kAlert.alertSet
	end
	
	if setsTable == kAlertAlerts.subSets and kAlert.alertSubSet.active == setNumber then
		return kAlert.alertSubSet
	end
	
	targetSet = private.AlertSet.Create(setsTable)
	targetSet:Load(setNumber)
	
	return targetSet
end

local function buildLayoutFrame()
	local window = UI.CreateFrame("RiftWindow", "kAlertConfigLayoutFrame", kAlert.context)
	window:SetVisible(false)
	window:SetTitle(kAlertTexts.titleLayout)
	window:SetHeight(100)
	window:SetWidth(260)
	window:SetPoint("TOPLEFT", UIParent, "TOPLEFT",UIParent:GetWidth()/2-100,UIParent:GetHeight()/2-50)
	window:SetLayer(99)
	-- Mover Box
	window.frMoveBar = kUtils.buildWindowMover("frMoveBar", window, true)

	window.btSave = kUtils.buildButton("btSave",window,35,120,kAlertTexts.btSave)
	window.btSave:SetPoint("TOPCENTER", window, "TOPCENTER", -60, 50)

	window.btSave:EventAttach(Event.UI.Button.Left.Press,
		function ()
			for id, details in pairs(kAlert.screenObjects.object) do
				if details.name ~= nil then
					if kAlert.config.movers.object[id] ~= nil then
						kAlert.config.movers.object[id].clearTarget()
					end
					if window.alertSet.alerts[details.name] ~= nil then
						window.alertSet.alerts[details.name].imageX = details:GetLeft()
						window.alertSet.alerts[details.name].imageY = details:GetTop()
					end
				end
			end
			kAlert.screenObjects.hide()
			window.alertSet = nil
			window:SetVisible(false)
			kAlert.config.mainFrame:SetVisible(true)
		end, "Save")
	
	window.btCancel = kUtils.buildButton("btCancel",window,35,120,kAlertTexts.btCancel)
	window.btCancel:SetPoint("LEFTCENTER", window.btSave, "RIGHTCENTER")
	
	window.btCancel:EventAttach(Event.UI.Button.Left.Press,
		function ()
			for id, details in pairs(kAlert.screenObjects.object) do
				if details.name ~= nil and kAlert.config.movers.object[id] ~= nil then
					kAlert.config.movers.object[id].clearTarget()
				end
			end
			kAlert.screenObjects.hide()
			window:SetVisible(false)
			kAlert.config.mainFrame:SetVisible(true)
		end, "Cancel")
	
	function window.Open(alertSet)
		window.alertSet = alertSet
		window:SetVisible(true)
		
		kUtils.queueTask(function()
			kAlert.screenObjects.clear()
			for id, details in pairs(window.alertSet.alerts) do
				kAlert.screenObjects.add(details)
			end
			
			for i, details in ipairs(kAlert.screenObjects.object) do
				if details.name ~= nil then
					details:SetVisible(true)
					if kAlert.config.movers.object[i] == nil then
						kAlert.config.movers.object[i] = kAlert.config.movers.addObject(i)
					end
					kAlert.config.movers.object[i].setTarget(details)
				end
			end
		end)
	end

	kAlert.config.layoutFrame = window
end

local function buildAboutFrame()
	local window = UI.CreateFrame("RiftWindow", "kAlertAboutFrame", kAlert.context)
	window:SetTitle(kAlertTexts.miAbout)
	window:SetHeight(600)
	window:SetWidth(600)
	window:SetPoint("TOPLEFT", UIParent, "TOPLEFT",UIParent:GetWidth()/2-(window:GetWidth()/2),UIParent:GetHeight()/2-(window:GetHeight()/2))
	window:SetLayer(99)
	-- Mover Box
	window.frMoveBar = kUtils.buildWindowMover("frMoveBar", window, true)

	window.txtAboutTitle = kUtils.buildLabel("txtAboutTitle", window, 15, window:GetWidth() - 60, kAlertTexts.abtTitle,true)
	window.txtAboutTitle:SetPoint("TOPLEFT", window, "TOPLEFT", 30, 65)

	window.txtAboutVersion = kUtils.buildLabel("txtAboutVersion", window, 15, window:GetWidth() - 60, kAlertTexts.lbVersion .. " " .. tostring(kAlert.version),true)
	window.txtAboutVersion:SetPoint("TOPLEFT", window.txtAboutTitle, "BOTTOMLEFT")

	window.txtAboutInfo = kUtils.buildLabel("txtAboutInfo", window, 15, window:GetWidth() - 60, kAlertTexts.abtInfo,true)
	window.txtAboutInfo:SetPoint("TOPLEFT", window.txtAboutVersion, "BOTTOMLEFT", 0, 10)
	window.txtAboutInfo.setWrapText(kAlertTexts.abtInfo)

	window.btClose = kUtils.buildButton("btClose",window,35,120,kAlertTexts.btClose,"close")
	window.btClose:SetPoint ("TOPRIGHT", window, "TOPRIGHT", -9, 16)
	
	window.btClose:EventAttach(Event.UI.Button.Left.Press, function() window:SetVisible(false) end, "Close")

	kAlert.config.aboutFrame = window
end

local function buildHelpFrame()
	local window = UI.CreateFrame("RiftWindow", "kAlertConfigImportExportFrame", kAlert.context)
	window:SetTitle("Karuul Alert Help")
	window:SetHeight(600)
	window:SetWidth(750)
	window:SetPoint("TOPLEFT", UIParent, "TOPLEFT",UIParent:GetWidth()/2-(window:GetWidth()/2),UIParent:GetHeight()/2-(window:GetHeight()/2))
	window:SetLayer(100)
	window:SetVisible(false)
	-- Mover Box
	window.frMoveBar = kUtils.buildWindowMover("frMoveBar", window, true)
	
	window.frIndex = kUtils.buildListPane("frIndex",window, table.getn(private.helpIndex)*20,210)
	window.frIndex:SetPoint ("TOPLEFT", window, "TOPLEFT", 30, 65)
	window.frIndex.fillTextList(private.helpIndex)
	
	function window.navigateTo(indexNumber, sectionNumber)
		if indexNumber then
			window.frIndex.setSelected(private.helpIndex[indexNumber])
		end
		if sectionNumber then
			local offset = window.sections.section[sectionNumber].labelLine:GetTop() - window.frView:GetTop()
			local rangeMin, rangeMax = window.scrPage:GetRange()
			window.scrPage:SetPosition(math.min(offset, rangeMax))
		end
	end
	
	-- Unfortunately we need a global variable to be able to access this function from HTML right now
	kAlertHelpNavigateTo = window.navigateTo

	function window.frIndex.click(button)
		window.sections.clear()
		local topic = private.helpTopic[window.frIndex.getSelected()]
		for i = 1, table.getn(topic), 1 do
			window.sections.add(topic[i].label, topic[i].text)
		end
		window.frPage:SetPoint("TOPLEFT", window.frView, "TOPLEFT")
		if window.frIndex.getSelected() == "Configuration Screen" then
			window.ibConfig:SetVisible(true)
			window.sections.section[1].label:SetPoint("TOPLEFT", window.frPage, "TOPLEFT",0,window.ibConfig:GetHeight()+2)
			window.frPage:SetHeight(math.max(window.ibConfig:GetHeight()+2+window.sections.getHeight(),window.frView:GetHeight()))
		else
			window.ibConfig:SetVisible(false)
			window.sections.section[1].label:SetPoint("TOPLEFT", window.frPage, "TOPLEFT")
			window.frPage:SetHeight(math.max(window.sections.getHeight(),window.frView:GetHeight()))
		end
		window.scrPage:SetPosition(0)
		window.scrPage:SetRange(0, math.max(0, window.frPage:GetHeight()- window.frView:GetHeight()))
	end
	
	window.frView = UI.CreateFrame("Mask", "frView", window)
	window.frView:SetHeight(window:GetHeight() - 120)
	window.frView:SetWidth(window:GetWidth() - window.frIndex:GetWidth() - 70)
	window.frView:SetPoint ("TOPLEFT", window.frIndex, "TOPRIGHT", 10, 0)
	window.frView.outline = kUtils.setOutline(window.frView)
	
	window.frPage = kUtils.buildFrame("frPage", window.frView, window.frView:GetHeight(), window.frView:GetWidth())
	window.frPage:SetBackgroundColor(0,0,0,0.5)
	window.frPage:SetPoint("TOPLEFT", window.frView, "TOPLEFT")
	
	window.scrPage = UI.CreateFrame("RiftScrollbar", "scrPage", window)
	window.scrPage:SetPoint("TOPLEFT", window.frView, "TOPRIGHT")
	window.scrPage:SetHeight(window.frView:GetHeight())
	window.scrPage:SetRange(0, math.max(0, window.frPage:GetHeight() - window.frView:GetHeight()))
	
	window.scrPage:EventAttach(Event.UI.Scrollbar.Change,
		function(self, handle)
			local value = self:GetPosition()
			window.frPage:SetPoint("TOPLEFT", window.frView, "TOPLEFT", 0, -1 * value)
		end, "PageScroll")
	
	window.frView:EventAttach(Event.UI.Input.Mouse.Wheel.Back,
		function()
			local minRange, maxRange = window.scrPage:GetRange()
			if maxRange == 0 then return end
			local value = math.min(maxRange - 1, window.scrPage:GetPosition() + 30)
			window.scrPage:SetPosition(value)
		end, "PageWheelBack")
		
	window.frView:EventAttach(Event.UI.Input.Mouse.Wheel.Forward,
		function()
			local value = math.max(0, window.scrPage:GetPosition() - 30)
			window.scrPage:SetPosition(value)
		end, "PageWheelForward")
	
	window.ibConfig = UI.CreateFrame("Texture", "ibConfig", window.frPage)
	window.ibConfig:SetTexture("kAlert", "images\\ConfigScreen.png")
	window.ibConfig:SetVisible(false)
	window.ibConfig:SetPoint("TOPCENTER", window.frPage, "TOPCENTER",0,2)
	
	kUtils.taskYield("buildHelpFrame - sections")
	window.sections = {}
	window.sections.section = {}
	window.sections.count = 0
	function window.sections.clear()
		for i = 1, table.getn(window.sections.section), 1 do
			window.sections.section[i].label.setWrapText("")
			window.sections.section[i].labelLine:SetVisible(false)
			window.sections.section[i].text.setWrapText("")
		end
		window.sections.count = 0
	end
	function window.sections.add(label,text)
		local index = window.sections.count + 1
		if window.sections.section[index] == nil then
			local section = {}
			if index == 1 then 
				section.label = kUtils.buildLabel("lblSection" .. tostring(index), window.frPage, 22, window.frPage:GetWidth(), "",true)
				section.label:SetPoint("TOPLEFT", window.frPage, "TOPLEFT")
				section.label:SetFontColor(0,0,0)
				section.label:SetBackgroundColor(.75,.60,0)
			else
				section.label = kUtils.buildLabel("lblSection" .. tostring(index), window.frPage, 18, window.frPage:GetWidth(), "",true)
				section.label:SetPoint("TOPLEFT", window.sections.section[index-1].text, "BOTTOMLEFT",-20,10)
				section.label:SetFontColor(.75,.60,0)
			end
			section.label:SetFont("Rift", "$Flareserif_bold")
			section.labelLine = UI.CreateFrame("Frame", "lblSectionLine" .. tostring(index), section.label)
			section.labelLine:SetPoint("CENTERTOP", section.label, "CENTERTOP")
			section.labelLine:SetHeight(1)
			section.labelLine:SetWidth(section.label:GetWidth())
			section.labelLine:SetBackgroundColor(.52,.51,.42)
			section.text = kUtils.buildLabel("txtSection" .. tostring(index), section.label, 15, window.frPage:GetWidth()-40, "",true)
			section.text:SetPoint("TOPLEFT", section.label, "BOTTOMLEFT",20,0)
			section.text:SetFontColor(.9,.9,.9)
			window.sections.section[index] = section
		end
		window.sections.section[index].label.setWrapText(label)
		window.sections.section[index].labelLine:SetVisible(true)
		
		-- Convert Wiki syntax links to Rift "html" code
		local htmlText = string.gsub(text, "%[%[([^/%]]*)[/]?([^|]*)|([^%]]+)%]%]", function(link, section, text)
			local indexNumber = nil
			local sectionNumber = nil

			if string.len(link) > 0 then
				for i, topic in ipairs(private.helpIndex) do
					if topic == link then
						indexNumber = i
						break
					end
				end
				if indexNumber == nil then return text end
			end
			
			if string.len(section) > 0 then
				for i, topic in ipairs(private.helpTopic[link]) do
					if topic.anchor == section or topic.label == section then
						sectionNumber = i
						break
					end
				end
			end
			
			return string.format(
				"<u><font color=\"#FF0000\"><a lua=\"kAlertHelpNavigateTo(%s,%s)\">%s</a></font></u>",
				tostring(indexNumber), tostring(sectionNumber), text)
			
		end)
		
		window.sections.section[index].text.setWrapText(htmlText, true)
		window.sections.count = window.sections.count + 1
	end
	
	function window.sections.getHeight()
		local height = 0
		for i = 1, table.getn(window.sections.section), 1 do
			height = height + window.sections.section[i].label:GetHeight() + 10
			height = height + window.sections.section[i].text:GetHeight()
		end
		return height
	end

	window.navigateTo(1)
	
	window.btClose = kUtils.buildButton("btClose", window, 35, 120, kAlertTexts.btClose, "close")
	window.btClose:SetPoint("TOPRIGHT", window, "TOPRIGHT", -9, 16)
	
	window.btClose:EventAttach(Event.UI.Button.Left.Press,
		function()
			window:SetVisible(false)
			window.sections.clear()
			window.ibConfig:SetVisible(false)
			window.navigateTo(1)
		end, "Close")
	
	kAlert.config.helpFrame = window
	
end

local function buildImportExportFrame()
	local window = UI.CreateFrame("RiftWindow", "kAlertConfigImportExportFrame", kAlert.context)
	window:SetTitle("")
	window:SetHeight(400)
	window:SetWidth(620)
	window:SetPoint("TOPLEFT", UIParent, "TOPLEFT",UIParent:GetWidth()/2-(window:GetWidth()/2),UIParent:GetHeight()/2-(window:GetHeight()/2))
	window:SetLayer(99)
	window:SetVisible(false)
	-- Mover Box
	window.frMoveBar = kUtils.buildWindowMover("frMoveBar", window, true)

	window.txtExplanation = kUtils.buildLabel("txtExplanation", window, 13, window:GetWidth() - 60, "", true)
	window.txtExplanation:SetPoint("TOPLEFT", window, "TOPLEFT", 30, 70)
	
	window.lbData = kUtils.buildLabel("lbData", window, 13, 200, kAlertTexts.lbAlertData, false)
	window.lbData:SetPoint("TOPLEFT", window.txtExplanation, "BOTTOMLEFT", 0, 10)
	
	window.ebData = kUtils.buildEditBox("ebData", window, 120, window:GetWidth() - 60, "")
	window.ebData:SetPoint("TOPLEFT", window.lbData, "BOTTOMLEFT", 0, 5)
	
	window.txtStatus = kUtils.buildLabel("txtStatus", window, 13, window:GetWidth() - 60, "", true)
	window.txtStatus:SetPoint("TOPLEFT", window.ebData, "BOTTOMLEFT", 0, 10)

	window.btImport = kUtils.buildButton("btImport", window, 35, 120, kAlertTexts.btImport)
	window.btImport:SetPoint("BOTTOMCENTER", window, "BOTTOMCENTER", -60, -20)

	window.btCancel = kUtils.buildButton("btCancel", window, 35, 120, kAlertTexts.btCancel)
	window.btCancel:SetPoint("LEFTCENTER", window.btImport, "RIGHTCENTER")
	
	local autoSelect = false
	
	function window.Open(title, explanation, data, status, autoSelect)
		window:SetTitle(title)
		window.txtExplanation:SetText(explanation)
		window.ebData.text:SetText(data or "")
		window.txtStatus:SetText(status or "")

		window.AutoSelect(autoSelect or false)
		window:SetVisible(true)
		if not autoSelect then
			window.ebData.text:SetKeyFocus(true)
		end
	end
	
	function window.Close()
		kAlert.screenObjects:refresh()
		kAlert.config.mainFrame.clearAlert()
		kAlert.config.mainFrame.frScreenObjects.fillList(kAlert.config.mainFrame.alertSet.alerts)
		window:SetVisible(false)	
	end
	
	function window.ebData.text:SelectAll()
		if autoSelect then
			self:SetSelection(0, self:GetText():len())
		end
	end
	
	function window.AutoSelect(value)
		if value then
			window.ebData.text:SetKeyFocus(true)
			window.ebData.text:SelectAll()
		end
		
		autoSelect = value
	end	
	
	window.ebData.text:EventAttach(Event.UI.Textfield.Select, window.ebData.text.SelectAll, "selectionChanged")
	window.ebData.text:EventAttach(Event.UI.Input.Mouse.Left.Click, window.ebData.text.SelectAll, "mouseClick")

	window.btCancel:EventAttach(Event.UI.Input.Mouse.Left.Click, function()
		window:SetVisible(false)
	end, "cancel")

	kAlert.config.importExportFrame = window
	
end

local function buildAlertPreview(name, parent)
	local preview = UI.CreateFrame("Frame", name, parent)
	preview:SetWidth(50)
	preview:SetHeight(50)
	preview:SetBackgroundColor(1, 1, 1, 0.8)
	preview.text = kUtils.createExtText("frPreviewText", preview)
	preview.text:SetPoint("CENTER", preview, "CENTER", 0, 0)
	return preview
end

local function buildGeneralConfigFrame()
	local window = UI.CreateFrame("RiftWindow", "kAlertConfigShareFrame", kAlert.context)
	window:SetTitle(kAlertTexts.addonName)
	window:SetWidth(455)
	window:SetHeight(525)
	--window:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
	
	-- Mover Box and Close button
	window.frMoveBar = kUtils.buildWindowMover("frMoveBar", window, true)
	window.btClose = kUtils.buildButton("btClose",window,35,100,kAlertTexts.btClose,"close")
	window.btClose:SetPoint("TOPRIGHT", window, "TOPRIGHT", -9, 15)

	window.lbAlertTextEffects = kUtils.buildLabel("lbTextEffects", window, 13, 200, kAlertTexts.lbAlertTextEffects, false)
	window.lbAlertTextEffects:SetPoint("TOPLEFT", window, "TOPLEFT", 30, 65)

	window.dlAlertTextEffects = UIX.CreateDropdownList("dlAlertTextEffects", window)
	window.dlAlertTextEffects:SetPoint("TOPLEFT", window.lbAlertTextEffects, "BOTTOMLEFT", 0, 5)
	window.dlAlertTextEffects:SetWidth(200)
	window.dlAlertTextEffects:SetItems(kAlertTexts.tbTextEffects)	
	
	window.frTextPreview = buildAlertPreview("frTextPreview", window)
	window.frTextPreview:SetPoint("TOPLEFT", window.lbAlertTextEffects, "TOPRIGHT", 10, 5)
	window.frTextPreview.text:SetText("Text")
	window.frTextPreview.text:SetFontSize(20)

	function window.dlAlertTextEffects.Event:SelectionChange(index)
		window.frTextPreview.text:SetShadow(index - 1)
	end

	window.lbAlertCounterEffects = kUtils.buildLabel("lbTextEffects", window, 13, 200, kAlertTexts.lbAlertCounterEffects, false)
	window.lbAlertCounterEffects:SetPoint("TOPLEFT", window.dlAlertTextEffects, "BOTTOMLEFT", 0, 15)
	
	window.dlAlertCounterEffects = UIX.CreateDropdownList("dlAlertCounterEffects", window)
	window.dlAlertCounterEffects:SetPoint("TOPLEFT", window.lbAlertCounterEffects, "BOTTOMLEFT", 0, 5)
	window.dlAlertCounterEffects:SetWidth(200)
	window.dlAlertCounterEffects:SetItems(kAlertTexts.tbTextEffects)
	
	window.frCounterPreview = buildAlertPreview("frCounterPreview", window)
	window.frCounterPreview:SetPoint("TOPLEFT", window.lbAlertCounterEffects, "TOPRIGHT", 10, 5)
	window.frCounterPreview.text:SetText("12")
	window.frCounterPreview.text:SetFontSize(30)
	
	function window.dlAlertCounterEffects.Event:SelectionChange(index)
		window.frCounterPreview.text:SetShadow(index - 1)
	end

	window.lbPerformance = kUtils.buildLabel("lbPerformance", window, 13, 200, kAlertTexts.lbPerformance, false)
	window.lbPerformance:SetPoint("TOPLEFT", window.dlAlertCounterEffects, "BOTTOMLEFT", 0, 15)
	window.tbPerformance = kUtils.buildToggleBox("tbPerformance", window, 20, 200, kAlertTexts.tbPerformance, 1, false)
	window.tbPerformance:SetPoint("TOPLEFT", window.lbPerformance, "BOTTOMLEFT", 0, 5)	
	window.txtPerformance = kUtils.buildLabel("txtPerformance", window, 13, 200, kAlertTexts.txtPerformance, true)
	window.txtPerformance:SetPoint("TOPLEFT", window.tbPerformance, "TOPRIGHT", 10, 0)	

	window.lbOther = kUtils.buildLabel("lbScanner", window, 13, 200, kAlertTexts.lbScanner, false)
	window.lbOther:SetPoint("TOPLEFT", window.tbPerformance, "BOTTOMLEFT", 0, 15)
	
	window.btScannerOn = kUtils.buildButton("btScannerOn", window, 35, 150, kAlertTexts.btScannerStart)
	window.btScannerOn:SetPoint("TOPLEFT", window.lbOther, "BOTTOMLEFT", 0, 5)	
	window.btScannerOff = kUtils.buildButton("btScannerOff", window, 35, 150, kAlertTexts.btScannerStop)
	window.btScannerOff:SetPoint("TOPLEFT", window.btScannerOn, "BOTTOMLEFT", 0, 0)	
	window.btResetGlobals = kUtils.buildButton("btResetGlobals", window, 35, 150, kAlertTexts.btResetGlobals)
	window.btResetGlobals:SetPoint("TOPLEFT", window.btScannerOff, "BOTTOMLEFT", 0, 5)	
	window.txtScanner = kUtils.buildLabel("txtScanner", window, 13, 200, kAlertTexts.txtScanner, true)
	window.txtScanner:SetPoint("TOPLEFT", window.btScannerOn, "TOPRIGHT", 60, 0)		
	window.txtResetGlobals = kUtils.buildLabel("txtResetGlobals", window, 13, 200, kAlertTexts.txtResetGlobals, true)
	window.txtResetGlobals:SetPoint("TOPLEFT", window.btResetGlobals, "TOPRIGHT", 60, 0)		
	
	window.btClose2 = kUtils.buildButton("btClose", window, 35, 100, kAlertTexts.btClose)
	window.btClose2:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -20, -20)

	window.btSave = kUtils.buildButton("btSave", window, 35, 100, kAlertTexts.btApply)
	window.btSave:SetPoint("BOTTOMRIGHT", window.btClose2, "BOTTOMLEFT", -10, 0)
	
	window.btScannerOn:EventAttach(Event.UI.Button.Left.Press,
		function()
			window.btScannerOn:SetEnabled(false)
			window.btScannerOff:SetEnabled(true)
			kAlert.systemScanner.start()
		end, "ScannerOn")
	
	window.btScannerOff:EventAttach(Event.UI.Button.Left.Press,	
		function()
			window.btScannerOn:SetEnabled(true)
			window.btScannerOff:SetEnabled(false)
			kAlert.systemScanner.stop()
		end, "ScannerOff")
	
	window.btResetGlobals:EventAttach(Event.UI.Button.Left.Press,
		function()
			kAlertGlobalItems = {}
			kAlert.screenObjects:refresh()
		end, "ResetGlobals")

	function window.close()
		window:SetVisible(false)
	end
	
	-- Loading and saving
	function window.loadSettings()
		window.dlAlertTextEffects:SetSelected(kAlertGlobalSettings.textTextEffects + 1)
		window.dlAlertCounterEffects:SetSelected(kAlertGlobalSettings.counterTextEffects + 1)

		-- Find the next preset that has a treshold that is at least as long as the active setting
		for i, threshold in ipairs(kAlert.config.yieldThresholds) do
			window.tbPerformance.setSelected(i)
			if kAlert.config.yieldThresholds[i] >= kAlertGlobalSettings.yieldThreshold then break end
		end
		
		window.btScannerOn:SetEnabled(not kAlert.systemScanner.activeScanning)
		window.btScannerOff:SetEnabled(kAlert.systemScanner.activeScanning)
	end
	
	function window.saveSettings()
		kAlertGlobalSettings.textTextEffects = window.dlAlertTextEffects:GetSelected() - 1
		kAlertGlobalSettings.counterTextEffects = window.dlAlertCounterEffects:GetSelected() - 1
		kAlertGlobalSettings.yieldThreshold = kAlert.config.yieldThresholds[window.tbPerformance.getSelected()]
				
		kUtils.queueTask(function()
			kAlert.screenObjects.setTextsShadow(kAlertGlobalSettings.textTextEffects)
			kAlert.screenObjects.setCountersShadow(kAlertGlobalSettings.counterTextEffects)
		end)
		
	end
	
	window.btSave:EventAttach(Event.UI.Button.Left.Press, window.saveSettings, "Save")
	window.btClose:EventAttach(Event.UI.Button.Left.Press, window.close, "Close")
	window.btClose2:EventAttach(Event.UI.Button.Left.Press, window.close, "Close")
	
	window.loadSettings()
	kAlert.config.generalConfigFrame = window
	
end

local function buildShareFrame()
	local window = UI.CreateFrame("RiftWindow", "kAlertConfigShareFrame", kAlert.context)
	window:SetTitle(kAlertTexts.titleShareAlert)
	window:SetHeight(625)
	window:SetWidth(200)
	window:SetPoint("TOPLEFT", UIParent, "TOPLEFT",UIParent:GetWidth()/2-(window:GetWidth()/2),UIParent:GetHeight()/2-(window:GetHeight()/2))
	window:SetLayer(99)
	window:SetVisible(false)
	
	window.btClose = kUtils.buildButton("btClose", window, 35, 100, kAlertTexts.btClose, "close")
	window.btClose:SetPoint("TOPRIGHT", window, "TOPRIGHT", -3, 15)
	
	window.btClose:EventAttach(Event.UI.Button.Left.Press,
		function()
			window:SetVisible(false)
		end, "Close")
	
	window.txUsers = UI.CreateFrame("Text", "txUsers", window)
	window.txUsers:SetText(kAlertTexts.lbSharingSelectPlayer)
	window.txUsers:SetPoint("TOPLEFT", window, "TOPLEFT", 30, 65)
	
	window.lpUsers = kUtils.buildListPane("lpUsers", window, 400, 150)
	window.lpUsers:SetPoint("TOPLEFT", window.txUsers, "BOTTOMLEFT", 0, 5)
	
	window.details = UI.CreateFrame("Frame", "frDetails", window)
	window.details:SetPoint("TOPLEFT", window.lpUsers, "BOTTOMLEFT", 0, 5)
	
	window.details.lbPlayer = kUtils.buildLabel("lbPlayer", window.details, 15, 65, kAlertTexts.unitPlayer ..  ":", false)
	window.details.lbPlayer:SetPoint("TOPLEFT", window.details, "TOPLEFT")
	window.details.txtPlayer = kUtils.buildLabel("txtPlayer", window.details, 15, 85, "", false)
	window.details.txtPlayer:SetPoint("TOPLEFT", window.details.lbPlayer, "TOPRIGHT")

	window.details.lbVersion = kUtils.buildLabel("lbVersion", window.details, 15, 65, kAlertTexts.lbVersion, false)
	window.details.lbVersion:SetPoint("TOPLEFT", window.details.lbPlayer, "BOTTOMLEFT", 0, 5)
	window.details.txtVersion = kUtils.buildLabel("txtVersion", window.details, 15, 85, "", false)
	window.details.txtVersion:SetPoint("TOPLEFT", window.details.lbVersion, "TOPRIGHT")
	
	window.btShare = kUtils.buildButton("btShare", window, 35, 120, kAlertTexts.btShare)
	window.btShare:SetPoint("BOTTOMCENTER", window, "BOTTOMCENTER", 0, -20)
	window.btShare:SetEnabled(false)
	
	function window.lpUsers.click(button)
		local selectedUser = window.lpUsers.getSelected()
		
		window.details.txtPlayer:SetText(selectedUser)
		window.details.txtVersion:SetText(tostring(kAlert.messaging.users[selectedUser].version))
		window.btShare:SetEnabled(true)
	end
	
	window.btShare:EventAttach(Event.UI.Button.Left.Press,
		function()	
			local selectedUser = window.lpUsers.getSelected()
			local selectedAlert = kAlert.config.mainFrame.frScreenObjects.getSelected()
			if selectedAlert ~= "" then
				local alertData = kAlert.config.mainFrame.alertSet.alerts[selectedAlert]
				local serializedData, err = kAlert.config.formatAlertExport(alertData)
				if not serializedData then
					print(err)
				else
					kAlert.messaging.shareAlert(selectedUser, serializedData, function(failure, message)
						if (failure) then
							print(string.format(kAlertTexts["msgSharingFailure"], selectedUser))
						else
							print(string.format(kAlertTexts["msgSharingSuccess"], selectedUser))
						end
					end
					)
				end
			end
		end, "Share")

	local function updateList()
		window.lpUsers.fillList(kAlert.messaging.users)
	end
	
	table.insert(Event.kAlert.Users.Add, {updateList, "kAlert", "shareFrameUserAdd"})

	updateList()
	kAlert.messaging.discoverUsers()

	window:SetPoint("TOPLEFT", kAlert.config.mainFrame, "TOPRIGHT", 10, 0)
	
	kAlert.config.shareFrame = window
end

local function buildAlertCopyFrame()
	local window = UI.CreateFrame("RiftWindow", "kAlertConfigAlertCopyFrame", kAlert.context)
	window:SetTitle("Copy")
	window:SetHeight(350)
	window:SetWidth(350)
	window:SetPoint("TOPLEFT", UIParent, "TOPLEFT",UIParent:GetWidth()/2-(window:GetWidth()/2),UIParent:GetHeight()/2-(window:GetHeight()/2))
	window:SetLayer(99)
	window:SetVisible(false)
	-- Mover Box
	window.frMoveBar = kUtils.buildWindowMover("frMoveBar", window, true)
	
	window.lbText = UI.CreateFrame("Text", "alertCopyFrameText", window)
	window.lbText:SetPoint("TOPLEFT", window, "TOPLEFT", 30, 60)
	window.lbText:SetWidth(290)
	window.lbText:SetWordwrap(true)
	window.lbText:SetFontSize(15)
	
	window.ebAlert = kUtils.buildEditBox("ebAlert", window, 20, 280, kAlertTexts.ebAlertName .. ":", 180)
	window.ebAlert:SetPoint("TOPLEFT", window.lbText, "BOTTOMLEFT", 0, 15)
	window.ebAlert.text:SetText("")
	
	window.ebSet = kUtils.buildEditBoxInteger("ebSet", window, 20, 150, kAlertTexts.lbSet, 50)
	window.ebSet:SetPoint("TOPLEFT", window.ebAlert, "BOTTOMLEFT", 0, 15)
	window.ebSet.text:SetText("")
	window.lbSetHint = kUtils.buildLabel("lbSetHint", window, 15, 100, "(1 - " .. tostring(kAlert.rolesMax) .. ")", false)
	window.lbSetHint:SetPoint("TOPLEFT", window.ebSet.text, "TOPRIGHT")
	
	window.ebSubSet = kUtils.buildEditBoxInteger("ebSubSet", window, 20, 150, kAlertTexts.lbSubSet, 50)
	window.ebSubSet:SetPoint("TOPLEFT", window.ebSet, "BOTTOMLEFT", 0, 10)
	window.ebSubSet.text:SetText("")
	window.lbSubSetHint = kUtils.buildLabel("lbSetHint", window, 15, 100, "(1 - 10)", false)
	window.lbSubSetHint:SetPoint("TOPLEFT", window.ebSubSet.text, "TOPRIGHT")
	
	window.lbStatus = UI.CreateFrame("Text", "alertCopyFrameStatus", window)
	window.lbStatus:SetPoint("TOPLEFT", window.ebSubSet, "BOTTOMLEFT", 0, 20)
	window.lbStatus:SetWidth(290)
	window.lbStatus:SetWordwrap(true)
	window.lbStatus:SetFontSize(15)
	
	local function updateButtonStatus()
		window.btImport:SetEnabled(window.set ~= nil or window.subSet ~= nil)
	end
	
	
	window.ebSet.text:EventAttach(Event.UI.Textfield.Change,
		function(self, handle)
			window.ebSubSet.text:SetText("")
		
			local setNumber = kUtils.toInteger(self:GetText())
			if self:GetText() == "" then
				window.set = nil
			elseif setNumber == nil	or setNumber > kAlert.rolesMax or setNumber < 1 then
				window.ebSet.text:SetText(tostring(window.set or ""))
			else
				window.set = setNumber
				window.subSet = nil
			end
			
			updateButtonStatus()
		end, "SetChange")
	
	window.ebSubSet.text:EventAttach(Event.UI.Textfield.Change,
		function(self, handle)
			window.ebSet.text:SetText("")
		
			local setNumber = kUtils.toInteger(self:GetText())
			if self:GetText() == "" then
				window.subSet = nil
			elseif setNumber == nil	or setNumber > 10 or setNumber < 1 then
				window.ebSubSet.text:SetText(tostring(window.subSet or ""))
			else
				window.subSet = setNumber
				window.set = nil
			end
			
			updateButtonStatus()
		end, "SubSetChange")
	
	function window.open(title, text, alertName, set, subSet, buttonText)
		window:SetTitle(title)
		window.lbText:SetText(text)
		window.ebAlert.text:SetText(alertName)
		window.set = set
		window.ebSet.text:SetText(tostring(set or ""))
		window.ebSubSet.text:SetText(tostring(subSet or ""))
		window.subSet = subSet
		window.btImport:SetText(buttonText)
		updateButtonStatus()
		window:SetVisible(true)
	end
	
	window.btImport = kUtils.buildButton("btImport",window,35,120,kAlertTexts.btImport)
	window.btImport:SetPoint("BOTTOMCENTER", window, "BOTTOMCENTER",-60,-20)
	
	window.btImport:EventAttach(Event.UI.Button.Left.Press,
		function()
			local set, setsTable
			if window.set then
				set = window.set
				setsTable = kAlertAlerts.sets
			elseif window.subSet then
				set = window.subSet
				setsTable = kAlertAlerts.subSets
			end
				
			local result, text = window.callback(window.ebAlert.text:GetText(), set, setsTable)
			if result == true then
				window:SetVisible(false)
				window.lbStatus:SetText("")
			else
				window.lbStatus:SetText(text or "")
			end
		end, "Import")

	window.btCancel = kUtils.buildButton("btCancel",window,35,120,kAlertTexts.btCancel)
	window.btCancel:SetPoint("LEFTCENTER", window.btImport, "RIGHTCENTER")
	
	window.btCancel:EventAttach(Event.UI.Button.Left.Press,
		function()
			window.cancelCallback()
			window:SetVisible(false)
			window.lbStatus:SetText("")
		end, "Cancel")

	kAlert.config.alertCopyFrame = window
end

local function editAlert(window)
	window.setStatus("")
	local alertData = window.alertSet.alerts[window.frScreenObjects.getSelected()]
	if alertData ~= nil then
		window.clearAlert()
		window.ebAlertName.text:SetText(alertData.name)
		window.ebAlertLayer.text:SetText(tostring(alertData.layer))
		window.tbRelation.setSelected(alertData.unitRelation)
		for i = 1, table.getn(kAlert.units), 1 do
			if kAlert.units[i] == alertData.unit then window.tbUnit.setSelected(i) end
		end
		window.tbAlertTypes.setSelected(alertData.type)
		if alertData.typeToggle then
			window.tbAlertToggle.setSelected(1)
			window.tbResourceToggle.setSelected(1)
		else
			window.tbAlertToggle.setSelected(2)
			window.tbResourceToggle.setSelected(2)
		end

		if alertData ~= 3 then
			window.ebAlertItem.text:SetText(alertData.itemName)
			window.tbResourceTypes.setSelected(1)
		end
		
		if alertData.type == 1 then
			window.ebStacks.text:SetText(tostring(alertData.itemValue or ""))
		elseif alertData.type == 3 then
			window.ebAlertItem.text:SetText("")
			window.tbResourceTypes.setSelected(alertData.itemId)
			if alertData.range then
				window.tbResourceToggle.setSelected(3)
				if alertData.rangeLow == alertData.rangeHigh then
					tValue = tostring(alertData.rangeLow)
				else
					tValue = tostring(alertData.rangeLow) .. '-' .. tostring(alertData.rangeHigh)
				end
				if alertData.itemValuePercent then
					tValue = tValue .. "%"
				end
				window.ebValue.text:SetText(tValue)
			else
				local tValue = tostring(alertData.itemValue)
				if tValue ~= 'nil' then
					if alertData.itemValuePercent then
						tValue = tValue .. "%"
					end
					window.ebValue.text:SetText(tValue)
				end
			end
		end
		
		window.ckSelfCast:SetChecked(alertData.selfCast)
		window.ckInterruptible:SetChecked(alertData.interruptibleCast or false)
		if alertData.itemLength > 0 then
			window.ebBuffLength.text:SetText(tostring(alertData.itemLength))
		end
		window.ckDisableAlert:SetChecked(not alertData.active)
		window.ckCombatOnly:SetChecked(alertData.combatOnly)
		for id, itemName in pairs(string.split(alertData.itemName, ",")) do
			if kAlertGlobalItems[itemName] and kAlertGlobalItems[itemName].icon then
				window.ebImage.setDefault(kAlertGlobalItems[itemName].icon)
			end
		end
		if alertData.imageSource ~= "Rift" then
			window.ckDefaultImage:SetChecked(false)
			if string.sub(alertData.image,1,6) == "custom" then
				window.ebImage.setImageCustom(alertData.imageSource, alertData.image)
				window.ebCustomImage.text:SetText(string.sub(alertData.image,8))
			else
				local imageIndex = tonumber(string.match(alertData.image, "Aura%-(%d+)%.dds"))
				if imageIndex then
					window.ebImage.setImageIndex(imageIndex)
				else
					print(string.format("Warning: Alert \"%s\" image information is invalid (%s). Reverting to default image.", alertData.name, alertData.image))
					window.ebImage.index = 0
					window.ckDefaultImage:SetChecked(true)
				end
			end
		else
			window.ebImage.index = 0
			window.ckDefaultImage:SetChecked(true)
		end
		
		window.ebImageX.text:SetText(tostring(alertData.imageX))
		window.ebImageY.text:SetText(tostring(alertData.imageY))
		window.ebImageScale.text:SetText(tostring(alertData.imageScale))
		window.ebImageOpacity.text:SetText(tostring(alertData.imageOpacity*100))
		window.ebText.text:SetText(alertData.text)
		window.ebTextOpacity.text:SetText(tostring(alertData.textOpacity*100))
		if string.sub(alertData.textFont,1,6) == "custom" then
			window.ebTextFont.text:SetText(string.sub(alertData.textFont,8))
		end
		window.ebRed.text:SetText(tostring(alertData.textRed*100))
		window.ebGreen.text:SetText(tostring(alertData.textGreen*100))
		window.ebBlue.text:SetText(tostring(alertData.textBlue*100))
		window.slRed:SetPosition(math.floor(alertData.textRed*100))
		window.slGreen:SetPosition(math.floor(alertData.textGreen*100))
		window.slBlue:SetPosition(math.floor(alertData.textBlue*100))
		window.frColor.setColor()
		window.ebTextSize.text:SetText(tostring(alertData.textSize))
		for i = 1, table.getn(kAlert.config.tLocation), 1 do
			if kAlert.config.tLocation[i] == alertData.textLocation then
				window.tbTextLocation.setSelected(i)
			end
		end
		if alertData.textInside then
			window.tbTextInside.setSelected(1)
		else
			window.tbTextInside.setSelected(2)
		end
		window.ckTimer:SetChecked(alertData.timer)
		window.ebTimerSize.text:SetText(tostring(alertData.timerSize))
		for i = 1, table.getn(kAlert.config.tLocation), 1 do
			if kAlert.config.tLocation[i] == alertData.timerLocation then
				window.tbTimerLocation.setSelected(i)
			end
		end
		if alertData.timerInside then
			window.tbTimerInside.setSelected(1)
		else
			window.tbTimerInside.setSelected(2)
		end
		window.ebTimerLength.text:SetText(tostring(alertData.timerLength-1))
		window.frScreenObjects.clearSelected()
		window.ebAlertName.text:SetKeyFocus(true)
		window.oldAlertName = alertData.name
		window.setStatus(kAlertTexts.statLoaded)
	end
end

local function saveAlert(window)
	window.setStatus("")
	
	local v = kUtils.FormsValidator.create()
	local alertData = {}

	local function getFormData()
		alertData.name = window.ebAlertName.text:GetText()
		alertData.itemLength = v:GetNumberInput(window.ebBuffLength, 0, false)
		alertData.imageX = v:GetIntegerInput(window.ebImageX, 0, false)
		alertData.imageY = v:GetIntegerInput(window.ebImageY, 0, false)
		alertData.imageScale = v:GetNumberInput(window.ebImageScale, 1, false, 0)

		local textRed = v:GetIntegerInput(window.ebRed, 100, true, 0, 100)
		local textGreen = v:GetIntegerInput(window.ebGreen, 100, true, 0, 100)
		local textBlue = v:GetIntegerInput(window.ebBlue, 100, true, 0, 100)
		
		alertData.layer = v:GetIntegerInput(window.ebAlertLayer, 1, false, 1, 40)
		alertData.unit = kAlert.units[window.tbUnit.getSelected()]
		alertData.unitRelation = window.tbRelation.getSelected()
		
		alertData.type = window.tbAlertTypes.getSelected()
		
		if alertData.type ~= 3 then
			alertData.typeToggle = (window.tbAlertToggle.getSelected() == 1)
		end
		
		if alertData.type == 1 then
			alertData.itemValue = tonumber(window.ebStacks.text:GetText()) or 1
		elseif alertData.type == 3 then
			local tValue = window.ebValue.text:GetText()
			alertData.itemValuePercent = tValue:suffix("%")
			if alertData.itemValuePercent then
				tValue = string.sub(tValue, 0, string.len(tValue) - 1)
			end
			alertData.itemValue = tonumber(string.match(tValue,"(%d+)")) or 1

			alertData.typeToggle = (window.tbResourceToggle.getSelected() == 1)
			alertData.range = (window.tbResourceToggle.getSelected() == 3)
			if alertData.range then
				if string.find(tValue,"-") then
					local rangeLow, rangeHigh = string.match(tValue,"(%d+)-(%d+)")
					alertData.rangeLow = tonumber(rangeLow)
					alertData.rangeHigh = tonumber(rangeHigh)
				else
					alertData.rangeLow = tonumber(tValue)
					alertData.rangeHigh = tonumber(tValue)
				end
			end
		end
		
		if alertData.rangeLow == nil then alertData.rangeLow = 0 end
		if alertData.rangeHigh == nil then alertData.rangeHigh = 0 end
		alertData.itemId = nil
		alertData.itemName = window.ebAlertItem.text:GetText()
		if string.len(alertData.name) == 0 then
			-- Use item name as default alert name
			alertData.name = string.split(alertData.itemName, ",")[1]
		end
		
		alertData.selfCast = window.ckSelfCast:GetChecked()
		alertData.interruptibleCast = window.ckInterruptible:GetChecked()
		alertData.active = not window.ckDisableAlert:GetChecked()
		alertData.combatOnly = window.ckCombatOnly:GetChecked()
		alertData.image = window.ebImage.image
		alertData.imageSource = window.ebImage.source
		
		local imageOpacity = v:GetNumberInput(window.ebImageOpacity, 100, false, 0, 100)
		alertData.text = window.ebText.text:GetText()
		local textOpacity = v:GetNumberInput(window.ebTextOpacity, 100, false, 0, 100)
		
		if string.len(window.ebTextFont.text:GetText()) > 0 then
			alertData.textFont = "custom\\" .. window.ebTextFont.text:GetText()
		else
			alertData.textFont = ""
		end
		
		alertData.textSize = v:GetIntegerInput(window.ebTextSize, 30, false, 1)
		alertData.textLocation = kAlert.config.tLocation[window.tbTextLocation.getSelected()]
		alertData.textInside = (window.tbTextInside.getSelected() == 1)
		alertData.timer = window.ckTimer:GetChecked()
		
		local timerLength = v:GetIntegerInput(window.ebTimerLength, 5, false, 0)
		alertData.timerSize = v:GetIntegerInput(window.ebTimerSize, 30, false, 1)
		alertData.timerLocation = kAlert.config.tLocation[window.tbTimerLocation.getSelected()]
		alertData.timerInside = (window.tbTimerInside.getSelected() == 1)
		alertData.sound = false
		alertData.set = window.alertSet.active
		
		if v.validationError then
			return kAlertTexts.statAlertInvalid .. ": " .. v.validationError, v.validationControl
		end
		
		if string.len(alertData.name) == 0 then
			return kAlertTexts.statAlertNameMissing, window.ebAlertName.text
		end

		-- Fields derived from input, set after validation.
		alertData.textRed = textRed / 100
		alertData.textGreen = textGreen / 100
		alertData.textBlue =  textBlue / 100
		alertData.timerLength = timerLength + 1
		alertData.imageOpacity = imageOpacity / 100
		alertData.textOpacity = textOpacity / 100
		alertData.imageWidth = window.ebImage:GetTextureWidth() * alertData.imageScale
		alertData.imageHeight = window.ebImage:GetTextureHeight() * alertData.imageScale
		
		if window.frScreenObjects.itemCount >= kAlert.screenObjects.max then
			return "Alert failed to add - maximum has been reached"
		end
	
		if window.tbAlertTypes.getSelected() == 4 then
			-- No additional validation
		elseif window.tbAlertTypes.getSelected() == 3 then
			alertData.itemId = window.tbResourceTypes.getSelected()
			alertData.itemName = kAlert.config.recources[alertData.itemId]
		elseif window.tbAlertTypes.getSelected() == 2 then
			local itemDetails = kAlertGlobalItems[alertData.itemName]
			if itemDetails == nil or itemDetails.ability == nil then
				return kAlertTexts.statItemNotFound
			end
		elseif window.tbAlertTypes.getSelected() == 1 then
			alertData.itemId = "none"
			local found = false
			for id, itemName in pairs(string.split(alertData.itemName, ",")) do
				local itemDetails = kAlertGlobalItems[itemName]
				if itemDetails ~= nil then
					found = true
					if itemDetails.ability ~= nil then
						alertData.itemId = itemDetails.ability
					end
				end
			end
			if not found then
				return kAlertTexts.statItemNotFound
			end
		else
			return "No alert type set"
		end
	end
	
	local statusText, control = getFormData()
	if statusText then
		window.setStatus(statusText)
		if control then
			control:SetKeyFocus(true)
		end
		return
	end
	
	local alertAddStatus
	if alertData.name ~= window.oldAlertName and window.alertSet.alerts[alertData.name] ~= nil then
		window.setStatus(kAlertTexts.statAlertAlreadyExists)
		window.ebAlertName.text:SetKeyFocus(true)
		return
	elseif window.oldAlertName == nil then
		alertAddStatus = kAlertTexts.statAlertAdded
	else
		alertAddStatus = kAlertTexts.statAlertUpdated
		if alertData.name ~= window.oldAlertName then
			window.alertSet:Delete(window.oldAlertName)
		end
	end
	
	window.alertSet:Add(alertData)
	window.alertSet:Save()
	
	kAlert.screenObjects:refresh()
	window.clearAlert()
	
	window.frScreenObjects.fillList(window.alertSet.alerts)
	window.setStatus(alertAddStatus)
end

local function buildMainFrame()
	local window = UI.CreateFrame("RiftWindow", "kAlertConfigMainFrame", kAlert.context)
	window:SetVisible(false)
	window:SetTitle(kAlertTexts.addonName)
	window:SetHeight(625)
	window:SetWidth(890)
	window:SetPoint("TOPLEFT", UIParent, "TOPLEFT",UIParent:GetWidth()/2-445,UIParent:GetHeight()/2-280)

	-- Mover Box
	window.frMoveBar = kUtils.buildWindowMover("frMoveBar", window, true)
	
	-- Main Menu
	local function importEnabled()
		return window.frScreenObjects.itemCount < kAlert.screenObjects.max
	end
	local function exportAlertEnabled()
		return window.getActiveAlertName() ~= nil
	end
	local function exportSetEnabled()
		return window.frScreenObjects.itemCount > 0
	end
	
	local menu = 
	{
		{
			kAlertTexts.miFile, 
			{
				{ kAlertTexts.btImportAlert, kAlert.config.importAlert, importEnabled },
				{ kAlertTexts.btImportSet, kAlert.config.importSet, importEnabled },
				{ kAlertTexts.btExportAlert, kAlert.config.exportAlert, exportAlertEnabled },
				{ kAlertTexts.btExportSet, kAlert.config.exportSet, exportSetEnabled },
				{ kAlertTexts.miGeneralConfiguration, kAlert.config.generalConfiguration }
			},
		},
		{
			kAlertTexts.miHelp,
			{
				{ kAlertTexts.miAbout, kAlert.config.about },
				{ kAlertTexts.miContents, kAlert.config.help }
			}
		}
	}
	
	window.mbMain = kUtils.buildMenuBar("mbMain", window, 20, window:GetWidth() - 60 , menu)
	window.mbMain:SetLayer(9000)
	window.mbMain:SetPoint("TOPLEFT", window, "TOPLEFT", 30, 65)

	kUtils.taskYield("buildMainFrame")
	
	-- Alert Set Controls
	window.btASLeft = kUtils.buildButton("btASLeft",window,25,60,"<-")
	window.btASLeft:SetPoint("TOPLEFT", window.mbMain, "BOTTOMLEFT", 0, 5)

	window.btASLeft:EventAttach(Event.UI.Button.Left.Press,
		function()
			if window.alertSet.active > 1 then
				window.alertSet = getAlertSet(window.alertSet.active - 1, window.alertSet.setsTable)
			elseif window.alertSet.setsTable == kAlertAlerts.subSets then
				window.alertSet = getAlertSet(kAlert.rolesMax, kAlertAlerts.sets)
			end
		
			window.txtASNumber.updateText()
			kAlert.screenObjects:refresh()
			window.frScreenObjects.fillList(window.alertSet.alerts)
		end, "ASLeft")
	
	window.frASFrame = kUtils.buildFrame("frASFrame",window,25,80)
	window.frASFrame:SetPoint("BOTTOMLEFT", window.btASLeft, "BOTTOMRIGHT", 0, 0)
	
	window.txtASNumber = kUtils.buildLabel("txtASNumber", window, 15, 80, "(set)")
	window.txtASNumber:SetPoint("CENTER", window.frASFrame, "CENTER")

	function window.txtASNumber.updateText()
		if window.alertSet.setsTable == kAlertAlerts.sets then
			kAlert.config.mainFrame.txtASNumber:SetText("Set " .. tostring(window.alertSet.active))
		else
			kAlert.config.mainFrame.txtASNumber:SetText("Sub Set " .. tostring(window.alertSet.active))
		end
	end

	window.btASRight = kUtils.buildButton("btASRight",window,25,60,"->")
	window.btASRight:SetPoint("BOTTOMLEFT", window.frASFrame, "BOTTOMRIGHT", 0, 0)

	window.btASRight:EventAttach(Event.UI.Button.Left.Press,
		function()
			if window.alertSet.setsTable == kAlertAlerts.sets then
				if window.alertSet.active < kAlert.rolesMax then
					window.alertSet = getAlertSet(window.alertSet.active + 1, kAlertAlerts.sets)
				else
					window.alertSet = getAlertSet(1, kAlertAlerts.subSets)
				end
			else
				if window.alertSet.active < 10 then
					window.alertSet = getAlertSet(window.alertSet.active + 1, kAlertAlerts.subSets)
				end
			end
				
			window.txtASNumber.updateText()
			kAlert.screenObjects:refresh()
			window.frScreenObjects.fillList(window.alertSet.alerts)
		end, "ASRight")
	
	kUtils.taskYield("frScreenObjects")
	window.frScreenObjects = kUtils.buildListPane("frScreenObjects",window, 410, 200)
	window.frScreenObjects:SetPoint("TOPLEFT", window.btASLeft, "BOTTOMLEFT", 0, 5)
	--window.frScreenObjects.fillList(window.alertSet.alerts)

	local function deleteSelectedAlert()
		window.setStatus("")
		local alertName = window.frScreenObjects.getSelected()
		if window.alertSet.alerts[alertName] ~= nil then
			window.alertSet:Delete(alertName)
			window.alertSet:Save()
			window.frScreenObjects.fillList(window.alertSet.alerts)
			window.clearAlert()
		end
		kAlert.screenObjects:refresh()
	end
	
	local function shareAlert()
		kUtils.queueTask(function()
			buildShareFrame()
			kAlert.config.shareFrame:SetVisible(true)
		end)
	end
	
	function window.frScreenObjects.click(button)
		if button == "LEFT" then
			if window.frScreenObjects.lastSelected == window.frScreenObjects.getSelected() and (window.frScreenObjects.lastSelectedTime + 0.2 > Inspect.Time.Real()) then
				editAlert(window)
			else
				window.frScreenObjects.lastSelected = window.frScreenObjects.getSelected()
			end
			window.frScreenObjects.lastSelectedTime = Inspect.Time.Real()
		else
			kUtils.showContextMenu(
				{
					--{"Edit", nil},
					{kAlertTexts.miMoveToSet, kAlert.config.moveAlert},
					{kAlertTexts.miCopyToSet, kAlert.config.copyAlert},
					{kAlertTexts.btDelete, deleteSelectedAlert},
					{kAlertTexts.btShareAlert, shareAlert},
					{kAlertTexts.btExportAlert .. "...", kAlert.config.exportAlert}
				})
		end
	end
	
	window.btEdit = kUtils.buildButton("btEdit",window,35,100,kAlertTexts.btEdit)
	window.btEdit:SetPoint("TOPLEFT", window.frScreenObjects, "BOTTOMLEFT", 0, 5)
	window.btEdit:EventAttach(Event.UI.Input.Mouse.Left.Click, function(self, handle) editAlert(window) end, "edit")
	kUtils.taskYield()
	
	window.btEditLayout = kUtils.buildButton("btEditLayout",window,35,100,kAlertTexts.btEditLayout)
	window.btEditLayout:SetPoint("TOPLEFT", window.btEdit, "TOPRIGHT")

	window.btConfig = kUtils.buildButton("btConfig", window, 35, 100,kAlertTexts.btGeneralConfiguration)
	window.btConfig:SetPoint("TOPLEFT", window.btEdit, "BOTTOMLEFT", 50, 0)
	
	window.btEditLayout:EventAttach(Event.UI.Button.Left.Press,
		function()	
			window:SetVisible(false)
			kAlert.config.mainFrame.clearAlert()
			if kAlert.config.layoutFrame == nil then
				buildLayoutFrame()
			end
			kAlert.config.layoutFrame.Open(window.alertSet)
		end, "Click")

	window.btConfig:EventAttach(Event.UI.Button.Left.Press,
		function()
			kAlert.config.generalConfiguration()
		end, "Click")

	-- Alert Info Controls
	kUtils.taskYield("ebAlertName")
	window.ebAlertName = kUtils.buildEditBox("ebAlertName",window,20,200,kAlertTexts.ebAlertName .. ":")
	window.ebAlertName:SetPoint("TOPLEFT", window.btASRight, "TOPRIGHT", 10, 0)

	window.ebAlertLayer = kUtils.buildEditBoxInteger("ebAlertLayer",window,20,100,kAlertTexts.ebScreenLayer .. ":")
	window.ebAlertLayer:SetPoint ("TOPLEFT", window.ebAlertName, "TOPRIGHT", 10, 0)

	window.ckDisableAlert = kUtils.buildCheckBox("ckDisableAlert",window,20,180,kAlertTexts.ckDisableAlert)
	window.ckDisableAlert:SetPoint ("TOPLEFT", window.ebAlertLayer, "TOPRIGHT", 10, 0)
	
	-- Trigger Info
	kUtils.taskYield("tbAlertTypes")
	window.tbAlertTypes = kUtils.buildToggleBox("tbAlertTypes",window, 20, 200, kAlert.config.evaluationTypes)
	window.tbAlertTypes:SetPoint("TOPLEFT", window.ebAlertName, "BOTTOMLEFT", 0, 5)
	function window.tbAlertTypes.change()
		local checkType = window.tbAlertTypes.getSelected()
		if checkType == 1 then
			window.ebAlertItem:SetVisible(true)
			window.ebAlertItem.setLabel(kAlertTexts.buff .. ":")
			window.tbResourceTypes:SetVisible(false)
			window.ebBuffLength:SetVisible(true)
			window.ckSelfCast:SetVisible(true)
			window.ckInterruptible:SetVisible(false)
			window.tbUnit:SetVisible(true)
			window.tbUnit:SetPoint("TOPLEFT", window.ckSelfCast, "BOTTOMLEFT", 0, 5)
			window.tbAlertToggle:SetVisible(true)
			window.tbAlertToggle.setOptions({kAlertTexts.tbAlertToggleActive,kAlertTexts.tbAlertToggleMissing})
			window.tbAlertToggle:SetPoint("TOPLEFT", window.tbRelation, "BOTTOMLEFT", 0, 5)
			window.tbResourceToggle:SetVisible(false)
			window.ebStacks:SetVisible(true)
			window.ebValue:SetVisible(false)
			window.ckCombatOnly:SetPoint("TOPLEFT", window.ebValue, "BOTTOMLEFT", 0, 5)
			window.ckTimer:SetVisible(true)
		elseif checkType == 2 then
			window.ebAlertItem:SetVisible(true)
			window.ebAlertItem.setLabel(kAlertTexts.ability .. ":")
			window.tbResourceTypes:SetVisible(false)
			window.ebBuffLength:SetVisible(false)
			window.ckSelfCast:SetVisible(false)
			window.ckInterruptible:SetVisible(false)
			window.tbUnit:SetVisible(false)
			window.tbUnit.setSelected(1)
			window.tbRelation.setSelected(0)
			window.tbAlertToggle:SetVisible(true)
			window.tbAlertToggle.setOptions({kAlertTexts.tbAlertToggleReady,kAlertTexts.tbAlertToggleCooldown})
			window.tbAlertToggle:SetPoint("TOPLEFT", window.ebAlertItem, "BOTTOMLEFT", 0, 5)
			window.tbResourceToggle:SetVisible(false)
			window.ebStacks:SetVisible(false)
			window.ebValue:SetVisible(false)
			window.ckCombatOnly:SetPoint("TOPLEFT", window.tbAlertToggle, "BOTTOMLEFT", 0, 5)
			window.ckTimer:SetVisible(true)
		elseif checkType == 3 then
			window.ebAlertItem:SetVisible(false)
			window.tbResourceTypes:SetVisible(true)
			window.ebBuffLength:SetVisible(false)
			window.ckSelfCast:SetVisible(false)
			window.ckInterruptible:SetVisible(false)
			window.tbUnit:SetVisible(true)
			window.ckInterruptible:SetVisible(false)
			window.tbUnit:SetPoint("TOPLEFT", window.tbResourceTypes, "BOTTOMLEFT", 0, 5)
			window.tbAlertToggle:SetVisible(false)
			window.tbResourceToggle:SetVisible(true)
			window.tbResourceToggle:SetPoint("TOPLEFT", window.tbRelation, "BOTTOMLEFT", 0, 5)
			window.ebStacks:SetVisible(false)
			window.ebValue:SetVisible(true)
			window.ckCombatOnly:SetPoint("TOPLEFT", window.ebValue, "BOTTOMLEFT", 0, 5)
			window.ckTimer:SetVisible(false)
			window.ckTimer:SetChecked(false)
		elseif checkType == 4 then
			window.ebAlertItem:SetVisible(true)
			window.ebAlertItem.setLabel(kAlertTexts.ability .. ":")
			window.tbResourceTypes:SetVisible(false)
			window.ebBuffLength:SetVisible(false)
			window.ckSelfCast:SetVisible(false)
			window.ckInterruptible:SetVisible(true)
			window.tbUnit:SetVisible(true)
			window.tbUnit:SetPoint("TOPLEFT", window.ckInterruptible, "BOTTOMLEFT", 0, 5)
			window.tbAlertToggle:SetVisible(false)
			window.tbResourceToggle:SetVisible(false)
			window.ebStacks:SetVisible(false)
			window.ebValue:SetVisible(false)
			window.ckCombatOnly:SetPoint("TOPLEFT", window.tbRelation, "BOTTOMLEFT", 0, 5)
			window.ckTimer:SetVisible(false)
			window.ckTimer:SetChecked(false)
		end
		window.btTextVars:SetEnabled(checkType == 1)
		window.tbAlertToggle.change()
	end

	kUtils.taskYield("ebAlertItem")
	window.ebAlertItem = kUtils.buildEditBox("ebAlertItem", window, 20, 200, kAlertTexts.ability .. ":")
	window.ebAlertItem:SetPoint("TOPLEFT", window.tbAlertTypes, "BOTTOMLEFT", 0, 5)
	
	local function updateDefaultImage()
		local itemName = string.split(window.ebAlertItem.text:GetText(), ",")[1]
		if kAlertGlobalItems[itemName] and kAlertGlobalItems[itemName].icon then
			window.ebImage.setDefault(kAlertGlobalItems[itemName].icon)
		else
			window.ebImage.clear()
		end	
	end
	
	function window.ebAlertItem.text.Event:KeyFocusLoss()
		window.frItemDrop:SetVisible(false)
	end

	function window.ebAlertItem.text.Event:KeyUp()
		local itemName = window.ebAlertItem.text:GetText()
		
		kUtils.queueTask(function()
			if itemName ~= nil and string.len(itemName) > 0 then
				if window.ebAlertItem.label:GetText() == kAlertTexts.buff .. ":" then
					local pos = string.find(string.reverse(itemName),",")
					if pos ~= nil then itemName = string.sub(itemName,2+string.len(itemName)-pos) end
				end
				if string.len(itemName) > 0 then
					window.frItemDrop.clearList()
					kUtils.taskYield()
					
					local exactMatch = false
					for id, _ in kUtils.pairsByKeys(kAlertGlobalItems) do
						if string.prefix(id:upper(), itemName:upper()) then
							if itemName == id then exactMatch = true end
							window.frItemDrop.addItem(id)
							kUtils.taskYield()
						end
						if window.frItemDrop.itemCount == 10 then break end
					end
					window.frItemDrop:SetVisible(window.frItemDrop.itemCount > 1 or (window.frItemDrop.itemCount == 1 and not exactMatch))
				end
			else
				window.frItemDrop:SetVisible(false)
			end
			updateDefaultImage()
		end)
	end
	
	function window.ebAlertItem.text.Event:LeftUp()
		local itemType, held = Inspect.Cursor()
		if itemType == "ability" then
			local details = Inspect.Ability.New.Detail(held)
			if details then
				local text = window.ebAlertItem.text:GetText()
				if string.suffix(text, ",") then
					text = text .. details.name
				else
					text = details.name
				end
				window.ebAlertItem.text:SetText(text)
				window.ebAlertItem.text:SetKeyFocus(true)
				window.ebAlertItem.text:SetCursor(string.len(text))
				updateDefaultImage()
			end
			Command.Cursor(nil)
		end
	end
	
	window.frItemDrop = kUtils.buildListPane("frItemDrop",window, 200,200)
	window.frItemDrop:SetPoint("TOPRIGHT", window.ebAlertItem.text, "BOTTOMRIGHT", 0, 0)
	window.frItemDrop:SetBackgroundColor(0, 0, 0, 1)
	window.frItemDrop:SetLayer(2)
	window.frItemDrop:SetVisible(false)
	
	function window.frItemDrop.click(button)
	
		if window.frItemDrop.lastSelected == window.frItemDrop.getSelected() and window.frItemDrop.lastSelectedTime == math.floor(Inspect.Time.Real()) then
			local itemPre = ""
			if window.ebAlertItem.label:GetText() == kAlertTexts.buff .. ":" then
				local itemName = window.ebAlertItem.text:GetText()
				if itemName ~= nil and string.len(itemName) > 0 then
					local pos = string.find(string.reverse(itemName),",")
					if pos ~= nil then itemPre = string.sub(itemName,1,string.len(itemName)-pos) .. "," end
				end
			end
			window.ebAlertItem.text:SetText(itemPre .. window.frItemDrop.getSelected())
			window.ebAlertItem.text.Event:KeyUp()
			window.ebAlertItem.text:SetCursor(string.len(window.ebAlertItem.text:GetText()))
			window.frItemDrop:SetVisible(false)
		else
			window.frItemDrop.lastSelected = window.frItemDrop.getSelected()
		end
		
		window.frItemDrop.lastSelectedTime = math.floor(Inspect.Time.Real())
		
	end

	kUtils.taskYield("tbResourceTypes")
	window.tbResourceTypes = kUtils.buildToggleBox("tbResourceTypes",window, 20, 200, kAlert.config.recources)
	window.tbResourceTypes:SetPoint("TOPLEFT", window.tbAlertTypes, "BOTTOMLEFT", 0, 5)

	kUtils.taskYield("ebBuffLength")
	window.ebBuffLength = kUtils.buildEditBoxInteger("ebBuffLength",window,20,200,kAlertTexts.buff .. " " .. kAlertTexts.ebTimerLength .. ":")
	window.ebBuffLength:SetPoint("TOPLEFT", window.ebAlertItem, "BOTTOMLEFT", 0, 5)
	window.ebBuffLength.text:SetText("")
	
	kUtils.taskYield("ckInterruptible")
	window.ckInterruptible = kUtils.buildCheckBox("ckInterruptible", window, 20, 200, kAlertTexts.ckInterruptible)
	window.ckInterruptible:SetPoint("TOPLEFT", window.ebAlertItem, "BOTTOMLEFT", 0, 5)
	
	kUtils.taskYield("ckSelfCast")
	window.ckSelfCast = kUtils.buildCheckBox("ckSelfCast", window, 20, 200, kAlertTexts.ckSelfCast)
	window.ckSelfCast:SetPoint("TOPLEFT", window.ebBuffLength, "BOTTOMLEFT", 0, 5)

	-- Trigger Condition
	kUtils.taskYield("tbUnit")
	window.tbUnit = kUtils.buildToggleBox("tbUnit",window, 20, 100, kAlert.config.units,2)
	window.tbUnit:SetPoint("TOPLEFT", window.ckSelfCast, "BOTTOMLEFT", 0, 5)
	
	kUtils.taskYield("tbRelation")
	window.tbRelation = kUtils.buildToggleBox("tbRelation",window.tbUnit, 20, 100, {kAlertTexts.ckFriend,kAlertTexts.ckFoe},2,true)
	window.tbRelation:SetPoint("TOPLEFT", window.tbUnit, "BOTTOMLEFT", 0, 5)
	
	window.tbAlertToggle = kUtils.buildToggleBox("tbAlertToggle",window, 20, 100, {kAlertTexts.tbAlertToggleAbove,kAlertTexts.tbAlertToggleBelow},2)
	window.tbAlertToggle:SetPoint("TOPLEFT", window.tbRelation, "BOTTOMLEFT", 0, 5)
	function window.tbAlertToggle.change()
		local checkType = window.tbAlertTypes.getSelected()
		local toggleType = window.tbAlertToggle.getSelected()
		if checkType == toggleType then
			window.ckTimer.label:SetText(kAlertTexts.ckTimerTimer)
			window.ebTimerLength:SetVisible(false)
		else
			window.ckTimer.label:SetText(kAlertTexts.ckTimerWarning)
			window.ebTimerLength:SetVisible(true)
		end
	end
	
	--window.dlResource = UIX.CreateDropdownList("dlResource", window)
	--window.dlResource:SetPoint("TOPLEFT", window.tbUnit, "BOTTOMLEFT", 0, 5)
	--window.dlResource:SetWidth(200)
	--window.dlResource:SetItems(kAlert.config.recources)
	
	kUtils.taskYield("tbResourceToggle")
	window.tbResourceToggle = kUtils.buildToggleBox("tbResourceToggle",window, 20, 100, {kAlertTexts.tbAlertToggleAbove,kAlertTexts.tbAlertToggleBelow,kAlertTexts.tbAlertToggleRange},2)
	window.tbResourceToggle:SetPoint("TOPLEFT", window.tbUnit, "BOTTOMLEFT", 0, 5)
	window.tbResourceToggle:SetVisible(false)

	window.ebStacks = kUtils.buildEditBoxInteger("ebStacks", window, 20, 200, kAlertTexts.ebStacks .. ":")
	window.ebStacks:SetPoint("TOPLEFT", window.tbAlertToggle, "BOTTOMLEFT", 0, 5)

	window.ebValue = kUtils.buildEditBox("ebValue", window, 20, 200, kAlertTexts.ebValue .. ":")
	window.ebValue:SetPoint("TOPLEFT", window.tbResourceToggle, "BOTTOMLEFT", 0, 5)
	
	window.ckCombatOnly = kUtils.buildCheckBox("ckCombatOnly",window, 20, 200, kAlertTexts.ckCombatOnly)
	window.ckCombatOnly:SetPoint("TOPLEFT", window.ebValue, "BOTTOMLEFT", 0, 5)
	
	-- Display Controls
	-- Display Image
	window.ebImage = kUtils.buildImageBox("ebImage", window, 200, 200)
	window.ebImage:SetPoint("TOPLEFT", window.tbAlertTypes, "TOPRIGHT", 10, 0)
	window.ebImage:SetLayer(-1)
	window.ebImage.count = 75
	
	function window.ebImage.clear()
		window.ebImage.defSorce = nil
		window.ebImage.defImage = nil
		window.ckDefaultImage:SetVisible(false)
		window.ckDefaultImage:SetChecked(false)
		window.ebImage.setImageIndex(1)
	end
	
	function window.ebImage.setDefault(image)
		window.ebImage.defSorce = "Rift"
		window.ebImage.defImage = image
		if window.ebImage.index <= 1 then
			window.ebImage.setImageCustom("Rift", image)
			window.ckDefaultImage:SetChecked(true)
		end
		window.ckDefaultImage:SetVisible(true)
	end
	
	function window.ebImage.setImageIndex(index)
		window.ebImage.index = index
		window.ebImage.setImage("kAlert", string.format("images\\Aura-%d.dds", window.ebImage.index))
		window.btImageBack:SetVisible(index > 1)
		window.btImageNext:SetVisible(index < window.ebImage.count)
	end
	
	function window.ebImage.setImageCustom(source, image)
		window.ebImage.index = 0
		window.ebImage.setImage(source, image)
		window.btImageBack:SetVisible(false)
		window.btImageNext:SetVisible(false)
	end
	
	window.ckDefaultImage = kUtils.buildCheckBox("ckDefaultImage",window, 20, 195, kAlertTexts.ckUseDefaultImage)
	window.ckDefaultImage:SetPoint("TOPLEFT", window.ebImage, "TOPLEFT", 5, 2)
	window.ckDefaultImage.label:SetBackgroundColor(0, 0, 0, 0.5)
	window.ckDefaultImage:SetVisible(false)

	function window.ckDefaultImage.Event:CheckboxChange()
		if window.ckDefaultImage:GetChecked() then
			window.ebImage.setImageCustom(window.ebImage.defSorce, window.ebImage.defImage)
		else
			window.ebImage.setImageIndex(1)
		end
	end
	
	kUtils.taskYield("btImageBack")
	window.btImageBack = kUtils.buildLabel("btImageBack",window,35,30,"<")
	window.btImageBack:SetBackgroundColor(0, 0, 0, 0.5)
	window.btImageBack:SetPoint ("LEFTCENTER", window.ebImage, "LEFTCENTER",1,0)

	window.btImageBack:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			if window.ebImage.index > 1 then
				window.ebImage.setImageIndex(window.ebImage.index - 1)
			end
		end, "Click")

	window.btImageNext = kUtils.buildLabel("btImageNext",window,35,30,">")
	window.btImageNext:SetBackgroundColor(0, 0, 0, 0.5)
	window.btImageNext:SetPoint("RIGHTCENTER", window.ebImage, "RIGHTCENTER",-1,0)
	
	window.btImageNext:EventAttach(Event.UI.Input.Mouse.Left.Click,
		function()
			if window.ebImage.index < window.ebImage.count then
				window.ebImage.setImageIndex(window.ebImage.index + 1)
			end
		end, "Click")
	
	window.ebImage.setImageIndex(1)
	
	kUtils.taskYield("ebCustomImage")
	window.ebCustomImage = kUtils.buildEditBox("ebCustomImage",window,20,200,kAlertTexts.ebCustomImage .. ":")
	window.ebCustomImage:SetPoint("TOPLEFT", window.ebImage, "BOTTOMLEFT", 0, 5)
	function window.ebCustomImage.text.Event:KeyUp()
		
		if string.len(self:GetText()) > 0 then
			window.ebImage.setImageCustom("kAlert", "custom\\" .. self:GetText())
		else
			if window.ebImage.index >= 1 then
				window.ebImage.setImageIndex(window.ebImage.index)
			elseif window.ebImage.index == 0 and window.ebImage.defSorce ~= nil then
				window.ebImage.setImageCustom(window.ebImage.defSorce, window.ebImage.defImage)
			else
				window.ebImage.setImageIndex(1)
			end
		end

	end	
	
	kUtils.taskYield("ebImageX")
	window.ebImageX = kUtils.buildEditBoxInteger("ebImageX",window,20,95,kAlertTexts.ebImageX .. ":")
	window.ebImageX:SetPoint("TOPLEFT", window.ebCustomImage, "BOTTOMLEFT", 0, 5)
	
	window.ebImageY = kUtils.buildEditBoxInteger("ebImageY",window,20,95,kAlertTexts.ebImageY .. ":")
	window.ebImageY:SetPoint("TOPLEFT", window.ebImageX, "TOPRIGHT", 10, 0)

	window.ebImageScale = kUtils.buildEditBox("ebImageScale",window,20,95,kAlertTexts.ebImageScale .. ":")
	window.ebImageScale:SetPoint("TOPLEFT", window.ebImageX, "BOTTOMLEFT", 0, 5)

	kUtils.taskYield("ebImageOpacity")
	window.ebImageOpacity = kUtils.buildEditBoxInteger("ebImageOpacity",window,20,95,kAlertTexts.ebOpacity .. ":")
	window.ebImageOpacity:SetPoint("TOPLEFT", window.ebImageScale, "TOPRIGHT", 10, 0)

	-- Display Text
	kUtils.taskYield("ebText")
	window.ebText = kUtils.buildEditBox("ebText",window,20,185,kAlertTexts.ebText .. ":")
	window.ebText:SetPoint("TOPLEFT", window.ebImage, "TOPRIGHT", 10, 0)
	
	window.btTextVars = UIX.CreateImageButton("btTextVars", window)
	window.btTextVars:SetTextures("Rift", "btn_expand (normal).dds", "btn_expand (over).dds", "btn_expand (click).dds")
	window.btTextVars:SetPoint("CENTERLEFT", window.ebText, "CENTERRIGHT", 3, 0)
	
	local function insertVariable(text)
		local tf = window.ebText.text

		local oldText = tf:GetText()
		local selStart, selEnd = tf:GetSelection()
		if selStart == nil then
			selStart = tf:GetCursor()
			if selStart == -1 then
				selStart = oldText:len()
			end
			selEnd = selStart
		end
		
		tf:SetText(oldText:sub(1, selStart) .. text .. oldText:sub(selEnd + 1))
		tf:SetCursor(selStart + text:len())
	end
	
	function window.btTextVars.Event:LeftClick()
		if not window.btTextVars:GetEnabled() then return end
		kUtils.showContextMenu(
		{
			{ "Caster", function() insertVariable("{caster}") end},
			{ "Stacks", function() insertVariable("{stacks}") end}
		})
	end

	kUtils.taskYield("ebTextOpacity")
	window.ebTextOpacity = kUtils.buildEditBoxInteger("ebTextOpacity",window.ebText,20,90,kAlertTexts.ebOpacity .. ":")
	window.ebTextOpacity:SetPoint("TOPLEFT", window.ebText, "BOTTOMLEFT", 0, 5)
	
	kUtils.taskYield("ebTextSize")
	window.ebTextSize = kUtils.buildEditBoxInteger("ebTextSize",window.ebText,20,90,kAlertTexts.ebSize .. ":")
	window.ebTextSize:SetPoint("TOPLEFT", window.ebTextOpacity, "BOTTOMLEFT", 0, 5)
	window.ebTextSize.text:SetText("30")

	window.tbTextInside = kUtils.buildToggleBox("tbTextInside",window.ebTextSize, 20, 90, {kAlertTexts.tbInsideInside,kAlertTexts.tbInsideOutside})
	window.tbTextInside:SetPoint("TOPLEFT", window.ebTextSize, "BOTTOMLEFT", 0, 5)

	kUtils.taskYield("tbTextLocation")
	window.tbTextLocation = kUtils.buildToggleBox("tbTextLocation",window.ebTextSize, 20, 100, {kAlertTexts.tbLocationCenter,kAlertTexts.tbLocationTop,kAlertTexts.tbLocationBottom,kAlertTexts.tbLocationLeft,kAlertTexts.tbLocationRight})
	window.tbTextLocation:SetPoint("TOPLEFT", window.ebTextOpacity, "TOPRIGHT", 10, 0)

	kUtils.taskYield("ebTextFont")
	window.ebTextFont = kUtils.buildEditBox("ebTextFont",window.ebText, 20, 200, kAlertTexts.ebTextFont .. ":")
	window.ebTextFont:SetPoint("TOPLEFT", window.tbTextInside, "BOTTOMLEFT", 0, 15)
	
	-- Display Color
	window.txtColor = kUtils.buildLabel("txtColor", window,15,50,kAlertTexts.lblColor .. ":")
	window.txtColor:SetPoint("TOPLEFT", window.ebTextFont, "BOTTOMLEFT", 0, 5)

	kUtils.taskYield("frColor")
	window.frColor = kUtils.buildFrame("frColor", window, 20, 140)
	window.frColor:SetPoint("TOPLEFT", window.txtColor, "TOPRIGHT", 10, 0)
	function window.frColor.setColor()
		local red = window.slRed:GetPosition()
		local green = window.slGreen:GetPosition()
		local blue = window.slBlue:GetPosition()
		window.frColor:SetBackgroundColor(red / 100, green / 100, blue / 100, 1)
	end

	kUtils.taskYield("ebRed")
	window.ebRed = kUtils.buildEditBoxInteger("ebRed",window,20,50,kAlertTexts.ebRed .. ":", 28)
	window.ebRed.text:SetText("100")
	window.ebRed:SetPoint("TOPLEFT", window.txtColor, "BOTTOMLEFT", 0, 5)
	
	window.ebRed.text:EventAttach(Event.UI.Textfield.Change,
		function(self, handle)
			local val = tonumber(self:GetText())
			if val then
				val = math.min(100, math.max(0, math.floor(val)))
				window.slRed:SetPosition(val)
			end
			window.frColor.setColor()
		end, "TextChange")
	
	window.slRed = kUtils.buildSlider("slRed",window.ebRed,20,140,0,100)
	window.slRed:SetPoint("CENTERLEFT", window.ebRed, "CENTERRIGHT", 10, 5)
	
	window.slRed:EventAttach(Event.UI.Slider.Change,
		function()
			window.ebRed.text:SetText(tostring(window.slRed:GetPosition()))
			window.frColor.setColor()
		end, "SliderChange")

	kUtils.taskYield("ebGreen")
	window.ebGreen = kUtils.buildEditBoxInteger("ebGreen",window,20,50,kAlertTexts.ebGreen .. ":", 28)
	window.ebGreen.text:SetText("100")
	window.ebGreen:SetPoint("TOPLEFT", window.ebRed, "BOTTOMLEFT", 0, 5)
	
	window.ebGreen.text:EventAttach(Event.UI.Textfield.Change,
		function(self, handle)
			local val = tonumber(self:GetText())
			if val then
				val = math.min(100, math.max(0, math.floor(val)))
				window.slGreen:SetPosition(val)
			end	
			window.frColor.setColor()
		end, "TextChange")
	
	window.slGreen = kUtils.buildSlider("slGreen",window.ebGreen,20,140,0,100)
	window.slGreen:SetPoint("CENTERLEFT", window.ebGreen, "CENTERRIGHT", 10, 5)
	
	window.slGreen:EventAttach(Event.UI.Slider.Change,
		function()	
			window.ebGreen.text:SetText(tostring(window.slGreen:GetPosition()))
			window.frColor.setColor()
		end, "SliderChange")

	kUtils.taskYield("ebBlue")
	window.ebBlue = kUtils.buildEditBoxInteger("ebBlue",window,20,50,kAlertTexts.ebBlue .. ":", 28)
	window.ebBlue.text:SetText("100")
	window.ebBlue:SetPoint("TOPLEFT", window.ebGreen, "BOTTOMLEFT", 0, 5)
	
	window.ebBlue.text:EventAttach(Event.UI.Textfield.Change,
		function(self, handle)	
			local val = tonumber(self:GetText())
			if val then
				val = math.min(100, math.max(0, math.floor(val)))
				window.slBlue:SetPosition(val)
			end
			window.frColor.setColor()
		end, "TextChange")
	
	window.slBlue = kUtils.buildSlider("slBlue",window.ebBlue,20,140,0,100)
	window.slBlue:SetPoint("CENTERLEFT", window.ebBlue, "CENTERRIGHT", 10, 5)
	
	window.slBlue:EventAttach(Event.UI.Slider.Change,
		function()
			window.ebBlue.text:SetText(tostring(window.slBlue:GetPosition()))
			window.frColor.setColor()
		end, "SliderChange")
	
	window.frColor.setColor()
	
	-- Display Timer
	kUtils.taskYield("ckTimer")
	window.ckTimer = kUtils.buildCheckBox("ckTimer",window.ebAlertItem, 20, 90, kAlertTexts.ckTimerTimer)
	window.ckTimer:SetPoint("TOPLEFT", window.ebBlue, "BOTTOMLEFT", 0, 10)
	
	function window.ckTimer.Event:CheckboxChange()
		window.ebTimerSize:SetVisible(window.ckTimer:GetChecked())
	end

	window.ebTimerSize = kUtils.buildEditBoxInteger("ebTimerSize",window.ebAlertItem,20,90,kAlertTexts.ebSize .. ":")
	window.ebTimerSize:SetPoint("TOPLEFT", window.ckTimer, "BOTTOMLEFT", 0, 5)
	window.ebTimerSize.text:SetText("30")
	window.ebTimerSize:SetVisible(false)

	kUtils.taskYield("tbTimerInside")
	window.tbTimerInside = kUtils.buildToggleBox("tbTimerInside",window.ebTimerSize, 20, 90, {kAlertTexts.tbInsideInside,kAlertTexts.tbInsideOutside})
	window.tbTimerInside:SetPoint("TOPLEFT", window.ebTimerSize, "BOTTOMLEFT", 0, 5)

	kUtils.taskYield("tbTimerLocation")
	window.tbTimerLocation = kUtils.buildToggleBox("tbTimerLocation",window.ebTimerSize, 20, 100, {kAlertTexts.tbLocationCenter,kAlertTexts.tbLocationTop,kAlertTexts.tbLocationBottom,kAlertTexts.tbLocationLeft,kAlertTexts.tbLocationRight})
	window.tbTimerLocation:SetPoint("TOPLEFT", window.ckTimer.label, "TOPRIGHT", 10, 0)

	kUtils.taskYield("ebTimerLength")
	window.ebTimerLength = kUtils.buildEditBoxInteger("ebTimerLength",window.ebTimerSize,20,90,kAlertTexts.ebTimerLength .. ":")
	window.ebTimerLength:SetPoint("TOPLEFT", window.tbTimerInside, "BOTTOMLEFT", 0, 5)
	window.ebTimerLength.text:SetText("5")
	
	-- Display Base
	kUtils.taskYield("btSave")
	window.btSave = kUtils.buildButton("btSave",window,35,100,kAlertTexts.btSave)
	window.btSave:SetPoint("BOTTOMLEFT", window.btEditLayout, "BOTTOMRIGHT", 440, 10)
	window.btSave:EventAttach(Event.UI.Input.Mouse.Left.Click, function(self, handle) saveAlert(window) end, "save") 

	window.btClear = kUtils.buildButton("btClear",window,35,100,kAlertTexts.btClear)
	window.btClear:SetPoint ("TOPLEFT", window.btSave, "TOPRIGHT")
	
	function window.clearAlert()
		window.oldAlertName = nil
		window.setStatus("")
		window.ebAlertName.text:SetText("")
		window.ebAlertLayer.text:SetText("1")
		window.tbUnit.setSelected(1)
		window.tbAlertTypes.setSelected(1)
		window.tbAlertToggle.setSelected(1)
		window.tbResourceToggle.setSelected(1)
		window.tbResourceTypes.setSelected(1)
		window.ebAlertItem.text:SetText("")
		window.ebValue.text:SetText("")
		window.ckSelfCast:SetChecked(false)
		window.ebBuffLength.text:SetText("")
		window.ebImage.clear()
		window.ebCustomImage.text:SetText("")
		window.ebImageX.text:SetText("0")
		window.ebImageY.text:SetText("0")
		window.ebImageScale.text:SetText("1")
		window.ebImageOpacity.text:SetText("100")
		window.ebText.text:SetText("")
		window.ebTextOpacity.text:SetText("100")
		window.ebTextFont.text:SetText("")
		window.slRed:SetPosition(100)
		window.slGreen:SetPosition(100)
		window.slBlue:SetPosition(100)
		window.ebRed.text:SetText("100")
		window.ebGreen.text:SetText("100")
		window.ebBlue.text:SetText("100")
		window.frColor.setColor()
		window.ebTextSize.text:SetText("30")
		window.tbTextLocation.setSelected(1)
		window.tbTextInside.setSelected(1)
		window.ckTimer:SetChecked(false)
		window.ebTimerSize.text:SetText("30")
		window.tbTimerLocation.setSelected(1)
		window.tbTimerInside.setSelected(1)
		window.ebTimerLength.text:SetText("5")
		window.tbAlertTypes.change()
		window.frScreenObjects.clearSelected()
		window.ckDisableAlert:SetChecked(false)
		window.ckCombatOnly:SetChecked(false)
		window.tbRelation.setSelected(0)
		window.ebAlertName.text:SetKeyFocus(true)
	end
	
	window.btClear:EventAttach(Event.UI.Button.Left.Press, window.clearAlert, "Clear")
	
	-- System Elements
	window.btClose = kUtils.buildButton("btClose",window,35,100,kAlertTexts.btClose,"close")
	window.btClose:SetPoint("TOPRIGHT", window, "TOPRIGHT", -9, 16)
	
	function window.btClose.Event:LeftPress()
		window.setStatus("")
		window:SetVisible(false)
		if kAlert.config.shareFrame then
			kAlert.config.shareFrame:SetVisible(false)
		end
		
		kAlert.changeHandler.changeOccured = true
		window.clearAlert()
		
		if window.alertSet.setsTable == kAlertAlerts.sets then
			if kAlertSet == "auto" then
				if kAlert.effectiveAlertSet() ~= window.alertSet.active then
					print(string.format(kAlertTexts.msgActiveSetUnchanged, window.alertSet.active))
				end
			elseif kAlertSet ~= window.alertSet.active then
				kAlertSet = window.alertSet.active
				kAlert.printActiveSets()
			end
		end

		kAlert.alertSet:Load(kAlert.effectiveAlertSet())
		kAlert.alertSubSet:Load(kAlertSubSet)

		kAlert.screenObjects:refresh()
		window.ebAlertName.text:SetKeyFocus(false)

		kAlert.config.active = false
	end
	

	window.ckScanBuffs = kUtils.buildCheckBox("ckScanBuffs",window,20,180,kAlertTexts.ckScanBuffs,true)
	window.ckScanBuffs:SetPoint ("BOTTOMRIGHT", window, "BOTTOMRIGHT", -30, -20)
	
	function window.ckScanBuffs.Event:CheckboxChange()
		if window.ckScanBuffs:GetChecked() then
			kAlert.systemScanner.start()
		else
			kAlert.systemScanner.stop()
		end
	end

	-- Status Output
	window.txtStatus = kUtils.buildLabel("txtStatus", window, 15, 450, "")
	window.txtStatus:SetPoint("TOPLEFT", window.btConfig, "TOPRIGHT", 10, 5)

	function window.setStatus(message)
		window.txtStatus:SetText(message)
		--if string.len(message) > 0 then print(message) end
	end

	function window.getActiveAlertName()
		if string.len(window.ebAlertName.text:GetText()) > 0 then
			return window.ebAlertName.text:GetText()
		elseif string.len(window.frScreenObjects.getSelected()) > 0 then
			return window.frScreenObjects.getSelected()
		end
	end
	
	kUtils.taskYield("buildMainFrame end")
	
	window:SetVisible(true)

	kAlert.config.mainFrame = window
	
end

local function buildMessageBox()
	local context = UI.CreateContext("messageBox")
	local window = UIX.CreateStretchedTexture("messageBox", context)
	window:SetTexture("Rift", "window_popup_alpha.png.dds")
	window:SetEdges(20, 22, 15, 22)
	
	window.text = UI.CreateFrame("Text", "messageBoxText", window)
	window.text:SetPoint("TOPCENTER", window, "TOPCENTER", -3, 7)
	window.text:SetFontSize(17.5)
	
	window.buttons = {}
	
	function window:SetMessageBox(text, buttons, position, callback)
		window.text:SetText(text)
		UIX.Frame.ClearPoints(window)
		window:SetPoint(unpack(position))
		kUtils.makeMovable(window)
		window:SetWidth(math.max(#buttons * 166 + 35, 50 + window.text:GetWidth()))
		window:SetHeight(94 + window.text:GetHeight())
		
		for i, _ in ipairs(buttons) do
			if window.buttons[i] == nil then
				local button = UI.CreateFrame("RiftButton", "button" .. tostring(i), window)
				button:SetWidth(176)
				button:SetHeight(38)
				window.buttons[i] = button
			end
		end
		
		for i = 1, #buttons do
			local button = window.buttons[i]
			button:SetText(buttons[i])
			button:SetVisible(true)
			button:SetPoint("TOPLEFT", window.text, "BOTTOMCENTER", 
				(-83 * #buttons) + (i - 1) * 166, 20)	
			
			if type(callback) == "table" then
				button.Event.LeftClick = callback[i]
			else
				function button.Event:LeftClick()
					window:SetVisible(false)
					if callback then
						callback(i)
					end
				end
			end
		end
		
		for i = #buttons + 1, table.getn(window.buttons) do
			window.buttons[i]:SetVisible(false)
		end
	
	end
	
	return window
end

function kAlert.config.movers.addObject(id)

	local iID = tostring(id)
	local object = UI.CreateFrame("Frame", "objectMoverFrame" .. iID, kAlert.context)
	object:SetWidth(75)
	object:SetHeight(75)
	object:SetPoint ("TOPLEFT", kAlert.context, "TOPLEFT")
	object:SetVisible(false)
	object:SetBackgroundColor(0, 0, 0, 0.5)
	object.movable = true
	object.target = nil
	
	function object.clearTarget()
		object.target = nil
		object:SetVisible(false)
	end
	
	function object.setTarget(target)
		object.movable = true
		object.target = target
		object:SetVisible(true)
		object:SetWidth(target:GetWidth())
		object:SetHeight(target:GetHeight())
		object:SetPoint("TOPLEFT", target, "TOPLEFT")
	end
	
	function object.Event:LeftDown()
		self.MouseDown = self.movable
		mouseData = Inspect.Mouse()
		self.MyStartX = self:GetLeft()
		self.MyStartY = self:GetTop()
		self.StartX = mouseData.x - self.MyStartX
		self.StartY = mouseData.y - self.MyStartY
	end
	
	function object.Event:MouseMove(mouseX, mouseY)
		if self.MouseDown then
			self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", math.floor(mouseX - self.StartX), math.floor(mouseY - self.StartY))
			if object.target ~= nil then
				object.target:SetPoint("TOPLEFT", UIParent, "TOPLEFT", math.floor(mouseX - self.StartX), math.floor(mouseY - self.StartY))
			end
		end
	end
	
	function object.Event:LeftUp()
		self.MouseDown = false
	end
	
	return object
	
end

function kAlert.config.formatSetExport(set)
	local exportData = {}
	for id, details in pairs(set.alerts) do
		local serializedData, err = kAlert.config.formatAlertExport(details)
		if not serializedData then
			print(err)
		else
			table.insert(exportData, serializedData)
		end
	end
	return table.concat(exportData, "|")
end

function kAlert.config.formatAlertExport(alertData, excludeName)
	local exportData = {}
	if alertData ~= nil then
		if excludeName then
			table.insert(exportData, "")
		else
			table.insert(exportData, alertData.name)
		end
		table.insert(exportData, alertData.layer)
		table.insert(exportData, kUtils.booltostring(alertData.active))
		table.insert(exportData, alertData.unit)
		table.insert(exportData, alertData.type)
		table.insert(exportData, kUtils.booltostring(alertData.typeToggle))
		table.insert(exportData, kUtils.booltostring(alertData.combatOnly))
		table.insert(exportData, kUtils.booltostring(alertData.selfCast))
		table.insert(exportData, alertData.itemName or "")
		table.insert(exportData, alertData.itemId or "")
		table.insert(exportData, alertData.itemLength)
		table.insert(exportData, alertData.itemValue or "")
		table.insert(exportData, kUtils.booltostring(alertData.itemValuePercent))
		table.insert(exportData, kUtils.booltostring(alertData.range))
		table.insert(exportData, alertData.rangeLow)
		table.insert(exportData, alertData.rangeHigh)
		table.insert(exportData, alertData.imageSource)
		table.insert(exportData, alertData.image)
		table.insert(exportData, alertData.imageX)
		table.insert(exportData, alertData.imageY)
		table.insert(exportData, alertData.imageHeight)
		table.insert(exportData, alertData.imageWidth)
		table.insert(exportData, alertData.imageScale)
		table.insert(exportData, alertData.imageOpacity)
		table.insert(exportData, alertData.text)
		table.insert(exportData, alertData.textLocation)
		table.insert(exportData, alertData.textOpacity)
		table.insert(exportData, alertData.textFont)
		table.insert(exportData, alertData.textRed)
		table.insert(exportData, alertData.textGreen)
		table.insert(exportData, alertData.textBlue)
		table.insert(exportData, alertData.textSize)
		table.insert(exportData, kUtils.booltostring(alertData.textInside))
		table.insert(exportData, kUtils.booltostring(alertData.timer))
		table.insert(exportData, alertData.timerLocation)
		table.insert(exportData, alertData.timerSize)
		table.insert(exportData, kUtils.booltostring(alertData.timerInside))
		table.insert(exportData, alertData.timerLength)
		table.insert(exportData, kUtils.booltostring(alertData.sound))
		table.insert(exportData, alertData.unitRelation)
		table.insert(exportData, kUtils.booltostring(alertData.interruptibleCast))
	end
	
	if #exportData == 41 then
		return table.concat(exportData, ";")
	else
		return nil, kAlertTexts.msgExportCorrupt
	end
end

function kAlert.config.formatSetImport(data, set, minLength)
	data = data:gsub("\n", "")
	local importData = string.split(data, "%s*%|%s*", true)
	for id, details in pairs(importData) do
		local alert, err = kAlert.config.formatAlertImport(details, minLength)
		if not err then
			set:Add(alert)
		end
	end
	kAlert.alertSet:Save()
end

function kAlert.config.formatAlertImport(data, minLength)
	local importData = string.split(data, ";")
	if #importData < (minLength or 39) then
		return nil, kAlertTexts.msgImportCorrupt
	end

	local whitespaceAllowed = { [1] = true, [9] = true, [17] = true, [18] = true, [25] = true, [28] = true }
	for i = 1, #importData do
		if not whitespaceAllowed[i] then
			importData[i] = importData[i]:gsub("%s", "")
		end
	end
	
	local alertData = {}
	alertData.name = importData[1]
	alertData.layer = tonumber(importData[2])
	alertData.active = kUtils.stringtobool(importData[3])
	alertData.unit = importData[4]
	alertData.type = tonumber(importData[5])
	alertData.typeToggle = kUtils.stringtobool(importData[6])
	alertData.combatOnly = kUtils.stringtobool(importData[7])
	alertData.selfCast = kUtils.stringtobool(importData[8])
	alertData.itemName = importData[9]
	
	if alertData.type == 3 then
	    -- Alert type 3 (Resource) uses the itemId to store the type of resource, which is an integer.
		alertData.itemId = tonumber(importData[10])
	else
		alertData.itemId = importData[10]
	end
	
	alertData.itemLength = tonumber(importData[11])
	alertData.itemValue = tonumber(importData[12])
	alertData.itemValuePercent = kUtils.stringtobool(importData[13])
	alertData.range = kUtils.stringtobool(importData[14])
	alertData.rangeLow = tonumber(importData[15])
	alertData.rangeHigh = tonumber(importData[16])
	alertData.imageSource = importData[17]
	alertData.image = importData[18]
	alertData.imageX = tonumber(importData[19])
	alertData.imageY = tonumber(importData[20])
	alertData.imageHeight = tonumber(importData[21])
	alertData.imageWidth = tonumber(importData[22])
	alertData.imageScale = tonumber(importData[23])
	alertData.imageOpacity = tonumber(importData[24])
	alertData.text = importData[25]
	alertData.textLocation = importData[26]
	alertData.textOpacity = tonumber(importData[27])
	alertData.textFont = importData[28]
	alertData.textRed = tonumber(importData[29])
	alertData.textGreen = tonumber(importData[30])
	alertData.textBlue = tonumber(importData[31])
	alertData.textSize = tonumber(importData[32])
	alertData.textInside = kUtils.stringtobool(importData[33])
	alertData.timer = kUtils.stringtobool(importData[34])
	alertData.timerLocation = importData[35]
	alertData.timerSize = tonumber(importData[36])
	alertData.timerInside = kUtils.stringtobool(importData[37])
	alertData.timerLength = tonumber(importData[38])
	alertData.sound = kUtils.stringtobool(importData[39])
	alertData.unitRelation = tonumber(importData[40]) or 0
	alertData.interruptibleCast = kUtils.stringtobool(importData[41] or "F")

	alertData.set = kAlert.alertSet.active

	if (alertData.type == 1 or alertData.type == 2) and alertData.itemId then
		alertData.itemId = string.gsub(alertData.itemId, " ", "")
		alertData.itemId = kAlert.convertAbilityId(alertData.itemId)
	end

	if alertData.type == 1 then
		if alertData.itemName ~= nil and alertData.imageSource == "Rift" then
			local itemName =  string.split(alertData.itemName, ",")[1]
			if kAlertGlobalItems[itemName] == nil then
				kAlertGlobalItems[itemName] = {ability = alertData.itemId, name = itemName, icon = alertData.image, update = true}
				print(string.format(kAlertTexts.msgNewBuff, itemName))
			end
		end
	elseif alertData.type == 2 then
		if alertData.itemName ~= nil and alertData.imageSource == "Rift" then
			if kAlertGlobalItems[alertData.itemName] == nil then
				kAlertGlobalItems[alertData.itemName] = {ability = alertData.itemId, name = alertData.itemName, icon = alertData.image, update = true}
				print(kAlertTexts.msgNewAbility .. ': ' .. alertData.itemName) -- .. '-' .. alertData.ability)
			end
		end
	end
	return alertData
end

function kAlert.config.main()
	kUtils.queueTask(function()
		kAlert.config.active = true
		if kAlert.config.mainFrame == nil then
			buildMainFrame()
		else
			kAlert.config.mainFrame:SetVisible(true)
		end
		kAlert.config.mainFrame.alertSet = private.AlertSet.Create(kAlertAlerts.sets)
		kAlert.config.mainFrame.alertSet:Load(kAlert.alertSet.active)
		kAlert.config.mainFrame.clearAlert()
		kAlert.config.mainFrame.frScreenObjects.fillList(kAlert.alertSet.alerts)
		kAlert.config.mainFrame.txtASNumber.updateText()
		kAlert.config.mainFrame.ckScanBuffs:SetChecked(kAlert.systemScanner.activeScanning)
	end, kAlert.debug and kAlert.profile)
end

function kAlert.config.generalConfiguration()
	kUtils.queueTask(function()
		if kAlert.config.generalConfigFrame == nil then
			buildGeneralConfigFrame()
		else
			kAlert.config.generalConfigFrame:SetVisible(true)
		end
	end, kAlert.debug and kAlert.profile)
end

function kAlert.config.about()
	if kAlert.config.aboutFrame == nil then
		buildAboutFrame()
	end
	kAlert.config.aboutFrame:SetVisible(true)
end

function kAlert.config.help()
	kUtils.queueTask(function()
		if kAlert.config.helpFrame == nil then
			buildHelpFrame()
		end
		kAlert.config.helpFrame:SetVisible(true)
	end)
end

function kAlert.config.importAlert()
	local alertSet = kAlert.config.mainFrame.alertSet

	if kAlert.config.importExportFrame == nil then
		buildImportExportFrame()
	end
	local window = kAlert.config.importExportFrame
	
	window.btImport:SetVisible(true)
	window.btCancel:SetPoint("LEFTCENTER", kAlert.config.importExportFrame.btImport, "RIGHTCENTER")
	
	function window.btImport.Event:LeftPress()
		local alertData, importError = kAlert.ImportAlert(window.ebData.text:GetText())
		if alertData then
			alertSet:Add(alertData)
			alertSet:Save()
			window.Close()
		else
			window.txtStatus:SetText(importError)
		end
	end
	
	window.Open(kAlertTexts.btImportAlert, kAlertTexts.txtImportAlert)
	window.ebData.text:SetKeyFocus(true)
end

function kAlert.config.importSet()
	local alertSet = kAlert.config.mainFrame.alertSet

	if kAlert.config.importExportFrame == nil then
		buildImportExportFrame()
	end
	local window = kAlert.config.importExportFrame
	
	window.btImport:SetVisible(true)
	window.btCancel:SetPoint("LEFTCENTER", window.btImport, "RIGHTCENTER")
	
	function window.btImport.Event:LeftPress()
		local _, importError = kAlert.ImportSet(window.ebData.text:GetText(), alertSet)
		if importError then
			window.txtStatus:SetText(importError)
			return
		end
		alertSet:Save()
		window.Close()
	end
	
	window.Open(kAlertTexts.btImportSet, kAlertTexts.txtImportSet)
	window.ebData.text:SetKeyFocus(true)
end

function kAlert.config.exportAlert()
	if kAlert.config.importExportFrame == nil then
		buildImportExportFrame()
	end
	local window = kAlert.config.importExportFrame

	local alertName = kAlert.config.mainFrame.getActiveAlertName()
	local alertData = kAlert.config.mainFrame.alertSet.alerts[alertName]
	local dataAlert, err = kAlert.ExportAlert(alertData)
	if err then
		print(err)
		return
	end

	window.btImport:SetVisible(false)
	window.btCancel:SetPoint("LEFTCENTER", window.btImport, "RIGHTCENTER", -60, 0)
	window.Open(kAlertTexts.btExportAlert, kAlertTexts.txtExportAlert, dataAlert, "", true)
end

function kAlert.config.exportSet()
	if kAlert.config.importExportFrame == nil then
		buildImportExportFrame()
	end
	local window = kAlert.config.importExportFrame
	
	local dataSet = kAlert.ExportSet(kAlert.config.mainFrame.alertSet)

	window.btImport:SetVisible(false)
	window.btCancel:SetPoint("LEFTCENTER", window.btImport, "RIGHTCENTER", -60, 0)
	
	window.Open(kAlertTexts.btExportSet, kAlertTexts.txtExportSet, dataSet, "", true)
end

function kAlert.config.moveAlert()
	if kAlert.config.alertCopyFrame == nil then
		buildAlertCopyFrame()
	end
	
	local alertName = kAlert.config.mainFrame.getActiveAlertName()
	local alertData = kAlert.config.mainFrame.alertSet.alerts[alertName]
	
	kAlert.config.alertCopyFrame.open(
		kAlertTexts.titleMoveAlert,
		kAlertTexts.lbMoveAlert,
		alertName,
		kAlert.alertSet.active,
		nil,
		kAlertTexts.btMove)
		
	kAlert.config.alertCopyFrame.callback = function(newAlertName, set, setsTable)
		if kAlert.config.mainFrame.alertSet == nil then return end
	
		alertData.name = newAlertName
		
		local targetSet = getAlertSet(set, setsTable)
		if targetSet.alerts[alertData.name] ~= nil then
			return false, kAlertTexts.statAlertAlreadyExists
		end
		
		kAlert.config.mainFrame.alertSet:Delete(alertName)
		kAlert.config.mainFrame.alertSet:Save()
		
		targetSet:Add(alertData)
		targetSet:Save()
		
		kAlert.config.mainFrame.clearAlert()
		kAlert.config.mainFrame.frScreenObjects.fillList(kAlert.config.mainFrame.alertSet.alerts)
		
		if kAlert.isAlertSetActive(kAlert.config.mainFrame.alertSet) or kAlert.isAlertSetActive(targetSet) then
			kAlert.screenObjects:refresh()
		end
		
		return true
	end
	
	kAlert.config.alertCopyFrame.cancelCallback = Utility.GlobalEmptyFunction
end

function kAlert.config.copyAlert()
	if kAlert.config.alertCopyFrame == nil then
		buildAlertCopyFrame()
	end
	
	local alertData = kUtils.tableCopy(
		kAlert.config.mainFrame.alertSet.alerts[kAlert.config.mainFrame.getActiveAlertName()])
	
	kAlert.config.alertCopyFrame.open(
		kAlertTexts.titleCopyAlert,
		kAlertTexts.lbCopyAlert,
		alertData.name,
		kAlert.alertSet.active,
		nil,
		kAlertTexts.btCopy)
		
	kAlert.config.alertCopyFrame.callback = function(newAlertName, set, setsTable)
		alertData.name = newAlertName
	
		local targetSet = getAlertSet(set, setsTable)
		if targetSet.alerts[alertData.name] ~= nil then
			return false, kAlertTexts.statAlertAlreadyExists
		end
		
		targetSet:Add(alertData)
		targetSet:Save()
			
		if kAlert.isAlertSetActive(targetSet) then
			kAlert.screenObjects:refresh()
		end
		
		return true
	end
	
	kAlert.config.alertCopyFrame.cancelCallback = Utility.GlobalEmptyFunction
	
	kAlert.config.alertCopyFrame:SetVisible(true)
end

function kAlert.config.sharedAlert()
	if kAlert.config.alertCopyFrame == nil then
		buildAlertCopyFrame()
	end
	
	-- Skip if a dialog is already open
	if kAlert.config.alertCopyFrame:GetVisible() then return end
	
	local alertData = kAlert.sharedAlerts[1][1]
	local from = kAlert.sharedAlerts[1][2]
	
	kAlert.config.alertCopyFrame.open(
		kAlertTexts.titleSharedAlert,
		string.format(kAlertTexts.lbSharedAlert, from),
		alertData.name,
		kAlert.alertSet.active,
		nil,
		kAlertTexts.btAdd)
		
	kAlert.config.alertCopyFrame.callback = function(newAlertName, set, setsTable)
		alertData.name = newAlertName

		local targetSet = getAlertSet(set, setsTable)
		if targetSet.alerts[alertData.name] ~= nil then
			return false, kAlertTexts.statAlertAlreadyExists
		end
		
		targetSet:Add(alertData)
		targetSet:Save()
		
		if kAlert.config.active then
			kAlert.config.mainFrame.clearAlert()
			kAlert.config.mainFrame.frScreenObjects.fillList(kAlert.alertSet.alerts)
		end
		
		table.remove(kAlert.sharedAlerts, 1)
		return true
	end
	
	kAlert.config.alertCopyFrame.cancelCallback = function ()
		table.remove(kAlert.sharedAlerts, 1)
	end
	
	kAlert.config.alertCopyFrame:SetVisible(true)
end

local function messageBox(text, buttons, position, callback)
	if kAlert.config.messageBoxFrame == nil then
		kAlert.config.messageBoxFrame = buildMessageBox()
	end
	local window = kAlert.config.messageBoxFrame
	
	window:SetMessageBox(text, buttons, position, callback)
	window:SetVisible(true)
end

function kAlert.config.messageBox(text, buttons, callback)
	messageBox(text, buttons, {"CENTER", UIParent, "CENTER"}, callback)
end

function kAlert.config.messageBoxTop(text, buttons, callback)
	messageBox(text, buttons, {"TOPCENTER", UIParent, "TOPCENTER", 0, 100}, callback)
end