# =============================================================================
# CORRECT WORKFLOW ANALYSIS - STEP BY STEP WITH PROPER ORDER
# =============================================================================

library(dplyr)
library(ggplot2)
library(knitr)
library(rmarkdown)
library(gridExtra)
library(viridis)
library(RColorBrewer)
library(reshape2)
library(stringr)

# Set working directory
setwd("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/tercer_intento")

cat("=== CORRECT WORKFLOW ANALYSIS ===\n")

# Create output directory
output_dir <- "correct_workflow_analysis"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Create figures directory
figures_dir <- file.path(output_dir, "figures")
if (!dir.exists(figures_dir)) {
  dir.create(figures_dir, recursive = TRUE)
}

# =============================================================================
# STEP 1: LOAD ORIGINAL DATASET AND EXPLORE
# =============================================================================

cat("STEP 1: LOADING ORIGINAL DATASET\n")
cat("================================\n")

# Load the original dataset
original_file <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"

if (file.exists(original_file)) {
  cat("Loading original dataset...\n")
  
  # Load with proper column handling
  original_data <- read.table(original_file, 
                             sep = "\t", 
                             header = TRUE, 
                             stringsAsFactors = FALSE,
                             check.names = FALSE)
  
  cat("Original dataset loaded successfully!\n")
  cat("Dimensions:", nrow(original_data), "x", ncol(original_data), "\n")
  
  # Basic dataset information
  cat("\nDataset Structure:\n")
  cat("- Rows (SNVs):", nrow(original_data), "\n")
  cat("- Columns:", ncol(original_data), "\n")
  cat("- miRNA names:", length(unique(original_data$miRNA.name)), "\n")
  
  # Identify sample columns
  sample_cols <- colnames(original_data)[!colnames(original_data) %in% c("miRNA.name", "pos.mut")]
  count_cols <- sample_cols[!grepl("\\.\\.PM\\.1MM\\.2MM\\.$", sample_cols)]
  total_cols <- sample_cols[grepl("\\.\\.PM\\.1MM\\.2MM\\.$", sample_cols)]
  
  cat("- Sample count columns:", length(count_cols), "\n")
  cat("- Sample total columns:", length(total_cols), "\n")
  
  # Create dataset overview figure
  p1 <- ggplot() +
    annotate("text", x = 0.5, y = 0.7, 
             label = paste0("ORIGINAL DATASET OVERVIEW\n\n",
                           "• Total SNVs: ", nrow(original_data), "\n",
                           "• Unique miRNAs: ", length(unique(original_data$miRNA.name)), "\n",
                           "• Sample count columns: ", length(count_cols), "\n",
                           "• Sample total columns: ", length(total_cols), "\n",
                           "• File: miRNA_count.Q33.txt"), 
             size = 5, hjust = 0.5, vjust = 0.5, fontface = "bold") +
    theme_void() +
    theme(plot.background = element_rect(fill = "#f8f9fa", color = "black", size = 1)) +
    labs(title = "Step 1: Original Dataset Structure")
  
  ggsave(file.path(figures_dir, "step1_original_dataset_overview.png"), p1, 
         width = 12, height = 8, dpi = 300)
  
  # Create metadata analysis
  cat("\nAnalyzing sample metadata...\n")
  
  # Extract sample information from column names
  sample_info <- data.frame(
    sample_name = count_cols,
    stringsAsFactors = FALSE
  )
  
  # Identify groups based on sample names
  sample_info$group <- ifelse(grepl("control", sample_info$sample_name, ignore.case = TRUE), 
                             "Control", 
                             ifelse(grepl("ALS", sample_info$sample_name, ignore.case = TRUE), 
                                   "ALS", "Unknown"))
  
  # Count samples by group
  group_counts <- table(sample_info$group)
  cat("Sample distribution:\n")
  print(group_counts)
  
  # Create sample distribution figure
  p2 <- ggplot(sample_info, aes(x = group, fill = group)) +
    geom_bar(alpha = 0.8) +
    scale_fill_manual(values = c("ALS" = "#e74c3c", "Control" = "#3498db", "Unknown" = "#95a5a6")) +
    labs(title = "Sample Distribution by Group",
         x = "Group", 
         y = "Number of Samples") +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
          legend.position = "none") +
    geom_text(aes(label = ..count..), stat = "count", vjust = -0.5, size = 5, fontface = "bold")
  
  ggsave(file.path(figures_dir, "step1_sample_distribution.png"), p2, 
         width = 10, height = 6, dpi = 300)
  
  # Analyze mutation types in original data
  cat("\nAnalyzing mutation types in original data...\n")
  
  # Extract mutation types from pos.mut column
  mutation_types <- str_extract_all(original_data$pos.mut, "[A-Z]>[A-Z]", simplify = TRUE)
  mutation_types_flat <- as.vector(mutation_types)
  mutation_types_flat <- mutation_types_flat[mutation_types_flat != ""]
  
  mutation_counts <- table(mutation_types_flat)
  cat("Mutation types in original data:\n")
  print(mutation_counts)
  
  # Create mutation type distribution figure
  mutation_df <- data.frame(
    mutation_type = names(mutation_counts),
    count = as.numeric(mutation_counts)
  )
  
  p3 <- ggplot(mutation_df, aes(x = reorder(mutation_type, count), y = count, fill = mutation_type)) +
    geom_bar(stat = "identity", alpha = 0.8) +
    scale_fill_viridis_d() +
    labs(title = "Distribution of Mutation Types in Original Data",
         x = "Mutation Type", 
         y = "Count") +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
          axis.text.x = element_text(angle = 45, hjust = 1),
          legend.position = "none") +
    coord_flip()
  
  ggsave(file.path(figures_dir, "step1_mutation_types_distribution.png"), p3, 
         width = 10, height = 6, dpi = 300)
  
} else {
  cat("❌ Original dataset not found at:", original_file, "\n")
  stop("Cannot proceed without original dataset")
}

