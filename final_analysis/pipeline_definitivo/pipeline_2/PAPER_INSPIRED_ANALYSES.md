# 📖 PAPER-INSPIRED ANALYSES FOR PIPELINE_2

## 🎯 **KEY INSIGHTS FROM RESEARCH & PRD**

Based on:
1. Modern oxidative RNA damage literature (Wheeler et al, 2024)
2. Your comprehensive PRD (adaptive ALS miRNA notebook)
3. Standard bioinformatics practices

---

## 🔬 **ANALYSES WORTH IMPLEMENTING**

### **CATEGORY 1: INITIAL CHARACTERIZATION** (GENERIC - NO METADATA)

#### ✅ **ALREADY IMPLEMENTED (Figure 1):**
1. Dataset overview & mutation type distribution
2. G>T positional frequency
3. Seed vs non-seed comparison
4. Overall mutation spectrum

#### 🆕 **ADDITIONAL ANALYSES TO ADD (Still generic, no metadata):**

**1.1 G-Content Correlation** ⭐⭐⭐⭐⭐
```r
# Question: Does G-content in seed region correlate with G>T frequency?
# Why: Mechanistic validation of oxidative susceptibility
# Input: Sequence data (can derive from miRNA names + miRBase)
# Output: Scatter plot (G-content vs G>T frequency)
```
**Inspiration:** Wheeler paper shows sequence context matters  
**Value:** Validates that G>T is oxidative, not random  
**Complexity:** Medium (need miRNA sequences)

**1.2 Sequence Context Analysis** ⭐⭐⭐⭐
```r
# Question: What nucleotides flank G>T mutations (±1 position)?
# Why: 8-oxoG has sequence preferences (GGG, GGC contexts)
# Input: miRNA sequences + G>T positions
# Output: Sequence logo or enrichment heatmap
```
**Inspiration:** Standard for oxidative damage validation  
**Value:** Mechanistic evidence  
**Complexity:** Medium

**1.3 Position-Specific Mutation Spectrum** ⭐⭐⭐⭐
```r
# Question: At each position, what's the proportion of G>T vs G>A vs G>C?
# Why: Shows if G>T is specifically enriched (not all G>X)
# Input: Current processed data
# Output: Stacked bar chart (already partially implemented)
```
**Inspiration:** PRD Q7  
**Value:** Specificity of G>T signal  
**Complexity:** Low (can enhance Panel C)

---

### **CATEGORY 2: COMPARATIVE ANALYSIS** (REQUIRES METADATA)

#### 🆕 **FOR STEP 2 (Group Comparison - GENERIC FRAMEWORK):**

**2.1 Global G>T Burden Comparison** ⭐⭐⭐⭐⭐
```r
# Question: Is overall G>T burden higher in Group A vs Group B?
# Method: Per-sample G>T count/fraction → Wilcoxon/t-test
# Input: processed_data + sample_groups.csv (user-provided)
# Output: Violin/boxplot + statistical test results
```
**Inspiration:** PRD Q3, standard in all papers  
**Value:** PRIMARY HYPOTHESIS TEST  
**Complexity:** Low (well-established method)  
**Generic:** ✅ Accepts any grouping file

**2.2 Position-Specific Differences** ⭐⭐⭐⭐⭐
```r
# Question: Which positions show group differences?
# Method: Per-position Wilcoxon test + FDR correction
# Input: processed_data + sample_groups.csv
# Output: Delta curve (like your favorite figure from PRD Q10)
```
**Inspiration:** PRD Q8, Q10 - Your favorite figure style  
**Value:** Pinpoints WHERE differences occur  
**Complexity:** Medium  
**Generic:** ✅ Group-agnostic

**2.3 Seed vs Non-Seed Enrichment by Group** ⭐⭐⭐⭐
```r
# Question: Is seed region MORE affected in one group?
# Method: 2×2 contingency table (Seed/Non-seed × Group A/Group B)
# Input: processed_data + sample_groups.csv
# Output: OR, CI, Fisher's exact test
```
**Inspiration:** PRD Q9, functional relevance  
**Value:** Tests functional impact hypothesis  
**Complexity:** Low  
**Generic:** ✅ Group-agnostic

**2.4 Per-miRNA Enrichment Analysis** ⭐⭐⭐⭐
```r
# Question: Which miRNAs show significant G>T enrichment in Group A?
# Method: Per-miRNA Fisher's test + FDR correction
# Input: processed_data + sample_groups.csv
# Output: Volcano plot, ranked table
```
**Inspiration:** PRD Q11, biomarker discovery  
**Value:** Identifies candidate miRNAs  
**Complexity:** Medium  
**Generic:** ✅ Works with any grouping

---

### **CATEGORY 3: ADVANCED CHARACTERIZATION** (OPTIONAL METADATA)

**3.1 Clustering Analysis** ⭐⭐⭐
```r
# Question: Do miRNAs cluster by seed mutation patterns?
# Method: Ward/HDBSCAN on seed position vectors (2-8)
# Input: Processed data only (no metadata needed)
# Output: Dendrogram, heatmap, cluster membership
```
**Inspiration:** PRD Q13-Q15  
**Value:** Discovers mutation signatures  
**Complexity:** High  
**Generic:** ✅ No metadata required  
**Enhancement:** If groups provided, test cluster-group association

**3.2 Covariate Adjustment** ⭐⭐⭐⭐⭐ (If demographics available)
```r
# Question: Are group differences independent of age/sex/batch?
# Method: Multivariate models (group + age + sex + batch)
# Input: demographics.csv (OPTIONAL, user-provided)
# Output: Adjusted p-values, effect sizes
```
**Inspiration:** Standard practice, PRD Q21-Q22  
**Value:** CRITICAL for validity  
**Complexity:** Medium  
**Generic:** ✅ Optional - only if user provides data

