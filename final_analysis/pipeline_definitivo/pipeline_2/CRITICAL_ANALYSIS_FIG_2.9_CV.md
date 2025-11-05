# 🔬 CRITICAL ANALYSIS: FIGURE 2.9 - COEFFICIENT OF VARIATION (CV)

**Date:** 2025-10-27  
**Analyst Perspective:** Expert Bioinformatician / Statistical Analysis Specialist  
**Focus:** Biological relevance, statistical validity, technical correctness

---

## 📊 **WHAT IS COEFFICIENT OF VARIATION (CV)?**

### **Definition:**

```
CV = (Standard Deviation / Mean) × 100

Or simply:
CV = SD / Mean

Units: Percentage (%)

Purpose: Normalized measure of variability
```

### **Interpretation:**

```
CV < 15%:   Low variability (consistent)
CV 15-30%:  Moderate variability
CV > 30%:   High variability (heterogeneous)

Example:
  Mean VAF = 0.05
  SD VAF = 0.01
  CV = 0.01 / 0.05 = 0.20 = 20%

  Mean VAF = 0.05
  SD VAF = 0.02
  CV = 0.02 / 0.05 = 0.40 = 40%

Same mean, but different spread!
```

---

## 🎯 **BIOLOGICAL QUESTIONS ANSWERED**

### **Question 1: Which group is MORE heterogeneous?**

```
"Does ALS have more variable G>T burden than Control?"

If CV_ALS > CV_Control:
  → ALS is more heterogeneous
  → Some ALS samples have high G>T, others have low
  → Suggests sub-groups within ALS
  
If CV_ALS < CV_Control:
  → Control is more heterogeneous
  → Control samples vary more
  → ALS is more uniform
```

### **Question 2: Is variability miRNA-specific?**

```
"Do some miRNAs have high variability while others have low?"

If CV varies widely across miRNAs:
  → Some miRNAs are consistent
  → Others are highly variable
  → May indicate technical issues (unreliable miRNAs)
  
If CV is similar across miRNAs:
  → Consistent data quality
  → Variability is biological (not technical)
```

### **Question 3: Heterogeneity vs Burden**

```
"Are miRNAs with HIGH VAF also HIGH in variability?"

Positive correlation (CV ∼ Mean):
  → High burden samples tend to vary more
  → "Rich get richer, poor get poorer"
  
No correlation:
  → Variability independent of magnitude
  → All miRNAs have similar relative spread
```

---

## 🔍 **CODE REVIEW - FIGURE 2.9**

### **Expected Code Structure (from `generate_PASO2_FIGURES_GRUPOS_CD.R`):**

**STEP 1: Calculate VAF per miRNA per sample**

```r
# Aggregate G>T VAF by miRNA and sample
cv_data <- vaf_gt %>%
  group_by(miRNA_name, Group) %>%
  summarise(
    Total_VAF = sum(VAF, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  group_by(Group, miRNA_name) %>%
  summarise(
    Mean_VAF = mean(Total_VAF, na.rm = TRUE),
    SD_VAF = sd(Total_VAF, na.rm = TRUE),
    CV = (SD_VAF / Mean_VAF) * 100
  )
```

**Critical Analysis:**

✅ **Appropriate aggregation:**
- Per miRNA per group (correct level)
- Then calculate mean and SD
- Then CV = SD/Mean

⚠️ **Potential issues:**
- SD can be unstable with small N
- CV undefined if Mean = 0
- Outliers can inflate SD (and thus CV)

---

**STEP 2: Statistical Testing**

```r
# F-test for variance equality
f_test <- var.test(CV ~ Group, data = cv_data)
```

**Critical Analysis:**

✅ **Test used (F-test):**
- Tests if groups have equal variance
- Appropriate for comparing variability

⚠️ **Assumptions:**
- CV must be normally distributed
- Groups must be independent
- Both assumptions may not hold!

**Better alternatives:**
```r
# Option 1: Levene's test (more robust)
library(car)
leveneTest(CV ~ Group, data = cv_data)

# Option 2: Ansari-Bradley test (non-parametric)
ansari_test <- ansari.test(CV ~ Group, data = cv_data)

# Option 3: Permutation test (no assumptions)
library(coin)
independence_test(CV ~ as.factor(Group), data = cv_data)
```

---

**STEP 3: Visualization**

