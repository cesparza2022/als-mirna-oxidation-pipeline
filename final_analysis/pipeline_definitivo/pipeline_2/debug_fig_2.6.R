#!/usr/bin/env Rscript
# Debug script for Figure 2.6

library(tidyverse)

# Load data
data <- read.csv("final_processed_data_CLEAN.csv", check.names = FALSE)
sample_cols <- names(data)[3:ncol(data)]

cat("📊 Sample columns:\n")
cat("  Total:", length(sample_cols), "\n")
cat("  ALS:", sum(grepl("^ALS", sample_cols)), "\n")
cat("  Control:", sum(grepl("^Control", sample_cols)), "\n\n")

# Check metadata
metadata <- data.frame(
  Sample_ID = sample_cols,
  Group = ifelse(grepl("^ALS", sample_cols), "ALS", "Control")
)

cat("📊 Metadata summary:\n")
print(table(metadata$Group))
cat("\n")

# Filter G>T
vaf_gt <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  filter(!is.na(position), position <= 22)

cat("📊 G>T SNVs by position:\n")
print(table(vaf_gt$position))
cat("\n")

# Transform to long
vaf_long <- vaf_gt %>%
  select(miRNA_name, position, all_of(sample_cols)) %>%
  pivot_longer(cols = all_of(sample_cols), 
               names_to = "Sample_ID", 
               values_to = "VAF") %>%
  filter(!is.na(VAF)) %>%
  left_join(metadata, by = "Sample_ID")

cat("📊 Long format data:\n")
cat("  Total rows:", nrow(vaf_long), "\n")
cat("  By group:\n")
print(table(vaf_long$Group))
cat("\n")

# Aggregate per sample
vaf_per_sample <- vaf_long %>%
  group_by(Sample_ID, position, Group) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE),
            N_SNVs = n(),
            .groups = "drop")

cat("📊 Per-sample aggregation:\n")
cat("  Total rows:", nrow(vaf_per_sample), "\n")
cat("  By group:\n")
print(table(vaf_per_sample$Group))
cat("\n")

# Check regions
vaf_regions <- vaf_per_sample %>%
  mutate(Region = case_when(
    position >= 2 & position <= 8 ~ "Seed (2-8)",
    position == 1 ~ "5' Terminal",
    TRUE ~ "Non-seed (9-22)"
  ))

cat("📊 By region and group:\n")
print(table(vaf_regions$Region, vaf_regions$Group))
cat("\n")

# Filter main regions
vaf_regions_main <- vaf_regions %>%
  filter(Region != "5' Terminal")

cat("📊 Main regions (Seed + Non-seed):\n")
print(table(vaf_regions_main$Region, vaf_regions_main$Group))
cat("\n")

# Calculate stats
region_stats <- vaf_regions_main %>%
  group_by(Region, Group) %>%
  summarise(
    N = n(),
    Mean = mean(Total_VAF, na.rm = TRUE),
    Median = median(Total_VAF, na.rm = TRUE),
    SD = sd(Total_VAF, na.rm = TRUE),
    .groups = "drop"
  )

cat("📊 Region statistics:\n")
print(region_stats)
cat("\n")

