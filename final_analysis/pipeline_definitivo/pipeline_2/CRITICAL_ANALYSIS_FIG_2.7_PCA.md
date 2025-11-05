# 🔬 CRITICAL ANALYSIS: FIGURE 2.7 - PCA

**Date:** 2025-10-27  
**Analyst Perspective:** Expert Bioinformatician / Multivariate Analysis Specialist  
**Focus:** Statistical validity, biological interpretation, visualization effectiveness

---

## 📊 **WHAT IS A PCA AND WHY USE IT?**

### **Definition:**

**PCA (Principal Component Analysis):**
```
Dimensionality reduction technique that:
  1. Takes high-dimensional data (many variables)
  2. Finds directions of maximum variance
  3. Projects data onto 2D for visualization

In our case:
  • Input: 415 samples × N miRNAs (high-dimensional)
  • Output: 415 samples × 2 PCs (2D plot)
  • Each point = 1 sample
```

### **Purpose:**

**Question PCA answers:**
```
"Can we separate ALS from Control samples based on their
 G>T mutational profiles across miRNAs?"

Possible outcomes:

A) CLEAR SEPARATION:
   ALS samples cluster separately from Control
   → Strong group-specific signature
   → G>T profile predicts disease status
   
B) OVERLAP:
   ALS and Control samples intermixed
   → High within-group heterogeneity
   → G>T profile does NOT predict disease status
   → Individual variation >> group difference
```

---

## 🔍 **REVIEWING THE CODE LOGIC**

### **STEP 1: Data Preparation**

```r
# Create matrix: samples (rows) × miRNAs (columns)
pca_matrix <- vaf_gt %>%
  filter(miRNA_name %in% all_seed_mirnas) %>%  # Only miRNAs with G>T in seed
  group_by(Sample_ID, miRNA_name) %>%
  summarise(Total_VAF = sum(VAF, na.rm = TRUE)) %>%  # Sum VAF per miRNA per sample
  pivot_wider(names_from = miRNA_name, 
              values_from = Total_VAF, 
              values_fill = 0)
```

**Analysis:**

✅ **CORRECT APPROACH:**
- Per-sample aggregation (each sample = 1 row)
- Sum VAF across all positions for each miRNA
- Focuses on seed miRNAs only (biological focus)

⚠️ **POTENTIAL ISSUES:**

**Issue 1: Missing data handling**
```
values_fill = 0  ← Fills missing with 0

Problem:
  Missing data ≠ VAF of 0
  Missing = miRNA not detected OR no G>T mutation
  
Should consider:
  values_fill = NA  (treat as missing)
  OR: Use only miRNAs present in >50% samples
```

**Issue 2: Data structure**
```
Total_VAF per miRNA = Sum of all G>T VAF at all positions

Example:
  miR-X has G>T at positions 3, 6, 9
  Total_VAF = VAF_3 + VAF_6 + VAF_9
  
Question:
  Is this the right metric?
  Alternative: Use MEAN instead of SUM?
```

---

### **STEP 2: Variance Filtering**

```r
# Filter columns with low variance
col_vars <- apply(pca_data, 2, var, na.rm = TRUE)
pca_data_filt <- pca_data[, col_vars > 0.001]
```

**Analysis:**

✅ **CORRECT:**
- Removes invariant features (no information)
- Standard practice in PCA

⚠️ **CONSIDERATIONS:**

**Threshold of 0.001:**
```
Is this appropriate?

VAF scale: ~0.0001 to ~0.5
Variance of 0.001:
  → SD ≈ 0.032
  → CV ≈ 50-300% (very variable)
  
This threshold:
  ✓ Keeps most informative miRNAs
  ✗ May remove low-abundance but important miRNAs
  
Alternative thresholds:
  - Stricter: 0.01 (only highly variable)
  - Looser: 0.0001 (keep more miRNAs)
  - Percentile: Top 80% by variance
```

**How many miRNAs remain?**
```
Started with: ~301 miRNAs (seed G>T)
After filtering: ??? miRNAs

Critical questions:
  → How many were removed?
  → Are we losing biological signal?
  → Should we report this number?
```

