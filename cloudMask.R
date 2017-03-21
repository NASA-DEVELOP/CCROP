# Notices:
# Copyright 2017 United States Government as represented by the Administrator of the 
# National Aeronautics and Space Administration. All Rights Reserved.
 
# Disclaimers
# No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY WARRANTY OF ANY KIND, 
# EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, ANY WARRANTY THAT 
# THE SUBJECT SOFTWARE WILL CONFORM TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT THE SUBJECT 
# SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT DOCUMENTATION, IF PROVIDED, WILL CONFORM 
# TO THE SUBJECT SOFTWARE. THIS AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT 
# BY GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING DESIGNS, HARDWARE, 
# SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING FROM USE OF THE SUBJECT SOFTWARE.  
# FURTHER, GOVERNMENT AGENCY DISCLAIMS ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY 
# SOFTWARE, IF PRESENT IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
 
# Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS AGAINST THE UNITED STATES 
# GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S 
# USE OF THE SUBJECT SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR LOSSES 
# ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED ON, OR RESULTING FROM, 
# RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT SHALL INDEMNIFY AND HOLD HARMLESS THE 
# UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, 
# TO THE EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER SHALL BE THE 
# IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.



##*********************************************************************************
## DATE:   October 2nd, 2016
## AUTHOR: Sunita Yadav
## TEAM:   Glacier National Park Climate
## TERM:   Fall 2016
##*********************************************************************************
## Cloud Masking Script: The source code provided removes clouds, cloud shadow, 
## water, and snow pixels from Landsat scenes using the cloud mask layer provided 
## with Landsat data.
## CAUTION: cloud removal is dependent on the cloud mask layer provided. 
## Therefore, check any anomalies by verifying results with the cloud mask layer.
##*********************************************************************************

# work with raster data
library(raster)
# export GeoTIFFs and other core GIS functions
library(rgdal)

#set working dir
#C:\GNPC_data\L8
setwd("C:/GNPC_data/L7_cldmask_waterton/")
getwd()

#get a list of all the folders in the working dir
allfolders <- list.dirs(full.names=TRUE, recursive=FALSE)
allfolders
length(allfolders)


for (i in 1:length(allfolders)) {
    print("***************************************")
    print(allfolders[i])
    #get filenames for cloud masking
    allfiles <- list.files(paste(allfolders[i], sep="/"), full.names=TRUE, pattern="tif$")
    print(length(allfiles))
  
    ##exclude files that we do not need
    cldmask_files = list.files(paste(allfolders[i], sep="/"), full.names=TRUE, pattern="*cfmask*")
    misc_files = list.files(paste(allfolders[i], sep="/"), full.names=TRUE, pattern="*ipflag*")
    cld_files = list.files(paste(allfolders[i], sep="/"), full.names=TRUE, pattern="*cloud*")
    atm_files = list.files(paste(allfolders[i], sep="/"), full.names=TRUE, pattern="*atmos*")
    qa_files = list.files(paste(allfolders[i], sep="/"), full.names=TRUE, pattern="*qa*")
    #make the raster list by excluding certain files
    rasterList <- allfiles[!allfiles %in% cldmask_files] 
    rasterList <- rasterList[!rasterList %in% misc_files]
    rasterList <- rasterList[!rasterList %in% cld_files]
    rasterList <- rasterList[!rasterList %in% atm_files]
    rasterList <- rasterList[!rasterList %in% qa_files]
    #check number of rasters
    print(length(rasterList))
    rasterList
    print("==============================")
  
    #create raster brick object
    rgbRaster <- stack(rasterList)
    rgbBrick <- brick(rgbRaster)
  
    ##-------------------------------------------------------
    ## READ IN CLOUD MASK FILE
    ##-------------------------------------------------------
    #read in cld mask file
    cld_filename <- list.files(paste(allfolders[i], sep="/"), full.names=TRUE, pattern="*cfmask_clip.tif$")
    cldmask <- raster(cld_filename)
    print(cld_filename)
    print("======BANDS======")
    
    ##-----------------------------------------------------------
    ## SET TO NO DATA ALL PIXELS THAT >= 1 IN CLOUD MASK LAYER
    cldmask[cldmask >= 1] <- NA       # Pixel Reliability rank 3,4 pixels (cloudy) set to NA
    cldmask[cldmask == 0] <- 1        # Pixel Reliability rank 0 pixels (good quality) set to 1
 
    ##-----------------------------------------------------------
    #multiplying the raster layer stack by the cloud mask layer
    rgbBrick = rgbBrick * cldmask 
  
    ##-------------------------------------------
    # unstack object for writing rasters
    un_rgbBrick <- unstack(rgbBrick)
    # use original filenames
    outputnames2 <- paste(rasterList)
    
    ##write the brick bands to tif files
    for(i in seq_along(un_rgbBrick)) {
      print(outputnames2[i])
      writeRaster(un_rgbBrick[[i]], filename=outputnames2[i], format="GTiff", overwrite=TRUE)
    }
    
    #clean up before iteration of next folder
    rm(rgbBrick, rgbRaster, cldmask, rasterList)
    print("***************************************")
}


