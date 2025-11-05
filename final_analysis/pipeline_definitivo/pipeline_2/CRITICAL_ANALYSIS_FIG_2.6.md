# 🔬 CRITICAL ANALYSIS: FIGURE 2.6 - POSITIONAL PROFILES

**Date:** 2025-10-27  
**Analyst Perspective:** Expert Bioinformatician / Data Scientist  
**Focus:** Biological relevance, statistical rigor, visualization effectiveness

---

## 📊 **WHAT WE'RE LOOKING AT**

### **Figure Type:**
Line plot showing mean VAF across miRNA positions (1-22)

### **Data Shown:**
- **Blue line:** Control group mean VAF
- **Red line:** ALS group mean VAF  
- **X-axis:** Position in miRNA (1-22)
- **Y-axis:** Mean VAF (presumably linear scale)
- **Seed region:** Positions 2-8 (likely marked with shading or dashed lines)

### **Question Addressed:**
"Does G>T burden vary by position along the miRNA, and does this pattern differ between ALS and Control?"

---

## 🎯 **BIOLOGICAL INTERPRETATION**

### **What This SHOULD Tell Us:**

**1. Seed Region Specificity:**
```
Biological hypothesis:
  If oxidative damage targets the seed region specifically,
  we should see:
    • HIGHER VAF in positions 2-8
    • LOWER VAF outside seed
    • Potential "spike" or "plateau" in seed region
```

**2. Group Differences:**
```
If ALS has more oxidative stress:
  Red line (ALS) > Blue line (Control)
  
Current finding (from previous figures):
  Blue line (Control) > Red line (ALS) ⚠️
  → Contradicts initial hypothesis
  → Requires biological re-interpretation
```

**3. Positional Hotspots:**
```
Are there specific positions with elevated G>T?
  → Positions 1, 8, 22? (terminal positions)
  → Position 6? (middle of seed)
  → Uniform distribution?
```

---

## 🔍 **CRITICAL QUESTIONS (Expert Review)**

### **1. WHAT IS BEING AVERAGED?**

**Critical issue:** What exactly is "mean VAF"?

```
Option A: Mean across miRNAs first, then across samples
  Mean_VAF_pos_p = mean(mean(VAF_miRNA_i at pos_p across samples))
  
  Problem: Gives equal weight to all miRNAs
           (miRNA with 1 sample = same weight as miRNA with 100 samples)

Option B: Mean across ALL SNVs at that position, then across samples
  Mean_VAF_pos_p = mean(VAF_all_SNVs_at_pos_p across all samples)
  
  Problem: Positions with more miRNAs get more "votes"
  
Option C: Per-sample aggregation first
  For each sample: Total_VAF_pos_p = sum(VAF at pos p)
  Then: Mean_VAF_pos_p = mean(Total_VAF_pos_p across samples)
  
  Best option: Preserves sample-level structure
               Allows proper statistical testing
```

**Question for authors:**
- Which averaging method was used?
- Does this introduce bias?

---

### **2. STATISTICAL SIGNIFICANCE**

**What's MISSING:** Error bars and statistical tests

```
Current figure (probably):
  • Two lines
  • No error bars
  • No p-values
  • No confidence intervals

Should have:
  • Error bars (SD or SE)
  • Statistical test per position
    (Wilcoxon rank-sum: Control vs ALS at each position)
  • Multiple testing correction (Bonferroni or FDR)
  • Asterisks marking significant positions: * p < 0.05, ** p < 0.01
```

**Example improvement:**
```r
# For each position:
for (p in 1:22) {
  test_result <- wilcox.test(
    VAF_Control_at_pos_p, 
    VAF_ALS_at_pos_p
  )
  
  pvalues[p] <- test_result$p.value
}

# Adjust for multiple testing
adjusted_p <- p.adjust(pvalues, method = "fdr")

# Mark significant positions on plot
significant_pos <- which(adjusted_p < 0.05)
```

---

### **3. BIOLOGICAL RELEVANCE OF POSITIONS**

**Issue:** Are all 22 positions biologically equivalent?