---

### **STEP 3: PCA Calculation**

```r
pca_result <- prcomp(pca_data_filt, scale. = TRUE, center = TRUE)
```

**Analysis:**

✅ **CORRECT PARAMETERS:**
```
scale. = TRUE:
  → Standardizes each miRNA (mean=0, SD=1)
  → Prevents high-variance miRNAs from dominating
  → ESSENTIAL for biological data
  
center = TRUE:
  → Centers each miRNA at 0
  → Standard practice
  → Works with scale=TRUE
```

⚠️ **CRITICAL QUESTIONS:**

**1. What are the PCs capturing?**
```
PC1 = Direction of maximum variance
  → Could be: Batch effects, age, sex, technical artifacts
  → May NOT be ALS vs Control difference!
  
PC2 = Second direction of variance
  → Orthogonal to PC1
  → Often captures second-most important factor
```

**2. How much variance is explained?**
```
Need to check:
  var_exp[1] = PC1 variance explained (should be >10%)
  var_exp[2] = PC2 variance explained
  Cumulative = PC1 + PC2 (should be >30% for meaningful)
  
If PC1+PC2 < 20%:
  ⚠️ Most variance is NOT captured
  → PCA may not be informative
```

**3. What if disease signal is in PC3-PC10?**
```
Problem:
  We only plot PC1 vs PC2
  BUT: ALS signal might be in PC3, PC4, etc.
  
Should check:
  → Correlation of PCs with Group (ALS/Control)
  → PERMANOVA test: Does Group explain variance?
```

---

### **STEP 4: Visualization**

```r
fig_2_7 <- ggplot(pca_coords, aes(x = PC1, y = PC2, 
                                  color = Group, size = Total_VAF)) +
  geom_point(alpha = 0.6) +
  stat_ellipse(aes(fill = Group), geom = "polygon", 
               alpha = 0.1, level = 0.95) +
  scale_color_manual(values = c("ALS" = COLOR_ALS, "Control" = COLOR_CONTROL)) +
  scale_size_continuous(range = c(1, 5), name = "Total G>T VAF")
```

**Analysis:**

✅ **GOOD ELEMENTS:**
- Points colored by group
- Ellipses show 95% confidence regions
- Point size = Total VAF (shows burden)

⚠️ **POTENTIAL ISSUES:**

**Issue 1: Ellipses can be misleading**
```
stat_ellipse(level = 0.95)
  → Assumes bivariate normal distribution
  → May not be true for biological data
  
If data is:
  • Multimodal (multiple clusters)
  • Skewed
  • Has outliers
  
Then ellipses are NOT accurate!

Better alternative:
  • Convex hull (actual boundary)
  • Density contours
  • No ellipse (just points)
```

**Issue 2: Point size by Total_VAF**
```
Concern:
  Total_VAF is correlated with Group (Control > ALS)
  
Result:
  Control points will be LARGER
  → Visual bias (Control looks more prominent)
  → May mislead readers
  
Should consider:
  • All points same size
  • OR: Size by technical variable (coverage)
  • OR: Explain clearly in legend
```

**Issue 3: Overplotting**
```
415 points in 2D space
  → Likely heavy overlap
  → Hard to see individual points
  
Solutions:
  • Reduce alpha (current: 0.6, good!)
  • Add jitter (small random offset)
  • Use smaller points
  • Density contours instead of points
```

---

## 🧬 **BIOLOGICAL INTERPRETATION**

### **Scenario 1: CLEAR SEPARATION**

**Visual:**
```
PC2 ^
    |  ●●●●Control●●●●
    |    ●●●●●●●●
    |              ●●●●ALS●●●●
    |                ●●●●●●●
    +--------------------------> PC1
```

**Interpretation:**
```
✓ G>T profile PREDICTS disease status
✓ Strong biological signature
✓ ALS and Control have distinct patterns

Possible reasons:
  → Different oxidative stress levels
  → Different repair mechanisms
  → Different miRNA expression patterns
  
Next steps:
  → Identify which miRNAs drive separation (loadings)
  → Build classifier (diagnostic potential)
  → Validate in independent cohort
```

