@echo off

for %%I in (SquaresOblongs\*.in) do (
lua HowManySquares.lua %%I -q %%I_sq.html
lua HowManyOblongs.lua %%I -q %%I_obl.html
)

for %%I in (Triangles\*.in) do (
lua HowManyTriangles.lua %%I -q
)

for %%I in (HexTriangles\*.in) do (
lua HowManyTriangles.lua %%I -q
)

for %%I in (Squares\*.in) do (
lua HowManySquares.lua %%I -q
)

lua CreateIndex.lua
lua CheckResultConsistency.lua

echo Done