# =============================================================================
# STEP 2: SPLIT AND COLLAPSE MUTATIONS
# =============================================================================

cat("\n\nSTEP 2: SPLIT AND COLLAPSE MUTATIONS\n")
cat("=====================================\n")

# Split multiple mutations
cat("Splitting multiple mutations...\n")

# Create split function
split_mutations <- function(data) {
  # Identify rows with multiple mutations (containing commas)
  multi_mut_rows <- grepl(",", data$pos.mut)
  cat("Rows with multiple mutations:", sum(multi_mut_rows), "\n")
  
  # Process rows with multiple mutations
  split_data <- data[!multi_mut_rows, ]  # Start with single mutations
  
  if (sum(multi_mut_rows) > 0) {
    multi_mut_data <- data[multi_mut_rows, ]
    
    for (i in 1:nrow(multi_mut_data)) {
      row <- multi_mut_data[i, ]
      mutations <- strsplit(row$pos.mut, ",")[[1]]
      mutations <- trimws(mutations)
      
      for (mut in mutations) {
        new_row <- row
        new_row$pos.mut <- mut
        split_data <- rbind(split_data, new_row)
      }
    }
  }
  
  return(split_data)
}

# Apply split
split_data <- split_mutations(original_data)
cat("After split - SNVs:", nrow(split_data), "\n")

# Collapse duplicates
cat("Collapsing duplicates...\n")

# Group by miRNA.name and pos.mut, sum counts, take first total
collapse_data <- split_data %>%
  group_by(miRNA.name, pos.mut) %>%
  summarise(
    across(all_of(count_cols), sum, na.rm = TRUE),
    across(all_of(total_cols), first, na.rm = TRUE),
    .groups = "drop"
  )

cat("After collapse - SNVs:", nrow(collapse_data), "\n")

