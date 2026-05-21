--[[
	This module provides a suite of helper functions for safe and efficient table manipulation. 
	It focuses on preventing runtime errors caused by nil values, handling circular references 
	during copying, and merging configuration data with defaults.

	Key Features:
		Safety: Functions like safeTable and safeClearTable prevent crashes when passed nil or non-table values.
		Deep Copying: deepCopy handles circular references and preserves metatables.
		Configuration Merging: defaultMissing fills in missing settings without overwriting existing user data.
		Debugging: dTable provides recursive string representation of complex tables.

	Technical Notes

    Metatable Preservation: deepCopy explicitly retrieves and sets the metatable of the original table, 
		ensuring custom behaviors (like __index) are maintained in the copy.
    Circular Reference Safety: The seen table in deepCopy is crucial for preventing stack overflow when 
		copying tables that reference themselves.
    Performance: getSize uses next() which is generally faster and more memory-efficient than iterating 
		with pairs() for large tables.
    Return Types: Most functions return the modified table or a new table, allowing for method chaining 
		or immediate assignment.
--]]

-- LibSFUtils is already defined in prior loaded file
LibSFUtils = LibSFUtils or {}
local sfutil = LibSFUtils

--[[
	sfutil.dTable(vtable, depth, name)

	Recursively converts a table into a formatted string for debugging.

		Parameters:
			vtable (table): The table to inspect.
			depth (number, optional): Maximum recursion depth. Defaults to 0 (no recursion).
			name (string, optional): A prefix name for the root table (used in output labels).
		Behavior:
			Iterates through keys and values.
			Functions are labeled as (function).
			Nested tables are recursively processed up to the depth limit.
			Returns a concatenated string of key -> value pairs.
		Returns: String representation of the table.
		Note: If vtable is not a table, it returns the stringified value using sfutil.str.
--]]
function sfutil.dTable(vtable, depth, name)
	if type(vtable) ~= "table" then
		return sfutil.str(vtable)
	end
    depth = math.max(0, tonumber(depth) or 0)
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
	sfutil.defaultMissing(svtable, defaulttable)

	Merges default values into a saved table without overwriting existing data.

    Parameters:
        svtable (table): The existing saved data (may be nil).
        defaulttable (table): The template of default values.
    Behavior:
        If svtable is nil, returns a deep copy of defaulttable.
        If svtable is not a table, returns a safe empty table.
        Iterates through defaulttable:
            If a key is missing in svtable, it is added.
            If the default value is a table, it recursively fills missing sub-keys.
            Existing values in svtable are preserved.
--]]
function sfutil.defaultMissing(svtable, defaulttable)
    if svtable == nil then return sfutil.safeTable(sfutil.deepCopy(defaulttable)) end
	if type(svtable) ~= 'table' or type(defaulttable) ~= 'table' then return sfutil.safeTable(svtable) end

	for k in pairs(defaulttable) do
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
	sfutil.deepCopy(orig, seen)

	Creates a deep copy of a table, handling circular references and metatables.

    Parameters:
        orig (any): The value to copy.
        seen (table, internal): Tracks already copied tables to prevent infinite loops.
    Behavior:
        If orig is not a table, returns it directly.
        Detects circular references using the seen table and returns the existing copy.
        Copies all keys and values recursively.
        The resulting table also gets a reference to the metatable from the orig table.
    Returns: A new independent table (or the original value if not a table).
    Use Case: Creating isolated snapshots of configuration or state without affecting the original.

    The seen argument is typically nii when called from
		outside, and a table of already seen tables when
		called internally (recursively). This is so that
		an orig table that contains multiple copies of another
		table will copy the first instance of that table to the result
		table and after that set all other instance of that table to
		reference the first full copy.
