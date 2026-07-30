# Convenience Color Tables

Defines values for : junk, normal, fine, superior, epic, legendary as well as some other colors that I commonly use

`LibSFUtils.colors` - master table of colors in both hex and rgb <br>
`LibSFUtils.hex` - an alias table for just the hex color values <br>
`LibSFUtils.rgb` - an alias table for just the rgb color values <br>

# Standalone Color Functions
## colorRGBToHex()
`function sfutil.colorRGBToHex(r, g, b)`

Turn a ([0,1])^3 RGB colour to "ABCDEF" form.
## colorHexToRGBA()
`function sfutil.colorHexToRGBA(colourString)`

Convert "rrggbb" hex color into float numbers.<br>
Prefer [sfutil.ConvertHexToRGBA()](https://github.com/Shadowfen/LibSFUtils/wiki/SFUtils_Color#converthextorgba) as it is more flexible.

## ConvertRGBToHex(r, g, b)
`function sfutil.ConvertRGBToHex(r, g, b)`

Turn a ([0,1])^3 RGB colour to "|cABCDEF" form. We could use
ZO_ColorDef to build this, but we use so many colors, we won't do it.<br>
Note: This is NOT the same as the LibSFUtils.colorRGBToHex() function!

## ConvertHexToRGBA()
`function sfutil.ConvertHexToRGBA(colourString)`

Convert a colour from hexadecimal form to `{[0,1],[0,1],[0,1]}` RGB form.<br>
Note: This is NOT the same as the older LibSFUtils.colorHexToRGBA() function
as it can convert from a variety of hex string formats for colors:<br>
|crrggbb, aarrggbb, and rrggbb

## ConvertHexToRGBAPacked()
`function sfutil.ConvertHexToRGBAPacked(colourString)`

Convert a colour from "|cABCDEF" form to [0,1] RGB form and return them in a table.

# The SF_Color Object

## SF_Color:New()
`function SF_Color:New(pr, pg, pb, pa)`

Create a color object.<br>
This is a storage container for:
* hex - a 6-character hex representation of the RGB color
* rgb - a table containing the float values for r, g, b, a  (values btwn 0-1)with some handy related functions.

Why not use the already existing ZO_ColorDef? The intention is to have an object
which does not do as much calculation behind the scenes with every use - with the
intention of optimizing speed at the expense of a little extra memory.
The capability to convert between SF_Color and ZO_ColorDef is provided.

Parameters options:
* pr, pg, pb, pa - The RGB floats between 0-1.
  Missing (nil) rgba values will be set to 1.
* pr - The hex value (6-character string rrggbb) to set the color to.
* pr - The hex value (8-character string aarrggbb) to set the color to.
* pr - Another SF_Color object to copy values from.
* pr - A ZO_ColorDef to copy/calculate values from.

## SF_Color:UnpackRGB()
`function SF_Color:UnpackRGB()`

Returns the color values r, g, b (in that order): color values are in [0,1]

## SF_Color:UnpackRGBA()
`function SF_Color:UnpackRGBA()`

Returns the color values r, g, b, a (in that order): color values are in [0,1]

## SF_Color:SetAlpha
`function SF_Color:SetAlpha(a)`

## SF_Color:SetColor()
`function SF_Color:SetColor(r, g, b, a)`

Set a color object to a particular color value. 

Parameters:
* pr, pg, pb, pa - The RGB floats between 0-1. Missing (nil) rgba values will be set to 1.
* pr - The hex value (6-character string) to set the color to.
* pr - Another SF_Color object to copy values from.
* pr - A ZOS ZO_ColorDef to copy/calculate values from.

## SF_Color:ToZO_ColorDef()
`function SF_Color:ToZO_ColorDef()`

Create a ZO_ColorDef object with the same color values as are in the SF_Color object.

Returns a ZO_ColorDef object.

## SF_Color:Colorize()
`function SF_Color:Colorize(text)`

Add the colorizing markup to a string of text for display

Parameter:
* text - string text to be colorized, or
* text - number to use GetString() on to get text to color

Return:
* string - colorized text

## SF_Color:IsEqual()
`function SF_Color:IsEqual(other)`

Determine if the color values are equivalent (even if the structures are not).
Parameter:
* other - a ZO_ColorDef object, or
* other - a SF_Color object

## SF_Color:Clone()
`function SF_Color:Clone()`

Create another SF_Color instance that as the same color values as this one.

## SF_Color:ToHex()
`function SF_Color:ToHex()`







