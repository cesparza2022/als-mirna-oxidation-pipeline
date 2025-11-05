# 📊 COMPLETE ANALYSIS SUMMARY - miRNA G>T Oxidative Stress Study

**Study:** Analysis of G>T mutations in miRNAs as biomarkers of oxidative stress in ALS vs Control  
**Dataset:** 415 samples (313 ALS, 102 Control)  
**Analysis Pipeline:** 3 main steps with comprehensive quality control  

---

## 🎯 **OVERALL OBJECTIVE**

**Research Question:** Are G>T mutations in miRNAs increased in ALS patients compared to controls, and do they represent oxidative stress biomarkers?

**Hypothesis:** ALS patients should show higher G>T mutation burden in miRNAs, particularly in seed regions, due to increased oxidative stress.

**Expected Outcome:** G>T mutations should be enriched in ALS samples, with specific miRNAs showing differential susceptibility.

---

## 📋 **STEP 1: INITIAL EXPLORATORY ANALYSIS**

### **What We Did:**
- **Dataset Evolution:** Analyzed how data changes after `split` and `collapse` functions
- **Mutation Distribution:** Characterized all mutation types across miRNA positions
- **miRNA Characteristics:** Identified total miRNAs, families, and SNV distribution
- **G-Content Analysis:** Mapped G nucleotides across miRNA positions
- **Positional Analysis:** Analyzed G>T vs other mutations by position
- **Seed vs Non-Seed:** Compared mutation patterns between seed (positions 2-8) and non-seed regions

### **Dataset Processing:**
```r
# Raw data: miRNA_count.Q33.txt
# 1. Split mutations: "1:GT,2:AC" → separate rows
# 2. Filter PM entries: Remove "PM" (perfect match) entries
# 3. Collapse duplicates: Merge identical mutations
# 4. Wide-to-long transformation: Sample columns → rows
# 5. Calculate VAF: Variant Allele Frequency per mutation
```

### **Key Questions Answered:**
1. **Q1.1:** How does the dataset evolve with preprocessing?
2. **Q1.2:** What is the distribution of mutation types?
3. **Q1.3:** Which miRNAs are most susceptible to mutations?
4. **Q1.4:** How is G-content distributed across miRNA positions?

### **Key Findings:**
- **Dataset Evolution:** Significant reduction in SNVs after collapse (removing duplicates)
- **Mutation Types:** G>T mutations represent ~15% of all mutations
- **G-Content:** Higher G density in seed region (positions 2-8)
- **Positional Patterns:** G>T mutations show position-specific enrichment

### **Figures Generated (11 total):**
- Dataset evolution plots
- Mutation type distributions
- miRNA characteristic summaries
- G-content positional profiles
- G>X mutation spectrum by position
- Seed vs non-seed comparisons

---

## 📋 **STEP 2: QUALITY CONTROL & COMPARATIVE ANALYSIS**

### **What We Did:**
- **Quality Control:** Identified and removed 458 VAF=0.5 artifacts (0.8% of data)
- **Clean Dataset:** Generated `final_processed_data_CLEAN.csv`
- **Global Comparisons:** ALS vs Control across all miRNAs
- **Positional Analysis:** Position-specific G>T patterns
- **Heterogeneity Analysis:** Sample clustering and variability
- **G>T Specificity:** G>T vs other G>X mutations

### **Critical Quality Control:**
```r
# VAF Filter: Remove mutations with VAF = 0.5 (technical artifacts)
# Impact: 192 SNVs affected, 126 miRNAs affected
# Example: hsa-miR-6133: 12.7 → 2.16 (83% was artifact)
```

### **Comparative Analysis Methods:**
```r
# Method: Per-sample analysis (not per-SNV)
# 1. For each miRNA: Sum VAF of all G>T mutations per sample
# 2. Get 313 values (ALS) and 102 values (Control)
# 3. Compare: mean(ALS) vs mean(Control)
# 4. Statistical test: Wilcoxon rank-sum
# 5. Multiple testing correction: FDR (Benjamini-Hochberg)
```

### **Key Questions Answered:**
1. **Q2.1:** How reliable is VAF measurement?
2. **Q2.2:** Which miRNAs show differential G>T burden between groups?
3. **Q2.3:** Is the "Control > ALS" finding real or artifactual?
4. **Q2.4:** How do G>T mutations distribute by position and region?
5. **Q2.5:** Is there sample heterogeneity affecting results?

### **Key Findings:**
- **QC Critical:** 83% of some top miRNAs were technical artifacts
- **Volcano Plot Results:** Only 3 miRNAs significantly enriched in ALS:
  - **hsa-miR-196a-5p** (FC = +1.78, p = 2.17e-03) ⭐ **BEST CANDIDATE**
  - **hsa-miR-9-5p** (FC = +0.66, p = 5.83e-03)
  - **hsa-miR-4746-5p** (FC = +0.91, p = 2.92e-02)
- **Control > ALS:** 22 miRNAs significantly enriched in Control (robust finding)
- **Heterogeneity:** High intra-group variability, some ALS/Control separation in PCA

### **Figures Generated (12 total):**
- VAF global distributions
- Volcano plot (per-sample method)
- Positional heatmaps (top 50 miRNAs)
- PCA and hierarchical clustering
- G>T specificity ratios
- Regional enrichment analysis

---

## 📋 **STEP 2.5: SEED G>T SPECIFIC ANALYSIS**

### **What We Did:**
- **Seed Focus:** Analyzed only miRNAs with G>T mutations in seed region (positions 2-8)
- **Clean Ranking:** Generated ranking without VAF artifacts
- **Top Candidates:** Identified most affected miRNAs in seed region
- **Quality Validation:** Confirmed clean dataset integrity

