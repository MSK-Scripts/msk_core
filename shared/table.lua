MSK.Table = {}

MSK.Table.Contains = function(tbl, val)
    assert(tbl and type(tbl) == 'table', 'Parameter "tbl" has to be a table on function MSK.Table.Contains')
    assert(val, 'Parameter "val" is nil on function MSK.Table.Contains')
    
    if type(val) == 'table' then
        for k, value in pairs(tbl) do
            if MSK.Table.Contains(val, value) then
                return true
            end
        end
        return false
    else
        for k, v in pairs(tbl) do
            if v == val then
                return true
            end
        end
    end
    return false
end
MSK.TableContains = MSK.Table.Contains -- Backwards compatibility
MSK.Table_Contains = MSK.Table.Contains -- Backwards compatibility
exports('TableContains', MSK.Table.Contains)

MSK.Table.Dump = function(tbl)
    return type(tbl) == "table" and json.encode(tbl, { indent = true }) or tostring(tbl)
end
MSK.DumpTable = MSK.Table.Dump -- Backwards compatibility
exports('TableDump', MSK.Table.Dump)

MSK.Table.DumpString = function(tbl, n)
    if not n then n = 0 end
    if type(tbl) ~= "table" then return tostring(tbl) end
    local s = '{\n'

    for k, v in pairs(tbl) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        for i = 1, n, 1 do s = s .. "    " end
        s = s .. '    ['..k..'] = ' .. MSK.Table.DumpString(v, n + 1) .. ',\n'
    end

    for i = 1, n, 1 do s = s .. "    " end

    return s .. '}'
end
exports('TableDumpString', MSK.Table.DumpString)

MSK.Table.Size = function(tbl)
    local count = 0

    for k, v in pairs(tbl) do
        count += 1
    end

    return count
end
exports('TableSize', MSK.Table.Size)

MSK.Table.Index = function(tbl, val)
    for i = 1, #tbl, 1 do
        if tbl[i] == val then
            return i
        end
    end

    return -1
end
exports('TableIndex', MSK.Table.Index)

MSK.Table.LastIndex = function(tbl, val)
    for i = 1, #tbl, -1 do
        if tbl[i] == val then
            return i
        end
    end

    return -1
end
exports('TableLastIndex', MSK.Table.LastIndex)

MSK.Table.Find = function(tbl, val)
    for i = 1, #tbl do
        if tbl[i] == val then
            return i, val
        end
    end

    return nil, val
end
exports('TableFind', MSK.Table.Find)

MSK.Table.Reverse = function(tbl)
    local newTbl = {}

    for i = #tbl, 1, -1 do
        table.insert(newTbl, tbl[i])
    end

    return newTbl
end
exports('TableReverse', MSK.Table.Reverse)

MSK.Table.Clone = function(tbl)
    assert(tbl and type(tbl) == 'table', 'Parameter "tbl" has to be a table on function MSK.Table.Clone')
    local clone = {}

    for k, v in pairs(tbl) do
		if type(v) == 'table' then
			clone[k] = MSK.Table.Clone(v)
		else
			clone[k] = v
		end
	end

    return setmetatable(clone, getmetatable(tbl))
end
exports('TableClone', MSK.Table.Clone)

-- Credit: https://stackoverflow.com/a/15706820
MSK.Table.Sort = function(tbl, order)
    -- collect the keys
	local keys = {}

	for k, _ in pairs(tbl) do
		keys[#keys + 1] = k
	end

	-- if order function given, sort by it by passing the table and keys a, b,
	-- otherwise just sort the keys
	if order then
		table.sort(keys, function(a, b)
			return order(tbl, a, b)
		end)
	else
		table.sort(keys)
	end

	-- return the iterator function
	local i = 0

	return function()
		i = i + 1
		if keys[i] then
			return keys[i], tbl[keys[i]]
		end
	end
end
exports('TableSort', MSK.Table.Sort)