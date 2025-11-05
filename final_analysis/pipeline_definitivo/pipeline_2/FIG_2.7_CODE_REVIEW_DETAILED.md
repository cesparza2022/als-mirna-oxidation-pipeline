# 🔬 FIGURE 2.7 PCA - EXHAUSTIVE CODE & LOGIC REVIEW

**Date:** 2025-10-27  
**Purpose:** Line-by-line analysis of code, data flow, logic, and visualization

---

## 📋 **COMPLETE CODE WALKTHROUGH**

### **STEP 0: Setup**

```r
library(ggplot2)
library(dplyr)
library(tidyr)
library(stringr)
library(pheatmap)
library(tibble)
library(FactoMineR)
library(factoextra)
```

**Analysis:**
- ✅ All necessary packages loaded
- ⚠️ Note: Uses `FactoMineR` and `factoextra` but then uses base `prcomp` (inconsistent)
- 💡 Recommendation: Use ONLY `prcomp` (simpler, base R)

---

### **STEP 1: Load Data**

```r
data <- read.csv("final_processed_data_CLEAN.csv")
metadata <- read.csv("metadata.csv")
seed_ranking <- read.csv("SEED_GT_miRNAs_CLEAN_RANKING.csv")
sample_cols <- metadata$Sample_ID
```

**Inputs:**
1. `final_processed_data_CLEAN.csv` - Main data (from Step 1)
2. `metadata.csv` - Sample annotations (ALS/Control)
3. `SEED_GT_miRNAs_CLEAN_RANKING.csv` - List of miRNAs with G>T in seed

**Logic Check:**
```
✓ Uses metadata.csv (external file with Group info)
  → More flexible than hardcoded pattern
  → Can handle any sample naming convention
  
⚠️ Dependency:
  → Requires metadata.csv to exist
  → Needs to match sample names exactly
```

---

### **STEP 2: Prepare G>T Data**

```r
vaf_gt <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  select(all_of(c("miRNA_name", "pos.mut", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), 
               names_to = "Sample_ID", 
               values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID") %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(!is.na(position), position <= 22)
```

**Step-by-step logic:**

**Line 1: Filter G>T mutations**
```r
filter(str_detect(pos.mut, ":GT$"))

What it does:
  Keeps: "6:GT", "13:GT" ✅
  Removes: "6:GA", "7:AC", "10:GC" ❌
  
Result: Only G>T mutations (focus of study)

Logic: ✅ CORRECT
```

**Lines 2-3: Transform to long format**
```r
pivot_longer(cols = all_of(sample_cols), 
             names_to = "Sample_ID", 
             values_to = "VAF")

BEFORE (wide):
  miRNA    | pos.mut | Sample1 | Sample2 | Sample3
  let-7a   | 6:GT    | 0.02    | 0.01    | 0.03
  
AFTER (long):
  miRNA    | pos.mut | Sample_ID | VAF
  let-7a   | 6:GT    | Sample1   | 0.02
  let-7a   | 6:GT    | Sample2   | 0.01
  let-7a   | 6:GT    | Sample3   | 0.03

Logic: ✅ CORRECT - Standard data transformation
```

**Line 4: Add metadata**
```r
left_join(metadata, by = "Sample_ID")

Adds Group column (ALS or Control) to each row

Logic: ✅ CORRECT - Joins metadata properly
```

**Lines 5-6: Extract position and filter**
```r
mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+")))
filter(!is.na(position), position <= 22)

"6:GT" → position = 6
"13:GT" → position = 13

Filters: position <= 22 (miRNAs can be longer)

Logic: ✅ CORRECT - Standard position extraction
```

---

### **STEP 3: Create PCA Matrix (CRITICAL STEP!)**

```r
pca_matrix <- vaf_gt %>%
  filter(miRNA_name %in% all_seed_mirnas) %>%
  group_by(Sample_ID, miRNA_name) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = miRNA_name, 
              values_from = Total_VAF, 
              values_fill = 0)
```

**Detailed breakdown:**

