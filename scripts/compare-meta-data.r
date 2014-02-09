#------------------------------------------------------------------------------
#
# Identify extent of overlap in surveys across different years
#
#------------------------------------------------------------------------------

# Set up workspace

  rm(list=ls())
  "%&%" <- function(...){ paste0(...)}

  try(setwd("/home/nick/GitHub/acs-shop-cook-serve"), silent = T)
  try(setwd("C:/Users/nmader/Documents/GitHub/acs-shop-cook-serve"), silent = T)
  dirRoot <- getwd()
  dirMeta    <- dirRoot %&% "/data/prepped-data/"

# Load metafiles

  #loadFiles <- paste0(dirMeta, "MetaFile_ACS_", 2007:2012, "_1Year.csv")
  for (y in as.character(2007:2012)) {
    myObj <- read.csv(paste0(dirMeta, "MetaFile_ACS_", y, "_1Year.csv"), header=T)
    myObj <- myObj[!is.na(myObj$Start.Position)
                   & myObj$Start.Position != "."
                   & myObj$Start.Position != 0, c("Table.ID", "Table.Title")] #
    colnames(myObj) <- c("Table.ID", paste0("Table.Title_", y))
    myObj[, paste0("In", y)] <- 1
    assign(paste0("m", y), myObj)
  }
#View(m2010[m2010$Table.ID=="B05002",]) ... This is towards examining why there are multiple copies of certain tables represented in the meta data

# Merge and output
  mergedMeta <- m2007
  for (y in as.character(2008:2012)) {
    mergedMeta <- merge(x=mergedMeta, y=get(paste0("m", y)), by = "Table.ID", all = T)
  }
  write.csv(mergedMeta, file = paste0(dirMeta, "MergedMetaFiles.csv"))
