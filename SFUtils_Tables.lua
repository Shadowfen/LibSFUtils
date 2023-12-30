-- LibSFUtils is already defined in prior loaded file

LibSFUtils = LibSFUtils or {}
local sfutil = LibSFUtils

-- debug convenience function
function sfutil.dTable(vtable, depth, name)
	if type(vtable) ~= "table" then 
		return sfutil.str(vtable) 
	end
    local arg = {}
	if depth == nil or depth < 1 then return end
	for k, v in pairs(vtable) do
		if type(v) == "function" then
			arg[#arg+1] = name.." : "..tostring(k).." -> (function),  \n"
		elseif type(v) == "table" then 
			arg[#arg+1] = sfutil.dTable(v, depth - 1, name.." - ["..tostring(k).."]") 
		else
			arg[#arg+1] = name.." : "..tostring(k).." -> "..tostring(v)..",  \n"
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
	if type(svtable) ~= 'table' then return end
	if type(defaulttable) ~= 'table' then return end
	
	for k,v in pairs(defaulttable) do
		if( svtable[k] == nil ) then 
			if( type( defaulttable[k] )=='table' ) then
				svtable[k] = {}
				sfutil.defaultMissing( svtable[k], defaulttable[k])
				
			else
				svtable[k] = defaulttable[k]
			end
		end
	end
end

--[[ ---------------------
	Recursively copy contents of a table into a new table
	for table/object it returns a copy of the table/object
	for anything else, it returns the value of the orig
--]]
function sfutil.deepCopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[sfutil.deepCopy(orig_key)] = sfutil.deepCopy(orig_value)
		end
		setmetatable(copy, sfutil.deepCopy(getmetatable(orig)))
		
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end


--[[ ---------------------
	given a (supposed) table variable
		either return the table variable
		or return an empty table if the table variable was nil
--]]
function sfutil.safeTable(tbl)
    if tbl == nil or type(tbl) ~= "table" then
        tbl = {}
    end
    return tbl
end

--[[ ---------------------
	given a (supposed) table variable
		either return the same table variable after discarding the contents
		or return an empty table if the table variable was nil
--]]
function sfutil.safeClearTable(tbl)
    if tbl == nil or type(tbl) ~= "table" then
        tbl = {}
		return tbl
    end
    for k in pairs(tbl) do
        tbl[k] = nil
    end
    return tbl
end

--[[ ---------------------
	Return only listA (all) items that are not in listB (known)
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


