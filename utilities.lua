local addonInfo, private = ...
local kAlert = private.kAlert
local kUtils = private.kUtils
local menuFrame = nil
local textfieldSpecialKeys = { "Home", "End", "Delete", "Backspace", "Insert", "Left", "Right" }

if Utility.GlobalEmptyFunction == nil then
	Utility.GlobalEmptyFunction = function () end
end

function kUtils.pairsByKeys(t, f)
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a, f)
	local i = 0      -- iterator variable
	local iter = function ()   -- iterator function
		i = i + 1
		if a[i] == nil then return nil
		else return a[i], t[a[i]]
		end
	end
	return iter
end

function kUtils.tableContainsValue(t, value)
	for k, v in pairs(t) do
		if v == value then return true end
	end
	return false
end

function kUtils.removeKeys(t, keysTable)
	for key, _ in pairs(keysTable) do
		t[key] = nil
	end
end

function kUtils.tableIsEmpty(t)
	for _, _ in pairs(t) do
		return false
	end
	return true
end

function kUtils.booltostring(value)
	if value then
		return "T"
	else
		return "F"
	end
end

function kUtils.stringtobool(value)
	return (value == "T")
end

function kUtils.toInteger(value)
	local i, j = string.find(value, "%d+")
	if i == 1 and j == string.len(value) then
		return tonumber(value)
	else
		return nil
	end
end

function kUtils.tableCopy(t)
	local t2 = {}
	for k,v in pairs(t) do
		t2[k] = v
	end
	return t2
end

