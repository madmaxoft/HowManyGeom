-- Util.lua

-- Implements some common methods for all programs





--[[
The calculations take place on a data structure that describes the input shape:
{
	points =
	{
		a =
		{
			name = "a",
			coords = {0, 1, 2},
			edges = {<ptB>, <ptC>, ...}
			extEdges = { <ptB>, <ptC>, ..., <ptD>, <ptE>, ...}
		},
		...
	},
	edges =
	{
		{ <ptA>, <ptB> },
		...
	},
	extEdges =
	{
		{ <ptA>, <ptB> },
		...
		{ <ptA>, <ptD> },
		...
	},
}
--]]





--- Returns the direction triplet calculated from the difference between the two points
local function directionFromPoints(coords1, coords2)
	return {
		coords1[1] - coords2[1],
		coords1[2] - coords2[2]
	}
end





--- Returns true if the two numbers are almost equal (up to EPSILON)
local function isAlmostEqual(n1, n2)
	return (math.abs(n1 - n2) < 0.000001)
end





--- Returns true if the specified direction triplets are of the same direction
local function isDirectionSame(dir1, dir2)
	local k  -- coefficient of the first nonzero direction coord
	if (dir1[1] ~= 0) then
		k = dir2[1] / dir1[1]
	elseif (dir1[2] ~= 0) then
		k = dir2[2] /dir1[2]
	else
		error("Bad direction - both coords are zero")
	end
	if (k < 0) then
		-- Opposite direction
		return false
	end
	return (
		isAlmostEqual(k * dir1[1], dir2[1]) and
		isAlmostEqual(k * dir1[2], dir2[2])
	);
end





function isSingleLine(coords1, coords2, coords3)
	local dir1 = directionFromPoints(coords1, coords2)
	return (
		isDirectionSame(dir1, directionFromPoints(coords2, coords3)) or
		isDirectionSame(dir1, directionFromPoints(coords3, coords2))
	)
end





--- Adds extEdges to each point in the data structure, containing the extended (transitive)
-- edges from that point. Also stores all the extEdges in data.extEdges
-- The input table is modified directly
local function extendEdges(data)
	data.extEdges = {}
	local nextExtEdge = 1  -- Index into data.extendedEdges for the next added edge
	local ins = table.insert
	for ptName, pt in pairs(data.points) do
		-- For each edge in the point, try to extend it further:
		pt.extEdges = {}
		for _, edgePt in ipairs(pt.edges) do
			ins(pt.extEdges, edgePt)
			ins(data.extEdges, {pt, edgePt})
			local lastPt = pt
			local nextPoint = edgePt
			local direction = directionFromPoints(pt.coords, edgePt.coords)
			while (nextPoint) do
				local curPoint = nextPoint
				nextPoint = nil
				for _, nextEdgePt in ipairs(curPoint.edges) do
					if (nextEdgePt ~= lastPt) then
						local nextDir = directionFromPoints(curPoint.coords, nextEdgePt.coords)
						if (isDirectionSame(direction, nextDir)) then
							ins(pt.extEdges, nextEdgePt)
							data.extEdges[nextExtEdge] = {pt, nextEdgePt}
							nextExtEdge = nextExtEdge + 1
							lastPt = curPoint
							nextPoint = nextEdgePt
							--[[
							print("Extending from point [" .. pt.coords[1] .. ", " .. pt.coords[2] .. "]")
							print("extendEdges: going from point [" .. curPoint.coords[1] .. ", " .. curPoint.coords[2] .. "] to point [" .. nextPoint.coords[1] .. ", " .. nextPoint.coords[2] .. "]")
							print("  Master direction: " .. direction[1] .. ", " .. direction[2])
							print("  Current direction: " .. nextDir[1] .. ", " .. nextDir[2])
							--]]
							break
						end
					end
				end
			end
		end
	end
end





