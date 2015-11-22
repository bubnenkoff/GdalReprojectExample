module gdallookup;

import std.stdio;
import std.process;   // environment
import std.algorithm; // splitter
import std.file;      // exists
import std.path;      // separator

//FIND and return PATH where GDAL libs located
string which(string executableName) // analog of unix which
{
    string binlocation = "";
    auto path = environment["PATH"];
	//pathSeparator - Windows use ";" separator, Linux use ":"
    auto dirs = splitter(path, pathSeparator);
	
	//INNER folder always primary!
	if (exists(buildPath(getcwd, "GDAL", executableName)))
	{
		//path to inner GDAL folder. Not tested on Unix
		//writeln((buildPath(getcwd, "GDAL", executableName)));
		binlocation = buildPath(getcwd, "GDAL");
	}
	//ONLY if gdal DO NOT present in current location we should do scanning
	if (binlocation.length == 0) // nothing found in PATH
	{
		foreach (dir; dirs) 
		{
			//auto tmpPath = dir;
			if (exists(dir ~ dirSeparator ~ executableName)) 
			{
				writeln("GDAL from system PATH.");
				binlocation = dir ~ dirSeparator;
			}			
		}
	
			if (exists(`C:\Program Files (x86)\GDAL\` ~ executableName))
			{
				binlocation = `C:\Program Files (x86)\GDAL\`;
			}
			
			else if (exists(`C:\Program Files\GDAL\` ~ executableName))
			{
				binlocation = `C:\Program Files\GDAL\`;
			}
			
			else if (exists(`C:\gdal\gdal\apps\` ~ executableName))
			{
				binlocation = `C:\gdal\gdal\apps\`;
			}
					
			else
			{
				writeln(`[ERROR] Can't find GDAL files. Please check if GDAL libs in system`);
				writeln(`Try to place GDAL libs in \GDAL folder inside your App`);
			}
		}
	
	writeln("GDAL bin located: ", binlocation);
    return binlocation;
} 

/*
void main(string[] args) 
{
	version(Windows)
	{
		writeln(which("gdalwarp.exe")); // output: /usr/bin/wget
	}
	version(Linux)
	{
		writeln(which("gdalwarp")); // output: /usr/bin/wget
	}


}
*/