```
Functional regions in miRNAs:
  
  Position 1: 
    • 5' end
    • May have lower coverage (technical artifact)
    • Less functionally critical
  
  Positions 2-8: SEED REGION
    • Most critical for target recognition
    • Should be under stronger selection
    • Mutations here = more functional impact
  
  Positions 9-12: Central region
    • Secondary importance
    • Some role in target recognition
  
  Positions 13-22: 3' region
    • Less critical
    • More tolerant to variation
    • Position 22: 3' end (may have lower coverage)
```

**Question:**
- Should we weight positions differently by functional importance?
- Are we comparing "apples to apples"?

---

### **4. COVERAGE BIAS**

**Critical technical issue:** Do all positions have equal coverage?

```
Potential problems:

Terminal positions (1, 22):
  • Often have lower sequencing coverage
  • May have higher error rates
  • PCR artifacts more common
  
Central positions (8-15):
  • Usually have highest coverage
  • Most reliable calls
  
Should check:
  • Mean coverage per position
  • Number of miRNAs with data at each position
  • Filter positions with coverage < threshold
```

**Proposed QC:**
```r
# Check coverage per position
coverage_summary <- data %>%
  group_by(position) %>%
  summarise(
    N_miRNAs = n_distinct(miRNA_name),
    Mean_coverage = mean(coverage, na.rm = TRUE),
    N_samples_with_data = sum(!is.na(VAF))
  )

# Flag low-coverage positions
low_cov_positions <- coverage_summary %>%
  filter(Mean_coverage < 100 | N_samples_with_data < 50)
```

---

## 🎨 **VISUALIZATION CRITIQUE**

### **Current Design (Assumed):**

```
Strengths:
  ✓ Simple, clear concept
  ✓ Direct comparison (two lines)
  ✓ Easy to interpret trends
  
Weaknesses:
  ✗ No uncertainty quantification
  ✗ No statistical significance markers
  ✗ Hides within-group variability
  ✗ Doesn't show sample size per position
  ✗ May not show seed region clearly
```

---

### **ALTERNATIVE VISUALIZATIONS (Better Options):**

#### **Option 1: Ribbon Plot with Confidence Intervals**

```r
ggplot(data_summary, aes(x = position, y = mean_VAF, color = Group)) +
  geom_line(size = 1.2) +
  geom_ribbon(aes(ymin = mean_VAF - se, 
                  ymax = mean_VAF + se, 
                  fill = Group), 
              alpha = 0.2, color = NA) +
  geom_vline(xintercept = c(2, 8), linetype = "dashed", color = "blue") +
  annotate("rect", xmin = 2, xmax = 8, ymin = -Inf, ymax = Inf, 
           alpha = 0.1, fill = "blue") +
  labs(title = "Positional G>T Burden with Confidence Intervals",
       subtitle = "Shaded regions = Standard Error")
```

**Advantages:**
- Shows uncertainty (SE bands)
- Visually shows overlap between groups
- Seed region clearly highlighted

---

#### **Option 2: Faceted by Seed vs Non-Seed**

```r
# Split into seed (2-8) and non-seed (9-22)
data_split <- data %>%
  mutate(Region = ifelse(position >= 2 & position <= 8, "Seed", "Non-seed"))

ggplot(data_split, aes(x = Group, y = VAF, fill = Group)) +
  geom_boxplot() +
  facet_wrap(~Region) +
  stat_compare_means(method = "wilcox.test") +
  labs(title = "G>T Burden: Seed vs Non-Seed Regions")
```

**Advantages:**
- Tests the biological hypothesis directly
- Clear statistical test (seed region special?)
- Simpler than 22 positions

---

#### **Option 3: Heatmap with Annotations**

```r
# Create matrix: Position × Group
matrix_data <- data %>%
  group_by(position, Group) %>%
  summarise(Mean_VAF = mean(VAF, na.rm = TRUE))

# Add statistical tests
pvalues_per_position <- ...

# Heatmap
Heatmap(matrix_data, 
        col = colorRamp2(c(0, max), c("white", "red")),
        row_annotation = significance_markers)
```

**Advantages:**
- Shows magnitude AND significance
- Compact visualization
- Easy to spot hotspots

---

#### **Option 4: Individual Sample Lines (Spaghetti Plot)**