-- Compares two version strings in the same way RIFT does when comparing library versions
-- @usage kUtils.compareVersions("1.30.0", "1.30 alpha")
-- returns -1
-- @usage kUtils.compareVersions("1.30.0", "1.30.0")
-- returns 0
-- @usage kUtils.compareVersions("1.30.0", "1.31 alpha")
-- returns 1
function kUtils.compareVersions(va, vb)
	local a = string.split(va, "[%. ]+", true)
	local b = string.split(vb, "[%. ]+", true)
	
	for i = 1, math.max(#a, #b), 1 do
		if a[i] == nil then
			return 1
		elseif b[i] == nil then
			return -1
		elseif a[i] == b[i] then
			-- Do nothing
		else
			local na = tonumber(a[i])
			local nb = tonumber(b[i])
			
			if na and nb then
				return (nb - na) / math.abs(nb - na)
			elseif na == nil and nb ~= nil then
				return 1
			elseif na ~= nil and nb == nil then
				return -1
			elseif a[i] < b[i] then
				return 1
			else
				return -1
			end
		end
	end
	
	return 0
end


function kUtils.buildFrame(name, parent, height, width)

	local frame = UI.CreateFrame("Frame", name, parent)
	frame:SetHeight(height)
	frame:SetWidth(width)
	
	return frame
	
end

function kUtils.buildLabel(name, parent, height, width, text, wrap)

	if wrap == nil then wrap = false end
	local label = UI.CreateFrame("Text", name, parent)
	label:SetWordwrap(wrap)
	label:SetText(text)
	label:SetFontSize(height)
	label:SetWidth(width)
	label:SetFontColor(1, 1, 1, 1)
	
	function label.setWrapText(text, html)
		label:SetWordwrap(true)
		label:SetText(text, html or false)
	end
	
	return label
	
end

function kUtils.createExtText(name, parent)
	return kUtils.ExtText:new(name, parent)
end

kUtils.ExtText = {}
function kUtils.ExtText:new(name, parent)
	local frame = UI.CreateFrame("Frame", name, parent)
	
	-- create the new metatable
  	local mt = {__index={}}
  	-- get the original metatable
  	local fmt = getmetatable(frame)
  	-- copy the content of the original metatable in the new one
  	for k, v in pairs(fmt.__index) do
    	if type (v) == 'function' then
	      mt.__index[k] = v
    	end
  	end
  	
 	-- add some new fancy methods in our metatable here:
 	mt.__index.CreateShadow = function(self, index)
 		if self.shadows[index] then return end
		local shadow = UI.CreateFrame("Text", "shadow", frame)
		shadow:SetFontColor(0, 0, 0, 1)
		shadow:SetLayer(1)
		shadow:SetText(self.text:GetText() or "")
		shadow:SetFont(self.text:GetFont())
		shadow:SetFontSize(self.text:GetFontSize())
		
		self.shadows[index] = shadow
		
		kUtils.taskYield()
 	end
 	
  	mt.__index.SetShadow = function(self, shadow)
  		if shadow == 1 or shadow == 3 then
  			self:CreateShadow(1)
  			self.shadows[1]:SetPoint("TOPLEFT", frame.text, "TOPLEFT", 2, 2)
  			self.shadows[1]:SetVisible(true)
  		elseif self.shadows[1] ~= nil then
  			self.shadows[1]:SetVisible(false)
  		end
  		
  		if shadow == 2 or shadow == 3 then
  			local glowTable = {
				colorA = 1, colorB = 0,	colorG = 0,	colorR = 0,
				offsetX = 0, offsetY = 0,
				blurX = 1.2, blurY = 1.2,
				knockout = false,
				replace = false,
				strength = 7
			}
			frame.text:SetEffectGlow(glowTable)
  		else
  			frame.text:SetEffectGlow(nil)
  		end
  	end
  	-- switch metatable for our frame
  	setmetatable(frame, mt)	
	
	frame.text = UI.CreateFrame("Text", "text", frame)
	frame.text:SetLayer(2)
	frame.text:SetPoint("CENTER", frame, "CENTER", -1, -1)
	
	frame.shadows = {}
	
	function frame:SetText(text)
		self.text:SetText(text)
		for i, shadow in ipairs(self.shadows) do
			shadow:SetText(text)
		end
	end
	
	function frame:SetFont(...)
		self.text:SetFont(...)
		for i, shadow in ipairs(self.shadows) do
			shadow:SetFont(...)
		end
	end
	
	function frame:SetFontSize(size)
		self.text:SetFontSize(size)
		for i, shadow in ipairs(self.shadows) do
			shadow:SetFontSize(size)
		end
	end
	
	function frame:SetFontColor(...)
		self.text:SetFontColor(...)
	end
	
	function frame:GetFontColor(...)
		return self.text:GetFontColor(...)
	end	
	
	return frame
end



function kUtils.buildSlider(name, parent, height, width, minVal, maxVal)

	local frame = UI.CreateFrame("RiftSlider", name, parent)
	frame:SetHeight(height)
	frame:SetWidth(width)
	frame:SetRange(minVal, maxVal)
	
	return frame
	
end

function kUtils.buildCheckBox(name, parent, height, width, label, reverse)

	local checkBox = UI.CreateFrame("RiftCheckbox", name, parent)
	checkBox:SetHeight(height)
	checkBox:SetWidth(height)
	checkBox.label = kUtils.buildLabel(name .. "Label", checkBox, height - 6, width - height - 1, label)
	if reverse then
		checkBox.label:SetPoint("CENTERRIGHT", checkBox, "CENTERLEFT", 1, 0)
	else
		checkBox.label:SetPoint("CENTERLEFT", checkBox, "CENTERRIGHT", 1, 0)
	end
	
	return checkBox
	
end

function kUtils.buildButton(name, parent, height, width, label, skin)

	local button = UI.CreateFrame("RiftButton", name, parent)
	if skin == "close" then
		button:SetSkin("close")
		return button
	else
		button:SetText(label)
		button:SetHeight(height)
		button:SetWidth(width)
	end
	
	return button
	
end

function kUtils.buildEditBox(name, parent, height, width, label, boxWidth)

	local editBox = UI.CreateFrame("Frame", name, parent)
	editBox:SetPoint("TOPLEFT", parent, "TOPLEFT")
	editBox:SetHeight(height)
	editBox:SetWidth(width)
	editBox.label = kUtils.buildLabel(name .. "Label", editBox, height - 5, width, label)
	editBox.label:ClearWidth()
	editBox.label:SetPoint("CENTERLEFT", editBox, "CENTERLEFT")
	editBox.label:SetLayer(1)
	editBox.text = UI.CreateFrame("RiftTextfield", name .. "Text", editBox)
	
	if boxWidth == nil then
		editBox.text:SetPoint("CENTERLEFT", editBox.label, "CENTERRIGHT")
		editBox.text:SetHeight(height)
		editBox.text:SetWidth(width - editBox.label:GetWidth())
	else
		editBox.text:SetPoint("CENTERY", editBox.label, "CENTERY")
		editBox.text:SetPoint("RIGHT", editBox, "RIGHT")
		editBox.text:SetHeight(height)
		editBox.text:SetWidth(boxWidth)
	end
		
	editBox.text:SetBackgroundColor(.25, .25, .25)
	editBox.text:SetLayer(1)
	editBox.outline = kUtils.setOutline(editBox.text)
	
	function editBox.setLabel(label)
		editBox.label:SetText(label)
		editBox.text:SetWidth(editBox:GetWidth() - editBox.label:GetWidth())		
	end
	
	return editBox
end


local filterKeysInteger
do
	local integerSpecialKeys = { "Dash", "Subtract" }

	function filterKeysInteger(obj, handle, key)
		if string.prefix(key, "Numpad ") then key = string.sub(key, 8) end
		if (key >= '0' and key <= '9') or key == '-'  then return end
		if kUtils.tableContainsValue(integerSpecialKeys, key) or kUtils.tableContainsValue(textfieldSpecialKeys, key) then return end
		handle:Halt()
	end
end

function kUtils.buildEditBoxInteger(name, parent, height, width, label, boxWidth)
	local editBox = kUtils.buildEditBox(name, parent, height, width, label, boxWidth)
	editBox.text:EventAttach(Event.UI.Input.Key.Down.Dive, filterKeysInteger, "filter")
	return editBox
end

function kUtils.buildImageBox(name, parent, height, width, source, image)

	local imageBox = UI.CreateFrame("Texture", name, parent)
	imageBox:SetWidth(width)
	imageBox:SetHeight(height)
	imageBox:SetBackgroundColor(0, 0, 0, 0.5)
	imageBox:SetLayer(0)
	imageBox.outline = kUtils.setOutline(imageBox)
	
	function imageBox.setImage(source, image)
		if source == nil or image == nil then
			print("Warning: no image found for alert.")
			return
		end
		imageBox.source = source
		imageBox.image = image
		imageBox:SetTexture(source, image)
	end
	
	if source and image then
		imageBox.setImage(source, image)
	end
	
	return imageBox
end

function kUtils.buildToggleBox(name, parent, height, width, options, columns, allowNone)

	local toggleBox = UI.CreateFrame("Frame", name, parent)
	toggleBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, 65)
	if columns == nil then columns = 1 end
	toggleBox:SetHeight(height * math.ceil(table.getn(options)/columns))
	toggleBox:SetWidth(width * columns)
	toggleBox:SetBackgroundColor(0, 0, 0, 0.25)
	toggleBox:SetLayer(-1)
	toggleBox.updateOptions = true
	toggleBox.cbOption = {}
	toggleBox.outline = kUtils.setOutline(toggleBox)
	toggleBox.allowNone = allowNone
	
	local row = 1
	for id, details in pairs(options) do
		option = kUtils.buildCheckBox(name .. "Option" .. tostring(id),toggleBox,height,width,details)
		if id == 1 then
			option:SetPoint("TOPLEFT", toggleBox, "TOPLEFT",1,0)
			option:SetChecked(true)
		elseif math.ceil(id/columns)-row == 0 then
			option:SetPoint("TOPLEFT", toggleBox.cbOption[id-1].label, "TOPRIGHT")
		else
			option:SetPoint("TOPLEFT", toggleBox.cbOption[id-columns], "BOTTOMLEFT")
			row = row + 1
		end

		function option.Event:CheckboxChange()
			if not toggleBox.updateOptions then return end

			toggleBox.updateOptions = false
			local setValue = self:GetChecked() or not toggleBox.allowNone
			for i = 1, table.getn(options), 1 do
				toggleBox.cbOption[i]:SetChecked(false)
			end
			self:SetChecked(setValue)
			toggleBox.updateOptions = true

			if toggleBox.change ~= nil then toggleBox.change() end
		end
		
		toggleBox.cbOption[id] = option
	end
	
	function toggleBox.setOptions(options)
		for i = 1, table.getn(toggleBox.cbOption), 1 do
			if options[i] ~= nil then toggleBox.cbOption[i].label:SetText(options[i]) end
		end
	end
	
	function toggleBox.getSelected()
		for i = 1, table.getn(options), 1 do
			if toggleBox.cbOption[i]:GetChecked() then return i end
		end
		return 0
	end
	
	function toggleBox.setSelected(id)
		if id == 0 or id == nil then
			toggleBox.cbOption[1]:SetChecked(true)
			if toggleBox.allowNone then toggleBox.cbOption[1]:SetChecked(false) end
		else
			toggleBox.cbOption[id]:SetChecked(true)
		end
	end
	
	return toggleBox
	
