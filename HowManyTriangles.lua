-- HowManyTriangles.lua

-- Calculates the number of triangles in the input mesh





-- DEBUGGING Settings:
local g_DrawPointCircles = false
local g_OutputEdges = false
local g_OutputExtEdges = false





dofile("Util.lua")





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





--- Returns the SVG coords of the specified input coords
local function svgCoords(x, y)
	return {10 + x * 100, 10 + y * 100}
end





--- Returns the SVG code to display the original shape
local function originalShapeSvg(data)
	local res = {}
	local idx = 0

	-- Draw circles around points:
	if (g_DrawPointCircles) then
		for _, pt in pairs(data.points) do
			local coords = svgCoords(pt.coords[1], pt.coords[2])
			idx = idx + 1
			res[idx] = string.format(
				[[<circle cx="%d" cy="%d" r="5" style="stroke:rgb(128,128,128);stroke-width:1;fill:none" />]],
				coords[1], coords[2]
			)
		end
	end

	-- Draw edges:
	for ei, edge in pairs(data.edges) do
		local coords1 = svgCoords(edge[1].coords[1], edge[1].coords[2])
		local coords2 = svgCoords(edge[2].coords[1], edge[2].coords[2])
		idx = idx + 1
		--[[
		print(string.format("Edge %s: [%d, %d] - [%d, %d]",
			ei,
			edge[1].coords[1], edge[1].coords[2],
			edge[2].coords[1], edge[2].coords[2]
		))
		--]]
		res[idx] = string.format(
			[[<line x1="%d" y1="%d" x2="%d" y2="%d" style="stroke:rgb(128,128,128);stroke-width:1" />]],
			coords1[1], coords1[2],
			coords2[1], coords2[2]
		)
	end
	return table.concat(res, "\n")
end





--- Returns the SVG width and height to contain the specified points
local function getMaxSvgCoords(points)
	local maxX, maxY = 0, 0
	for _, pt in pairs(points) do
		if (pt.coords[1] > maxX) then
			maxX = pt.coords[1]
		end
		if (pt.coords[2] > maxY) then
			maxY = pt.coords[2]
		end
	end
	local coords = svgCoords(maxX, maxY)
	return coords[1] + 10, coords[2] + 10
end





--- Returns the SVG code for highlighting the specified triangle
local function getSvgTriangleHighlight(triangle)
	local coords1 = svgCoords(triangle[1].coords[1], triangle[1].coords[2])
	local coords2 = svgCoords(triangle[2].coords[1], triangle[2].coords[2])
	local coords3 = svgCoords(triangle[3].coords[1], triangle[3].coords[2])

	return string.format([[
<line x1="%d" y1="%d" x2="%d" y2="%d" style="stroke:rgb(255, 0, 0);stroke-width:5" />
<line x1="%d" y1="%d" x2="%d" y2="%d" style="stroke:rgb(255, 0, 0);stroke-width:5" />
<line x1="%d" y1="%d" x2="%d" y2="%d" style="stroke:rgb(255, 0, 0);stroke-width:5" />
]],
		coords1[1], coords1[2], coords2[1], coords2[2],
		coords2[1], coords2[2], coords3[1], coords3[2],
		coords3[1], coords3[2], coords1[1], coords1[2]
	)

end





--- Outputs the SVGs into individual files in the output folder, as well as an index HTML file for viewing them
local function outputTriangleSvgs(data, triangles, outputFileName)
	local orig = originalShapeSvg(data)
	local width, height = getMaxSvgCoords(data.points)
	local svgHeader = [[<svg width="]] .. width .. [[" height="]] .. height .. [[">]]
	local svgFooter = "Get a better browser with SVG support.</svg>"
	local triangleNames = {}  -- array of "ABC"
	local ins = table.insert
	for trName, _ in pairs(triangles) do
		ins(triangleNames, trName)
	end
	table.sort(triangleNames)
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
		f:write(getSvgTriangleHighlight(triangles[name]))
		f:write(orig)
		f:write(svgFooter)
	end

	-- DEBUG: Output individual edges:
	if (g_OutputEdges) then
		f:write("</p><hr/><p>DEBUG: " .. #(data.edges) .. " edges:</p><p>")
		for _, edge in pairs(data.edges) do
			local pt1 = svgCoords(edge[1].coords[1], edge[1].coords[2])
			local pt2 = svgCoords(edge[2].coords[1], edge[2].coords[2])
			f:write(svgHeader)
			f:write(string.format(
				[[<line x1="%d" y1="%d" x2="%d" y2="%d" style="stroke:rgb(0, 255, 0);stroke-width:5" />]],
				pt1[1], pt1[2], pt2[1], pt2[2]
			))
			f:write("\n")
			f:write(orig)
			f:write(svgFooter)
		end
	end

	-- DEBUG: Output individual extEdges:
	if (g_OutputExtEdges) then
		f:write("</p><hr/><p>DEBUG: " .. #(data.extEdges) .. " extEdges:</p><p>")
		for _, edge in pairs(data.extEdges) do
			local pt1 = svgCoords(edge[1].coords[1], edge[1].coords[2])
			local pt2 = svgCoords(edge[2].coords[1], edge[2].coords[2])
			f:write(svgHeader)
			f:write(string.format(
				[[<line x1="%d" y1="%d" x2="%d" y2="%d" style="stroke:rgb(0, 255, 0);stroke-width:5" />]],
				pt1[1], pt1[2], pt2[1], pt2[2]
			))
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
