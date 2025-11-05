# =============================================================================
# STEP 1: LOAD AND EXPLORE ORIGINAL DATASET
# =============================================================================

library(dplyr)
library(ggplot2)
library(viridis)
library(RColorBrewer)
library(stringr)

# Set working directory
setwd("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/tercer_intento")

cat("=== STEP 1: LOAD AND EXPLORE ORIGINAL DATASET ===\n")

# Create output directory
output_dir <- "step_by_step_analysis"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Create figures directory
figures_dir <- file.path(output_dir, "step1_figures")
if (!dir.exists(figures_dir)) {
  dir.create(figures_dir, recursive = TRUE)
}

# =============================================================================
# LOAD ORIGINAL DATASET
# =============================================================================

cat("Loading original dataset...\n")

# Load the original dataset
original_file <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"

if (file.exists(original_file)) {
  # Load with proper column handling
  original_data <- read.table(original_file, 
                             sep = "\t", 
                             header = TRUE, 
                             stringsAsFactors = FALSE,
                             check.names = FALSE)
  
  cat("✅ Original dataset loaded successfully!\n")
  cat("📊 Dimensions:", nrow(original_data), "x", ncol(original_data), "\n")
  
  # Use correct column names
  sample_cols <- colnames(original_data)[!colnames(original_data) %in% c("miRNA name", "pos:mut")]
  
  cat("📋 Dataset Structure:\n")
  cat("  - Rows (SNVs):", nrow(original_data), "\n")
  cat("  - Columns:", ncol(original_data), "\n")
  cat("  - miRNA names:", length(unique(original_data$`miRNA name`)), "\n")
  cat("  - Sample columns:", length(sample_cols), "\n")
  
} else {
  cat("❌ Original dataset not found at:", original_file, "\n")
  stop("Cannot proceed without original dataset")
}

# =============================================================================
# CREATE DATASET OVERVIEW FIGURE
# =============================================================================

cat("\nCreating dataset overview figure...\n")

# Create dataset overview figure with better colors and readability
p1 <- ggplot() +
  annotate("text", x = 0.5, y = 0.7, 
           label = paste0("ORIGINAL DATASET OVERVIEW\n\n",
                         "• Total SNVs: ", format(nrow(original_data), big.mark = ","), "\n",
                         "• Unique miRNAs: ", format(length(unique(original_data$`miRNA name`)), big.mark = ","), "\n",
                         "• Sample columns: ", format(length(sample_cols), big.mark = ","), "\n",
                         "• File: miRNA_count.Q33.txt\n",
                         "• Format: Count data only"), 
           size = 6, hjust = 0.5, vjust = 0.5, fontface = "bold", color = "white") +
  theme_void() +
  theme(plot.background = element_rect(fill = "#2c3e50", color = "white", linewidth = 3)) +
  labs(title = "Step 1: Original Dataset Structure")

ggsave(file.path(figures_dir, "dataset_overview.png"), p1, 
       width = 14, height = 10, dpi = 300)

# =============================================================================
# ANALYZE SAMPLE METADATA
# =============================================================================

cat("Analyzing sample metadata...\n")

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
cat("📊 Sample distribution:\n")
print(group_counts)

# Create sample distribution figure with better colors and readability
p2 <- ggplot(sample_info, aes(x = group, fill = group)) +
  geom_bar(alpha = 0.8, color = "black", linewidth = 0.5) +
  scale_fill_manual(values = c("ALS" = "#e74c3c", "Control" = "#27ae60", "Unknown" = "#95a5a6")) +
  labs(title = "Sample Distribution by Group",
       x = "Group", 
       y = "Number of Samples") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 18, face = "bold"),
        axis.text = element_text(size = 14),
        axis.title = element_text(size = 16),
        legend.position = "none") +
  geom_text(aes(label = after_stat(count)), stat = "count", vjust = -0.5, size = 8, fontface = "bold")

ggsave(file.path(figures_dir, "sample_distribution.png"), p2, 
       width = 12, height = 8, dpi = 300)

# =============================================================================
# ANALYZE POSITION DISTRIBUTION
# =============================================================================

cat("Analyzing position distribution...\n")

# Extract positions from pos:mut column
positions <- str_extract(original_data$`pos:mut`, "^[0-9]+")
positions <- as.numeric(positions[!is.na(positions)])

cat("📊 Position analysis:\n")
cat("  - Position range:", min(positions), "to", max(positions), "\n")
cat("  - Unique positions:", length(unique(positions)), "\n")

# Create position distribution figure
position_df <- data.frame(position = positions)

p3 <- ggplot(position_df, aes(x = factor(position))) +
  geom_bar(fill = "#8e44ad", alpha = 0.8, color = "black", linewidth = 0.3) +
  labs(title = "Distribution of Positions in Original Data",
       x = "Position", 
       y = "Count") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 18, face = "bold"),
        axis.text = element_text(size = 12),
        axis.title = element_text(size = 16)) +
  scale_x_discrete(breaks = seq(0, max(positions), by = 2))

ggsave(file.path(figures_dir, "position_distribution.png"), p3, 
       width = 14, height = 8, dpi = 300)

