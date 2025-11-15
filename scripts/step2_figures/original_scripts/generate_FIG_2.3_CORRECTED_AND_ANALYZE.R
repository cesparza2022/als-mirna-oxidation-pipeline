#!/usr/bin/env Rscript
# ============================================================================
# FIGURE 2.3 - CORRECTED VOLCANO PLOT + CONSISTENCY ANALYSIS
# ============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(ggrepel)

# Colors
COLOR_ALS <- "#D62728"        # Red for ALS
COLOR_CONTROL <- "#404040"    # Dark gray for Control
COLOR_NS <- "gray80"          # Light gray for not significant

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  FIGURE 2.3 - VOLCANO PLOT + CONSISTENCY ANALYSIS\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# ============================================================================
# LOAD DATA
# ============================================================================

cat("📂 Loading data...\n")
data <- read_csv("final_processed_data_CLEAN.csv", show_col_types = FALSE)
metadata <- read_csv("metadata.csv", show_col_types = FALSE)
sample_cols <- metadata$Sample_ID

# Filter only G>T in seed
vaf_gt_seed <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  filter(str_detect(pos.mut, "^(2|3|4|5|6|7|8):GT$")) %>%  # Only seed (2-8)
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID")

# List of unique miRNAs
all_seed_gt_mirnas <- unique(vaf_gt_seed$miRNA_name)

cat("   ✅ Data loaded\n")
cat("   ✅ miRNAs with G>T in seed:", length(all_seed_gt_mirnas), "\n\n")

# ============================================================================
# GENERATE VOLCANO DATA
# ============================================================================

cat("🔢 Generating volcano plot data...\n\n")

volcano_data <- data.frame()
for (mirna in all_seed_gt_mirnas) {
  mirna_data <- vaf_gt_seed %>% filter(miRNA_name == mirna)
  als_vals <- mirna_data %>% filter(Group == "ALS") %>% pull(VAF) %>% na.omit()
  ctrl_vals <- mirna_data %>% filter(Group == "Control") %>% pull(VAF) %>% na.omit()
  
  if (length(als_vals) > 5 && length(ctrl_vals) > 5) {
    mean_als <- mean(als_vals) + 0.001
    mean_ctrl <- mean(ctrl_vals) + 0.001
    fc <- log2(mean_als / mean_ctrl)
    test_result <- tryCatch(wilcox.test(als_vals, ctrl_vals), error = function(e) list(p.value = 1))
    
    volcano_data <- rbind(volcano_data, data.frame(
      miRNA = mirna, 
      log2FC = fc, 
      pvalue = test_result$p.value,
      Mean_ALS = mean_als,
      Mean_Control = mean_ctrl
    ))
  }
}

volcano_data$padj <- p.adjust(volcano_data$pvalue, method = "fdr")
volcano_data$neg_log10_padj <- -log10(volcano_data$padj)
volcano_data$Sig <- "NS"
volcano_data$Sig[volcano_data$log2FC > 0.58 & volcano_data$padj < 0.05] <- "ALS"
volcano_data$Sig[volcano_data$log2FC < -0.58 & volcano_data$padj < 0.05] <- "Control"

cat("   ✅ Volcano data generated for", nrow(volcano_data), "miRNAs\n\n")

# ============================================================================
# CONSISTENCY ANALYSIS WITH FIG 2.1-2.2
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("🔍 CONSISTENCY ANALYSIS WITH FIGURES 2.1-2.2\n")
cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

# Finding from Fig 2.1-2.2
cat("PREVIOUS FINDING (Fig 2.1-2.2):\n")
cat("   • Control > ALS in global G>T VAF\n")
cat("   • Control Mean: 3.69\n")
cat("   • ALS Mean: 2.58\n")
cat("   • p = 2.5e-13 (highly significant)\n")
cat("\n")

# Count in volcano
count_sig_als <- sum(volcano_data$Sig == "ALS")
count_sig_control <- sum(volcano_data$Sig == "Control")
count_ns <- sum(volcano_data$Sig == "NS")

