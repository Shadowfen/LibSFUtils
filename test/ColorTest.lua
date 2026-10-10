package.path = package.path .. ";C:/Users/scott/Documents/SFAddons/TK/?.lua;C:/Users/scott/Documents/Elder Scrolls Online/live/AddOns/LibSFUtils/?.lua"

require "zos"
require "tk"
local TK = TestKit

require "LibSFUtils_Global"
require "SFUtils_Logger"
require "SFUtils_Color"
require "LibSFUtils"
local SF = LibSFUtils


local moduleName = "SF_Color"
local mn = moduleName

-- --------------------------------------------------------
-- helpers
-- --------------------------------------------------------

local function setRGB(sfcolor, r, g, b, a)
	r = r>1 and r/255 or r
	g = g>1 and g/255 or g
	b = b>1 and b/255 or b
	a = a and (a > 1 and a / 255 or a)

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
    if string.sub(colourString, 1, 2):lower() == "|c" then
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
  sfc.rgb = {}
  sfc.hex = ""
end

local lsfc = {
  rgb = {},
  hex = ""
}

-- --------------------------------------------------------
-- tests
-- --------------------------------------------------------

local function test_setRGB1()
    TK.printSuite(mn, "testing local setRGB...1")

    setRGB(lsfc, 255,255,255,255)

    TK.assertTrue(lsfc.rgb.r == 1,"red set 1")
    TK.assertTrue(lsfc.rgb.g == 1,"green set 1")
    TK.assertTrue(lsfc.rgb.b == 1,"blue set 1")
    TK.assertTrue(lsfc.rgb.a == 1,"a set 1")
    TK.assertTrue(lsfc.hex == "", "hex unchanged")

    d("hex = "..lsfc.hex)
    d("\n")
    clear_lsfc(lsfc)
    d("-----------------------")
end

local function test_setRGB2()
    TK.printSuite(mn, "testing local setRGB...2")
    setRGB(lsfc, 0.1,0.20,0.3,0.4)

    TK.assertTrue(lsfc.rgb.r == 0.1,"red set "..lsfc.rgb.r)
    TK.assertTrue(lsfc.rgb.g == 0.2,"green set "..lsfc.rgb.g)
    TK.assertTrue(lsfc.rgb.b == 0.3,"blue set "..lsfc.rgb.b)
    TK.assertTrue(lsfc.rgb.a == 0.4,"a set "..lsfc.rgb.a)
    TK.assertTrue(lsfc.hex == "", "hex unchanged")

    d("hex = "..lsfc.hex)
    d("\n")
    clear_lsfc(lsfc)
    d("-----------------------")
end

local function test_ConvertHexToRGBA()
    TK.printSuite(mn, "testing ConvertHexToRGBA...")

    local fr, fg, fb, fa, r, g, b, a = ConvertHexToRGBA("AABBCCDD")

    TK.assertTrue(fr == 187 / 255, "red normalized")
    TK.assertTrue(fg == 204 / 255, "green normalized")
    TK.assertTrue(fb == 221 / 255, "blue normalized")
    TK.assertTrue(fa == 170 / 255, "alpha normalized")

    TK.assertTrue(r == 187, "red raw")
    TK.assertTrue(g == 204, "green raw")
    TK.assertTrue(b == 221, "blue raw")
    TK.assertTrue(a == 170, "alpha raw")

    d("\n")
    d("-----------------------")
end


local function test_Constructor1()
    local fn = "testing SF_Color:New...1"
    TK.printSuite(mn, fn)

    local sfc = SF.SF_Color:New(255, 255, 255, 255)

    TK.assertNotNil(sfc, "SFC call create [0,255]")

    TK.assertTrue(sfc.rgb.r == 1, "red set " .. sfc.rgb.r)
    TK.assertTrue(sfc.rgb.g == 1, "green set " .. sfc.rgb.g)
    TK.assertTrue(sfc.rgb.b == 1, "blue set " .. sfc.rgb.b)
    TK.assertTrue(sfc.rgb.a == 1, "alpha set " .. sfc.rgb.a)
    TK.assertTrue(sfc.hex == "ffffff", "hex set " .. sfc.hex)

    d("\n")
    d("-----------------------")
end

