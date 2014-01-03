dlDir <- "/researchdata/acs/raw_downloads/"
setwd("/researchdata/acs/raw_downloads")

myFile <- paste(dlDir, "Illinois_All_Geographis.zip", sep="")

download.file("http://www2.census.gov/acs2012_1yr/summaryfile/2012_ACSSF_By_State_All_Tables/Illinois_All_Geographies.zip", myFile)
# myFileUnz <- unz("TestFile", myFile) ... NSM: not sure how to run this properly. The zip file expands in to 2*178 different tables. These will need to be expanded and then assembled separately.

# NSM: the tables come out in 178 separate files, where each in this 178 sequence is one of the summary file tables. The contents of each of those files
#   can be found in this table: http://www2.census.gov/acs2012_1yr/summaryfile/Sequence_Number_and_Table_Number_Lookup.txt.
# My current thought for the best way to import the data is to loop through each of the sequence tables, name, transpose or horizontally append them, and then aggregate them
# A complementary/alternative step would be to try to adapt the SAS code that is provided under the UserTools folder -- http://www2.census.gov/acs2012_1yr/summaryfile/UserTools/SF_All_Macro.sas

# Note--depending on how much we want to save space, we can delete all tables that were not requested for our use
# Note--the filenaming convention is unique across end-years, aggregations, and sequence numbers.