cat("VOLCANO PLOT RESULTS:\n")
cat("   • miRNAs elevated in ALS:", count_sig_als, "\n")
cat("   • miRNAs elevated in Control:", count_sig_control, "\n")
cat("   • miRNAs not significant:", count_ns, "\n")
cat("\n")

# Global direction analysis
mean_log2fc_all <- mean(volcano_data$log2FC)
median_log2fc_all <- median(volcano_data$log2FC)

cat("GLOBAL DIRECTION (log2FC):\n")
cat("   • Mean log2FC:", round(mean_log2fc_all, 3), "\n")
cat("   • Median log2FC:", round(median_log2fc_all, 3), "\n")
cat("\n")

if (median_log2fc_all < 0) {
  cat("   ✅ CONSISTENT: Median < 0 → Trend toward Control\n")
} else {
  cat("   ⚠️  INCONSISTENT: Median > 0 → Trend toward ALS\n")
}
cat("\n")

# Proportion of miRNAs with direction toward Control
prop_control_direction <- sum(volcano_data$log2FC < 0) / nrow(volcano_data) * 100

cat("PROPORTION OF miRNAs:\n")
cat("   • Control direction (log2FC < 0):", round(prop_control_direction, 1), "%\n")
cat("   • ALS direction (log2FC > 0):", round(100 - prop_control_direction, 1), "%\n")
cat("\n")

if (prop_control_direction > 50) {
  cat("   ✅ CONSISTENT: Majority of miRNAs have more G>T in Control\n")
} else {
  cat("   ⚠️  INCONSISTENT: Majority of miRNAs have more G>T in ALS\n")
}
cat("\n")

# ============================================================================
# EXPLANATION OF APPARENT CONTRADICTION
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("💡 RECONCILING FINDINGS:\n")
cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

cat("KEY DIFFERENCE:\n")
cat("\n")
cat("Fig 2.1-2.2: GLOBAL burden (sum of ALL miRNAs)\n")
cat("   • Metric: Total sum of VAF per sample\n")
cat("   • Question: Which group has more G>T in TOTAL?\n")
cat("   • Answer: Control > ALS\n")
cat("\n")
cat("Fig 2.3: miRNA-SPECIFIC (each miRNA individually)\n")
cat("   • Metric: Mean VAF per miRNA\n")
cat("   • Question: Which SPECIFIC miRNAs differ between groups?\n")
cat("   • Answer: Depends on the miRNA\n")
cat("\n")

cat("POSSIBLE SCENARIO (reconciles both findings):\n")
cat("\n")
cat("Option 1: CONTROL has more affected miRNAs (more spread)\n")
cat("   • Control: 50 miRNAs with moderate G>T each\n")
cat("   • ALS: 20 miRNAs with high G>T each\n")
cat("   → Total Control > Total ALS (Fig 2.1-2.2)\n")
cat("   → But some specific miRNAs ALS > Control (Fig 2.3)\n")
cat("\n")
cat("Option 2: CONTROL has some VERY high miRNAs\n")
cat("   • A few miRNAs dominate the global burden in Control\n")
cat("   • Other miRNAs are higher in ALS\n")
cat("   → Volcano shows miRNA-specific heterogeneity\n")
cat("\n")
cat("Option 3: Different POSITIONS within seed\n")
cat("   • Some seed positions more in ALS\n")
cat("   • Other positions more in Control\n")
cat("   → Global: Control wins, but there are specific miRNAs in ALS\n")
cat("\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

# Analyze top significant miRNAs
if (count_sig_als > 0) {
  cat("TOP miRNAs ELEVATED IN ALS:\n")
  top_als <- volcano_data %>% 
    filter(Sig == "ALS") %>% 
    arrange(padj) %>% 
    head(5)
  print(top_als %>% select(miRNA, log2FC, Mean_ALS, Mean_Control, padj))
  cat("\n")
}

if (count_sig_control > 0) {
  cat("TOP miRNAs ELEVATED IN CONTROL:\n")
  top_control <- volcano_data %>% 
    filter(Sig == "Control") %>% 
    arrange(padj) %>% 
    head(5)
  print(top_control %>% select(miRNA, log2FC, Mean_ALS, Mean_Control, padj))
  cat("\n")
}

# ============================================================================
# GENERATE CORRECTED FIGURE
# ============================================================================

cat("🎨 Generating CORRECTED volcano plot (Control = dark gray)...\n")

theme_prof <- theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 15, hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray40"),
    axis.title = element_text(face = "bold", size = 12),
    axis.text = element_text(size = 11),
    legend.position = c(0.15, 0.85),
    legend.background = element_rect(fill = "white", color = "gray80"),
    legend.title = element_text(face = "bold", size = 11),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.3)
  )

