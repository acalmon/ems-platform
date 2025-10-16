################################################################################
# Uber Movement Data Consolidation Script
################################################################################
#
# Purpose:
#   Consolidates 32 quarterly Uber Movement CSV files (2016-2020) into a single
#   dataset containing the most recent travel time measurement for each
#   source-destination pair.
#
# Input:
#   - 32 CSV files in Nairobi_Uber_Data/ directory
#   - Format: nairobi-hexclusters-YEAR-QUARTER-OnlyDayType-MonthlyAggregate.csv
#   - Each file: sourceid, dstid, month, mean_travel_time, std dev, etc.
#
# Output:
#   - Uber-Nairobi-Weekdays.csv OR Uber-Nairobi-Weekends.csv
#   - Contains most recent monthly data for each unique O-D pair
#   - Typical output: ~67,000 rows (from ~960,000 total input rows)
#
# Key Algorithm:
#   For each source-destination pair, keeps ONLY the most recent month's data
#   across all quarterly files. This handles overlapping quarters and ensures
#   the analysis uses the latest available traffic measurements.
#
# Author: [Research Team]
# Date: [Original Date]
# Last Modified: October 2025 (added documentation)
################################################################################

library(tidyverse)  # For data manipulation (dplyr, tibble)
library(lubridate)  # For date parsing and handling

# Set working directory to Uber Movement data location
# NOTE: Update this path to match your local directory structure
dir = "~/Dropbox (Personal)/Georgia Tech Research/Flare/Data Uber/Data"

setwd(dir)

# Get list of all CSV files in the directory
files = list.files(path=dir, pattern="*.csv", full.names=TRUE, recursive=FALSE)

# ============================================================================
# IMPORTANT: Set day type to process
# Options: "Weekdays" or "Weekends"
# ============================================================================
typeOfDay = "Weekends"  # CHANGE HERE FOR weekdays/weekends

# Filter files to only those matching the selected day type
# e.g., only process "OnlyWeekdays" or "OnlyWeekends" files
filesUsed = files[grepl(typeOfDay, files)]

# Regular expression to extract year from filename
regexp <- "[[:digit:]]+"

# Initialize empty tibble to store consolidated results
dfRecent = tibble()

# ============================================================================
# Main Processing Loop: Iterate through all quarterly files
# ============================================================================
for(f in filesUsed){

  # Extract year from filename (e.g., "2016" from "nairobi-hexclusters-2016-...")
  year = as.numeric(str_extract(f, regexp))

  # Read the CSV file
  df = read_csv(f)

  # Add temporal metadata
  # Note: Setting day to 1st of month for consistency
  df$year = year
  df$date = my(paste(df$month, df$year, sep = "-"))  # Parse as "MM-YYYY" format

  # -------------------------------------------------------------------------
  # STEP 1: Within this file, keep only the most recent month for each O-D pair
  # -------------------------------------------------------------------------
  # Why: Some quarterly files may contain multiple months of data
  # This ensures we only keep the latest month from THIS file
  dfRecentTemp = df %>%
    group_by(sourceid, dstid) %>%
    filter(date == max(date)) %>%
    ungroup()

  # -------------------------------------------------------------------------
  # STEP 2: Merge with previously processed files
  # -------------------------------------------------------------------------
  dfRecent = rbind(dfRecent, dfRecentTemp)

  # -------------------------------------------------------------------------
  # STEP 3: Across ALL files processed so far, keep most recent for each O-D pair
  # -------------------------------------------------------------------------
  # Why: As we process files sequentially, newer quarters may have more recent
  # data for the same O-D pairs. This ensures we always keep the latest.
  dfRecent = dfRecent %>%
    group_by(sourceid, dstid) %>%
    filter(date == max(date)) %>%
    ungroup()

}

# ============================================================================
# Write consolidated output
# ============================================================================
outName = paste("Uber-Nairobi-", typeOfDay, ".csv", sep = "")
write_csv(dfRecent, outName)

# Expected output: ~67,000 rows for Weekdays, similar for Weekends
# Each row = most recent monthly average for that source-destination pair
  
  
