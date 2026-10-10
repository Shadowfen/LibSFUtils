package.path = package.path .. ";C:/Users/scott/Documents/SFAddons/TK/?.lua;C:/Users/scott/Documents/Elder Scrolls Online/live/AddOns/LibSFUtils/?.lua"

require "zos"
require "tk"
local TK = TestKit

require "LibSFUtils_Global"
require "SFUtils_Logger"
require "SFUtils_Strings"
require "SFUtils_Color"
require "LibSFUtils"
local SF = LibSFUtils

local moduleName = "applyColors"
local mn = moduleName


-- -------------------------------------------------------
-- helpers
-- -------------------------------------------------------

local TEST_COLOR = "FF0000"
local EMBED_COLOR = "00FF00"

-- -------------------------------------------------------
-- tests
-- -------------------------------------------------------

local function testApplyColorNilString()
    TK.printSuite(mn,"NilString")
    local result = LibSFUtils.applyColor(nil, TEST_COLOR)

    TK.assertTrue(result == nil, "nil string should return nil")
end


local function testApplyColorNilColor()
    TK.printSuite(mn,"NilColor")
    local str = "Hello world"

    local result = LibSFUtils.applyColor(str, nil)

    TK.assertEqual(str, result,
        "nil color should return original string")
end


local function testApplyColorEmptyColor()
    TK.printSuite(mn,"EmptyColor")
    local str = "Hello world"

    local result = LibSFUtils.applyColor(str, "")

    TK.assertEqual(str, result,
        "empty color should return original string")
end


local function testApplyColorNoDelimiters()
    TK.printSuite(mn,"NoDelimiters")
    local str = "Hello world"

    local result = LibSFUtils.applyColor(str, TEST_COLOR)

    TK.assertEqual(
        "|c" .. TEST_COLOR .. str .. "|r",
        result,
        "plain text should be wrapped in requested color"
    )
end


local function testApplyColorEmptyString()
    TK.printSuite(mn,"EmptyString")
    local result = LibSFUtils.applyColor("", TEST_COLOR)

    TK.assertEqual(
        "|c" .. TEST_COLOR .. "|r",
        result,
        "empty string should be wrapped in requested color"
    )
end


local function testApplyColorEmbeddedColorOnly()
    TK.printSuite(mn,"EmbeddedColorOnly")
    local str = "|c" .. EMBED_COLOR .. "Green text|r"

    local result = LibSFUtils.applyColor(str, TEST_COLOR)

    TK.assertEqual(
        str,
        result,
        "already-colored text should retain its embedded color"
    )
end


local function testApplyColorTextBeforeEmbeddedColor()
    TK.printSuite(mn,"TextBeforeEmbeddedColor")
    local str = "Normal |c" .. EMBED_COLOR .. "Green text|r"

    local result = LibSFUtils.applyColor(str, TEST_COLOR)

    TK.assertEqual(
        "|c" .. TEST_COLOR .. "Normal |r"
            .. "|c" .. EMBED_COLOR .. "Green text|r",
        result,
        "text before embedded color should use requested color"
    )
end


local function testApplyColorTextAfterEmbeddedColor()
    TK.printSuite(mn,"TextAfterEmbeddedColor")
    local str = "|c" .. EMBED_COLOR .. "Green text|r normal"

    local result = LibSFUtils.applyColor(str, TEST_COLOR)

    TK.assertEqual(
        "|c" .. EMBED_COLOR .. "Green text|r"
            .. "|c" .. TEST_COLOR .. " normal|r",
        result,
        "text after embedded color should use requested color"
    )
end


local function testApplyColorTextAroundEmbeddedColor()
    TK.printSuite(mn,"TextAroundEmbeddedColor")
    local str =
        "Normal |c" .. EMBED_COLOR .. "Green text|r normal"

    local result = LibSFUtils.applyColor(str, TEST_COLOR)

    TK.assertEqual(
        "|c" .. TEST_COLOR .. "Normal |r"
            .. "|c" .. EMBED_COLOR .. "Green text|r"
            .. "|c" .. TEST_COLOR .. " normal|r",
        result,
        "uncolored portions around embedded color should use requested color"
    )
end


local function testApplyColorMultipleEmbeddedColors()
    TK.printSuite(mn,"MultipleEmbeddedColors")
    local str =
        "A |c" .. EMBED_COLOR .. "B|r C |cFFFFFFD0D0D0D" .. "D|r E"

    local result = LibSFUtils.applyColor(str, TEST_COLOR)

    TK.assertEqual(
        "|c" .. TEST_COLOR .. "A |r"
            .. "|c" .. EMBED_COLOR .. "B|r"
            .. "|c" .. TEST_COLOR .. " C |r"
            .. "|cFFFFFFD0D0D0D" .. "D|r"
            .. "|c" .. TEST_COLOR .. " E|r",
        result,
        "multiple embedded colors should be preserved"
    )
