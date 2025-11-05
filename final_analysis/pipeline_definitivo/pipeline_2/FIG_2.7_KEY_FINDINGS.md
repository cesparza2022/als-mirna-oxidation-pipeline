# 📊 FIGURE 2.7 PCA - KEY FINDINGS & INTERPRETATION

**Date:** 2025-10-27  
**Status:** ✅ **GENERATED WITH STATISTICAL RIGOR**

---

## 🎯 **CRITICAL RESULTS**

### **1. PERMANOVA: Significant but Small Effect**

```
R² = 0.020 (2.0% of variance explained by Group)
p-value = 0.0001 (highly significant)

Interpretation:
  ✅ Group difference is REAL (p < 0.001)
  ⚠️ But effect is SMALL (only 2% of variance)
  ✅ 98% of variance = individual differences, not disease
```

---

### **2. Variance Captured: LOW (⚠️)**

```
PC1: 7.0% variance
PC2: 5.2% variance
Total (PC1+PC2): 12.2% variance

Interpretation:
  ⚠️ Most data structure (88%) is NOT in PC1-PC2
  → 2D plot shows incomplete picture
  → Higher PCs (PC3-PC15) contain most variance
  → PCA may not be best method for this data
```

---

### **3. PC1 Correlates with Group**

```
PC1 correlation with Group: r = 0.325, p = 1.16e-11

Interpretation:
  ✅ PC1 is associated with ALS vs Control
  ✅ Control samples tend toward negative PC1
  ✅ ALS samples tend toward positive PC1
  
  Mean PC1:
    ALS: +0.26
    Control: -0.80
    Difference: 1.06 (groups have different centers)
```

---

### **4. Only 28 miRNAs Used (⚠️)**

```
Started with: 301 seed G>T miRNAs
After variance filter: 28 miRNAs (only 9%!)

Removed: 273 miRNAs with variance < 0.001

Interpretation:
  ⚠️ Most miRNAs have very low variance
  → Sparse data (many zeros)
  → PCA based on only 28 informative miRNAs
  → Results may not generalize
```

---

## 🔬 **WHAT THIS MEANS BIOLOGICALLY**

### **Finding 1: Groups ARE Different (but subtly)**

```
PERMANOVA p < 0.001:
  → Difference is statistically real
  → Not due to chance
  
BUT R² = 0.02:
  → Difference explains only 2% of variance
  → 98% of variance = individual variation
  
Biological meaning:
  → ALS and Control have different G>T profiles
  → BUT: Person-to-person variation is 50x larger!
  → Cannot predict disease from G>T profile alone
```

---

### **Finding 2: PC1 = Disease Axis**

```
PC1 separates ALS (positive) from Control (negative)

This means:
  → PC1 captures the ALS-Control difference
  → Direction of maximum variance aligns with disease
  → Consistent with global burden difference (Fig 2.1-2.6)
```

---

### **Finding 3: Data is Very Sparse**

```
Only 28/301 miRNAs have enough variance to inform PCA

Reasons:
  → Most miRNAs have very low VAF (near zero)
  → High proportion of zero values
  → Only a few miRNAs vary substantially

Implication:
  → G>T burden is concentrated in few miRNAs
  → Most miRNAs contribute little information
  → PCA based on "signal" subset only
```

---

### **Finding 4: Low Dimensionality Capture**

```
PC1+PC2 = only 12.2% of variance

This is LOW for PCA

Possible reasons:
  1. Data is very high-dimensional (complex)
  2. No dominant pattern (variance spread across many PCs)
  3. Data is noisy (technical variation)
  4. Sparse data structure (many zeros)
  
Implication:
  → PCA may not be ideal for this dataset
  → Alternative methods may work better (t-SNE, UMAP)
  → OR: Need to aggregate data differently
```

---

## 📊 **DRIVER miRNAs (LOADINGS)**

### **Top 5 miRNAs Contributing to PC1:**

1. **hsa-miR-1908-3p** - Highest contributor
2. **hsa-miR-584-5p**
3. **hsa-miR-92b-5p**
4. **hsa-miR-6129**
5. **hsa-miR-4508**

**Interpretation:**
```
These miRNAs vary the MOST between ALS and Control

Action items:
  → Investigate these miRNAs specifically
  → Check: Are they known in ALS biology?
  → Validate in independent dataset
  → Potential biomarker candidates
```

---

### **Top 5 miRNAs Contributing to PC2:**

1. **hsa-miR-493-3p**
2. **hsa-miR-6129** (also in PC1!)
3. **hsa-miR-1224-5p**
4. **hsa-miR-584-5p** (also in PC1!)
5. **hsa-miR-92b-5p** (also in PC1!)

**Interpretation:**
```
PC2 = secondary variation axis
  → Not strongly associated with Group (r = 0.066, p = 0.18)
  → Likely: Individual variation, technical factors
  
Note: Some overlap with PC1 drivers
  → These miRNAs vary in multiple directions
```

---

## 🎨 **VISUAL INTERPRETATION GUIDE**

### **What to Look for in Figure 2.7A:**

**Expected observation (based on statistics):**

```
PC1 axis (horizontal):
  ✓ Control samples shifted LEFT (negative PC1)
  ✓ ALS samples shifted RIGHT (positive PC1)
  ✓ Difference in group centers: ~1.06 units
  
But with OVERLAP:
  ⚠️ Some ALS samples in Control region
  ⚠️ Some Control samples in ALS region
  ⚠️ Ellipses overlap significantly
  
Why?
  → Only 2% of variance explained by Group
  → 98% = individual differences
```

