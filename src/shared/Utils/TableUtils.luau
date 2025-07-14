--!strict
-- TableUtils.luau
-- Utility functions for table operations

local TableUtils = {}

-- Deep copy a table
function TableUtils.deepCopy(original: any): any
	local copy: any
	
	if type(original) == "table" then
		copy = {}
		for key, value in pairs(original) do
			copy[TableUtils.deepCopy(key)] = TableUtils.deepCopy(value)
		end
	else
		copy = original
	end
	
	return copy
end

-- Merge two tables
function TableUtils.merge(target: {[any]: any}, source: {[any]: any}): {[any]: any}
	for key, value in pairs(source) do
		target[key] = value
	end
	return target
end

-- Check if table is empty
function TableUtils.isEmpty(tbl: {[any]: any}): boolean
	return next(tbl) == nil
end

-- Get table size
function TableUtils.getSize(tbl: {[any]: any}): number
	local count = 0
	for _ in pairs(tbl) do
		count += 1
	end
	return count
end

-- Get random element from table
function TableUtils.getRandom(tbl: {any}): any
	if #tbl == 0 then
		return nil
	end
	
	local randomIndex = math.random(1, #tbl)
	return tbl[randomIndex]
end

-- Get table keys
function TableUtils.getKeys(tbl: {[any]: any}): {any}
	local keys = {}
	for key in pairs(tbl) do
		table.insert(keys, key)
	end
	return keys
end

-- Get table values
function TableUtils.getValues(tbl: {[any]: any}): {any}
	local values = {}
	for _, value in pairs(tbl) do
		table.insert(values, value)
	end
	return values
end

-- Filter table by predicate
function TableUtils.filter(tbl: {any}, predicate: (any) -> boolean): {any}
	local filtered = {}
	for _, value in ipairs(tbl) do
		if predicate(value) then
			table.insert(filtered, value)
		end
	end
	return filtered
end

-- Map table with function
function TableUtils.map(tbl: {any}, func: (any) -> any): {any}
	local mapped = {}
	for i, value in ipairs(tbl) do
		mapped[i] = func(value)
	end
	return mapped
end

-- Find element in table
function TableUtils.find(tbl: {any}, predicate: (any) -> boolean): any
	for _, value in ipairs(tbl) do
		if predicate(value) then
			return value
		end
	end
	return nil
end

-- Shuffle table (Fisher-Yates algorithm)
function TableUtils.shuffle(tbl: {any}): {any}
	local shuffled = TableUtils.deepCopy(tbl)
	
	for i = #shuffled, 2, -1 do
		local j = math.random(i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	
	return shuffled
end

-- Clear table
function TableUtils.clear(tbl: {[any]: any}): {[any]: any}
	table.clear(tbl)
	return tbl
end

-- Export
return TableUtils 