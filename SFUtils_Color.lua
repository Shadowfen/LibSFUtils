-- LibSFUtils is already defined in prior loaded file
local sfutil = LibSFUtils or {}

---------------------
--[[
    Color conversion functions
]]
-- Turn a ([0,1])^3 RGB colour to "ABCDEF" form.
function sfutil.colorRGBToHex(r, g, b)
  return string.format("%.2x%.2x%.2x", zo_floor(r * 255), zo_floor(g * 255), zo_floor(b * 255))
end

-- Convert "rrggbb" hex color into float numbers.
-- Prefer sfutil.ConvertHexToRGBA() as it is more flexible.
function sfutil.colorHexToRGBA(colourString)
	if not colourString then
		return 1,1,1,1
	end
	local r=tonumber(string.sub(colourString, 1, 2), 16) or 255
	local g=tonumber(string.sub(colourString, 3, 4), 16) or 255
	local b=tonumber(string.sub(colourString, 5, 6), 16) or 255
	return r/255, g/255, b/255, 1
end

-- Turn a ([0,1])^3 RGB colour to "|cABCDEF" form. We could use
-- ZO_ColorDef to build this, but we use so many colors, we won't do it.
-- Note: This is NOT the same as the LibSFUtils.colorRGBToHex() function!
function sfutil.ConvertRGBToHex(r, g, b)
    return string.format("|c%.2x%.2x%.2x", zo_floor(r * 255), zo_floor(g * 255), zo_floor(b * 255))
end

-- Convert a colour from hexadecimal form to {[0,1],[0,1],[0,1]} RGB form.
-- Note: This is NOT the same as the older LibSFUtils.colorHexToRGBA() function
--   as it can convert from a variety of hex string formats for colors:
--      |crrggbb, aarrggbb, and rrggbb
function sfutil.ConvertHexToRGBA(colourString)
	if type(colourString) ~= "string" then 
		return 1,1,1,1
	end
	
    local r, g, b, a
    if string.sub(colourString,1,1) == "|" then
        -- format "|crrggbb"
        r=tonumber(string.sub(colourString, 3, 4), 16) or 255
        g=tonumber(string.sub(colourString, 5, 6), 16) or 255
        b=tonumber(string.sub(colourString, 7, 8), 16) or 255
        a = 255
    elseif #colourString == 8 then
        -- format "aarrggbb"
        a=tonumber(string.sub(colourString, 1, 2), 16) or 255
        r=tonumber(string.sub(colourString, 3, 4), 16) or 255
        g=tonumber(string.sub(colourString, 5, 6), 16) or 255
        b=tonumber(string.sub(colourString, 7, 8), 16) or 255
    elseif #colourString == 6 then
        -- format "rrggbb"
        r=tonumber(string.sub(colourString, 1, 2), 16) or 255
        g=tonumber(string.sub(colourString, 3, 4), 16) or 255
        b=tonumber(string.sub(colourString, 5, 6), 16) or 255
        a = 255
    else
        -- unidentified format
        r = 255
        g = 255
        b = 255
        a = 255
    end
    return r/255, g/255, b/255, a/255
end

-- Convert a colour from "|cABCDEF" form to [0,1] RGB form and return them in a table.
function sfutil.ConvertHexToRGBAPacked(colourString)
    local r, g, b, a = sfutil.ConvertHexToRGBA(colourString)
    return {r = r, g = g, b = b, a = a}
end


-- ------------------------------------------
SF_Color = ZO_Object:Subclass()

--[[ ---------------------
	Create a color object. 
		This is a storage container for:
			hex - a 6-character hex representation of the RGB color
			rgb - a table containing the float values for r, g, b, a  (values btwn 0-1)
		with some handy related functions.
		
		Why not use the already existing ZO_ColorDef? The intention is to have an object
		which does not do as much calculation behind the scenes with every use - with the
		intention of optimizing speed at the expense of a little extra memory.
		The capability to convert between one and the other is provided.
		
	Parameters options:
		pr, pg, pb, pa - The RGB floats between 0-1.
			Missing (nil) rgba values will be set to 1.
		pr - The hex value (6-character string) to set the color to.
		pr - Another SF_Color object to copy values from.
		pr - A ZO_ColorDef to copy/calculate values from.
--]]
function SF_Color:New(pr, pg, pb, pa)
    local c = ZO_Object.New(self)
	c.rgb = {r=1, g=1, b=1, a=1}
	local rgb = c.rgb

	c:SetColor(pr, pg, pb, pa)

    return c