---

## 🎨 **FIGURE STRUCTURE RECOMMENDATIONS**

### **FIGURE 1 (CURRENT):** ✅ KEEP AS-IS
**Status:** Complete and generic  
**Panels:** 4 panels (A-D)  
**No metadata required:** ✅

---

### **FIGURE 2 (PROPOSED): GROUP COMPARISON**
**Requires:** `sample_groups.csv` (user-provided)  
**Panels:** 4 panels

**Panel A: Global G>T Burden by Group** ⭐⭐⭐⭐⭐
- Violin/boxplot
- Wilcoxon test results
- Effect size (Cohen's d or OR)

**Panel B: Position-Specific Differences** ⭐⭐⭐⭐⭐
- Delta curve (Group A - Group B) per position
- Seed region shaded
- Stars for significant positions (q < 0.05)
- **This is your favorite figure from PRD Q10!**

**Panel C: Seed vs Non-Seed by Group** ⭐⭐⭐⭐
- 2×2 comparison
- Interaction plot
- OR with CI

**Panel D: Top Differential miRNAs** ⭐⭐⭐⭐
- Volcano plot (log2FC vs -log10 p-value)
- Top 10 labeled
- FDR threshold line

---

### **FIGURE 3 (PROPOSED): MECHANISTIC VALIDATION**
**Requires:** miRNA sequences (from miRBase - public)  
**Panels:** 3-4 panels

**Panel A: G-Content vs G>T Frequency** ⭐⭐⭐⭐⭐
- Scatter plot
- Spearman correlation
- Shows dose-response (more G's → more oxidation)
- **You already have this from previous analysis!**

**Panel B: Sequence Context Around G>T** ⭐⭐⭐⭐
- Enrichment of flanking nucleotides (±1 position)
- Sequence logo
- Compare to known 8-oxoG preferences

**Panel C: G>T vs Other G>X Mutations** ⭐⭐⭐
- Specificity analysis
- Shows G>T is enriched, not all G>X equally

**Panel D (Optional): Clustering Heatmap** ⭐⭐⭐
- miRNAs clustered by seed mutation pattern
- Only if adds insight beyond Figure 2

---

### **FIGURE 4 (OPTIONAL): CONFOUNDERS**
**Requires:** `demographics.csv` (optional)  
**Only if user provides this data**

**Panels:**
- Age distribution by group
- Sex distribution by group
- Adjusted vs unadjusted effect sizes
- Batch effect assessment (if applicable)

---

## 🚀 **IMPLEMENTATION PRIORITY**

### **HIGH PRIORITY** (Implement Next):

1. **G-Content Correlation (Figure 3, Panel A)** ⭐⭐⭐⭐⭐
   - Can be done NOW (no metadata)
   - Strong mechanistic validation
   - You already did this in previous analysis!
   - Just needs to be ported to pipeline_2

2. **Sequence Context Analysis (Figure 3, Panel B)** ⭐⭐⭐⭐
   - Can be done NOW (no metadata)
   - Validates 8-oxoG signature
   - Moderate complexity

3. **Enhanced Position-Specific Spectrum** ⭐⭐⭐⭐
   - Enhance current Panel C
   - Show G>T vs G>A vs G>C proportions
   - Already partially implemented

### **MEDIUM PRIORITY** (After metadata integration):

4. **Group Comparison Framework (Figure 2)** ⭐⭐⭐⭐⭐
   - Design generic comparison functions
   - Create templates for user configuration
   - Implement statistical tests

5. **Clustering Analysis** ⭐⭐⭐
   - Discover mutation signatures
   - Can enhance with group association if metadata available

### **LOW PRIORITY** (Optional/Advanced):

6. **Covariate Adjustment (Figure 4)**
   - Only if user provides demographics
   - Template-based approach

---

## 📋 **RECOMMENDED NEXT ACTIONS**

### **Option A: Enhance Figure 1 with Mechanistic Validation** (NO METADATA)
**Advantage:** Can do NOW, strengthens current results
**Actions:**
1. Add G-content correlation panel (port from previous analysis)
2. Add sequence context panel (new analysis)
3. Create "Extended Figure 1" or "Figure 1 Supplement"

### **Option B: Design Generic Comparison Framework** (PREPARE FOR METADATA)
**Advantage:** Prepares for future use with any dataset
**Actions:**
1. Create configuration templates
2. Design group comparison functions
3. Implement statistical testing framework
4. Create Figure 2 structure (ready to populate when user has groups)

### **Option C: Both in Parallel** (COMPREHENSIVE)
**Advantage:** Complete solution
**Actions:**
1. Enhance Figure 1 with mechanistic panels (A)
2. Design comparison framework (B)
3. Document how to use both approaches

---

## 🎯 **MY RECOMMENDATION**

**Implement Option A FIRST** (Enhance Figure 1):
1. Port G-content correlation from your previous analysis
2. Add sequence context analysis
3. This gives us **2 complete, publication-ready figures** without needing metadata:
   - **Figure 1:** Dataset characterization & G>T landscape ✅
   - **Figure 3:** Mechanistic validation (G-content, sequence context)

Then **prepare Option B** (comparison framework) as templates for when metadata is available.

---

## ❓ **QUESTION FOR YOU**

**What do you want to prioritize?**

A. **Enhance current Figure 1** with mechanistic validation (G-content, sequence context)?
B. **Design generic comparison framework** for future metadata integration?
C. **Both** - enhance Figure 1 AND prepare comparison templates?

**Also:**
- Do you have miRNA sequences available (for G-content analysis)?
- Should we port your previous G-content analysis to pipeline_2?

---

**🎯 READY TO:** Implement whichever approach you prefer, all analyses are well-defined and actionable!

