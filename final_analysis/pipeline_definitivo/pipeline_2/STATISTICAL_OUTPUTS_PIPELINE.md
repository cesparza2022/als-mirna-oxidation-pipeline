# 📊 STATISTICAL OUTPUTS - Pipeline Integration

**Integration Status:** ✅ **FULLY INTEGRATED**  
**Last Updated:** 2025-01-29  
**Language:** English

---

## 🎯 **OVERVIEW**

The pipeline automatically generates **statistical tables** alongside all figures. This ensures:
- ✅ Complete reproducibility
- ✅ Transparent reporting
- ✅ Ready for publication supplementary materials
- Linux automated analysis workflows

---

## 📁 **OUTPUT STRUCTURE**

### **Directory:**
```
pipeline_2/
├── figures/                    → Final publication-ready figures (PNG)
├── figures_paso2_CLEAN/        → ALL outputs (figures + tables)
│   ├── FIG_2.X_*.png          → Figures
│   └── TABLE_2.X_*.csv        → Statistical tables ⭐
└── RUN_COMPLETE_PIPELINE_PASO2.R zaw
```

### **Naming Convention:**
```
FIG_2.X_description.png         → Figure outputs
TABLE_2.X_description.csv       → Statistical table outputs
```

---

## 🔗 **PIPELINE INTEGRATION**

### **Automatic Generation:**

When you run:
```bash
Rscript RUN_COMPLETE_PIPELINE_PASO2.R
```

**ALL scripts automatically generate:**
1. ✅ Figures (PNG format)
2. ✅ Statistical tables (CSV format)
3. ✅ Summary output to console

**No extra steps needed** - tables are generated alongside figures.

---

## 📊 **STATISTICAL TABLES BY FIGURE**

### **FIGURE 2.6: Positional Analysis** ⭐ NEWLY ENHANCED

**Script:** `generate_FIG_2.6_POSITIONAL.R`  
**Integration:** ✅ Called automatically by master script (line 130)

**Outputs:**
- `TABLE_2.6_positional_tests_COMPLETE.csv` (all 23 positions)
- `TABLE_2.6_positional_tests_SIGNIFICANT.csv` (FDR < 0.05 only)

**Statistics Included:**
- Descriptive: mean, median, SD, N per group
- Tests: Wilcoxon rank-sum, Student's t-test
- Multiple testing correction: FDR (Benjamini-Hochberg)
- Effect size: Cohen's d (standardized)
- Direction: Effect direction indicator

**Example Usage:**
```r
# Load complete results
all_positions <- read_csv("figures_paso2_CLEAN/TABLE_2.6_positional_tests_COMPLETE.csv")

# Filter significant with large effects
key_positions <- all_positions %>% 
  filter(wilcoxon_padj < 0.05, abs(cohens_d) > 0.5)
```

---

### **FIGURE 2.7: PCA Analysis**

**Outputs:**
- `TABLE_2.7_PERMANOVA_results.csv`
- `TABLE_2.7_PC_correlations.csv`
- `TABLE_2.7_PC1_top_loadings.csv`
- `TABLE_2.7_PC2_top_loadings.csv`
- `TABLE_2.7_variance_explained.csv`

---

### **FIGURE 2.9: Heterogeneity (CV Analysis)**

