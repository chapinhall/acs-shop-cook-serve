
### Set Up Workspace
  rm(list=ls())
  "%&%" <- function(...){ paste(..., sep="")}

  #myLocalUser <- "nmader.CHAPINHALL"
  myLocalUser <- "nmader"
  dirRoot <- "C:/Users/nmader/Documents/GitHub/acs-shop-cook-serve/"
  dirScripts <- dirRoot %&% "scripts/"
  dirDl <- dirRoot %&% "data/raw-downloads/"
  dirSave <- dirRoot %&% "data/prepped-data/"
  setwd(dirDl)
  source(dirScripts %&% "download_acs_fn.r")

#---------------
### Set up pulls
#---------------
  downloadData <- FALSE
  myYear <- "2012"
  mySpan  <- 1
  myState <- "Illinois"
  mySt <- "IL"
  myCounties  <- c("Cook County", "Will County", "Lake County", "Kane County", "McHenry County", "DuPage County")
  myTables <- unlist(strsplit("B01001 B01001A B01001B B01001C B01001D B01001E B01001F B01001G B01001H B01001I B08006 B08008 B08011 B08012 B08013 B15001 B15002 B17001 B12001 B12002 B12006 B17003 B17004 B17005 B19215 B19216 B14004 B14005 B05003 B23001 B23018 B23022 B24012 B24022 B24042 B24080 B24082 B24090 C24010 C24020 C24040 B11001 B11003 B11004 B13002 B13012 B13014 B13016 B17022 B23007 B23008 B25115", split= " "))

#-----------------
### Call for pulls 
#-----------------
  myData <- getAcs(pullYear = 2012, pullSpan = 1, pullState = "Illinois", pullSt = "IL", pullCounties = myCounties, pullTables = myTables, dirDl = dirDl, downloadData = TRUE)
  writecsv(myData, paste0(dirSave, "ACS_", pullYear, "_", pullSpan, "Year_", pullSt, "_PreppedVars.csv"))


  
  