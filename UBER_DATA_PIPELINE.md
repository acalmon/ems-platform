# Uber Movement Data Pipeline: Technical Documentation

**Document Purpose:** Detailed technical documentation of the Uber Movement data processing pipeline for Nairobi EMS research

**Last Updated:** October 2025

---

## Table of Contents

1. [Uber Movement Data Structure](#1-uber-movement-data-structure)
2. [H3 Hexagonal Spatial Index](#2-h3-hexagonal-spatial-index)
3. [Data Processing: read_uber_data.r](#3-data-processing-read_uber_datar)
4. [Graph Construction: Distance Matrix.R](#4-graph-construction-distance-matrixr)
5. [Uncertainty Quantification: Std Dev Matrix.R](#5-uncertainty-quantification-std-dev-matrixr)
6. [Mathematical Formulations](#6-mathematical-formulations)
7. [Validation & Quality Checks](#7-validation--quality-checks)
8. [Known Limitations](#8-known-limitations)

---

## 1. Uber Movement Data Structure

### 1.1 Raw Data Organization

**Location:** `Nairobi_Uber_Data/` directory

**File Naming Convention:**
```
nairobi-hexclusters-{YEAR}-{QUARTER}-Only{DayType}-MonthlyAggregate.csv
```

**Examples:**
- `nairobi-hexclusters-2016-1-OnlyWeekdays-MonthlyAggregate.csv`
- `nairobi-hexclusters-2019-3-OnlyWeekends-MonthlyAggregate.csv`

**Coverage:**
- Years: 2016, 2017, 2018, 2019, 2020
- Quarters: 1 (Jan-Mar), 2 (Apr-Jun), 3 (Jul-Sep), 4 (Oct-Dec)
- Day Types: Weekdays (Mon-Fri), Weekends (Sat-Sun)
- Total Files: 32 (4 years × 4 quarters × 2 day types)

**Note:** 2020 data only includes Q1 (Jan-Mar 2020), cut off before COVID-19 pandemic effects.

### 1.2 Data Fields

Each CSV file contains the following columns:

| Field Name | Data Type | Unit | Description |
|------------|-----------|------|-------------|
| `sourceid` | integer | - | Origin hexcluster ID (1-400) |
| `dstid` | integer | - | Destination hexcluster ID (1-400) |
| `month` | integer | 1-12 | Month within the quarter |
| `mean_travel_time` | float | seconds | Arithmetic mean of observed travel times |
| `standard_deviation_travel_time` | float | seconds | Standard deviation of observed travel times |
| `geometric_mean_travel_time` | float | seconds | Geometric mean of observed travel times |
| `geometric_standard_deviation_travel_time` | float | - | Geometric standard deviation (dimensionless ratio) |

**Record Count Examples:**
- 2016-Q1 Weekdays: 37,655 rows
- 2019-Q3 Weekends: 6,668,637 rows (filename indicates)
- Typical file: 10,000-40,000 origin-destination pairs

### 1.3 Data Generation Methodology (Uber Movement)

**Source Data:** GPS traces from Uber rides in Nairobi

**Aggregation Process:**
1. Individual ride GPS points collected during trip
2. Origin and destination mapped to hexcluster IDs
3. Travel time calculated: pickup time → dropoff time
4. Trips grouped by (sourceid, dstid, month, day_type)
5. Statistics computed: mean, std dev, geometric mean, geometric std dev
6. Results with insufficient sample size excluded (privacy threshold)

**Privacy Protection:**
- Minimum trip count threshold (exact number not publicly disclosed)
- No individual ride data preserved
- Aggregation over multiple trips masks individual patterns
- No timestamp information (prevents trip re-identification)

**Temporal Aggregation:**
- Data aggregated at monthly level within each quarter
- Separate aggregation for weekdays vs weekends
- No hour-of-day breakdown in this dataset variant

### 1.4 Data Quality Characteristics

**Coverage:**
- Not all 400×400 = 160,000 possible O-D pairs have observations
- Typical coverage: 30,000-70,000 pairs per quarter
- Missing pairs occur due to:
  - No Uber rides between certain distant zones
  - Insufficient trip counts (privacy threshold)
  - Low-demand peripheral areas

**Observed vs Inferred Connections:**
- **Directly Observed:** Pairs present in Uber Movement CSV files
- **Inferred:** Pairs computed via shortest path algorithm (see Section 4)

**Asymmetry:**
- Travel time from A→B may differ from B→A
- Causes: One-way streets, traffic light timing, gradient (uphill/downhill)
- Data is DIRECTED (maintains asymmetry)

---

## 2. H3 Hexagonal Spatial Index

### 2.1 System Overview

**H3 (Hexagonal Hierarchical Geospatial Indexing System)**
- Developed by Uber Technologies, released open-source in 2018
- GitHub: https://github.com/uber/h3
- Documentation: https://h3geo.org/

**Purpose:** Efficient spatial indexing and analysis using hierarchical hexagonal grid

### 2.2 Why Hexagons?

**Advantages over square grids:**

1. **Uniform Neighbor Distance:** All 6 neighbors are equidistant from center
2. **Minimal Quantization Error:** Better approximation of circular service areas
3. **Spatial Continuity:** Smoother transitions between cells
4. **Aesthetic Properties:** More natural-looking spatial visualizations

**Comparison:**
- Square grid: 4 adjacent neighbors at distance d, 4 diagonal at distance √2·d (41% variation)
- Hexagonal grid: 6 neighbors all at distance d (0% variation)

### 2.3 Hierarchical Structure

**Resolution Levels:** H3 supports 16 resolutions (0-15)

| Resolution | Cell Area | Edge Length | Applications |
|------------|-----------|-------------|--------------|
| 0 | ~4,250,546 km² | ~1,107 km | Continental scale |
| 3 | ~12,392 km² | ~70 km | Metropolitan regions |
| 5 | ~252 km² | ~10 km | Cities |
| 7 | ~5.16 km² | ~1.4 km | **Nairobi dataset** |
| 9 | ~0.105 km² | ~200 m | Neighborhoods |
| 15 | ~0.0009 m² | ~0.5 m | Sub-meter precision |

**Note:** Exact resolution used for Nairobi not explicitly documented but inferred from ~2.94 km² average area → approximately resolution 7-8.

**Aperture 7 Subdivision:** Each parent hexagon subdivides into 7 child hexagons at next finer resolution.

### 2.4 Nairobi Implementation

**Spatial Extent:** Nairobi metropolitan area
**Number of Hexclusters:** 400
**Average Area:** 2.94 km² per hexcluster
**Estimated Resolution:** 7-8 (based on area)

**Zone Identification:**
- `sourceid` and `dstid` range from 1 to 400
- IDs are arbitrary labels (not standard H3 cell indices)
- Mapping to lat/lon coordinates available via GeoJSON boundary file (not included in dataset)

**Coverage Area Calculation:**
```
Total Area = 400 hexclusters × 2.94 km²/hexcluster = 1,176 km²
```
For reference: Nairobi County area ≈ 696 km² (core city), Greater Nairobi ≈ 1,500 km²

---

## 3. Data Processing: read_uber_data.r

### 3.1 Script Purpose

**Objective:** Consolidate 32 quarterly CSV files → Single dataset with most recent travel time data for each O-D pair

**Rationale:** Overlapping quarters and monthly measurements require conflict resolution strategy.

### 3.2 Algorithm

```r
# Pseudo-code representation
FOR day_type IN {Weekdays, Weekends}:

    # Initialize empty result
    consolidated_data = empty_tibble()

    # Get all quarterly files matching day_type
    files = list_files(pattern = day_type)

    FOR each file IN files:
        # Extract year from filename
        year = extract_year(filename)

        # Load CSV
        data = read_csv(file)

        # Add temporal metadata
        data$year = year
        data$date = create_date(month, year)

        # Keep most recent month for each O-D pair
        recent_data = data %>%
            group_by(sourceid, dstid) %>%
            filter(date == max(date)) %>%
            ungroup()

        # Merge with consolidated data
        consolidated_data = rbind(consolidated_data, recent_data)

        # Re-apply filter to handle cross-file overlaps
        consolidated_data = consolidated_data %>%
            group_by(sourceid, dstid) %>%
            filter(date == max(date)) %>%
            ungroup()

    # Save output
    write_csv(consolidated_data, output_filename)
```

### 3.3 Key Design Decisions

**Decision 1: Most Recent Data Selection**

**Why?** Different quarters may report overlapping months:
- Q4 2016: October, November, December
- Q1 2017: January (also includes Dec data in some cases)

**Solution:** For each (sourceid, dstid), keep only the observation with `max(date)`

**Benefit:** Ensures latest available measurement, avoiding duplication

**Decision 2: Iterative Filtering**

**Implementation:** Filter applied both within-file and across-files

**Reason:** As files are processed sequentially, newer data may supersede previous files

**Decision 3: Date Formatting**

**Uses:** `lubridate::my()` function for month-year parsing

**Format:** "MM-YYYY" → Date object (e.g., "03-2017" → 2017-03-01)

**Advantage:** Enables chronological comparisons via `max(date)`

### 3.4 Output Specifications

**Output Files:**
- `Uber-Nairobi-Weekdays.csv` (67,247 rows observed)
- `Uber-Nairobi-Weekends.csv` (similar size)

**Row Interpretation:** Each row represents the most recent monthly average for that specific source-destination pair.

**Fields Preserved:** All original columns plus `year` and `date`

**Data Reduction:**
- Input: ~32 files × ~30,000 rows/file ≈ 960,000 total rows
- Output: ~67,000 unique O-D pairs
- Reduction: ~93% (due to filtering most recent data)

---

## 4. Graph Construction: Distance Matrix.R

### 4.1 Script Purpose

**Objective:** Convert sparse O-D observations → Complete 400×400 all-pairs distance matrix

**Challenge:** Uber Movement data doesn't cover all 160,000 possible zone pairs

**Solution:** Graph-based shortest path computation

### 4.2 Graph Theory Approach

**Graph Representation:**
- **Nodes (V):** 400 hexclusters
- **Edges (E):** Observed O-D pairs from Uber Movement data (~67,000 edges)
- **Edge Weights:** Mean travel time in seconds
- **Graph Type:** Directed (A→B may differ from B→A)

**Library Used:** `igraph` R package

**Graph Construction:**
```r
# Create edge list: 2-column matrix [source, destination]
edge_list = as.matrix(data[, c("sourceid", "dstid")])

# Build directed graph
G = graph_from_edgelist(edge_list, directed = TRUE)

# Assign edge weights
E(G)$weight = data$mean_travel_time
```

### 4.3 Shortest Path Algorithm

**Algorithm:** Dijkstra's shortest path (implementation in `igraph::distances()`)

**Computation:**
```r
dist_matrix = distances(
    graph = G,
    v = 1:400,           # From all nodes
    to = 1:400,          # To all nodes
    mode = "out",        # Follow edge directions
    algorithm = "dijkstra"
)
```

**Result:** 400×400 matrix where `dist_matrix[i, j]` = minimum travel time from zone i to zone j

**Complexity:** O(|V|² log|V| + |V||E|) for all-pairs using repeated Dijkstra

### 4.4 Path Inference Examples

**Example 1: Direct Connection**
- Uber data contains sourceid=10, dstid=25, time=480 seconds
- Matrix entry [10, 25] = 480 (direct observation)

**Example 2: Single Intermediate**
- Uber data: 10→15 (300s), 15→25 (200s)
- No direct 10→25 observation
- Shortest path: 10→15→25 = 500 seconds
- Matrix entry [10, 25] = 500 (inferred)

**Example 3: Multiple Paths**
- Path A: 10→12→18→25 = 650 seconds
- Path B: 10→15→25 = 500 seconds
- Shortest path selected: Path B
- Matrix entry [10, 25] = 500

**Example 4: No Connection**
- If no path exists from zone i to zone j
- Matrix entry [i, j] = Inf (infinity)
- Paper notes: "5 nodes don't seem to have outgoing edges"

### 4.5 Assumptions & Implications

**Assumption 1: Additivity**
- Travel time through A→B→C = time(A→B) + time(B→C)
- Ignores: Turn delays, complex intersection dynamics
- Justification: Large zone size (~3 km²) makes intra-zone effects negligible

**Assumption 2: Network Connectivity**
- Assumes road network allows travel between most zone pairs
- Nairobi road network is well-connected (expected for major city)

**Assumption 3: Static Times**
- Uses single mean value per O-D pair (monthly average)
- Ignores: Hour-of-day variation, day-to-day fluctuations
- Justification: Tactical planning focus (not real-time optimization)

**Implication for Ambulances:**
- Distance matrix represents realistic routing through road network
- Ambulances will navigate via intermediate zones for distant destinations
- Critical for 15-minute coverage threshold calculation

### 4.6 Output Format

**File:** `Distances.txt`

**Format:**
- 400 rows × 400 columns
- Space-separated values
- No header row, no row names
- Units: seconds

**Example Structure:**
```
0 312 567 891 ... (400 values)
289 0 455 723 ... (400 values)
543 389 0 612 ... (400 values)
...
(400 rows total)
```

**Interpretation:** Row i, Column j = travel time from zone i to zone j

**Diagonal:** All zeros (zero time from zone to itself)

**Infinity Values:** Encoded as "Inf" for disconnected pairs

---

## 5. Uncertainty Quantification: Std Dev Matrix.R

### 5.1 Script Purpose

**Objective:** Quantify travel time variability for ambulance response planning

**Challenge:** Standard deviations must match the routing paths used in mean distance matrix

**Solution:** Pooled standard deviation calculation along shortest paths

### 5.2 Mathematical Motivation

**Problem Statement:**
- Ambulance travels from zone i to zone j via shortest path
- Path consists of edges: i→a, a→b, b→c, ..., z→j
- Each edge has observed std dev: σ₁, σ₂, σ₃, ..., σₙ
- **Question:** What is the total travel time variability?

**Statistical Framework:**
- Assume travel times on different road segments are independent random variables
- Total travel time T = T₁ + T₂ + ... + Tₙ (sum of segment times)
- Variance of sum: Var(T) = Var(T₁) + Var(T₂) + ... + Var(Tₙ) (by independence)
- Standard deviation: σ_total = √Var(T) = √(σ₁² + σ₂² + ... + σₙ²)

**Formula:** **Pooled Standard Deviation**
```
σ_pooled = √(σ₁² + σ₂² + σ₃² + ... + σₙ²)
```

### 5.3 Algorithm

```r
# Initialize output matrix
std_dev_matrix = matrix(Inf, nrow = 400, ncol = 400)

# Build graph with TWO edge attributes
E(G)$weight = data$mean_travel_time      # For routing
E(G)$std_dev = data$standard_deviation_travel_time  # For uncertainty

# For each source node
FOR i IN 1:400:

    # Find shortest paths from i to all destinations
    # (based on MEAN travel times)
    paths_from_i = shortest_paths(
        graph = G,
        from = i,
        to = 1:400,
        mode = "out",
        output = "both"  # Return both vertex and edge sequences
    )

    # For each destination node
    FOR j IN 1:400:

        # Get edge sequence along shortest path
        path_edges = paths_from_i$epath[[j]]

        IF length(path_edges) > 0:
            # Path exists: calculate pooled std dev
            std_devs = E(G)$std_dev[path_edges]
            pooled_std = sqrt(sum(std_devs^2))
            std_dev_matrix[i, j] = pooled_std

        ELSE IF i == j:
            # Diagonal: zero variability
            std_dev_matrix[i, j] = 0

        # ELSE: No path exists, remains Inf

# Write output
write.table(std_dev_matrix, "Distances_StdDev.txt")
```

### 5.4 Key Design Decisions

**Decision 1: Routing Based on Mean Times**

**Rationale:** Ambulances navigate to minimize expected travel time, not to minimize variability

**Implementation:** `E(G)$weight = mean_travel_time` determines paths

**Consequence:** Some paths with higher variability may be chosen if mean time is lower

**Decision 2: Independence Assumption**

**Assumption:** Travel times on different road segments are independent

**Validity:**
- ✓ Reasonable: Segments represent different roads, traffic conditions localized
- ✗ Limitation: City-wide events (weather, major accidents) affect multiple segments
- ✗ Limitation: Traffic waves propagate between adjacent segments

**Justification:** Standard approach in transportation literature; violations tend to average out over many trips

**Decision 3: Separate Matrix Storage**

**Alternative:** Could store in single file with mean/std pairs

**Chosen:** Separate matrices maintain simplicity and match distance matrix structure

**Benefit:** Easier integration with optimization code expecting matrix input

### 5.5 Validation Process

**Objective:** Verify that std dev matrix uses same paths as distance matrix

**Method:**
1. Recalculate mean travel times using edges from std dev computation
2. Compare to original `Distances.txt`
3. Report maximum absolute difference and count of mismatches

**Implementation:**
```r
# Recalculate means along same paths
dist_matrix_recomputed = matrix(Inf, 400, 400)

FOR i IN 1:400:
    FOR j IN 1:400:
        path_edges = paths_from_i$epath[[j]]
        IF length(path_edges) > 0:
            mean_times = E(G)$weight[path_edges]
            dist_matrix_recomputed[i, j] = sum(mean_times)

# Compare matrices
max_diff = max(abs(dist_matrix_original - dist_matrix_recomputed))
n_mismatches = sum(abs(dist_matrix_original - dist_matrix_recomputed) > 0.001)

# Report
print(paste("Max difference:", max_diff))
print(paste("Mismatches:", n_mismatches))
```

**Expected Result:**
- Max difference: < 0.001 seconds (floating-point rounding only)
- Mismatches: 0

**If Validation Fails:** Indicates data mismatch or algorithm error; investigation required

### 5.6 Output Format

**File:** `Distances_StdDev.txt`

**Format:** Identical to `Distances.txt`
- 400 rows × 400 columns
- Space-separated values
- No header row, no row names
- Units: seconds

**Interpretation:** Entry [i, j] = pooled standard deviation for travel from zone i to zone j

**Diagonal:** All zeros (no variability when origin = destination)

**Infinity Values:** "Inf" for disconnected pairs (matches distance matrix)

---

## 6. Mathematical Formulations

### 6.1 Coverage Probability Model

**From Paper (Section 3.1):**

For a demand point i covered by ambulance set K:

```
s_i(K) = 1 - ∏_{k∈K} [1 - (q_k × Σ_{j∈J_i} p_jk)]
```

Where:
- `q_k` = availability probability of ambulance k (time commitment)
- `p_jk` = probability ambulance k is at location j (spatial commitment)
- `J_i` = set of locations within response time threshold of demand point i

**Distance Matrix Role:** Defines set `J_i`

```
J_i = {j : Distances[j, i] + pre_trip_delay ≤ threshold}
J_i = {j : Distances[j, i] ≤ 900 - 180 = 720 seconds}
```

### 6.2 Pooled Standard Deviation Derivation

**Random Variables:**
- T_k = travel time on edge k (random variable)
- E[T_k] = μ_k (mean travel time, observed)
- SD[T_k] = σ_k (standard deviation, observed)

**Total Path Travel Time:**
```
T_total = T_1 + T_2 + ... + T_n
```

**Expected Value:**
```
E[T_total] = E[T_1] + E[T_2] + ... + E[T_n] = μ_1 + μ_2 + ... + μ_n
```
(This is what Distance Matrix.R calculates)

**Variance (assuming independence):**
```
Var[T_total] = Var[T_1] + Var[T_2] + ... + Var[T_n] = σ_1² + σ_2² + ... + σ_n²
```

**Standard Deviation:**
```
SD[T_total] = √Var[T_total] = √(σ_1² + σ_2² + ... + σ_n²)
```
(This is what Std Dev Matrix.R calculates)

### 6.3 Response Time Calculation

**Total Response Time:**
```
Response_Time = Pre_Trip_Delay + Travel_Time
Response_Time = 180 seconds + Distances[ambulance_zone, incident_zone]
```

**Coverage Criterion:**
```
IF Response_Time ≤ 900 seconds (15 minutes):
    Incident is "covered" by that ambulance
ELSE:
    Incident is NOT covered by that ambulance
```

**Stochastic Extension (with variability):**
```
Response_Time ~ Normal(μ = 180 + Distances[i,j], σ = Distances_StdDev[i,j])

Coverage_Probability = P(Response_Time ≤ 900)
                      = Φ((900 - μ) / σ)  [using normal CDF]
```

Note: Paper uses deterministic threshold for optimization, stochastic model for simulation (Section 5.3)

---

## 7. Validation & Quality Checks

### 7.1 Data Completeness Checks

**Check 1: Node Coverage**
```r
num_nodes = max(df$sourceid, df$dstid)
# Expected: 400
# Observed: 400 ✓
```

**Check 2: Edge Count**
```r
nrow(df)
# Weekdays: 67,247 unique O-D pairs
# Coverage: 67,247 / 160,000 = 42% of all possible pairs
```

**Check 3: Disconnected Components**
```r
components = igraph::components(G)
components$no
# Paper mentions: "5 nodes don't seem to have [outgoing edges]"
# Expected: 1 main component + 5 isolated nodes
```

### 7.2 Distance Matrix Validation

**Validation 1: Symmetry Check (SHOULD FAIL)**
```r
is_symmetric = all(dist_matrix == t(dist_matrix))
# Expected: FALSE (directed graph)
# Rationale: Traffic patterns differ by direction
```

**Validation 2: Triangle Inequality**
```r
# For all i, j, k: d(i,k) ≤ d(i,j) + d(j,k)
# Should hold for shortest path distances
violations = 0
FOR i, j, k:
    IF dist_matrix[i,k] > dist_matrix[i,j] + dist_matrix[j,k] + tolerance:
        violations += 1
# Expected: violations = 0
```

**Validation 3: Diagonal Check**
```r
all(diag(dist_matrix) == 0)
# Expected: TRUE (zero distance from zone to itself)
```

**Validation 4: Reasonableness Check**
```r
# Nairobi metropolitan area ~ 40km diameter
# Max driving distance ~ 60km (with routing)
# At 30 km/h average: 60km / 30 km/h = 2 hours = 7200 seconds

max_finite_distance = max(dist_matrix[is.finite(dist_matrix)])
# Expected: < 10,000 seconds (reasonable upper bound)
```

### 7.3 Standard Deviation Matrix Validation

**Validation 1: Path Consistency (Built-in)**
```r
# Performed automatically in Std Dev Matrix.R
# Recalculates means using same paths
# Reports max_diff and n_mismatches
```

**Validation 2: Non-Negativity**
```r
all(std_dev_matrix >= 0)
# Expected: TRUE (standard deviation cannot be negative)
```

**Validation 3: Diagonal Check**
```r
all(diag(std_dev_matrix) == 0)
# Expected: TRUE (zero variability within same zone)
```

**Validation 4: Coefficient of Variation**
```r
# CV = σ / μ (relative variability)
# Typical highway: CV ≈ 0.1-0.3
# Urban traffic: CV ≈ 0.3-0.6

cv_matrix = std_dev_matrix / dist_matrix
median_cv = median(cv_matrix[is.finite(cv_matrix)])
# Expected: 0.2-0.5 (reasonable for urban traffic)
```

### 7.4 Temporal Consistency

**Check: Most Recent Data Selection**
```r
# After running read_uber_data.r:
df %>%
    group_by(sourceid, dstid) %>%
    summarize(n = n()) %>%
    filter(n > 1) %>%
    nrow()
# Expected: 0 (no duplicate O-D pairs, only most recent kept)
```

---

## 8. Known Limitations

### 8.1 Data Limitations

**Limitation 1: Temporal Aggregation**
- Monthly averages mask hour-by-hour variations
- Rush hour vs off-peak differences not captured
- Implication: Coverage estimates may be optimistic for peak hours

**Limitation 2: Incomplete Network**
- Only 42% of possible O-D pairs have direct Uber observations
- 58% inferred via shortest paths
- Implication: Some distances may have larger error bounds

**Limitation 3: Uber Rider Sample Bias**
- Data from Uber rides may not represent all traffic
- Uber drivers may use different routes than ambulances
- Implication: Ambulance travel times could differ systematically

**Limitation 4: Data Currency**
- Dataset ends 2020-Q1 (before COVID-19 impact)
- Traffic patterns may have changed since collection
- Road infrastructure improvements not reflected

### 8.2 Methodological Limitations

**Limitation 1: Independence Assumption**
- Pooled std dev assumes independent segments
- Reality: Correlated traffic conditions across segments
- Implication: Actual variability may be higher than estimated

**Limitation 2: Static Planning Horizon**
- Single mean value per O-D pair
- No adaptation to real-time conditions
- Implication: Operational performance may vary from estimates

**Limitation 3: Directed Graph Assumption**
- Treats all roads as directed (A→B ≠ B→A)
- Some roads may be bidirectional with similar times
- Implication: Graph may be more complex than necessary

**Limitation 4: Disconnected Nodes**
- 5 nodes noted as having no outgoing edges
- Likely data artifacts or peripheral areas
- Implication: Complete coverage optimization infeasible

### 8.3 Modeling Assumptions

**Assumption 1: Additive Travel Times**
- Assumes path time = sum of edge times
- Ignores: Turn delays, complex intersections
- Justification: Large zone size mitigates intra-zone effects

**Assumption 2: Normal Distribution**
- Simulation assumes normal travel time distribution
- Reality: May be skewed (heavy right tail from delays)
- Justification: Central Limit Theorem for multiple segments

**Assumption 3: Stationary Statistics**
- Mean and std dev assumed constant over analysis period
- Reality: Seasonal variations, long-term trends
- Justification: Four-year dataset averages out fluctuations

### 8.4 Implications for Research

**Coverage Estimates:**
- Likely optimistic (monthly averages smooth variability)
- Relative comparisons (intervention A vs B) more reliable than absolute values
- Simulation (Section 5.3) provides reality check

**Optimization Results:**
- Optimal locations valid under assumptions
- Real deployment should account for hour-of-day patterns
- Robustness analysis important (not performed in scripts, done in paper)

**Policy Recommendations:**
- Directional insights robust (spatial > temporal commitment)
- Quantitative estimates (15 ambulances vs 340) should include confidence intervals
- Field validation recommended before operational deployment

---

## Appendix A: Data Dictionary

### A.1 Input Files (Nairobi_Uber_Data/)

| File Pattern | Records | Size | Description |
|--------------|---------|------|-------------|
| nairobi-hexclusters-YYYY-Q-OnlyWeekdays-MonthlyAggregate.csv | ~10-40k | ~1-5 MB | Quarterly weekday data |
| nairobi-hexclusters-YYYY-Q-OnlyWeekends-MonthlyAggregate.csv | ~10-40k | ~1-5 MB | Quarterly weekend data |

### A.2 Intermediate Files

| File | Records | Size | Description |
|------|---------|------|-------------|
| Uber-Nairobi-Weekdays.csv | 67,247 | ~4 MB | Consolidated weekday O-D pairs |
| Uber-Nairobi-Weekends.csv | ~65,000 | ~4 MB | Consolidated weekend O-D pairs |

### A.3 Output Files

| File | Dimensions | Size | Description |
|------|------------|------|-------------|
| Distances.txt | 400×400 | ~1.2 MB | Mean travel time matrix (seconds) |
| Distances_StdDev.txt | 400×400 | ~2.5 MB | Std dev travel time matrix (seconds) |

---

## Appendix B: Software Dependencies

### B.1 R Packages

| Package | Version | Purpose |
|---------|---------|---------|
| tidyverse | ≥1.3.0 | Data manipulation (dplyr, tibble) |
| lubridate | ≥1.7.0 | Date parsing and handling |
| igraph | ≥1.2.0 | Graph construction and shortest paths |

### B.2 Installation Commands

```r
install.packages("tidyverse")
install.packages("lubridate")
install.packages("igraph")
```

---

**Document End**

For questions or clarifications on this technical documentation, contact:
- Andre P. Calmon (andre.calmon@gatech.edu)