end

function kUtils.buildListPane(name, parent, height, width)

	local listPane = UI.CreateFrame("Frame", name, parent)
	listPane:SetHeight(height)
	listPane:SetWidth(width)
	listPane:SetLayer(-1)
	--local itemHight = listPane:GetHeight() / size
	local itemHight = 20
	listPane.itemCount = 0
	listPane.lpItem = {}
	
	listPane.scrollView = UI.CreateFrame("Mask", name .. "ScrollView", listPane)
	listPane.scrollView:SetPoint("TOPLEFT", listPane, "TOPLEFT")
	listPane.scrollView:SetHeight(listPane:GetHeight())
	listPane.scrollView:SetWidth(listPane:GetWidth())
	listPane.scrollView:SetBackgroundColor(0, 0, 0, 0.5)
	listPane.outline = kUtils.setOutline(listPane.scrollView, listPane)
	
	listPane.scrollPane = UI.CreateFrame("Frame", name .. "ScrollPane", listPane.scrollView)
	listPane.scrollPane:SetPoint("TOPLEFT", listPane.scrollView, "TOPLEFT")
	
	listPane.scrollbar = UI.CreateFrame("RiftScrollbar", name .. "Scrollbar", listPane)
	listPane.scrollbar:SetPoint("TOPLEFT", listPane.scrollView, "TOPRIGHT")
	listPane.scrollbar:SetHeight(height)
	
	function listPane.scrollView.Event:WheelBack()
		local minRange, maxRange = listPane.scrollbar:GetRange()
		if maxRange == 0 then return end
		local value = math.min(maxRange, listPane.scrollbar:GetPosition() + itemHight)
		listPane.scrollbar:SetPosition(value)
	end

	function listPane.scrollView.Event:WheelForward()
		local minRange, maxRange = listPane.scrollbar:GetRange()
		local value = math.max(0, listPane.scrollbar:GetPosition() - itemHight)
		listPane.scrollbar:SetPosition(value)
	end
	
	function listPane.scrollbar.Event:ScrollbarChange()
		local value = self:GetPosition()
		listPane.scrollPane:SetPoint("TOPLEFT", listPane, "TOPLEFT", 0, -1 * value)
	end
	
	local function createItem()
		local i = table.getn(listPane.lpItem) + 1
		
		item = UI.CreateFrame("Text", name .. "Item" .. tostring(i), listPane.scrollPane)
		item:SetText("")
		item:SetFontSize(itemHight - 5)
		item:SetHeight(itemHight)
		item:SetWidth(listPane:GetWidth())
		item:SetFontColor(1, 1, 1, 1)
		item.selected = false
		item.enabled = true
		
		if i == 1 then
			item:SetPoint("TOPLEFT", listPane.scrollPane, "TOPLEFT")
		else
			item:SetPoint("TOPLEFT", listPane.lpItem[i - 1], "BOTTOMLEFT")
		end
		
		function item.Event:MouseIn()
			if listPane.onMouseOver ~= nil then listPane.onMouseOver() end
		end
		
		local function Click(item, button)
			if string.len(item:GetText()) > 0 and item.enabled then
				listPane.clearSelected()
				item:SetBackgroundColor(1, 1, 1, 0.5)
				item.selected = true
				if listPane.click ~= nil then listPane.click(button) end
			end
		end
		
		function item.Event:LeftClick()
			Click(self, "LEFT")
		end
		
		function item.Event:RightClick()
			Click(self, "RIGHT")
		end
		
		listPane.lpItem[i] = item
		return item
	end
	
	function listPane.updateScrollbar()
		local scrollRange = math.max(listPane.itemCount * itemHight - height, 0)
		
		if (scrollRange > 0) then
			listPane.scrollView:SetWidth(listPane:GetWidth() - 17)
			listPane.scrollbar:SetRange(0, scrollRange)
			listPane.scrollbar:SetVisible(true)
		else
			listPane.scrollView:SetWidth(listPane:GetWidth())
			listPane.scrollbar:SetRange(0, 0)
			listPane.scrollbar:SetVisible(false)
		end

	end
	
	function listPane.clearSelected()
		for i, lpi in ipairs(listPane.lpItem) do
			lpi:SetBackgroundColor(1, 1, 1, 0)
			lpi.selected = false
		end
	end
	
	local function setItemEnabled(item, value)
		listPane.lpItem[item].enabled = value
		if value then
			listPane.lpItem[item]:SetFontColor(1, 1, 1, 1)
		else
			listPane.lpItem[item]:SetFontColor(.5, .5, .5, .5)
		end
	end

	function listPane.itemsEnabled(value)
		for i, lpi in ipairs(listPane.lpItem) do
			setItemEnabled(i, value)
		end
	end

	function listPane.itemEnabled(item, value)
		for i, lpi in ipairs(listPane.lpItem) do
			if lpi:GetText() == item then
				setItemEnabled(i, value)
			end
		end
	end
	
	function listPane.getSelected()
		for i, lpi in ipairs(listPane.lpItem) do
			if lpi.selected then return lpi:GetText() end
		end
		return ""
	end
	
	function listPane.setSelected(itemText)
		for i, lpi in ipairs(listPane.lpItem) do
			if lpi:GetText() == itemText then
				lpi.Event.LeftClick(lpi)
			end
		end
	end

	function listPane.clearList()
		for i, lpi in ipairs(listPane.lpItem) do
			lpi:SetText("")
			lpi:SetBackgroundColor(1, 1, 1, 0)
			lpi.selected = false
			lpi:SetVisible(false)
		end
		listPane.itemCount = 0
	end
	
	function listPane.addItem(text)
		listPane.itemCount = listPane.itemCount + 1
		if not listPane.lpItem[listPane.itemCount] then
			createItem()
		end
		listPane.lpItem[listPane.itemCount]:SetText(text)
		listPane.lpItem[listPane.itemCount]:SetVisible(true)	
	end
	
	function listPane.fillList(items)
		local selectedItem = listPane.getSelected()
		listPane.clearList()
		listPane.itemCount = 0
		for id, details in kUtils.pairsByKeys(items) do
			listPane.addItem(id)
		end
		listPane.updateScrollbar()
	end
	
	function listPane.fillTextList(items)
		local selectedItem = listPane.getSelected()
		listPane.clearList()
		listPane.itemCount = 0
		for id, details in pairs(items) do
			listPane.addItem(details)
		end
	end
	
	listPane.updateScrollbar()

	return listPane
	
