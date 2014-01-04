#########################################################################
#
# DOWNLOAD, EXTRACT, AND SELECT DATA FOR CUSTOM DATA SETS AND GEOGRAPHIES
# Developed by Chapin Hall
# Authors: Nick Mader (nmader@chapinhall.org), ...
#
#########################################################################


### Set Up Workspace

  "%&%" <- function(...){ paste(..., sep="")}
  library(acs) # This package isn't (yet) used directly to download ACS data, since it generates pulls using the Census API, and 
    #   only a subset of Census data sets are available through the API. However, it has some useful helper functions to
    #   find codes for tables and geographies
  
  myLocalUser <- "nmader.CHAPINHALL"
  rootDir <- "C:/Documents and Settings/" %&% myLocalUser %&% "/My Documents/GitHub/acs-prep-cook-serve/"
  dlDir <- "C:/Documents and Settings/" %&% myLocalUser %&% "/My Documents/GitHub/acs-prep-cook-serve/data/raw-downloads/"
  setwd(dlDir)

### Define Pulls

  # NSM: we will want to convert this to a function so that users can call on this multiple times for different types of pulls, either with separate years

  pullYear <- c("2012")
  pullSpan  <- 1
  pullState <- "Illinois"
  pullCtny  <- c("Cook County", "Will County", "Lake County", "Kane County", "McHenry County", "DuPage County")  ## To avoid potentially non-unique pulls, "County" should be specified here
  pullTract <- "*"
  pullTables <- unlist(strsplit("B01001 B01001A B01001B B01001C B01001D B01001E B01001F B01001G B01001H B01001I B08006 B08008 B08011 B08012 B08013 B15001 B15002 B17001 B12001 B12002 B12006 B17003 B17004 B17005 B19215 B19216 B14004 B14005 B05003 B23001 B23018 B23022 B24012 B24022 B24042 B24080 B24082 B24090 C24010 C24020 C24040 B11001 B11003 B11004 B13002 B13012 B13014 B13016 B17022 B23007 B23008 B25115", split= " "))


  # Look up geography codes using the acs package
    pullSt <- "IL"


