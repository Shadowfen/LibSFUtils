package.path = package.path .. ";C:/Users/scott/Documents/SFAddons/TK/?.lua;C:/Users/scott/Documents/Elder Scrolls Online/live/AddOns/LibSFUtils/?.lua"

require "zos"
require "tk"
local TK = TestKit

require "LibSFUtils_Global"
require "SFUtils_Logger"
require "SFUtils_Tables"
require "SFUtils_Strings"
require "SFUtils_Color"
require "LibSFUtils"
local SF = LibSFUtils

local TR = test_log
local d = print


local mn = "addonChatter"

test_log = {}

local messages = {}

-- testable simple mock for the ESO chat function
local function ResetMessages()
    messages = {}
end

CHAT_ROUTER = {}
CHAT_ROUTER.AddSystemMessage = function(self, msg)
    table.insert(messages, msg)
end
-- -------------

function testNew()
  TK.printSuite(mn,"testNew")
  local chat = SF.addonChatter:New("TestMe")

  TK.assertEqual(chat.addonName, "TestMe", "addon name is set to TestMe")
  TK.assertFalse(chat:isDebugEnabled(), "debug is initially false")
  TK.assertEqual(chat.namecolor, SF.hex.goldenrod, "verified name color")
  TK.assertEqual(chat.normalcolor, SF.hex.mocassin, "verified normal color")
  TK.assertEqual(chat.debugcolor, SF.hex.ltskyblue, "verified debug color")
end

function testEnableDebug()
  TK.printSuite(mn,"testEnableDebug")
  local chat = SF.addonChatter:New("Test")

  chat:enableDebug()

  TK.assertTrue(chat:isDebugEnabled(), "enabling debug succeeded")
end

function testDisableDebug()
  TK.printSuite(mn,"testDisableDebug")
  local chat = SF.addonChatter:New("Test")

  chat:enableDebug()
  TK.assertTrue(chat:isDebugEnabled(), "enabling debug succeeded")
  
  chat:disableDebug()
  TK.assertFalse(chat:isDebugEnabled(), "disabling debug succeeded")
end

function testToggleDebug()
  TK.printSuite(mn,"testToggleDebug")
  local chat = SF.addonChatter:New("Test")

  chat:toggleDebug()
  TK.assertTrue(chat:isDebugEnabled(), "toggling enabled debug succeeded")
  
  chat:toggleDebug()
  TK.assertFalse(chat:isDebugEnabled(), "toggling disabled debug succeeded")
end

function testSetNameColor()
  TK.printSuite(mn,"testSetNameColor")
  local chat = SF.addonChatter:New("Test3")

  TK.assertEquals(chat.prefix,"|cEECA00 [Test3] |r", "default prefix")
  chat:setNameColor(SF.hex.purple)
  TK.assertEquals(chat.prefix,"|cb000ff [Test3] |r", "changed prefix")

  chat:setNameColor(SF.hex.goldenrod)
  TK.assertEquals(chat.prefix,"|cEECA00 [Test3] |r", "changed prefix")
end

function testSetNormalColor()
  TK.printSuite(mn,"testSetNormalColor")
  local chat = SF.addonChatter:New("Test3")

  ResetMessages()
  chat:setNormalColor(SF.hex.red)
  chat:systemMessage("Hello")

  TK.assertEqual(messages[#messages], "|cEECA00 [Test3] |r|cFF0000 Hello|r", "normal color changed to red")
end

function testSetDebugColor()
  TK.printSuite(mn,"testSetDebugColor")
  local chat = SF.addonChatter:New("Test4")
  chat:enableDebug()

  ResetMessages()
  chat:setDebugColor(SF.hex.green)
  chat:systemMessage("Hello")
  TK.assertEqual(messages[#messages], "|cEECA00 [Test4] |r|cFFE4B5 Hello|r", "debug color changed to green")
end

function testSystemMessage()
  TK.printSuite(mn,"testSystemMessage")
  local chat = SF.addonChatter:New("TestSystem")
  
  ResetMessages()
  chat:systemMessage("Hello")

  TK.assertEqual(#messages, 1, "one chat message")
  TK.assertEqual(messages[1],"|cEECA00 [TestSystem] |r|cFFE4B5 Hello|r")

  ResetMessages()
  chat:systemMessage()   -- nil message

  TK.assertEqual(#messages, 1, "got 'nil' system message in 'chat'")
  TK.assertEqual(messages[1],"|cEECA00 [TestSystem] |r|cFFE4B5 |r", "nil debug message has prefix")
end

function testDebugMessage()
  TK.printSuite(mn,"testDebugMessage")
  local chat = SF.addonChatter:New("TestDebug")
  
  ResetMessages()
  chat:debugMsg("Hello")
  TK.assertEqual(#messages, 0, "no debug message in 'chat'")
  
  chat:toggleDebug()
  chat:debugMsg("Hello also")

  TK.assertEqual(#messages, 1, "got debug message in 'chat'")
  TK.assertEqual(messages[1],"|cEECA00 [TestDebug] |r|c87cefa Hello also|r", "debug message is correct")

  ResetMessages()
  chat:debugMsg()   -- nil message

  TK.assertEqual(#messages, 1, "got 'nil' debug message in 'chat'")
  TK.assertEqual(messages[1],"|cEECA00 [TestDebug] |r|c87cefa |r", "nil debug message has prefix")
end

function testMultipleArgs()
  TK.printSuite(mn,"testMultipleArgs")
  local chat = SF.addonChatter:New("TestMulti")
  
  ResetMessages()

  chat:systemMessage("A", 123, true)

  TK.assertEqual(messages[1], "|cEECA00 [TestMulti] |r|cFFE4B5 A 123 true|r", "multi arg system message correct")
  
  ResetMessages()
  chat:toggleDebug()
  chat:debugMsg("B", 124, true)
  TK.assertEqual(messages[1], "|cEECA00 [TestMulti] |r|c87cefa B 124 true|r", "multi arg debug message correct")
end

function addonChatter_runTests()
    testNew()
    testEnableDebug()
    testDisableDebug()
    testToggleDebug()
    testSetNameColor()
    testSetNormalColor()
    testSetDebugColor()
    testSystemMessage()
    testDebugMessage()
    testMultipleArgs()
end


-- main
if not Suite then
    TK.init()
    
    addonChatter_runTests()
    
    TK.showResult("addonChatter_Test")
end
