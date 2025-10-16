################################################################################
# Mean Travel Time Distance Matrix Generator
################################################################################
#
# Purpose:
#   Creates a complete 400×400 distance matrix from Uber Movement travel time data
#   using graph-based shortest path calculations. Converts sparse O-D observations
#   (~67,000 pairs) into complete all-pairs distance matrix (160,000 pairs).
#
# Input:
#   - Uber-Nairobi-Weekdays.csv (processed by read_uber_data.r)
#   - Contains: sourceid, dstid, mean_travel_time, std dev, date
#
# Output:
#   - Distances.txt: 400×400 matrix of minimum travel times (seconds)
#   - Format: space-separated, no headers, no row names
#   - Entry [i,j] = shortest travel time from zone i to zone j
#
# Methodology:
#   1. Build directed graph from observed O-D pairs
#   2. Weight edges by mean travel time
#   3. Compute all-pairs shortest paths using Dijkstra's algorithm
#   4. Export complete distance matrix
#
# Why Shortest Paths?
#   Uber Movement data doesn't cover all possible 400×400 = 160,000 zone pairs.
#   Shortest path algorithm infers unobserved connections by routing through
#   the observed network, reflecting realistic ambulance navigation.
#
# Graph Properties:
#   - Nodes: 400 hexclusters (Nairobi metro area)
#   - Edges: ~67,000 observed O-D pairs
#   - Type: Directed (A→B may differ from B→A due to traffic patterns)
#   - Weights: Mean travel time in seconds
#
# Note on Disconnected Nodes:
#   Paper mentions "5 origins don't seem to have at least one destination"
#   These will have Inf entries in the distance matrix.
#
# Author: [Research Team]
# Date: [Original Date]
# Last Modified: October 2025 (added documentation)
################################################################################

library(tidyverse)  # For data manipulation
library(lubridate)  # For date handling (not actively used in this script)
library(igraph)     # For graph construction and shortest path algorithms

# Set working directory
# NOTE: Update this path to match your local directory structure
setwd("~/Dropbox (Personal)/Georgia Tech Research/Flare/Data Uber/Data")

# ============================================================================
# Load Preprocessed Uber Movement Data
# ============================================================================
df = read_csv("Uber-Nairobi-Weekdays.csv")

# Determine total number of unique zones
num_nodes = max(df$sourceid, df$dstid)  # Should be 400 for Nairobi

# ============================================================================
# Build Graph from Observed O-D Pairs
# ============================================================================

# Create edge list: 2-column matrix [source, destination]
# Each row represents an observed connection between zones
el = as.matrix(df[,c("sourceid", "dstid")])

# Construct directed graph
# Why directed? Traffic patterns may differ by direction:
#   - One-way streets
#   - Traffic light timing
#   - Gradient (uphill vs downhill)
G = graph_from_edgelist(el, directed = TRUE)

# Assign edge weights = mean travel time (in seconds)
# These weights will be used by shortest path algorithm
E(G)$weight = df$mean_travel_time

# ============================================================================
# Compute All-Pairs Shortest Paths
# ============================================================================

# Calculate distance matrix using Dijkstra's shortest path algorithm
# Result: 400×400 matrix where entry [i,j] = min travel time from zone i to j
#
# Parameters:
#   - v: source nodes (all 400 zones)
#   - to: destination nodes (all 400 zones)
#   - mode: "out" follows edge directions (important for directed graph)
#
# Algorithm: Dijkstra's shortest path (O(V² log V + VE))
dist_matrix = distances(G, v = 1:num_nodes, to = 1:num_nodes, mode = "out")

# ============================================================================
# Matrix Interpretation
# ============================================================================
# Row i, Column j = minimum travel time from zone i to zone j
# Diagonal entries = 0 (zero time from zone to itself)
# Inf entries = no path exists between zones (disconnected components)
#
# Example: dist_matrix[10, 25] = 480 means:
#   Shortest travel time from zone 10 to zone 25 is 480 seconds (8 minutes)
#   This may be direct (if Uber data contains 10→25) or
#   routed through intermediates (e.g., 10→15→25 if that's shorter)

# ============================================================================
# Write Output File
# ============================================================================
# Format: Space-separated values, 400 rows × 400 columns
# No column headers, no row names (for easy import into optimization code)
write.table(dist_matrix, "Distances.txt", col.names = FALSE, row.names = FALSE)

# Expected output: ~1.2 MB file
# Usage in paper: Defines J_i sets for coverage model (Section 3)
# Coverage threshold: 15 min = 900 sec (including 3 min pre-trip delay)
          