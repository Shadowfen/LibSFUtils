zo_floor = math.floor

require "LibSFUtils.test.tk"
require "LibSFUtils.test.zos"

require "LibSFUtils.LibSFUtils_Global"
require "LibSFUtils.SFUtils_Color"
require "LibSFUtils.LibSFUtils"
local TK = TestKit
local SF = LibSFUtils

local TR = test_run
local d = print


local moduleName = "SF_Color"
local mn = "SF_Color"

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

local function ConvertHexToRGBA(colourString)
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
    return r/255, g/255, b/255, a/255, r, g, b, a
end


-- main
TK.init()


local function clear_lsfc(sfc)
  sfc.rbg = {}
  sfc.hex = ""
end
local lsfc = {
  rgb = {},
  hex = ""
}

d("testing local setRGB...")
d("-----------------------")
setRGB(lsfc, 255,255,255,255)
TK.assertTrue(lsfc.rgb.r == 1,"red set 1")
TK.assertTrue(lsfc.rgb.g == 1,"green set 1")
TK.assertTrue(lsfc.rgb.b == 1,"blue set 1")
TK.assertTrue(lsfc.rgb.a == 1,"a set 1")
d("hex = "..lsfc.hex)
d("\n")
clear_lsfc(lsfc)

setRGB(lsfc, 0.1,0.20,0.3,0.4)
TK.assertTrue(lsfc.rgb.r == 0.1,"red set "..lsfc.rgb.r)
TK.assertTrue(lsfc.rgb.g == 0.2,"green set "..lsfc.rgb.g)
TK.assertTrue(lsfc.rgb.b == 0.3,"blue set "..lsfc.rgb.b)
TK.assertTrue(lsfc.rgb.a == 0.4,"a set "..lsfc.rgb.a)
d("hex = "..lsfc.hex)
d("\n")
clear_lsfc(lsfc)

d("testing ConvertHexToRGBA...")
d("-----------------------")
local fr, fg, fb,fa,r,g,b,a = ConvertHexToRGBA("AABBCCDD")
d("\n")


d("testing SF_Color:New...")
d("-----------------------")
local sfc = SF.SF_Color:New(255,255,255,255)
TK.assertNotNil(sfc,"SFC call create [2,255]")
TK.assertTrue(sfc.rgb.r == 1,"red set "..sfc.rgb.r)
TK.assertTrue(sfc.rgb.g == 1,"green set "..sfc.rgb.g)
TK.assertTrue(sfc.rgb.b == 1,"blue set "..sfc.rgb.b)
TK.assertTrue(sfc.rgb.a == 1,"a set "..sfc.rgb.a)
d("\n")
sfc = nil

local sfc = SF.SF_Color:New(.1,.2,.3,.4)
TK.assertNotNil(sfc,"SFC call create [0,1]")
local r, g, b, a = sfc:UnpackRGBA()
TK.assertTrue(sfc.rgb.r == r,"red set "..sfc.rgb.r.." "..r)
TK.assertTrue(sfc.rgb.g == g,"green set "..sfc.rgb.g.." "..g)
TK.assertTrue(sfc.rgb.b == b,"blue set "..sfc.rgb.b.." "..b)
TK.assertTrue(sfc.rgb.a == a,"a set "..sfc.rgb.a.." "..a)
d("\n")
sfc = nil

local sfc = SF.SF_Color:New("AABBCCDD") -- remember format is aarrggbb
TK.assertNotNil(sfc,"SFC call create hex")
local r, b, g, a = sfc:UnpackRGBA()
--d("r="..sfc.rgb.r.." orig="..(tonumber("AA",16)/255).." unpacked r="..r)
TK.assertTrue(sfc.rgb.r == tonumber("BB",16)/255,"red   set AA "..sfc.rgb.r.." "..r.." BB="..tonumber("BB",16)/255)
TK.assertTrue(sfc.rgb.g == tonumber("CC",16)/255,"green set BB "..sfc.rgb.g.." "..g.." CC="..tonumber("CC",16)/255)
TK.assertTrue(sfc.rgb.b == tonumber("DD",16)/255,"blue  set CC "..sfc.rgb.b.." "..b.." DD="..tonumber("DD",16)/255)
TK.assertTrue(sfc.rgb.a == tonumber("AA",16)/255,"a     set DD "..sfc.rgb.a.." "..a.." AA="..tonumber("AA",16)/255)
d("\n")
sfc = nil




d("\n")
TK.showResult()
d()