--- Loads the input data from a Lua-formatted file (initial format)
local function loadFromLuaFile(fileName, fileContents)
	-- Parse the Lua structure into memory:
	local allfn, err = loadstring(fileContents)
	if not(allfn) then
		error("Cannot load input from file " .. fileName .. ", error: " .. err)
	end

	-- Load the Lua code:
	local isSuccess, allrep = pcall(allfn)
	if not(isSuccess) then
		error("Cannot load input from file " .. fileName .. ", error: " .. allRep)
	end

	-- Convert the textual edge representation into referential:
	if (type(allrep.points) ~= "table") then
		error("Cannot load input from file " .. fileName .. ", missing or invalid \"points\" definition.")
	end
	if (type(allrep.edges) ~= "table") then
		error("Cannot load input from file " .. fileName .. ", missing or invalid \"edges\" definition.")
	end
	local res =
	{
		points = {},
		edges = {},
	}
	for name, coords in pairs(allrep.points) do
		if (type(name) ~= "string") then
			error("Cannot load input from file " .. fileName .. ", point '" .. tostring(name) .. "' has an invalid name.")
		end
		if (name:len() ~= 1) then
			error("Cannot load input from file " .. fileName .. ", point '" .. name .. "' has a name too long. Only single letters are accepted.")
		end
		res.points[name] = { name = name, coords = coords, edges = {} }
	end
	local ins = table.insert
	for idx, edge in ipairs(allrep.edges) do
		if not(type(edge) == "string") then
			error("Cannot load input from file " .. fileName .. ", edge #" .. idx .. " is not a string.")
		end
		local pt1 = res.points[edge:sub(1, 1)]
		if not(pt1) then
			error("Cannot load input from file " .. fileName .. ", edge #" .. idx .. " refers to an unknown point '" .. edge:sub(1, 1) .. "'.")
		end
		local pt2 = res.points[edge:sub(2, 2)]
		if not(pt2) then
			error("Cannot load input from file " .. fileName .. ", edge #" .. idx .. " refers to an unknown point '" .. edge:sub(2, 2) .. "'.")
		end
		if (pt1.name == pt2.name) then
			error("Cannot load input from file " .. fileName .. ", edge #" .. idx .. " refers to the same point '" .. pt1.name .. "' twice.")
		end
		res.edges[idx] = {pt1, pt2}
		ins(pt1.edges, pt2)
		ins(pt2.edges, pt1)
	end

	extendEdges(res)
	return res
end




--- The pool of names for points that can be assigned (1 letter each)
local pointNames = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

--- Returns true if the specified point lies inside the specified edge
-- Assumes that the point lies on the line defined by the edge!
local function isPointInsideEdge(x, y, edge)
	local x1 = edge[1]
	local y1 = edge[2]
	local x2 = edge[3]
	local y2 = edge[4]
	local smallerY, largerY
	if (y1 < y2) then
		smallerY = y1
		largerY = y2
	else
		smallerY = y2
		largerY = y1
	end
	if ((y < smallerY) or (y > largerY)) then
		-- Outside the Y range
		return false
	end

	-- Y range didn't help (equal Y coords?), check X range:
	local smallerX, largerX
	if (x1 < x2) then
		smallerX = x1
		largerX = x2
	else
		smallerX = x2
		largerX = x1
	end

	return ((x >= smallerX) and (x <= largerX))
end