# =============================================================================
# ANALYZE MUTATION TYPES
# =============================================================================

cat("Analyzing mutation types...\n")

# Extract mutation types from pos:mut column (format: position:mutation)
mutation_types <- str_extract(original_data$`pos:mut`, "[A-Z]{2}$")
mutation_types <- mutation_types[!is.na(mutation_types)]

if (length(mutation_types) > 0) {
  mutation_counts <- table(mutation_types)
  cat("📊 Mutation types in original data:\n")
  print(mutation_counts)
  
  # Create mutation type distribution figure
  mutation_df <- data.frame(
    mutation_type = names(mutation_counts),
    count = as.numeric(mutation_counts)
  )
  
  p4 <- ggplot(mutation_df, aes(x = reorder(mutation_type, count), y = count, fill = mutation_type)) +
    geom_bar(stat = "identity", alpha = 0.8, color = "black", linewidth = 0.3) +
    scale_fill_brewer(palette = "Set3") +
    labs(title = "Distribution of Mutation Types in Original Data",
         x = "Mutation Type", 
         y = "Count") +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5, size = 18, face = "bold"),
          axis.text = element_text(size = 14),
          axis.title = element_text(size = 16),
          legend.position = "none") +
    coord_flip()
  
  ggsave(file.path(figures_dir, "mutation_types_distribution.png"), p4, 
         width = 12, height = 8, dpi = 300)
} else {
  cat("⚠️ No mutation types found\n")
}

# =============================================================================
# ANALYZE MULTIPLE MUTATIONS
# =============================================================================

cat("Analyzing multiple mutations...\n")

# Check for multiple mutations (comma-separated)
multi_mut_rows <- grepl(",", original_data$`pos:mut`)
cat("📊 Multiple mutations analysis:\n")
cat("  - Rows with multiple mutations:", sum(multi_mut_rows), "\n")
cat("  - Percentage:", round(sum(multi_mut_rows)/nrow(original_data)*100, 1), "%\n")

if (sum(multi_mut_rows) > 0) {
  # Show sample rows with multiple mutations
  cat("  - Sample rows with multiple mutations:\n")
  print(head(original_data[multi_mut_rows, c("miRNA name", "pos:mut")], 5))
  
  # Create multiple mutations summary figure
  p5 <- ggplot() +
    annotate("text", x = 0.5, y = 0.6, 
             label = paste0("MULTIPLE MUTATIONS ANALYSIS\n\n",
                           "• Total rows: ", format(nrow(original_data), big.mark = ","), "\n",
                           "• Rows with multiple mutations: ", format(sum(multi_mut_rows), big.mark = ","), "\n",
                           "• Percentage: ", round(sum(multi_mut_rows)/nrow(original_data)*100, 1), "%\n",
                           "• These will be split in Step 2"), 
             size = 6, hjust = 0.5, vjust = 0.5, fontface = "bold", color = "white") +
    theme_void() +
    theme(plot.background = element_rect(fill = "#e67e22", color = "white", linewidth = 3)) +
    labs(title = "Multiple Mutations Analysis")
  
  ggsave(file.path(figures_dir, "multiple_mutations_analysis.png"), p5, 
         width = 14, height = 10, dpi = 300)
}

# =============================================================================
# SAVE STEP 1 DATA
# =============================================================================

cat("\nSaving Step 1 data...\n")

# Save the original data
write.csv(original_data, file.path(output_dir, "step1_original_data.csv"), row.names = FALSE)

# Save sample info
write.csv(sample_info, file.path(output_dir, "step1_sample_info.csv"), row.names = FALSE)

# Save summary statistics
summary_stats <- data.frame(
  Metric = c("Total SNVs", "Unique miRNAs", "Sample columns", "ALS samples", "Control samples", 
             "Position range", "Unique positions", "Multiple mutation rows", "Multiple mutation %"),
  Value = c(nrow(original_data), 
           length(unique(original_data$`miRNA name`)), 
           length(sample_cols), 
           group_counts["ALS"], 
           group_counts["Control"],
           paste0(min(positions), "-", max(positions)), 
           length(unique(positions)),
           sum(multi_mut_rows), 
           round(sum(multi_mut_rows)/nrow(original_data)*100, 1)))
write.csv(summary_stats, file.path(output_dir, "step1_summary_stats.csv"), row.names = FALSE)

cat("✅ Step 1 data saved\n")

# =============================================================================
# FINAL SUMMARY
# =============================================================================

cat("\n=== STEP 1 COMPLETED ===\n")
cat("📊 Original dataset: ", format(nrow(original_data), big.mark = ","), " SNVs\n")
cat("📊 Unique miRNAs: ", format(length(unique(original_data$`miRNA name`)), big.mark = ","), "\n")
cat("📊 Samples: ", group_counts["ALS"], " ALS, ", group_counts["Control"], " Control\n")
cat("📁 Output directory: ", output_dir, "\n")
cat("📋 Figures created: ", length(list.files(figures_dir)), "\n")
cat("🎯 Ready for Step 2: Split and Collapse!\n")