end


local function testApplyColorEmptyEmbeddedColor()
    TK.printSuite(mn,"EmptyEmbeddedColor")
    local str = "|c" .. EMBED_COLOR .. "|rHello"

    local result = LibSFUtils.applyColor(str, TEST_COLOR)

    TK.assertEqual(
        "|c" .. TEST_COLOR .. "Hello|r",
        result,
        "empty embedded color should be removed before applying color"
    )
end


local function testApplyColorEmptyEmbeddedColorBetweenText()
    TK.printSuite(mn,"EmptyEmbeddedColorBetweenText")
    local str = "Hello|c" .. EMBED_COLOR .. "|rWorld"

    local result = LibSFUtils.applyColor(str, TEST_COLOR)

    TK.assertEqual(
        "|c" .. TEST_COLOR .. "Hello|r"
            .. "|c" .. TEST_COLOR .. "World|r",
        result,
        "empty embedded color between text portions should be removed"
    )
end


local function testApplyColorAdjacentColors()
    TK.printSuite(mn,"AdjacentColors")
    local str =
        "|cAAAAAA|cBBBBBBBlue text|r"

    local result = LibSFUtils.applyColor(str, TEST_COLOR)

    TK.assertEqual(
        "|cBBBBBBBlue text|r",
        result,
        "adjacent colors should retain the later color"
    )
end


local function testApplyColorAdjacentColorsWithFollowingText()
    TK.printSuite(mn,"AdjacentColorsWithFollowingText")
    local str =
        "|cAAAAAA|cBBBBBBBlue text|r normal"

    local result = LibSFUtils.applyColor(str, TEST_COLOR)

    TK.assertEqual(
        "|cBBBBBBBlue text|r"
            .. "|c" .. TEST_COLOR .. " normal|r",
        result,
        "text after adjacent embedded colors should use requested color"
    )
end


