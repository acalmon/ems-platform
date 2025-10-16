################################################################################
# Standard Deviation Distance Matrix Calculator
################################################################################
# 
# Purpose: 
#   Calculates a matrix of pooled standard deviations for travel times between
#   all region pairs in Nairobi. Uses the same routing paths as the mean travel
#   time distance matrix (based on shortest paths).
#
# Input:
#   - Uber-Nairobi-Weekdays.csv: Contains mean and std dev of travel times
#     between hexcluster pairs (most recent month only, from read_uber_data.r)
#
# Output:
#   - Distances_StdDev.txt: Matrix of pooled standard deviations (seconds)
#     matching the structure of Distances.txt
#
# Mathematical Approach:
#   For direct connections: Uses observed standard deviation
#   For indirect paths: Calculates pooled standard deviation using:
#     σ_pooled = sqrt(σ₁² + σ₂² + ... + σₙ²)
#   This assumes independence of travel time segments, which is reasonable
#   for different road segments along a route.
#
# Key Decision: 
#   Routing paths are determined by MEAN travel times (not std dev).
#   This ensures consistency with Distances.txt and reflects actual
#   ambulance routing decisions.
#
# Author: [Your name]
# Date: [Date]
################################################################################

library(tidyverse)
library(lubridate)
library(igraph)

################################################################################
# 1. LOAD DATA
################################################################################

setwd("~/Dropbox (Personal)/Georgia Tech Research/Flare/Data Uber/Data")

# Read preprocessed Uber travel time data
# This file contains only the most recent month for each source-destination pair
df = read_csv("Uber-Nairobi-Weekdays.csv")

# Determine number of unique hexcluster nodes
num_nodes = max(df$sourceid, df$dstid)

################################################################################
# 2. BUILD GRAPH WITH TRAVEL TIME DATA
################################################################################

# Create edge list from source-destination pairs
el = as.matrix(df[,c("sourceid", "dstid")])

# Build directed graph
# Directed because travel times may differ by direction (e.g., due to one-way streets)
G = graph_from_edgelist(el, directed = TRUE)

# Add edge attributes:
# - weight: mean travel time (used for routing decisions)
# - std_dev: standard deviation of travel time (used for uncertainty calculation)
E(G)$weight = df$mean_travel_time
E(G)$std_dev = df$standard_deviation_travel_time

################################################################################
# 3. CALCULATE POOLED STANDARD DEVIATIONS
################################################################################

# Initialize output matrix with Inf (disconnected regions stay as Inf)
std_dev_matrix = matrix(Inf, nrow = num_nodes, ncol = num_nodes)

# Calculate pooled standard deviation for each source-destination pair
# Note: We call shortest_paths() once per source node for efficiency
for(i in 1:num_nodes) {
  
  # Find shortest paths from node i to all other nodes
  # Paths are determined by minimizing mean travel time (E(G)$weight)
  paths_from_i = shortest_paths(G, 
                                 from = i, 
                                 to = 1:num_nodes, 
                                 mode = "out",
                                 output = "both")
  
  for(j in 1:num_nodes) {
    # Extract the sequence of edges in the path from i to j
    path_edges = paths_from_i$epath[[j]]
    
    if(length(path_edges) > 0) {
      # Path exists: calculate pooled standard deviation
      
      # Get standard deviations for all edges along the path
      std_devs = E(G)$std_dev[path_edges]
      
      # Calculate pooled standard deviation
      # Formula: σ_pooled = sqrt(σ₁² + σ₂² + ... + σₙ²)
      # This is the correct way to combine standard deviations of
      # independent random variables (travel time segments)
      pooled_std = sqrt(sum(std_devs^2))
      
      std_dev_matrix[i, j] = pooled_std
      
    } else if(i == j) {
      # Diagonal: zero standard deviation for same location
      # (no travel time variability when origin equals destination)
      std_dev_matrix[i, j] = 0
    }
    # else: path_edges is empty and i != j, meaning no path exists
    # Matrix value remains Inf (initialized above)
  }
}

################################################################################
# 4. VALIDATION CHECK
################################################################################
# Verify that our shortest paths match the existing Distances.txt file
# This ensures consistency between mean and std dev matrices

cat("=== VALIDATION CHECK ===\n")

# Load existing Distances.txt file (created by Distance Matrix.R)
if(file.exists("Distances.txt")) {
  dist_matrix_original = as.matrix(read.table("Distances.txt", header = FALSE))
  
  # Recalculate mean distances from the same shortest paths we used above
  dist_matrix_from_paths = matrix(Inf, nrow = num_nodes, ncol = num_nodes)
  
  for(i in 1:num_nodes) {
    paths_from_i = shortest_paths(G, from = i, to = 1:num_nodes, mode = "out", output = "both")
    
    for(j in 1:num_nodes) {
      path_edges = paths_from_i$epath[[j]]
      
      if(length(path_edges) > 0) {
        # Sum mean travel times along the path
        mean_times = E(G)$weight[path_edges]
        dist_matrix_from_paths[i, j] = sum(mean_times)
      } else if(i == j) {
        dist_matrix_from_paths[i, j] = 0
      }
      # else remains Inf
    }
  }
  
  # Compare the two matrices
  max_diff = max(abs(dist_matrix_original - dist_matrix_from_paths)[is.finite(dist_matrix_original)])
  num_mismatches = sum(abs(dist_matrix_original - dist_matrix_from_paths) > 0.001, na.rm = TRUE)
  
  cat("Max difference between files:", max_diff, "\n")
  cat("Number of mismatches (diff > 0.001):", num_mismatches, "\n")
  
  if(max_diff < 0.001) {
    cat("✓ VALIDATION PASSED: Shortest paths match existing Distances.txt file!\n\n")
  } else {
    cat("✗ WARNING: Discrepancies found! Check if Distances.txt was created from same data.\n")
    cat("  Possible causes: Different input CSV, weekday vs weekend data, or data updates.\n\n")
  }
} else {
  cat("⚠ Distances.txt file not found in working directory - skipping validation check.\n")
  cat("  Run Distance Matrix.R first to generate this file.\n\n")
}

################################################################################
# 5. WRITE OUTPUT
################################################################################

# Write standard deviation matrix to file
# Format matches Distances.txt: space-separated values, no headers
write.table(std_dev_matrix, 
            "Distances_StdDev.txt", 
            col.names = FALSE, 
            row.names = FALSE)

################################################################################
# 6. SUMMARY STATISTICS
################################################################################

cat("=== STANDARD DEVIATION MATRIX SUMMARY ===\n")
cat("Dimensions:", nrow(std_dev_matrix), "x", ncol(std_dev_matrix), "\n")
cat("Min std dev (excluding diagonal):", 
    min(std_dev_matrix[std_dev_matrix > 0 & is.finite(std_dev_matrix)]), "seconds\n")
cat("Max std dev (excluding Inf):", 
    max(std_dev_matrix[is.finite(std_dev_matrix)]), "seconds\n")
cat("Number of Inf values (disconnected pairs):", 
    sum(is.infinite(std_dev_matrix)), "\n")
cat("Number of zero values (diagonal):", 
    sum(std_dev_matrix == 0), "\n")

cat("\n✓ Output written to: Distances_StdDev.txt\n")

################################################################################
# END OF SCRIPT
################################################################################