#---------------------------------------------------------------------------
## This code is a sandbox to look for ACS data using the "acs" library for R
## Author: Nick Mader <nmader@chapinhall.org>
#---------------------------------------------------------------------------

# Set up workspace
  rm(list=ls())
  library(acs)
  library(stringr)
  try(setwd("C:/Users/nmader/Documents/GitHub/acs-shop-cook-serve/"))

# Instantiate key for using Census API. It will be necessary to 
keyFile <- read.delim(file = "./key/key.txt", header = F)
myKey <- as.character(keyFile[1,1])
api.key.install(myKey, file = "key.rda")

# Example searchers for keywords
  acs.lookup(endyear = 2011, span = 5, dataset = "acs", keyword = c("poverty", "workers"))
  acs.lookup(endyear = 2011, span = 5, dataset = "acs", keyword = c("poverty", "force"))

# Defining our pull
  pullSt <- "IL"
  pullCounties <- "Cook County"
  pullPlace <- "Chicago"
  pullYear <- 2011
  pullSpan <- 5
  pullTables <- c("B17014", "B17005")


geo.lookup(state=pullSt, county=pullCounties)
geo.lookup(state=pullSt, county=pullPlace)
myGeo <- geo.make(state = pullSt, county = pullCounties, tract = "*")
acs.lookup(endyear = pullYear, span = pullSpan, dataset = "acs", table.number = c("ABCD"))
  # XXX Doesn't seem to like multiple arguments to table.number. May be because 
acsPull <- acs.fetch(endyear = 2011, span = 5, geography = myGeo, table.number = "B17014")

acsEst <- acsPull@estimate
acsEst.df <- data.frame(acsEst)
tract <- sapply(rownames(acsEst.df), function(x) substr(x, 14, str_locate(x, ",")[1] - 1))
  # 14 is the first character of the tract number in the row names. Before that is "Census Tract " which is length 13.
acsEst.df$tract <- as.numeric(tract)*100
rownames(acsEst.df) <- NULL
  



