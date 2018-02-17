-- HowManyTriangles.lua

-- Calculates the number of triangles in the input mesh





-- DEBUGGING Settings:
local g_DrawPointCircles = false
local g_OutputEdges      = false
local g_OutputExtEdges   = false
local g_SvgWidth  = 270
local g_SvgHeight = 270





dofile("Util.lua")
local Svg = dofile("Svg.lua")





--- Normalizes the specified triangle
-- Returns {ptA, ptB, ptC} where the points are alpha-sorted by their name
local function normalizeTriangle(pt1, pt2, pt3)
	if (pt1.name < pt2.name) then
		if (pt2.name < pt3.name) then
			return {pt1, pt2, pt3}
		else
			if (pt1.name < pt3.name) then
				return {pt1, pt3, pt2}
			else
				return {pt3, pt1, pt2}
			end
		end
	else
		-- pt1 > pt2
		if (pt2.name > pt3.name) then
			return {pt3, pt2, pt1}
		else
			if (pt1.name < pt3.name) then
				return {pt2, pt1, pt3}
			else
				return {pt2, pt3, pt1}
			end
		end
	end
end





--- Returns a string representing the triangle name for the specified triangle
-- trianglePoints is an array of 3 points
local function triangleName(trianglePoints)
	return trianglePoints[1].name .. trianglePoints[2].name .. trianglePoints[3].name
end





--- Outputs the SVGs into individual files in the output folder, as well as an index HTML file for viewing them
local function outputTriangleSvgs(data, triangles, outputFileName)
	-- Get the source shape data to append:
	local svg = Svg.new(g_SvgWidth, g_SvgHeight, data)
	for _, edge in ipairs(data.edges) do
		svg:drawEdge(edge, "stroke:rgb(128,128,128);stroke-width:1")
	end
	if (g_DrawPointCircles) then
		for _, pt in pairs(data.points) do
			svg:drawPoint(pt, "stroke:rgb(128,128,128);stroke-width:1;fill:none")
		end
	end
	local orig = svg:dataOutput()
	local svgHeader = svg:header()
	local svgFooter = svg:footer()
	svg:clear()

	-- Sort the triangles:
	local triangleNames = {}  -- array of "ABC"
	local ins = table.insert
	for trName, _ in pairs(triangles) do
		ins(triangleNames, trName)
	end
	table.sort(triangleNames)

	-- Output the HTML:
	local f = assert(io.open(outputFileName, "wb"))
	f:write("<html><head><title>" .. outputFileName .. "</title></head><body>")
	f:write("<p>Input:</p><p>")
	f:write(svgHeader)
	f:write(orig)
	f:write(svgFooter)

	-- Output individual triangles:
	f:write("<p>Found " .. #triangleNames .. " triangles:</p><p>")
	for _, name in ipairs(triangleNames) do
		f:write(svgHeader)
		svg:drawPolyline(triangles[name], "stroke:rgb(255,0,0);stroke-width:5")
		f:write(svg:dataOutput())
		svg:clear()
		f:write(orig)
		f:write(svgFooter)
	end

	-- DEBUG: Output individual edges:
	if (g_OutputEdges) then
		f:write("</p><hr/><p>DEBUG: " .. #(data.edges) .. " edges:</p><p>")
		for _, edge in pairs(data.edges) do
			f:write(svgHeader)
			svg:drawEdge(edge, "stroke:rgb(0,255,0);stroke-width:5")
			f:write(svg:dataOutput())
			svg:clear()
			f:write("\n")
			f:write(orig)
			f:write(svgFooter)
		end
	end

	-- DEBUG: Output individual extEdges:
	if (g_OutputExtEdges) then
		f:write("</p><hr/><p>DEBUG: " .. #(data.extEdges) .. " extEdges:</p><p>")
		for _, edge in pairs(data.extEdges) do
			f:write(svgHeader)
			svg:drawEdge(edge, "stroke:rgb(0,0,255);stroke-width:5")
			f:write(svg:dataOutput())
			svg:clear()
			f:write("\n")
			f:write(orig)
			f:write(svgFooter)
		end
	end

	f:write("</p></body></html>")
	f:close()
end





local function main()
	-- Placeholder for navigation in IDE to the code below
end

local args = {...}
local inputFileName = args[1]
if not(inputFileName) then
	print("Usage: HowManyTriangles.lua <InputFileName> [<OutputFileName>]")
	os.exit(0)
end
local outputFileName = inputFileName:gsub("%.in", "") .. "_out.html"
if (args[2] == "-q") then
	-- Quiet mode: don't output anything to console
	local emptyFunction = function() end
	print = emptyFunction
	if (args[3]) then
		outputFileName = args[3]
	end
elseif (args[2]) then
	outputFileName = args[2]
end



print("Processing file " .. inputFileName .. "...")
-- local data = InputFile.load(inputFileName)
local data = loadInputFile(inputFileName)
print("File " .. inputFileName .. " loaded successfully.")

-- Find all triangles:
local numTriangles = 0
local triangleNames = {}  -- array of "ABC"
local triangles = {}  -- map of "ABC" -> {ptA, ptB, ptC}
for ptName, pt in pairs(data.points) do
	for _, pt2 in ipairs(pt.extEdges) do
		for _, pt3 in ipairs(pt2.extEdges) do
			if (pt3.name ~= ptName) then
				for _, pt4 in ipairs(pt3.extEdges) do
					if ((pt4.name == ptName) and not(isSingleLine(pt.coords, pt2.coords, pt3.coords))) then
						-- A triangle was found, add it if not already added:
						local triangle = normalizeTriangle(pt, pt2, pt3)
						local trName = triangleName(triangle)
						if not(triangles[trName]) then
							numTriangles = numTriangles + 1
							triangles[trName] = triangle
							triangleNames[numTriangles] = trName
						end
					end
				end
			end
		end
	end
end

-- Output to console:
print("Found triangles: " .. numTriangles)
table.sort(triangleNames)
for _, name in ipairs(triangleNames) do
	print("  " .. name)
end

-- Output nice HTML files:
outputTriangleSvgs(data, triangles, outputFileName)