```r
# Panel A: Boxplots by group
panel_2_9_a <- ggplot(cv_data, aes(x = Group, y = CV, fill = Group)) +
  geom_boxplot()

# Panel B: Distribution of CV values
panel_2_9_b <- ggplot(cv_data, aes(x = Group, y = CV, fill = Group)) +
  geom_boxplot() +
  coord_cartesian(ylim = c(0, quantile(cv_data$CV, 0.95)))
```

**Critical Analysis:**

✅ **Good:**
- Boxplots show distributions
- Jitter adds individual points
- Y-axis filtered (removes outliers)

⚠️ **Issues:**
- **Missing:** Which miRNAs have high CV?
- **Missing:** Is there a pattern?
- **Missing:** Interpretation of CV values
- **Missing:** Correlation with magnitude

---

## 💡 **WHAT SHOULD THIS FIGURE SHOW?**

### **Expected Visual Patterns:**

**Pattern A: ALS has Higher CV**
```
Panel A shows:
  ALS box shifted UP (higher CV)
  Control box shifted DOWN (lower CV)
  
Interpretation:
  ✓ ALS is MORE heterogeneous
  ✓ High variability within ALS group
  ✓ May indicate ALS subtypes
```

**Pattern B: Control has Higher CV**
```
Panel A shows:
  Control box shifted UP
  ALS box shifted DOWN
  
Interpretation:
  ✓ Control is MORE heterogeneous
  ⚠️ Unexpected (Control should be more uniform)
  ✓ May indicate age, comorbidities vary in Control
```

**Pattern C: Similar CV**
```
Panel A shows:
  Overlapping boxes
  No clear difference
  
Interpretation:
  ✓ Similar heterogeneity in both groups
  ✓ Variability is biological, not disease-specific
```

---

## 🔬 **DETAILED EXPECTATIONS**

### **What We KNOW from Previous Figures:**

**From Figure 2.1-2.2:**
```
Control > ALS globally
SD likely similar or Control larger
→ CV_Control might be LOWER (higher mean, similar SD)
→ OR CV might be similar

Need to check!
```

**From Figure 2.7 (PCA):**
```
R² = 2% (Group explains little variance)
98% = individual differences
→ Expect HIGH CV overall
→ Large inter-sample variation in both groups
```

**From Figure 2.6:**
```
Non-seed >> Seed (10x difference)
→ Some miRNAs have high burden (non-seed)
→ Some miRNAs have low burden (seed)
→ CV might be HIGH due to this spread
```

---

## 📊 **WHAT TO LOOK FOR**

### **Visual Checklist:**

**1. Boxplot overlap:**
```
If boxes overlap completely:
  → No difference in heterogeneity
  
If boxes are separate:
  → Groups have different variability
```

**2. Box width (IQR):**
```
Narrow box (small IQR):
  → Consistent CV across miRNAs
  
Wide box (large IQR):
  → Some miRNAs very variable, others stable
```

**3. Outliers:**
```
Many outliers above box:
  → Several miRNAs have VERY high CV
  → May need to investigate (technical issue?)
  
Few outliers:
  → Most miRNAs similar variability
```

---

## 🔢 **MATHEMATICAL ISSUES TO CHECK**

### **Issue 1: CV with Near-Zero Means**

**Problem:**
```r
If Mean_VAF ≈ 0:
  CV = SD / 0 = Inf or undefined
  → Can distort analysis!
```

**How handled:**
```r
Should filter:
  cv_data <- cv_data %>% filter(Mean_VAF > 0.001)
  
OR use alternative:
  CV_alternative = SD / (Mean + 0.001)
  
Check in code!
```

---

### **Issue 2: CV Outliers**

**Problem:**
```
A few miRNAs with extreme CV can distort:
  → Mean CV
  → Boxplots
  → Statistical tests
```

**Solution:**
```r
# Identify outliers
outliers <- cv_data %>%
  filter(CV > quantile(CV, 0.99))

# Either:
# A) Remove outliers
# B) Transform (log, sqrt)
# C) Use robust statistics (median, MAD)
```

---

### **Issue 3: Sample Size per miRNA**

**Problem:**
```
CV calculated from N samples per miRNA
If N is small (< 5):
  → SD is unreliable
  → CV is not trustworthy
```

**Should report:**
```r
cv_data %>% 
  group_by(miRNA_name) %>%
  summarise(N_samples = n())

# Filter miRNAs with insufficient data
cv_data_filtered <- cv_data %>%
  filter(N_samples >= 5)
```

---

## 🧬 **BIOLOGICAL INTERPRETATION**

### **High CV in ALS could mean:**

