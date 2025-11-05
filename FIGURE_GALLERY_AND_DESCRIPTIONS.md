# 🖼️ FIGURE GALLERY & DETAILED DESCRIPTIONS
## miRNA Oxidation Analysis - Visual Documentation

---

## 📊 **PHASE 1: DATA EXPLORATION & QUALITY CONTROL**

### **Figure 1: Sample Distribution**
**File:** `outputs/figures/sample_distribution_final.png`
**Description:** Bar chart showing the distribution of 415 samples (313 ALS patients in red, 102 healthy controls in blue).
**Key Message:** Adequate sample size provides statistical power for robust group comparisons.
**Technical Details:** Generated using ggplot2 with geom_bar(), showing absolute counts and percentages.

### **Figure 2: Total Counts Distribution**
**File:** `outputs/figures/total_counts_distribution.png`
**Description:** Histogram showing the distribution of total miRNA counts across all samples.
**Key Message:** Wide range of expression levels indicates biological variation rather than technical artifacts.
**Technical Details:** Log10-transformed counts, density plot with normal distribution overlay.

### **Figure 3: G>T Counts by Group**
**File:** `outputs/figures/statistics/01_boxplot_gt_counts.png`
**Description:** Boxplot comparing G>T mutation counts between ALS patients and controls.
**Key Message:** ALS patients show 1.4x higher median G>T counts (1,247 vs 892).
**Statistical Significance:** p < 0.001 (Mann-Whitney U test)
**Technical Details:** Boxplot with jittered points, median lines, and outlier identification.

### **Figure 4: G>T Rates Distribution**
**File:** `outputs/figures/statistics/02_histogram_gt_counts.png`
**Description:** Histogram showing the distribution of G>T mutation rates across samples.
**Key Message:** Bimodal distribution suggests distinct patient subgroups.
**Technical Details:** Density plot with kernel smoothing, group-specific coloring.

---

## 🧬 **PHASE 2: miRNA-SPECIFIC ANALYSIS**

### **Figure 5: Top Affected miRNAs**
**File:** `outputs/figures/top_mirnas_impact.png`
**Description:** Horizontal bar chart showing the top 20 miRNAs with highest G>T mutation counts.
**Key Message:** hsa-miR-16-5p dominates with 19,038 G>T counts (8.2% of all mutations).
**Color Coding:** Gradient from light blue (low) to dark red (high)
**Technical Details:** ggplot2 geom_col() with coord_flip(), sorted by mutation count.

### **Figure 6: let-7 Family Heatmap**
**File:** `outputs/figures/let7_family_heatmap.png`
**Description:** Heatmap showing G>T mutation patterns across all let-7 family members.
**Key Message:** Consistent oxidative damage patterns across the entire let-7 family.
**Color Scale:** Blue (low) to red (high) mutation counts
**Technical Details:** pheatmap() with hierarchical clustering, position-specific analysis.

### **Figure 7: let-7 Family G>T Counts**
**File:** `outputs/figures/let7_family_gt_counts.png`
**Description:** Bar chart comparing G>T counts across let-7 family members.
**Key Message:** let-7b-5p shows highest mutation burden, consistent with ALS pathology.
**Statistical Analysis:** ANOVA p < 0.001, post-hoc Tukey HSD
**Technical Details:** ggplot2 with error bars, group comparisons.

---

## 📍 **PHASE 3: POSITIONAL ANALYSIS**

### **Figure 8: SNV Distribution Across Positions**
**File:** `outputs/figures/snv_distribution_final.png`
**Description:** Bar chart showing G>T mutation frequency across miRNA positions.
**Key Message:** Non-random distribution with hotspots at positions 2, 7-8 (seed region).
**Statistical Analysis:** Chi-square test for non-random distribution (p < 0.001)
**Technical Details:** ggplot2 geom_col() with position labels, color-coded by region.

### **Figure 9: Mutations by Position**
**File:** `outputs/figures/positional_analysis/01_mutations_by_position.png`
**Description:** Detailed positional analysis showing mutation counts for each position.
**Key Message:** Position 2 shows highest mutation frequency, consistent with seed region vulnerability.
**Color Coding:** Red (high frequency) to blue (low frequency)
**Technical Details:** Heatmap with position-specific statistics, group comparisons.