---

### **Scenario 2: PARTIAL OVERLAP**

**Visual:**
```
PC2 ^
    |  ●●Control●●
    |   ●●●ALS●●●
    |    ●●●●●●●
    |   ●●●●●●●●
    +--------------------------> PC1
```

**Interpretation:**
```
⚠️ Some separation, but significant overlap
  → Group effect exists but is WEAK
  → High heterogeneity within groups
  → Individual variation >> group difference
  
Consistent with:
  → Figures 2.1-2.2 (small but significant difference)
  → Figure 2.3 (few significantly different miRNAs)
  → Figure 2.5 (small, distributed differences)
```

---

### **Scenario 3: COMPLETE OVERLAP (Most Likely)**

**Visual:**
```
PC2 ^
    |    ●●●●●●●
    |  ●●ALS●Control●●
    |   ●●●●●●●●●
    |    ●●●●●●
    +--------------------------> PC1
```

**Interpretation:**
```
✗ NO meaningful separation
  → G>T profile does NOT predict disease
  → Within-group variation >> between-group
  → Individual differences dominate
  
Biological meaning:
  → G>T mutations are highly variable person-to-person
  → ALS vs Control difference is SUBTLE
  → Requires large sample size to detect (statistical, not visual)
  
Consistent with:
  → Small effect size (Figures 2.1-2.2)
  → Distributed effect (Figures 2.5-2.6)
```

---

## 📉 **WHAT DRIVES PC1 AND PC2?**

### **Critical Question: What do the PCs represent?**

**PC1 could be:**
```
Option A: ALS vs Control difference
  → Best case scenario
  → PC1 separates groups
  
Option B: Total G>T burden
  → PC1 = overall mutation load
  → Correlated with age, sample quality, etc.
  → NOT disease-specific
  
Option C: Batch effect
  → PC1 = sequencing batch, date, etc.
  → Technical artifact
  → CONFOUNDING factor
  
Option D: Individual variation
  → PC1 = person-to-person differences
  → Biological, but not disease-related
```

**How to check:**
```r
# Correlate PC1 with variables
cor(pca_coords$PC1, as.numeric(pca_coords$Group == "ALS"))
cor(pca_coords$PC1, total_vaf$Total_VAF)

# PERMANOVA test
adonis2(pca_data_filt ~ Group, data = metadata, method = "euclidean")

# Check loadings (which miRNAs drive PC1?)
top_loadings <- pca_result$rotation[, 1] %>% sort() %>% head(10)
```

---

## 🎨 **VISUALIZATION CRITIQUE**

### **Current Design Strengths:**

```
✓ Clear group coloring (red/blue)
✓ 95% ellipses (confidence regions)
✓ Point size by Total_VAF (shows burden)
✓ Variance explained in axes labels
✓ Professional theme
```

### **Current Design Weaknesses:**

```
✗ Ellipses assume normality (may not be true)
✗ Point size creates visual bias (Control bigger)
✗ No statistical test displayed (PERMANOVA)
✗ Overplotting possible (415 points)
✗ Doesn't show PC3-PC10 (may contain signal)
```

---

## 💡 **RECOMMENDED IMPROVEMENTS**

### **Improvement 1: Add Statistical Test**

```r
library(vegan)

# PERMANOVA: Test if Group explains variance
permanova_result <- adonis2(pca_data_filt ~ Group, 
                            data = metadata, 
                            method = "euclidean",
                            permutations = 999)

# Add to plot subtitle
subtitle = paste0("PERMANOVA: R² = ", round(permanova_result$R2[1], 3),
                 ", p = ", format.pval(permanova_result$`Pr(>F)`[1], digits = 2))
```

**Why important:**
- Quantifies group separation objectively
- p-value tells if separation is real
- R² tells how much variance is explained by Group

---

### **Improvement 2: Show PC Variance Explained**

