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


getAcs <- function(pullYear, pullSpan, pullState, pullSt, pullCounties, pullTables) {

  CountyLookup <- geo.lookup(state=pullSt, county=pullCounties)
  pullCountyCodes <- CountyLookup$county[!is.na(CountyLookup$county)]

#----------------------------
### Download and Extract Data
#----------------------------
  
  myPathFileName <- dlDir %&% "Illinois_All_Geographies.zip"
  remoteDataName <- paste0("http://www2.census.gov/acs", pullYear, "_", pullSpan, "yr/summaryfile/", pullYear, "_ACSSF_By_State_All_Tables/", pullState, "_All_Geographies.zip")

  Meta <- read.csv(url(paste0("http://www2.census.gov/acs", pullYear, "_", pullSpan, "yr/summaryfile/Sequence_Number_and_Table_Number_Lookup.txt")), header = TRUE)
  if (downloadData == TRUE) {
    download.file(remoteDataName, myPathFileName)
    unzip(zipfile = myPathFileName) # NSM: am having problems explicitly feeding an argument to "exdir" for this function.
                                    # For now, it's using the current working directory as the default
  }

#----------------------------
### Set Up Metadata for Files
#----------------------------

  # Identify the sequence number corresponding to each table that has been specified
    #myMeta <- Meta[Meta$Table.ID %in% pullTables, ]
    Meta$ElemName <- paste0(Meta$Table.ID, "_", Meta$Line.Number)
    myMeta <- Meta[!is.na(Meta$Line.Number) & Meta$Line.Number %% 1 == 0, ]; rm(Meta)

    geoLabels <- read.csv(paste0(rootDir, "data/prepped-data/geofile-fields.csv"), header=T)
    # Note--this file was created by hand from the labels in the SAS version of the data prep file. See ".../scripts/Summary file assembly script from Census.sas"
    geoFile <- read.csv(paste0(dlDir, "g", pullYear, pullSpan, tolower(pullSt), ".csv"), header=F)
    colnames(geoFile) <- geoLabels$geoField
    myLogRecNos <- geoFile$LOGRECNO[geoFile$COUNTY %in% pullCountyCodes & geoFile$SUMLEVEL == 50]
    # Note -- summary level 50 corresponds to county-level summary. See Appendix F of the ACS 1-year summary document for a full list of summary levels and components.

    seqFile.dict <- list(c("FILEID", "File Identification"),
                         c("FILETYPE", "File Type"),
                         c("STUSAB", "State/U.S.-Abbreviation (USPS)"),
                         c("CHARITER", "Character Iteration"),
                         c("SEQUENCE", "Sequence Number"),
                         c("LOGRECNO", "Logical Record Number"))
    seqFile.idVars <- sapply(seqFile.dict, function(m) m[1])
    seqFile.mergeVars <- c("FILEID", "FILETYPE", "STUSAB", "LOGRECNO")

  # Pull those sequence files

#-----------------------------------
### Select Tables and Merge Together
#-----------------------------------

    for (t in pullTables) {
      # Compile meta-data related to the table
      t.seqNum <- myMeta[myMeta$Table.ID == t, "Sequence.Number"][1] # We can take the first element, since all of the returned sequence numbers should be the same
        # t.seqNum_check <- names(table(myMeta[myMeta$Table.ID == t, "Sequence.Number"]))
        # t.seqNum == t.seqNum_check
      seqFile.elemNames <- myMeta$ElemName[   myMeta$Sequence.Number == t.seqNum]
      t.elemNames       <- myMeta$ElemName[   myMeta$Table.ID        == t       ]
      #t.dataLabels      <- myMeta$Table.Title[myMeta$Table.ID        == t       ] # ... This isn't working well since the hierarchy of table element labels is not easy to reconstruct.
      tableMeta <- acs.lookup(endyear = 2011, span = pullSpan, dataset = "acs", table.name = t) # using year 2011 since the ACS package hasn't been updated to expect 2012 and throws an error. 2011 gets us the same results in terms of table information.
      t.dataLabels <- tableMeta@results$variable.name
      mySeqColNames <- c(seqFile.idVars, seqFile.elemNames)
      t.dataDict    <- cbind(t.elemNames, t.dataLabels)
        
      # Identify the proper sequence table and pull the appropriate table columns
      mySeq <- read.csv(paste0(dlDir, "e", pullYear, pullSpan, pullSt, sprintf("%04d", t.seqNum), "000.txt"), header=FALSE)
      print("Working on table " %&% t)
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

  return(myResults)

}

