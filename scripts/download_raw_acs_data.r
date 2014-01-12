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
  pullCtny  <- c("Cook County", "Will County", "Lake County", "Kane County", "McHenry County", "DuPage County")  ## To avoid potentially non-unique pulls, "County" should be specified here
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
      t.seqNum <- myMeta[myMeta$Table.ID == t, "Sequence.Number"][1] # We can take the first element, since all of the returned sequence numbers should be the same
        # t.seqNum_check <- names(table(myMeta[myMeta$Table.ID == t, "Sequence.Number"]))
        # t.seqNum == t.seqNum_check
      t.elemNames       <- Meta$ElemName[Meta$Table.ID        == t        & !is.na(Meta$Line.Number)]
      seqFile.elemNames <- Meta$ElemName[Meta$Sequence.Number == t.seqNum & !is.na(Meta$Line.Number)]
      mySeqColNames <- c(seqFile.idVars, seqFile.elemNames)
        
      # Identify the proper sequence table and pull the appropriate table columns
      mySeq <- read.csv(paste0(dlDir, "e", pullYear, pullSpan, pullSt, sprintf("%04d", t.seqNum), "000.txt"), header=FALSE)
      colnames(mySeq) <- mySeqColNames
      myTable <- mySeq[, c(seqFile.idVars, t.elemNames) ]
      
      # Compile all requested table information
      if (t == pullTables[1]) {
        myResults <- myTable
      } else {
        myResults <- merge(x=myResults, y=myTable, by=seqFile.idVars)
      }
    }
getTable("B17004")

  # Generate headers for the files based on standard fields, and additional fields based on meta-data

    # Based on the read files from SAS, the standard set of fields includes--
#       FILEID  ='File Identification'
#       FILETYPE='File Type'
#       STUSAB  ='State/U.S.-Abbreviation (USPS)'
#       CHARITER='Character Iteration'
#       SEQUENCE='Sequence Number'
#       LOGRECNO='Logical Record Number' # ... looks like the geo file has the right reference for this, which has values 1:270 in field LOGRECNO (same as the data file, except for leading zeroes)
#       ... In the file for sequence number 31 there are 36 values. The metafile shows 30 non-NA values in the "Line.Number" field, and there are 6 standard variables.
#       .... The problem is that metadatafile has information on *many* tables! I'd expected this to be unique! Perhaps it didn't read in properly?
#       .... Nevermind! There really is data on multiple tables in each sequence table. What the hell?
#       ... the "Start.Position" is the cue for the starting column (rather than character) of the table in question.
#       ... There are large gaps in the tables which, in the data that I've downloaded, correspond to the lack of data on Puerto Rico

  # Horizontally merge the files

  # Use the geo file to select among the rows in the sequence tables


  geoLabels <- read.csv(paste0(rootDir, "data/prepped-data/geofile-fields.csv"), header=T) # Note--this file was created by hand from the labels in the SAS version of the data prep file. See ".../scripts/Summary file assembly script from Census.sas"
  geoFile <- read.csv(paste0(dlDir, "g", pullYear, pullSpan, tolower(pullSt), ".csv"), header=F)
  colnames(geoFile) <- geoLabels$geoField

  # ... what is the particular syntax of sequence tables?
  # A good way to add leading 0s is sprintf, e.g.: sprintf("%010d", 104)

  a <- read.csv(paste0(dlDir, "e20121il0001000.txt"), header=F)
  g <- read.csv(paste0(dlDir, "g20121il.csv"), header=F)



# NSM: the tables come out in 178 separate files, where each in this 178 sequence is one of the summary file tables. The contents of each of those files
#   can be found in this table: http://www2.census.gov/acs2012_1yr/summaryfile/Sequence_Number_and_Table_Number_Lookup.txt.
# My current thought for the best way to import the data is to loop through each of the sequence tables, name, transpose or horizontally append them, and then aggregate them
# A complementary/alternative step would be to try to adapt the SAS code that is provided under the UserTools folder -- http://www2.census.gov/acs2012_1yr/summaryfile/UserTools/SF_All_Macro.sas

# Note--depending on how much we want to save space, we can delete all tables that were not requested for our use
# Note--the filenaming convention is unique across end-years, aggregations, and sequence numbers.