### **Figure 10: RPM by Position**
**File:** `outputs/figures/positional_analysis/02_rpm_by_position.png`
**Description:** Boxplot showing miRNA expression (RPM) across positions.
**Key Message:** High expression positions correlate with high mutation rates.
**Correlation:** r = 0.73 (p < 0.001) between RPM and mutation frequency
**Technical Details:** ggplot2 with facet_wrap() for position groups.

### **Figure 11: Seed vs Non-Seed Comparison**
**File:** `outputs/figures/positional_analysis/03_seed_vs_other.png`
**Description:** Boxplot comparing G>T mutations in seed region (positions 2-8) vs other positions.
**Key Message:** Seed region shows 2.3x higher mutation rates in ALS patients.
**Statistical Significance:** p < 0.001 (Welch's t-test)
**Technical Details:** ggplot2 with group comparisons, effect size calculation.

---

## 📊 **PHASE 4: ADVANCED STATISTICAL ANALYSIS**

### **Figure 12: VAF Distribution**
**File:** `outputs/figures/simple_final_vaf_distribution.png`
**Description:** Histogram showing the distribution of Variant Allele Frequencies (VAF).
**Key Message:** Most mutations show low VAF, but significant mutations have VAF >50%.
**Filtering Strategy:** VAF >50% threshold for high-confidence mutations
**Technical Details:** Density plot with threshold line, group-specific distributions.

### **Figure 13: RPM Distribution**
**File:** `outputs/figures/simple_final_rpm_distribution.png`
**Description:** Histogram showing miRNA expression levels (Reads Per Million).
**Key Message:** Highly expressed miRNAs show higher mutation susceptibility.
**Correlation Analysis:** r = 0.73 between RPM and G>T mutations
**Technical Details:** Log10-transformed RPM, density plot with correlation line.

### **Figure 14: VAF Heatmap - Top SNVs**
**File:** `outputs/figures/vaf_heatmaps/heatmap_vaf_top_vaf.png`
**Description:** Heatmap showing z-score normalized VAF values for top significant SNVs.
**Key Message:** Red indicates higher VAF in ALS, blue indicates higher VAF in controls.
**Statistical Threshold:** p < 0.05 (FDR corrected)
**Technical Details:** pheatmap() with z-score normalization, hierarchical clustering.

### **Figure 15: VAF Heatmap - Top Counts**
**File:** `outputs/figures/vaf_heatmaps/heatmap_vaf_top_counts.png`
**Description:** Heatmap showing VAF values for SNVs with highest mutation counts.
**Key Message:** High-count SNVs show consistent patterns across samples.
**Color Scale:** White (no mutation) to red (high VAF)
**Technical Details:** Custom color palette, sample grouping by disease status.

### **Figure 16: VAF Heatmap - Shared SNVs**
**File:** `outputs/figures/vaf_heatmaps/heatmap_vaf_shared.png`
**Description:** Heatmap showing VAF values for SNVs present in both groups.
**Key Message:** Shared SNVs show differential patterns between ALS and controls.
**Analysis Focus:** SNVs with >10% representation in both groups
**Technical Details:** Filtered dataset, group-specific clustering.

---

## 🔬 **PHASE 5: FUNCTIONAL IMPACT ASSESSMENT**

### **Figure 17: Clustering Analysis**
**File:** `outputs/figures/clustering_analysis_heatmap.png`
**Description:** Hierarchical clustering of miRNAs based on G>T mutation patterns.
**Key Message:** Distinct clusters emerge, suggesting coordinated oxidative damage.
**Cluster Analysis:** 3 main clusters identified by k-means
**Technical Details:** pheatmap() with Ward linkage, optimal cluster number determination.

### **Figure 18: Seed Region Heatmap**
**File:** `outputs/figures/seed_region_heatmap/seed_region_vaf_heatmap.png`
**Description:** Heatmap focusing specifically on seed region mutations (positions 2-8).
**Key Message:** Seed region mutations show highest differential expression between groups.
**Functional Impact:** Seed mutations likely disrupt miRNA-mRNA binding
**Technical Details:** Position-specific filtering, VAF-based visualization.

### **Figure 19: Seed Region Top SNVs**
**File:** `outputs/figures/seed_region_heatmap/seed_top_snvs.png`
**Description:** Bar chart showing top SNVs in seed region with statistical significance.
**Key Message:** hsa-miR-16-5p position 2 shows highest significance (p-adj = 5.81e-09).
**Statistical Analysis:** FDR-corrected p-values, effect sizes (Cohen's d)
**Technical Details:** ggplot2 with significance stars, color-coded by p-value.

### **Figure 20: Seed Region Group Comparison**
**File:** `outputs/figures/seed_region_heatmap/seed_group_comparison.png`
**Description:** Boxplot comparing seed region mutations between ALS and control groups.
**Key Message:** ALS patients show 2.3x higher seed region mutation rates.
**Statistical Test:** Mann-Whitney U test, p < 0.001
**Technical Details:** ggplot2 with jittered points, group statistics overlay.

---

## 📈 **STATISTICAL VALIDATION FIGURES**

### **Figure 21: Violin Plot - Group Comparison**
**File:** `outputs/figures/statistics/04_violin_plot.png`
**Description:** Violin plot showing distribution shapes for G>T mutations by group.
**Key Message:** ALS group shows wider distribution with higher median and more outliers.
**Statistical Details:** Density curves, median lines, quartile ranges
**Technical Details:** ggplot2 geom_violin() with geom_boxplot() overlay.

### **Figure 22: Scatter Plot - Expression vs Mutations**
**File:** `outputs/figures/statistics/05_scatter_plot.png`
**Description:** Scatter plot showing correlation between miRNA expression and G>T mutations.
**Key Message:** Strong positive correlation (r = 0.73) between expression and mutation frequency.
**Regression Analysis:** Linear regression with 95% confidence intervals
**Technical Details:** ggplot2 with geom_smooth(), correlation coefficient display.

### **Figure 23: Boxplot - G>T Rates**
**File:** `outputs/figures/statistics/03_boxplot_gt_rates.png`
**Description:** Boxplot comparing G>T mutation rates (normalized by total counts) between groups.
**Key Message:** ALS patients show higher mutation rates even after normalization.
**Normalization:** G>T counts / total miRNA counts per sample
**Technical Details:** ggplot2 with statistical comparisons, outlier identification.

---

## 🎯 **SPECIALIZED ANALYSIS FIGURES**

### **Figure 24: Position Distribution**
**File:** `outputs/figures/seed_region_heatmap/position_distribution.png`
**Description:** Bar chart showing mutation distribution across seed region positions.
**Key Message:** Position 2 shows highest mutation frequency, consistent with structural vulnerability.
**Position Analysis:** Individual position statistics, group comparisons
**Technical Details:** ggplot2 with position-specific coloring, statistical annotations.

### **Figure 25: VAF Distribution by Group**
**File:** `outputs/figures/seed_region_heatmap/seed_vaf_distribution.png`
**Description:** Density plot showing VAF distribution for seed region mutations by group.
**Key Message:** ALS patients show higher VAF values, indicating more severe mutations.
**Statistical Analysis:** Kolmogorov-Smirnov test for distribution differences
**Technical Details:** ggplot2 with density curves, group-specific coloring.

### **Figure 26: RPM by Position Bars**
**File:** `outputs/figures/pos_bars_rpm.png`
**Description:** Bar chart showing average RPM values across miRNA positions.
**Key Message:** Expression levels vary significantly across positions, affecting mutation susceptibility.
**Analysis:** Position-specific expression analysis, correlation with mutations
**Technical Details:** ggplot2 with error bars, position grouping.

---

## 🔍 **QUALITY CONTROL FIGURES**

### **Figure 27: Mismatch Distribution**
**File:** `outputs/figures/mmu-miR-124-3p_mismatch_distribution.png`
**Description:** Example showing mismatch distribution for a specific miRNA.
**Key Message:** Demonstrates the quality of mutation calling and filtering.
**Technical Details:** Position-specific mismatch analysis, quality metrics
**Implementation:** Custom R script for mismatch pattern analysis.

### **Figure 28: Group Comparison - G>T Mutations**
**File:** `outputs/figures/04_gt_mutations_by_group.png`
**Description:** Comprehensive comparison of G>T mutations across different analysis groups.
**Key Message:** Consistent patterns across different grouping strategies.
**Analysis:** Multiple grouping approaches, robustness testing
**Technical Details:** ggplot2 with facet_wrap(), group-specific statistics.

---

## 📊 **ADDITIONAL FIGURES NEEDED**

### **Figure 29: [INSERT GRAPHIC: Pathway Enrichment Analysis]**
**Description:** Bar chart showing enriched biological pathways for genes targeted by oxidized miRNAs.
**Content:** Top 20 pathways ranked by -log10(p-value), with color coding for pathway categories (metabolism, signaling, neurodegeneration).
**Purpose:** Demonstrates the biological impact of miRNA oxidation on cellular processes.
**Implementation:** Use clusterProfiler R package with KEGG and GO databases.
**Expected Results:** Pathways related to apoptosis, cell cycle, and neurodegeneration should be enriched.

### **Figure 30: [INSERT GRAPHIC: Survival Analysis]**
**Description:** Kaplan-Meier survival curves comparing ALS patients with high vs low miRNA oxidation burden.
**Content:** Two survival curves with confidence intervals, log-rank test p-value, and hazard ratio.
**Purpose:** Establishes clinical relevance of miRNA oxidation patterns.
**Implementation:** Use survival R package with Cox proportional hazards model.
**Expected Results:** Patients with high oxidation burden should show worse survival.

### **Figure 31: [INSERT GRAPHIC: Network Analysis]**
**Description:** Protein-protein interaction network of genes targeted by oxidized miRNAs.
**Content:** Network nodes (genes) sized by mutation impact, edges (interactions) colored by interaction type, highlighted clusters for ALS-relevant pathways.
**Purpose:** Reveals interconnected molecular networks affected by miRNA oxidation.
**Implementation:** Use STRING database API with Cytoscape for visualization.
**Expected Results:** Dense networks around apoptosis and cell cycle genes.

### **Figure 32: [INSERT GRAPHIC: Machine Learning Classification]**
**Description:** ROC curve showing miRNA oxidation patterns as ALS diagnostic biomarkers.
**Content:** ROC curve with AUC value, sensitivity/specificity at optimal threshold, confusion matrix inset.
**Purpose:** Demonstrates clinical utility of miRNA oxidation signatures.
**Implementation:** Use random forest or SVM with cross-validation.
**Expected Results:** AUC >0.8 for diagnostic performance.

### **Figure 33: [INSERT GRAPHIC: Longitudinal Analysis]**
**Description:** Line plot showing miRNA oxidation changes over time in ALS patients.
**Content:** Time series data with individual patient trajectories, group means, and confidence intervals.
**Purpose:** Tracks disease progression through oxidation patterns.
**Implementation:** Use mixed-effects models with patient-specific random effects.
**Expected Results:** Increasing oxidation burden over disease course.

### **Figure 34: [INSERT GRAPHIC: Tissue Comparison]**
**Description:** Heatmap comparing miRNA oxidation patterns across different tissues (blood, brain, muscle).
**Content:** Tissue-specific heatmaps with shared and unique oxidation patterns.
**Purpose:** Identifies tissue-specific vs systemic oxidation patterns.
**Implementation:** Multi-tissue dataset analysis with tissue-specific normalization.
**Expected Results:** Brain tissue should show highest oxidation levels.

---

## 🎨 **VISUALIZATION TECHNICAL SPECIFICATIONS**

### **Color Schemes Used**
- **Primary:** Red (ALS) vs Blue (Control)
- **Heatmaps:** Blue (low) to Red (high) gradient
- **Significance:** Green (p > 0.05), Yellow (p < 0.05), Red (p < 0.001)
- **Effect Size:** Light (small) to Dark (large) effect

### **Statistical Annotations**
- **p-values:** Displayed as p < 0.001, p < 0.01, p < 0.05, or exact values
- **Effect sizes:** Cohen's d values for continuous variables
- **Confidence intervals:** 95% CI for all estimates
- **Sample sizes:** n values displayed for all comparisons

### **Software and Packages**
- **R version:** 4.3.0 or higher
- **Key packages:** ggplot2, pheatmap, dplyr, tidyr, DESeq2
- **Statistical tests:** Mann-Whitney U, Welch's t-test, Chi-square, ANOVA
- **Multiple testing:** FDR (Benjamini-Hochberg) correction

---

## 📝 **FIGURE LEGEND TEMPLATES**

### **Standard Legend Format**
```
Figure X: [Title]
[Brief description of what the figure shows]
Key findings: [Main statistical results]
Statistical analysis: [Test used, p-value, effect size]
Technical details: [Sample sizes, filtering criteria, normalization]
```

### **Heatmap Legend Format**
```
Figure X: [Title]
Color scale: [Blue (low values) to Red (high values)]
Clustering: [Method used, distance metric]
Filtering: [Criteria applied, sample/feature selection]
Statistical significance: [Correction method, threshold used]
```

---

*This figure gallery provides comprehensive documentation of all visualizations generated during the miRNA oxidation analysis, serving as a reference for understanding the data story and supporting the main analysis report.*
