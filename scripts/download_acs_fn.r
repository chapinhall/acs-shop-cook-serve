#########################################################################
#
# DOWNLOAD, EXTRACT, AND SELECT DATA FOR CUSTOM DATA SETS AND GEOGRAPHIES
# Developed by Chapin Hall
# Authors: Nick Mader (nmader@chapinhall.org), ...
#
#########################################################################

getAcs <- function(pullYear, pullSpan, pullState, pullSt, pullCounties, pullTables, dirGeoLab, dirDl, downloadData) {

  #Test code for if we want to run within this function
  pullYear = 2012; pullSpan = 1; pullState = "Illinois"; pullSt = "IL"; pullCounties = myCounties; pullTables = "B19215"; dirGeoLab = dirSave; dirDl = dirDl; downloadData = TRUE # myTables
  
  print(paste0("Downloading and extracting ACS ", pullYear, " ", pullSpan, " year data for ", "state =  ", pullState, " and Counties = ", paste(pullCounties, collapse = ", ")))
  CountyLookup <- geo.lookup(state=pullSt, county=pullCounties)
  pullCountyCodes <- CountyLookup$county[!is.na(CountyLookup$county)]

#----------------------------
### Download and Extract Data
#----------------------------
  
  # Get metadata
  if (pullYear >= 2010) {
    metaPath   <- paste0("acs", pullYear, "_", pullSpan, "yr/summaryfile/Sequence_Number_and_Table_Number_Lookup.txt")
    remoteData <- paste0("acs", pullYear, "_", pullSpan, "yr/summaryfile/", pullYear, "_ACSSF_By_State_All_Tables/", pullState, "_All_Geographies.zip")
    geoFileExt <- "csv"
  } else if (pullYear == 2009) {
    metaPath   <- paste0("acs", pullYear, "_", pullSpan, "yr/summaryfile/UserTools/merge_5_6.txt")
    remoteData <- paste0("acs", pullYear, "_", pullSpan, "yr/summaryfile/Entire_States/Illinois.zip")
    geoFileExt <- "txt"
  } else if (pullYear == 2008) {
    metaPath   <- paste0("acs", pullYear, "_", pullSpan, "yr/summaryfile/merge_5_6.xls")
    remoteData <- paste0("acs", pullYear, "_", pullSpan, "yr/summaryfile/Illinois/")
    geoFileExt <- "txt"
  } else if (pullYear == 2007) {
    metaPath   <- paste0("acs", pullYear, "_", pullSpan, "yr/summaryfile/merge_5_6_final.xls")
    remoteData <- paste0("acs", pullYear, "_", pullSpan, "yr/summaryfile/Illinois/")
    geoFileExt <- "txt"
  } else if (pullYear == 2006) {
    metaPath   <- paste0("acs", pullYear, "/summaryfile/merge_5_6_final.xls")
    remoteData <- paste0("acs", pullYear, "/summaryfile/Illinois/")
    geoFileExt <- "txt"
  }
  
  metaExt <- substr(metaPath, nchar(metaPath) - 2, nchar(metaPath))
  if (metaExt == "txt") {
    # XXX Instead of downloading Metafiles every time, should save them to file, and check if we've previously
    # saved them
    Meta <- read.csv(url(paste0("http://www2.census.gov/", metaPath)), header = TRUE)
  } else if (metaExt == "xls") {
    Meta <- read.xls(paste0("http://www2.census.gov/", metaPath))
  }
  colnames(Meta) <- c("File.ID", "Table.ID", "Sequence.Number", "Line.Number", "Start.Position", "Total.Cells.in.Table", "Total.Cells.in.Sequence", "Table.Title", "Subject.Area")

  # Get data
  myFileName <- paste0("/ACS_", pullYear, "_", pullSpan, "Year_", pullSt, ".zip")
  myPathFileName <- paste0(dirDl, myFileName)
  remoteDataName <- paste0("http://www2.census.gov/", remoteData)
  if (downloadData == TRUE & !file.exists(myPathFileName)) {
    print(paste0("Downloading data: ", myFileName, " from remoteDataName"))
    download.file(remoteDataName, myPathFileName)
    unzip(zipfile = myPathFileName)
      # NSM: am having problems explicitly feeding an argument to "exdir" for this function.
      # For now, it's using the current working directory as the default
  }
  
  # Get geodata  
  geoLabels <- read.csv(paste0(dirGeoLab, "/geofile-fields.csv"), header=T)
  # created by hand from documentation
  if (geoFileExt == "csv") {
    geoFile <- read.csv(paste0(dirDl, "/g", pullYear, pullSpan, tolower(pullSt), ".", geoFileExt), header=F)
  } else if (geoFileExt == "txt") {
    geoFields <- read.csv(paste0(dirGeoLab, "/geofile-fields-", pullYear, ".csv"), header=T)
    geoFile <- read.fwf(file = paste0(dirDl, "/g", pullYear, pullSpan, tolower(pullSt), ".", geoFileExt), 
                        widths = geoFields$Widths,
                        col.names = geoFields$Col.Names)
    #geoFile <- read.delim(paste0(dirDl, "/g", pullYear, pullSpan, tolower(pullSt), ".", geoFileExt), header=F)
  }
  colnames(geoFile) <- geoLabels$geoField
  

#----------------------------
### Set Up Metadata for Files
#----------------------------

  # Identify the sequence number corresponding to each table that has been specified
    if (is.factor(Meta$Line.Number)) {
      Meta$Line.Number <- as.numeric(levels(Meta$Line.Number)[Meta$Line.Number])
    } 
      # Convert Line.Number from a factor to numeric, using the levels of the factor. (The reason that Line.Number comes in as a factor is because it has non-numeric values, and read.csv handles this by creating a factor.)
    Meta$elemName <- paste0(Meta$Table.ID, "_", Meta$Line.Number)
  # Subset the metafile to only information pertaining to table columns
    myMeta <- Meta[!is.na(Meta$Line.Number) & Meta$Line.Number %% 1 == 0, ]; # rm(Meta)

    myLogRecNos <- geoFile$LOGRECNO[geoFile$COUNTY %in% pullCountyCodes & geoFile$SUMLEVEL == 50]
      # XXX Implicitly only allows draws of county data. Need to update this when going to other geographies
      # To generalize this, should add arguments for the function to specify state, county, and tract (should
      # check on whether there's more geographic nesting). Can build subsetting statement and summary level 
      # based off of arguments that are given.

    seqFile.dict <- list(c("FILEID",   "File Identification"),
                         c("FILETYPE", "File Type"),
                         c("STUSAB",   "State/U.S.-Abbreviation (USPS)"),
                         c("CHARITER", "Character Iteration"),
                         c("SEQUENCE", "Sequence Number"),
                         c("LOGRECNO", "Logical Record Number"))
    seqFile.idVars <- sapply(seqFile.dict, function(m) m[1])
    seqFile.mergeVars <- c("FILEID", "FILETYPE", "STUSAB", "LOGRECNO")

#-----------------------------------
### Select Tables and Merge Together
#-----------------------------------

    for (t in pullTables) {
      
      print("    Extracting table " %&% t)
      
      # Identify the sequence file we need to open
        t.seqNum <- myMeta[myMeta$Table.ID == t, "Sequence.Number"][1]
          # We can take the first element, since all of the returned sequence numbers
          # should be the same
      
      # Get meta data on the sequence file
        seqFile.elemNames <- myMeta$elemName[myMeta$Sequence.Number == t.seqNum]
        mySeqColNames <- c(seqFile.idVars, seqFile.elemNames)
      
      # Get meta data on the table we'll draw from the sequence file
        t.elemNames <- myMeta$elemName[myMeta$Table.ID == t]
        t.meta <- acs.lookup(endyear = pullYear, span = pullSpan, dataset = "acs", table.name = t)
          # Through some testing, acs.lookup() will return results for any input endyear (using span)
      
          # For future use of this, note that the Census API only works for subsets of years, although I believe
          # that the table lookups should be the same across different spans
        t.dataLabels <- t.meta@results$variable.name[t.meta@results$table.number == t]
          # Note: need to ensure subsetting to exactly rows equal to t since acs.lookup returns
          # all table matches to the search. Thus, it returns meta data for "B01001A" when searching
          # for "B01001".
        if (length(t.elemNames) == length(t.dataLabels)) {
          useLabels <- t.dataLabels
        } else {
          useLabels <- "Error with sourcing table element labels from acs.lookup function"
          print(paste0("Mismatch between length of ", t, "'s elements for ", pullSpan, " yr data, with end year ", pullYear, ", and labels from acs.lookup() function"))
        }
        t.dataDict <- cbind(t.elemNames, useLabels)
              
      # Open the sequence file and apply headers
        mySeq <- read.csv(paste0(dirDl, "/e", pullYear, pullSpan, tolower(pullSt), sprintf("%04d", t.seqNum), "000.txt"), header=FALSE)
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
        #print(paste0("        Completed running ", t))
    }

  myResults$County <- pullCounties
  colnames(myDataDict) <- c("Table Element", "Element Label")

  return(list(myResults, myDataDict))

}