**Line 1: Filter to seed miRNAs only**
```r
filter(miRNA_name %in% all_seed_mirnas)

all_seed_mirnas = 301 miRNAs with G>T in seed region

Question: Should we use ALL miRNAs or just seed miRNAs?

Current choice: Seed miRNAs only
  ✓ Focused analysis
  ✓ Biological relevance (seed mutations important)
  ✗ Ignores non-seed information
  
Alternative: ALL G>T miRNAs
  ✓ Complete picture
  ✗ May dilute signal
  ✗ More noise
```

**Lines 2-3: Aggregate per sample and miRNA**
```r
group_by(Sample_ID, miRNA_name) %>%
summarise(Total_VAF = sum(VAF, na.rm = TRUE))

What it does:
  For each combination of (Sample, miRNA):
    Sum ALL G>T VAF across all positions
    
Example:
  Sample: ALS-001
  miRNA: let-7a
  G>T at positions: 3, 6, 9
  
  Total_VAF = VAF_pos3 + VAF_pos6 + VAF_pos9
            = 0.01 + 0.02 + 0.015
            = 0.045

Logic: ✅ CORRECT
  → Aggregates positional information
  → Each miRNA = 1 value per sample
  → Ready for PCA
```

**⚠️ CRITICAL DECISION: SUM vs MEAN?**

```
Current: Total_VAF = SUM(VAF across positions)

Problem:
  miRNAs with MORE G>T positions will have HIGHER Total_VAF
  
  Example:
    miR-A: G>T at 3 positions → Sum = 0.06
    miR-B: G>T at 1 position → Sum = 0.05
    
  miR-A appears "higher burden" just because it has more positions!

Alternative: Use MEAN instead
  Mean_VAF = MEAN(VAF across positions)
  
  Example:
    miR-A: Mean = 0.02 (0.06 / 3)
    miR-B: Mean = 0.05 (0.05 / 1)
    
  Now miR-B shows higher burden per position

Which is correct?
  → Depends on biological question!
  → SUM = total mutation load (current)
  → MEAN = average mutation intensity (alternative)
  
For PCA: SUM is reasonable (total burden per miRNA)
But should be DOCUMENTED clearly!
```

**Line 4: Pivot to wide format**
```r
pivot_wider(names_from = miRNA_name, 
            values_from = Total_VAF, 
            values_fill = 0)

Creates matrix:
            let-7a  let-7b  miR-9  ... (301 miRNAs)
  Sample1   0.045   0.023   0.100  ...
  Sample2   0.030   0.015   0.080  ...
  ...
  Sample415 0.050   0.040   0.120  ...

Dimensions: 415 samples × 301 miRNAs

values_fill = 0:
  If a miRNA has NO G>T in that sample → 0
  
⚠️ Is this correct?
  Missing data ≠ VAF of 0
  0 means "no mutation detected"
  But could be:
    a) Truly no mutation (correct)
    b) miRNA not expressed (should be NA?)
    c) Low coverage (should be NA?)
    
For PCA: Filling with 0 is standard
But creates SPARSE matrix (many zeros)
```

---

### **STEP 4: Variance Filtering**

```r
col_vars <- apply(pca_data, 2, var, na.rm = TRUE)
pca_data_filt <- pca_data[, col_vars > 0.001]
```

**What it does:**
```
For each miRNA (column):
  Calculate variance across 415 samples
  
  If variance > 0.001 → KEEP
  If variance ≤ 0.001 → REMOVE (no information)
```

**Mathematical example:**
```
miR-X values across 415 samples:
  [0.01, 0.01, 0.01, 0.01, ...]  (all similar)
  Variance = 0.0001 (very low)
  → REMOVED (no variation = no information for PCA)

miR-Y values:
  [0.001, 0.05, 0.10, 0.002, ...]  (very variable)
  Variance = 0.008 (high)
  → KEPT (variation = informative)
```

**⚠️ IS 0.001 A GOOD THRESHOLD?**

