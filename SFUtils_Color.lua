--[[
	This module extends LibSFUtils with a suite of functions for converting between color 
	representations (RGB floats, Hex strings, and ESO color tags) and a dedicated SF_Color 
	class for managing color state. It is optimized for performance in the ESO addon 
	environment, minimizing runtime calculations by caching hex values.

	Key Features:

		Format Flexibility: Handles rrggbb, aarrggbb, and |crrggbb hex strings automatically.
		Robust Conversion: Safe handling of nil inputs and mixed integer/float inputs.
		Object-Oriented Color: SF_Color class with methods for cloning, comparing, and colorizing text.
		Performance: Caches hex strings to avoid repeated formatting calculations.

	Technical Notes

    Alpha Handling: The SF_Color object stores alpha internally, but the hex property (and ToHex()) 
		only stores the 6-character RGB hex. This is intentional for ESO text tags (|cRRGGBB), which 
		do not support alpha in the tag itself. Alpha must be handled by the UI control (e.g., SetTextColor) 
		if transparency is needed for the text element itself.
    Input Ambiguity: The SetColor method resolves ambiguity between 0–1 and 0–255 ranges by checking 
		the first argument (r). If r > 1, it assumes all numeric arguments are integers. Mixing 
		types (e.g., r=0.5, g=200) is discouraged and may yield unexpected results.
    Performance: The library avoids creating ZO_ColorDef objects unless explicitly requested (ToZO_ColorDef), 
		reducing overhead in loops or frequent UI updates.

--]]
-- LibSFUtils should already be defined in prior loaded file
local sfutil = LibSFUtils or {}

local zo_floor = zo_floor
---------------------
--[[
	sfutil.colorRGBToHex(r, g, b)

	Converts RGB float values (0–1) to a 6-character hex string (RRGGBB).

    Parameters:
        r, g, b (number): Float values between 0 and 1.
        Note: If any value is nil, it defaults to 1 (White).
    Returns: String (e.g., "FF0000").
    Returns nil if all three inputs are explicitly nil (though the default logic usually prevents this).
]]
function sfutil.colorRGBToHex(r, g, b)
	if not r or not g or not b then return nil end
  return string.format("%.2x%.2x%.2x", zo_floor((tonumber(r) or 1) * 255),
                zo_floor((tonumber(g) or 1) * 255), zo_floor((tonumber(b) or 1) * 255))
end

--[[
	sfutil.colorHexToRGBA(colourString)

	Converts a 6-character hex string (rrggbb) to RGB float values.

    Parameters: colourString (string).
    Returns: r, g, b, a (four numbers between 0 and 1).
    Defaults: Returns 1, 1, 1, 1 (White, opaque) if input is nil or invalid.
    Note: This function does not support alpha in the input string. Prefer sfutil.ConvertHexToRGBA for flexibility.
--]]
function sfutil.colorHexToRGBA(colourString)
	if not colourString then
		return 1,1,1,1
	end
	local r=tonumber(string.sub(colourString, 1, 2), 16) or 255
	local g=tonumber(string.sub(colourString, 3, 4), 16) or 255
	local b=tonumber(string.sub(colourString, 5, 6), 16) or 255
	return r/255, g/255, b/255, 1
end

--[[
	sfutil.ConvertRGBToHex(r, g, b)

	Converts RGB floats to an ESO color tag string (|cRRGGBB). We could use
		ZO_ColorDef to build this, but we use so many colors, we won't do it.

    Parameters: r, g, b (number).
    Safety: If any input is nil, it defaults to 1 (White).
    Returns: String (e.g., "|cFF0000").
	Note: This is NOT the same as the LibSFUtils.colorRGBToHex() function!
--]]
function sfutil.ConvertRGBToHex(r, g, b)
    r = r or 1
    g = g or 1
    b = b or 1
    return string.format("|c%.2x%.2x%.2x", zo_floor(r * 255), zo_floor(g * 255), zo_floor(b * 255))
end

--[[
	sfutil.ConvertHexToRGBA(colourString)

	Converts various hex string formats to RGB float values with alpha support.

	Supported Formats:
		|crrggbb (ESO tag format)
		aarrggbb (8-char with alpha)
		rrggbb (6-char standard)
	Parameters: colourString (string).
	Returns: r, g, b, a (numbers 0–1).
	Defaults: Returns 1, 1, 1, 1 for invalid inputs or non-string types.
--]]
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

--[[
	sfutil.ConvertHexToRGBAPacked(colourString)

	Convenience wrapper that returns the result of ConvertHexToRGBA as a table.

		Returns: Table {r = ..., g = ..., b = ..., a = ...}.
--]]
function sfutil.ConvertHexToRGBAPacked(colourString)
    local r, g, b, a = sfutil.ConvertHexToRGBA(colourString)
    return {r = r, g = g, b = b, a = a}
end


-- ------------------------------------------
--[[
	SF_Color Class

	A lightweight object for storing and manipulating color data. It caches the hex 
	representation to optimize text rendering.
--]]
SF_Color = {}
SF_Color.__index = SF_Color
--[[
	color:__call(text)

	Allows the object to be called like a function.

    Usage: myColor("Hello") is equivalent to myColor:Colorize("Hello").
--]]
SF_Color.__call = function(self, text)
        return self:Colorize(text)
    end

--[[
	Don't want to make this public because it can leave
	SF_Color in an inconsistant state - hex is not set
	from these values. We just assume that has been or
	will be taken care of.
--]]
local function setRGB(sfcolor, r, g, b, a)
	r = r>1 and r/255 or r
	g = g>1 and g/255 or g
	b = b>1 and b/255 or b
	a = a>1 and a/255 or a
	sfcolor.rgb.r = r or 1
	sfcolor.rgb.g = g or 1
	sfcolor.rgb.b = b or 1
	sfcolor.rgb.a = a or 1
