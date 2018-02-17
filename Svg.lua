-- Svg.lua

-- Implements a basic SVG serializer with rescaling capabilities, customized for our calc data


--[[
Usage:
local Svg = require("svg")
local svg = Svg.new(500, 400, data)  -- Creates a new SVG that will be 500 x 400 pixels
svg:drawEdge(data.edge[1], "stroke:rgb(0, 255, 0);stroke-width:5")
svg:drawPoint(data.points["a"], "stroke:rgb(128,128,128);stroke-width:1;fill:none")
local triangle =
{
	data.points["a"],
	data.points["b"],
	data.points["c"],
}
svg:drawPolyline(triangle, "stroke:rgb(128,128,128);stroke-width:1")
file:write(svg:wholeOutput())  -- Output the SVG data
stream:write(svg:header())
stream:write(svg:dataOutput())
stream:write(svg2:dataOutput())  -- Join two SVG datastreams together by simple appending
steram:write(svg:footer())
svg.clear()  -- Now the object can be reused for another SVG; the dimensions set earlier still stay
--]]




local Svg = {}
Svg.__index = Svg

local table = table
local string = string





--- Returns true if the specified object likely represents a set of coords
local function isCoords(coords)
	return (
		(type(coords) == "table") and
		(type(coords[1]) == "number") and
		(type(coords[2]) == "number")
	)
end





--- Returns true if the specified object likely represents a point
local function isPoint(point)
	return (
		(type(point) == "table") and
		isCoords(point.coords) and
		(type(point.edges) == "table")
	)
end





--- Returns true if the specified object likely represents an edge
local function isEdge(edge)
	return (
		(type(edge) == "table") and
		isPoint(edge[1]) and
		isPoint(edge[2])
	)
end





--- Returns true if the specified object likely represents the calculation data
local function isData(data)
	return (
		(type(data) == "table") and
		(type(data.points) == "table") and
		(type(data.edges) == "table") and
		(type(data.extEdges) == "table")
	)
end





local function isSvg(svg)
	local meta = getmetatable(svg)
	return (
		(type(svg) == "table") and
		(type(meta) == "table") and
		(type(meta.drawEdge) == "function") and
		(type(meta.dataOutput) == "function")
	)
end





local function findMaxCoords(data)
	assert(isData(data))
	local maxX = -1e30
	local maxY = -1e30
	for _, pt in pairs(data.points) do
		if (pt.coords[1] > maxX) then
			maxX = pt.coords[1]
		end
		if (pt.coords[2] > maxY) then
			maxY = pt.coords[2]
		end
	end
	return {maxX, maxY}
end





function Svg:clear()
	assert(isSvg(self))

	self.data = {}
end





function Svg:dataCoordsToSvgCoords(dataCoords)
	assert(isSvg(self))
	assert(isCoords(dataCoords))

	local x = 10 + dataCoords[1] * (self.width - 20) / self.maxX
	local y = 10 + dataCoords[2] * (self.height - 20) / self.maxY
	return {x, y}
end





function Svg:dataOutput()
	assert(isSvg(self))

	return table.concat(self.data, "\n")
end





function Svg:drawEdge(edge, style)
	assert(isSvg(self))
	assert(isEdge(edge))
	assert(type(style or "") == "string")

	local coords1 = self:dataCoordsToSvgCoords(edge[1].coords)
	local coords2 = self:dataCoordsToSvgCoords(edge[2].coords)
	table.insert(self.data, string.format(
		[[<line x1="%s" y1="%s" x2="%s" y2="%s" style="%s" />]],
		coords1[1], coords1[2], coords2[1], coords2[2], style or ""
	))
end





function Svg:drawPoint(point, style)
	assert(isSvg(self))
	assert(isPoint(point))
	assert(type(style or "") == "string")

	local coords = self:dataCoordsToSvgCoords(point.coords)
	table.insert(self.data, string.format(
		[[<circle cx="%s" cy="%s" r="%s" style="%s" />]],
		coords[1], coords[2], 5, style or ""
	))
end





function Svg:drawPolyline(polygon, style)
	assert(isSvg(self))
	assert(type(polygon) == "table")
	assert(isPoint(polygon[1]))
	assert(type(style or "") == "string")

	local lastPt = polygon[#polygon]
	local lastCoords = self:dataCoordsToSvgCoords(lastPt.coords)
	for _, pt in ipairs(polygon) do
		local coords = self:dataCoordsToSvgCoords(pt.coords)
		table.insert(self.data, string.format(
			[[<line x1="%s" y1="%s" x2="%s" y2="%s" style="%s" />]],
			lastCoords[1], lastCoords[2], coords[1], coords[2], style or ""
		))
		lastCoords = coords
	end
end





function Svg:footer()
	-- No configurable entities here
	return "Get a better browser with SVG support.</svg>"
end





function Svg:header()
	assert(isSvg(self))

	return string.format(
		[[<svg width="%s" height="%s">]],
		self.width, self.height
	)
end





function Svg:wholeOutput()
	assert(isSvg(self))

	return self:header() .. self:dataOutput() .. self:footer()
end





local function newSvg(width, height, data)
	assert(width > 20)
	assert(height > 20)

	local maxCoords = findMaxCoords(data)
	local res =
	{
		width = width,
		height = height,
		maxX = maxCoords[1],
		maxY = maxCoords[2],
		data = {},
	}
	setmetatable(res, Svg)
	return res
end





return {
	new = newSvg,
}