```
Typical VAF: 0.001 to 0.5
Typical SD: ~0.05-0.1
Typical Variance: ~0.0025-0.01

Threshold = 0.001:
  → Removes miRNAs with SD < 0.032
  → Keeps miRNAs with moderate-high variation
  → Seems reasonable

But should check:
  → How many miRNAs removed?
  → Are we losing signal?
  
Output shows: "miRNAs con varianza suficiente: X"
  → If X << 301: Many removed (⚠️)
  → If X ≈ 301: Most kept (✅)
```

---

### **STEP 5: Run PCA**

```r
pca_result <- prcomp(pca_data_filt, scale. = TRUE, center = TRUE)
```

**What happens mathematically:**

**Input matrix:**
```
          miR-1  miR-2  miR-3  ... miR-N
Sample1   0.045  0.023  0.100  ...
Sample2   0.030  0.015  0.080  ...
...
Sample415 0.050  0.040  0.120  ...

Dimensions: 415 × N (where N = miRNAs after filtering)
```

**center = TRUE:**
```
For each miRNA (column):
  Subtract the mean
  
miR-1:
  Mean = 0.042
  Centered values = [0.045 - 0.042, 0.030 - 0.042, ...]
                  = [0.003, -0.012, ...]
  
Result: Each miRNA now has mean = 0
Why: Removes absolute level, focuses on variation
```

**scale. = TRUE:**
```
For each miRNA (column):
  Divide by SD
  
miR-1:
  SD = 0.010
  Scaled values = [0.003/0.010, -0.012/0.010, ...]
                = [0.3, -1.2, ...]
  
Result: Each miRNA now has SD = 1 (unit variance)
Why: Prevents high-variance miRNAs from dominating PC1
```

**PCA calculation:**
```
1. Compute covariance matrix (N × N)
2. Find eigenvectors (directions of variance)
3. Find eigenvalues (amount of variance in each direction)
4. Project data onto eigenvectors

Result:
  PC1 = Direction with MOST variance
  PC2 = Direction with second-most variance
  PC3 = Third-most, etc.
  
  All PCs are ORTHOGONAL (perpendicular)
```

**Output:**
```
pca_result$x:
  Matrix of PC coordinates (415 × N_PCs)
  
pca_result$rotation:
  Loadings (which miRNAs contribute to each PC)
  
pca_result$sdev:
  Standard deviations of PCs
  
summary(pca_result)$importance:
  Variance explained by each PC
```

---

### **STEP 6: Extract Coordinates**

```r
pca_coords <- data.frame(
  Sample_ID = pca_samples,
  PC1 = pca_result$x[, 1],
  PC2 = pca_result$x[, 2]
) %>%
  left_join(metadata, by = "Sample_ID")
```

**What it does:**
```
Creates dataframe:
  Sample_ID  | PC1    | PC2    | Group
  Sample1    | -2.1   | 1.5    | ALS
  Sample2    | 0.8    | -0.3   | Control
  ...

Each row = 1 sample
PC1, PC2 = coordinates in 2D PCA space
Group = ALS or Control (for coloring)
```

**Logic: ✅ CORRECT**

---

### **STEP 7: Add Total VAF for Point Size**

```r
total_vaf <- vaf_gt %>%
  filter(miRNA_name %in% all_seed_mirnas) %>%
  group_by(Sample_ID) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE), .groups = "drop")

pca_coords <- pca_coords %>% left_join(total_vaf, by = "Sample_ID")
```

**What it calculates:**
```
For each sample:
  Total_VAF = SUM of ALL G>T VAF across ALL miRNAs and positions
  
Example (Sample1):
  let-7a, pos 3: 0.01
  let-7a, pos 6: 0.02
  miR-9, pos 5: 0.03
  ... (all 301 miRNAs, all positions)
  
  Total_VAF = 0.01 + 0.02 + 0.03 + ... = 2.15
```

**⚠️ CRITICAL ISSUE: VISUAL BIAS**

```
From previous figures:
  Control > ALS globally
  
Result:
  Control samples have HIGHER Total_VAF
  → Control points will be LARGER in plot
  → Visual bias: Control looks more prominent
  → May mislead interpretation
  
Solutions:
  A) Use fixed size (all points same)
  B) Size by technical variable (coverage, not VAF)
  C) Clearly note bias in caption
  
Current code: Uses Total_VAF
Recommendation: CHANGE to fixed size for fair comparison
```

