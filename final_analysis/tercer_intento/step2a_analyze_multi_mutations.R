# =============================================================================
# STEP 2A: ANALYZE MULTIPLE MUTATIONS (VERIFICATION STEP)
# =============================================================================

library(dplyr)
library(ggplot2)
library(stringr)

# Set working directory
setwd("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/tercer_intento")

cat("=== STEP 2A: ANALYZE MULTIPLE MUTATIONS ===\n")

# Create output directory
output_dir <- "step_by_step_analysis"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Create figures directory
figures_dir <- file.path(output_dir, "step2a_figures")
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

# Show some examples
cat("\n📋 Sample multiple mutations (first 10):\n")
sample_multi <- original_data[multi_mut_rows, ][1:10, c("miRNA name", "pos:mut")]
print(sample_multi)

# =============================================================================
# CREATE ANALYSIS FIGURES
# =============================================================================

cat("\nCreating analysis figures...\n")

# Create multiple mutations summary figure
p1 <- ggplot() +
  annotate("text", x = 0.5, y = 0.6, 
           label = paste0("MULTIPLE MUTATIONS ANALYSIS\n\n",
                         "• Total rows: ", format(nrow(original_data), big.mark = ","), "\n",
                         "• Rows with multiple mutations: ", format(sum(multi_mut_rows), big.mark = ","), "\n",
                         "• Percentage: ", round(sum(multi_mut_rows)/nrow(original_data)*100, 1), "%\n",
                         "• All multiple mutations have exactly 2 mutations\n",
                         "• These will be split in the next step"), 
           size = 6, hjust = 0.5, vjust = 0.5, fontface = "bold", color = "white") +
  theme_void() +
  theme(plot.background = element_rect(fill = "#e67e22", color = "white", linewidth = 3)) +
  labs(title = "Step 2A: Multiple Mutations Analysis")

ggsave(file.path(figures_dir, "multiple_mutations_analysis.png"), p1, 
       width = 14, height = 10, dpi = 300)

# Create mutations per row figure
mutations_df <- data.frame(
  mutations_per_row = mutations_per_row
)

p2 <- ggplot(mutations_df, aes(x = factor(mutations_per_row))) +
  geom_bar(fill = "#e74c3c", alpha = 0.8, color = "black", linewidth = 0.3) +
  labs(title = "Number of Mutations per Row (Multiple Mutation Rows Only)",
       x = "Number of Mutations", 
       y = "Count") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
        axis.text = element_text(size = 14),
        axis.title = element_text(size = 16))

ggsave(file.path(figures_dir, "mutations_per_row.png"), p2, 
       width = 10, height = 6, dpi = 300)

# =============================================================================
# SAVE ANALYSIS DATA
# =============================================================================

cat("\nSaving analysis data...\n")

# Save the multiple mutations data for inspection
multi_mut_data <- original_data[multi_mut_rows, ]
write.csv(multi_mut_data, file.path(output_dir, "step2a_multiple_mutations.csv"), row.names = FALSE)

# Save single mutations data
single_mut_data <- original_data[!multi_mut_rows, ]
write.csv(single_mut_data, file.path(output_dir, "step2a_single_mutations.csv"), row.names = FALSE)

# Save summary statistics
summary_stats <- data.frame(
  Metric = c("Total rows", "Single mutations", "Multiple mutations", 
             "Multiple mutations %", "Mutations per row (all 2)"),
  Value = c(nrow(original_data), 
           sum(!multi_mut_rows),
           sum(multi_mut_rows),
           round(sum(multi_mut_rows)/nrow(original_data)*100, 1),
           "2"))
write.csv(summary_stats, file.path(output_dir, "step2a_summary_stats.csv"), row.names = FALSE)

cat("✅ Step 2A data saved\n")

# =============================================================================
# FINAL SUMMARY
# =============================================================================

cat("\n=== STEP 2A COMPLETED ===\n")
cat("📊 Total rows: ", format(nrow(original_data), big.mark = ","), "\n")
cat("📊 Single mutations: ", format(sum(!multi_mut_rows), big.mark = ","), "\n")
cat("📊 Multiple mutations: ", format(sum(multi_mut_rows), big.mark = ","), "\n")
cat("📊 Percentage multiple: ", round(sum(multi_mut_rows)/nrow(original_data)*100, 1), "%\n")
cat("📁 Output directory: ", output_dir, "\n")
cat("📋 Figures created: ", length(list.files(figures_dir)), "\n")
cat("🎯 Ready for Step 2B: Split a small sample first!\n")









