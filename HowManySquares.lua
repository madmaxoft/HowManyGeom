-- HowManySquares.lua

-- Calculates the number of squares in the input mesh





-- DEBUGGING Settings:
local g_DrawPointCircles = false
local g_OutputEdges      = false
local g_OutputExtEdges   = false
local g_SvgWidth  = 270
local g_SvgHeight = 270





--- When the SVGs are created, the original shape's full SVG data is stored into this variable for later
local g_ShapeFullSvg





dofile("Util.lua")
local Svg = dofile("Svg.lua")





--- Returns the square from the specified coords that has the lowest name point as the first point
local function minimizeSquare(pt1, pt2, pt3, pt4)
	-- Search for the point with the lowest name:
	local extended = {pt1, pt2, pt3, pt4, pt1, pt2, pt3}
	local minStart = 1
	for i = 2, 4 do
		if (extended[i].name < extended[minStart].name) then
			minStart = i
		end
	end
	return {extended[minStart], extended[minStart + 1], extended[minStart + 2], extended[minStart + 3]}
end





--- Returns the square that has the specified coords and the lowest name is the first point, and the second
-- point is lower than the last point
local function normalizeSquare(pt1, pt2, pt3, pt4)
	local minimized = minimizeSquare(pt1, pt2, pt3, pt4)
	if (minimized[2].name > minimized[4].name) then
		-- Swap around:
		minimized[2], minimized[4] = minimized[4], minimized[2]
	end
	return minimized
end





--- Returns the distance between the two points, squared
local function edgeLengthSq(pt1, pt2)
	local dx = pt1.coords[1] - pt2.coords[1]
	local dy = pt1.coords[2] - pt2.coords[2]
	return dx * dx + dy * dy
end





--- Returns true if the four points form a square
local function isSquare(pt1, pt2, pt3, pt4)
	-- Check edge lengths:
	local len1 = edgeLengthSq(pt1, pt2)
	local len2 = edgeLengthSq(pt2, pt3)
	if not(isAlmostEqual(len1, len2)) then
		return false
	end
	local len3 = edgeLengthSq(pt3, pt4)
	if not(isAlmostEqual(len1, len3)) then
		return false
	end
	local len4 = edgeLengthSq(pt4, pt1)
	if not(isAlmostEqual(len1, len4)) then
		return false
	end

	-- Check one angle:
	return isPerpendicular(pt1.coords, pt2.coords, pt3.coords)
end





local function squareName(square)
	return square[1].name .. square[2].name .. square[3].name .. square[4].name
end





--- Outputs the SVGs into an index HTML file for viewing them
local function outputSvgs(data, squares, outputFileName)
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
	g_ShapeFullSvg = svg:header() .. orig .. svg:footer()

	-- Output the HTML:
	local f = assert(io.open(outputFileName, "wb"))
	f:write("<html><head><title>" .. outputFileName .. "</title></head><body>")
	f:write("<p>Input:</p><p>")
	f:write(svgHeader)
	f:write(orig)
	f:write(svgFooter)

	-- Output individual triangles:
	f:write("<p>Found " .. #squares .. " squares:</p><p>")
	for _, square in ipairs(squares) do
		f:write(svgHeader)
		svg:drawPolyline(square, "stroke:rgb(255,0,0);stroke-width:5")
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
	print("Usage: lua HowManySquares.lua <InputFileName> [<OutputFileName>]")
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

-- Find all squares:
local numSquares = 0
local squares = {}  -- array of {ptA, ptB, ptC, ptD}
local hasSquare = {}  -- Map of "ABCD" -> true for all squares
for ptName, pt in pairs(data.points) do
	for _, pt2 in ipairs(pt.extEdges) do
		for _, pt3 in ipairs(pt2.extEdges) do
			-- TODO: Check edge length and perpendicularity
			if (pt3.name ~= ptName) then
				for _, pt4 in ipairs(pt3.extEdges) do
					-- TODO: Check edge length and perpendicularity
					if (pt4.name ~= pt2.name) then
						for _, pt5 in ipairs(pt4.extEdges) do
							if ((pt5.name == ptName) and isSquare(pt, pt2, pt3, pt4)) then
								-- A square was found, add it if not already added:
								local square = normalizeSquare(pt, pt2, pt3, pt4)
								local sqName = squareName(square)
								if not(hasSquare[sqName]) then
									numSquares = numSquares + 1
									squares[numSquares] = square
									hasSquare[sqName] = true
								end
							end
						end
					end
				end
			end
		end
	end
end

-- Sort the squares:
table.sort(squares,
	function(sq1, sq2)
		return (squareName(sq1) < squareName(sq2))
	end
)

-- Output to console:
print("Found squares: " .. numSquares)
for _, sq in ipairs(squares) do
	print("  " .. squareName(sq))
end

-- Output nice HTML files:
outputSvgs(data, squares, outputFileName)

-- Save the results for Index creation / Consistency checking:
local f = assert(io.open("index.in", "ab"))
f:write(string.format(
	[[reg({inFile = %q, outFile = %q, timestamp = %s, query = "squares", result = %d, meshSvg = %q})]],
	inputFileName, outputFileName, os.time(), numSquares, g_ShapeFullSvg or ""
))
f:close()