--- Returns the coords of the intersection for the two edges, or nil if they don't cross
local function edgesIntersection(edge1, edge2)
	local x1 = edge1[1]
	local y1 = edge1[2]
	local x2 = edge1[3]
	local y2 = edge1[4]
	local x3 = edge2[1]
	local y3 = edge2[2]
	local x4 = edge2[3]
	local y4 = edge2[4]
	assert(x1 and y1 and x2 and y2 and x3 and y3 and x4 and y4)

	if (
		((x3 == x1) and (y3 == y1)) or
		((x3 == x2) and (y3 == y2)) or
		((x4 == x1) and (y4 == y1)) or
		((x4 == x2) and (y4 == y2))
	) then
		-- The edges touch by their ends, there's no need to calculate the crossing
		return
	end

	--[[
	print("Potential crossing?")
	print("  " .. x1 .. ", " .. y1 .. " - " .. x2 .. ", " .. y2)
	print("  " .. x3 .. ", " .. y3 .. " - " .. x4 .. ", " .. y4)
	--]]
	local hx = x2 - x1
	local hy = y2 - y1
	local nx = x4 - x3
	local ny = y4 - y3
	local d = hx * ny - hy * nx

	if (math.abs(d) < 1e-30) then
		-- Parallel lines
		return
	end

	local coeff = ((y1 - y3) * nx - (x1 - x3) * ny) / d
	if ((coeff < 0) or (coeff > 1)) then
		-- The crossing is outside the first edge
		return
	end
	local crossingX = x1 + coeff * hx
	local crossingY = y1 + coeff * hy
	if not(isPointInsideEdge(crossingX, crossingY, edge2)) then
		-- The crossing is outside the second edge
		return
	end
	return {crossingX, crossingY}
end





--- Returns true if the specified point is one of the edge's endpoints
local function isEdgeEndpoint(pt, edge)
	return (
		((pt[1] == edge[1]) and (pt[2] == edge[2])) or
		((pt[1] == edge[3]) and (pt[2] == edge[4]))
	)
end





--- Returns all points from allIntersections that lie on the specified edge
-- Doesn't return the edge endpoints
local function filterPointsOnEdge(allIntersections, edge)
	local res = {}
	local ins = table.insert
	for _, pt in pairs(allIntersections) do
		if not(isEdgeEndpoint(pt, edge)) then
			if (isSingleLine(
				{edge[1], edge[2]},
				{pt[1], pt[2]},
				{edge[3], edge[4]}
			)) then
				ins(res, pt)
			end
		end
	end
	return res
end





--- Finds all edge intersections and breaks the edges in them, creating a new points
-- Returns the new edges
local function breakOnIntersections(edges)
	local intersections = {}
	local newEdges = {}
	local idx = 1
	local idxOuter = 1
	local numEdges = #edges
	local ins = table.insert

	-- Get all intersections:
	for idxOuter = 1, numEdges do
		local edge = edges[idxOuter]
		for idxInner = idxOuter + 1, numEdges do
			local crossEdge = edges[idxInner]
			local coords = edgesIntersection(edge, crossEdge)
			if (coords) then
				ins(intersections, coords)
			end
		end
	end

	-- Point-sorting function:
	local sortPoints = function(points)
		table.sort(points,
			function (coords1, coords2)
				if (coords1[1] < coords2[1]) then
					return true
				elseif (coords1[1] > coords2[1]) then
					return false
				end
				return (coords1[2] < coords2[2])
			end
		)
	end

	-- Prune duplicates:
	sortPoints(intersections)
	local lastX, lastY = 1e30, 1e30  -- Outside reasonable coords range
	local tmp = {}
	for _, pt in ipairs(intersections) do
		if not(isAlmostEqual(pt[1], lastX) or isAlmostEqual(pt[2], lastY)) then
			ins(tmp, pt)
			lastX = pt[1]
			lastY = pt[2]
		end
	end
	intersections = tmp

	-- Break each edge on all the intersections that lie on it:
	local res = {}
	for _, edge in ipairs(edges) do
		local contained = filterPointsOnEdge(intersections, edge)
		if not(contained[1]) then
			-- Edge not intersected at all, insert as-is:
			ins(res, edge)
		else
			-- Edge intersected, insert sub-edges:
			ins(contained, {edge[1], edge[2]})
			ins(contained, {edge[3], edge[4]})
			sortPoints(contained)
			---[[
			print(string.format("Intersections on edge [%d, %d] - [%d, %d]:",
				edge[1], edge[2], edge[3], edge[4]
			))
			for _, pt in ipairs(contained) do
				print(string.format("  [%d, %d]", pt[1], pt[2]))
			end
			--]]
			lastX = nil
			lastY = nil
			for _, pt in ipairs(contained) do
				if (lastX and lastY and ((lastX ~= pt[1]) or (lastY ~= pt[2]))) then
					ins(res, {lastX, lastY, pt[1], pt[2]})
				end
				lastX = pt[1]
				lastY = pt[2]
			end
		end
	end
	return res
