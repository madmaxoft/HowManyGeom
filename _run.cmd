@echo off
for %%i in (Triangles\*.in) do (
lua HowManyTriangles.lua %%i -q
)

echo Done