end

--[[ ---------------------
--]]
function SF_Color:UnpackRGB()
    return self.r, self.g, self.b
end

--[[ ---------------------
--]]
function SF_Color:UnpackRGBA()
    return self.r, self.g, self.b, self.a
end

--[[ 
	Don't want to make this public because it can leave
	SF_Color in an inconsistant state - hex is not set
	from these values. We just assume that has been or 
	will be taken care of.
--]]
local function setRGB(sfcolor, r, g, b, a)
	sfcolor.rgb.r = r or 1
	sfcolor.rgb.g = g or 1
	sfcolor.rgb.b = b or 1
	sfcolor.rgb.a = a or 1
end

function SF_Color:SetAlpha(a)
    self.a = a
end


--[[ ---------------------
	Set a color object to a particular color value. 
		
	Parameters:
		pr, pg, pb, pa - The RGB floats between 0-1.
			Missing (nil) rgba values will be set to 1.
		pr - The hex value (6-character string) to set the color to.
		pr - Another SF_Color object to copy values from.
		pr - A ZOS ZO_ColorDef to copy/calculate values from.
--]]
function SF_Color:SetColor(r, g, b, a)
    if type(r) == "string" then
		-- r is hex value
		self.hex = r
		self.rgb.r, self.rgb.g, self.rgb.b, self.rgb.a = sfutil.ConvertHexToRGBA(r)
		--self.hex = sfutil.colorRGBToHex(r,g,b)
		
    elseif type(r) == "table" then
		if r.r ~= nil then
			-- r is ZO_ColorDef
			setRGB(self, r:UnpackRGBA())
			self.hex = sfutil.colorRGBToHex(r:UnpackRGB())
		else
			-- r is SF_Color
			setRGB(self, r:UnpackRGBA())
			self.hex = r.hex
		end
		
	elseif r > 1 or g > 1 or b > 1 or a > 1 then
		-- r is RGB value [0,255]
		setRGB(self, r/255, g/255, b/255, a/255)
		self.hex = sfutil.colorRGBToHex(self:UnpackRGB())
		
	else
		-- r is float value [0,1]
		setRGB(self, r, g, b, a)
		self.hex = sfutil.colorRGBToHex(self:UnpackRGB())
	end
	return self
end

--[[ ---------------------
	Create a ZO_ColorDef object with the same color values
	as are in the SF_Color object.
	
	Returns a ZO_ColorDef object.
--]]
function SF_Color:ToZO_ColorDef()
	return ZO_ColorDef:New(self:UnpackRGBA())
end

--[[ ---------------------
	Add the colorizing markup to a string of text for display
	
	Parameter:
		text - string text to be colorized, or
		text - number to use GetString() on to get text to color
		
	Return:
		string - colorized text
--]]
function SF_Color:Colorize(text)
    if( text == nil ) then
        return ""	-- Do NOT colorize an empty string!
    elseif( type(text) == "string") then
        strprompt = text
    elseif( type(text) == "number") then
        strprompt = GetString(text)
	else
		strprompt = tostring(text)
    end
	--if self then 
	--	if self.rgb then d("r="..self.rgb.r.."  g="..self.rgb.g.."  b="..self.rgb.b) end
	--	if self.hex then d("color to colorize = 0x"..self.hex) end
	--end
	local combineTable = { "|c", self.hex, strprompt, "|r" }
	return table.concat(combineTable)
end

--[[ ---------------------
	Determine if the color values are equivalent (even if the structures are not).
	Paramenter:
		other - a ZO_ColorDef object, or
		other - a SF_Color object
--]]
function SF_Color:IsEqual(other)
	if other.r ~= nil then
		-- ZO_ColorDef
		return self.rgb.r == other.r
		   and self.rgb.g == other.g
		   and self.rgb.b == other.b
		   and self.rgb.a == other.a
	end
	-- SF_Color
	return self.hex == other.hex
	   and self.rgb.a == other.rgb.a
end

function SF_Color:Clone()
	return SF_Color:New(self:UnpackRGBA())
end

function SF_Color:ToHex()
    return self.hex
end