```r
# Show ALL samples (transparent lines)
ggplot(data_per_sample, aes(x = position, y = VAF, 
                              group = Sample_ID, color = Group)) +
  geom_line(alpha = 0.1) +  # Individual samples (faint)
  geom_smooth(aes(group = Group), method = "loess", se = TRUE, 
              size = 2, alpha = 0.3) +  # Group mean (bold)
  facet_wrap(~Group)
```

**Advantages:**
- Shows individual variability
- Reveals outlier samples
- Shows data distribution honestly

---

## 🧬 **BIOLOGICAL CONSIDERATIONS**

### **1. WHAT ARE WE REALLY MEASURING?**

**Issue:** G>T VAF is a composite measure

```
VAF = Variant Allele Fraction
    = N_mutant_reads / (N_mutant_reads + N_wildtype_reads)

But in miRNA-seq:
  • Low abundance miRNAs → low counts → noisy VAF
  • High abundance miRNAs → high counts → reliable VAF
  
Should we weight by:
  • miRNA abundance?
  • Read coverage?
  • Number of samples with data?
```

---

### **2. BIOLOGICAL INTERPRETATION DEPENDS ON PATTERN:**

**Pattern A: Uniform across positions**
```
Observation: All positions ~0.015 VAF, no peaks

Interpretation:
  → G>T mutations occur randomly
  → NO positional specificity
  → Likely global oxidative damage
  → NOT specific to seed region
```

**Pattern B: Seed region elevated**
```
Observation: Positions 2-8 show 2x higher VAF

Interpretation:
  → Seed region MORE susceptible
  → Could be:
      a) Higher oxidative exposure (functional hotspot)
      b) Reduced repair (seed region protected differently)
      c) Selection bias (more impactful mutations detected)
```

**Pattern C: Terminal peaks**
```
Observation: Positions 1 and 22 show high VAF

Interpretation:
  ⚠️ Likely TECHNICAL ARTIFACT
  → Terminal positions = lower coverage
  → Sequencing errors accumulate at ends
  → Should be FILTERED or downweighted
```

**Pattern D: Position 1 spike**
```
Observation: Only position 1 elevated

Interpretation:
  ⚠️ TECHNICAL ARTIFACT
  → 5' end bias in library prep
  → NOT biological signal
  → Should be EXCLUDED from analysis
```

---

### **3. FUNCTIONAL IMPACT VARIES BY POSITION:**

```
Not all G>T mutations are equal:

Position 2-3 (seed nucleation):
  • CRITICAL for target recognition
  • Mutations here = complete loss of function
  • May be under NEGATIVE selection
  • Expected: LOWER VAF (purifying selection)

Position 4-7 (seed complement):
  • Important but less critical
  • Mutations = reduced affinity
  • May be tolerated

Position 8 (supplementary):
  • Enhances binding
  • Less critical than 2-7
  • More tolerant

Position 9-22:
  • Minimal impact on most targets
  • Expected: HIGHER VAF (neutral variation)
```

**Question:**
- Are we seeing selection signature?
- Should VAF pattern match functional importance?

---

## 🔢 **STATISTICAL CONCERNS**

### **1. MULTIPLE TESTING PROBLEM:**

```
We're testing 22 positions independently

Without correction:
  Expected false positives = 22 × 0.05 = 1.1
  → At least one "significant" position by chance!

Solution:
  • Bonferroni: p_threshold = 0.05 / 22 = 0.0023
  • FDR (Benjamini-Hochberg): more lenient
  • Permutation test: shuffle ALS/Control labels 1000x
```

---

### **2. UNEQUAL SAMPLE SIZES:**

```
ALS: N = 313
Control: N = 102

Issues:
  • Unequal power per position
  • Control has 3x larger SE
  • Statistical tests need adjustment
  
Solution:
  • Use tests that handle unequal N (Welch's t-test, Wilcoxon)
  • Report effect size (not just p-value)
  • Consider bootstrapping for CI
```

---

### **3. NON-INDEPENDENCE:**

```
Problem: Same miRNA appears at multiple positions
  → Positions are NOT independent
  → Violates assumptions of most tests

Example:
  let-7a has G>T at positions 3, 6, 9
  → These three data points are LINKED
  → Can't treat as independent observations

Solution:
  • Mixed-effects model:
      VAF ~ Position × Group + (1|miRNA) + (1|Sample)
  • Or: Aggregate to miRNA-level first
  • Or: Permutation test preserving miRNA structure
```