local function test_Constructor2()
    local fn = "testing SF_Color:New...2"
    TK.printSuite(mn, fn)

    local sfc = SF.SF_Color:New(0.1, 0.2, 0.3, 0.4)

    TK.assertNotNil(sfc, "SFC call create [0,1]")

    local r, g, b, a = sfc:UnpackRGBA()

    TK.assertTrue(r == 0.1, "red set " .. r)
    TK.assertTrue(g == 0.2, "green set " .. g)
    TK.assertTrue(b == 0.3, "blue set " .. b)
    TK.assertTrue(a == 0.4, "alpha set " .. a)

    TK.assertTrue(sfc.rgb.r == 0.1, "rgb red set " .. sfc.rgb.r)
    TK.assertTrue(sfc.rgb.g == 0.2, "rgb green set " .. sfc.rgb.g)
    TK.assertTrue(sfc.rgb.b == 0.3, "rgb blue set " .. sfc.rgb.b)
    TK.assertTrue(sfc.rgb.a == 0.4, "rgb alpha set " .. sfc.rgb.a)

    TK.assertTrue(sfc.hex == "19334c", "hex set " .. sfc.hex)

    d("\n")
    d("-----------------------")
end

local function test_Constructor3()
    TK.printSuite(mn, "testing SF_Color:New...3")

    -- AARRGGBB
    local sfc = SF.SF_Color:New("AABBCCDD")

    TK.assertNotNil(sfc, "SFC call create hex")

    local r, g, b, a = sfc:UnpackRGBA()

    TK.assertTrue(sfc.rgb.r == tonumber("BB", 16) / 255,
        "red set " .. sfc.rgb.r .. " expected " .. tonumber("BB", 16) / 255)
    TK.assertTrue(sfc.rgb.g == tonumber("CC", 16) / 255,
        "green set " .. sfc.rgb.g .. " expected " .. tonumber("CC", 16) / 255)
    TK.assertTrue(sfc.rgb.b == tonumber("DD", 16) / 255,
        "blue set " .. sfc.rgb.b .. " expected " .. tonumber("DD", 16) / 255)
    TK.assertTrue(sfc.rgb.a == tonumber("AA", 16) / 255,
        "alpha set " .. sfc.rgb.a .. " expected " .. tonumber("AA", 16) / 255)

    TK.assertTrue(r == tonumber("BB", 16) / 255, "unpacked red " .. r)
    TK.assertTrue(g == tonumber("CC", 16) / 255, "unpacked green " .. g)
    TK.assertTrue(b == tonumber("DD", 16) / 255, "unpacked blue " .. b)
    TK.assertTrue(a == tonumber("AA", 16) / 255, "unpacked alpha " .. a)

    d("\n")
    d("-----------------------")
end

local function test_Constructor4()
    local fn = "testing SF_Color:New...4"
    TK.printSuite(mn, fn)

    local sfc = SF.SF_Color:New(0, 0, 0, 0)

    TK.assertNotNil(sfc, "SFC call create zero")

    TK.assertTrue(sfc.rgb.r == 0, "red set " .. sfc.rgb.r)
    TK.assertTrue(sfc.rgb.g == 0, "green set " .. sfc.rgb.g)
    TK.assertTrue(sfc.rgb.b == 0, "blue set " .. sfc.rgb.b)
    TK.assertTrue(sfc.rgb.a == 0, "alpha set " .. sfc.rgb.a)

    TK.assertTrue(sfc.hex == "000000", "hex set " .. sfc.hex)
end

local function test_Initialize()
    local fn = "testing SF_Color:Initialize..."
    TK.printSuite(mn, fn)

    local sfc = SF.SF_Color:New(255, 0, 0, 1)
    local rgb = sfc.rgb

    sfc:Initialize(0, 255, 0, 128)

    TK.assertTrue(sfc.rgb == rgb, "rgb table reused")

    TK.assertTrue(sfc.rgb.r == 0, "red")
    TK.assertTrue(sfc.rgb.g == 1, "green")
    TK.assertTrue(sfc.rgb.b == 0, "blue")
    TK.assertTrue(sfc.rgb.a == 128 / 255, "alpha")

    TK.assertTrue(sfc.hex == "00ff00", "hex " .. sfc.hex)
end

local function test_SetColor1()
    local fn = "testing SF_Color:SetColor..."
    TK.printSuite(mn, fn)

    local sfc = SF.SF_Color:New(1, 1, 1, 1)

    sfc:SetColor(128, 64, 32, 16)

    TK.assertTrue(sfc.rgb.r == 128 / 255, "red")
    TK.assertTrue(sfc.rgb.g == 64 / 255, "green")
    TK.assertTrue(sfc.rgb.b == 32 / 255, "blue")
    TK.assertTrue(sfc.rgb.a == 16 / 255, "alpha")

    TK.assertTrue(sfc.hex == "804020", "hex " .. sfc.hex)