---

### **STEP 8: Calculate Variance Explained**

```r
var_exp <- summary(pca_result)$importance[2, ] * 100
```

**What it extracts:**
```
summary(pca_result)$importance:
                         PC1    PC2    PC3   ...
Standard deviation       2.1    1.8    1.5   ...
Proportion of Variance   0.15   0.12   0.08  ...  ← This row (* 100)
Cumulative Proportion    0.15   0.27   0.35  ...

var_exp[1] = PC1 variance explained (%)
var_exp[2] = PC2 variance explained (%)
```

**Critical values:**
```
If var_exp[1] = 15%, var_exp[2] = 12%:
  → PC1+PC2 = 27% of total variance
  → 73% of variance is in other PCs!
  → 2D plot shows only partial picture
  
If var_exp[1] = 40%, var_exp[2] = 25%:
  → PC1+PC2 = 65% of total variance
  → 2D plot captures most structure
  → Good representation
  
Threshold for "good PCA":
  PC1+PC2 > 30%: Acceptable
  PC1+PC2 > 50%: Good
  PC1+PC2 < 20%: Poor (⚠️ don't trust 2D view)
```

---

### **STEP 9: Create Plot**

```r
fig_2_7 <- ggplot(pca_coords, aes(x = PC1, y = PC2, 
                                  color = Group, size = Total_VAF)) +
```

**Aesthetic mappings:**
```
x = PC1: Horizontal position
y = PC2: Vertical position
color = Group: Red (ALS) or Blue (Control)
size = Total_VAF: Point size proportional to burden
```

**⚠️ Issue with size:**
- Creates visual bias (Control points bigger)
- Should use fixed size for fair comparison

---

```r
  geom_point(alpha = 0.6) +
```

**Point rendering:**
```
alpha = 0.6: Transparency (60% opaque)
  → Helps with overplotting
  → Can see overlapping points
  
✅ Good choice
  → 415 points will overlap
  → Transparency helps
```

---

```r
  stat_ellipse(aes(fill = Group, group = Group), 
               geom = "polygon", 
               alpha = 0.1, 
               level = 0.95, 
               show.legend = FALSE) +
```

**Ellipse calculation:**

**What `stat_ellipse` does:**
```
For each group:
  1. Calculate mean of (PC1, PC2)
  2. Calculate covariance matrix
  3. Assume bivariate normal distribution
  4. Draw ellipse containing 95% of points (if normal)

Mathematical formula:
  (x - μ)ᵀ Σ⁻¹ (x - μ) = χ²₀.₉₅,₂

Where:
  x = (PC1, PC2)
  μ = group mean
  Σ = covariance matrix
  χ²₀.₉₅,₂ = 95th percentile of chi-square distribution (df=2)
```

**⚠️ CRITICAL ASSUMPTION:**

```
stat_ellipse assumes:
  Data is bivariate normal (bell curve in 2D)

If data is:
  ✗ Multimodal (multiple clusters)
  ✗ Skewed
  ✗ Has outliers
  
Then ellipse is MISLEADING!

Check by visual inspection:
  → Are points evenly distributed around center?
  → Or clustered in sub-groups?
  → Are there far outliers?
  
Better alternatives:
  • Convex hull (actual boundary, no assumptions)
  • Density contours (data-driven)
  • No ellipse (just points with clear separation)
```

---

```r
  scale_color_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_fill_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
```

**Color scheme:**
```
ALS = "#D62728" (red)
Control = "#666666" (gray)

✓ Clear distinction
✓ Standard colors
✓ Consistent with other figures
```

---

```r
  scale_size_continuous(range = c(1, 5), name = "Total G>T VAF") +
```

**Point size mapping:**
```
Smallest Total_VAF → size = 1
Largest Total_VAF → size = 5

Linear scaling between min and max

⚠️ Creates bias (as noted above)
```

---

