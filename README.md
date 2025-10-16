# Emergency Medical Services Platform Optimization - Nairobi Case Study

**Research Paper:** "The Value of Time- and Location-Commitment for Decentralized Emergency Medical Services"
**Journal:** Working Paper
**Authors:** van den Berg, Calmon, Gernert, Lemmens, Rabinovich, Romero

## Overview

This repository contains the data processing pipeline and simulation code supporting the research on decentralized emergency medical services (EMS) platforms in Nairobi, Kenya. The study investigates the relative effectiveness of improving temporal versus spatial commitment in ambulance fleet coordination for better service coverage.

**Key Finding:** The coverage provided by ~340 loosely committed ambulances could potentially be matched by fewer than 15 optimally deployed, fully committed units - demonstrating the significant "cost of decentralization."

## Data Sources

### 1. Uber Movement Travel Time Data (2016-2020)

**Source:** Uber Movement Platform (now discontinued)
**Location:** Nairobi, Kenya
**Temporal Coverage:** 2016-Q1 through 2020-Q1 (32 quarterly datasets)
**Spatial System:** H3 Hexagonal Hierarchical Geospatial Index
**Resolution:** 400 hexagonal zones (hexclusters) covering Nairobi metropolitan area
**Zone Size:** Average ~2.94 km² per hexcluster

#### Data Description
The Uber Movement dataset provides aggregated travel time statistics between geographic zones based on actual Uber ride GPS traces. Each dataset includes:
- `sourceid`: Origin hexcluster ID
- `dstid`: Destination hexcluster ID
- `month`: Month within the quarter
- `mean_travel_time`: Average travel time in seconds
- `standard_deviation_travel_time`: Standard deviation of travel time in seconds
- `geometric_mean_travel_time`: Geometric mean of travel time
- `geometric_standard_deviation_travel_time`: Geometric standard deviation

Data is split into:
- **Weekdays:** Monday-Friday travel patterns
- **Weekends:** Saturday-Sunday travel patterns

**Privacy & Anonymization:** Data is anonymized and aggregated from numerous trips. Insufficient trip counts are automatically excluded to protect user privacy and ensure statistical accuracy.

**Important Note:** Uber Movement platform was discontinued around 2022. The data used in this study was downloaded prior to platform closure and is no longer publicly available.

## Repository Structure

```
.
├── Nairobi_Uber_Data/              # Raw Uber Movement quarterly CSV files (32 files)
├── read_uber_data.r                # Step 1: Process raw data → consolidated datasets
├── Distance Matrix.R               # Step 2: Create mean travel time matrix
├── Std Dev Matrix.R                # Step 3: Create standard deviation matrix
├── Uber-Nairobi-Weekdays.csv       # Processed weekday travel times (67,247 O-D pairs)
├── Uber-Nairobi-Weekends.csv       # Processed weekend travel times
├── Distances.txt                   # 400×400 mean travel time matrix (seconds)
├── Distances_StdDev.txt            # 400×400 std dev travel time matrix (seconds)
├── Paper/                          # Research paper PDF
├── README.md                       # This file
├── UBER_DATA_PIPELINE.md           # Detailed technical documentation
└── CITATIONS.md                    # References and data sources
```

## Data Processing Pipeline

### Step 1: Consolidate Raw Uber Movement Data

**Script:** `read_uber_data.r`

**Input:** 32 quarterly CSV files from `Nairobi_Uber_Data/`
**Output:** `Uber-Nairobi-Weekdays.csv` or `Uber-Nairobi-Weekends.csv`

**Process:**
1. Reads all quarterly files for specified day type (weekdays or weekends)
2. Extracts year and creates date column in month-year format
3. **For each source-destination pair, keeps only the most recent month's data**
   - This handles overlapping quarters and data updates
   - Uses `dplyr::group_by()` and `filter(date == max(date))`
4. Produces consolidated dataset with most up-to-date travel time estimates

**Key Decision:** Using most recent data for each O-D pair ensures the analysis reflects current traffic conditions while maintaining maximum spatial coverage.

### Step 2: Create Mean Travel Time Matrix

**Script:** `Distance Matrix.R`

**Input:** `Uber-Nairobi-Weekdays.csv`
**Output:** `Distances.txt` (400×400 matrix)

**Process:**
1. Loads consolidated weekday travel time data
2. Constructs directed graph using `igraph` package
   - Nodes: 400 hexclusters
   - Edges: Observed O-D pairs from Uber data
   - Weights: Mean travel times in seconds
   - Directed: Traffic patterns may differ by direction