---

## 📈 **WHAT WE'RE DISCOVERING (Likely Findings)**

Based on previous figures, I predict Figure 2.6 shows:

### **Prediction 1: Flat Profile**
```
Expected observation:
  • Both lines relatively flat across positions
  • Control line slightly above ALS (consistent with Fig 2.1)
  • No dramatic seed region elevation
  
Interpretation:
  → G>T burden is DISTRIBUTED
  → NO strong positional specificity
  → Contradicts "seed-specific oxidation" hypothesis
```

### **Prediction 2: Small Differences**
```
Expected observation:
  • Lines very close together
  • Differences < 0.01 VAF at most positions
  • May overlap within error bars
  
Interpretation:
  → Differences are SUBTLE
  → Requires large sample size to detect
  → Effect is REAL but SMALL (from Fig 2.1 p-value)
```

### **Prediction 3: No Terminal Spikes**
```
Expected observation:
  • Position 1 and 22 NOT elevated
  • (If they are → technical artifact)
  
Interpretation:
  → Data quality is good
  → Proper filtering was applied
```

---

## 🚨 **RED FLAGS TO CHECK**

### **Things that would indicate PROBLEMS:**

**1. Position 1 Spike:**
```
If position 1 >> other positions:
  ⚠️ Technical artifact (5' end bias)
  → Exclude position 1 from analysis
```

**2. Sawtooth Pattern:**
```
If alternating high/low VAF:
  ⚠️ Suggests batch effect or systematic error
  → Check for technical confounders
```

**3. Single Position Dominates:**
```
If one position has 10x higher VAF:
  ⚠️ May be driven by a single miRNA
  → Check: Is this one miRNA with huge effect?
  → If yes: Remove and re-plot
```

**4. Lines Cross Multiple Times:**
```
If ALS > Control at some positions, Control > ALS at others:
  ⚠️ Suggests heterogeneity or noise
  → May need stratification by miRNA family
  → Or: Indicates no real positional effect
```

---

## ✅ **WHAT WOULD MAKE THIS FIGURE EXCELLENT**

### **Minimum Requirements:**

1. **Error bars** (SE or 95% CI)
2. **Statistical tests** (per position, with FDR correction)
3. **Seed region highlighted** (shaded box or dashed lines)
4. **Sample sizes** (N per position if variable)
5. **Scale clarity** (linear scale, clearly labeled)

### **Advanced Improvements:**

6. **Inset plot:** Zoom in on seed region (positions 2-8)
7. **Effect size:** Show Cohen's d or log2 fold change
8. **Coverage track:** Bottom panel showing N_miRNAs per position
9. **Functional annotation:** Mark known functional positions
10. **Secondary plot:** Difference (Control - ALS) with CI

---

## 🎯 **REDUNDANCY CHECK**

### **Is Figure 2.6 redundant with other figures?**

**Compared to Figure 2.4 (Heatmap, all miRNAs):**
```
Fig 2.4: Shows VAF per (miRNA × position)
  → Detailed, but hard to see overall trend
  
Fig 2.6: Shows mean VAF per position
  → Summary, easy to see trend
  
Redundant? NO
  → Complementary views
  → Fig 2.4 = detail, Fig 2.6 = summary
```

**Compared to Figure 2.5 (Differential heatmap):**
```
Fig 2.5: Shows (ALS - Control) per (miRNA × position)
  → All 301 miRNAs, differential values
  
Fig 2.6: Shows mean VAF per position, by group
  → Averages across miRNAs
  
Redundant? PARTIALLY
  → Fig 2.5 column means ≈ Fig 2.6 line difference
  → Fig 2.6 adds: Visual comparison + error bars
  
Keep both? MAYBE
  → If Fig 2.6 has good error bars: YES
  → If Fig 2.6 is just two lines: MERGE into Fig 2.5
```

**Compared to Figure 2.3 (Volcano plot):**
```
Fig 2.3: Shows per-miRNA differential (NOT positional)
Fig 2.6: Shows per-position differential (NOT per-miRNA)

Redundant? NO
  → Different questions
  → Fig 2.3 = "which miRNAs differ?"
  → Fig 2.6 = "which positions differ?"
```

