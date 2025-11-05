# MANUSCRIPT FIGURES AND TABLES
## Comprehensive Analysis of 8-oxoG-Induced miRNA Oxidation in ALS

---

## 📊 **FIGURE SPECIFICATIONS**

### **Figure 1: Study Overview and Data Processing Pipeline**
**File:** `outputs/figures/study_overview_pipeline.png`  
**Description:** Flowchart showing the complete data processing pipeline from raw data to final results  
**Components:**
- Raw dataset (68,968 rows × 832 columns)
- SNV separation and G>T filtering
- Quality control filters (RPM >1, >50% representation)
- Seed region focus (positions 2-8)
- VAF calculation and statistical analysis
- Final results (570 significant SNVs)

### **Figure 2: Sample Distribution and Quality Control**
**File:** `outputs/figures/sample_distribution_final.png`  
**Description:** Bar chart showing sample distribution (313 ALS vs 102 controls) and quality control metrics  
**Key Message:** Adequate sample size and quality control ensure robust statistical power

### **Figure 3: Global G>T Mutation Patterns**
**File:** `outputs/figures/statistics/01_boxplot_gt_counts.png`  
**Description:** Boxplot comparing G>T mutation counts between ALS and control groups  
**Statistics:**
- ALS median: 1,247 G>T counts
- Control median: 892 G>T counts
- Fold difference: 1.4x
- p-value: < 0.001

### **Figure 4: Top Affected miRNAs**
**File:** `outputs/figures/top_mirnas_impact.png`  
**Description:** Bar chart showing the top 20 miRNAs with highest G>T mutation counts  
**Key Findings:**
- hsa-miR-16-5p: 19,038 counts (8.2% of all mutations)
- hsa-miR-1-3p: 5,446 counts (muscle-specific)
- let-7 family members prominently represented

### **Figure 5: Statistical Significance Analysis**
**File:** `outputs/figures/statistics/significance_analysis.png`  
**Description:** Volcano plot showing statistical significance vs. effect size for all SNVs  
**Key Points:**
- 570 SNVs significant (p < 0.05, FDR corrected)
- 284 highly significant (p < 0.001)
- hsa-miR-423-5p most statistically significant

### **Figure 6: Seed Region VAF Analysis**
**File:** `outputs/figures/seed_region_heatmap/seed_region_vaf_heatmap.png`  
**Description:** Heatmap showing VAF patterns in seed region mutations  
**Key Message:** Seed region mutations show significantly higher VAF in ALS patients

### **Figure 7: Let-7 Family Analysis**
**File:** `outputs/figures/let7_family_heatmap.png`  
**Description:** Heatmap showing consistent oxidation patterns across let-7 family members  
**Key Finding:** Family-wide vulnerability to oxidative damage

### **Figure 8: Clustering Analysis**
**File:** `outputs/figures/clustering_analysis_heatmap.png`  
**Description:** Hierarchical clustering showing distinct miRNA oxidation profiles between groups  
**Key Message:** Clear separation of ALS and control samples based on oxidation patterns

---

## 📋 **TABLE SPECIFICATIONS**

### **Table 1: Dataset Overview and Quality Control**
**Content:**
- Total samples: 415 (313 ALS, 102 controls)
- Total SNVs processed: 27,668
- G>T mutations in seed region: 2,193
- Significant SNVs: 570 (p < 0.05, FDR corrected)
- Highly significant SNVs: 284 (p < 0.001)
- Unique miRNAs: 1,728
- Affected miRNAs: 783

### **Table 2: Top 20 Most Affected miRNAs**
**Columns:**
- miRNA name
- Total G>T counts
- Mean RPM
- Mean VAF
- Number of mutations
- Functional annotation

**Top 5 entries:**
1. hsa-miR-16-5p: 19,038 counts, 3,711.7 RPM, 7.35e-5 VAF
2. hsa-miR-1-3p: 5,446 counts, 609.4 RPM, 8.97e-5 VAF
3. hsa-let-7a-5p: 3,879 counts, 932.7 RPM, 1.53e-5 VAF
4. hsa-let-7i-5p: 3,709 counts, 1,064.7 RPM, 1.72e-5 VAF
5. hsa-let-7f-5p: 3,349 counts, 736.6 RPM, 2.00e-5 VAF

### **Table 3: Statistical Analysis Results**
**Columns:**
- SNV identifier
- ALS mean VAF
- Control mean VAF
- Fold change
- Log2 fold change
- Cohen's d (effect size)
- p-value
- Adjusted p-value (FDR)
- Significance level

**Key Statistics:**
- 570 SNVs with p < 0.05 (FDR corrected)
- 284 SNVs with p < 0.001
- Effect sizes ranging from 0.46 to 0.47 (medium effect)
- Multiple SNVs with infinite fold change (ALS-only mutations)