### Download and Extract Data

  # For now, this is just a test run using a sample data set
  
  myPathFileName <- dlDir %&% "Illinois_All_Geographies.zip"
  remoteDataName <- paste0("http://www2.census.gov/acs", pullYear, "_", pullSpan, "yr/summaryfile/", pullYear, "_ACSSF_By_State_All_Tables/", pullState, "_All_Geographies.zip")

  tableLookup <- read.csv(url(paste0("http://www2.census.gov/acs", myYear, "_", pullSpan, "yr/summaryfile/Sequence_Number_and_Table_Number_Lookup.txt"), header = TRUE)
  download.file(remoteDataName, myPathFileName)
  unzip(zipfile = myPathFileName) # NSM: am having problems explicitly feeding an argument to "exdir" for this function.
                                  # For now, it's using the current working directory as the default.

  geoLabels <- read.csv(paste0(rootDir, "data/prepped-data/geofile-fields.csv"), header=T) # Note--this file was created by hand from the labels in the SAS version of the data prep file. See ".../scripts/Summary file assembly script from Census.sas"
  geoFile <- read.csv(paste0(dlDir, "g", pullYear, pullSpan, tolower(pullSt), ".csv"), header=F)
  colnames(geoFile) <- geoLabels$geoField
  
  geoLabels <- c()
  names(geoLabels) <- c("FILEID", "STUSAB", "SUMLEVEL", "COMPONENT", "LOGRECNO", "US", "REGION", "DIVISION", "STATECE", "STATE", "COUNTY", "COUSUB", "PLACE", "TRACT", "BLKGRP", "CONCIT", "CSA", "METDIV", "UA", "UACP", "VTD", "ZCTA3", "SUBMCD", "SDELM", "SDSEC", "SDUNI", "UR", "PCI", "TAZ", "UGA", "GEOID", "NAME", "AIANHH", "AIANHHFP", "AIHHTLI", "AITSCE", "AITS", "ANRC", "CBSA", "MACC", "MEMI", "NECTA", "CNECTA", "NECTADIV", "CDCURR", "SLDU", "SLDL", "ZCTA5", "PUMA5", "PUMA1")
    
  
    
      FILEID  ='File Identification'           STUSAB   ='State Postal Abbreviation' 		SUMLEVEL='Summary Level'            	COMPONENT='geographic Component'
		LOGRECNO='Logical Record Number'	    US       ='US'
		REGION  ='Region'						DIVISION ='Division'
		STATECE ='State (Census Code)'			STATE    ='State (FIPS Code)'
		COUNTY  ='County'						COUSUB   ='County Subdivision (FIPS)'
		PLACE   ='Place (FIPS Code)'			TRACT    ='Census Tract'
		BLKGRP  ='Block Group'					CONCIT   ='Consolidated City'
		CSA     ='Combined Statistical Area'	METDIV  ='Metropolitan Division'
		UA      ='Urban Area'                   UACP    ='Urban Area Central Place'
		VTD     ='Voting District'				ZCTA3  ='ZIP Code Tabulation Area (3-digit)'
		SUBMCD  ='Subbarrio (FIPS)'				SDELM  ='School District (Elementary)'
		SDSEC   ='School District (Secondary)'	SDUNI  ='School District (Unified)'
		UR      ='Urban/Rural'					PCI    ='Principal City Indicator'
		TAZ     ='Traffic Analysis Zone'		UGA    ='Urban Growth Area'
		GEOID   ='geographic Identifier'		NAME   ='Area Name' 					    
		AIANHH  ='American Indian Area/Alaska Native Area/Hawaiian Home Land (Census)'
		AIANHHFP='American Indian Area/Alaska Native Area/Hawaiian Home Land (FIPS)'
		AIHHTLI ='American Indian Trust Land/Hawaiian Home Land Indicator'
		AITSCE  ='American Indian Tribal Subdivision (Census)'
		AITS    ='American Indian Tribal Subdivision (FIPS)'
		ANRC    ='Alaska Native Regional Corporation (FIPS)'
		CBSA    ='Metropolitan and Micropolitan Statistical Area'
		MACC    ='Metropolitan Area Central City'	
		MEMI    ='Metropolitan/Micropolitan Indicator Flag'
		NECTA   ='New England City and Town Combined Statistical Area'
		CNECTA  ='New England City and Town Area'
		NECTADIV='New England City and Town Area Division'
		CDCURR  ='Current Congressional District'
		SLDU    ='State Legislative District Upper'	
		SLDL    ='State Legislative District Lower'
		ZCTA5   ='ZIP Code Tabulation Area (5-digit)'
		PUMA5   ='Public Use Microdata Area - 5% File'
		PUMA1   ='Public Use Microdata Area - 1% File'	
    
    
### Select Tables and Merge Together

  a <- read.csv(paste0(dlDir, "e20121il0001000.txt"), header=F)
  g <- read.csv(paste0(dlDir, "g20121il.csv"), header=F)



# NSM: the tables come out in 178 separate files, where each in this 178 sequence is one of the summary file tables. The contents of each of those files
#   can be found in this table: http://www2.census.gov/acs2012_1yr/summaryfile/Sequence_Number_and_Table_Number_Lookup.txt.
# My current thought for the best way to import the data is to loop through each of the sequence tables, name, transpose or horizontally append them, and then aggregate them
# A complementary/alternative step would be to try to adapt the SAS code that is provided under the UserTools folder -- http://www2.census.gov/acs2012_1yr/summaryfile/UserTools/SF_All_Macro.sas

# Note--depending on how much we want to save space, we can delete all tables that were not requested for our use
# Note--the filenaming convention is unique across end-years, aggregations, and sequence numbers.