```r
# Calculate cumulative variance
var_exp <- summary(pca_result)$importance[2, ] * 100

# Create scree plot (inset or separate)
scree_data <- data.frame(
  PC = 1:10,
  Variance = var_exp[1:10]
)

scree_plot <- ggplot(scree_data, aes(x = PC, y = Variance)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  geom_line(group = 1, color = "red") +
  labs(title = "Variance Explained", x = "PC", y = "% Variance")

# Add as inset to main plot
fig_2_7 + inset_element(scree_plot, left = 0.7, bottom = 0.7, 
                        right = 1, top = 1)
```

**Why important:**
- Shows if PC1+PC2 capture most variance
- If PC1+PC2 < 20% → PCA not very informative

---

### **Improvement 3: Equal Point Sizes**

```r
# Remove size aesthetic (all points same size)
geom_point(alpha = 0.6, size = 2.5) +  # Fixed size
```

**Or: Size by sample quality, not VAF**
```r
# Add technical metadata
metadata$Coverage <- ...
metadata$Read_depth <- ...

aes(size = Coverage)  # Size by technical variable
```

**Why important:**
- Removes visual bias (Control looking more prominent)
- Makes group comparison fair

---

### **Improvement 4: Check PC Correlation**

```r
# Which PCs correlate with Group?
pc_group_cor <- data.frame()
for (i in 1:10) {
  pc_values <- pca_result$x[, i]
  group_numeric <- as.numeric(metadata$Group == "ALS")
  
  cor_result <- cor.test(pc_values, group_numeric)
  
  pc_group_cor <- rbind(pc_group_cor, data.frame(
    PC = i,
    Correlation = cor_result$estimate,
    Pvalue = cor_result$p.value
  ))
}

# If PC3 or PC4 has stronger correlation than PC1:
#   → Should plot PC3 vs PC4 instead!
```

**Why important:**
- Disease signal may not be in PC1-PC2
- Should plot PCs that best show group difference

---

### **Improvement 5: Loadings Analysis**

```r
# Which miRNAs contribute most to PC1?
loadings_pc1 <- pca_result$rotation[, 1]
top_drivers <- names(sort(abs(loadings_pc1), decreasing = TRUE)[1:10])

# Annotate these on the plot
# OR: Create separate loadings plot
```

**Why important:**
- Tells us WHICH miRNAs drive the pattern
- Biological interpretation
- Hypothesis generation

---

## 🔬 **EXPECTED RESULTS (Based on Previous Figures)**

### **Prediction: SIGNIFICANT OVERLAP**

**Rationale:**
```
From Figures 2.1-2.6:
  → Group difference is REAL but SMALL
  → Effect is DISTRIBUTED (not concentrated)
  → High individual variability
  
Expected PCA result:
  → Ellipses overlap significantly
  → No clear visual separation
  → PERMANOVA: R² < 0.05 (Group explains <5% variance)
  → Most variance = individual differences
```

---

### **What Variance Explained Would Mean:**

**If PC1+PC2 = 50-70%:**
```
✓ Most data structure captured in 2D
✓ PCA is informative
✓ Clear interpretation
```

**If PC1+PC2 = 20-40%:**
```
⚠️ Moderate representation
⚠️ Much variance in higher PCs
⚠️ 2D view incomplete
```

**If PC1+PC2 < 20%:**
```
✗ Poor representation
✗ Most variance NOT in PC1-PC2
✗ 2D plot misleading
✗ Consider: t-SNE, UMAP instead
```

---

## 🎯 **BIOLOGICAL SCENARIOS**

### **Scenario A: PC1 Separates Groups**

**Observation:**
```
PC1 correlates with Group (r > 0.5, p < 0.001)
Control samples on left, ALS on right
```

**Interpretation:**
```
✓ PC1 = ALS vs Control axis
✓ G>T profile is disease-specific
✓ Strongest signal in data

Loadings analysis reveals:
  → Which miRNAs differentiate groups
  → Candidate biomarkers
```

---

### **Scenario B: PC1 = Total Burden**

**Observation:**
```
PC1 correlates with Total_VAF (r > 0.8)
BUT: Does NOT separate ALS/Control well
```

**Interpretation:**
```
⚠️ PC1 = overall mutation load
  → Driven by individual variation
  → NOT disease-specific
  
Biological meaning:
  → Some people have high G>T globally
  → Others have low G>T globally
  → This variation >> group difference
```