**1. Disease Subtypes**
```
If ALS has high CV:
  → ALS is heterogeneous
  → Multiple ALS subtypes
  → Some patients high G>T, others low
  → Important for personalized medicine!
```

**2. Disease Stage**
```
If included samples at different stages:
  → Early stage = low G>T
  → Late stage = high G>T
  → High CV due to stage mixing
```

**3. Treatment Effects**
```
If some patients are treated:
  → Treatment reduces G>T?
  → Treated vs untreated = high variability
  → CV reflects treatment heterogeneity
```

---

### **High CV in Control could mean:**

**1. Age Spread**
```
If Controls vary in age:
  → Older = more oxidative damage
  → Younger = less oxidative damage
  → CV reflects age heterogeneity
```

**2. Comorbidities**
```
If Controls have various health conditions:
  → Some healthy (low G>T)
  → Some less healthy (higher G>T)
  → CV reflects health heterogeneity
```

**3. Sampling Issues**
```
If Controls are not well-matched:
  → Diverse sources
  → Different protocols
  → CV reflects technical heterogeneity
```

---

## 📊 **CORRELATION WITH MAGNITUDE**

### **Important Question:**

**Is CV correlated with Mean VAF?**

```r
# Test: Does high-burden miRNA = high variability?
cor_test <- cor.test(cv_data$Mean_VAF, cv_data$CV)

# If positive correlation:
#   High-burden miRNAs are more variable
#   
# If negative correlation:
#   High-burden miRNAs are more consistent
#
# If no correlation:
#   Variability independent of magnitude
```

**Why important:**
```
If CV correlates with Mean:
  → Scaling issue (technically)
  → OR: Biological (high-burden miRNAs less stable)
  
If CV doesn't correlate:
  → Variability is intrinsic
  → Not due to measurement artifacts
```

---

## 🎨 **IMPROVEMENTS RECOMMENDED**

### **Improvement 1: Add Scatter Plot (CV vs Mean)**

```r
# Show CV as function of mean
ggplot(cv_data, aes(x = Mean_VAF, y = CV, color = Group)) +
  geom_point(alpha = 0.7) +
  geom_smooth(method = "lm") +
  labs(x = "Mean VAF", y = "CV (%)")

# Reveals:
#   - Is high CV in high-burden miRNAs?
#   - Correlation between magnitude and variability
```

---

### **Improvement 2: Add Top Variable miRNAs Table**

```r
# Top 10 most variable miRNAs
top_variable <- cv_data %>%
  arrange(desc(CV)) %>%
  head(10)

# Add to plot as labels
geom_text(data = top_variable, 
          aes(label = miRNA_name))
```

**Why:**
- Shows WHICH miRNAs are most heterogeneous
- Biological interpretation
- Validation targets

---

### **Improvement 3: Stratify by miRNA Family**

```r
# Add family information
cv_data <- cv_data %>%
  mutate(family = str_extract(miRNA_name, "miR-\\d+|let-7"))

# Plot with family facet
ggplot(cv_data, aes(x = Group, y = CV)) +
  facet_wrap(~family) +
  geom_boxplot()
```

**Why:**
- Tests if variability is family-specific
- Reveals biological patterns
- Groups related miRNAs

---

### **Improvement 4: More Robust Tests**

```r
# Use Levene's test (more robust than F-test)
library(car)
levene_result <- leveneTest(CV ~ Group, data = cv_data)

# Non-parametric alternative
ansari_result <- ansari.test(CV ~ Group, data = cv_data)

# Include both in results
```

**Why:**
- F-test assumes normality (may not hold)
- Levene's more robust to outliers
- Provides multiple perspectives

---

### **Improvement 5: Distribution Comparison**

```r
# Compare distributions directly
library(gghalves)

ggplot(cv_data, aes(x = Group, y = CV, fill = Group)) +
  geom_half_violin(side = "l", alpha = 0.5) +
  geom_half_boxplot(side = "r", outlier.shape = NA) +
  geom_jitter(alpha = 0.3)

# Shows:
#   - Full distribution shape
#   - Skewness
#   - Bimodality
```

---

## 🎯 **EXPECTED RESULTS (Predictions)**

Based on previous figures:

**Prediction 1: CV will be HIGH overall**
```
From Fig 2.7: R² = 2% (98% individual variance)
→ Expect mean CV > 30% (high heterogeneity)
```

**Prediction 2: Groups will be SIMILAR**
```
From Fig 2.1-2.6: Small differences, distributed
→ CV_ALS ≈ CV_Control
→ F-test: p > 0.05 (no significant difference)
```

