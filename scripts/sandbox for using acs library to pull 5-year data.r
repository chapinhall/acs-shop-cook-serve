
# This code is a sandbox to look for ACS data using the "acs" library for R

rm(list=ls())
library(acs)
library(stringr)
try(setwd("C:/Users/nmader/Documents/GitHub/acs-shop-cook-serve/"))

acs.lookup(endyear = 2011, span = 5, dataset = "acs", keyword = c("poverty", "workers"))
acs.lookup(endyear = 2011, span = 5, dataset = "acs", keyword = c("poverty", "force"))

pullSt <- "IL"
pullCounties <- "Cook County"
pullPlace <- "Chicago"
pullYear <- 2011
pullSpan <- 5
pullTables <- c("B17014", "B17005")

keyFile <- read.delim(file = "./key/key.txt", header = F)
myKey <- as.character(keyFile[1,1])
api.key.install(myKey, file = "key.rda")

geo.lookup(state=pullSt, county=pullCounties)
geo.lookup(state=pullSt, county=pullPlace)
myGeo <- geo.make(state = pullSt, county = pullCounties, tract = "*")
acs.lookup(endyear = pullYear, span = pullSpan, dataset = "acs", table.number = c("B17014", "B17005"))
acsPull <- acs.fetch(endyear = 2011, span = 5, geography = myGeo, table.number = "B17014")

acsEst <- acsPull@estimate
acsEst.df <- data.frame(acsEst)
str_locate("abcdbe", "b")