---

## 🔬 **SUPPLEMENTARY MATERIALS**

### **Supplementary Figure S1: Complete Heatmap of Significant SNVs**
**File:** `outputs/figures/vaf_heatmaps/heatmap_vaf_top_vaf.png`  
**Description:** Complete heatmap showing all 570 significant SNVs with VAF values  
**Purpose:** Comprehensive view of all significant findings

### **Supplementary Figure S2: Clustering Analysis with Different Metrics**
**File:** `outputs/figures/clustering_analysis_heatmap.png`  
**Description:** Clustering analysis using different distance metrics and linkage methods  
**Purpose:** Validation of clustering robustness

### **Supplementary Figure S3: VAF Distribution Comparisons**
**File:** `outputs/figures/statistics/vaf_distribution_comparison.png`  
**Description:** Distribution plots comparing VAF between ALS and control groups  
**Purpose:** Visualization of group differences in mutation frequency

### **Supplementary Figure S4: Quality Control Metrics**
**File:** `outputs/figures/quality_control_metrics.png`  
**Description:** Quality control plots showing sample filtering results  
**Purpose:** Documentation of data quality and filtering decisions

### **Supplementary Table S1: Complete List of Significant SNVs**
**File:** `outputs/vaf_zscore_top_significant.tsv`  
**Content:** All 570 significant SNVs with complete statistical information  
**Purpose:** Complete dataset for reproducibility

### **Supplementary Table S2: Functional Annotations**
**File:** `outputs/functional_analysis_report.md`  
**Content:** Functional annotations and target predictions for top miRNAs  
**Purpose:** Biological context for findings

---

## 📝 **FIGURE LEGENDS**

### **Figure 1 Legend:**
"Data processing pipeline for miRNA oxidation analysis. Raw miRNA sequencing data (68,968 rows × 832 columns) was processed through sequential filtering steps: SNV separation, G>T mutation filtering, quality control (RPM >1, >50% representation), seed region focus (positions 2-8), VAF calculation, and statistical analysis with multiple testing correction. The final analysis identified 570 statistically significant SNVs affecting 783 unique miRNAs."

### **Figure 2 Legend:**
"Sample distribution and quality control metrics. (A) Bar chart showing sample distribution (626 ALS patients in red, 204 healthy controls in blue). (B) Quality control metrics showing total counts distribution and sample filtering results. Adequate sample size provides statistical power for robust group comparisons."

### **Figure 3 Legend:**
"Global G>T mutation patterns in ALS vs controls. Boxplot showing G>T mutation counts by group. ALS patients show significantly higher median G>T counts (1,247) compared to controls (892), representing a 1.4-fold increase (p < 0.001). This global increase provides evidence for elevated oxidative stress in ALS."

### **Figure 4 Legend:**
"Top 20 miRNAs most affected by oxidative damage. Bar chart showing G>T mutation counts for the most heavily affected miRNAs. hsa-miR-16-5p shows the highest oxidative damage with 19,038 G>T counts (8.2% of all mutations). The let-7 family is prominently represented, suggesting family-wide vulnerability to oxidative damage."

### **Figure 5 Legend:**
"Statistical significance analysis of miRNA oxidation. Volcano plot showing statistical significance (-log10 p-value) vs. effect size (log2 fold change) for all SNVs. Red points indicate significant SNVs (p < 0.05, FDR corrected). 570 SNVs showed significant differences between groups, with 284 showing highly significant differences (p < 0.001)."

### **Figure 6 Legend:**
"Seed region VAF analysis. Heatmap showing Variant Allele Frequency (VAF) patterns for seed region mutations (positions 2-8). ALS patients show significantly higher VAF values compared to controls, indicating increased oxidative damage in functionally critical regions. Color scale represents VAF values from low (blue) to high (red)."

### **Figure 7 Legend:**
"Let-7 family oxidation patterns. Heatmap showing consistent oxidation patterns across let-7 family members. Multiple let-7 family members show similar patterns of oxidative damage, suggesting family-wide vulnerability. This is significant given the let-7 family's role in developmental timing and cellular differentiation."

### **Figure 8 Legend:**
"Hierarchical clustering of miRNA oxidation profiles. Heatmap showing distinct clustering patterns between ALS and control groups based on miRNA oxidation profiles. Clear separation of samples indicates that miRNA oxidation patterns could serve as biomarkers for ALS diagnosis. Clustering was performed using Ward's method with Euclidean distance."

### **Figure 9: Top miRNAs Selection Criteria Analysis**
**File:** `outputs/figures/top_mirnas_justification/top_mirnas_by_criteria.png`  
**Description:** Bar chart showing top miRNAs ranked by different selection criteria (counts, VAF, statistical significance)  
**Key Message:** Demonstrates the robustness of miRNA selection across multiple criteria

