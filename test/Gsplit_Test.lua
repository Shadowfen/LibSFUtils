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

local moduleName = "gsplit"
local mn = "gsplit"


-- -------------------------------------------------------
-- helpers
-- -------------------------------------------------------

local function assertTableEquals(actual, expected, message)
    TK.assertEqual(#actual, #expected, message .. " (length)")

    for i = 1, #expected do
        TK.assertEqual(actual[i], expected[i],
            message .. " (index " .. tostring(i) .. ")")
    end
end

-- -------------------------------------------------------
-- tests
-- -------------------------------------------------------

function testGsplit_nil()
    TK.printSuite("LibSFUtils", "testGsplit_nil")

    local result = SF.gsplit(nil, ",")

    assertTableEquals(result, {},
        "nil string should return an empty table")
end


function testGsplit_emptyString()
    TK.printSuite("LibSFUtils", "testGsplit_emptyString")

    local result = SF.gsplit("", ",")

    assertTableEquals(result, { "" },
        "empty string should produce one empty field")
end


function testGsplit_noDelimiter()
    TK.printSuite("LibSFUtils", "testGsplit_noDelimiter")

    local result = SF.gsplit("abc", ",")

    assertTableEquals(result, { "abc" },
        "string without delimiter should be unchanged")
end


function testGsplit_nilPattern()
    TK.printSuite("LibSFUtils", "testGsplit_nilPattern")

    local result = SF.gsplit("abc", nil)

    assertTableEquals(result, { "abc" },
        "nil pattern should return the original string")
end


function testGsplit_emptyPattern()
    TK.printSuite("LibSFUtils", "testGsplit_emptyPattern")

    local result = SF.gsplit("abc", "")

    assertTableEquals(result, { "abc" },
        "empty pattern should return the original string")
end


function testGsplit_basic()
    TK.printSuite("LibSFUtils", "testGsplit_basic")

    local result = SF.gsplit("one,two,three", ",")

    assertTableEquals(result,
        { "one", "two", "three" },
        "basic comma-separated string")
end


function testGsplit_leadingDelimiter()
    TK.printSuite("LibSFUtils", "testGsplit_leadingDelimiter")

    local result = SF.gsplit(",one,two", ",")

    assertTableEquals(result,
        { "", "one", "two" },
        "leading delimiter should produce an empty first field")
end


function testGsplit_trailingDelimiter()
    TK.printSuite("LibSFUtils", "testGsplit_trailingDelimiter")

    local result = SF.gsplit("one,two,", ",")

    assertTableEquals(result,
        { "one", "two", "" },
        "trailing delimiter should produce an empty final field")
end


function testGsplit_adjacentDelimiters()
    TK.printSuite("LibSFUtils", "testGsplit_adjacentDelimiters")

    local result = SF.gsplit("one,,three", ",")

    assertTableEquals(result,
        { "one", "", "three" },
        "adjacent delimiters should produce an empty field")
end


function testGsplit_multipleAdjacentDelimiters()
    TK.printSuite("LibSFUtils", "testGsplit_multipleAdjacentDelimiters")

    local result = SF.gsplit(",,,", ",")

    assertTableEquals(result,
        { "", "", "", "" },
        "multiple delimiters should produce empty fields between and around them")
end


function testGsplit_delimiterOnly()
    TK.printSuite("LibSFUtils", "testGsplit_delimiterOnly")

    local result = SF.gsplit(",", ",")

    assertTableEquals(result,
        { "", "" },
        "a delimiter-only string should produce two empty fields")
end


function testGsplit_multiCharacterDelimiter()
    TK.printSuite("LibSFUtils", "testGsplit_multiCharacterDelimiter")

    local result = SF.gsplit("one::two::three", "::")

    assertTableEquals(result,
        { "one", "two", "three" },
        "multi-character delimiter should be supported")
end


function testGsplit_patternDelimiter()
    TK.printSuite("LibSFUtils", "testGsplit_patternDelimiter")

    local result = SF.gsplit("one123two456three", "%d+")

    assertTableEquals(result,
        { "one", "two", "three" },
        "delimiter should be treated as a Lua pattern")
end


function testGsplit_literalPatternCharacters()
    TK.printSuite("LibSFUtils", "testGsplit_literalPatternCharacters")

    local result = SF.gsplit("one.two.three", "%.")

    assertTableEquals(result,
        { "one", "two", "three" },
        "escaped pattern character should act as a literal delimiter")
end


function testGsplit_delimiterAtBothEnds()
    TK.printSuite("LibSFUtils", "testGsplit_delimiterAtBothEnds")

    local result = SF.gsplit(",one,two,", ",")

    assertTableEquals(result,
        { "", "one", "two", "" },
        "delimiters at both ends should produce empty fields")
end


function testGsplit_textContainingPattern()
    TK.printSuite("LibSFUtils", "testGsplit_textContainingPattern")

    local result = SF.gsplit("a--b----c", "%-%-")

    assertTableEquals(result,
        { "a", "b", "", "c" },
        "adjacent multi-character delimiters should produce empty fields")
end


function testGsplit_preservesWhitespace()
    TK.printSuite("LibSFUtils", "testGsplit_preservesWhitespace")

    local result = SF.gsplit(" one , two , three ", ",")

    assertTableEquals(result,
        { " one ", " two ", " three " },
        "split should not trim whitespace")
end


function testGsplit1_runAll()

    testGsplit_nil()
    testGsplit_emptyString()
    testGsplit_noDelimiter()
    testGsplit_nilPattern()
    testGsplit_emptyPattern()

    testGsplit_basic()
    testGsplit_leadingDelimiter()
    testGsplit_trailingDelimiter()
    testGsplit_adjacentDelimiters()
    testGsplit_multipleAdjacentDelimiters()
    testGsplit_delimiterOnly()

    testGsplit_multiCharacterDelimiter()
    testGsplit_patternDelimiter()
    testGsplit_literalPatternCharacters()

    testGsplit_delimiterAtBothEnds()
    testGsplit_textContainingPattern()
    testGsplit_preservesWhitespace()
end


if not Suite then
    TK.init()
    testGsplit1_runAll()
    TK.showResult("sfutil.gsplit Tests")
end
