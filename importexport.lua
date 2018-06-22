local addonInfo, private = ...
local kAlert = private.kAlert 
local kAlertTexts = private.kAlertTexts

-- character table string
local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- encoding
local function EncodeBase64(data)
	return ((data:gsub('.', function(x) 
		local r,b='',x:byte()
		for i = 8, 1 ,-1 do
			r = r .. (b % 2 ^ i - b % 2 ^ (i - 1)> 0 and '1' or '0') end
		return r;
	end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
		if (#x < 6) then return '' end
		local c=0
		for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
		return b:sub(c+1,c+1)
	end))
end

-- decoding
local function DecodeBase64(data)
	data = string.gsub(data, '[^'..b..'=]', '')
	return (data:gsub('.', function(x)
		if (x == '=') then return '' end
		local r,f='',(b:find(x)-1)
		for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
		return r;
	end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
		if (#x ~= 8) then return '' end
		local c=0
		for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
		return string.char(c)
	end))
end

local function Checksum(data)
	local checksum = Utility.Storage.Checksum(data)
	local shortCheck = string.sub(checksum, -6)
	
	local bytes = {}
	for hexPair in shortCheck:gmatch("(%x%x)") do
    	table.insert(bytes, string.char(tonumber(hexPair, 16)))
	end
	
	return EncodeBase64(table.concat(bytes))
end

local function InsertNewLines(str, length)
	local tmp = {}
	for i = 1, str:len(), length do
		table.insert(tmp, str:sub(i, i + length - 1))
	end
	return table.concat(tmp, "\n")
end

local function PackageData(name, type, data)
	local compressed = zlib.deflate(zlib.BEST_COMPRESSION)(data, "finish")
	local encoded = EncodeBase64(compressed)
	
	local result = "KA:" .. name .. ":" .. type .. Checksum(compressed) .. encoded
	return InsertNewLines(result, 76)
end

local function UnpackageData(package)
	local split = package:trim():split(":")
	if #split ~= 3 or split[3]:len() < 6 then
		return nil, nil, nil, kAlertTexts.msgImportCorrupt
	end
	
	if split[1] ~= "KA" then
		return nil, nil, nil, kAlertTexts.msgImportCorrupt
	end
	
	-- Remove whitespace that may have been added by forums, etc.
	split[3] = split[3]:gsub("%s", "")
	
	local name = split[2]
	local type = split[3]:sub(0, 1)
	
	local decoded = DecodeBase64(split[3]:sub(6))
	if Checksum(decoded) ~= split[3]:sub(2, 5) then
		return nil, nil, nil, kAlertTexts.msgImportCorrupt
	end
	
	-- Decode and uncompress
	local data, eof = zlib.inflate()(decoded)
	if not eof then
		return nil, kAlertTexts.msgImportCorrupt
	end
	
	return name, type, data
end

function kAlert.ExportAlert(alertData)
	local serialized, err = kAlert.config.formatAlertExport(alertData, true)
	if not serialized then
		return nil, err
	else
		return PackageData(alertData.name, "a", serialized)
	end
end

function kAlert.ImportAlert(alertData)
	alertData = alertData:trim()

	if alertData:prefix("KA:") then
		local name, type, data, err = UnpackageData(alertData)
		if type:lower() ~= type then
			return nil, "This appears to be an alert set. Use Import Set instead."
		elseif type ~= "a" then
			return nil, "Import format is unrecognized. You may need to update KaruulAlert."
		end
		
		local alert, err = kAlert.config.formatAlertImport(data, 41)
		if not err then
			alert.name = name
			return alert
		else
			return nil, err
		end
	else
		return kAlert.config.formatAlertImport(alertData)
	end
end

function kAlert.ExportSet(alertSet)
	local serialized = kAlert.config.formatSetExport(alertSet)
	return PackageData("", "A", serialized)
end

function kAlert.ImportSet(setData, alertSet)
	setData = setData:trim()

	if setData:prefix("KA:") then
		local name, type, data, err = UnpackageData(setData)
		if type:upper() ~= type then
			return nil, "This appears to be a single alert. Use Import Alert instead."
		elseif type ~= "A" then
			return nil, "Import format is unrecognized. You may need to update KaruulAlert."
		end
		
		kAlert.config.formatSetImport(data, alertSet, 41)
		return alertSet
	else
		kAlert.config.formatSetImport(setData, alertSet)
		return alertSet
	end
end