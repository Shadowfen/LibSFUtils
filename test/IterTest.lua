require "LibSFUtils.test.tk"
require "LibSFUtils.test.zos"

--require "LibSFUtils.LibSFUtils_Global"
--require "LibSFUtils.SFUtils_Logger"
--require "LibSFUtils.SFUtils_Tables"
--require "LibSFUtils.SFUtils_Color"
--require "LibSFUtils.LibSFUtils"
local TK = TestKit
local SF = LibSFUtils

local TR = test_log
local d = print


local moduleName = "IteratorTest"
local mn = "IteratorTest"

test_log = {}

-- main
TK.init()

-- create a varargs iterator function
-- without using the 5.2 table.pack()
-- returns index, value, total with each iteration. (total does not change)
local function iter_args(...)
  local t = {...}
  local n = select("#", ...)
  --print ("n = "..tostring(n))
  local i = 0
  
  --[[
  print( "table is:")
  local v
  for k=1, n do
    v = select(k, ...)
    print( tostring(k).."  v="..tostring(v).." type(v)="..type(v) )
  end
  print("---")
  --]]
  
  return function()
    i=i+1
    if i<=n then return i,t[i], n end
  end
end

-- create a varargs iterator function
local function iter_args1(...)
  local ac = select("#", ...)
  print ("ac="..tostring(ac))
  local ax = 0
  
  print( "table is:")
  local v
  for k=1, ac do
    v = select(k, ...)
    print( tostring(k).."  v="..tostring(v) )
  end
  print("---")
  
  return function (...)
            if ac == 0 or ax >= ac then return nil, nil, 0 end
            
             ax = ax + 1
             print()
             print( "iter called with ax = "..ax..", ac = "..ac)
             if ax <= ac then
                local v = select(ax, ...)
                print( "ax = "..tostring(ax).." select("..tostring(ax)..", ...) returns "..tostring(v))
                return ax, v, ac
            end
        end
  
end


-- create a varargs function for testing
local function f0(...)
    local ax1, arg1, ac1 = 0, nil, 0
    for ax, arg, ac in iter_args(...) do
        ac1, ax1, arg1 = ac, ax, arg
        print ("ax="..tostring(ax1)..", arg="..tostring(arg1), ", type="..type(arg1)..", total = "..tostring(ac1))
    end
    --print ("ax1="..tostring(ax1).." arg1="..tostring(arg1))
    if not ac1 then return ac end
    return ac1
end

local function Iter_testEmpty()
    local fn = "testEmpty"
    TK.printSuite(mn,fn)
    
    local ac = f0()
    TK.assertTrue(ac < 1, "have no args")
    print()
end

local function Iter_testSingle()
    local fn = "testSingle"
    TK.printSuite(mn,fn)
    --print ("f0 returns "..tostring(f0(1)))
    TK.assertTrue(f0(1) == 1, "f0 has 1 args")
    print()
end

local function Iter_testMulti()
    local fn = "testMulti"
    TK.printSuite(mn,fn)
    
    TK.assertTrue(f0(1,2,"aa", "bb") == 4, "f0 has 4 args")
    print()
end

local function Iter_testMultiNil()
    local fn = "testMultiNil"
    TK.printSuite(mn,fn)
    
    TK.assertTrue(f0(1,2,nil,"aa", "bb") == 5, "f0 has 5 args")
    print()
end


function Iter_runTests()
    Iter_testEmpty()
    Iter_testSingle()
    Iter_testMulti()
    Iter_testMultiNil()
end

-- main
if not Suite then
    Iter_runTests()
    d("\n")
    TK.showResult("Iter_Test")
end
