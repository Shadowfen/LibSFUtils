-- LibSFUtils is already defined in prior loaded file

LibSFUtils = LibSFUtils or {}
local sfutil = LibSFUtils

-- debug convenience function
function sfutil.dTable(vtable, depth, name)
	if type(vtable) ~= "table" then
		return sfutil.str(vtable)
	end
    local function appendVal(tbl, val)
        tbl[#tbl+1] = val
        return tbl
    end

    local arg = {}
    local vt
	if depth == nil or depth < 1 then return table.concat(arg) end
	for k, v in pairs(vtable) do
      vt = type(v)
      if vt == "function" then
          appendVal(arg, sfutil.str(name, " : ", k, " -> (function),  \n"))

      elseif vt == "table" then 
          appendVal(arg, (sfutil.dTable(v, depth - 1, name.." - ["..tostring(k).."]")))

      else
          appendVal(arg, sfutil.str(name, " : ", k, " -> ", v, ",  \n"))
      end
	end
    return table.concat(arg)
end


--[[ ---------------------
	Recursively initialize missing values in a table from
	a defaults table. Existing values in the svtable will
	remain unchanged.
--]]
function sfutil.defaultMissing(svtable, defaulttable)
    if svtable == nil then return sfutil.deepCopy(defaulttable) end
	if type(svtable) ~= 'table' or type(defaulttable) ~= 'table' then return sfutil.safeTable(svtable) end

	for k,v in pairs(defaulttable) do
		if svtable[k] == nil then 
			if type( defaulttable[k] )=='table' then
				svtable[k] = {}
				sfutil.defaultMissing( svtable[k], defaulttable[k])

			else
				svtable[k] = defaulttable[k]
			end
		end
	end
    return svtable
end

--[[ ---------------------
	Recursively copy contents of a table into a new table
	for table/object it returns a copy of the table/object
	for anything else, it returns the value of the orig
--]]

function sfutil.deepCopy(orig, seen)
    local dcpy = sfutil.deepCopy
    seen = sfutil.safeTable(seen)
	local orig_type = type(orig)
	if orig_type ~= 'table' then return orig end
    if seen[orig] then
        return seen[orig]
    end

	local tcopy = {}
    seen[orig] = tcopy
	for orig_key, orig_value in pairs(orig) do
        if not orig_key then break end
		tcopy[dcpy(orig_key)] = dcpy(orig_value)
	end
    local mt = getmetatable(orig)
    if mt then
	    setmetatable(tcopy, mt)
    end

	return tcopy
end

--[[ ---------------------
	given a (supposed) table variable
		either return the table variable (reference)
		or return a new empty table if the table variable was nil
--]]
function sfutil.safeTable(tbl)
    if tbl == nil or type(tbl) ~= "table" then
        return {}
    end
    return tbl
end

--[[ ---------------------
	given a (supposed) table variable
		either return the same table variable after discarding the contents
		or return an empty table if the table variable was nil

	The difference between this and ZO_ClearTable is the initial safety check
		and that we return the empty table (which might have been created if
		the parameter was not a proper table).
--]]
function sfutil.safeClearTable(tbl)
    if tbl == nil or type(tbl) ~= "table" then
        return {}
    end
    for k,v in pairs(tbl) do
        tbl[k] = nil
    end
    return tbl
end

--[[ ---------------------
	Return only listA (all) items that are not in listB (known)
  Note: Compares listA values to listB keys, returns listA values as keys in remains with values of 1. Kinda wierd.
--]]
function sfutil.RemainsInList(listA, listB)
	local newList = {}

	if listA == nil then return newList end
	for _, v in pairs(listA) do
		if not listB[v] then
			newList[v] = 1
		end
	end

	return newList
end

--[[ ---------------------
	Return a count of the number of items in the table.
	Return nil if the supposed "table" is not a table
	Handles non-contiguous. More safe version of ZOS's NonContiguousCount()
--]]
function sfutil.GetSize(tbl)
    if tbl == nil or type(tbl) ~= "table" then
		return 0
	end
	local count = 0
	for _ in pairs(tbl) do 
		count = count + 1 
	end
	return count
end


--[[ ---------------------
	Return true or false if the table is empty or not.
	Return nil if the supposed "table" is not a table
	(Adds the type() check above what ZO_IsTableEmpty() does.
	Also, I regard a nil "t" to be not an "empty" table as it
	is not a table at all. ZOS seems to disagree.)
--]]
function sfutil.isEmpty(tbl)
    if tbl == nil or type(tbl) ~= "table" then
		return nil
	end
	return next(tbl) == nil
end


