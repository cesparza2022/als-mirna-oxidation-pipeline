# =============================================================================
# STEP 2B: SPLIT SMALL SAMPLE (VERIFICATION STEP)
# =============================================================================

library(dplyr)
library(ggplot2)
library(stringr)

# Set working directory
setwd("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/tercer_intento")

cat("=== STEP 2B: SPLIT SMALL SAMPLE ===\n")

# Create output directory
output_dir <- "step_by_step_analysis"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Create figures directory
figures_dir <- file.path(output_dir, "step2b_figures")
if (!dir.exists(figures_dir)) {
  dir.create(figures_dir, recursive = TRUE)
}

# =============================================================================
# LOAD STEP 2A DATA
# =============================================================================

cat("Loading Step 2A data...\n")

# Load the multiple mutations data from Step 2A
multi_mut_data <- read.csv(file.path(output_dir, "step2a_multiple_mutations.csv"), stringsAsFactors = FALSE)
single_mut_data <- read.csv(file.path(output_dir, "step2a_single_mutations.csv"), stringsAsFactors = FALSE)

cat("✅ Step 2A data loaded successfully!\n")
cat("📊 Single mutations:", nrow(single_mut_data), "\n")
cat("📊 Multiple mutations:", nrow(multi_mut_data), "\n")

# =============================================================================
# SPLIT SMALL SAMPLE
# =============================================================================

cat("\nSplitting small sample (first 100 rows)...\n")

# Take a small sample for testing
sample_size <- 100
sample_multi_mut <- multi_mut_data[1:sample_size, ]

cat("📊 Sample size:", nrow(sample_multi_mut), "rows\n")

# Show the sample
cat("📋 Sample multiple mutations to split:\n")
print(sample_multi_mut[, c(1, 2)])  # First two columns

# Split the sample
cat("\nSplitting sample...\n")
split_sample <- single_mut_data  # Start with single mutations

for (i in 1:nrow(sample_multi_mut)) {
  row <- sample_multi_mut[i, ]
  mutations <- strsplit(row[,2], ",")[[1]]  # Second column
  mutations <- trimws(mutations)
  
  cat("  - Row", i, ":", row[,2], "->", paste(mutations, collapse = ", "), "\n")
  
  for (mut in mutations) {
    new_row <- row
    new_row[,2] <- mut  # Second column
    split_sample <- rbind(split_sample, new_row)
  }
}

cat("✅ Sample split completed!\n")
cat("📊 After split - SNVs:", nrow(split_sample), "\n")
cat("📊 Increase:", nrow(split_sample) - nrow(single_mut_data), "SNVs\n")

# =============================================================================
# COLLAPSE SAMPLE
# =============================================================================

cat("\nCollapsing sample duplicates...\n")

# Get sample columns (all except first two)
sample_cols <- colnames(split_sample)[3:ncol(split_sample)]

# Group by first two columns, sum counts
collapse_sample <- split_sample %>%
  group_by(across(1:2)) %>%
  summarise(
    across(all_of(sample_cols), sum, na.rm = TRUE),
    .groups = "drop"
  )

cat("✅ Sample collapse completed!\n")
cat("📊 After collapse - SNVs:", nrow(collapse_sample), "\n")
cat("📊 Reduction:", nrow(split_sample) - nrow(collapse_sample), "SNVs\n")

# =============================================================================
# VERIFY RESULTS
# =============================================================================

cat("\nVerifying results...\n")

# Check for duplicates
duplicates <- collapse_sample %>%
  group_by(across(1:2)) %>%
  summarise(count = n(), .groups = "drop") %>%
  filter(count > 1)

if (nrow(duplicates) > 0) {
  cat("⚠️ Found", nrow(duplicates), "duplicates after collapse!\n")
  print(duplicates)
} else {
  cat("✅ No duplicates found after collapse!\n")
}

# Show some examples of the split results
cat("\n📋 Sample split results:\n")
sample_results <- collapse_sample[1:10, 1:2]  # First two columns
print(sample_results)

# =============================================================================
# CREATE VERIFICATION FIGURES
# =============================================================================

cat("\nCreating verification figures...\n")

# Create split sample summary figure
p1 <- ggplot() +
  annotate("text", x = 0.5, y = 0.6, 
           label = paste0("SMALL SAMPLE SPLIT RESULTS\n\n",
                         "• Sample size: ", nrow(sample_multi_mut), " rows\n",
                         "• Single mutations: ", nrow(single_mut_data), "\n",
                         "• After split: ", nrow(split_sample), "\n",
                         "• After collapse: ", nrow(collapse_sample), "\n",
                         "• Net change: ", nrow(collapse_sample) - nrow(single_mut_data), "\n",
                         "• Process verified: Ready for full split!"), 
           size = 6, hjust = 0.5, vjust = 0.5, fontface = "bold", color = "white") +
  theme_void() +
  theme(plot.background = element_rect(fill = "#27ae60", color = "white", linewidth = 3)) +
  labs(title = "Step 2B: Small Sample Split Results")

ggsave(file.path(figures_dir, "sample_split_results.png"), p1, 
       width = 14, height = 10, dpi = 300)

# =============================================================================
# SAVE SAMPLE DATA
# =============================================================================

cat("\nSaving sample data...\n")

# Save the sample data
write.csv(sample_multi_mut, file.path(output_dir, "step2b_sample_multiple_mutations.csv"), row.names = FALSE)
write.csv(split_sample, file.path(output_dir, "step2b_sample_split_data.csv"), row.names = FALSE)
write.csv(collapse_sample, file.path(output_dir, "step2b_sample_collapse_data.csv"), row.names = FALSE)

# Save summary statistics
summary_stats <- data.frame(
  Metric = c("Sample size", "Single mutations", "After split", "After collapse", 
             "Split increase", "Collapse reduction", "Net change"),
  Value = c(nrow(sample_multi_mut), nrow(single_mut_data), nrow(split_sample), 
           nrow(collapse_sample), nrow(split_sample) - nrow(single_mut_data),
           nrow(split_sample) - nrow(collapse_sample),
           nrow(collapse_sample) - nrow(single_mut_data)))
write.csv(summary_stats, file.path(output_dir, "step2b_summary_stats.csv"), row.names = FALSE)

cat("✅ Step 2B data saved\n")

# =============================================================================
# FINAL SUMMARY
# =============================================================================

cat("\n=== STEP 2B COMPLETED ===\n")
cat("📊 Sample size: ", nrow(sample_multi_mut), "rows\n")
cat("📊 After split: ", nrow(split_sample), "SNVs\n")
cat("📊 After collapse: ", nrow(collapse_sample), "SNVs\n")
cat("📊 Net change: ", nrow(collapse_sample) - nrow(single_mut_data), "SNVs\n")
cat("📁 Output directory: ", output_dir, "\n")
cat("📋 Figures created: ", length(list.files(figures_dir)), "\n")
cat("🎯 Process verified! Ready for Step 2C: Full split!\n")
