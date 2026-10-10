package.path = package.path .. ";C:/Users/scott/Documents/SFAddons/TK/?.lua"

require "zos"
require "tk"

local TK = TestKit

require "LibSFUtils_Global"
require "SFUtils_Logger"
require "SFUtils_Tables"
require "SFUtils_Strings"
require "SFUtils_Color"
require "SFUtils_VersionChecker"
require "LibSFUtils"
require "SFUtils_CallLater"
require "SFUtils_HookManager"
require "SFUtils_VersionChecker"
require "SFUtils_LoadLanguage"
require "SFUtils_TimedQueue"


-- Set this so that the individual test files don't try to run
-- immediately on loading and instead wait until called from here.
Suite=true

require "test.addonChatterTest"
require "test.ApplyColorTest"
require "test.CallLaterTest"
require "test.ClosureTest"
require "test.ColorSplitTest"
require "test.ColorTest"
require "test.ColorDelimTest"
require "test.Gsplit_Test"
require "test.gsplitTest"
require "test.HookManagerTest"
require "test.IterTest"
require "test.LoadLanguageTest"
require "test.LoggerTest"
require "test.QueueTest"
require "test.RegularizeColorsTest"
require "test.StringsTest"
require "test.StripColorsTest"
require "test.TablesTest"
require "test.TimedQueueTest"
require "test.VersionCheckerTest"

TK.printSuite("LibSFUtil", "LibSFUtil Tests")

TK.init()

addonChatter_runTests()
ApplyColor_runAll()
Test_CallLater_All()
Closure_runTests()
test_runAllColor()
test_runAllColorDelim()
test_runAllColorSplit()
testGsplit_runAll()
testGsplit1_runAll()
Test_HookManager_All()
Iter_runTests()
LoadLanguages_runTests()
Logger_runTests()
testRegularizeColors_runAll()
Strings_runTests()
Tables_runTests()
Test_Queue_All()
StripColors_runAll()
Test_TimedQueue_All()
VCTest_runAll()

TK.showResult("LibSFUtil")