```r
  labs(
    title = paste0("PCA: Samples by Seed G>T Profile (", ncol(pca_data_filt), " miRNAs)"),
    subtitle = "Using CLEAN DATA (no VAF ≥ 0.5) | Per-sample method",
    x = paste0("PC1 (", round(var_exp[1], 1), "%)"),
    y = paste0("PC2 (", round(var_exp[2], 1), "%)")
  )
```

**Labels:**

**Title:**
```
"PCA: Samples by Seed G>T Profile (N miRNAs)"

✓ Clear and descriptive
✓ Shows number of miRNAs used
✓ Specifies "Seed G>T" (focused analysis)
```

**Subtitle:**
```
"Using CLEAN DATA (no VAF ≥ 0.5) | Per-sample method"

✓ Notes data cleaning step
✓ Notes aggregation method
✓ Transparency for reproducibility
```

**Axes:**
```
"PC1 (X%)" and "PC2 (Y%)"

✓ Shows variance explained
✓ Critical information for interpretation

Should also show:
  "PC1+PC2 = Z% total" (cumulative)
```

---

## 🔢 **MISSING STATISTICAL ANALYSIS**

### **What is NOT in the code but SHOULD be:**

**1. PERMANOVA Test**

```r
library(vegan)

# Test: Does Group explain variance in PCA space?
permanova_result <- adonis2(pca_data_filt ~ Group, 
                            data = metadata,
                            method = "euclidean",
                            permutations = 9999)

# Result:
#   R² = Fraction of variance explained by Group
#   p-value = Significance

# Add to plot
subtitle = paste0(subtitle, 
                 " | PERMANOVA R² = ", round(permanova_result$R2[1], 3),
                 ", p = ", format.pval(permanova_result$`Pr(>F)`[1]))
```

**Why critical:**
```
Visual separation is SUBJECTIVE
PERMANOVA is OBJECTIVE

Tells us:
  → Does Group explain significant variance?
  → How much variance? (R² value)
  → Is separation real or random?
```

---

**2. PC-Group Correlation**

```r
# Does PC1 correlate with Group?
group_numeric <- as.numeric(metadata$Group == "ALS")  # 1=ALS, 0=Control

pc1_group_cor <- cor.test(pca_coords$PC1, group_numeric)
pc2_group_cor <- cor.test(pca_coords$PC2, group_numeric)

# If correlation is strong:
#   → PC separates groups
# If correlation is weak:
#   → PC driven by other factors
```

**Interpretation:**
```
If |cor(PC1, Group)| > 0.3:
  ✓ PC1 is associated with disease status
  
If |cor(PC1, Group)| < 0.1:
  ✗ PC1 is NOT associated with disease
  → PC1 driven by something else (batch, age, etc.)
```

---

**3. Loadings Analysis**

```r
# Which miRNAs contribute most to PC1?
loadings_pc1 <- pca_result$rotation[, 1]
top_10_pc1 <- names(sort(abs(loadings_pc1), decreasing = TRUE)[1:10])

# Create loadings plot
barplot(sort(loadings_pc1[top_10_pc1]), 
        main = "Top 10 miRNAs contributing to PC1")
```

**Why important:**
```
Tells us:
  → WHICH miRNAs drive separation
  → Biological interpretation
  → Candidate biomarkers

Example:
  If let-7a has high loading on PC1:
    → let-7a variation drives PC1
    → Should investigate let-7a specifically
```

---

## 🎨 **VISUAL ANALYSIS OF EXPECTED OUTPUT**

### **What to look for in the actual figure:**

**1. Overall pattern:**
```
✓ Are there TWO distinct clouds (ALS and Control)?
✓ Or ONE mixed cloud?
✓ Are ellipses overlapping or separate?
```

**2. Variance explained:**
```
✓ PC1 = ?%  (should be > 10%)
✓ PC2 = ?%  (should be > 5%)
✓ Total = ?% (should be > 30%)

If total < 20%:
  ⚠️ Most variance is NOT shown in plot
  → 2D view is incomplete
  → May miss important patterns
```