---

## 💡 **EXPERT RECOMMENDATIONS**

### **Option A: Keep Figure 2.6 IF:**

Make these improvements:
1. Add error bars (±SE)
2. Add per-position statistical tests
3. Highlight seed region clearly
4. Show effect size (not just means)
5. Add sample size annotation

**Rationale:** Tests positional hypothesis directly

---

### **Option B: Replace with Better Visualization:**

**Proposed: Seed vs Non-Seed Boxplot**

```r
# Instead of 22 positions, compare 2 regions
data %>%
  mutate(Region = case_when(
    position >= 2 & position <= 8 ~ "Seed (2-8)",
    position %in% c(1, 9:22) ~ "Non-seed"
  )) %>%
  ggplot(aes(x = Group, y = VAF, fill = Group)) +
  geom_boxplot() +
  facet_wrap(~Region) +
  stat_compare_means(method = "wilcox.test", 
                     label = "p.format") +
  labs(title = "G>T Burden: Seed vs Non-Seed",
       subtitle = "Testing seed region specificity")
```

**Advantages:**
- Directly tests biological hypothesis
- Clearer statistical test
- Easier to interpret
- Less multiple testing burden

---

### **Option C: Combine with Figure 2.5:**

**Proposed: Enhanced Differential Heatmap**

Add to Figure 2.5:
- Bottom panel: Average differential per position
- Line plot below heatmap
- Shows: Mean(Control - ALS) per position ± SE

**Advantages:**
- Integrates two views
- Saves space
- Shows both detail (heatmap) and summary (line)

---

## 🔬 **BIOLOGICAL CONCLUSIONS (Likely)**

### **If profile is FLAT:**

```
Conclusion:
  → G>T burden is NOT position-specific
  → NO special seed region targeting
  → Global oxidative damage hypothesis supported
  
Implications:
  → Oxidative damage is uniform across miRNA
  → OR: Repair mechanisms are uniform
  → Functional consequences may vary (seed mutations more impactful)
```

### **If seed region is ELEVATED:**

```
Conclusion:
  → Seed region IS preferentially targeted
  
Possible mechanisms:
  a) Seed region more exposed during function
  b) Seed region has different chromatin context
  c) Seed-targeting repair mechanisms less active
```

### **If NO significant positions:**

```
Conclusion:
  → Confirms distributed effect
  → Consistent with Fig 2.5 (mostly light colors)
  
Interpretation:
  → Effect is CUMULATIVE across positions
  → No single "hotspot" position
  → Functional impact from many small changes
```

---

## 📊 **FINAL VERDICT**

### **Figure 2.6 Value: MODERATE ⭐⭐⭐**

**Reasons:**

**Strengths:**
- Tests positional hypothesis directly
- Easy to interpret
- Standard analysis in the field

**Weaknesses:**
- Likely redundant with Figure 2.5
- May show "nothing" (flat profiles)
- Hides miRNA-level heterogeneity
- 22 positions = multiple testing burden

**Recommendation:**

1. **IF seed region shows difference:**
   - KEEP figure (shows important result)
   - Add statistics and error bars
   - Highlight seed clearly

2. **IF profiles are flat:**
   - REPLACE with seed vs non-seed boxplot
   - More direct test of hypothesis
   - Simpler interpretation

3. **IF very similar to Figure 2.5 column means:**
   - MERGE into Figure 2.5
   - Add bottom panel to Fig 2.5
   - Save space, same information

---

## 📝 **QUESTIONS TO ANSWER BEFORE APPROVING:**

1. Does figure have error bars? (If no → REJECT)
2. Are statistical tests shown? (If no → ADD)
3. Is seed region clearly marked? (If no → ADD)
4. Do profiles differ meaningfully? (If no → CONSIDER REPLACING)
5. Is this redundant with Fig 2.5? (If yes → MERGE)
6. Are positions 1 and 22 problematic? (If yes → EXCLUDE)
7. What is sample size per position? (If variable → ANNOTATE)

---

**Created:** 2025-10-27  
**Purpose:** Critical evaluation before approval  
**Next step:** Review actual figure against these criteria