# Create split and collapse summary figure
p4 <- ggplot() +
  annotate("text", x = 0.5, y = 0.6, 
           label = paste0("SPLIT AND COLLAPSE RESULTS\n\n",
                         "• Original SNVs: ", nrow(original_data), "\n",
                         "• After split: ", nrow(split_data), "\n",
                         "• After collapse: ", nrow(collapse_data), "\n",
                         "• Net change: ", nrow(collapse_data) - nrow(original_data), "\n",
                         "• Unique miRNAs: ", length(unique(collapse_data$miRNA.name))), 
           size = 5, hjust = 0.5, vjust = 0.5, fontface = "bold") +
  theme_void() +
  theme(plot.background = element_rect(fill = "#e8f4fd", color = "black", size = 1)) +
  labs(title = "Step 2: Split and Collapse Results")

ggsave(file.path(figures_dir, "step2_split_collapse_results.png"), p4, 
       width = 12, height = 8, dpi = 300)

# =============================================================================
# STEP 3: CALCULATE VAFs AND ANALYZE DISTRIBUTIONS
# =============================================================================

cat("\n\nSTEP 3: CALCULATE VAFs AND ANALYZE DISTRIBUTIONS\n")
cat("==================================================\n")

# Calculate VAFs
cat("Calculating VAFs...\n")

vaf_data <- collapse_data

# Calculate VAF for each sample
for (i in 1:length(count_cols)) {
  count_col <- count_cols[i]
  total_col <- total_cols[i]
  vaf_col <- paste0("VAF_", gsub("\\..*", "", count_col))
  
  vaf_data[[vaf_col]] <- vaf_data[[count_col]] / vaf_data[[total_col]]
  vaf_data[[vaf_col]][is.na(vaf_data[[vaf_col]])] <- 0
  vaf_data[[vaf_col]][is.infinite(vaf_data[[vaf_col]])] <- 0
}

cat("VAFs calculated for", length(count_cols), "samples\n")

# Analyze VAF distributions
vaf_cols <- colnames(vaf_data)[grepl("^VAF_", colnames(vaf_data))]

# Calculate mean VAF per SNV
vaf_data$mean_vaf <- rowMeans(vaf_data[, vaf_cols], na.rm = TRUE)

# Create VAF distribution figure
p5 <- ggplot(vaf_data, aes(x = mean_vaf)) +
  geom_histogram(bins = 50, fill = "#3498db", alpha = 0.7, color = "black") +
  labs(title = "Distribution of Mean VAF Values",
       x = "Mean VAF", 
       y = "Count") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold")) +
  scale_x_log10()

ggsave(file.path(figures_dir, "step3_vaf_distribution.png"), p5, 
       width = 10, height = 6, dpi = 300)

# Analyze mutation types after split/collapse
mutation_types_after <- str_extract_all(vaf_data$pos.mut, "[A-Z]>[A-Z]", simplify = TRUE)
mutation_types_after_flat <- as.vector(mutation_types_after)
mutation_types_after_flat <- mutation_types_after_flat[mutation_types_after_flat != ""]

mutation_counts_after <- table(mutation_types_after_flat)
cat("Mutation types after split/collapse:\n")
print(mutation_counts_after)

# Create mutation type comparison
mutation_comparison <- data.frame(
  mutation_type = names(mutation_counts_after),
  count_after = as.numeric(mutation_counts_after),
  stringsAsFactors = FALSE
)

mutation_comparison$count_before <- mutation_counts[mutation_comparison$mutation_type]
mutation_comparison$count_before[is.na(mutation_comparison$count_before)] <- 0

p6 <- ggplot(mutation_comparison, aes(x = mutation_type)) +
  geom_bar(aes(y = count_before, fill = "Before"), stat = "identity", alpha = 0.7, position = "dodge") +
  geom_bar(aes(y = count_after, fill = "After"), stat = "identity", alpha = 0.7, position = "dodge") +
  scale_fill_manual(values = c("Before" = "#e74c3c", "After" = "#27ae60")) +
  labs(title = "Mutation Type Counts: Before vs After Split/Collapse",
       x = "Mutation Type", 
       y = "Count",
       fill = "Stage") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
        axis.text.x = element_text(angle = 45, hjust = 1)) +
  coord_flip()

