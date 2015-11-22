import std.stdio;
import std.path;
import std.file;
import std.conv;
import std.algorithm;
import std.array;
import std.string;
import std.process;
import gdallookup;

void main()
{
	string gdalfolder = which("gdalwarp.exe"); //return folder that consist gdalwarp.exe file
	string example = buildPath(getcwd, "images\\example.jpg");
	//writeln("example img path: ", example);
	//writeln;
	//writeln("cwd: ", getcwd());
	//writeln;
	
	if(!exists(example))
	{
		writeln("example image do not exists");
		return;
	}
	gdalProcessFile(example);
}

	// before calling we should set PATH to current CMD session like: SET PATH=%PATH%;
	// GDAL_DATA Need to be specified too! --> GDAL\gdal-data
	// better to call both command with --config key like:
	// gdalwarp --config GDAL_DATA "D:/my/gdal/data"

/* Example of manual calling:

"C:\Program Files (x86)\GDAL\gdal_translate.exe" --config GDAL_DATA "C:\Program Files (x86)\GDAL\gdal-data" -of JPEG ^
-gcp 609.379425 715.418998 -57.807336 -51.682874 ^
-gcp 298.566685 214.554344 -119.989166 29.990432 ^
-gcp 448.665859 29.746925 -90.013676 60.009832 ^
-gcp 1701.491957 16.627166 160.332297 61.932027 ^
-gcp 1648.377555 399.601398 150.005315 0.001500 ^
-gcp 1499.114107 214.648079 120.002269 30.017098 ^
-gcp 1059.517674 182.404592 32.292795 35.065381 ^
-gcp 899.988711 214.936138 0.036211 30.004496 ^
-gcp 899.945721 398.018136 0.000926 0.001867 ^
-gcp 149.345029 768.745707 -150.009238 -59.992892 ^
-gcp 49.086449 582.265595 -169.974976 -29.993605 ^
-gcp 1348.177466 29.815091 90.002152 60.003958 ^
-gcp 1648.494330 215.373824 149.992562 30.003650 ^
-gcp 1748.976811 216.240451 170.016828 29.994199 ^
-gcp 1499.521371 768.927413 119.988446 -59.993457 ^
-gcp 1648.287924 766.928166 150.033080 -59.993457 ^
D:\code\GdalWarpReproj\test\20151012.0000.multisat.ir.stitched.Global.x.jpg D:\code\GdalWarpReproj\test\ready\output.jpg

"C:\Program Files (x86)\GDAL\gdalwarp.exe" --config GDAL_DATA "C:\Program Files (x86)\GDAL\gdal-data" -s_srs EPSG:4326 -t_srs '+proj=aea +lat_1=35 +lat_2=5 +lat_0=20 +lon_0=145 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs' -r cubicspline D:\code\GdalWarpReproj\test\ready\output.jpg D:\code\GdalWarpReproj\test\ready\1_proj.jpg -order 3	

*/

	void gdalProcessFile(string imageFullName) //FIXME: Now it's process File, not Dir!
	{

		string gdalfolder = which("gdalwarp.exe"); //return folder that consist gdalwarp.exe file
			
			// before calling we should set PATH to current CMD session like: SET PATH=%PATH%;
			// GDAL_DATA Need to be specified too! --> GDAL\gdal-data
			// better to call both command with --config key like:
			// gdalwarp --config GDAL_DATA "D:/my/gdal/data"

			// GDAL_DATA folder include metadatas that needed for processing
			string gdal_data_folder = buildPath(gdalfolder, "gdal-data");
			if (!exists(gdal_data_folder))
			{
				writeln("[ERROR] GDAL-DATA do not exists in GDAL folder. Can't continue.");
				return;
			}

			string gdalFullPath = buildPath(gdalfolder, `gdal_translate.exe`);

		bool reprojectToWGS84 = false;	

		//every folder with images should have subfolder "data"
		//that should include file named "points.txt"
		string pointFile = buildPath(imageFullName.dirName, "data", "points.txt");
		string projParamsFileName = buildPath(imageFullName.dirName, "data", "proj_params.txt");
		string projParamsWgs84FileName = buildPath(imageFullName.dirName, "data", "proj_params_wgs84.txt"); //for final reprojection

		string projParamsWGS84FileContent;

		if(!pointFile.exists)
		{
			writeln("Folder do not have data/points.txt. This file is require for reprojecting");
			readln;
		}

		if(!projParamsFileName.exists)
		{
			writeln("Folder do not have data/proj_params.txt. This file is require for reprojecting");
			readln;
		}

		if(projParamsWgs84FileName.exists) // WGS84 transformation final. If EXISTS!
		{
			reprojectToWGS84 = true;
			projParamsWGS84FileContent = projParamsWgs84FileName.readText();
		}

			string projParamsFileContent = projParamsFileName.readText();

			File file = File(pointFile, "r"); 
			string contentWithGsp = to!string(file.byLine.map!(a => "-gcp " ~ a ~ " ").joiner);
			//writeln(contentWithGsp);

				if (imageFullName.getSize/1024 < 100) //if image less then 100KB than skip it
					imageFullName.remove;

				// adding for FullImageName _reproj postfix, temp for 
				string outputImageName_temp = to!string(imageFullName).stripExtension ~ "_temp" ~ to!string(imageFullName).extension;
				string outputImageName_reproj = to!string(imageFullName).stripExtension ~ "_reproj" ~ to!string(imageFullName).extension;

				string currentImageExtension = (to!string(imageFullName).extension).replace(".","").toUpper; // it's should be passed as argiment bellow
				// if extension "jpg" it's should be renamed to "JPEG"
				// FIXME: need to add check other extension, for example for geotiff

				if (currentImageExtension == "JPG")
					currentImageExtension = currentImageExtension.replace("JPG", "JPEG");
				writeln(currentImageExtension);


				//FIXME need ability to specified other file types. 
				string gdal_translate_string_for_cmd = `"` ~ gdalFullPath  ~ `" --config GDAL_DATA "` ~ gdal_data_folder ~ `"` ~ ` -of ` ~ currentImageExtension ~ " " ~ contentWithGsp ~ " " ~ imageFullName ~ " " ~ outputImageName_temp; 

				//writeln(gdal_translate_string_for_cmd);
				//writeln;
				string gdalwarp_command_for_cmd = `"` ~ buildPath(gdalfolder, "gdalwarp.exe") ~ `"` ~ ` --config GDAL_DATA "` ~ gdal_data_folder ~ `" ` ~ projParamsFileContent ~ " " ~ outputImageName_temp ~ " " ~ outputImageName_reproj ~ " -order 3";
				writeln;
				writeln(gdalwarp_command_for_cmd);
				writeln;
				readln;

				string gdalwarp_command_WGS84_for_cmd;
				if(reprojectToWGS84)
				{
					gdalwarp_command_WGS84_for_cmd = `"` ~ buildPath(gdalfolder, "gdalwarp.exe") ~ `" ` ~ projParamsWGS84FileContent ~ " " ~ outputImageName_reproj ~ " " ~ outputImageName_reproj.replace("_reproj", "_reproj_WGS84");
					writeln(gdalwarp_command_WGS84_for_cmd);
				}
				//projParamsWGS84FileContent
				
				// we should use spawnShell because it use
				// rules about command structure, argument/filename quoting and escaping of special characters

				/*
				D:\code\GdalReprojectExample\GDAL\gdalwarp.exe -t_srs "+proj=longlat +ellps=WGS84" D:\code\GdalReprojectExample\images\example_reproj.jpg D:\code\GdalReprojectExample\images\output.jpg
				*/
				
				//GDAL Translate start
				auto gdal_translate_Pid = spawnShell(gdal_translate_string_for_cmd);
				if(wait(gdal_translate_Pid) !=0)
				{
					writeln("[ERROR] Gdal Translate failed");
					return;
				}
				else
					writeln("gdal translate DONE");

				//GDAL Warp start
				auto gdal_warp_Pid = spawnShell(gdalwarp_command_for_cmd);
				if(wait(gdal_warp_Pid) !=0)
				{
					writeln("[ERROR] Gdal Warp failed");
					return;
				}

				//GDAL warp for translate from local coordinat to WGS84 (last step)
				if(reprojectToWGS84)
				{
					auto gdal_warp_Pid_WGS84 = spawnShell(gdalwarp_command_WGS84_for_cmd);
					if(wait(gdal_warp_Pid_WGS84) !=0)
					{
						writeln("[ERROR] Gdal Warp failed");
						return;
					}
					writeln("Reprojection to WGS84 (final step complete)");
				}

				//now we should remove "_temp" images
				outputImageName_temp.remove;
				(outputImageName_temp ~ ".aux.xml").remove;

				//remove originals
				//imageFullName.remove;
				return;
			
	}