# Top labels (15 most significant)
top_labels <- volcano_data %>% 
  filter(Sig != "NS") %>% 
  arrange(padj) %>% 
  head(15)

fig_2_3 <- ggplot(volcano_data, aes(x = log2FC, y = neg_log10_padj, color = Sig)) +
  geom_point(alpha = 0.6, size = 2.5) +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "gray50", linewidth = 0.5) +
  geom_vline(xintercept = c(-0.58, 0.58), linetype = "dashed", color = "gray50", linewidth = 0.5) +
  scale_color_manual(
    values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL, "NS" = COLOR_NS),
    labels = c("ALS" = paste0("Elevated in ALS (n=", count_sig_als, ")"),
               "Control" = paste0("Elevated in Control (n=", count_sig_control, ")"),
               "NS" = paste0("Not Significant (n=", count_ns, ")"))
  ) +
  labs(
    title = "Differential G>T in Seed Region by miRNA",
    subtitle = paste0("Total miRNAs analyzed: ", nrow(volcano_data), " | FDR < 0.05, |log₂FC| > 0.58"),
    x = "log₂(Fold Change) [ALS vs Control]",
    y = "-log₁₀(FDR p-value)",
    color = "Significance"
  ) +
  theme_prof

# Add labels for top miRNAs
if (nrow(top_labels) > 0) {
  fig_2_3 <- fig_2_3 + 
    geom_text_repel(
      data = top_labels, 
      aes(label = miRNA), 
      size = 3, 
      max.overlaps = 20, 
      color = "black",
      box.padding = 0.5,
      point.padding = 0.3,
      segment.color = "gray60",
      segment.size = 0.3
    )
}

ggsave("figures_step2_CLEAN/FIG_2.3_VOLCANO_CORRECTED.png", fig_2_3, 
       width = 12, height = 10, dpi = 300, bg = "white")
cat("   ✅ CORRECTED volcano plot saved\n\n")

# ============================================================================
# DETAILED CONSISTENCY ANALYSIS
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("📊 CONSISTENCY ANALYSIS WITH FIG 2.1-2.2\n")
cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

# 1. GLOBAL DIRECTION
cat("1️⃣ GLOBAL DIRECTION:\n")
cat("   Fig 2.1-2.2: Control > ALS (p = 2.5e-13)\n")
cat("   Fig 2.3 Volcano:\n")
cat("      • Mean log2FC:", round(mean_log2fc_all, 3), 
    ifelse(mean_log2fc_all < 0, "→ Control > ALS ✅", "→ ALS > Control ⚠️"), "\n")
cat("      • Median log2FC:", round(median_log2fc_all, 3),
    ifelse(median_log2fc_all < 0, "→ Control > ALS ✅", "→ ALS > Control ⚠️"), "\n")
cat("\n")

# 2. PROPORTION OF miRNAs
cat("2️⃣ PROPORTION OF miRNAs BY DIRECTION:\n")
cat("   • log2FC < 0 (Control > ALS):", round(prop_control_direction, 1), "% (", 
    sum(volcano_data$log2FC < 0), "/", nrow(volcano_data), ")\n")
cat("   • log2FC > 0 (ALS > Control):", round(100 - prop_control_direction, 1), "% (", 
    sum(volcano_data$log2FC > 0), "/", nrow(volcano_data), ")\n")
cat("\n")

if (prop_control_direction > 50) {
  cat("   ✅ CONSISTENT: Majority of miRNAs with Control direction\n")
} else {
  cat("   ⚠️  Balanced or inverse distribution\n")
}
cat("\n")

# 3. SIGNIFICANT
cat("3️⃣ SIGNIFICANT miRNAs:\n")
cat("   • Elevated in ALS:", count_sig_als, "\n")
cat("   • Elevated in Control:", count_sig_control, "\n")
cat("\n")

