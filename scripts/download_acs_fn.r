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

getAcs <- function(pullYear, pullSpan, pullState, pullSt, pullCounties, pullTables, dlDir, downloadData) {

  CountyLookup <- geo.lookup(state=pullSt, county=pullCounties)
  pullCountyCodes <- CountyLookup$county[!is.na(CountyLookup$county)]

#----------------------------
### Download and Extract Data
#----------------------------
  
  # Get metadata
  Meta <- read.csv(url(paste0("http://www2.census.gov/acs", pullYear, "_", pullSpan, "yr/summaryfile/Sequence_Number_and_Table_Number_Lookup.txt")), header = TRUE)
  
  # Get geodata
  geoLabels <- read.csv(paste0(rootDir, "data/prepped-data/geofile-fields.csv"), header=T) # created by hand from documentation
  geoFile <- read.csv(paste0(dlDir, "g", pullYear, pullSpan, tolower(pullSt), ".csv"), header=F)
  colnames(geoFile) <- geoLabels$geoField
  
  # Get data
  myPathFileName <- paste0(dlDir, "ACS_", pullYear, "_", pullSpan, "Year_", pullSt, ".zip")
  remoteDataName <- paste0("http://www2.census.gov/acs", pullYear, "_", pullSpan, "yr/summaryfile/", pullYear, "_ACSSF_By_State_All_Tables/", pullState, "_All_Geographies.zip")
  if (downloadData == TRUE & !file.exists(myPathFileName)) {
    download.file(remoteDataName, myPathFileName)
    unzip(zipfile = myPathFileName) # NSM: am having problems explicitly feeding an argument to "exdir" for this function.
                                    # For now, it's using the current working directory as the default
  }

#----------------------------
### Set Up Metadata for Files
#----------------------------

  # Identify the sequence number corresponding to each table that has been specified
    Meta$elemName <- paste0(Meta$Table.ID, "_", Meta$Line.Number)
  # Subset the metafile to only information pertaining to table columns
    myMeta <- Meta[!is.na(Meta$Line.Number) & Meta$Line.Number %% 1 == 0, ]; rm(Meta)

    myLogRecNos <- geoFile$LOGRECNO[geoFile$COUNTY %in% pullCountyCodes & geoFile$SUMLEVEL == 50] # XXX Implicitly only allows draws of county data. Need to update this.

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
        t.seqNum <- myMeta[myMeta$Table.ID == t, "Sequence.Number"][1] # We can take the first element, since all of the returned sequence numbers should be the same
      
      # Get meta data on the sequence file
        seqFile.elemNames <- myMeta$ElemName[myMeta$Sequence.Number == t.seqNum]
        mySeqColNames <- c(seqFile.idVars, seqFile.elemNames)
      
      # Get meta data on the table we'll draw from the sequence file
        t.elemNames <- myMeta$elemName[myMeta$Table.ID == t]
        t.meta <- acs.lookup(endyear = 2011, span = pullSpan, dataset = "acs", table.name = t)
          # using year 2011 since the ACS package hasn't been updated to expect 2012 and throws an error. 2011 gets us the same results in terms of table information.
        t.dataLabels <- t.meta@results$variable.name
        t.dataDict <- cbind(t.elemNames, t.dataLabels)
              
      # Open the sequence file and apply headers
        mySeq <- read.csv(paste0(dlDir, "e", pullYear, pullSpan, pullSt, sprintf("%04d", t.seqNum), "000.txt"), header=FALSE)
        #print("Working on table " %&% t)
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

  rownames(myResults) <- pullCounty

  return(list(myResults, myDataDict))

}

