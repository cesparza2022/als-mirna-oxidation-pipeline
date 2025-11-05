# =============================================================================
# CORRECT DATA STRUCTURE WORKFLOW - USING ACTUAL COLUMN NAMES
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

cat("=== CORRECT DATA STRUCTURE WORKFLOW ===\n")

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
  
  # Use correct column names
  sample_cols <- colnames(original_data)[!colnames(original_data) %in% c("miRNA name", "pos:mut")]
  
  cat("Dataset Structure:\n")
  cat("- Rows (SNVs):", nrow(original_data), "\n")
  cat("- Columns:", ncol(original_data), "\n")
  cat("- miRNA names:", length(unique(original_data$`miRNA name`)), "\n")
  cat("- Sample columns:", length(sample_cols), "\n")
  
  # Create dataset overview figure with better colors
  p1 <- ggplot() +
    annotate("text", x = 0.5, y = 0.7, 
             label = paste0("ORIGINAL DATASET OVERVIEW\n\n",
                           "• Total SNVs: ", nrow(original_data), "\n",
                           "• Unique miRNAs: ", length(unique(original_data$`miRNA name`)), "\n",
                           "• Sample columns: ", length(sample_cols), "\n",
                           "• File: miRNA_count.Q33.txt\n",
                           "• Format: Count data only"), 
             size = 5, hjust = 0.5, vjust = 0.5, fontface = "bold", color = "white") +
    theme_void() +
    theme(plot.background = element_rect(fill = "#2c3e50", color = "white", linewidth = 2)) +
    labs(title = "Step 1: Original Dataset Structure")
  
  ggsave(file.path(figures_dir, "step1_original_dataset_overview.png"), p1, 
         width = 12, height = 8, dpi = 300)
  
  # Analyze sample metadata
  cat("\nAnalyzing sample metadata...\n")
  
  # Extract sample information from column names
  sample_info <- data.frame(
    sample_name = sample_cols,
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
  
  # Create sample distribution figure with better colors
  p2 <- ggplot(sample_info, aes(x = group, fill = group)) +
    geom_bar(alpha = 0.8, color = "black", linewidth = 0.5) +
    scale_fill_manual(values = c("ALS" = "#e74c3c", "Control" = "#27ae60", "Unknown" = "#95a5a6")) +
    labs(title = "Sample Distribution by Group",
         x = "Group", 
         y = "Number of Samples") +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
          axis.text = element_text(size = 12),
          axis.title = element_text(size = 14),
          legend.position = "none") +
    geom_text(aes(label = after_stat(count)), stat = "count", vjust = -0.5, size = 6, fontface = "bold")
  
  ggsave(file.path(figures_dir, "step1_sample_distribution.png"), p2, 
         width = 10, height = 6, dpi = 300)
  
  # Analyze mutation types in original data
  cat("\nAnalyzing mutation types in original data...\n")
  
  # Extract mutation types from pos:mut column
  mutation_types <- str_extract_all(original_data$`pos:mut`, "[A-Z]>[A-Z]", simplify = TRUE)
  mutation_types_flat <- as.vector(mutation_types)
  mutation_types_flat <- mutation_types_flat[mutation_types_flat != ""]
  
  if (length(mutation_types_flat) > 0) {
    mutation_counts <- table(mutation_types_flat)
    cat("Mutation types in original data:\n")
    print(mutation_counts)
    
    # Create mutation type distribution figure with better colors
    mutation_df <- data.frame(
      mutation_type = names(mutation_counts),
      count = as.numeric(mutation_counts)
    )
    
    p3 <- ggplot(mutation_df, aes(x = reorder(mutation_type, count), y = count, fill = mutation_type)) +
      geom_bar(stat = "identity", alpha = 0.8, color = "black", linewidth = 0.3) +
      scale_fill_brewer(palette = "Set3") +
      labs(title = "Distribution of Mutation Types in Original Data",
           x = "Mutation Type", 
           y = "Count") +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
            axis.text = element_text(size = 12),
            axis.title = element_text(size = 14),
            legend.position = "none") +
      coord_flip()
    
    ggsave(file.path(figures_dir, "step1_mutation_types_distribution.png"), p3, 
           width = 10, height = 6, dpi = 300)
  } else {
    cat("No mutation types found in pos:mut column\n")
    
    # Check what's actually in the pos:mut column
    cat("Sample values from pos:mut column:\n")
    print(unique(original_data$`pos:mut`)[1:20])
    
    # Create a figure showing the actual content
    p3 <- ggplot() +
      annotate("text", x = 0.5, y = 0.5, 
               label = paste0("pos:mut Column Content Analysis\n\n",
                             "Sample values:\n",
                             paste(unique(original_data$`pos:mut`)[1:10], collapse = "\n"),
                             "\n\nThis appears to be position:mutation format\n",
                             "not A>B mutation type format"), 
               size = 4, hjust = 0.5, vjust = 0.5) +
      theme_void() +
      theme(plot.background = element_rect(fill = "#f39c12", color = "black", linewidth = 1)) +
      labs(title = "pos:mut Column Analysis")
    
    ggsave(file.path(figures_dir, "step1_mutation_types_distribution.png"), p3, 
           width = 12, height = 8, dpi = 300)
  }
  
  # Analyze position distribution
  cat("\nAnalyzing position distribution...\n")
  
  # Extract positions from pos:mut column
  positions <- str_extract(original_data$`pos:mut`, "^[0-9]+")
  positions <- as.numeric(positions[!is.na(positions)])
  
  if (length(positions) > 0) {
    cat("Position range:", min(positions), "to", max(positions), "\n")
    cat("Unique positions:", length(unique(positions)), "\n")
    
    # Create position distribution figure
    position_df <- data.frame(position = positions)
    
    p4 <- ggplot(position_df, aes(x = factor(position))) +
      geom_bar(fill = "#8e44ad", alpha = 0.8, color = "black", linewidth = 0.3) +
      labs(title = "Distribution of Positions in Original Data",
           x = "Position", 
           y = "Count") +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
            axis.text = element_text(size = 10),
            axis.title = element_text(size = 14)) +
      scale_x_discrete(breaks = seq(0, max(positions), by = 5))
    
    ggsave(file.path(figures_dir, "step1_position_distribution.png"), p4, 
           width = 12, height = 6, dpi = 300)
  }
  
} else {
  cat("❌ Original dataset not found at:", original_file, "\n")
  stop("Cannot proceed without original dataset")
}