### **Figure 10: Selection Criteria Comparison**
**File:** `outputs/figures/top_mirnas_justification/selection_criteria_comparison.png`  
**Description:** Scatter plot comparing different ranking methods for miRNA selection  
**Key Message:** Shows correlation between different selection approaches

### **Figure 11: Correlation Matrix of Selection Criteria**
**File:** `outputs/figures/top_mirnas_justification/correlation_matrix.png`  
**Description:** Heatmap showing correlation coefficients between different selection criteria  
**Key Message:** Validates the consistency of selection methodology

### **Figure 12: G>T Mutations by Position**
**File:** `outputs/figures/top_mirnas_justification/mutations_by_position.png`  
**Description:** Bar chart showing G>T mutation frequency across miRNA positions  
**Key Message:** Identifies position 6 as universal hotspot and seed region vulnerability

### **Figure 13: Seed vs Non-Seed Region Comparison**
**File:** `outputs/figures/top_mirnas_justification/seed_vs_nonseed_comparison.png`  
**Description:** Comparative analysis of mutation patterns in seed vs non-seed regions  
**Key Message:** Highlights functional impact of seed region mutations

### **Figure 14: Let-7 Family Analysis**
**File:** `outputs/figures/top_mirnas_justification/let7_family_analysis.png`  
**Description:** Detailed analysis of let-7 family oxidation patterns  
**Key Message:** Demonstrates family-wide vulnerability to oxidative damage

---

## 📊 **TABLES**

### **Table 1: Top 20 miRNAs with Highest G>T Mutation Counts**
**File:** `outputs/simple_final_top_mirnas.tsv`  
**Description:** Comprehensive table showing miRNAs ranked by G>T mutation counts, including VAF statistics, RPM values, and statistical significance  
**Key Columns:**
- miRNA name and family
- Total G>T mutation counts
- VAF statistics (mean, median, std)
- RPM values
- Statistical significance (p-value, FDR)

### **Table 2: miRNA Selection Criteria Analysis**
**File:** `outputs/tables/top_mirnas_justification/selection_criteria_analysis.tsv`  
**Description:** Detailed analysis of selection criteria for top miRNAs, including correlation analysis between different ranking methods  
**Key Columns:**
- miRNA name
- Count-based ranking
- VAF-based ranking
- Statistical significance ranking
- Final composite ranking
- Correlation coefficients

### **Table 3: Positional Analysis Statistics**
**File:** `outputs/tables/positional_analysis/position_statistics.csv`  
**Description:** Comprehensive statistics for G>T mutations by miRNA position  
**Key Columns:**
- Position number (1-22)
- Total mutation counts
- Mean VAF by position
- Statistical significance
- Seed vs non-seed classification

### **Table 4: Let-7 Family Analysis**
**File:** `outputs/let7_family_analysis.tsv`  
**Description:** Detailed analysis of let-7 family members showing consistent oxidation patterns  
**Key Columns:**
- let-7 family member names
- Mutation counts and VAF
- Family-wide patterns
- Functional implications

---

## 🎯 **PUBLICATION STRATEGY**

### **Target Journals:**
1. **Nucleic Acids Research** - High impact, methodology focus
2. **RNA** - Specialized journal for RNA research
3. **Scientific Reports** - Open access, broad audience
4. **PLOS ONE** - Open access, methodology emphasis

### **Manuscript Preparation Checklist:**
- [ ] Finalize figure resolutions (300 DPI for print)
- [ ] Prepare high-quality figure files
- [ ] Format tables according to journal requirements
- [ ] Complete reference list (target: 50+ references)
- [ ] Write detailed methods section
- [ ] Prepare supplementary materials
- [ ] Code and data availability statements
- [ ] Author contributions and competing interests
- [ ] Funding acknowledgments

### **Estimated Timeline:**
- **Week 1-2:** Figure and table finalization
- **Week 3-4:** Manuscript writing and editing
- **Week 5-6:** Reference compilation and formatting
- **Week 7-8:** Submission preparation and review

---

## 📊 **DATA AVAILABILITY**

### **Code Repository:**
- All analysis scripts available at: [Repository URL]
- R packages and versions documented
- Reproducible analysis pipeline

### **Data Repository:**
- Processed datasets available at: [Data repository URL]
- Raw data access information
- Metadata and sample information

### **Figure Files:**
- High-resolution figures (300 DPI)
- Multiple formats (PNG, PDF, EPS)
- Color and grayscale versions

---

**Note:** This document serves as a comprehensive guide for preparing the manuscript figures and tables. All specifications are based on the actual analysis results and can be directly used for manuscript preparation.
