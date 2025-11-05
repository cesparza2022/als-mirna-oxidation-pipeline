# 📊 STEP 2 REVIEW - Comparative Analysis (ALS vs Control)

**Date:** 2025-10-24  
**Status:** 📋 Ready for Review  
**HTML Viewer:** `pipeline_2/HTML_VIEWERS_FINALES/PASO_2_ANALISIS_COMPARATIVO.html`

---

## 🎯 **WHAT IS STEP 2?**

**Comparative analysis** with VAF filtering to identify differential G>T mutations between ALS and Control groups.

**Key Differences from Step 1:**
- ✅ VAF filtering applied (≥0.5 → NA)
- ✅ Group comparison (ALS vs Control)
- ✅ Statistical testing (Wilcoxon, FDR correction)
- ✅ Differential miRNA identification
- ✅ Volcano plots, PCA, clustering

---

## 📊 **STEP 2 STRUCTURE**

### **PART 1: Quality Control (4 figures)**
- Diagnostic figures for VAF filtering
- Impact assessment

### **PART 2: Comparative Analysis (12 figures in 4 groups)**

#### **Group A: Global Comparisons (3 figures)**
1. `FIG_2.1_VAF_GLOBAL_CLEAN.png` - Global VAF comparison (ALS vs Control)
2. `FIG_2.2_DISTRIBUTIONS_CLEAN.png` - VAF distributions
3. `FIG_2.3_VOLCANO_PER_SAMPLE_METHOD.png` - Volcano plot ⭐

#### **Group B: Positional Analysis (3 figures)**
4. `FIG_2.4_HEATMAP_TOP50_CLEAN.png` - Positional heatmap (top 50)
5. `FIG_2.5_HEATMAP_ZSCORE_CLEAN.png` - Z-score heatmap
6. `FIG_2.6_POSITIONAL_CLEAN.png` - Positional profiles

#### **Group C: Heterogeneity (3 figures)**
7. `FIG_2.7_PCA_CLEAN.png` - PCA (sample separation)
8. `FIG_2.8_CLUSTERING_CLEAN.png` - Hierarchical clustering
9. `FIG_2.9_CV_CLEAN.png` - Coefficient of variation

#### **Group D: G>T Specificity (3 figures)**
10. `FIG_2.10_RATIO_CLEAN.png` - G>T/G>A ratio
11. `FIG_2.11_MUTATION_TYPES_CLEAN.png` - Mutation types heatmap
12. `FIG_2.12_ENRICHMENT_CLEAN.png` - Regional enrichment

### **ADDITIONAL FIGURES (4):**
13. `FIG_2.13_DENSITY_HEATMAP_ALS.png` - Density heatmap ALS
14. `FIG_2.14_DENSITY_HEATMAP_CONTROL.png` - Density heatmap Control
15. `FIG_2.15_DENSITY_COMBINED.png` - Combined density
16. `FIG_2.3_VOLCANO_CLEAN.png` - Alternative volcano (archived)

**Total:** 16 figures

---

## 🔧 **KEY PROCESSES**

### **1. VAF Filtering:**
```r
# Filter: VAF >= 0.5 → NA
data_clean <- data %>%
  mutate(across(sample_cols, ~ifelse(. >= 0.5, NA, .)))
```

### **2. Metadata Creation:**
```r
# Assign groups based on sample ID pattern
metadata <- data.frame(
  Sample_ID = sample_ids,
  Group = ifelse(grepl("ALS", sample_ids), "ALS", "Control")
)
# Result: 313 ALS, 102 Control
```

### **3. Volcano Plot (Critical Method):**
```r
# Per-sample method (CORRECT):
# For each miRNA:
#   1. Calculate total G>T VAF per sample
#   2. Compare ALS samples vs Control samples (Wilcoxon)
#   3. Calculate log2FC from group means
#   4. Adjust p-values (FDR)

# Thresholds:
#   - log2FC > 0.58 (1.5x fold change)
#   - FDR-adjusted p < 0.05
```

---

## 📋 **CURRENT STATUS**

### **✅ What Exists:**
- 16 figures generated in `figures_paso2_CLEAN/`
- HTML viewer created and functional
- Volcano plot uses correct per-sample method
- Statistical testing implemented

### **❓ To Review:**
- Are all 16 figures displaying correctly in HTML?
- Are figure descriptions clear and accurate?
- Any duplications or inconsistencies?
- Color scheme consistent (grey for Control, red for ALS)?
- Statistical annotations correct?

---

## 🎯 **NEXT STEPS FOR CONSOLIDATION**

1. **Review HTML and figures**
   - Check all 16 figures are visible
   - Verify descriptions match figures
   - Check for errors or inconsistencies

2. **Organize like Step 1**
   - Create `STEP2_ORGANIZED/` directory
   - Rename figures with consistent nomenclature
   - Document scripts used
   - Create comprehensive documentation

3. **Critical review**
   - Verify volcano plot method
   - Check statistical tests
   - Validate ALS vs Control comparisons
   - Ensure no hardcoded metadata

---

## 📁 **EXPECTED STEP 2 STRUCTURE (After Consolidation)**

```
STEP2_ORGANIZED/
├── STEP2_FINAL.html
├── figures/
│   ├── step2_fig01_vaf_global.png
│   ├── step2_fig02_distributions.png
│   ├── step2_fig03_volcano.png
│   ├── ... (13 more)
├── scripts/
│   ├── 01_vaf_filtering.R
│   ├── 02_create_metadata.R
│   ├── 03_volcano_analysis.R
│   └── ... (more)
└── documentation/
    └── STEP2_README.md
```

---

**Current HTML viewer is open in Safari.**

¿Puedes revisar el HTML del Paso 2 y decirme si las figuras se ven bien? ¿O si hay algo que necesite corrección? 🔍

