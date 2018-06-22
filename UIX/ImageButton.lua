local addon, private = ...

function UIX.CreateImageButton(name, parent)
	local control = UI.CreateFrame("Texture", name, parent)
	control.textures = {}
	control.mouseIn = false
	control.ignoreMouseOut = false
	control.enabled = true
	
	function control:SetTextures(source, normal, over, click, disabled)
		control.textures = { source, normal, over or normal, click or normal, disabled or normal }
		control:SetTexture(source, normal)
	end
	
	function control:GetEnabled(enabled)
		return control.enabled
	end
	
	function control:SetEnabled(enabled)
		if control.enabled == enabled then return end

		control.enabled = enabled
		control:SetTexture(control.textures[1], control.textures[enabled and 2 or 5])
	end
	
	function control.Event.MouseIn()
		if not control.enabled then return end
		control.mouseIn = true
		control:SetTexture(control.textures[1], control.textures[3])
	end

	function control.Event.MouseOut()
		if control.ignoreMouseOut then
			control.ignoreMouseOut = false
			return
		end
		control.mouseIn = false
		control:SetTexture(control.textures[1], control.textures[2])
	end
	
	function control.Event.LeftDown()
		if not control.enabled then return end
		control:SetTexture(control.textures[1], control.textures[4])
	end

	function control.Event.LeftUp()
		if not control.enabled then return end
		control.ignoreMouseOut = true
		control:SetTexture(control.textures[1], control.textures[control.mouseIn and 3 or 2])
	end
	
	return control
end