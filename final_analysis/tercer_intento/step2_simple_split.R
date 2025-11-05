# =============================================================================
# STEP 2: SIMPLE SPLIT AND COLLAPSE MUTATIONS
# =============================================================================

library(dplyr)
library(ggplot2)
library(viridis)
library(RColorBrewer)
library(stringr)

# Set working directory
setwd("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/tercer_intento")

cat("=== STEP 2: SIMPLE SPLIT AND COLLAPSE MUTATIONS ===\n")

# Create output directory
output_dir <- "step_by_step_analysis"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Create figures directory
figures_dir <- file.path(output_dir, "step2_figures")
if (!dir.exists(figures_dir)) {
  dir.create(figures_dir, recursive = TRUE)
}

# =============================================================================
# LOAD STEP 1 DATA
# =============================================================================

cat("Loading Step 1 data...\n")

# Load the original data from Step 1
original_data <- read.csv(file.path(output_dir, "step1_original_data.csv"), stringsAsFactors = FALSE)

# Convert column names back to original format
colnames(original_data)[1] <- "miRNA name"
colnames(original_data)[2] <- "pos:mut"

cat("✅ Step 1 data loaded successfully!\n")
cat("📊 Starting with:", nrow(original_data), "SNVs\n")

# =============================================================================
# ANALYZE MULTIPLE MUTATIONS
# =============================================================================

cat("\nAnalyzing multiple mutations...\n")

# Identify rows with multiple mutations
multi_mut_rows <- grepl(",", original_data$`pos:mut`)
cat("📊 Rows with multiple mutations:", sum(multi_mut_rows), "\n")
cat("📊 Percentage:", round(sum(multi_mut_rows)/nrow(original_data)*100, 1), "%\n")

# Count how many mutations per row
mutations_per_row <- str_count(original_data$`pos:mut`[multi_mut_rows], ",") + 1
cat("📊 Mutations per row (multiple mutation rows):\n")
print(table(mutations_per_row))

# =============================================================================
# SIMPLE SPLIT APPROACH
# =============================================================================

cat("\nStarting simple split process...\n")

# Start with single mutations
single_mut_data <- original_data[!multi_mut_rows, ]
cat("📊 Single mutations:", nrow(single_mut_data), "\n")

# Process multiple mutations in smaller batches
multi_mut_data <- original_data[multi_mut_rows, ]
cat("📊 Multiple mutations to process:", nrow(multi_mut_data), "\n")

# Create empty dataframe for split results
split_data <- single_mut_data

# Process in batches of 1000
batch_size <- 1000
n_batches <- ceiling(nrow(multi_mut_data) / batch_size)

cat("📊 Processing", n_batches, "batches of", batch_size, "rows each...\n")

for (batch in 1:n_batches) {
  start_idx <- (batch - 1) * batch_size + 1
  end_idx <- min(batch * batch_size, nrow(multi_mut_data))
  
  cat("  - Processing batch", batch, "of", n_batches, 
      "(", start_idx, "to", end_idx, ")\n")
  
  batch_data <- multi_mut_data[start_idx:end_idx, ]
  
  # Process each row in the batch
  for (i in 1:nrow(batch_data)) {
    row <- batch_data[i, ]
    mutations <- strsplit(row$`pos:mut`, ",")[[1]]
    mutations <- trimws(mutations)
    
    # Create new row for each mutation
    for (mut in mutations) {
      new_row <- row
      new_row$`pos:mut` <- mut
      split_data <- rbind(split_data, new_row)
    }
  }
  
  # Progress update every 10 batches
  if (batch %% 10 == 0) {
    cat("    - Progress: ", round(batch/n_batches*100, 1), "% complete\n")
  }
}

cat("✅ Split completed!\n")
cat("📊 After split - SNVs:", nrow(split_data), "\n")
cat("📊 Increase:", nrow(split_data) - nrow(original_data), "SNVs\n")

# =============================================================================
# COLLAPSE DUPLICATES
# =============================================================================

cat("\nCollapsing duplicates...\n")

# Get sample columns
sample_cols <- colnames(split_data)[!colnames(split_data) %in% c("miRNA name", "pos:mut")]

# Group by miRNA name and pos:mut, sum counts
cat("  - Grouping by miRNA name and pos:mut...\n")
collapse_data <- split_data %>%
  group_by(`miRNA name`, `pos:mut`) %>%
  summarise(
    across(all_of(sample_cols), sum, na.rm = TRUE),
    .groups = "drop"
  )