ggsave(file.path(figures_dir, "step3_mutation_comparison.png"), p6, 
       width = 10, height = 6, dpi = 300)

# =============================================================================
# STEP 4: G>T FILTERING
# =============================================================================

cat("\n\nSTEP 4: G>T FILTERING\n")
cat("=====================\n")

# Filter for G>T mutations only
gt_data <- vaf_data[grepl(":GT", vaf_data$pos.mut), ]
cat("G>T SNVs:", nrow(gt_data), "\n")
cat("G>T miRNAs:", length(unique(gt_data$miRNA.name)), "\n")

# Create G>T filtering summary
p7 <- ggplot() +
  annotate("text", x = 0.5, y = 0.6, 
           label = paste0("G>T FILTERING RESULTS\n\n",
                         "• Total SNVs before: ", nrow(vaf_data), "\n",
                         "• G>T SNVs: ", nrow(gt_data), "\n",
                         "• G>T miRNAs: ", length(unique(gt_data$miRNA.name)), "\n",
                         "• Reduction: ", round((1 - nrow(gt_data)/nrow(vaf_data))*100, 1), "%\n",
                         "• Focus: Oxidative damage analysis"), 
           size = 5, hjust = 0.5, vjust = 0.5, fontface = "bold") +
  theme_void() +
  theme(plot.background = element_rect(fill = "#fff3cd", color = "black", size = 1)) +
  labs(title = "Step 4: G>T Filtering Results")

ggsave(file.path(figures_dir, "step4_gt_filtering_results.png"), p7, 
       width = 12, height = 8, dpi = 300)

# Analyze G>T VAF distribution
gt_data$mean_gt_vaf <- rowMeans(gt_data[, vaf_cols], na.rm = TRUE)

p8 <- ggplot(gt_data, aes(x = mean_gt_vaf)) +
  geom_histogram(bins = 50, fill = "#e67e22", alpha = 0.7, color = "black") +
  labs(title = "Distribution of Mean G>T VAF Values",
       x = "Mean G>T VAF", 
       y = "Count") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold")) +
  scale_x_log10()

ggsave(file.path(figures_dir, "step4_gt_vaf_distribution.png"), p8, 
       width = 10, height = 6, dpi = 300)

# =============================================================================
# STEP 5: SEED REGION FILTERING
# =============================================================================

cat("\n\nSTEP 5: SEED REGION FILTERING\n")
cat("==============================\n")

# Extract positions and filter for seed region (positions 2-8)
gt_data$position <- as.numeric(str_extract(gt_data$pos.mut, "^[0-9]+"))
seed_data <- gt_data[gt_data$position >= 2 & gt_data$position <= 8, ]

cat("Seed region G>T SNVs:", nrow(seed_data), "\n")
cat("Seed region G>T miRNAs:", length(unique(seed_data$miRNA.name)), "\n")

# Create seed region filtering summary
p9 <- ggplot() +
  annotate("text", x = 0.5, y = 0.6, 
           label = paste0("SEED REGION FILTERING RESULTS\n\n",
                         "• G>T SNVs before: ", nrow(gt_data), "\n",
                         "• Seed region G>T SNVs: ", nrow(seed_data), "\n",
                         "• Seed region G>T miRNAs: ", length(unique(seed_data$miRNA.name)), "\n",
                         "• Reduction: ", round((1 - nrow(seed_data)/nrow(gt_data))*100, 1), "%\n",
                         "• Focus: Functionally important region"), 
           size = 5, hjust = 0.5, vjust = 0.5, fontface = "bold") +
  theme_void() +
  theme(plot.background = element_rect(fill = "#d1ecf1", color = "black", size = 1)) +
  labs(title = "Step 5: Seed Region Filtering Results")

ggsave(file.path(figures_dir, "step5_seed_filtering_results.png"), p9, 
       width = 12, height = 8, dpi = 300)

