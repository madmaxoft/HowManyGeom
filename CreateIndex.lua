-- CreateIndex.lua

-- After running the HowMany scripts, this script will take their results and create an HTML index file.
--[[
The HowMany scripts each write basic info into a common index file, "index.in", which this tool processes.
The index data file is organized to allow simple appending - each entry is added by calling a "reg" function
with the entry table as its parameter.
Multiple executions of the HowMany scripts produce multiple entries in the index for the same output file.
The HTML index produced by this script will use the latest entry, based on its timestamp field.
--]]




--- Debugging settings:
local g_EnableDebugPrint = true





--- Counter used in indexReg() to keep track of the total number of entries in the index (including bad ones)
local entryCounter = 1

--- Storage for the valid entries
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
-- At minimum, it should contain outFile, timestamp, query, result and meshSvg
local function indexReg(entry)
	if (
		(type(entry) ~= "table") or
		not(entry.outFile) or
		not(entry.timestamp) or
		not(entry.query) or
		not(entry.result) or
		not(entry.meshSvg)
	) then
		debugPrint(string.format(
			"Entry doesn't contain required fields, skipping the entry.\n\
			outFile: %s, timestamp: %s, query: %s, result: %s, svgData: %s)",
			type(entry.outFile), type(entry.timestamp), type(entry.query),
			type(entry.result), type(entry.meshSvg)
		))
	end
	entry.outFile = normalizePath(entry.outFile)
	table.insert(indexEntries, entry)
end





--- Collapses multiple runs over a single input file into a single (latest) entry
-- entries is an array-table of index entries
-- Returns a map of "outFile" -> entry, picking the latest entry for each outFile
local function collapseEntries(entries)
	assert(type(entries) == "table")

	local res = {}
	for idx, entry in ipairs(entries) do
		entry.index = idx
		if (
			not(res[entry.outFile]) or                        -- This is the first entry for that outFile
			(res[entry.outFile].timestamp < entry.timestamp)  -- This entry is newer
		) then
			res[entry.outFile] = entry
		end
	end

	return res
end





local function outputIndexFile(entries)
	local collapsedEntries = collapseEntries(entries)
	local outFiles = {}
	for of, _ in pairs(collapsedEntries) do
		table.insert(outFiles, of)
	end
	table.sort(outFiles)
	for _, of in ipairs(outFiles) do
		debugPrint(of)
	end

	local f = assert(io.open("index.html", "wb"))
	f:write([[
<html><head><title>HowMany</title><style>
.hh { text-color: black; background-color: black; }
.hh:hover { text-color: black; background-color: white }
</style>
</head><body>]]
	)
	f:write("<table border=1 cellspacing=0 cellpadding='10em'><tr><th>Mesh</th><th>Shape</th><th>Quick result</th><th>Detailed solution</th></tr>")
	for _, of in ipairs(outFiles) do
		local entry = collapsedEntries[of]
		f:write("<tr><td><a href='", entry.outFile, "'>")
		f:write(entry.meshSvg)
		f:write("</a></td><td>", entry.query, "</td><td>")
		f:write("<p>Hover mouse over the black rectangle to show the result:</p>")
		f:write("<p class='hh'>", entry.result, "</p></td><td>")
		f:write("<a href='", entry.outFile, "'>View detailed solution</a></td></tr>")
	end
	f:write("</table></body></html>")
	f:close()
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

-- Process into an index file:
outputIndexFile(indexEntries)