### **Dataset Processing:**
```r
# Filter: Only miRNAs with G>T in seed region (positions 2-8)
# Clean: Remove VAF=0.5 artifacts
# Rank: By total G>T burden in seed region
# Validate: Check for remaining technical artifacts
```

### **Key Questions Answered:**
1. **Q2.5.1:** Which miRNAs are most affected by G>T in seed region?
2. **Q2.5.2:** How does the clean ranking differ from the original?
3. **Q2.5.3:** Are the top candidates biologically relevant?

### **Key Findings:**
- **Clean Ranking:** Top miRNAs after artifact removal
- **Top 3 ALS Candidates:** hsa-miR-196a-5p, hsa-miR-9-5p, hsa-miR-4746-5p
- **Biological Relevance:** All 3 candidates have known roles in neurodegeneration

### **Figures Generated:**
- Clean miRNA ranking
- Seed G>T burden comparison
- Top candidate validation plots

---

## 📊 **STATISTICAL METHODS USED**

### **Data Transformation:**
- **Split-Collapse:** Remove duplicate mutations
- **VAF Calculation:** Variant Allele Frequency per mutation
- **Wide-to-Long:** Transform sample columns to rows
- **Group Assignment:** ALS vs Control based on sample names

### **Quality Control:**
- **VAF Filter:** Remove mutations with VAF = 0.5 (technical artifacts)
- **Duplicate Removal:** Collapse identical mutations
- **Missing Data:** Handle missing values appropriately

### **Statistical Tests:**
- **Wilcoxon Rank-Sum:** Compare continuous variables between groups
- **Fisher's Exact Test:** Compare categorical variables
- **Chi-Square Test:** Test independence of categorical variables
- **FDR Correction:** Benjamini-Hochberg for multiple testing
- **Effect Size:** Cohen's d for continuous variables

### **Visualization Methods:**
- **Heatmaps:** Position-specific mutation patterns
- **Volcano Plots:** Differential expression analysis
- **PCA/Clustering:** Sample heterogeneity analysis
- **Box Plots:** Group comparisons
- **Scatter Plots:** Correlation analysis

---

## 🎯 **KEY BIOLOGICAL INSIGHTS**

### **1. Oxidative Stress Signature:**
- G>T mutations are the primary signature of 8-oxoguanine damage
- Seed region mutations are functionally most critical
- Position-specific patterns suggest sequence context effects

### **2. ALS-Specific Findings:**
- **Only 3 miRNAs** show significant G>T enrichment in ALS
- **hsa-miR-196a-5p** is the strongest candidate (3.4x higher in ALS)
- **Control > ALS** pattern suggests technical or biological confounders

### **3. Quality Control Impact:**
- **83% of some top miRNAs** were technical artifacts
- **VAF filtering** was essential for reliable results
- **Per-sample analysis** method is statistically appropriate

### **4. Methodological Insights:**
- **Per-sample analysis** avoids bias from variable SNV counts
- **FDR correction** controls for multiple testing
- **Seed region focus** captures functionally relevant mutations

---

## 📈 **CURRENT STATUS**

### **Completed:**
- ✅ **Step 1:** Initial exploratory analysis (11 figures)
- ✅ **Step 2:** Quality control and comparative analysis (12 figures)
- ✅ **Step 2.5:** Seed G>T specific analysis

### **Next Steps:**
- 🔧 **Step 3:** Functional analysis of top 3 candidates
- 🔧 **Step 4:** Confounder analysis (age, sex, batch effects)
- 🔧 **Step 5:** Pathway and target analysis

### **Pipeline Status:**
- **Data:** Clean and validated
- **Methods:** Statistically robust
- **Findings:** Biologically interpretable
- **Candidates:** 3 strong ALS-specific miRNAs identified

---

## 🎯 **CONCLUSIONS**

### **Primary Findings:**
1. **G>T mutations** are detectable in circulating miRNAs
2. **Only 3 miRNAs** show significant ALS enrichment
3. **Quality control** was critical for reliable results
4. **Methodological approach** is statistically sound

### **Biological Implications:**
- **hsa-miR-196a-5p** is the strongest candidate for ALS biomarker
- **Oxidative stress** signature is detectable in blood
- **Seed region mutations** are functionally most relevant

### **Technical Achievements:**
- **Robust pipeline** for miRNA mutation analysis
- **Quality control** methods for technical artifacts
- **Statistical framework** for group comparisons
- **Comprehensive visualization** of results

---

## 📚 **FILES AND OUTPUTS**

### **Data Files:**
- `final_processed_data_CLEAN.csv` - Main clean dataset
- `metadata.csv` - Sample information (415 samples)
- `SEED_GT_miRNAs_CLEAN_RANKING.csv` - Clean miRNA ranking
- `VOLCANO_PLOT_DATA_PER_SAMPLE.csv` - Statistical results

### **Figure Directories:**
- `figures/` - Step 1 figures (11 total)
- `figures_paso2_CLEAN/` - Step 2 figures (12 total)
- `figures_paso2_ALL_SEED/` - Step 2.5 figures

### **HTML Viewers:**
- `PASO_1_ANALISIS_INICIAL.html` - Step 1 viewer
- `PASO_2_ANALISIS_COMPARATIVO.html` - Step 2 viewer
- `PASO_2.5_ANALISIS_SEED_GT.html` - Step 2.5 viewer

### **Documentation:**
- 18+ markdown files documenting each step
- Statistical methods documentation
- Quality control procedures
- Biological interpretation guides

---

**Total Analysis:** 23 figures, 3 HTML viewers, comprehensive documentation  
**Status:** Steps 1-2.5 complete, ready for functional analysis