**3. Point distribution:**
```
✓ Are points evenly distributed?
✓ Or clustered in sub-groups?
✓ Are there far outliers?
✓ Is there a horseshoe/arch pattern? (⚠️ artifact)
```

**4. Ellipse overlap:**
```
✓ Completely separate → Strong separation
✓ Partial overlap → Moderate separation  
✓ Complete overlap → No separation
```

---

## 🧬 **BIOLOGICAL INTERPRETATION GUIDE**

### **Interpretation Matrix:**

| PC1+PC2 Variance | Group Separation | Interpretation |
|------------------|------------------|----------------|
| **>50%**, Clear | **Groups distinct** | ✅ Strong disease signature, PCA highly informative |
| **>50%**, Overlap | **Groups mixed** | ⚠️ High individual variation, subtle group effect |
| **30-50%**, Clear | **Groups distinct** | ✅ Moderate signature, some variance not captured |
| **30-50%**, Overlap | **Groups mixed** | ⚠️ Weak signal, most variance = individual differences |
| **<30%**, Clear | **Groups distinct** | ⚠️ May be artifact, check PC3-PC10 |
| **<30%**, Overlap | **Groups mixed** | ❌ PCA not informative, consider removing figure |

---

### **What Each Scenario Means:**

**HIGH variance, CLEAR separation:**
```
Biological meaning:
  → G>T profile is DIAGNOSTIC
  → Could build classifier
  → Strong disease signature
  
Implications:
  → Major finding (feature prominently)
  → Identify driver miRNAs (loadings)
  → Validate in independent cohort
```

**HIGH variance, OVERLAP:**
```
Biological meaning:
  → Individual variation >> group difference
  → Personalized medicine implications
  → Need stratification (ALS subtypes?)
  
Implications:
  → Heterogeneity is real
  → One-size-fits-all approach won't work
  → Need to find subgroups
```

**LOW variance, CLEAR separation:**
```
Suspicious:
  → Separation in low-variance PCs unusual
  → May be confounding variable
  → Check: Batch effect? Sex? Age?
  
Action:
  → Verify with PERMANOVA
  → Check PC3-PC10
  → Investigate technical factors
```

**LOW variance, OVERLAP:**
```
Conclusion:
  → PCA is not informative
  → Data is too noisy/sparse
  → Group effect is very subtle
  
Action:
  → Remove figure (doesn't add value)
  → OR: Use to show "no clear signature"
```

---

## 💡 **IMPROVED VERSION RECOMMENDATIONS**

### **Version 2.7A: Add PERMANOVA**

```r
library(vegan)

# Statistical test
permanova <- adonis2(pca_data_filt ~ Group, 
                     data = metadata,
                     method = "euclidean",
                     permutations = 9999)

# Add to plot
fig_2_7 <- fig_2_7 +
  labs(subtitle = paste0(
    "PERMANOVA: R² = ", round(permanova$R2[1], 3),
    ", p = ", format.pval(permanova$`Pr(>F)`[1], digits = 2),
    " | ", ncol(pca_data_filt), " miRNAs used"
  ))
```

**Why essential:**
- Quantifies group separation objectively
- Shows statistical significance
- R² shows effect size (how much variance Group explains)

---

### **Version 2.7B: Equal Point Sizes**

```r
# Remove size bias
fig_2_7 <- ggplot(pca_coords, aes(x = PC1, y = PC2, color = Group)) +
  geom_point(alpha = 0.6, size = 2.5) +  # FIXED size
  ...
```

**Why important:**
- Fair visual comparison
- Removes Control bias (bigger points)
- Cleaner appearance

---

### **Version 2.7C: Add Scree Plot**

```r
# Create scree plot showing variance by PC
scree_data <- data.frame(
  PC = 1:min(10, ncol(pca_result$x)),
  Variance = var_exp[1:min(10, length(var_exp))]
)

scree <- ggplot(scree_data, aes(x = PC, y = Variance)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  geom_line(aes(group = 1), color = "red", size = 1) +
  labs(title = "Scree Plot", y = "% Variance")

# Add as inset
library(patchwork)
fig_2_7 + inset_element(scree, 0.01, 0.6, 0.3, 0.99)
```