local function testApplyColorUnclosedEmbeddedColor()
    TK.printSuite(mn,"UnclosedEmbeddedColor")
    local str =
        "Normal |c" .. EMBED_COLOR .. "Green text"

    local markers = LibSFUtils.getAllColorDelim(str)

    markers = LibSFUtils.regularizeColors(markers, str)

    TK.assertEqual(2, #markers,
        "unclosed color should receive a synthetic reset")

    TK.assertEqual("c", markers[1].code, "first marker should be a color marker")
    TK.assertEqual(8, markers[1].start, "color marker should start at the embedded color delimiter")
    TK.assertEqual(15, markers[1].estr, "color marker should end after the six-digit color value")
    TK.assertTrue(markers[1].action == nil, "embedded color should be retained")

    TK.assertEqual("r", markers[2].code, "second marker should be a reset marker")
    TK.assertEqual(#str + 1, markers[2].start, "synthetic reset should start immediately after the input string")
    TK.assertEqual(#str + 1, markers[2].estr, "synthetic reset should be zero-width at the end of the input string")
    TK.assertEqual("+", markers[2].action, "final reset should be synthetic")

    local result = LibSFUtils.applyColor(str, TEST_COLOR)

    TK.assertEqual("|c" .. TEST_COLOR .. "Normal |r"
            .. "|c" .. EMBED_COLOR .. "Green text|r",
        result, "unclosed embedded color should receive a synthetic reset")
end



local function testApplyColorNonAdjacentColors()
    TK.printSuite(mn,"NonAdjacentColors")
    local str = "|cAAAAAAOuter text|cBBBBBBInner text|r"
    local result = LibSFUtils.applyColor(str, TEST_COLOR)

    TK.assertEqual( "|cAAAAAAOuter text|r" .. "|cBBBBBBInner text|r",
        result,
        "non-adjacent embedded colors should be separated by a reset"
    )
end


local function testApplyColorUppercaseDelimiters()
    TK.printSuite(mn,"UppercaseDelimiters")
    local str = "|C" .. EMBED_COLOR .. "Green text|R"

    local result = LibSFUtils.applyColor(str, TEST_COLOR)

    TK.assertEqual(
        str,
        result,
        "uppercase color delimiters should be preserved"
    )
end


local function testApplyColorMultiplePipes()
    TK.printSuite(mn,"MultiplePipes")
    local str = "Normal ||c" .. EMBED_COLOR .. "Green text||r"

    local result = LibSFUtils.applyColor(str, TEST_COLOR)

    TK.assertEqual(
        "|c" .. TEST_COLOR .. "Normal |r"
            .. "||c" .. EMBED_COLOR .. "Green text||r",
        result,
        "multiple-pipe delimiters should remain intact"
    )
end


local function testApplyColorNoColorAroundOnlyEmbedded()
    TK.printSuite(mn,"NoColorAroundOnlyEmbedded")
    local str =
        "|cAAAAAA|cBBBBBB|r"

    local result = LibSFUtils.applyColor(str, TEST_COLOR)

    TK.assertEqual(
        "|c" .. TEST_COLOR .. "|r",
        result,
        "empty adjacent embedded colors should be removed"
    )
end


local function testApplyColorPreservesPlainTextExactly()
    TK.printSuite(mn,"PreservesPlainTextExactly")
    local str = "This is |c00FF00colored|r text."

    local result = LibSFUtils.applyColor(str, TEST_COLOR)

    TK.assertEqual(
        "|c" .. TEST_COLOR .. "This is |r"
            .. "|c00FF00colored|r"
            .. "|c" .. TEST_COLOR .. " text.|r",
        result,
        "plain text content should not be modified"
    )
end


local function testApplyColorColorAtBeginning()
    TK.printSuite(mn,"ColorAtBeginning")
    local str =
        "|c" .. EMBED_COLOR .. "Green|r normal"

    local result = LibSFUtils.applyColor(str, TEST_COLOR)

    TK.assertEqual(
        "|c" .. EMBED_COLOR .. "Green|r"
            .. "|c" .. TEST_COLOR .. " normal|r",
        result,
        "embedded color at beginning should be preserved"
    )
end


local function testApplyColorColorAtEnd()
    TK.printSuite(mn,"ColorAtEnd")
    local str =
        "normal |c" .. EMBED_COLOR .. "Green|r"

    local result = LibSFUtils.applyColor(str, TEST_COLOR)

    TK.assertEqual(
        "|c" .. TEST_COLOR .. "normal |r"
            .. "|c" .. EMBED_COLOR .. "Green|r",
        result,
        "embedded color at end should be preserved"
    )
end


local function testApplyColorOnlyPlainText()
    TK.printSuite(mn,"OnlyPlainText")
    local str = "abc"

    local result = LibSFUtils.applyColor(str, "123456")

    TK.assertEqual(
        "|c123456abc|r",
        result,
        "plain text should receive exact requested color"
    )
end


local function testApplyColorRegularizationMixedColors()
    TK.printSuite(mn,"RegularizationMixedColors")
    local str =
        "|cAAAAAA|cBBBBabc|cCCCCCC"

    local result = LibSFUtils.applyColor(str, TEST_COLOR)

    TK.assertEqual(
        "|cBBBBabc|r"
            .. "|cCCCCCC|r",
        result,
        "regularized adjacent and non-adjacent colors should be handled"
    )
end


local function testApplyColorDoesNotMutateOriginalString()
    TK.printSuite(mn,"DoesNotMutateOriginalString")
    local str = "Hello world"

    local result = LibSFUtils.applyColor(str, TEST_COLOR)

    TK.assertEqual(
        "Hello world",
        str,
        "input string should remain unchanged"
    )

    assert(result ~= str,
        "colored result should differ from original string")
end


function ApplyColor_runAll()
    testApplyColorNilString()
    testApplyColorNilColor()
    testApplyColorEmptyColor()
    testApplyColorNoDelimiters()
    testApplyColorEmptyString()
    testApplyColorEmbeddedColorOnly()
    testApplyColorTextBeforeEmbeddedColor()
    testApplyColorTextAfterEmbeddedColor()
    testApplyColorTextAroundEmbeddedColor()
    testApplyColorMultipleEmbeddedColors()
    testApplyColorEmptyEmbeddedColor()
    testApplyColorEmptyEmbeddedColorBetweenText()
    testApplyColorAdjacentColors()
    testApplyColorAdjacentColorsWithFollowingText()
    testApplyColorUnclosedEmbeddedColor()
    testApplyColorNonAdjacentColors()
    testApplyColorUppercaseDelimiters()
    testApplyColorMultiplePipes()
    testApplyColorNoColorAroundOnlyEmbedded()
    testApplyColorPreservesPlainTextExactly()
    testApplyColorColorAtBeginning()
    testApplyColorColorAtEnd()
    testApplyColorOnlyPlainText()
    testApplyColorRegularizationMixedColors()
    testApplyColorDoesNotMutateOriginalString()
end


if not Suite then
    TK.init()
    ApplyColor_runAll()
    TK.showResult("sfutil.applyColor Tests")
end
