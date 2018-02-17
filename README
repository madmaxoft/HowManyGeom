HowManyGeom
===========

This is a set of scripts that I wrote out of frustration - I didn't want to count "how many triangles" or "how many squares" in a picture, because I knew I would miss some. And it was a nice challenge to actually do this.

Each script is named properly and takes a single input file name as parameter, optional "-q" parameter and optional output file name. Without the -q parameter the script writes the results to the console, in a simplified way, as well as to th eoutput file. The generated output file is a nice HTML that shows the original picture and lists each found shape. When run without any params, shows the invokation reminder and exits with code 0. Upon error in the input file, the error message is output to the console and the script aborts with a nonzero exit code.

## Input file format
There are two input formats understood by this tool. Either a "Lua", or a "SimplePoints" description of the mesh. The script can auto-detect between the two formats. There are exampels of both formats in the Triangles folder.

### Lua description
This should be a valid Lua source file that returns a table with two members: points and edges. The points whould be a dictionary of <letter> -> {x, y}, the edges should be an array of two-letter strings, each letter representing the endpoint of the edge. Here's an example:
```lua
return
{
	points =
	{
		a = {0, 0},
		b = {1, 0},
		c = {2, 0},
		d = {0, 1},
		e = {1, 1},
		f = {2, 1},
		g = {0, 2},
		h = {1, 2},
		i = {2, 2},
	},

	edges =
	{
		"ab", "ad", "ae",
		"bc", "be",
		"ce", "cf",
		"dg",
		"eg", "eh", "ei",
		"fi",
		"gh",
		"hi"
	},
}
```
Note that the script will NOT detect if the edges cross and will not give the right answer in such a case.

### SimplePoints description
This is a simple text file where the first line says `# SimplePoints` (note the space after `#`) and then each line defines one edge, using its endpoint coordinates. Any line starting with a `#` is considered a comment and is ignored. This is an example input:
```
# SimplePoints
0, 0 - 2, 0
0, 0 - 2, 2
0, 0 - 0, 2
1, 0 - 2, 2
2, 0 - 0, 2
2, 0 - 2, 2
0, 1 - 2, 2
0, 2 - 2, 2
```
The script WILL detect if the edges intersect and WILL give the right answer even in such case.