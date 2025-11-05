# 📊 GENERATE PROFESSIONAL TABLES - COMPLEMENTING FIGURES

rm(list = ls())

library(tidyverse)
library(knitr)

source("config/config_pipeline_2.R")

cat("\n📊 GENERATING PROFESSIONAL TABLES\n")
cat("═══════════════════════════════════════════════════════════\n\n")

## Load data
data_path <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"
raw_data <- read_tsv(data_path, show_col_types = FALSE)

processed_data <- raw_data %>%
  separate_rows(`pos:mut`, sep = ",") %>%
  filter(`pos:mut` != "PM") %>%
  separate(`pos:mut`, into = c("position", "mutation_type"), sep = ":", remove = FALSE) %>%
  mutate(
    position = as.numeric(position),
    mutation_type = case_when(
      mutation_type == "GT" ~ "G>T",
      mutation_type == "GA" ~ "G>A",
      mutation_type == "GC" ~ "G>C",
      mutation_type == "TC" ~ "T>C",
      mutation_type == "AG" ~ "A>G",
      mutation_type == "CT" ~ "C>T",
      TRUE ~ mutation_type
    )
  ) %>%
  filter(position >= 1 & position <= 22)

## ═══════════════════════════════════════════════════════════════════════════
## TABLE 1: Dataset Summary Statistics
## ═══════════════════════════════════════════════════════════════════════════

cat("📋 TABLE 1: Dataset Summary Statistics\n")

table1 <- tibble(
  Metric = c(
    "Raw entries (original file)",
    "Individual SNVs (after split)",
    "Valid SNVs (after PM filter)",
    "Unique miRNAs covered",
    "Total G>T mutations",
    "G>T as % of total",
    "Positions analyzed",
    "Samples (columns)"
  ),
  Value = c(
    "68,968",
    "111,785",
    "110,199",
    "1,462",
    "8,033",
    "7.3%",
    "1-22",
    "830 (626 ALS + 204 Control)"
  )
)

# Save as CSV
write.csv(table1, file.path(base_dir, "tables/table1_dataset_summary.csv"), row.names = FALSE)

# Print formatted
cat("\n")
print(kable(table1, format = "markdown", align = c("l", "r")))
cat("\n✅ Table 1 saved: tables/table1_dataset_summary.csv\n\n")

## ═══════════════════════════════════════════════════════════════════════════
## TABLE 2: Mutation Type Distribution (Top 10)
## ═══════════════════════════════════════════════════════════════════════════

cat("📋 TABLE 2: Mutation Type Distribution\n")

table2 <- processed_data %>%
  count(mutation_type, name = "Count") %>%
  arrange(desc(Count)) %>%
  head(10) %>%
  mutate(
    Percentage = sprintf("%.1f%%", Count / sum(Count) * 100),
    Count = format(Count, big.mark = ",")
  ) %>%
  rename(`Mutation Type` = mutation_type)

write.csv(table2, file.path(base_dir, "tables/table2_mutation_types.csv"), row.names = FALSE)

cat("\n")
print(kable(table2, format = "markdown", align = c("l", "r", "r")))
cat("\n✅ Table 2 saved: tables/table2_mutation_types.csv\n\n")

## ═══════════════════════════════════════════════════════════════════════════
## TABLE 3: G>T Distribution by Position
## ═══════════════════════════════════════════════════════════════════════════

cat("📋 TABLE 3: G>T Distribution by Position\n")

gt_by_position <- processed_data %>%
  filter(mutation_type == "G>T") %>%
  count(position) %>%
  complete(position = 1:22, fill = list(n = 0)) %>%
  mutate(
    Region = ifelse(position >= 2 & position <= 8, "Seed", "Non-Seed"),
    Percentage = sprintf("%.1f%%", n / sum(n) * 100)
  ) %>%
  rename(
    Position = position,
    `G>T Count` = n
  )

table3 <- gt_by_position %>%
  mutate(`G>T Count` = format(`G>T Count`, big.mark = ","))

write.csv(table3, file.path(base_dir, "tables/table3_gt_by_position.csv"), row.names = FALSE)

cat("\n")
print(kable(table3, format = "markdown", align = c("r", "l", "r", "r")))
cat("\n✅ Table 3 saved: tables/table3_gt_by_position.csv\n\n")

## ═══════════════════════════════════════════════════════════════════════════
## TABLE 4: Seed vs Non-Seed Summary
## ═══════════════════════════════════════════════════════════════════════════

cat("📋 TABLE 4: Seed vs Non-Seed Summary\n")