**Outputs:**
- `TABLE_2.9_CV_summary.csv`
- `TABLE_2.9_CV_all_miRNAs.csv`
- `TABLE_2.9_statistical_tests.csv` (F-test, Levene's, Wilcoxon)
- `TABLE_2.9_top_variable_miRNAs.csv`
- `TABLE_2.9_CV_Mean_correlations.csv`

---

### **FIGURE 2.10: G>T Ratio Analysis**

**Outputs:**
- `TABLE_2.10_global_ratio_summary.csv`
- `TABLE_2.10_statistical_tests.csv`
- `TABLE_2.10_positional_ratios.csv`
- `TABLE_2.10_seed_ratios.csv`
- `TABLE_2.10_per_sample_ratios.csv`

---

### **FIGURE 2.11: Mutation Spectrum**

**Outputs:**
- `TABLE_2.11_spectrum_simplified.csv` (5 categories)
- `TABLE_2.11_spectrum_detailed_12types.csv` (full 12 types)
- `TABLE_2.11_chi_square_simplified.csv`
- `TABLE_2.11_category_counts.csv`

---

### **FIGURE 2.12: Enrichment & Biomarkers**

**Outputs:**
- `TABLE_2.12_all_mirna_stats.csv` (~620 miRNAs)
- `TABLE_2.12_top50_mirnas.csv`
- `TABLE_2.12_family_stats.csv`
- `TABLE_2.12_positional_burden.csv`
- `TABLE_2.12_biomarker_candidates.csv` (112 candidates)

---

## 📋 **STATISTICAL METHODS**

### **Standardized Approach:**

1. **Multiple Testing Correction:**
   - Method: FDR (Benjamini-Hochberg)
   - Applied to: All position-wise and miRNA-wise comparisons
   - Threshold: padj < 0.05 considered significant

2. **Effect Size Calculation:**
   - Method: Cohen's d (standardized mean difference)
   - Interpretation:
     - |d| < 0.2: Negligible
     - |d| < 0.5: Small
     - |d| < 0.8: Medium
     - |d| ≥ 0.8: Large
   - Direction: Positive = Control > ALS

3. **Test Selection:**
   - **Wilcoxon:** Non-parametric (robust to outliers)
   - **t-test:** Parametric (when normality assumed)
   - Both reported: Allows comparison of parametric vs non-parametric

4. **Descriptive Statistics:**
   - Always included: Mean, median, SD, N
   - Enables: Effect size calculation, meta-analysis, reproducibility

---

## ✅ **QUALITY STANDARDS**

### **All Tables Include:**

- [x] Column headers in English
- [x] Consistent naming convention
- [x] FDR correction where appropriate
- [x] Effect sizes (when applicable)
- [x] Sample sizes (N per group)
- [x] Raw and adjusted p-values
- [x] Significance indicators
- [x] Proper decimal precision

### **File Format:**

- Format: CSV (comma-separated)
- Encoding: UTF-8
- Missing values: NA (not empty cells)
- Decimal separator: Period (.)

---

## 🔄 **PIPELINE EXECUTION**

### **Running the Pipeline:**

```bash
cd pipeline_2/
Rscript RUN_COMPLETE_PIPELINE_PASO2.R
```

**Automatic Outputs:**
- 15 figures (PNG format)
- 34+ statistical tables (CSV format)
- Console summary with key results

**No manual intervention needed** - everything is automated.

---

## 📖 **USAGE EXAMPLES**

### **Example 1: Extract Significant Positions**

```r
library(readr)
library(dplyr)

# Load positional test results
pos_tests <- read_csv("figures_paso2_CLEAN/TABLE_2.6_positional_tests_COMPLETE.csv")

# Filter significant positions with large effects
sig_large <- pos_tests %>% 
  filter(wilcoxon_padj < 0.05, abs(cohens_d) > 0.5) %>%
  arrange(desc(cohens_d))

print(sig_large)
```

### **Example 2: Create Publication Table**

```r
# Load significant positions
sig_pos <- read_csv("figures_paso2_CLEAN/TABLE_2.6_positional_tests_SIGNIFICANT.csv")

# Format for publication
pub_table <- sig_pos %>%
  select(position, mean_ALS, mean_Control, 
         wilcoxon_padj, cohens_d, effect_direction) %>%
  mutate(
    wilcoxon_padj = formatC(wilcoxon_padj, format = "e", digits = 2),
    cohens_d = round(cohens_d, 3)
  )

write_csv(pub_table, "Publication_Table_Positions.csv")
```

### **Example 3: Integrate with Biomarker Candidates**

```r
# Load biomarker candidates
biomarkers <- read_csv("figures_paso2_CLEAN/TABLE_2.12_biomarker_candidates.csv")

# Cross-reference with positional results
pos_tests <- read_csv("figures_paso2_CLEAN/TABLE_2.6_positional_tests_COMPLETE.csv")

# Identify positions of interest
hotspots <- pos_tests %>%
  filter(wilcoxon_padj < 0.05, cohens_d > 0.5) %>%
  pull(position)

# Filter biomarkers at these positions
key_biomarkers <- biomarkers %>%
  filter(position %in% hotspots)
```

---

## 📝 **DOCUMENTATION FILES**

1. **STATISTICAL_TABLES_INVENTORY.md** - Complete list of all tables
2. **STATISTICAL_OUTPUTS_PIPELINE.md** - This file (integration guide)
3. **PLAN_FDR_POSITIONAL_TESTS.md** - Implementation notes for Figure 2.6

---

## ✅ **INTEGRATION STATUS**

| Component | Status | Notes |
|-----------|--------|-------|
| Figure 2.6 tables | ✅ Integrated | Automatically generated |
| All other tables | ✅ Integrated | Already existed, documented |
| Master script | ✅ Calls all scripts | No changes needed |
| Output directory | ✅ Organized | All in `figures_paso2_CLEAN/` |
| Documentation | ✅ Complete | This file + inventory |

---

## 🚀 **NEXT STEPS FOR PIPELINE EXPANSION**

See: `PIPELINE_NEXT_STEPS_PROPOSAL.md` (to be created)

**Key Areas:**
1. Add statistical tables export to Paso 1 (exploratory)
2. Create unified summary report (combines all tables)
3. Add metadata JSON for each table
4. Create HTML viewer for tables (browsable interface)
5. Design Paso 4 (mechanistic validation + robustness)

---

**✅ Status: FULLY INTEGRATED AND DOCUMENTED**