---

### **Scenario C: No Clear Pattern**

**Observation:**
```
PC1 and PC2 don't correlate with anything obvious
Samples scattered randomly
```

**Interpretation:**
```
✗ No dominant pattern in data
✗ High noise-to-signal ratio
✗ PCA not informative

Possible reasons:
  → Data is too sparse (many zeros)
  → Variance is from noise, not biology
  → Need different analysis approach
```

---

## 🚨 **RED FLAGS TO CHECK**

### **1. Batch Effects**

**Check:**
```
Do samples cluster by:
  • Sequencing batch?
  • Sample collection date?
  • Laboratory?
  • Extraction method?
  
If YES:
  ⚠️ Technical confounding
  → Need batch correction before PCA
```

---

### **2. Outliers**

**Check:**
```
Are there extreme points far from others?

If YES:
  → Check: Technical artifact? (low coverage, contamination)
  → Check: Biological outlier? (extreme phenotype)
  → Consider: Remove and re-run PCA
```

---

### **3. Horseshoe Effect**

**Check:**
```
Do points form a curved arch shape?

If YES:
  ⚠️ Common PCA artifact with sparse data
  → Due to many zeros
  → PCA distorts distances
  → Consider: Log transformation or different method
```

---

## 📊 **ALTERNATIVE/COMPLEMENTARY ANALYSES**

### **Option 1: t-SNE or UMAP**

```r
# Better for non-linear relationships
library(umap)

umap_result <- umap(pca_data_filt)

# Often reveals clusters better than PCA
```

**Advantages:**
- Preserves local structure better
- May reveal clusters PCA misses

**Disadvantages:**
- Non-deterministic (different runs give different results)
- Distances not as interpretable

---

### **Option 2: PERMANOVA (Recommended!)**

```r
library(vegan)

# Direct test: Does Group explain variance?
permanova <- adonis2(pca_data_filt ~ Group, 
                     data = metadata,
                     method = "euclidean",
                     permutations = 9999)

# Result:
#   R² = Fraction of variance explained by Group
#   p-value = Is this significant?
```

**Advantages:**
- Quantitative answer
- Doesn't assume linearity
- Works with any distance metric

---

### **Option 3: Discriminant Analysis**

```r
library(MASS)

# Linear Discriminant Analysis
lda_result <- lda(Group ~ ., data = pca_matrix)

# Predict group membership
predictions <- predict(lda_result)
accuracy <- mean(predictions$class == metadata$Group)
```

**Advantages:**
- Maximizes group separation
- Can assess classification accuracy
- Shows which variables discriminate

---

## 📝 **WHAT TO LOOK FOR IN THE FIGURE**

### **Visual Checklist:**

**1. Axes labels:**
```
✓ PC1 (X%) and PC2 (Y%) shown?
✓ X + Y > 30%?  (meaningful representation)
✓ X + Y < 20%?  (poor representation, ⚠️)
```

**2. Point distribution:**
```
✓ Are groups intermixed or separated?
✓ Are ellipses overlapping or distinct?
✓ Are there obvious outliers?
✓ Is there a horseshoe/arch pattern?
```

**3. Legend clarity:**
```
✓ Group colors clear?
✓ Point size explained?
✓ Sample size noted? (n_ALS, n_Control)
```

**4. Statistical annotation:**
```
✗ Missing: PERMANOVA R² and p-value
✗ Missing: % variance explained by Group
```

---

## 🎯 **EXPERT VERDICT**

### **Figure 2.7 Value: MODERATE TO LOW ⭐⭐**

**Reasons:**

**If groups are well-separated:**
- Value: HIGH ⭐⭐⭐⭐
- Keep as main figure
- Shows clear disease signature

**If groups overlap significantly:**
- Value: LOW ⭐⭐
- Consider removing or moving to supplementary
- Doesn't add much over Figures 2.1-2.6

**Predicted outcome (based on previous figures):**
```
Likely: SIGNIFICANT OVERLAP
  → Because all previous figures show small, distributed effects
  → High heterogeneity expected
  → PCA will reflect this (no clear separation)
```

---

