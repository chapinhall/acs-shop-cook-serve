#########################################################################
#
# DOWNLOAD, EXTRACT, AND SELECT DATA FOR CUSTOM DATA SETS AND GEOGRAPHIES
# Developed by Chapin Hall
# Authors: Nick Mader (nmader@chapinhall.org), ...
#
#########################################################################
library(acs) # This package isn't (yet) used directly to download ACS data, since it generates pulls using the Census API, and 
  #   only a subset of Census data sets are available through the API. However, it has some useful helper functions to
  #   find codes for tables and geographies

getAcs <- function(pullYear, pullSpan, pullState, pullSt, pullCounties, pullTables, dirGeoLab, dirDl, downloadData) {
  
  
  pullYear = 2011; pullSpan = 1; pullState = "Illinois"; pullSt = "IL"; pullCounties = myCounties; pullTables = myTables; dirGeoLab = dirSave; dirDl = dirDl; downloadData = TRUE
  
  print(paste0("Downloading and extracting ACS ", pullYear, " ", pullSpan, " year data for ", "state =  ", pullState, " and Counties = ", paste(pullCounties, collapse = ", ")))
  CountyLookup <- geo.lookup(state=pullSt, county=pullCounties)
  pullCountyCodes <- CountyLookup$county[!is.na(CountyLookup$county)]

#----------------------------
### Download and Extract Data
#----------------------------
  
  # Get metadata
  if (myYear >= 2010) {
    metaPath <- paste0("acs", pullYear, "_", pullSpan, "yr/summaryfile/Sequence_Number_and_Table_Number_Lookup.txt")
    dataPath <- paste0("acs", pullYear, "_", pullSpan, "yr/summaryfile/", pullYear, "_ACSSF_By_State_All_Tables/", pullState, "_All_Geographies.zip")
    geoFileExt <- "csv"
  } else if (myYear == 2009) {
    metaPath <- paste0("acs", pullYear, "_", pullSpan, "yr/summaryfile/UserTools/merge_5_6.txt")
    dataPath <- paste0("acs", pullYear, "_", pullSpan, "yr/summaryfile/Entire_States/Illinois.zip")
    geoFileExt <- "csv"
  } else if (myYear == 2008) {
    metaPath <- paste0("acs", pullYear, "_", pullSpan, "yr/summaryfile/merge_5_6.xls")
    dataPath <- paste0("acs", pullYear, "_", pullSpan, "yr/summaryfile/Illinois/")
    geoFileExt <- "txt"
  } else if (myYear == 2007) {
    metaPath <- paste0("acs", pullYear, "_", pullSpan, "yr/summaryfile/merge_5_6_final.xls")
    dataPath <- paste0("acs", pullYear, "_", pullSpan, "yr/summaryfile/Illinois/")
    geoFileExt <- "txt"
  } else if (myYear == 2006) {
    metaPath <- paste0("acs", pullYear, "/summaryfile/merge_5_6_final.xls")
    metaPath <- paste0("acs", pullYear, "/summaryfile/Illinois/")
    geoFileExt <- "txt"
  }
  
  Meta <- read.csv(url(paste0("http://www2.census.gov/", metaPath)), header = TRUE)

  # Get geodata
  geoLabels <- read.csv(paste0(dirGeoLab, "/geofile-fields.csv"), header=T)
    # created by hand from documentation
  geoFile <- read.csv(paste0(dirDl, "/g", pullYear, pullSpan, tolower(pullSt), ".csv"), header=F)
  colnames(geoFile) <- geoLabels$geoField
  
  # Get data
  myFileName <- paste0("/ACS_", pullYear, "_", pullSpan, "Year_", pullSt, ".zip")
  myPathFileName <- paste0(dirDl, myFileName)
  remoteDataName <- paste0("http://www2.census.gov/", remotePath)
  if (downloadData == TRUE & !file.exists(myPathFileName)) {
    print(paste0("Downloading data: ", myFileName))
    download.file(remoteDataName, myPathFileName)
    unzip(zipfile = myPathFileName)
      # NSM: am having problems explicitly feeding an argument to "exdir" for this function.
      # For now, it's using the current working directory as the default
  }

#----------------------------
### Set Up Metadata for Files
#----------------------------

  # Identify the sequence number corresponding to each table that has been specified
    Meta$elemName <- paste0(Meta$Table.ID, "_", Meta$Line.Number)
  # Subset the metafile to only information pertaining to table columns
    myMeta <- Meta[!is.na(Meta$Line.Number) & Meta$Line.Number %% 1 == 0, ]; rm(Meta)

    myLogRecNos <- geoFile$LOGRECNO[geoFile$COUNTY %in% pullCountyCodes & geoFile$SUMLEVEL == 50]
      # XXX Implicitly only allows draws of county data. Need to update this.

    seqFile.dict <- list(c("FILEID", "File Identification"),
                         c("FILETYPE", "File Type"),
                         c("STUSAB", "State/U.S.-Abbreviation (USPS)"),
                         c("CHARITER", "Character Iteration"),
                         c("SEQUENCE", "Sequence Number"),
                         c("LOGRECNO", "Logical Record Number"))
    seqFile.idVars <- sapply(seqFile.dict, function(m) m[1])
    seqFile.mergeVars <- c("FILEID", "FILETYPE", "STUSAB", "LOGRECNO")

#-----------------------------------
### Select Tables and Merge Together
#-----------------------------------

    for (t in pullTables) {
      
      # Identify the sequence file we need to open
        t.seqNum <- myMeta[myMeta$Table.ID == t, "Sequence.Number"][1]
          # We can take the first element, since all of the returned sequence numbers
          # should be the same
      
      # Get meta data on the sequence file
        seqFile.elemNames <- myMeta$elemName[myMeta$Sequence.Number == t.seqNum]
        mySeqColNames <- c(seqFile.idVars, seqFile.elemNames)
      
      # Get meta data on the table we'll draw from the sequence file
        t.elemNames <- myMeta$elemName[myMeta$Table.ID == t]
        t.meta <- acs.lookup(endyear = 2011, span = pullSpan, dataset = "acs", table.name = t)
          # using year 2011 since the ACS package hasn't been updated to expect 2012
          # and throws an error. 2011 gets us the same results in terms of table information.
        t.dataLabels <- t.meta@results$variable.name[t.meta@results$table.number == t]
          # Note: need to ensure subsetting to exactly rows equal to t since acs.lookup returns
          # all table matches to the search. Thus, it returns meta data for "B01001A" when searching
          # for "B01001".
        t.dataDict <- cbind(t.elemNames, t.dataLabels)
              
      # Open the sequence file and apply headers
        mySeq <- read.csv(paste0(dirDl, "/e", pullYear, pullSpan, pullSt, sprintf("%04d", t.seqNum), "000.txt"), header=FALSE)
        print("    Working on table " %&% t)
        colnames(mySeq) <- mySeqColNames
      
      # Pull the tables and geographies of interest
        myTable <- mySeq[mySeq$LOGRECNO %in% myLogRecNos, c(seqFile.mergeVars, t.elemNames) ]
        
      # Compile all requested table information
        if (t == pullTables[1]) {
          myResults <- myTable
          myDataDict <- t.dataDict
        } else {
          myResults <- merge(x=myResults, y=myTable, by=c("FILEID", "FILETYPE", "STUSAB", "LOGRECNO"))
          myDataDict <- rbind(myDataDict, t.dataDict)
        }
    }

  myResults$County <- pullCounties
  colnames(myDataDict) <- c("Table Element", "Element Label")

  return(list(myResults, myDataDict))

}

