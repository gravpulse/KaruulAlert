local addonInfo, private = ...
local kAlert = private.kAlert
local kUtils = private.kUtils
local kAlertTexts = private.kAlertTexts

local FormsValidator = {}
FormsValidator.__index = FormsValidator

function FormsValidator.create()
	local obj = {}
	setmetatable(obj, FormsValidator)
	return obj
end

function FormsValidator:SetError(err, control)
	if self.validationError == nil then
		self.validationError = err
		self.validationControl = control
	end
end

function FormsValidator:GetNumberInput(control, default, required, rangeMin, rangeMax)
	local text = control.text:GetText()
	local label = string.rtrim(control.label:GetText(), ":")
	
	if string.len(text) == 0 then
		if required then
			self:SetError(string.format(kAlertTexts.vldRequired, label), control.text)
			return
		elseif string.len(text) == 0 then
			text = default
		end
	end
	
	local result = tonumber(text)
	if result == nil or (rangeMin and result < rangeMin) or (rangeMax and result > rangeMax) then
		if rangeMin and rangeMax then
			self:SetError(string.format(kAlertTexts.vldRangeValue, label, rangeMin, rangeMax), control.text)
		elseif rangeMin then
			self:SetError(string.format(kAlertTexts.vldMinValue, label, rangeMin), control.text)
		elseif rangeMax then
			self:SetError(string.format(kAlertTexts.vldMaxValue, label, rangeMax), control.text)
		else
			self:SetError(string.format(kAlertTexts.vldNotANumber, label), control.text)
		end
	else
		return result
	end
end

function FormsValidator:GetIntegerInput(control, default, required, rangeMin, rangeMax)
	local result = self:GetNumberInput(control, default, required, rangeMin, rangeMax)
	if result and math.floor(result) ~= result then
		local label = string.rtrim(control.label:GetText(), ":")
		self:SetError(string.format("%s must be a whole number", label, rangeMax), control.text)
	else
		return result
	end
end

kUtils.FormsValidator = FormsValidator