if (count_sig_control > count_sig_als) {
  cat("   ✅ CONSISTENT: More significant miRNAs in Control\n")
} else if (count_sig_control < count_sig_als) {
  cat("   ⚠️  MORE significant miRNAs in ALS (inconsistent with global burden)\n")
} else {
  cat("   ➖ NEUTRAL: Equal number of significant miRNAs\n")
}
cat("\n")

# 4. AVERAGE MAGNITUDE
mean_fc_control_mirnas <- volcano_data %>% filter(Sig == "Control") %>% pull(log2FC) %>% abs() %>% mean()
mean_fc_als_mirnas <- volcano_data %>% filter(Sig == "ALS") %>% pull(log2FC) %>% abs() %>% mean()

cat("4️⃣ EFFECT MAGNITUDE:\n")
if (count_sig_control > 0) {
  cat("   • |log2FC| average Control miRNAs:", round(mean_fc_control_mirnas, 2), 
      "(~", round(2^mean_fc_control_mirnas, 1), "x fold change)\n")
}
if (count_sig_als > 0) {
  cat("   • |log2FC| average ALS miRNAs:", round(mean_fc_als_mirnas, 2),
      "(~", round(2^mean_fc_als_mirnas, 1), "x fold change)\n")
}
cat("\n")

# ============================================================================
# INTEGRATED INTERPRETATION
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("🧠 INTEGRATED INTERPRETATION:\n")
cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")

cat("RECONCILING FINDINGS:\n")
cat("\n")

if (median_log2fc_all < 0 & count_sig_control >= count_sig_als) {
  cat("✅ FULLY CONSISTENT:\n")
  cat("   • Fig 2.1-2.2: Control > ALS (global)\n")
  cat("   • Fig 2.3: Majority of miRNAs Control > ALS (specific)\n")
  cat("   • Conclusion: The global finding is reflected at the individual miRNA level\n")
  cat("\n")
  
} else if (median_log2fc_all < 0 & count_sig_control < count_sig_als) {
  cat("⚠️  PARTIALLY CONSISTENT:\n")
  cat("   • Global trend toward Control (median < 0)\n")
  cat("   • BUT: More SIGNIFICANT miRNAs in ALS\n")
  cat("\n")
  cat("   POSSIBLE EXPLANATION:\n")
  cat("   • Control has MANY miRNAs with small elevations (not significant)\n")
  cat("   • ALS has FEW miRNAs but with LARGER changes (significant)\n")
  cat("   • Global burden is dominated by Control (more miRNAs)\n")
  cat("   • But strong individual changes are in ALS\n")
  cat("\n")
  
} else if (median_log2fc_all > 0) {
  cat("❌ APPARENTLY INCONSISTENT:\n")
  cat("   • Fig 2.1-2.2: Control > ALS (global)\n")
  cat("   • Fig 2.3: Trend toward ALS > Control (individual miRNAs)\n")
  cat("\n")
  cat("   POSSIBLE EXPLANATIONS:\n")
  cat("   • Control has FEW miRNAs but with VERY HIGH VAF\n")
  cat("   • ALS has MANY miRNAs with low/moderate VAF\n")
  cat("   • Control outliers dominate the global burden\n")
  cat("   • We need to investigate expression distribution\n")
  cat("\n")
}

# ============================================================================
# RECOMMENDATIONS
# ============================================================================

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("💡 RECOMMENDATIONS:\n")
cat("\n")

cat("1. Review the TOP significant miRNAs (above)\n")
cat("2. Verify if some miRNAs dominate the global burden\n")
cat("3. Consider analysis of:\n")
cat("   • Number of expressed miRNAs per group\n")
cat("   • Relative contribution of each miRNA to total burden\n")
cat("   • Baseline expression distribution per group\n")
cat("\n")

cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("✅ CORRECTED FIGURE GENERATED:\n")
cat("   • FIG_2.3_VOLCANO_CORRECTED.png\n")
cat("   • Control in dark gray (not blue)\n")
cat("   • Complete consistency analysis\n")
cat("\n")