3. Computes all-pairs shortest paths using Dijkstra's algorithm
   - Calculates minimum travel time between every zone pair
   - Fills in unobserved connections through routing
4. Exports as space-separated matrix (no headers)

**Why Shortest Paths?** Direct Uber measurements don't cover all possible O-D combinations. The shortest path algorithm infers travel times for unobserved pairs by routing through the observed network, reflecting realistic ambulance navigation.

### Step 3: Create Standard Deviation Matrix

**Script:** `Std Dev Matrix.R`

**Input:** `Uber-Nairobi-Weekdays.csv`
**Output:** `Distances_StdDev.txt` (400×400 matrix)

**Process:**
1. Loads same weekday data with standard deviation information
2. Builds graph with TWO edge attributes:
   - `weight`: Mean travel time (for routing)
   - `std_dev`: Standard deviation (for uncertainty)
3. **For each zone pair:**
   - Finds shortest path based on mean travel times
   - Calculates **pooled standard deviation** along path: σ_pooled = √(σ₁² + σ₂² + ... + σₙ²)
   - Assumes independence of travel time segments
4. **Validation:** Recalculates mean times using same paths and compares to `Distances.txt`
5. Exports matching structure to distance matrix

**Critical Design Choice:** Routing decisions use mean travel times (not std dev), as this reflects how ambulances actually navigate. Standard deviations are then calculated for the chosen routes to quantify uncertainty.

## Usage

### Requirements

- R (version ≥ 4.0)
- R packages: `tidyverse`, `lubridate`, `igraph`

### Running the Pipeline

```r
# Step 1: Consolidate Uber Movement data
# Edit read_uber_data.r to set typeOfDay = "Weekdays" or "Weekends"
source("read_uber_data.r")

# Step 2: Generate distance matrix
source("Distance Matrix.R")

# Step 3: Generate standard deviation matrix
source("Std Dev Matrix.R")
```

**Note:** Scripts assume data directory paths. Update `setwd()` calls as needed for your environment.

## Key Modeling Parameters

- **Coverage Threshold:** 15 minutes (900 seconds)
- **Pre-trip Delay:** 3 minutes for ambulance dispatch and crew mobilization
- **Response Time Calculation:** Pre-trip delay + travel time ≤ 15 minutes

## Data Limitations & Considerations

1. **Uber Movement Discontinued:** Data is no longer publicly accessible; preserved copy used for research
2. **Coverage Gaps:** Some hexcluster pairs have no direct Uber observations (filled via shortest paths)
3. **Temporal Aggregation:** Monthly aggregates may mask hour-by-hour variations
4. **Weekday Focus:** Analysis primarily uses weekday patterns (higher emergency call volume)
5. **Observation Period:** 2016-2020 traffic patterns; COVID-19 may have affected 2020-Q1
6. **Independence Assumption:** Pooled std dev calculation assumes independent road segments

## Citation

If you use this data or methodology, please cite:

```
van den Berg, P. L., Calmon, A. P., Gernert, A. K., Lemmens, S., Rabinovich, M., & Romero, G. (2024).
The Value of Time- and Location-Commitment for Decentralized Emergency Medical Services.
Manufacturing & Service Operations Management (Major Revision).
```

### Data Sources

**Uber Movement:**
- Uber Technologies. (2017-2022). Uber Movement: Travel Times. [Data platform, now discontinued]
- Access date: March 2022
- Coverage: Nairobi, Kenya, 2016-2020

**H3 Hexagonal Index:**
- Uber Technologies. (2018). H3: Uber's Hexagonal Hierarchical Spatial Index.
- GitHub: https://github.com/uber/h3
- Documentation: https://h3geo.org/

See `CITATIONS.md` for complete reference list.

## Contact

For questions about the data processing pipeline or research methodology, please contact:

- Andre P. Calmon (andre.calmon@gatech.edu) - Georgia Institute of Technology
- Pieter L. van den Berg (vandenberg@rsm.nl) - Erasmus University

## License

Research code and documentation are provided for academic and research purposes. Uber Movement data subject to original Uber Technologies terms of use.

## Acknowledgments

We acknowledge Uber Technologies for making Movement data available for research purposes prior to platform discontinuation.

---

**Last Updated:** October 2025
**Repository Status:** Supporting materials for M&SOM submission (Major Revision)
