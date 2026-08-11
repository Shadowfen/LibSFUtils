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


local moduleName = "SFUtils_Strings"
local mn = "SFUtils_Strings"

test_log = {}

local function Closure_testSelfForward()
    -- Basic self forwarding
    local fn = "testSelfForward"
    TK.printSuite(mn,fn)

    local selfObj = { value = 42 }

    local function cb(selfie)
        return selfie.value
    end

    local f = SF.closure(cb, selfObj)

    TK.assertEqual(42, f(), "self forwarded")
end

local function Closure_testBoundArgs()
    -- Bound arguments
    local fn = "testBoundArgs"
    TK.printSuite(mn,fn)

    local function cb(a, b)
        return a, b
    end

    local f = SF.closure(cb, "A", "B")

    local a, b = f()

    TK.assertEqual("A", a, "bound arg A")
    TK.assertEqual("B", b, "bound arg B")
end

local function Closure_testCalltimeArgs()
    -- Call-time arguments
    local fn = "testCalltimeArgs"
    TK.printSuite(mn,fn)

    local function cb(self, a, b)
        return a, b
    end

    local f = SF.methodClosure(cb,nil)

    local a, b = f("A", "B")

    TK.assertEqual("A", a, "call-time arg A")
    TK.assertEqual("B", b, "call-time arg B")
end

local function Closure_testBoundCallArgs()
    -- Bound + call-time arguments
    local fn = "testBoundCallArgs"
    TK.printSuite(mn,fn)

    local function cb(...)
        return ...
    end

    local f = SF.closure(cb, 1, 2)

    local a, b, c, d = f(3, 4)

    TK.assertEqual(1, a, "Bound arg 1")
    TK.assertEqual(2, b, "Bound arg 2")
    TK.assertEqual(3, c, "Call arg 3")
    TK.assertEqual(4, d, "Call arg 4")
end

local function Closure_testSelfBoundCallArgs()
    -- Bound + call-time arguments
    local fn = "testSelfBoundCallArgs"
    TK.printSuite(mn,fn)

    local function cb(...)
        return ...
    end

    local f = SF.closure(cb, 1, 2)

    local a, b, c, d = f(3, 4)

    TK.assertEqual(1, a, "Bound arg 1")
    TK.assertEqual(2, b, "Bound arg 2")
    TK.assertEqual(3, c, "Call arg 3")
    TK.assertEqual(4, d, "Call arg 4")
end

local function Closure_testNilSelf()
    -- Nil Self arguments
    local fn = "testNilSelf"
    TK.printSuite(mn,fn)

    local function cb(self)
        return self == nil
    end

    local f = SF.methodClosure(cb)

    TK.assertTrue(f(), "nil self preserved")
end

local function Closure_testNoArgs()
    -- No arguments
    local fn = "testNoArgs"
    TK.printSuite(mn,fn)

        local called = false

        local function cb(self)
            called = true
        end

        local f = SF.closure(cb)

        f()

        TK.assertTrue(called,"function has no args")
end

local function Closure_testBoundArgsRemembered()
    -- Bound arguments remain unchanged between calls
    local fn = "testBoundArgsRemembered"
    TK.printSuite(mn,fn)

    local function cb(...)
        return ...
    end

    local f = SF.closure(cb, "A")

    local a1, b1 = f("B")
    local a2, b2 = f("C")

    TK.assertEqual("A", a1, "First call A")
    TK.assertEqual("B", b1, "First call B")

    TK.assertEqual("A", a2, "Second call still A")
    TK.assertEqual("C", b2, "Second call C")
end

local function Closure_testIndependent()
    -- Multiple closures are independent
    local fn = "testIndependent"
    TK.printSuite(mn,fn)

    local function cb(...)
        return ...
    end

    local f1 = SF.closure(cb, 1)
    local f2 = SF.closure(cb, 2)

    local a = f1()
    local b = f2()

    TK.assertEqual(1, a, "Closure 1 returns 1")
    TK.assertEqual(2, b, "Closure 2 returns 2")
end

local function Closure_testExactReceiveds()
    TK.printSuite(mn, "testExactReceiveds")

    -- Callback receives exactly the expected arguments
    local received

    local function cb(...)
        received = { ... }
    end

    local selfObj = {}

    local f = SF.methodClosure(cb, selfObj, "A", "B")

    f("C", "D")

    TK.assertEqual(5, #received, "Received 5 args")
    TK.assertEqual(selfObj, received[1], "Received self")
    TK.assertEqual("A", received[2], "Received A")
    TK.assertEqual("B", received[3], "Received B")
    TK.assertEqual("C", received[4], "Received C")
    TK.assertEqual("D", received[5], "Received D")
end

function Closure_runTests()
    Closure_testSelfForward()
    Closure_testBoundArgs()
    Closure_testCalltimeArgs()
    Closure_testBoundCallArgs()
    Closure_testSelfBoundCallArgs()
    Closure_testNilSelf()
    Closure_testNoArgs()
    Closure_testBoundArgsRemembered()
    Closure_testIndependent()
    Closure_testExactReceiveds()
end

-- main
if not Suite then
    TK.init()

    Closure_runTests()

    TK.showResult("Closure_Test")
end
