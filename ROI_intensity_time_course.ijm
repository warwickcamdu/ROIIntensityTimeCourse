//Set output directory
#@ File (label = "Input image", style = "file") imageFile
#@ File (label = "Output directory", style = "directory") outDir
#@ Boolean (label = "Subtract background?") subtractBackgroundBool

//Open image
openingString = "open=" + imageFile + " autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT";
run("Bio-Formats", openingString);

//Get the name of the image
name=getTitle;
nameNoExt = split(name, ".");
nameNoExt = nameNoExt[0];

run("Duplicate...", "title=active duplicate");
selectWindow("active");
if (subtractBackgroundBool)
{
	run("Subtract Background...", "rolling=1000 stack");
}

selectWindow(name);
close();

roiManager("Show All");
setTool("polygon");
roiCounter = 0;

waitForUser("Draw an ROI of your choice, then click OK to add. If finished, click OK again. Click away from a completed ROI to cancel it.");

while(is("area")!=0)
{
	roiCounter = roiCounter + 1;
	roiManager("add");
	count = roiManager("count");
	roiManager("select", count-1);
	roiManager("Rename", "ROI" + roiCounter);
	run("Select None");
	waitForUser("Draw an ROI of your choice, then click OK to add. If finished, click OK again. Click away from a completed ROI to cancel it.");
}




//Make directories for intensity results and ROIs
resultsDir = outDir + "/intensity_results";

if(!(File.exists(resultsDir)))
{
	File.makeDirectory(resultsDir);
}

roiDir = outDir + "/ROIs";

if(!(File.exists(roiDir)))
{
	File.makeDirectory(roiDir);
}


//Create results files

outCSVName = resultsDir + "/" + name + "_results.csv";
outROIName = roiDir + "/" + name + "_ROIs.zip";

attempt = 1;

while(File.exists(outCSVName))
{
	attempt ++;
	outCSVName = resultsDir + "/" + name + "_results_" + attempt + ".csv";
	outROIName = roiDir + "/" + name + "_ROIs_" + attempt + ".zip";
}

//Save ROI
run("Select None");
roiManager("Save", outROIName);


numCells = roiManager("count");


//For each ROI, measure intensity for each frame
run("Set Measurements...", "mean redirect=None decimal=0");


roiManager("Multi Measure");

updateResults();


//Save normed length results
saveAs("results", outCSVName);

close("*");