-- CheckResultConsistency
-- Checks that all the past runs of the HowMany scripts produced the same results

--[[
The HowMany scripts each write basic info into a common index file, "index.in", which this tool processes.
The index data file is organized to allow simple appending - each entry is added by calling a "reg" function
with the entry table as its parameter.
Multiple executions of the HowMany scripts produce multiple entries in the index for the same output file.
This tool compares results on the same input file (and same query) across all the entries; if the result is
different in one entry from the other entries, an inconsistency is reported.
--]]





--- Counter used in indexReg() to keep track of the total number of entries in the index (including bad ones)
local entryCounter = 1

--- Storage for the valid entries
-- Multi-level map of "inFile" -> {map of "query" -> array of entries}
-- Access as indexEntries[inFile][query][1]
local indexEntries = {}





local function debugPrint(...)
	if (g_EnableDebugPrint) then
		print(...)
	end
end





--- Converts the path from the OS-native (possible backslashes) to web-native (slashes)
local function normalizePath(path)
	local res = string.gsub(path, package.config:sub(1, 1), "/")
	return res
end





--- This function gets called by the index.in file to register individual entries
-- <entry> is a table describing one run of any of the HowMany scripts
-- At minimum, it should contain inFile, timestamp, query, and result
local function indexReg(entry)
	if (
		(type(entry) ~= "table") or
		not(entry.inFile) or
		not(entry.timestamp) or
		not(entry.query) or
		not(entry.result)
	) then
		debugPrint(string.format(
			"Entry doesn't contain required fields, skipping the entry.\n\
			inFile: %s, timestamp: %s, query: %s, result: %s)",
			type(entry.inFile), type(entry.timestamp), type(entry.query), type(entry.result)
		))
	end
	local normalizedInFile = normalizePath(entry.inFile)
	entry.inFile = normalizedInFile
	local fileEntries = indexEntries[normalizedInFile] or {}
	indexEntries[normalizedInFile] = fileEntries
	fileEntries[entry.query] = fileEntries[entry.query] or {}
	table.insert(fileEntries[entry.query], entry)
end





--- Finds inconsistencies, outputs them
-- Returns the number of inconsistencies found
local function findInconsistencies(entries)
	local numInconsistencies = 0
	for inFile, queries in pairs(entries) do
		for query, runs in pairs(queries) do
			-- Sort the runs by timestamp:
			table.sort(runs,
				function (run1, run2)
					return (run1.timestamp < run2.timestamp)
				end
			)
			-- Check result inconsistencies within the runs:
			local result = runs[1].result
			for idx, entry in ipairs(runs) do
				if (entry.result ~= result) then
					print(string.format("File %s, query %s, entry at %s: result changed from %s to %s",
						inFile, query, os.date("%Y-%m-%d %H:%M:%S", entry.timestamp), result, entry.result
					))
					numInconsistencies = numInconsistencies + 1
					result = entry.result
				end
			end
		end
	end
	return numInconsistencies
end





local function main()
	-- Placeholder for navigation in IDE to the code below
end

-- Load the index entries:
local dataFn = assert(loadfile("index.in"))
setfenv(dataFn, {reg = indexReg})
local isSuccess, data = pcall(dataFn)
if not(isSuccess) then
	error("Failed to process index data: " .. tostring(data))
end

-- Find inconsistencies:
local numInconsistencies = findInconsistencies(indexEntries)
if (numInconsistencies > 0) then
	io.stderr:write(string.format("Inconsistencies found, count: %d\n", numInconsistencies))
	os.exit(1)
end