---

### **What Figure 2.7B (Scree) Shows:**

```
Expected pattern:
  • PC1 = 7.0% (tallest bar)
  • PC2 = 5.2% (second bar)
  • PC3-PC15 = gradual decline
  • Cumulative (red line) reaches only ~60-70% at PC15
  
Interpretation:
  → Variance is SPREAD across many PCs
  → No single dominant pattern
  → Data is complex/noisy
```

---

### **What Figure 2.7C (Loadings) Shows:**

```
Expected:
  • 10 bars per PC
  • Positive and negative loadings
  • Some miRNAs appear in both PC1 and PC2
  
Use:
  → Identify which miRNAs drive separation
  → Biological follow-up on these miRNAs
  → Validate in literature
```

---

## ✅ **VERDICT**

### **Should we keep Figure 2.7?**

**Arguments FOR keeping:**
```
✅ PERMANOVA is significant (p < 0.001)
✅ PC1 correlates with Group (r = 0.325)
✅ Shows group difference exists
✅ Identifies driver miRNAs (loadings)
✅ Standard analysis in the field
```

**Arguments AGAINST keeping:**
```
⚠️ Only 12.2% variance in 2D (poor representation)
⚠️ Only 2% variance explained by Group (small effect)
⚠️ Likely significant overlap (visual)
⚠️ May be redundant with Figures 2.1-2.6
⚠️ Only 28 miRNAs used (sparse data issue)
```

---

### **RECOMMENDATION:**

**Option 1: KEEP as Supplementary Figure**

**Rationale:**
- Shows that group difference IS detectable
- Identifies candidate biomarker miRNAs
- Complements other analyses
- BUT: Not strong enough for main figure

**Use:**
- Supplementary materials
- Support that difference is multivariate
- Provide loadings for follow-up

---

**Option 2: REPLACE with Better Analysis**

**Proposed: UMAP or t-SNE**

```r
library(umap)

# Non-linear dimensionality reduction
umap_result <- umap(pca_data_filt)

# May reveal clusters better than PCA
# Preserves local structure
```

**OR: Focus on Top Driver miRNAs**

```r
# Instead of all 28 miRNAs, analyze top 5 from loadings
# Create targeted analysis of:
#   - hsa-miR-1908-3p
#   - hsa-miR-584-5p
#   - etc.

# May be more informative than PCA
```

---

### **FINAL DECISION:**

**My recommendation: KEEP as Supplementary**

**Reasons:**
1. Statistically significant (PERMANOVA p < 0.001)
2. Shows PC1 aligns with disease (r = 0.325)
3. Provides candidate miRNAs (loadings)
4. Standard analysis (reviewers expect it)

**BUT:**
- Not strong enough for main figure
- Low variance capture (12.2%)
- Effect is small (R² = 0.02)
- Better suited for supplementary

---

## 📈 **CONSISTENCY WITH OTHER FIGURES**

### **Does PCA fit with Figures 2.1-2.6?**

✅ **Figure 2.1-2.2 (Control > ALS):**
```
PCA shows: Control shifted to negative PC1, ALS to positive
  → Consistent with burden difference
  → PC1 = burden axis
```

✅ **Figure 2.3 (Few significant miRNAs):**
```
PCA shows: Only 28 informative miRNAs
  → Consistent with sparse signal
  → Most miRNAs don't vary much
```

✅ **Figure 2.5 (Distributed differences):**
```
PCA shows: R² = 2% (small effect)
  → Consistent with small, distributed effect
  → Not concentrated in specific miRNAs
```

✅ **Figure 2.6 (Seed depletion):**
```
PCA uses: Total VAF per miRNA (sum across positions)
  → Includes both seed and non-seed
  → Weighted toward non-seed (10x more burden)
  → Separation driven by non-seed mutations
```

**ALL CONSISTENT!** ✅

---

## 🎯 **BIOLOGICAL INTERPRETATION**

### **What PCA Tells Us:**

**Main message:**
```
"ALS and Control samples have statistically distinguishable
 G>T mutational profiles, but individual variation dominates
 (50x larger than group difference)."
```

**Implications:**

1. **Heterogeneity is REAL:**
   - Cannot predict disease from G>T profile alone
   - Need large sample sizes to detect group effect
   - Personalized medicine approach needed

2. **Effect is MULTIVARIATE:**
   - Not driven by single miRNA
   - Involves ~28 miRNAs with variable contributions
   - Complex signature (not simple biomarker)

3. **Candidate Biomarkers Identified:**
   - Top loadings = most discriminative miRNAs
   - Focus on: miR-1908-3p, miR-584-5p, miR-92b-5p
   - Validate in independent cohort

---

## 📊 **NEXT STEPS**

### **1. Review Figures:**
```bash
# Open main figures
open FIG_2.7A_PCA_MAIN_IMPROVED.png  # Main PCA
open FIG_2.7_COMBINED_WITH_SCREE.png # With scree inset
open FIG_2.7C_LOADINGS.png           # Driver miRNAs
```

### **2. Review Statistics:**
```bash
# Check detailed results
open TABLE_2.7_PERMANOVA_results.csv
open TABLE_2.7_PC1_top_loadings.csv
```

### **3. Decision:**
```
Based on visual inspection:
  
  If ellipses overlap heavily:
    → Move to supplementary
    → Note: "Significant but small effect"
    
  If there's visible separation:
    → Could be main figure
    → Highlight PERMANOVA result
```

---

**Created:** 2025-10-27  
**Status:** ✅ Ready for review  
**Recommendation:** Supplementary figure (significant but low variance capture)