end


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

	SF_Color:New(pr, pg, pb, pa)

	Parameters options:
		pr, pg, pb, pa - The RGB floats between 0-1.
			Missing (nil) rgba values will be set to 1.
		pr - The hex value (6-character string rrggbb) to set the color to.
		pr - The hex value (8-character string aarrggbb) to set the color to.
		pr - Another SF_Color object to copy values from.
		pr - A ZO_ColorDef to copy/calculate values from.

    Returns: New SF_Color object.
--]]
function SF_Color:New(pr, pg, pb, pa)
	local c = setmetatable({},SF_Color)
    c.rgb = {r=1, g=1, b=1, a=1}
	SF_Color.SetColor(c, pr, pg, pb, pa)

    return c
end

--[[
	SF_Color:Initialize(pr, pg, pb, pa)

	Resets an existing SF_Color object to a new color.

    Usage: Useful for reusing objects to reduce garbage collection.
    Parameters: Same as New.
--]]
function SF_Color:Initialize(pr, pg, pb, pa)
    self.rgb = {r=1, g=1, b=1, a=1}
	self:SetColor(pr, pg, pb, pa)
end

--[[
	color:UnpackRGB()

    Returns: r, g, b (0–1).
--]]
function SF_Color:UnpackRGB()
	if not self.rgb and self.r then
		return self.r, self.g, self.b
	end
    return self.rgb.r, self.rgb.g, self.rgb.b
end

--[[
	color:UnpackRGBA()

	Returns RGBA float values.

    Returns: r, g, b, a (0–1).
    Safety: Handles both SF_Color rgb table structure and ZO_ColorDef r/g/b direct properties.
--]]
function SF_Color:UnpackRGBA()
	if self.r then
		-- is a ZO_ColorDef type
		return self.r, self.g, self.b, self.a or 1
	elseif self.rgb then
		-- is a SF_Color type
		return self.rgb.r or 1, self.rgb.g or 1, self.rgb.b or 1, self.rgb.a or 1
	end
    return 1, 1, 1, 1
end

--[[
	color:SetAlpha(a)

	Updates only the alpha channel.

    Parameters: a (number 0–1 or 0–255; auto-converted).
--]]
function SF_Color:SetAlpha(a)
	if self.rgb then
		self.rgb.a = a
	elseif self.r then
		self.a = a
	end
end


--[[
	Set a color object to a particular color value.

	color:SetColor(r, g, b, a)

	Parameters:
		pr, pg, pb, pa (number)- The RGB floats between 0-1.
			Missing (nil) rgba values will be set to 1.
		pr (string) - The hex value (6-character string) to set the color to.
		pr (table) - Another SF_Color object to copy values from.
		pr (table) - A ZOS ZO_ColorDef to copy/calculate values from.


    String: Interprets as Hex.
    Table: Interprets as SF_Color or ZO_ColorDef (copies values).
    Number:
        If r > 1: Assumes all inputs are integers (0–255) and converts to floats.
        If r <= 1: Assumes all inputs are floats (0–1).
    Returns: self (for chaining).

--]]
function SF_Color:SetColor(r, g, b, a)
    if type(r) == "string" then
		-- r is hex value
		self.hex = r
		self.rgb.r, self.rgb.g, self.rgb.b, self.rgb.a = sfutil.ConvertHexToRGBA(r)

    elseif type(r) == "table" then
		if r.r ~= nil then
			-- r is ZO_ColorDef
			setRGB(self, r:UnpackRGBA())
			self.hex = sfutil.colorRGBToHex(r:UnpackRGB())

		else
			-- r is SF_Color we are copying
			setRGB(self, r:UnpackRGBA())
			self.hex = r.hex
		end

	elseif type(r) == "number" then
		-- Determine scale based on the FIRST argument only to avoid mixed input ambiguity
		if r > 1 then
			-- Assume all are 0-255
			setRGB(self, r/255, g/255, b/255, a/255)
		else
			-- Assume all are 0-1
			setRGB(self, r, g, b, a)
		end
		self.hex = sfutil.colorRGBToHex(self:UnpackRGB())
	end
	return self
end

--[[ ---------------------
	Create a new ZO_ColorDef object with the same color values
	as are in the SF_Color object.

	color:ToZO_ColorDef()

    Returns: ZO_ColorDef object.
--]]
function SF_Color:ToZO_ColorDef()
	return ZO_ColorDef:New(self:UnpackRGBA())
end

--[[ ---------------------
	wraps the ESO colorizing markup on a string of text for display

	color:Colorize(text)

	Parameter:
		text - string text to be colorized,
		text - number to use GetString() to get localized text to color,
		text - nil to return "" (empty string)

	Return:
		string - colorized text (e.g., "|cFF0000Hello|r")
--]]
function SF_Color:Colorize(text)
    local strprompt
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
	Compares two color objects.

	color:IsEqual(other)
	Parameter:
		other - a ZO_ColorDef object, or
		other - a SF_Color object

    Logic: Compares RGB and Alpha values.
    Returns: true if RGB and Alpha are equal, false otherwise.
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

--[[
	color:Clone()

	Creates a deep copy of the color object.

    Returns: New SF_Color instance with identical values.
--]]
function SF_Color:Clone()
	return SF_Color:New(self:UnpackRGBA())
end

--[[
	color:ToHex()

	Returns the cached hex string.

    Returns: String (e.g., "FF0000").
    Note: This is the 6-character RGB hex. Alpha is not included in this specific string.
--]]
function SF_Color:ToHex()
    return self.hex
end

sfutil.SF_Color = SF_Color