# =============================================================================
# STEP 2: SPLIT AND COLLAPSE MUTATIONS
# =============================================================================

cat("\n\nSTEP 2: SPLIT AND COLLAPSE MUTATIONS\n")
cat("=====================================\n")

# Check if there are multiple mutations in pos:mut column
cat("Checking for multiple mutations...\n")

# Look for commas in pos:mut column
multi_mut_rows <- grepl(",", original_data$`pos:mut`)
cat("Rows with multiple mutations:", sum(multi_mut_rows), "\n")

if (sum(multi_mut_rows) > 0) {
  cat("Sample rows with multiple mutations:\n")
  print(head(original_data[multi_mut_rows, c("miRNA name", "pos:mut")], 5))
  
  # Split multiple mutations
  cat("Splitting multiple mutations...\n")
  
  split_data <- original_data[!multi_mut_rows, ]  # Start with single mutations
  
  multi_mut_data <- original_data[multi_mut_rows, ]
  
  for (i in 1:nrow(multi_mut_data)) {
    row <- multi_mut_data[i, ]
    mutations <- strsplit(row$`pos:mut`, ",")[[1]]
    mutations <- trimws(mutations)
    
    for (mut in mutations) {
      new_row <- row
      new_row$`pos:mut` <- mut
      split_data <- rbind(split_data, new_row)
    }
  }
  
  cat("After split - SNVs:", nrow(split_data), "\n")
} else {
  cat("No multiple mutations found. Skipping split step.\n")
  split_data <- original_data
}

# Collapse duplicates
cat("Collapsing duplicates...\n")

