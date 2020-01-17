require "LibSFUtils.test.tk"
require "LibSFUtils.LibSFUtils"
local TK = TestKit
local SF = LibSFUtils

local TR = test_run
local d = print

local moduleName = "gsplit"
local mn = "gsplit"

local function ReformatSysMessages(text)
     if not text then return "" end
   
    -- get positions of all of the desired delimiters
    local t1 = SF.getAllColorDelim(text) 
   
    if #t1 == 0 then
        -- no delimiters in string
        return text
    end
    
    -- balance and correct color markers
    SF.regularizeColors(t1, text)
    
    rawSys = table.concat(SF.colorsplit(t1, text))
    
    -- |u search (strip out hard padding)
    rawSys = string.gsub(rawSys,"|u%-?%d+%%?:%-?%d+%%?:(.-):|u","%1")

    return rawSys

end

-- s = string
-- sep = delimiter pattern
-- expect = table of strings not including pattern
local function test(nm, s, sep, expect)
    local tn = "test - "..nm
    TK.printSuite(mn,tn)
    
   local t1={} 
   for _,c in pairs(SF.gsplit(s,sep)) do 
       table.insert(t1,c) 
   end
   TK.assertTrue(#t1 == #expect,"length correct ".. #t1.." == "..#expect)
   local l = #t1
   if #expect > l then l = #expect end
   for i=1,l do 
       TK.assertTrue(t1[i] == expect[i], i..". \""..(t1[i] or "nil").."\" == \""..(expect[i] or "nil").."\"") 
   end
end

local function testzo(nm, s, expect)
    local tn = "test - "..nm
    TK.printSuite(mn,tn)
    
     if not s then return {},0 end
   
    -- get positions of all of the desired delimiters
    local t1 = SF.getAllColorDelim(s) 
   
    if #t1 == 0 then
        -- no delimiters in string
        return { s }, 1
    end
    
    -- balance and correct color markers
    SF.regularizeColors(t1, s)
    
    local t2 = SF.colorsplit(t1,s)
    
   TK.assertTrue(#t2 == #expect,"length correct ".. #t2.." == "..#expect)
   local ln = #t2
   if #expect > ln then ln = #expect end
   for i=1,ln do 
       TK.assertTrue(t2[i] == expect[i], i..". \""..(t2[i] or "nil").."\" == \""..(expect[i] or "nil").."\"") 
   end
end

local function teststrip(nm, s, expect)
    local tn = "test - "..nm
    TK.printSuite(mn,tn)
    
    local markers = SF.getAllColorDelim(s)    
    local s1=SF.stripColors(markers,s)
    
    TK.assertTrue(#s1 == #expect,"length correct ".. #s1.." == "..#expect)
    TK.assertTrue(s1 == expect,s1.." == "..expect)
end

TK.init()

d(ReformatSysMessages("aaaa|c454545blahblah|r std colorized string"))
d(ReformatSysMessages("|c454545blahblah|r|cfefefeserial|r serial colorized string"))
d(ReformatSysMessages("|c454545cola|h0|98|blahblah|hpepsi|h|rtail"))
d(ReformatSysMessages("|c454545|r empty colorized string"))
d(ReformatSysMessages("aaaa|c454545blahblah|c545454 std colorized string"))

d("------------------------")

mn="zo_colorsplit"

testzo("leading non, std colorized string",
        "aaaa|c454545blahblah|r std colorized string", 
        {"aaaa","|c454545","blahblah","|r"," std colorized string"})
testzo("serial colorized string",
        "|c454545blahblah|r|cfefefeserial|r serial colorized string", 
        {"|c454545","blahblah","|r", "|cfefefe","serial","|r"," serial colorized string"})
testzo("colorized hlink",
        "|c454545cola|h0|98|blahblah|hpepsi|h|rtail", 
        {"|c454545","cola|h0|98|blahblah|hpepsi|h","|r", "tail"})
testzo("empty colorized string",
        "|c454545|r empty colorized string", 
        {" empty colorized string"})

testzo("leading non, serial bad colorized string",
        "aaaa|c454545blahblah|c545454 std colorized string", 
        {"aaaa","|c454545","blahblah","|r","|c545454"," std colorized string","|r"})
testzo("forbidden nested colorized string",
        "|c454545|cfefefeblahblah|r|r nested colorized string", 
        {"|cfefefe","blahblah","|r"," nested colorized string"})

testzo("forbidden double pipe c",
        "||c454545||cfefefeblahblah|r|r nested colorized string", 
        {"|cfefefe","blahblah","|r"," nested colorized string"})
testzo("forbidden double pipe r",
        "|c454545|cfefefeblahblah||r||r nested colorized string", 
        {"|cfefefe","blahblah","|r"," nested colorized string"})
testzo("forbidden double every marker",
        "||c454545|||cfefefeblahblah||r||r nested colorized string", 
        {"|cfefefe","blahblah","|r"," nested colorized string"})


d("------------------------")

mn="stripColors"

teststrip("leading non, std colorized string",
        "aaaa|c454545blahblah|r std colorized string", 
        "aaaablahblah std colorized string")
teststrip("serial colorized string",
        "|c454545blahblah|r|cfefefeserial|r serial colorized string", 
        "blahblahserial serial colorized string")
teststrip("colorized hlink",
        "|c454545cola|h0|98|blahblah|hpepsi|h|rtail", 
        "cola|h0|98|blahblah|hpepsi|htail")
teststrip("empty colorized string",
        "|c454545|r empty colorized string", 
        " empty colorized string")

teststrip("leading non, serial bad colorized string",
        "aaaa|c454545blahblah|c545454 std colorized string", 
        "aaaablahblah std colorized string")
teststrip("forbidden nested colorized string",
        "|c454545|cfefefeblahblah|r|r nested colorized string", 
        "blahblah nested colorized string")
teststrip("forbidden double every marker",
        "||c454545|||cfefefeblahblah||r||r nested colorized string", 
        "blahblah nested colorized string")

d("------------------------")

mn="gsplit"

test("empty string - empty sep",
    '','',{''}) 
test("empty string - multi sep",
    '','asdf',{''})    
test("string - empty",
    'asdf','',{'asdf'})
test("empty string - comma sep",
    '', ',', {''}) 

test("comma string - comma sep",
    ',', ',', {'',''}) 
test("single elem - comma sep",
    'a', ',', {'a'})
test("double elem - comma sep",
    'a,b', ',', {'a','b'})
test("trailing comma - comma sep",
    'a,b,', ',', {'a','b',''})
test("leading comma - comma sep",
    ',a,b', ',', {'','a','b'})
test("enclosing commas - comma sep",
    ',a,b,', ',', {'','a','b',''})
test("enclosing and embedded - comma sep",
    ',a,,b,', ',', {'','a','','b',''})
test("embedded sep - comma sep",
    'a,,b', ',', {'a','','b'}) 
test("spacing - ,.; sep",
    'asd  ,   fgh  ,;  qwe, rty.   ,jkl', '%s*[,.;]%s*', {'asd','fgh','','qwe','rty','','jkl'})
test("python - spam", 
    'Spam eggs spam spam and ham', '[Ss]pam', {'',' eggs ',' ',' and ham'})
--]]
TK.showResult()