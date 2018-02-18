@echo off
for %%i in (Triangles\*.in) do (
lua HowManyTriangles.lua %%i -q
)

for %%i in (HexTriangles\*.in) do (
lua HowManyTriangles.lua %%i -q
)

for %%i in (Squares\*.in) do (
lua HowManySquares.lua %%i -q
)

lua CreateIndex.lua

echo Done