end

local function test_UnpackRGB()
    local fn = "testing SF_Color:UnpackRGB..."
    TK.printSuite(mn, fn)

    local sfc = SF.SF_Color:New(128, 64, 32, 16)

    local r, g, b = sfc:UnpackRGB()

    TK.assertTrue(r == 128 / 255, "red")
    TK.assertTrue(g == 64 / 255, "green")
    TK.assertTrue(b == 32 / 255, "blue")
end

local function test_UnpackRGBLegacy()
    local fn = "testing SF_Color:UnpackRGB legacy..."
    TK.printSuite(mn, fn)

    local sfc = {
        r = 0.1,
        g = 0.2,
        b = 0.3
    }

    local r, g, b = SF.SF_Color.UnpackRGB(sfc)

    TK.assertTrue(r == 0.1, "red " .. r)
    TK.assertTrue(g == 0.2, "green " .. g)
    TK.assertTrue(b == 0.3, "blue " .. b)
end

local function test_UnpackRGBAZero()
    TK.printSuite(mn, "testing SF_Color:UnpackRGBA zero...")

    local sfc = SF.SF_Color:New(0, 0, 0, 0)

    local r, g, b, a = sfc:UnpackRGBA()

    TK.assertTrue(r == 0, "red")
    TK.assertTrue(g == 0, "green")
    TK.assertTrue(b == 0, "blue")
    TK.assertTrue(a == 0, "alpha")
end

local function test_Clone()
    local fn = "testing SF_Color:Clone..."
    TK.printSuite(mn, fn)

    local original = SF.SF_Color:New(128, 64, 32, 16)
    local clone = original:Clone()

    TK.assertNotNil(clone, "clone created")

    if clone then
        TK.assertTrue(clone ~= original, "clone is different object")
        TK.assertTrue(clone.rgb ~= original.rgb, "clone has different rgb table")

        TK.assertTrue(clone.rgb.r == 128 / 255, "red copied")
        TK.assertTrue(clone.rgb.g == 64 / 255, "green copied")
        TK.assertTrue(clone.rgb.b == 32 / 255, "blue copied")
        TK.assertTrue(clone.rgb.a == 16 / 255, "alpha copied")
        TK.assertTrue(clone.hex == "804020", "hex copied")
    end
end

local function test_CloneIndependence()
    TK.printSuite(mn, "testing SF_Color:Clone independence...")

    local original = SF.SF_Color:New(128, 64, 32, 16)
    local clone = original:Clone()

    clone.rgb.r = 0

    TK.assertTrue(clone.rgb.r == 0, "clone changed")
    TK.assertTrue(original.rgb.r == 128 / 255, "original unchanged")
end

local function test_IsEqual()
    local fn = "testing SF_Color:IsEqual..."
    TK.printSuite(mn, fn)

    local c1 = SF.SF_Color:New(128, 64, 32, 16)
    local c2 = SF.SF_Color:New(128, 64, 32, 16)
    local c3 = SF.SF_Color:New(128, 64, 33, 16)
    local c4 = SF.SF_Color:New(128, 64, 32, 17)

    TK.assertTrue(c1:IsEqual(c2), "equal colors")
    TK.assertTrue(not c1:IsEqual(c3), "different blue")
    TK.assertTrue(not c1:IsEqual(c4), "different alpha")

    local zc = ZO_ColorDef:New(128 / 255, 64 / 255, 32 / 255, 16 / 255)

    TK.assertTrue(c1:IsEqual(zc), "equal ZO_ColorDef")

    zc.b = 33 / 255

    TK.assertTrue(not c1:IsEqual(zc), "different ZO_ColorDef blue")
end

local function test_ToHex()
    local fn = "testing SF_Color:ToHex..."
    TK.printSuite(mn, fn)

    local sfc = SF.SF_Color:New(128, 64, 32, 16)

    TK.assertTrue(sfc:ToHex() == "804020", "ToHex " .. sfc:ToHex())
end