# Analyze position distribution in seed region
p10 <- ggplot(seed_data, aes(x = factor(position))) +
  geom_bar(fill = "#8e44ad", alpha = 0.7, color = "black") +
  labs(title = "G>T SNV Distribution Across Seed Region Positions",
       x = "Position", 
       y = "Count") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"))

ggsave(file.path(figures_dir, "step5_seed_position_distribution.png"), p10, 
       width = 10, height = 6, dpi = 300)

# =============================================================================
# CREATE WORKFLOW SUMMARY
# =============================================================================

cat("\n\nCREATING WORKFLOW SUMMARY\n")
cat("==========================\n")

# Create comprehensive workflow summary
workflow_summary <- data.frame(
  Step = c("1. Original Dataset", "2. After Split", "3. After Collapse", "4. After VAF Calc", 
           "5. G>T Filtering", "6. Seed Region Filtering"),
  SNVs = c(nrow(original_data), nrow(split_data), nrow(collapse_data), nrow(vaf_data),
           nrow(gt_data), nrow(seed_data)),
  miRNAs = c(length(unique(original_data$miRNA.name)), 
             length(unique(split_data$miRNA.name)),
             length(unique(collapse_data$miRNA.name)),
             length(unique(vaf_data$miRNA.name)),
             length(unique(gt_data$miRNA.name)),
             length(unique(seed_data$miRNA.name))),
  Description = c("Raw miRNA count data", "Separated multiple mutations", 
                  "Aggregated duplicates", "Added VAF calculations",
                  "Oxidative damage focus", "Functionally important region")
)

# Save workflow summary
write.csv(workflow_summary, file.path(output_dir, "workflow_summary.csv"), row.names = FALSE)

# Create final workflow visualization
p11 <- ggplot(workflow_summary, aes(x = Step, y = SNVs, fill = Step)) +
  geom_bar(stat = "identity", alpha = 0.8, color = "black") +
  scale_fill_viridis_d() +
  labs(title = "Complete Data Processing Workflow",
       x = "Processing Step", 
       y = "Number of SNVs") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none") +
  geom_text(aes(label = SNVs), vjust = -0.5, size = 4, fontface = "bold")

ggsave(file.path(figures_dir, "complete_workflow_summary.png"), p11, 
       width = 14, height = 8, dpi = 300)

# =============================================================================
# SAVE PROCESSED DATA
# =============================================================================

cat("\nSaving processed data...\n")

# Save the final processed dataset
write.csv(seed_data, file.path(output_dir, "final_processed_data.csv"), row.names = FALSE)

# Save intermediate datasets
write.csv(original_data, file.path(output_dir, "original_data.csv"), row.names = FALSE)
write.csv(split_data, file.path(output_dir, "split_data.csv"), row.names = FALSE)
write.csv(collapse_data, file.path(output_dir, "collapse_data.csv"), row.names = FALSE)
write.csv(vaf_data, file.path(output_dir, "vaf_data.csv"), row.names = FALSE)
write.csv(gt_data, file.path(output_dir, "gt_data.csv"), row.names = FALSE)

cat("✅ All processed data saved\n")

# =============================================================================
# FINAL SUMMARY
# =============================================================================

cat("\n=== CORRECT WORKFLOW ANALYSIS COMPLETED ===\n")
cat("📊 Final dataset: ", nrow(seed_data), " SNVs, ", length(unique(seed_data$miRNA.name)), " miRNAs\n")
cat("📁 Output directory: ", output_dir, "\n")
cat("📋 Figures created: ", length(list.files(figures_dir)), "\n")
cat("🎯 Ready for detailed analysis!\n")

cat("\nNext steps:\n")
cat("1. Positional analysis with this clean dataset\n")
cat("2. Statistical comparisons between groups\n")
cat("3. Heatmaps and clustering\n")
cat("4. Functional analysis\n")
cat("5. Clinical correlations\n")