--]]
function sfutil.deepCopy(orig, seen)
    seen = sfutil.safeTable(seen)
	if type(orig) ~= 'table' then return orig end
    if seen[orig] then
        return seen[orig]
    end

	local tcopy = {}
    seen[orig] = tcopy
    local dcpy = sfutil.deepCopy        -- alias
	for orig_key, orig_value in pairs(orig) do
        if orig_key then
		    tcopy[dcpy(orig_key, seen)] = dcpy(orig_value, seen)
        end
	end

    local mt = getmetatable(orig)
    if mt then
	    setmetatable(tcopy, mt)
    end

	return tcopy
end

--[[ ---------------------
	sfutil.safeTable(tbl)

	Ensures a value is a table.

		Parameters: tbl (any).
		Behavior:
			If tbl is a table, returns it (reference).
			If tbl is nil or not a table, returns a new empty table {}.
--]]
function sfutil.safeTable(tbl)
    if type(tbl) ~= "table" then
        return {}
    end
    return tbl
end

--[[ ---------------------
	sfutil.safeClearTable(tbl)

	Clears all entries in a table safely.

		Parameters: tbl (any).
		Behavior:
			If tbl is not a table, returns a new empty table {}.
			If tbl is a table, iterates through keys and sets them to nil (similar to ZO_ClearTable).
			Returns the cleared (or new) table.

	The difference between this and ZO_ClearTable is the initial safety check
		and that we return the empty table (which might have been created if
		the parameter was not a proper table). ZO_ClearTable will error if passed nil.
--]]
function sfutil.safeClearTable(tbl)
    if type(tbl) ~= "table" then
        return {}
    end
    -- the loop is equal to ZO_ClearTable(tbl)
    for k in pairs(tbl) do
        tbl[k] = nil
    end
    return tbl
end

--[[ ---------------------
	sfutil.RemainsInList(listA, listB)

	Finds items in listA that are not present in listB.

    Parameters:
        listA (table): The primary list (values are treated as keys in the result).
        listB (table): The exclusion list (values are treated as keys for lookup).
    Behavior:
        Iterates through listA.
        If a value from listA is not a key in listB, it is added to the result.
        Returns a table where keys are the remaining values and values are 1.
    Returns: Table of listA (all) items that are not in listB (known).
    Note: This function assumes listB is used as a set (keys matter, values don't).
--]]
function sfutil.RemainsInList(listA, listB)
	local newList = {}

	if listA == nil or listB == nil then return newList end
	for _, v in pairs(listA) do
		if not listB[v] then
			newList[v] = 1
		end
	end

	return newList
end

--[[ ---------------------
	sfutil.getSize(tbl)

	Counts the number of items in a table.
		Handles non-contiguous tables. More safe version of ZOS's NonContiguousCount()

    Parameters: tbl (any).
    Behavior:
        Returns 0 if tbl is not a table.
        Uses next() to iterate, handling non-contiguous arrays and dictionary-style tables correctly.
    Returns: Integer count of keys or 0 if tbl is not a table.
    Advantage: More robust than #tbl (which only works for contiguous arrays) and safer than pairs() loops for counting.
--]]
function sfutil.GetSize(tbl)
    if type(tbl) ~= "table" then
		return 0
	end
	local count = 0
    local k = next(tbl, nil)   -- first key
    while k do
		count = count + 1
        k = next(tbl, k)       -- subsequent keys
    end

	--[[
    for _ in pairs(tbl) do
		count = count + 1
	end
    --]]
	return count
end


--[[ ---------------------
	sfutil.isEmpty(tbl)

	Checks if a table is empty.

    Parameters: tbl (any).
    Behavior:
        Returns true if the table has no keys.
        Returns false if the table has keys.
        Returns nil if tbl is nil or not a table.
    Note: Unlike ZO_IsTableEmpty, this explicitly returns nil for non-table inputs. Also, I regard a 
		nil "tbl" to be not an "empty" table as it is not a table at all. ZOS seems to disagree.
--]]
function sfutil.isEmpty(tbl)
    if tbl == nil or type(tbl) ~= "table" then
		return nil
	end
	return next(tbl) == nil
end