# Group by miRNA name and pos:mut, sum counts
collapse_data <- split_data %>%
  group_by(`miRNA name`, `pos:mut`) %>%
  summarise(
    across(all_of(sample_cols), sum, na.rm = TRUE),
    .groups = "drop"
  )

cat("After collapse - SNVs:", nrow(collapse_data), "\n")

# Create split and collapse summary figure
p5 <- ggplot() +
  annotate("text", x = 0.5, y = 0.6, 
           label = paste0("SPLIT AND COLLAPSE RESULTS\n\n",
                         "• Original SNVs: ", nrow(original_data), "\n",
                         "• After split: ", nrow(split_data), "\n",
                         "• After collapse: ", nrow(collapse_data), "\n",
                         "• Net change: ", nrow(collapse_data) - nrow(original_data), "\n",
                         "• Unique miRNAs: ", length(unique(collapse_data$`miRNA name`))), 
           size = 5, hjust = 0.5, vjust = 0.5, fontface = "bold", color = "white") +
  theme_void() +
  theme(plot.background = element_rect(fill = "#27ae60", color = "white", linewidth = 2)) +
  labs(title = "Step 2: Split and Collapse Results")

ggsave(file.path(figures_dir, "step2_split_collapse_results.png"), p5, 
       width = 12, height = 8, dpi = 300)

# =============================================================================
# STEP 3: G>T FILTERING
# =============================================================================

cat("\n\nSTEP 3: G>T FILTERING\n")
cat("=====================\n")

# Filter for G>T mutations only
gt_data <- collapse_data[grepl(":GT", collapse_data$`pos:mut`), ]
cat("G>T SNVs:", nrow(gt_data), "\n")
cat("G>T miRNAs:", length(unique(gt_data$`miRNA name`)), "\n")

# Create G>T filtering summary
p6 <- ggplot() +
  annotate("text", x = 0.5, y = 0.6, 
           label = paste0("G>T FILTERING RESULTS\n\n",
                         "• Total SNVs before: ", nrow(collapse_data), "\n",
                         "• G>T SNVs: ", nrow(gt_data), "\n",
                         "• G>T miRNAs: ", length(unique(gt_data$`miRNA name`)), "\n",
                         "• Reduction: ", round((1 - nrow(gt_data)/nrow(collapse_data))*100, 1), "%\n",
                         "• Focus: Oxidative damage analysis"), 
           size = 5, hjust = 0.5, vjust = 0.5, fontface = "bold", color = "white") +
  theme_void() +
  theme(plot.background = element_rect(fill = "#e67e22", color = "white", linewidth = 2)) +
  labs(title = "Step 3: G>T Filtering Results")

ggsave(file.path(figures_dir, "step3_gt_filtering_results.png"), p6, 
       width = 12, height = 8, dpi = 300)

# =============================================================================
# STEP 4: SEED REGION FILTERING
# =============================================================================

cat("\n\nSTEP 4: SEED REGION FILTERING\n")
cat("==============================\n")

# Extract positions and filter for seed region (positions 2-8)
gt_data$position <- as.numeric(str_extract(gt_data$`pos:mut`, "^[0-9]+"))
seed_data <- gt_data[gt_data$position >= 2 & gt_data$position <= 8, ]

cat("Seed region G>T SNVs:", nrow(seed_data), "\n")
cat("Seed region G>T miRNAs:", length(unique(seed_data$`miRNA name`)), "\n")

# Create seed region filtering summary
p7 <- ggplot() +
  annotate("text", x = 0.5, y = 0.6, 
           label = paste0("SEED REGION FILTERING RESULTS\n\n",
                         "• G>T SNVs before: ", nrow(gt_data), "\n",
                         "• Seed region G>T SNVs: ", nrow(seed_data), "\n",
                         "• Seed region G>T miRNAs: ", length(unique(seed_data$`miRNA name`)), "\n",
                         "• Reduction: ", round((1 - nrow(seed_data)/nrow(gt_data))*100, 1), "%\n",
                         "• Focus: Functionally important region"), 
           size = 5, hjust = 0.5, vjust = 0.5, fontface = "bold", color = "white") +
  theme_void() +
  theme(plot.background = element_rect(fill = "#8e44ad", color = "white", linewidth = 2)) +
  labs(title = "Step 4: Seed Region Filtering Results")