**Prediction 3: High-burden miRNAs more variable**
```
From Fig 2.6: Non-seed >> Seed (10x)
→ miRNAs with high mean will have high CV
→ Positive correlation
```

---

## 📊 **QUESTIONS TO ANSWER**

### **Before Approving Figure 2.9:**

**1. What are the actual CV values?**
```
Mean CV_ALS = ?
Mean CV_Control = ?
Range of CV = ?
```

**2. Is CV correlated with Mean VAF?**
```
Correlation coefficient = ?
Is it significant?
Linear or non-linear?
```

**3. Which miRNAs have extreme CV?**
```
Top 10 most variable miRNAs = ?
Are they technically problematic?
Or biologically interesting?
```

**4. Does F-test show difference?**
```
p-value = ?
Significant or not?
How does this relate to other tests?
```

**5. Are there outliers to investigate?**
```
Which miRNAs are outliers?
Why are they so variable?
Should they be removed?
```

---

## ✅ **DECISION CRITERIA**

### **Approve Figure 2.9 IF:**

✅ CV values are reasonable (20-50% typical for biological data)  
✅ F-test properly reported  
✅ No extreme outliers unexplained  
✅ Interpretation is clear  
✅ Statistically valid  

### **Improve/Reject IF:**

❌ CV has many infinite values (mean ≈ 0 problem)  
❌ No statistical test reported  
❌ Many outliers not addressed  
❌ Unclear what CV represents  
❌ Technical issues dominate  

---

## 🔬 **ALTERNATIVE ANALYSES**

### **If CV doesn't show differences, try:**

**Option 1: Variance Ratio (F-statistic per miRNA)**
```r
# Calculate F-statistic for each miRNA
cv_data <- cv_data %>%
  group_by(miRNA_name) %>%
  mutate(F_ratio = var(Total_VAF[Group == "ALS"]) / 
                    var(Total_VAF[Group == "Control"]))

# miRNAs with F > 2 or F < 0.5:
#   Significant difference in variability
```

**Option 2: Robust CV (based on median)**
```r
# Use MAD/Median instead of SD/Mean
cv_robust <- function(x) {
  mad(x, na.rm = TRUE) / median(x, na.rm = TRUE) * 100
}
```

**Option 3: Explore miRNA-Specific CV**
```r
# Plot CV by miRNA
ggplot(cv_data, aes(x = reorder(miRNA_name, CV), y = CV, fill = Group)) +
  geom_bar(stat = "identity", position = "dodge") +
  coord_flip() +
  facet_wrap(~Group)

# Shows which miRNAs are most/least variable
```

---

## 📝 **WHAT TO INCLUDE**

### **Minimum Requirements:**

1. ✅ Boxplots by group (current)
2. ⭐ **Add:** Statistical test results (F-test p-value)
3. ⭐ **Add:** Mean CV values for each group
4. ⭐ **Add:** Table of top 10 most variable miRNAs
5. ⭐ **Add:** Interpretation of CV values

### **Enhanced Version Would Include:**

6. Scatter plot (CV vs Mean VAF)
7. Violin plots (full distribution)
8. miRNA-specific breakdown
9. Levene's test in addition to F-test
10. Outlier identification and justification

---

## 🎯 **RECOMMENDATION**

### **Status: CONDITIONAL ⭐⭐⭐**

**Approve IF:**
- Clean data (no infinite CV values)
- Statistical test reported
- Reasonable CV ranges (20-100% typical)

**Improve IF:**
- Need more interpretation
- Want correlation analysis
- Need miRNA-specific breakdown

**Predicted Outcome:**
```
Likely: CV similar in both groups (consistent with Fig 2.7)
OR: Control slightly higher CV (age/comorbidities)

Either way: Useful for quantifying heterogeneity!
```

---

## 🚀 **NEXT STEPS**

### **1. Open and Review Current Figure**

```bash
open FIG_2.9_CV_CLEAN.png
```

**Check:**
- Are boxes overlapping or separate?
- What are typical CV values?
- Are there many outliers?
- Is the difference noticeable?

### **2. If Needed: Generate Enhanced Version**

```r
# Add:
# - Scatter plot (CV vs Mean)
# - Top variable miRNAs table
# - Better tests
# - Interpretation
```

### **3. Make Decision:**
```
Keep as-is / Improve / Reject

Based on biological significance and visual clarity
```

---

**Created:** 2025-10-27  
**Purpose:** Critical review of CV analysis  
**Status:** Ready for decision