**Why useful:**
- Shows if PC1+PC2 are dominant
- Helps interpret 2D plot
- Standard in PCA presentations

---

### **Version 2.7D: Check All PCs**

```r
# Test correlation of each PC with Group
pc_correlations <- data.frame()
for (i in 1:10) {
  cor_result <- cor.test(pca_result$x[, i], 
                         as.numeric(metadata$Group == "ALS"))
  pc_correlations <- rbind(pc_correlations, data.frame(
    PC = i,
    Correlation = cor_result$estimate,
    Pvalue = cor_result$p.value
  ))
}

# If PC3 or PC4 has stronger correlation:
#   → Plot PC3 vs PC4 instead of PC1 vs PC2!
```

**Why critical:**
- Disease signal may not be in PC1-PC2
- Should plot PCs that best show group difference
- Maximizes biological insight

---

## 🔥 **CRITICAL ISSUES FOUND**

### **Issue 1: No Statistical Test** ⚠️⚠️⚠️

**Problem:**
- Visual separation is subjective
- No objective quantification
- Can't tell if separation is significant

**Fix:**
```r
Add PERMANOVA test
Include R² and p-value in plot
```

**Priority: HIGH** (required for publication)

---

### **Issue 2: Point Size Bias** ⚠️⚠️

**Problem:**
- Control points are larger (higher VAF)
- Creates visual bias
- Makes Control look more prominent

**Fix:**
```r
Use fixed size for all points
OR: Clearly note bias in caption
```

**Priority: MEDIUM** (affects visual interpretation)

---

### **Issue 3: Missing Variance Information** ⚠️

**Problem:**
- Only shows PC1% and PC2% separately
- Doesn't show cumulative (PC1+PC2)
- Doesn't show if 2D is sufficient

**Fix:**
```r
Add: "PC1+PC2 = X% of total variance"
Add: Scree plot (inset or separate)
```

**Priority: MEDIUM** (important for interpretation)

---

### **Issue 4: No Loadings Analysis** ⚠️

**Problem:**
- Don't know which miRNAs drive PCs
- Can't interpret biological meaning
- Missing mechanistic insight

**Fix:**
```r
Calculate and plot top loadings
Identify driver miRNAs
```

**Priority: LOW** (useful but not essential for main figure)

---

## 📊 **EXPECTED FINDINGS (Prediction)**

Based on Figures 2.1-2.6, I predict:

**PCA Result:**
```
PC1 variance: ~15-25%
PC2 variance: ~10-15%
Total: ~25-40% (moderate)

Separation: PARTIAL OVERLAP
  → Ellipses overlap significantly
  → Some ALS points in Control region, vice versa
  → Gradual transition, not sharp boundary

PERMANOVA:
  → R² ≈ 0.02-0.05 (Group explains 2-5% of variance)
  → p < 0.05 (significant, but small effect)
  
Interpretation:
  → Group difference is REAL but SUBTLE
  → Individual variation dominates (95-98% of variance)
  → Consistent with distributed, small-effect model
```

---

## ✅ **ACTION PLAN**

### **To approve Figure 2.7:**

**Step 1: Review current figure**
- Check variance explained (PC1+PC2 total)
- Check visual separation (overlap degree)
- Check for obvious artifacts

**Step 2: Add PERMANOVA**
- Run test
- Add R² and p-value to plot
- Quantify group separation

**Step 3: Fix point size**
- Change to fixed size
- OR: Add clear caption about bias

**Step 4: Decision:**
```
If PERMANOVA R² > 0.05 and p < 0.05:
  → KEEP figure (shows moderate effect)
  → Add improvements
  → Include in main or supplementary
  
If PERMANOVA R² < 0.02 or p > 0.05:
  → REMOVE or move to supplementary only
  → Doesn't add value over other figures
  → Redundant with 2.1-2.6
```

---

**Created:** 2025-10-27  
**Lines analyzed:** 185  
**Issues found:** 4 critical, multiple minor  
**Recommendation:** ADD PERMANOVA before final decision