end





--- Loads the input data from the SimplePoints-formatted file
local function loadFromSimplePoints(fileName, fileContents)
	-- Read the edges from the file:
	local lineNum = 0
	local edges = {}  -- Array of {x1, y1, x2, y2}
	local ins = table.insert
	for line in fileContents:gmatch("[^\n]+") do
		lineNum = lineNum + 1
		if ((line ~= "") and (line:sub(1, 1) ~= '#')) then
			local x1, y1, x2, y2 = line:match("(%d+),%s*(%d+)%s*%-%s*(%d+),%s*(%d+)")
			x1 = tonumber(x1)
			y1 = tonumber(y1)
			x2 = tonumber(x2)
			y2 = tonumber(y2)
			if not(x1 and y1 and x2 and y2) then
				error("Cannot parse file " .. fileName .. ", line " .. lineNum .. " doesn't contain a valid edge definition (\"" .. line .. "\")")
			end
			if ((x1 == x2) and (y1 == y2)) then
				error("Cannot parse file " .. fileName .. ", line " .. lineNum .. " has a single-point loop")
			end
			ins(edges, {x1, y1, x2, y2})
		end
	end

	-- Break edges on their intersections:
	edges = breakOnIntersections(edges)

	-- De-duplicate and objectify all points:
	local points = {}  -- array of {x, y} coords for points, with possible duplicates
	for _, edge in ipairs(edges) do
		local x1 = edge[1]
		local y1 = edge[2]
		local x2 = edge[3]
		local y2 = edge[4]
		ins(points, {x1, y1})
		ins(points, {x2, y2})
	end
	table.sort(points,
		function (pt1, pt2)
			if (pt1[2] < pt2[2]) then
				return true
			elseif (pt1[2] > pt2[2]) then
				return false
			end
			-- The Y coord is the same, use the X coord:
			return (pt1[1] < pt2[1])
		end
	)

	-- Convert into points + edges representation:
	local res =
	{
		points = {},
		edges = {},
	}
	local nextNameIdx = 1
	local nextEdgeIdx = 1
	local lastX, lastY
	local pointsByCoords = {}  -- Multi-level map of [x][y] -> point object
	for _, pt in ipairs(points) do
		local x = pt[1]
		local y = pt[2]
		if ((x ~= lastX) or (y ~= lastY)) then  -- Filter out duplicates
			if (nextNameIdx > pointNames:len()) then
				error("Cannot parse file " .. fileName .. ", there are too many points");
			end
			local point =
			{
				name = pointNames:sub(nextNameIdx, nextNameIdx),
				coords = {x, y},
				edges = {}
			}
			nextNameIdx = nextNameIdx + 1
			res.points[point.name] = point
			pointsByCoords[x] = pointsByCoords[x] or {}
			pointsByCoords[x][y] = point
			lastX = x
			lastY = y
		end
	end
	for _, edge in ipairs(edges) do
		local pt1 = pointsByCoords[edge[1]][edge[2]]
		local pt2 = pointsByCoords[edge[3]][edge[4]]
		assert(pt1.name ~= pt2.name)
		ins(res.edges, {pt1, pt2})
		ins(pt1.edges, pt2)
		ins(pt2.edges, pt1)
	end

	extendEdges(res)
	return res
end





--- Reads the input from the specified file, checks it for validity and returns the calculation-optimized
-- representation of the data
function loadInputFile(fileName)
	assert(type(fileName) == "string")

	-- Read the file contents:
	local f = assert(io.open(fileName), "Cannot open file " .. fileName)
	local allstr = f:read("*all")
	f:close()

	if (allstr:sub(1, 14) == "# SimplePoints") then
		return loadFromSimplePoints(fileName, allstr)
	else
		return loadFromLuaFile(fileName, allstr)
	end
end
