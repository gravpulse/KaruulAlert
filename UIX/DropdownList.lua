local addon, private = ...

local context = private.context
local dropdownFrame

local metatable
local eventMetatable
local DropdownList = { Event = {} }

local function buildDropdown()
	local dropDown = UIX.CreateStretchedTexture("DropdownList", context)
	dropDown:SetTexture("Rift", "dropdown_list.png.dds")
	dropDown:SetEdges(10, 10, 10, 10)
	dropDown:SetLayer(9000)
	dropDown:SetVisible(false)
	
	local mouseOver = UI.CreateFrame("Frame", "DropDownListMouseOver", context)
	--mouseOver:SetBackgroundColor(1, 0, 0, 0.3)
	mouseOver:SetVisible(false)
	mouseOver:SetAllPoints(UIParent)
	mouseOver:SetLayer(8999)
	mouseOver:SetMouseMasking("limited")
	
	h1 = UI.CreateFrame("Texture", "ContextMenuH1", dropDown)
	h2 = UI.CreateFrame("Texture", "ContextMenuH2", dropDown)
	h1:SetTexture("kAlert", "images\\MenuHighlight.png")
	h2:SetTexture("kAlert", "images\\MenuHighlight.png")	
	
	local elements = {}

	local function LeftClick(index)
		dropDown:Close()
		dropDown.selected = index
		dropDown.control:SetSelected(index)
	end
	
	local function Highlight(item)
		if dropDown.highlight == item then
			return
		elseif dropDown.highlight ~= nil then
			local tmp = dropDown.highlight
			dropDown.highlight = nil
			elements[tmp]:UpdateColor()
		end
		
		if item == nil then -- or not elements[item].enabled then
			h1:SetVisible(false)
			h2:SetVisible(false)
		else
			dropDown.highlight = item
			elements[item]:UpdateColor()
			h1:SetPoint("TOPLEFT", elements[item], "TOPLEFT", 0, 1)
			h2:SetPoint("TOPLEFT", elements[item], "BOTTOMLEFT", 0, -1)
			h1:SetVisible(true)
			h2:SetVisible(true)
		end
	end
	
	local function CreateElements(count)
		for i = table.getn(elements) + 1, count, 1 do
			el = UI.CreateFrame("Text", "ContextMenuItem" .. tostring(i), dropDown)
			el:SetFontSize(12)
			el:SetHeight(20)
			--el:SetPoint("BOTTOMRIGHT", dropDown, "BOTTOMRIGHT", -10, 0)
			--el:SetWidth(width - 10)
			el:SetFontColor(0.8, 0.78, 0.7, 1)
			el.enabled = true
			el.index = i
			
			if i == 1 then
				el:SetPoint("TOPLEFT", dropDown, "TOPLEFT", 10, 10)
			else
				el:SetPoint("TOPLEFT", elements[i - 1], "BOTTOMLEFT", 0, 2)
			end
			
			function el.Event:LeftClick()
				LeftClick(self.index)
			end
			
			function el.Event:MouseIn()
				Highlight(self.index)
			end
			
			function el:UpdateColor()
				self:SetFontSize(11)
				self:SetFontSize(12)
				if dropDown.highlight == self.index then
					self:SetFontColor(1, 1, 1, 1)
				elseif self.enabled then
					self:SetFontColor(0.8, 0.78, 0.7, 1)
				else
					self:SetFontColor(0.3, 0.3, 0.3, 1)
				end
			end
			
			table.insert(elements, el)
		end
		
		dropDown:SetHeight(22 * count + 20)
	end	
	
	function dropDown.Open(control, items)
		dropDown.control = control
		dropDown:SetParent(control:GetParent())
		mouseOver:SetParent(control:GetParent())
		
		local width = control:GetWidth()
		dropDown:SetPoint("TOPLEFT", control, "BOTTOMLEFT")
		dropDown:SetWidth(width)
		
		h1:SetWidth(width - 20)
		h2:SetWidth(width - 20)
		
		CreateElements(#items)
		for i = 1, #items do
			elements[i]:SetText(items[i])
		end
		
		for _, el in pairs(elements) do
			el:SetWidth(width - 10)
		end
		
		dropDown:SetVisible(true)
		mouseOver:SetVisible(true)
	end

	function dropDown.Close()
		dropDown:SetVisible(false)
		mouseOver:SetVisible(false)
	end
	
	function mouseOver.Event:LeftClick()
		dropDown:Close()
	end

	function mouseOver.Event:RightClick()
		dropDown:Close()
	end
	

	return dropDown
end

function DropdownList.Create(name, parent)
	local obj = UIX.CreateStretchedTexture(name, parent)
	
	if metatable == nil then
		setmetatable(DropdownList, getmetatable(obj))
		metatable = { __index = DropdownList }
		
		eventMetatable = getmetatable(obj.Event)
		local newindex = eventMetatable.__newindex
		function eventMetatable.__newindex(t, k, v)
			if k == "SelectionChange" then
				rawset(t, k, v)
			else
				newindex(t, k, v)
			end
		end
	end
	
	setmetatable(obj, metatable)
	setmetatable(obj.Event, eventMetatable)
	
	return obj
end

function DropdownList:Open()
	if dropdownFrame == nil then
		dropdownFrame = buildDropdown()
	end 
	
	dropdownFrame.Open(self, self.items)
end

function DropdownList:Close()
	dropDownFrame.Close()
end

function DropdownList:SetItems(items)
	self.items = items
end

function DropdownList:GetSelected(index)
	return self.selected
end

function DropdownList:SetSelected(index)
	self.selected = index
	self.text:SetText(self.items[index])
	if self.Event.SelectionChange then
		self.Event.SelectionChange(self, index)
	end
end

function DropdownList:GetText()
	if self.selected then
		return self.items[self.selected]
	else
		return nil
	end
end

function DropdownList.Event:MouseIn()
	self:SetTexture("Rift", "drop_down_(over)02.png.dds")
end


function UIX.CreateDropdownList(name, parent)

	local control = DropdownList.Create(name, parent)
	control:SetTexture("Rift", "drop_down_(normal)02.png.dds")
	control:SetEdges(10, 30, 10, 10)
	control:SetWidth(128)
	control:SetHeight(32)
	
	local text = UI.CreateFrame("Text", name .. "Text", control)
	text:SetPoint("TOPLEFT", control, "TOPLEFT", 10, 7)
	text:SetFontColor(1, 1, 1, 1)
	
	control.text = text

	function control.Event.MouseIn()
		control:SetTexture("Rift", "drop_down_(over)02.png.dds")
	end

	function control.Event.MouseOut()
		control:SetTexture("Rift", "drop_down_(normal)02.png.dds")
	end
	
	function control.Event.LeftDown()
		control:SetTexture("Rift", "drop_down_(click)02.png.dds")
	end

	function control.Event.LeftClick()
		control:Open()
	end

	return control
end