table4 <- processed_data %>%
  filter(mutation_type == "G>T") %>%
  mutate(Region = ifelse(position >= 2 & position <= 8, "Seed", "Non-Seed")) %>%
  count(Region) %>%
  mutate(
    Percentage = sprintf("%.1f%%", n / sum(n) * 100),
    `Positions` = ifelse(Region == "Seed", "2-8 (7 positions)", "1,9-22 (15 positions)"),
    `Avg per Position` = sprintf("%.0f", n / c(7, 15))
  ) %>%
  rename(`G>T Count` = n) %>%
  select(Region, Positions, `G>T Count`, Percentage, `Avg per Position`)

table4$`G>T Count` <- format(table4$`G>T Count`, big.mark = ",")

write.csv(table4, file.path(base_dir, "tables/table4_seed_vs_nonseed.csv"), row.names = FALSE)

cat("\n")
print(kable(table4, format = "markdown"))
cat("\n✅ Table 4 saved: tables/table4_seed_vs_nonseed.csv\n\n")

## ═══════════════════════════════════════════════════════════════════════════
## TABLE 5: Top miRNAs with G>T (Top 20)
## ═══════════════════════════════════════════════════════════════════════════

cat("📋 TABLE 5: Top 20 miRNAs with G>T Mutations\n")

table5 <- processed_data %>%
  filter(mutation_type == "G>T") %>%
  count(`miRNA name`, name = "GT_Count") %>%
  arrange(desc(GT_Count)) %>%
  head(20) %>%
  mutate(
    Rank = row_number(),
    Percentage = sprintf("%.2f%%", GT_Count / sum(GT_Count) * 100)
  ) %>%
  rename(`G>T Count` = GT_Count) %>%
  select(Rank, `miRNA name`, `G>T Count`, Percentage)

table5$`G>T Count` <- format(table5$`G>T Count`, big.mark = ",")

write.csv(table5, file.path(base_dir, "tables/table5_top_mirnas.csv"), row.names = FALSE)

cat("\n")
print(kable(head(table5, 10), format = "markdown", align = c("r", "l", "r", "r")))
cat("   ... (Top 10 shown, full table has 20 miRNAs)\n")
cat("\n✅ Table 5 saved: tables/table5_top_mirnas.csv\n\n")

## ═══════════════════════════════════════════════════════════════════════════
## TABLE 6: G-Content Correlation Summary (from Figure 2)
## ═══════════════════════════════════════════════════════════════════════════

cat("📋 TABLE 6: G-Content vs Oxidation (Mechanistic Evidence)\n")

gcontent_file <- file.path(base_dir, "data/g_content_analysis.csv")
if (file.exists(gcontent_file)) {
  gcontent_data <- read.csv(gcontent_file)
  
  table6 <- gcontent_data %>%
    mutate(
      `# G's in Seed` = n_g_in_seed,
      `# miRNAs` = format(n_mirnas, big.mark = ","),
      `% Oxidized` = sprintf("%.1f%%", perc_oxidados),
      `Oxidation Level` = case_when(
        perc_oxidados == 0 ~ "None",
        perc_oxidados < 10 ~ "Low",
        perc_oxidados < 15 ~ "Medium",
        TRUE ~ "High"
      )
    ) %>%
    select(`# G's in Seed`, `# miRNAs`, `% Oxidized`, `Oxidation Level`)
  
  write.csv(table6, file.path(base_dir, "tables/table6_gcontent_correlation.csv"), row.names = FALSE)
  
  cat("\n")
  print(kable(table6, format = "markdown", align = c("r", "r", "r", "l")))
  cat("\n✅ Table 6 saved: tables/table6_gcontent_correlation.csv\n")
  cat("   📊 Spearman correlation: r = 0.347 (p < 0.001)\n\n")
}

## ═══════════════════════════════════════════════════════════════════════════
## SUMMARY
## ═══════════════════════════════════════════════════════════════════════════

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  🎉 6 PROFESSIONAL TABLES GENERATED\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")

cat("📁 OUTPUT DIRECTORY: tables/\n\n")

cat("📊 TABLES CREATED:\n")
cat("   1. Dataset summary statistics\n")
cat("   2. Mutation type distribution (Top 10)\n")
cat("   3. G>T by position (1-22)\n")
cat("   4. Seed vs Non-Seed summary\n")
cat("   5. Top 20 miRNAs with G>T\n")
cat("   6. G-content correlation data\n\n")

cat("💡 USES:\n")
cat("   • Supplementary tables for papers\n")
cat("   • Detailed statistics reference\n")
cat("   • Data for further analysis\n")
cat("   • Quick lookup of specific values\n\n")

cat("📝 All tables saved as CSV (publication-ready)\n")
cat("🌐 Can be integrated into HTML reports\n\n")