ggsave(file.path(figures_dir, "step4_seed_filtering_results.png"), p7, 
       width = 12, height = 8, dpi = 300)

# Analyze position distribution in seed region
p8 <- ggplot(seed_data, aes(x = factor(position))) +
  geom_bar(fill = "#e74c3c", alpha = 0.8, color = "black", linewidth = 0.3) +
  labs(title = "G>T SNV Distribution Across Seed Region Positions",
       x = "Position", 
       y = "Count") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
        axis.text = element_text(size = 12),
        axis.title = element_text(size = 14))

ggsave(file.path(figures_dir, "step4_seed_position_distribution.png"), p8, 
       width = 10, height = 6, dpi = 300)

# =============================================================================
# CREATE COMPREHENSIVE WORKFLOW SUMMARY
# =============================================================================

cat("\n\nCREATING COMPREHENSIVE WORKFLOW SUMMARY\n")
cat("==========================================\n")

# Create comprehensive workflow summary
workflow_summary <- data.frame(
  Step = c("1. Original Dataset", "2. After Split", "3. After Collapse", 
           "4. G>T Filtering", "5. Seed Region Filtering"),
  SNVs = c(nrow(original_data), nrow(split_data), nrow(collapse_data),
           nrow(gt_data), nrow(seed_data)),
  miRNAs = c(length(unique(original_data$`miRNA name`)), 
             length(unique(split_data$`miRNA name`)),
             length(unique(collapse_data$`miRNA name`)),
             length(unique(gt_data$`miRNA name`)),
             length(unique(seed_data$`miRNA name`))),
  Description = c("Raw miRNA count data", "Separated multiple mutations", 
                  "Aggregated duplicates", "Oxidative damage focus", 
                  "Functionally important region")
)

# Save workflow summary
write.csv(workflow_summary, file.path(output_dir, "workflow_summary.csv"), row.names = FALSE)

# Create final workflow visualization with better colors
p9 <- ggplot(workflow_summary, aes(x = Step, y = SNVs, fill = Step)) +
  geom_bar(stat = "identity", alpha = 0.8, color = "black", linewidth = 0.5) +
  scale_fill_manual(values = c("#2c3e50", "#27ae60", "#3498db", "#e67e22", "#8e44ad")) +
  labs(title = "Complete Data Processing Workflow",
       x = "Processing Step", 
       y = "Number of SNVs") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 18, face = "bold"),
        axis.text = element_text(size = 12),
        axis.title = element_text(size = 14),
        legend.position = "none") +
  geom_text(aes(label = SNVs), vjust = -0.5, size = 5, fontface = "bold") +
  scale_x_discrete(labels = c("Original", "Split", "Collapse", "G>T Filter", "Seed Filter"))

ggsave(file.path(figures_dir, "complete_workflow_summary.png"), p9, 
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
write.csv(gt_data, file.path(output_dir, "gt_data.csv"), row.names = FALSE)

cat("✅ All processed data saved\n")

# =============================================================================
# FINAL SUMMARY
# =============================================================================

cat("\n=== CORRECT WORKFLOW ANALYSIS COMPLETED ===\n")
cat("📊 Final dataset: ", nrow(seed_data), " SNVs, ", length(unique(seed_data$`miRNA name`)), " miRNAs\n")
cat("📁 Output directory: ", output_dir, "\n")
cat("📋 Figures created: ", length(list.files(figures_dir)), "\n")
cat("🎯 Ready for detailed analysis!\n")

cat("\nNext steps:\n")
cat("1. Positional analysis with this clean dataset\n")
cat("2. Statistical comparisons between groups\n")
cat("3. Heatmaps and clustering\n")
cat("4. Functional analysis\n")
cat("5. Clinical correlations\n")









