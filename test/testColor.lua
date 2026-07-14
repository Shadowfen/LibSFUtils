package.path = package.path .. ";C:/Users/scott/Documents/SFAddons/TK/?.lua;C:/Users/scott/Documents/Elder Scrolls Online/live/AddOns/LibSFUtils/?.lua"

require "zos"
require "tk"
local TK = TestKit

require "LibSFUtils_Global"
require "SFUtils_Logger"
require "SFUtils_Color"
require "LibSFUtils"
local SF = LibSFUtils

local TR = test_run


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




local function clear_lsfc(sfc)
  sfc.rbg = {}
  sfc.hex = ""
end
local lsfc = {
  rgb = {},
  hex = ""
}

function test_setRGB1()
    local fn = "testing local setRGB...1"
    TK.printSuite(mn,fn)
    setRGB(lsfc, 255,255,255,255)
    TK.assertTrue(lsfc.rgb.r == 1,"red set 1")
    TK.assertTrue(lsfc.rgb.g == 1,"green set 1")
    TK.assertTrue(lsfc.rgb.b == 1,"blue set 1")
    TK.assertTrue(lsfc.rgb.a == 1,"a set 1")
    d("hex = "..lsfc.hex)
    d("\n")
    clear_lsfc(lsfc)
    d("-----------------------")
end

function test_setRGB2()
    local fn = "testing local setRGB...2"
    TK.printSuite(mn,fn)
    setRGB(lsfc, 0.1,0.20,0.3,0.4)
    TK.assertTrue(lsfc.rgb.r == 0.1,"red set "..lsfc.rgb.r)
    TK.assertTrue(lsfc.rgb.g == 0.2,"green set "..lsfc.rgb.g)
    TK.assertTrue(lsfc.rgb.b == 0.3,"blue set "..lsfc.rgb.b)
    TK.assertTrue(lsfc.rgb.a == 0.4,"a set "..lsfc.rgb.a)
    d("hex = "..lsfc.hex)
    d("\n")
    clear_lsfc(lsfc)
    d("-----------------------")
end

function test_ConvertHexToRGBA()
    local fn = "testing ConvertHexToRGBA..."
    TK.printSuite(mn,fn)
    local fr, fg, fb,fa,r,g,b,a = ConvertHexToRGBA("AABBCCDD")
    d("\n")
    d("-----------------------")
end


function test_Constructor1()
    local fn = "testing SF_Color:New...1"
    TK.printSuite(mn,fn)
    local sfc = SF.SF_Color:New(255,255,255,255)
    TK.assertNotNil(sfc,"SFC call create [2,255]")
    TK.assertTrue(sfc.rgb.r == 1,"red set "..sfc.rgb.r)
    TK.assertTrue(sfc.rgb.g == 1,"green set "..sfc.rgb.g)
    TK.assertTrue(sfc.rgb.b == 1,"blue set "..sfc.rgb.b)
    TK.assertTrue(sfc.rgb.a == 1,"a set "..sfc.rgb.a)
    d("\n")
    d("-----------------------")
end

function test_Constructor2()
    local fn = "testing SF_Color:New...2"
    TK.printSuite(mn,fn)
    local sfc = SF.SF_Color:New(.1,.2,.3,.4)
    TK.assertNotNil(sfc,"SFC call create [0,1]")
    local r, g, b, a = sfc:UnpackRGBA()
    TK.assertTrue(sfc.rgb.r == r,"red set "..sfc.rgb.r.." "..r)
    TK.assertTrue(sfc.rgb.g == g,"green set "..sfc.rgb.g.." "..g)
    TK.assertTrue(sfc.rgb.b == b,"blue set "..sfc.rgb.b.." "..b)
    TK.assertTrue(sfc.rgb.a == a,"a set "..sfc.rgb.a.." "..a)
    d("\n")
    d("-----------------------")
end

function test_Constructor3()
    local fn = "testing SF_Color:New...3"
    TK.printSuite(mn,fn)
    local sfc = SF.SF_Color:New("AABBCCDD") -- remember format is aarrggbb
    TK.assertNotNil(sfc,"SFC call create hex")
    local r, b, g, a = sfc:UnpackRGBA()
    --d("r="..sfc.rgb.r.." orig="..(tonumber("AA",16)/255).." unpacked r="..r)
    TK.assertTrue(sfc.rgb.r == tonumber("BB",16)/255,"red   set AA "..sfc.rgb.r.." "..r.." BB="..tonumber("BB",16)/255)
    TK.assertTrue(sfc.rgb.g == tonumber("CC",16)/255,"green set BB "..sfc.rgb.g.." "..g.." CC="..tonumber("CC",16)/255)
    TK.assertTrue(sfc.rgb.b == tonumber("DD",16)/255,"blue  set CC "..sfc.rgb.b.." "..b.." DD="..tonumber("DD",16)/255)
    TK.assertTrue(sfc.rgb.a == tonumber("AA",16)/255,"a     set DD "..sfc.rgb.a.." "..a.." AA="..tonumber("AA",16)/255)
    d("\n")
    d("-----------------------")
end


function test_runAllColor()
    TK.init()
  
    test_setRGB1()
    test_setRGB2()
    test_ConvertHexToRGBA()
    test_Constructor1()
    test_Constructor2()
    test_Constructor3()
    
    TK.showResult()
end

if not Suite then
    test_runAllColor()
end
