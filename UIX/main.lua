local addon, private = ...
UIX =
{
	Frame = {}
}

private.context = UI.CreateContext("UIX")

function UIX.CreateStretchedTexture(name, parent)
	local window = UI.CreateFrame("Frame", name, parent)
	--window.__index = window
	
	local left = 0
	local right = 0
	local top = 0
	local bottom = 0

	local oldSetWidth = window.SetWidth
	local oldSetHeight = window.SetHeight
	local textures = {}
	
	textures.topLeft = UI.CreateFrame("Mask", "topLeft", window)
	textures.topLeft:SetPoint("TOPLEFT", window, "TOPLEFT")
	textures.topLeft.texture = UI.CreateFrame("Texture", "topLeftTexture", textures.topLeft)
	textures.topLeft.texture:SetPoint("TOPLEFT", textures.topLeft, "TOPLEFT")
	textures.topLeft:SetLayer(-1)
	
	textures.bottomLeft = UI.CreateFrame("Mask", "bottomLeft", window)
	textures.bottomLeft:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT")
	textures.bottomLeft.texture = UI.CreateFrame("Texture", "topLeftTexture", textures.bottomLeft)
	textures.bottomLeft.texture:SetPoint("BOTTOMLEFT", textures.bottomLeft, "BOTTOMLEFT")
	textures.bottomLeft:SetLayer(-1)

	textures.left = UI.CreateFrame("Mask", "left", window)
	textures.left:SetPoint("TOPLEFT", textures.topLeft, "BOTTOMLEFT", 0, 0)
	textures.left.texture = UI.CreateFrame("Texture", "topLeftTexture", textures.left)
	textures.left:SetLayer(-1)

	textures.topRight = UI.CreateFrame("Mask", "topRight", window)
	textures.topRight:SetPoint("TOPRIGHT", window, "TOPRIGHT")
	textures.topRight.texture = UI.CreateFrame("Texture", "topLeftTexture", textures.topRight)
	textures.topRight.texture:SetPoint("TOPRIGHT", textures.topRight, "TOPRIGHT")
	textures.topRight:SetLayer(-1)

	textures.bottomRight = UI.CreateFrame("Mask", "bottomRight", window)
	textures.bottomRight:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT")
	textures.bottomRight.texture = UI.CreateFrame("Texture", "bottomRightTexture", textures.bottomRight)
	textures.bottomRight.texture:SetPoint("BOTTOMRIGHT", textures.bottomRight, "BOTTOMRIGHT")
	textures.bottomRight:SetLayer(-1)

	textures.right = UI.CreateFrame("Mask", "right", window)
	textures.right:SetPoint("TOPRIGHT", textures.topRight, "BOTTOMRIGHT", 0, 0)
	textures.right.texture = UI.CreateFrame("Texture", "rightTexture", textures.right)
	textures.right:SetLayer(-1)
	
	textures.top = UI.CreateFrame("Mask", "top", window)
	textures.top:SetPoint("TOPLEFT", textures.topLeft, "TOPRIGHT", 0, 0)
	textures.top.texture = UI.CreateFrame("Texture", "topLeftTexture", textures.top)
	textures.top:SetLayer(-1)
	
	textures.bottom = UI.CreateFrame("Mask", "bottom", window)
	textures.bottom:SetPoint("BOTTOMLEFT", textures.bottomLeft, "BOTTOMRIGHT", 0, 0)
	textures.bottom.texture = UI.CreateFrame("Texture", "bottomTexture", textures.bottom)
	textures.bottom:SetLayer(-1)
	
	textures.middle = UI.CreateFrame("Mask", "bottom", window)
	textures.middle:SetPoint("TOPLEFT", textures.topLeft, "BOTTOMRIGHT", 0, 0)
	textures.middle.texture = UI.CreateFrame("Texture", "bottomTexture", textures.middle)
	textures.middle:SetLayer(-1)
	
	local function DoLayout(self)
		local width = self:GetWidth()
		local height = self:GetHeight()
		local textureWidth = textures.topLeft.texture:GetWidth()
		local textureHeight = textures.topLeft.texture:GetHeight()
		
		local magVer = (height - top - bottom) / (textureHeight - top - bottom)
		local magHor = (width - left - right ) / (textureWidth - left - right)
		
		textures.topLeft:SetWidth(left)
		textures.topLeft:SetHeight(top)
		
		textures.left:SetWidth(left)
		textures.left:SetHeight(height - top - bottom)

		textures.bottomLeft:SetWidth(left)
		textures.bottomLeft:SetHeight(bottom)

		textures.topRight:SetWidth(right)
		textures.topRight:SetHeight(top)
		
		textures.right:SetWidth(right)
		textures.right:SetHeight(height - top - bottom)

		textures.bottomRight:SetWidth(right)
		textures.bottomRight:SetHeight(bottom)
	
		textures.top:SetWidth(width - left - right)
		textures.top:SetHeight(top)
	
		textures.bottom:SetWidth(width - left - right)
		textures.bottom:SetHeight(bottom)
	
		textures.middle:SetWidth(width - left - right)
		textures.middle:SetHeight(height - top - bottom)

		textures.left.texture:SetPoint("TOPLEFT", textures.left, "TOPLEFT", 0, -top * magVer)
		textures.left.texture:SetPoint("BOTTOMLEFT", textures.left, "BOTTOMLEFT", 0, bottom * magVer)

		textures.right.texture:SetPoint("TOPRIGHT", textures.right, "TOPRIGHT", 0, -top * magVer)
		textures.right.texture:SetPoint("BOTTOMRIGHT", textures.right, "BOTTOMRIGHT", 0, bottom * magVer)	

		textures.top.texture:SetPoint("TOPLEFT", textures.top, "TOPLEFT", -left * magHor, 0)
		textures.top.texture:SetPoint("TOPRIGHT", textures.top, "TOPRIGHT", right * magHor, 0)

		textures.bottom.texture:SetPoint("BOTTOMLEFT", textures.bottom, "BOTTOMLEFT", -left * magHor, 0)
		textures.bottom.texture:SetPoint("BOTTOMRIGHT", textures.bottom, "BOTTOMRIGHT", right * magHor, 0)

		textures.middle.texture:SetPoint("TOPLEFT", textures.middle, "TOPLEFT", -left * magHor, -top * magVer)
		textures.middle.texture:SetPoint("BOTTOMRIGHT", textures.middle, "BOTTOMRIGHT", right * magHor, bottom * magVer)	
	end
	
	function window:SetWidth(width)
		oldSetWidth(self, width)
		DoLayout(self)
	end
	
	function window:SetHeight(height)
		oldSetHeight(self, height)
		DoLayout(self)
	end
	
	function window:SetTexture(source, texture)
		for _, section in pairs(textures) do
			section.texture:SetTexture(source, texture)
		end
		DoLayout(self)
	end
	
	function window:SetEdges(leftEdge, rightEdge, topEdge, bottomEdge)
		left = leftEdge
		right = rightEdge
		top = topEdge
		bottom = bottomEdge
		DoLayout(self)
	end
	
	return window
end

-- Helper function for workaround for bug in Frame:ClearPoint
local function PointToName(x, y)
	if x == nil and y == 0.5 then
		return "YCENTER"
	elseif x == 0.5 and y == nil then
		return "XCENTER"
	else
		local result = ""
		
		if y == 0 then
			result = "TOP"
		elseif y == 0.5 then
			result = "CENTER"
		elseif y == 1 then
			result = "BOTTOM"
		end
		
		if x == 0 then
			result = result .. "LEFT"
		elseif x == 0.5 then
			result = result .. "CENTER"
		elseif x == 1 then
			result = result .. "RIGHT"
		end
		
		return result
	end
end

function UIX.Frame.ClearPoint(frame, x, y)
	frame:ClearPoint(PointToName(x, y))
end

function UIX.Frame.ClearPoints(frame)
	local points = frame:ReadAll()
	local point = { x = nil, y = nil }
	for pos, _ in pairs(points.x) do
		if pos ~= "size" then
			UIX.Frame.ClearPoint(frame, tonumber(pos), nil)
		end
	end
	for pos, _ in pairs(points.y) do
		if pos ~= "size" then
			UIX.Frame.ClearPoint(frame, nil, tonumber(pos))
		end
	end
end

