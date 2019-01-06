library(zoo)
library(WDI)
library(readxl)
library(testthat)
library(janitor)
library(countrycode)
library(tidyverse)
options(stringsAsFactors = FALSE)

read_csv_last = function(stem = 'data_clean/claims_') {
    files = Sys.glob(paste0(stem, '*'))
    f = files[length(files)] # most recent (sorted by date)
    out = read.csv(f)
    return(out)
}
