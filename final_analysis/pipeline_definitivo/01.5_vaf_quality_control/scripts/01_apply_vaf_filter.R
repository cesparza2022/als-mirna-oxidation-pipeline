#!/usr/bin/env Rscript

# ============================================================================
# 🎯 STEP 1.5: VAF QUALITY CONTROL - APPLY VAF FILTER
# ============================================================================
# Purpose: Filter out technical artifacts (VAF >= 0.5)
# Input:  step2b_sample_collapse_data.csv (from Step 1)
# Output: ALL_MUTATIONS_VAF_FILTERED.csv (12 types, 23 pos, VAF-cleaned)

library(dplyr)
library(tidyr)
library(readr)

cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║     🎯 STEP 1.5: VAF QUALITY CONTROL - APPLY FILTER                ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

# Paths
base_dir <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo/01.5_vaf_quality_control"
input_file <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/tercer_intento/step_by_step_analysis/step1_original_data.csv"

setwd(base_dir)

# ============================================================================
# 1. LOAD DATA
# ============================================================================

cat("📊 Loading collapsed data...\n")
data <- read.csv(input_file, check.names = FALSE)

cat(sprintf("   ✅ Rows: %s\n", format(nrow(data), big.mark = ",")))
cat(sprintf("   ✅ Columns: %d\n", ncol(data)))

# Get column types
sample_cols <- grep("^Magen", names(data), value = TRUE)
total_cols <- grep("\\(PM\\+1MM\\+2MM\\)$", names(data), value = TRUE)
snv_cols <- setdiff(sample_cols, total_cols)

cat(sprintf("   ✅ SNV columns: %d\n", length(snv_cols)))
cat(sprintf("   ✅ Total columns: %d\n", length(total_cols)))

# ============================================================================
# 2. CALCULATE VAF AND IDENTIFY ARTIFACTS
# ============================================================================

cat("\n📊 Calculating VAF for all mutations...\n")

# Extract miRNA and position info
data_with_info <- data %>%
  mutate(
    miRNA = `miRNA name`,
    pos_mut = `pos:mut`
  )

# Initialize counter
total_filtered <- 0
filter_log <- list()

# Process each row (each SNV)
cat("📊 Processing SNVs and applying VAF filter...\n")

# Create a copy for filtering
data_filtered <- data_with_info

for (i in 1:nrow(data_with_info)) {
  mirna_name <- data_with_info$miRNA[i]
  
  # For each sample, calculate VAF
  for (snv_col in snv_cols) {
    # Find corresponding total column
    # Remove " (PM+1MM+2MM)" suffix from total column to match sample
    sample_base <- snv_col
    total_col <- paste0(sample_base, " (PM+1MM+2MM)")
    
    if (total_col %in% names(data_with_info)) {
      count_snv <- data_with_info[i, snv_col]
      count_total <- data_with_info[i, total_col]
      
      # Calculate VAF
      if (!is.na(count_snv) && !is.na(count_total) && count_total > 0) {
        vaf <- count_snv / count_total
        
        # If VAF >= 0.5, mark as NaN (artifact)
        if (vaf >= 0.5) {
          data_filtered[i, snv_col] <- NA
          total_filtered <- total_filtered + 1
          
          # Log this filter event
          filter_log[[length(filter_log) + 1]] <- list(
            row = i,
            miRNA = mirna_name,
            pos_mut = data_with_info$pos_mut[i],
            sample = snv_col,
            count_snv = count_snv,
            count_total = count_total,
            vaf = vaf
          )
        }
      }
    }
  }
  
  # Progress indicator
  if (i %% 5000 == 0) {
    cat(sprintf("   Progress: %d / %d rows processed...\n", i, nrow(data_with_info)))
  }
}

cat(sprintf("\n   ✅ VAF filtering complete!\n"))
cat(sprintf("   🚫 Total values filtered (VAF >= 0.5): %s\n", format(total_filtered, big.mark = ",")))

# ============================================================================
# 3. SAVE FILTERED DATASET
# ============================================================================

cat("\n💾 Saving VAF-filtered dataset...\n")

# Remove helper columns
data_output <- data_filtered %>%
  select(-miRNA, -pos_mut)

write.csv(data_output, "data/ALL_MUTATIONS_VAF_FILTERED.csv", row.names = FALSE)
cat("   ✅ data/ALL_MUTATIONS_VAF_FILTERED.csv\n")

# ============================================================================
# 4. SAVE FILTER REPORT
# ============================================================================

cat("\n💾 Saving filter report...\n")

if (length(filter_log) > 0) {
  filter_df <- bind_rows(filter_log)
  write.csv(filter_df, "data/vaf_filter_report.csv", row.names = FALSE)
  cat(sprintf("   ✅ data/vaf_filter_report.csv (%d filtered events)\n", nrow(filter_df)))
  
  # Statistics by mutation type
  stats_by_type <- filter_df %>%
    mutate(mutation_type = gsub(".*:", "", pos_mut)) %>%
    group_by(mutation_type) %>%
    summarise(
      N_filtered = n(),
      Mean_VAF = mean(vaf),
      Median_VAF = median(vaf),
      .groups = "drop"
    ) %>%
    arrange(desc(N_filtered))
  
  write.csv(stats_by_type, "data/vaf_statistics_by_type.csv", row.names = FALSE)
  cat("   ✅ data/vaf_statistics_by_type.csv\n")
  
  # Statistics by miRNA
  stats_by_mirna <- filter_df %>%
    group_by(miRNA) %>%
    summarise(
      N_filtered = n(),
      Mean_VAF = mean(vaf),
      N_samples_affected = n_distinct(sample),
      .groups = "drop"
    ) %>%
    arrange(desc(N_filtered))
  
  write.csv(stats_by_mirna, "data/vaf_statistics_by_mirna.csv", row.names = FALSE)
  cat("   ✅ data/vaf_statistics_by_mirna.csv\n")
}

# ============================================================================
# 5. SUMMARY STATISTICS
# ============================================================================

cat("\n╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║          ✅ VAF FILTERING COMPLETED                                 ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

cat("📊 SUMMARY:\n\n")
cat(sprintf("   Original dataset:\n"))
cat(sprintf("      • Rows (SNVs): %s\n", format(nrow(data), big.mark = ",")))
cat(sprintf("      • Columns: %d\n", ncol(data)))
cat(sprintf("\n   Filtered values (VAF >= 0.5):\n"))
cat(sprintf("      • Total: %s\n", format(total_filtered, big.mark = ",")))

if (length(filter_log) > 0) {
  cat(sprintf("      • Unique SNVs affected: %d\n", length(unique(sapply(filter_log, function(x) x$pos_mut)))))
  cat(sprintf("      • Unique miRNAs affected: %d\n", length(unique(sapply(filter_log, function(x) x$miRNA)))))
  
  cat(sprintf("\n   Top 5 mutation types affected:\n"))
  print(head(stats_by_type, 5))
  
  cat(sprintf("\n   Top 5 miRNAs affected:\n"))
  print(head(stats_by_mirna, 5))
}

cat("\n📁 OUTPUT FILES:\n")
cat("   • data/ALL_MUTATIONS_VAF_FILTERED.csv (main dataset)\n")
cat("   • data/vaf_filter_report.csv (detailed log)\n")
cat("   • data/vaf_statistics_by_type.csv (stats by mutation type)\n")
cat("   • data/vaf_statistics_by_mirna.csv (stats by miRNA)\n")

cat("\n🚀 NEXT: Generate diagnostic figures\n")
cat("   Rscript scripts/02_generate_diagnostic_figures.R\n\n")