end

function kUtils.buildMenuBar(name, parent, height, width, menus)
	local menuBar = UI.CreateFrame("Frame", name, parent)
	menuBar:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, 65)
	menuBar:SetHeight(height)
	menuBar:SetWidth(width)
	menuBar:SetBackgroundColor(0, 0, 0, 0)
	menuBar:SetLayer(0)
	menuBar.menus = {}
	menuBar.outline = kUtils.setOutline(menuBar)
	menuBar.menuIn = false
	
	for id, details in pairs(menus) do
		menu = kUtils.buildLabel(name .. "Menu" .. tostring(id),menuBar,height-7,width,details[1])
		menu:ClearWidth()
		menu:SetWidth(menu:GetWidth() + 10)
		menu.items = nil
		if id == 1 then
			menu:SetPoint("TOPLEFT", menuBar, "TOPLEFT")
		else
			menu:SetPoint("TOPLEFT", menuBar.menus[menus[id-1]], "TOPRIGHT")
		end
		function menu.Event:LeftClick()
			kUtils.showSubMenu(self, details[2], parent)
		end
		menuBar.menus[details] = menu
	end
	
	return menuBar
end

function kUtils.buildMenu()
	local width = 180
	local layer = 9000
	local menu = UI.CreateFrame("Frame", "ContextMenu", kAlert.context)
	menu:SetBackgroundColor(0,0,0,0.9)
	menu:SetWidth(width)
	menu:SetLayer(layer)
	menu:SetVisible(false)
	
	menu.items = {}
	menu.elements = {}
	menu.outline = kUtils.setOutline(menu)
	menu.highlight = nil

	menu.h1 = UI.CreateFrame("Texture", "ContextMenuH1", menu)
	menu.h2 = UI.CreateFrame("Texture", "ContextMenuH2", menu)
	menu.h1:SetTexture("kAlert", "images\\MenuHighlight.png")
	menu.h2:SetTexture("kAlert", "images\\MenuHighlight.png")
	
	local mouseOver = UI.CreateFrame("Frame", "MenuMouseOver", kAlert.context)
	--mouseOver:SetBackgroundColor(1, 0, 0, 0.3)
	mouseOver:SetVisible(false)
	mouseOver:SetAllPoints(UIParent)
	mouseOver:SetLayer(8999)
	mouseOver:SetMouseMasking("limited")
	menu.mouseOver = mouseOver	
	
	function menu:LeftClick(index)
		self:Close()
		local item = self.items[index]
		local func = item[2]
		if self.elements[index].enabled and func then 
			func()
		end
	end
	
	function menu:CreateElements(count)
		for i = table.getn(self.elements) + 1, count, 1 do
			el = UI.CreateFrame("Text", "ContextMenuItem" .. tostring(i), self)
			el:SetFontSize(12)
			el:SetHeight(20)
			el:SetWidth(width - 10)
			el:SetFontColor(0.8, 0.78, 0.7, 1)
			el.enabled = true
			el.index = i
			
			if i == 1 then
				el:SetPoint("TOPLEFT", self, "TOPLEFT", 10, 10)
			else
				el:SetPoint("TOPLEFT", self.elements[i - 1], "BOTTOMLEFT", 0, 2)
			end
			
			function el.Event:LeftClick()
				menu:LeftClick(self.index)
			end
			
			function el.Event:MouseIn()
				menu:Highlight(self.index)
			end
			
			function el:UpdateColor()
				if menu.highlight == self.index then
					self:SetFontColor(1, 1, 1, 1)
				elseif self.enabled then
					self:SetFontColor(0.8, 0.78, 0.7, 1)
				else
					self:SetFontColor(0.3, 0.3, 0.3, 1)
				end
			end
			
			table.insert(self.elements, el)
		end
		
		menu:SetHeight(21 * count + 20)
	end
	
	function menu:Highlight(item)
		if self.highlight == item then
			return
		elseif self.highlight ~= nil then
			local tmp = self.highlight
			self.highlight = nil
			self.elements[tmp]:UpdateColor()
		end
		
		if item == nil or not self.elements[item].enabled then
			self.h1:SetVisible(false)
			self.h2:SetVisible(false)
		else
			self.highlight = item
			self.elements[item]:UpdateColor()
			self.h1:SetPoint("TOPLEFT", self.elements[item], "TOPLEFT", 0, 1)
			self.h2:SetPoint("TOPLEFT", self.elements[item], "BOTTOMLEFT", 0, -1)
			self.h1:SetVisible(true)
			self.h2:SetVisible(true)
		end
	end
		
	function menu:SetItems(items)
		self:CreateElements(#items)
		
		for i = 1, #items, 1 do
			self.elements[i]:SetText(items[i][1] or "(Empty)")
			self.elements[i]:SetVisible(true)

			local t = type(items[i][3])
			local enabled 
			if t == "nil" then
				enabled = true
			elseif t == "boolean" then
				enabled = items[i][3]
			elseif t  == "function" then
				enabled = (items[i][3])()
			end
			
			if enabled ~= self.elements[i].enabled then
				self.elements[i].enabled = enabled
				self.elements[i]:UpdateColor()
			end
		end
		
		for i = #items + 1, table.getn(self.elements), 1 do
			self.elements[i]:SetVisible(false)
		end
		
		self.items = items
	end
	
	function menu:Open(frame, parent)
		if parent == nil then
			parent = kAlert.context
		end
		
		if frame == nil then
			local mouse = Inspect.Mouse()
			self:SetPoint("TOPLEFT", kAlert.context, "TOPLEFT", mouse.x + 2, mouse.y + 2)
		else
			--frame:SetBackgroundColor(1, 0, 0, 1)
			self:SetPoint("TOPLEFT", frame, "BOTTOMLEFT")
		end
		
		self:SetParent(parent)
		self:Highlight(nil)
		self:SetVisible(true)
		mouseOver:SetVisible(true)
		mouseOver:SetParent(parent)
	end
	
	function menu:Close()
		self:SetVisible(false)
		self.mouseOver:SetVisible(false)
	end
	
	function mouseOver.Event:MouseIn()
		menu:Highlight(nil)
	end	

	function mouseOver.Event:LeftClick()
		menu:Close()
	end

	function mouseOver.Event:RightClick()
		menu:Close()
	end
	
	return menu
end

function kUtils.showContextMenu(items)
	if menuFrame == nil then
		menuFrame = kUtils.buildMenu()
	end
	
	menuFrame:SetItems(items)
	
	menuFrame:Open()
end

function kUtils.showSubMenu(frame, items, parent)
	if menuFrame == nil then
		menuFrame = kUtils.buildMenu()
	end
	
	menuFrame:SetItems(items)
	menuFrame:Open(frame, parent)
end

function kUtils.buildWindowMover(name, parent)
	local windowMover = UI.CreateFrame("Frame", name, parent)
	windowMover:SetPoint("TOPLEFT", parent, "TOPLEFT")
	windowMover:SetHeight(50)
	windowMover:SetWidth(parent:GetWidth() - 40)
	windowMover:SetBackgroundColor(0, 0, 0, 0)

	kUtils.makeMovable(windowMover, parent)

	return windowMover
end

function kUtils.makeMovable(object, movingObject)
	if movingObject == nil then
		movingObject = object
	end
	
	object.movable = true
	
	function object.Event:LeftDown()
		self.MouseDown = self.movable
		mouseData = Inspect.Mouse()
		self.MyStartX = movingObject:GetLeft()
		self.MyStartY = movingObject:GetTop()
		self.StartX = mouseData.x - self.MyStartX
		self.StartY = mouseData.y - self.MyStartY
	end
	
	function object.Event:MouseMove(mouseX, mouseY)
		if self.MouseDown then
			UIX.Frame.ClearPoints(movingObject)
			movingObject:SetPoint("TOPLEFT", UIParent, "TOPLEFT", (mouseX - self.StartX), (mouseY - self.StartY))
		end
	end
	
	function object.Event:LeftUp()
		self.MouseDown = false
	end
end

function kUtils.setOutline(item, parent)
	if parent == nil then parent = item	end
	
	outline = UI.CreateFrame("Frame", item:GetName() .. "Outline", parent)
	outline:SetPoint("TOPLEFT", item, "TOPLEFT")
	outline:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT")
	outline:SetLayer(item:GetLayer()+1)
	outline.left = UI.CreateFrame("Frame", outline:GetName() .. "Left", outline)
	outline.left:SetPoint("TOPLEFT", outline, "TOPLEFT")
	outline.left:SetPoint("BOTTOMLEFT", outline, "BOTTOMLEFT")
	outline.left:SetWidth(1)
	outline.left:SetBackgroundColor(.45,.44,.38)
	outline.left:SetLayer(outline:GetLayer()+1)
	outline.right = UI.CreateFrame("Frame", outline:GetName() .. "Right", outline)
	outline.right:SetPoint("TOPRIGHT", outline, "TOPRIGHT")
	outline.right:SetPoint("BOTTOMRIGHT", outline, "BOTTOMRIGHT")
	outline.right:SetWidth(1)
	outline.right:SetBackgroundColor(.52,.51,.42)
	outline.right:SetLayer(outline:GetLayer()+1)
	outline.top = UI.CreateFrame("Frame", outline:GetName() .. "Top", outline)
	outline.top:SetPoint("TOPLEFT", outline, "TOPLEFT")
	outline.top:SetPoint("TOPRIGHT", outline, "TOPRIGHT")
	outline.top:SetHeight(1)
	outline.top:SetBackgroundColor(.52,.51,.42)
	outline.top:SetLayer(outline:GetLayer()+1)
	outline.bottom = UI.CreateFrame("Frame", outline:GetName() .. "Bottom", outline)
	outline.bottom:SetPoint("BOTTOMLEFT", outline, "BOTTOMLEFT")
	outline.bottom:SetPoint("BOTTOMRIGHT", outline, "BOTTOMRIGHT")
	outline.bottom:SetHeight(1)
	outline.bottom:SetBackgroundColor(.45,.44,.38)
	outline.bottom:SetLayer(outline:GetLayer()+1)
	return outline
end

function kUtils.subscribeEvent(eventTable, func, addonIdentifier, text)
	for i,v in ipairs(eventTable) do
		if v[1] == Utility.GlobalEmptyFunction then
			eventTable[i] = { func, addonIdentifier, text }
			return
		end
	end	
	table.insert(eventTable, {func, addonIdentifier, text})
end

function kUtils.unsubscribeEvent(eventTable, addonIdentifier, text)
	for k,v in ipairs(eventTable) do
		if v[2] == addonIdentifier and v[3] and v[3] == text then
			v[1] = Utility.GlobalEmptyFunction
			return true
		end
	end
	return false
end

function kUtils.attachEventEx(event, func, label, active)
	Command.Event.Detach(event, nil, label, nil, addonInfo.identifier)
	if not active then return end
	Command.Event.Attach(event, func, label)
end