cat("✅ Collapse completed!\n")
cat("📊 After collapse - SNVs:", nrow(collapse_data), "\n")
cat("📊 Reduction:", nrow(split_data) - nrow(collapse_data), "SNVs\n")

# =============================================================================
# CREATE STEP 2 FIGURES
# =============================================================================

cat("\nCreating Step 2 figures...\n")

# Create split and collapse summary figure
p1 <- ggplot() +
  annotate("text", x = 0.5, y = 0.6, 
           label = paste0("SPLIT AND COLLAPSE RESULTS\n\n",
                         "• Original SNVs: ", format(nrow(original_data), big.mark = ","), "\n",
                         "• After split: ", format(nrow(split_data), big.mark = ","), "\n",
                         "• After collapse: ", format(nrow(collapse_data), big.mark = ","), "\n",
                         "• Net change: ", format(nrow(collapse_data) - nrow(original_data), big.mark = ","), "\n",
                         "• Unique miRNAs: ", format(length(unique(collapse_data$`miRNA name`)), big.mark = ",")), 
           size = 6, hjust = 0.5, vjust = 0.5, fontface = "bold", color = "white") +
  theme_void() +
  theme(plot.background = element_rect(fill = "#27ae60", color = "white", linewidth = 3)) +
  labs(title = "Step 2: Split and Collapse Results")

ggsave(file.path(figures_dir, "split_collapse_results.png"), p1, 
       width = 14, height = 10, dpi = 300)

# Create workflow comparison figure
workflow_data <- data.frame(
  Step = c("Original", "After Split", "After Collapse"),
  SNVs = c(nrow(original_data), nrow(split_data), nrow(collapse_data)),
  miRNAs = c(length(unique(original_data$`miRNA name`)), 
             length(unique(split_data$`miRNA name`)),
             length(unique(collapse_data$`miRNA name`)))
)

p2 <- ggplot(workflow_data, aes(x = Step, y = SNVs, fill = Step)) +
  geom_bar(stat = "identity", alpha = 0.8, color = "black", linewidth = 0.5) +
  scale_fill_manual(values = c("#2c3e50", "#e67e22", "#27ae60")) +
  labs(title = "SNV Count Through Split and Collapse Process",
       x = "Processing Step", 
       y = "Number of SNVs") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 18, face = "bold"),
        axis.text = element_text(size = 14),
        axis.title = element_text(size = 16),
        legend.position = "none") +
  geom_text(aes(label = format(SNVs, big.mark = ",")), vjust = -0.5, size = 6, fontface = "bold")

ggsave(file.path(figures_dir, "workflow_comparison.png"), p2, 
       width = 12, height = 8, dpi = 300)

# =============================================================================
# SAVE STEP 2 DATA
# =============================================================================

cat("\nSaving Step 2 data...\n")

# Save the split data
write.csv(split_data, file.path(output_dir, "step2_split_data.csv"), row.names = FALSE)

# Save the collapse data
write.csv(collapse_data, file.path(output_dir, "step2_collapse_data.csv"), row.names = FALSE)

# Save summary statistics
summary_stats <- data.frame(
  Metric = c("Original SNVs", "After Split SNVs", "After Collapse SNVs", 
             "Split Increase", "Collapse Reduction", "Net Change",
             "Original miRNAs", "After Collapse miRNAs"),
  Value = c(nrow(original_data), nrow(split_data), nrow(collapse_data),
           nrow(split_data) - nrow(original_data),
           nrow(split_data) - nrow(collapse_data),
           nrow(collapse_data) - nrow(original_data),
           length(unique(original_data$`miRNA name`)),
           length(unique(collapse_data$`miRNA name`))))
write.csv(summary_stats, file.path(output_dir, "step2_summary_stats.csv"), row.names = FALSE)

cat("✅ Step 2 data saved\n")

# =============================================================================
# FINAL SUMMARY
# =============================================================================

cat("\n=== STEP 2 COMPLETED ===\n")
cat("📊 Original SNVs: ", format(nrow(original_data), big.mark = ","), "\n")
cat("📊 After split: ", format(nrow(split_data), big.mark = ","), "\n")
cat("📊 After collapse: ", format(nrow(collapse_data), big.mark = ","), "\n")
cat("📊 Net change: ", format(nrow(collapse_data) - nrow(original_data), big.mark = ","), "\n")
cat("📁 Output directory: ", output_dir, "\n")
cat("📋 Figures created: ", length(list.files(figures_dir)), "\n")
cat("🎯 Ready for Step 3: VAF Calculation and Analysis!\n")









