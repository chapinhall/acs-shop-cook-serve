
### Set Up Workspace
  rm(list=ls())
  "%&%" <- function(...){ paste(..., sep="")}
  
  library(acs) # This package isn't (yet) used directly to download ACS data, since it generates pulls using the Census API, and 
  #   only a subset of Census data sets are available through the API. However, it has some useful helper functions to
  #   find codes for tables and geographies
  library(gdata)
  
  try(setwd("C:/Users/imorey/Documents/GitHub/acs-shop-cook-serve"), silent = T)
  try(setwd("/home/nick/GitHub/acs-shop-cook-serve"), silent = T)
  try(setwd("C:/Users/nmader/Documents/GitHub/acs-shop-cook-serve"), silent = T)
  dirRoot <- getwd()
  dirScripts <- dirRoot %&% "/scripts/"
  dirDl      <- dirRoot %&% "/data/raw-downloads/"
  dirSave    <- dirRoot %&% "/data/prepped-data/"
  dirMetaFiles <- dirSave
  setwd(dirDl)
  
  for (d in c(dirRoot, dirScripts, dirDl, dirSave)) {
    print(file.exists(d))
    if (!file.exists(d)) {
      dir.create(d)
    } else {
      
    }
  }
  source(dirScripts %&% "/download_acs_fn.r")

#---------------
### Set up pulls
#---------------
  downloadData <- TRUE
  mySpan  <- 1
  myState <- "Illinois"
  mySt <- "IL"
  myTables <- unlist(strsplit("B01001 B01001A B01001B B01001C B01001D B01001E B01001F B01001G B01001H B01001I B08006 B08008 B08011 B08012 B08013 B15001 B15002 B17001 B12001 B12002 B12006 B17003 B17004 B17005 B19215 B14004 B14005 B19216 B05003 B23001 B23018 B23022 B24012 B24022 B24042 B24080 B24082 B24090 C24010 C24020 C24040 B11001 B11003 B11004 B13002 B13012 B13014 B17022 B23007 B23008 B25115 B17010 B17010A B17010B B17010C B17010D B17010E B17010F B17010G B17010H B17010I C23002A C23002B C23002C C23002D C23002E C23002F C23002G C23002H C23002I B20017 B20017A B20017B B20017C B20017D B20017E B20017F B20017G B20017H B20017I C15002 C15002A C15002B C15002C C15002D C15002E C15002F C15002G C15002H C15002I B17018 B20004 B24042 C24040", split= " ")) # Can't find B13016, at least in 2009 data. Look at the MergedMetaFiles.csv file that was created to look for extent of overlap across ACS years.
  #myTables <- "B17022"
  myGeos <- data.frame(c("Cook County", 050),
                       c("Will County", 050),
                       c("Lake County", 050),
                       c("Kane County", 050),
                       c("McHenry County", 050),
                       c("DuPage County", 050),
                       c("Chicago city", 160),
                       c("Chicago city", 312))
  myGeos <- data.frame(t(myGeos))
  colnames(myGeos) <- c("Place", "SumLevel")
  rownames(myGeos) <- NULL
  # Also note that these levels can be looked up using the geo.lookup function in the "acs" package, although you need to
  #   know the level of the geography that you're looking for (e.g. that "Chicago city" is a "place")
  # Alternatively, by opening up one of the geographic reference files from the Census downloads (presuming that you've
  #   done one already), you can look up summary level information by name of place, e.g. by:
  #     geoFile[grepl("Chicago city", geoFile$NAME), c("SUMLEVEL", "NAME")]
  #   That search will return all summary levels for which that string can be found. When looking for "Chicago city", the
  #   three responses were for summary levels
  #     60 : "Chicago city, Cook County, Illinois" which is a State-County-County Subdivision;
  #     160: "Chicago city, Illinois" which is a State-Place; and
  #     312: "Chicago city, IL, Chicago-Naperville-Joliet, IL-IN-WI Metropolitan Statistical Area.
  # 
  # Look here to look up what each summary level translates to in words (i.e., that 160 is a "State-Place"):
  # http://factfinder2.census.gov/help/en/glossary/s/summary_level_code_list.htm
  

#-----------------
### Call for pulls 
#-----------------
  
  
  
for (myYear in 2008:2012) { # 2010:2012
  myPull <- getAcs(pullYear = myYear, pullSpan = 1, pullState = "Illinois", pullSt = "IL", pullGeos = myGeos, pullTables = myTables, dirMetaFiles = dirSave, dirDl = dirDl, downloadData = TRUE)
    myData <- myPull[[1]]
    myDict <- myPull[[2]]
  write.csv(myData, file = paste0(dirSave, "ACS_", myYear, "_", mySpan, "Year_", mySt, "_PreppedVars.csv"))
  write.csv(myDict, file = paste0(dirSave, "ACS_", myYear, "_", mySpan, "Year_", mySt, "_PreppedVars_Dict.csv"))

}