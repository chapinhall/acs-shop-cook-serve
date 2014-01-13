#########################################################################
#
# DOWNLOAD, EXTRACT, AND SELECT DATA FOR CUSTOM DATA SETS AND GEOGRAPHIES
# Developed by Chapin Hall
# Authors: Nick Mader (nmader@chapinhall.org), ...
#
#########################################################################


### Set Up Workspace

  rm(list=ls())
  "%&%" <- function(...){ paste(..., sep="")}
  library(acs) # This package isn't (yet) used directly to download ACS data, since it generates pulls using the Census API, and 
    #   only a subset of Census data sets are available through the API. However, it has some useful helper functions to
    #   find codes for tables and geographies
  
  #myLocalUser <- "nmader.CHAPINHALL"
  myLocalUser <- "nmader"
  rootDir <- "C:/Users/nmader/Documents/GitHub/acs-shop-cook-serve/"
  dlDir <- rootDir %&% "data/raw-downloads/"
  setwd(dlDir)

### Define Pulls

  # NSM: we will want to convert this to a function so that users can call on this multiple times for different types of pulls, either with separate years

  pullYear <- "2012"
  pullSpan  <- 1
  pullState <- "Illinois"
  pullCnty  <- c("Cook County", "Will County", "Lake County", "Kane County", "McHenry County", "DuPage County")  ## To avoid potentially non-unique pulls, "County" should be specified here
  pullTract <- "*"
  pullTables <- unlist(strsplit("B01001 B01001A B01001B B01001C B01001D B01001E B01001F B01001G B01001H B01001I B08006 B08008 B08011 B08012 B08013 B15001 B15002 B17001 B12001 B12002 B12006 B17003 B17004 B17005 B19215 B19216 B14004 B14005 B05003 B23001 B23018 B23022 B24012 B24022 B24042 B24080 B24082 B24090 C24010 C24020 C24040 B11001 B11003 B11004 B13002 B13012 B13014 B13016 B17022 B23007 B23008 B25115", split= " "))


  # Look up geography codes using the acs package
    pullSt <- "IL"


### Download and Extract Data

  # For now, this is just a test run using a sample data set
  
  myPathFileName <- dlDir %&% "Illinois_All_Geographies.zip"
  remoteDataName <- paste0("http://www2.census.gov/acs", pullYear, "_", pullSpan, "yr/summaryfile/", pullYear, "_ACSSF_By_State_All_Tables/", pullState, "_All_Geographies.zip")

  Meta <- read.csv(url(paste0("http://www2.census.gov/acs", pullYear, "_", pullSpan, "yr/summaryfile/Sequence_Number_and_Table_Number_Lookup.txt")), header = TRUE)
  download.file(remoteDataName, myPathFileName)
  unzip(zipfile = myPathFileName) # NSM: am having problems explicitly feeding an argument to "exdir" for this function.
                                  # For now, it's using the current working directory as the default
  
### Select Tables and Merge Together

  # Identify the sequence number corresponding to each table that has been specified
    #myMeta <- Meta[Meta$Table.ID %in% pullTables, ]
    Meta$ElemName <- paste0(Meta$Table.ID, "_", Meta$Line.Number)
    seqFile.dict <- list(c("FILEID", "File Identification"),
                         c("FILETYPE", "File Type"),
                         c("STUSAB", "State/U.S.-Abbreviation (USPS)"),
                         c("CHARITER", "Character Iteration"),
                         c("SEQUENCE", "Sequence Number"),
                         c("LOGRECNO", "Logical Record Number"))
    seqFile.idVars <- sapply(seqFile.dict.id, function(m) m[1])

  # Pull those sequence files
    # XXX Should allow choice of E and M--or both--sets of tables
    
    for (t in pullTables) {
      # Compile meta-data related to the table
      t.seqNum <- Meta[Meta$Table.ID == t, "Sequence.Number"][1] # We can take the first element, since all of the returned sequence numbers should be the same
        # t.seqNum_check <- names(table(myMeta[myMeta$Table.ID == t, "Sequence.Number"]))
        # t.seqNum == t.seqNum_check
      t.elemNames       <- Meta$ElemName[Meta$Table.ID        == t        & !is.na(Meta$Line.Number)]
      t.dataLabel        <- Table.Title[  Meta$Table.ID        == t        & !is.na(Meta$Line.Number)]
        t.dataDict     <- cbind(t.elemNames, t.dataLabels)
      seqFile.elemNames <- Meta$ElemName[Meta$Sequence.Number == t.seqNum & !is.na(Meta$Line.Number)]
      mySeqColNames <- c(seqFile.idVars, seqFile.elemNames)
        
      # Identify the proper sequence table and pull the appropriate table columns
      mySeq <- read.csv(paste0(dlDir, "e", pullYear, pullSpan, pullSt, sprintf("%04d", t.seqNum), "000.txt"), header=FALSE)
      colnames(mySeq) <- mySeqColNames
      myTable <- mySeq[, c(seqFile.idVars, t.elemNames) ]
      
      # Compile all requested table information
      if (t == pullTables[1]) {
        myResults <- myTable
        myDataDict <- t.dataDict
      } else {
        myResults <- merge(x=myResults, y=myTable, by=c("FILEID", "FILETYPE", "STUSAB", "LOGRECNO"))
        myDataDict <- rbind(myDataDict, t.dataDict)
      }
    }


# Each of the sequence files has the following left-most identifying fields
#       FILEID  ='File Identification'
#       FILETYPE='File Type'
#       STUSAB  ='State/U.S.-Abbreviation (USPS)'
#       CHARITER='Character Iteration'
#       SEQUENCE='Sequence Number'
#       LOGRECNO='Logical Record Number' # ... looks like the geo file has the right reference for this, which has values 1:270 in field LOGRECNO (same as the data file, except for leading zeroes)

  ### *1* Use the geo file to select among the rows in the sequence tables
  # Need to translate counties to county codes. Either do that or, for now, ask the users to directly input county codes. ... Not sure how this will work when we're looking for data at the sub county level.

  geoLabels <- read.csv(paste0(rootDir, "data/prepped-data/geofile-fields.csv"), header=T) # Note--this file was created by hand from the labels in the SAS version of the data prep file. See ".../scripts/Summary file assembly script from Census.sas"
  geoFile <- read.csv(paste0(dlDir, "g", pullYear, pullSpan, tolower(pullSt), ".csv"), header=F)
  colnames(geoFile) <- geoLabels$geoField
  
  # Figure out which rows correspond to the counties that we want
  
  # Then, subset the myResults file to only these rows

  ### *2* Go back and make this a function



# Note--depending on how much we want to save space, we can delete all tables that were not requested for our use
# Note--the filenaming convention is unique across end-years, aggregations, and sequence numbers.