## ✅ **RECOMMENDATIONS**

### **Minimum Required Additions:**

1. **Add PERMANOVA test**
   ```r
   # Quantify group separation
   adonis2(data ~ Group)
   # Add R² and p-value to subtitle
   ```

2. **Report variance explained**
   ```r
   # In subtitle or caption
   "PC1+PC2 explain X% of total variance"
   ```

3. **Remove or fix point size**
   ```r
   # Option A: Fixed size
   geom_point(size = 2.5)
   
   # Option B: Explain bias
   caption = "Point size = Total VAF (Control tends larger)"
   ```

4. **Check for batch effects**
   ```r
   # Color by batch, date, etc. instead of Group
   # Verify no clustering by technical variables
   ```

---

### **Enhanced Version Would Include:**

5. **Scree plot** (variance by PC)
6. **Loadings plot** (which miRNAs drive PCs)
7. **PC3 vs PC4** (in case signal is there)
8. **Density contours** instead of ellipses
9. **Sample size annotation**
10. **Correlation matrix** (PCs vs Group)

---

## 🔬 **BIOLOGICAL CONTEXT**

### **Why PCA for Mutation Data?**

**Advantages:**
```
✓ Unsupervised (doesn't assume groups)
✓ Reduces dimensions (415 samples, many miRNAs → 2D)
✓ Shows global structure
✓ Standard in genomics
```

**Disadvantages:**
```
✗ Assumes linear relationships
✗ Sensitive to outliers
✗ Affected by sparse data (many zeros)
✗ May miss subtle effects
```

---

### **Interpretation Depends on Context:**

**If this is bulk tissue:**
```
Heterogeneity could be:
  → Cell type composition differences
  → Disease stage variability
  → Tissue quality differences
```

**If this is plasma miRNA:**
```
Heterogeneity could be:
  → Age, sex, lifestyle differences
  → Sample collection/processing
  → Individual genetic background
  → Disease subtypes
```

---

## 📊 **QUESTIONS TO ANSWER**

Before approving Figure 2.7, need to know:

1. **What % variance do PC1+PC2 explain?**
   - If < 20% → PCA not very useful

2. **Does Group correlate with PC1 or PC2?**
   - If no → Groups are not separated

3. **What drives PC1?**
   - Total VAF? Age? Batch? Disease?

4. **Are there outliers?**
   - If yes → Investigate (artifact or biology?)

5. **Is PERMANOVA significant?**
   - If yes → Groups differ (even if not visually clear)
   - If no → Groups are indistinguishable

6. **Are there batch effects?**
   - If yes → Need correction

---

## 🎯 **DECISION TREE**

```
Does PERMANOVA show p < 0.05?
  ├─ YES → Groups differ (keep figure, add p-value)
  │   └─ Is R² > 0.05?
  │       ├─ YES → Moderate effect (keep as is)
  │       └─ NO → Small effect (move to supplementary)
  │
  └─ NO → Groups don't differ
      └─ Consider: REMOVE figure (not informative)
          OR: Use to show "no clustering by disease"
```

---

## 📚 **SUMMARY**

### **What Figure 2.7 SHOULD show:**

**Best case:**
- Clear ALS vs Control separation
- Significant PERMANOVA (p < 0.05, R² > 0.05)
- Most variance captured in PC1+PC2

**Realistic case:**
- Partial overlap
- Significant but weak PERMANOVA
- Consistent with small, distributed effect

**Worst case:**
- Complete overlap
- Non-significant PERMANOVA
- Technical artifacts dominate

---

### **Critical Improvements Needed:**

1. ✅ **Add PERMANOVA** (quantify separation)
2. ✅ **Report variance explained** (how meaningful is 2D?)
3. ✅ **Fix point size bias** (equal sizes or explain)
4. ✅ **Check correlations** (what drives PCs?)
5. ✅ **Consider removing** (if not informative)

---

**Next: Review actual figure against these criteria, then improve or replace!**

---

**Created:** 2025-10-27  
**Purpose:** Critical evaluation before final approval  
**Recommendation:** CONDITIONAL (depends on PERMANOVA result and visual separation)