local function test_ToZO_ColorDef()
    local fn = "testing SF_Color:ToZO_ColorDef..."
    TK.printSuite(mn, fn)

    local sfc = SF.SF_Color:New(128, 64, 32, 16)
    local zc = sfc:ToZO_ColorDef()

    TK.assertNotNil(zc, "ZO_ColorDef created")

    if zc then
        local r, g, b, a = zc:UnpackRGBA()

        TK.assertTrue(r == 128 / 255, "red " .. r)
        TK.assertTrue(g == 64 / 255, "green " .. g)
        TK.assertTrue(b == 32 / 255, "blue " .. b)
        TK.assertTrue(a == 16 / 255, "alpha " .. a)
    end
end

local function test_ColorizeString()
    TK.printSuite(mn, "testing SF_Color:Colorize string...")

    local sfc = SF.SF_Color:New(255, 0, 0, 1)

    local result = sfc:Colorize("Hello")

    TK.assertTrue(result == "|cff0000Hello|r", "colored string " .. result)
end

local function test_ColorizeCall()
    TK.printSuite(mn, "testing SF_Color callable...")

    local sfc = SF.SF_Color:New(255, 0, 0, 1)

    local result = sfc("Hello")

    TK.assertTrue(result == "|cff0000Hello|r",
        "called color " .. result)
end

local function test_ColorizeNil()
    TK.printSuite(mn, "testing SF_Color:Colorize nil...")

    local sfc = SF.SF_Color:New(255, 0, 0, 1)

    TK.assertTrue(sfc:Colorize(nil) == "", "nil produces empty string")
end

local function test_ColorizeNumber()
    TK.printSuite(mn, "testing SF_Color:Colorize number...")

    local sfc = SF.SF_Color:New(255, 0, 0, 1)

    local result = sfc:Colorize(12345)

    TK.assertTrue( result == "|cff0000" .. tostring(12345) .. "|r",
        "numeric string ID")
end

local function test_SetColorZOColorDef()
    TK.printSuite(mn, "testing SF_Color:SetColor ZO_ColorDef...")

    local zc = ZO_ColorDef:New(128/255, 64/255, 32/255, 16/255)

    TK.assertNotNil(zc, "ZO_ColorDef created")

    if zc then
        local sfc = SF.SF_Color:New(0, 0, 0, 0)

        sfc:SetColor(zc)

        local r, g, b, a = sfc:UnpackRGBA()

        TK.assertTrue(r == 128 / 255, "red " .. r)
        TK.assertTrue(g == 64 / 255, "green " .. g)
        TK.assertTrue(b == 32 / 255, "blue " .. b)
        TK.assertTrue(a == 16 / 255, "alpha " .. a)

        TK.assertTrue(sfc.hex == "804020", "hex " .. sfc.hex)
    end
end

local function test_SetColorSFColor()
    TK.printSuite(mn, "testing SF_Color:SetColor SF_Color...")

    local source = SF.SF_Color:New(128, 64, 32, 16)
    local target = SF.SF_Color:New(255, 255, 255, 255)

    target:SetColor(source)

    TK.assertTrue(target ~= source, "different objects")
    TK.assertTrue(target.rgb ~= source.rgb, "different rgb tables")

    TK.assertTrue(target.rgb.r == 128 / 255, "red copied")
    TK.assertTrue(target.rgb.g == 64 / 255, "green copied")
    TK.assertTrue(target.rgb.b == 32 / 255, "blue copied")
    TK.assertTrue(target.rgb.a == 16 / 255, "alpha copied")
    TK.assertTrue(target.hex == "804020", "hex copied")

    TK.assertTrue(target.rgb.r == source.rgb.r, "red matches source")
    TK.assertTrue(target.rgb.g == source.rgb.g, "green matches source")
    TK.assertTrue(target.rgb.b == source.rgb.b, "blue matches source")
    TK.assertTrue(target.rgb.a == source.rgb.a, "alpha matches source")
end


function test_runAllColor()
    test_setRGB1()
    test_setRGB2()
    test_ConvertHexToRGBA()
    test_Constructor1()
    test_Constructor2()
    test_Constructor3()
    test_Constructor4()
    test_Initialize()
    test_SetColor1()
    test_UnpackRGB()
    test_UnpackRGBLegacy()
    test_UnpackRGBAZero()
    test_Clone()
    test_CloneIndependence()
    test_IsEqual()
    test_ToHex()
    test_ToZO_ColorDef()
    test_ColorizeString()
    test_ColorizeCall()
    test_ColorizeNil()
    test_ColorizeNumber()
    test_SetColorZOColorDef()
    test_SetColorSFColor()
end

if not Suite then
    TK.init()
  
    test_runAllColor()
    
    TK.showResult()
end
