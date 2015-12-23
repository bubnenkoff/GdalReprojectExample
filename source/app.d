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

..\gdal\gdal_translate -a_srs EPSG:3413 201512202100-00.png 201512202100-00.tif --config GDAL_DATA ..\gdal\gdal-data ^
-gcp 529.42231841 224.22090981 1920014.070 2288183.665 ^
-gcp 276.59548166 179.50734792 2586827.958 1493505.818 ^
-gcp 149.26295228 528.29412763 3876554.401 2238129.727 ^
-gcp 529.37873987 594.54737286 2877284.115 3429013.681 
..\gdal\gdalinfo 201512202100-00.tif
@..\gdal\gdalwarp --config GDAL_DATA ..\gdal\gdal-data -t_srs EPSG:3857 201512202100-00.tif output.jp2




*/

	void gdalProcessFile(string imageFullName) //FIXME: Now it's process File, not Dir!
	{

		string gdalfolder = which("gdalwarp.exe"); //return folder that consist gdalwarp.exe file
		string gdalpluginpath = (gdalfolder ~ `gdal\plugins\`); //for JP2 support
			
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

		bool is_gdal_warp_params = false;	

		//every folder with images should have subfolder "data"
		//that should include file named "points.txt"
		string pointFile = buildPath(imageFullName.dirName, "data", "points.txt");
		string proj_params_gdal_translate = buildPath(imageFullName.dirName, "data", "proj_params_gdal_translate.txt");
		string proj_params_gdalwarp = buildPath(imageFullName.dirName, "data", "proj_params_gdalwarp.txt"); //for final reprojection

		string gdal_warp_params_content;

		if(!pointFile.exists)
		{
			writeln("Folder do not have data/points.txt. This file is require for reprojecting");
			readln;
		}

		if(!proj_params_gdal_translate.exists)
		{
			writeln("Folder do not have data/proj_params.txt. This file is require for reprojecting");
			readln;
		}

		if(proj_params_gdalwarp.exists) // WGS84 transformation final. If EXISTS!
		{
			is_gdal_warp_params = true;
			gdal_warp_params_content = proj_params_gdalwarp.readText();
		}

			string projParamsFileContent = proj_params_gdal_translate.readText();
			writeln("--------------------------------");
			writeln("proj_params_gdal_translate: ", proj_params_gdal_translate);
			writeln("--------------------------------");
			writeln("gdal_warp_params_content: ", gdal_warp_params_content);
			writeln("--------------------------------");


			File file = File(pointFile, "r"); 
			string contentWithGsp = to!string(file.byLine.map!(a => "-gcp " ~ a ~ " ").joiner);
			//writeln(contentWithGsp);

				if (imageFullName.getSize/1024 < 30) //if image less then 30KB than skip it
					imageFullName.remove;

				// adding for FullImageName _reproj postfix, temp for 
				string outputImageName_temp = to!string(imageFullName).stripExtension ~ "_temp" ~ (to!string(imageFullName).extension).replace("jpg","jpg");
				string outputImageName_reproj = to!string(imageFullName).stripExtension ~ "_reproj" ~ (to!string(imageFullName).extension).replace("jpg","jpg");

				string currentImageExtension = (to!string(imageFullName).extension).replace(".","").toUpper; // it's should be passed as argiment bellow
				// if extension "jpg" it's should be renamed to "JPEG"
				// FIXME: need to add check other extension, for example for geotiff

				if (currentImageExtension == "JPG")
					currentImageExtension = currentImageExtension.replace("JPG", "JP2");
				writeln(currentImageExtension);


				//FIXME need ability to specified other file types. 
				string gdal_translate_string_for_cmd = `"` ~ gdalFullPath  ~ `" -of JP2OpenJPEG --config GDAL_DATA "` ~ gdal_data_folder ~ `" ` ~ projParamsFileContent  ~ " " ~ contentWithGsp ~ " " ~ imageFullName ~ " " ~ outputImageName_temp; 

				writeln(gdal_translate_string_for_cmd);
				writeln;
				string gdalwarp_command_for_cmd = `"` ~ buildPath(gdalfolder, "gdalwarp.exe") ~ `"` ~ ` --config GDAL_DATA "` ~ gdal_data_folder ~ `" ` ~ gdal_warp_params_content ~ " " ~ outputImageName_temp ~ " " ~ outputImageName_reproj ~ " -order 1";
				writeln;
				writeln(gdalwarp_command_for_cmd);
				writeln;
				readln;

				string gdalwarp_command_WGS84_for_cmd;
				if(is_gdal_warp_params)
				{
					gdalwarp_command_WGS84_for_cmd = `"` ~ buildPath(gdalfolder, "gdalwarp.exe") ~ `"` ~ ` --config GDAL_DATA "` ~ gdal_data_folder ~ `" ` ~ gdal_warp_params_content ~ " " ~ outputImageName_reproj ~ " " ~ outputImageName_reproj.replace("_reproj", "_reproj_WGS84");
					writeln(gdalwarp_command_WGS84_for_cmd);
				}
				//gdal_warp_params_content
				
				// we should use spawnShell because it use
				// rules about command structure, argument/filename quoting and escaping of special characters

				/*
				D:\code\GdalReprojectExample\GDAL\gdalwarp.exe -t_srs "+proj=longlat +ellps=WGS84" D:\code\GdalReprojectExample\images\example_reproj.jpg D:\code\GdalReprojectExample\images\output.jpg
				*/
				
				auto gdal_plugin_Pid = spawnShell(`SET PATH = "` ~ gdalpluginpath ~ `"`); //JP2 support

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
				if(is_gdal_warp_params)
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

					//outputImageName_temp.remove;
					//(outputImageName_temp ~ ".aux.xml").remove;

				//remove originals
				//imageFullName.remove;
				return;
			
	}

