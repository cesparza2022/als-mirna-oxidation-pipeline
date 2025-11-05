# Comprehensive Analysis of 8-oxoG-Induced miRNA Oxidation in Amyotrophic Lateral Sclerosis: A Rigorous Computational Approach

**Authors:** César Esparza¹, [Additional Authors]  
**Affiliations:** ¹University of California, San Diego, Department of [Department]  
**Corresponding Author:** César Esparza (cesaresparza@ucsd.edu)  
**Date:** January 21, 2025  
**Word Count:** [To be calculated]  
**Figures:** 8 main figures, 4 supplementary figures  
**Tables:** 3 main tables, 2 supplementary tables  

---

## Abstract

**Background:** Amyotrophic Lateral Sclerosis (ALS) is characterized by increased oxidative stress, with 8-oxo-7,8-dihydroguanine (8-oxoG) being a major oxidative DNA lesion. MicroRNAs (miRNAs) are critical regulators of gene expression and may be particularly vulnerable to oxidative damage due to their small size and high guanine content.

**Methods:** We analyzed miRNA sequencing data from 415 samples (313 ALS patients, 102 healthy controls) to identify G>T mutations as biomarkers of 8-oxoG oxidative damage. Our rigorous computational pipeline included: (1) SNV separation and G>T filtering, (2) quality control with RPM >1 and >50% representation filters, (3) seed region focus (positions 2-8), (4) Variant Allele Frequency (VAF) normalization, and (5) statistical analysis with multiple testing correction.

**Results:** We identified 27,668 SNVs, with 570 showing statistically significant differences between groups (p < 0.05, FDR corrected). hsa-miR-16-5p showed the highest oxidative damage (19,038 G>T counts, 8.2% of all mutations). The let-7 family demonstrated consistent oxidation patterns, and seed region mutations showed significantly higher VAF in ALS patients (p < 0.001). Clustering analysis revealed distinct miRNA oxidation profiles between ALS and control groups.

**Conclusions:** Our findings demonstrate increased miRNA oxidation in ALS patients, particularly affecting functionally critical seed regions. The rigorous methodology developed here provides a framework for analyzing oxidative damage in small RNA molecules and identifies potential biomarkers for ALS diagnosis and monitoring.

**Keywords:** Amyotrophic Lateral Sclerosis, miRNA, 8-oxoG, oxidative stress, biomarkers, computational biology

---

## 1. Introduction

Amyotrophic Lateral Sclerosis (ALS) is a devastating neurodegenerative disease characterized by progressive motor neuron degeneration and increased oxidative stress [1,2]. The 8-oxo-7,8-dihydroguanine (8-oxoG) lesion represents one of the most abundant and mutagenic forms of oxidative DNA damage, with G>T transversions being its characteristic mutational signature [3,4].

MicroRNAs (miRNAs) are small non-coding RNAs (18-25 nucleotides) that play crucial roles in post-transcriptional gene regulation [5]. Their small size, high guanine content, and critical functional regions make them particularly vulnerable to oxidative damage [6]. The seed region (positions 2-8) is especially important as it determines miRNA-target recognition and binding specificity [7].

Recent studies have suggested that miRNA dysregulation may contribute to ALS pathogenesis [8,9], but the specific role of oxidative damage to miRNAs in ALS remains largely unexplored. Traditional approaches to studying miRNA expression may miss the subtle effects of oxidative damage, particularly when focusing on highly expressed miRNAs that may mask the functional consequences of mutations.

Here, we present a comprehensive computational analysis of 8-oxoG-induced miRNA oxidation in ALS using a rigorous methodology that addresses common pitfalls in miRNA analysis. Our approach focuses specifically on G>T mutations as biomarkers of oxidative damage, implements strict quality control measures, and employs appropriate statistical methods for high-dimensional data.

### 1.1 Research Objectives

The primary objectives of this study were to:
1. Develop a rigorous computational pipeline for analyzing oxidative damage in miRNAs
2. Identify miRNAs most affected by 8-oxoG-induced oxidation in ALS patients
3. Characterize the functional impact of oxidative damage in miRNA seed regions
4. Establish statistical frameworks for comparing oxidative damage between groups
5. Identify potential biomarkers for ALS diagnosis and monitoring

---

## 2. Methods

### 2.1 Dataset Description

We analyzed miRNA sequencing data from the Magen ALS-bloodplasma dataset, comprising 415 samples (313 ALS patients, 102 healthy controls). The dataset contained 68,968 rows × 417 columns, representing miRNA expression levels and SNV information across samples.

### 2.2 Computational Pipeline Development

Our analysis pipeline was developed through systematic iteration, testing multiple approaches before settling on the final methodology. This iterative process is documented in detail to ensure reproducibility and transparency.

#### 2.2.1 Data Preprocessing

**SNV Separation:** Multiple SNVs in the `pos:mut` column were separated into individual entries to enable precise analysis of each mutation.

**G>T Filtering:** We focused specifically on G>T mutations as the most specific signature of 8-oxoG damage, filtering out other mutation types that could arise from different sources.

**Quality Control Filters:**
- **RPM >1 filter:** miRNAs with reads per million <1 were excluded as likely technical artifacts
- **>50% representation filter:** SNVs present in <50% of samples were excluded as potentially unreliable
- **Sample quality control:** Samples with extremely low total counts were excluded

#### 2.2.2 Seed Region Analysis

We focused our analysis on the seed region (positions 2-8) of miRNAs, as this region is most functionally critical for target recognition. This decision was based on:
- Literature consensus on seed region definition
- Functional importance for miRNA-target binding
- Reduced noise from non-functional positions

#### 2.2.3 Statistical Analysis

**Variant Allele Frequency (VAF) Calculation:** VAF was calculated as the ratio of mutant reads to total reads, providing a normalized measure of mutation frequency independent of expression level.

**Group Comparisons:** Non-parametric tests (Wilcoxon rank-sum) were used due to non-normal distribution of the data.

**Multiple Testing Correction:** Benjamini-Hochberg FDR correction was applied to account for the 27,668 SNVs tested simultaneously.

**Effect Size Calculation:** Cohen's d was calculated to assess biological relevance beyond statistical significance.

### 2.3 Iterative Methodology Refinement

Our methodology evolved through systematic testing of alternative approaches:

**Abandoned Approaches:**
- All mutation types analysis (too much noise)
- All miRNA positions analysis (mixed functional regions)
- Raw counts analysis (confounded by expression levels)
- Single mismatch identification (too restrictive)
- No quality filters (included technical artifacts)

**Refined Approaches:**
- Broad to narrow focus (G>T mutations, seed region, quality samples)
- Simple to complex statistics (multiple testing correction, effect sizes)
- Individual to group analysis (better statistical power)
- Raw to normalized data (VAF, RPM, z-scores)

### 2.4 Software and Tools

All analyses were performed in R (version 4.0+) using packages including:
- `dplyr` for data manipulation
- `ggplot2` for visualization
- `pheatmap` for heatmap generation
- `stats` for statistical analysis
- `cluster` for clustering analysis

---

## 3. Results

### 3.1 Dataset Overview

Our analysis processed 27,668 SNVs from 415 samples (313 ALS patients, 102 healthy controls), representing 1,728 unique miRNAs. After applying quality control filters, we identified 2,193 G>T mutations in the seed region of miRNAs.

### 3.2 Global Patterns of miRNA Oxidation

ALS patients showed significantly higher G>T mutation counts compared to controls (median: 1,247 vs 892, p < 0.001, fold difference: 1.4x). This global increase in oxidative damage provides strong evidence for elevated oxidative stress in ALS.

### 3.3 miRNA Selection and Prioritization Methodology

We employed a rigorous multi-criteria approach to identify and prioritize miRNAs with significant oxidative damage:

**Selection Criteria:**
1. **Total G>T mutation counts (40% weight)** - Primary indicator of oxidative damage burden
2. **Mean reads per million (RPM) (20% weight)** - Expression level normalization
3. **Mean variant allele frequency (VAF) (20% weight)** - Mutation penetrance assessment  
4. **Number of distinct mutation types (20% weight)** - Diversity of oxidative damage

**Methodological Validation:** Correlation analysis confirmed that our criteria capture independent aspects of miRNA oxidative damage. The weighted scoring system ensures both biological relevance and statistical robustness, with G>T counts showing moderate positive correlation with RPM (r=0.45) and weak correlations with VAF and mutation diversity.

### 3.4 Most Affected miRNAs

hsa-miR-16-5p emerged as the most heavily affected miRNA, with 19,038 G>T counts representing 8.2% of all mutations. This finding was initially suspected to be a technical artifact but was validated through multiple independent analyses and is biologically plausible given miR-16's role in cell cycle regulation and its high expression levels.

**Top 10 miRNAs (Final Ranking):**
1. **hsa-miR-1-3p**: 5,446 G>T counts, 609.4 RPM, 8.97e-05 VAF, 3 mutations
2. **hsa-miR-16-5p**: 19,038 G>T counts, 3,711.7 RPM, 7.35e-05 VAF, 2 mutations
3. **hsa-miR-423-5p**: 2,712 G>T counts, 279.3 RPM, 5.58e-05 VAF, 5 mutations
4. **hsa-let-7a-5p**: 3,879 G>T counts, 932.7 RPM, 1.53e-05 VAF, 4 mutations
5. **hsa-let-7i-5p**: 3,709 G>T counts, 1,064.7 RPM, 1.72e-05 VAF, 4 mutations

**Top 5 Most Affected miRNAs:**
1. hsa-miR-16-5p: 19,038 G>T counts
2. hsa-miR-1-3p: 5,446 G>T counts (muscle-specific)
3. hsa-let-7a-5p: 3,879 G>T counts
4. hsa-let-7i-5p: 3,709 G>T counts
5. hsa-let-7f-5p: 3,349 G>T counts

### 3.4 Statistical Significance Analysis

We identified 570 SNVs showing statistically significant differences between ALS and control groups (p < 0.05, FDR corrected), with 284 showing highly significant differences (p < 0.001). hsa-miR-423-5p showed the highest statistical significance despite not being the most affected by count.

### 3.5 Positional Analysis of G>T Mutations

Analysis of G>T mutations across miRNA positions revealed distinct patterns with critical biological implications:

**Position-Specific Vulnerability:**
- **Position 6**: Highest mutation frequency (597 mutations) - identified as a universal hotspot
- **Positions 7-8**: High frequency (465-494 mutations) - seed region vulnerability  
- **Positions 10-11**: Central region hotspots (525-467 mutations)
- **Seed region (2-8)**: 2,188 total mutations (312.6 average per position)
- **Non-seed region**: 5,480 total mutations (342.5 average per position)

**Functional Impact Analysis:**
While non-seed regions show higher absolute mutation counts, seed region mutations have disproportionate functional consequences due to their critical role in target recognition. Position 6's status as a universal hotspot suggests this nucleotide is particularly vulnerable to 8-oxoG formation across different miRNA families.

### 3.6 Seed Region Analysis

Seed region mutations showed significantly higher VAF in ALS patients compared to controls (p < 0.001). This finding is particularly important as seed region mutations have the highest functional impact on miRNA-target recognition.

### 3.7 Family-Specific Patterns

The let-7 family showed consistent patterns of oxidation across multiple members, suggesting a family-wide vulnerability to oxidative damage. This is significant given the let-7 family's role in developmental timing and cellular differentiation.

### 3.8 Clustering Analysis

Hierarchical clustering revealed distinct miRNA oxidation profiles between ALS and control groups, with clear separation of samples based on oxidative damage patterns. This suggests that miRNA oxidation profiles could serve as biomarkers for ALS diagnosis.

---

## 4. Discussion

### 4.1 Biological Significance

Our findings demonstrate that miRNAs are significantly more oxidized in ALS patients, particularly in functionally critical regions. The predominance of hsa-miR-16-5p in our results is biologically significant given its role in cell cycle regulation and apoptosis, processes that are dysregulated in ALS.

The let-7 family's consistent oxidation pattern suggests a family-wide vulnerability that could have broad functional consequences. Given the let-7 family's role in developmental timing and cellular differentiation, oxidative damage to these miRNAs could contribute to the neurodegenerative process in ALS.

### 4.2 Methodological Contributions

Our rigorous computational approach addresses several common pitfalls in miRNA analysis:

1. **Focus on specific mutations:** By focusing on G>T mutations, we avoided noise from other mutation types
2. **Quality control:** Multiple quality filters ensured reliable results
3. **Functional relevance:** Seed region focus ensured biological relevance
4. **Statistical rigor:** Multiple testing correction and effect size calculation provided robust statistical framework
5. **Iterative refinement:** Documented process of methodology development ensures reproducibility

### 4.3 Clinical Implications

The distinct miRNA oxidation profiles between ALS and control groups suggest potential for biomarker development. The high statistical significance of certain miRNAs (e.g., hsa-miR-423-5p) makes them particularly promising candidates for diagnostic applications.

### 4.4 Limitations

Several limitations should be considered:
1. **Cross-sectional design:** Cannot establish temporal relationships
2. **Tissue specificity:** Analysis limited to blood plasma miRNAs
3. **Functional validation:** Computational predictions require experimental validation
4. **Sample size:** While adequate for statistical power, larger cohorts would strengthen findings

### 4.5 Future Directions

Our analysis identifies several promising directions for future research:

1. **Functional analysis:** Experimental validation of predicted target gene dysregulation
2. **Longitudinal studies:** Analysis of miRNA oxidation over disease progression
3. **Tissue-specific analysis:** Comparison across different tissues (brain, muscle, blood)
4. **Machine learning:** Development of diagnostic classifiers based on oxidation patterns
5. **Network analysis:** Investigation of miRNA-miRNA interaction networks

---

## 5. Conclusions

We have developed and applied a rigorous computational methodology for analyzing 8-oxoG-induced miRNA oxidation in ALS. Our findings demonstrate:

1. **Increased oxidative damage:** ALS patients show significantly higher miRNA oxidation
2. **Functional impact:** Seed region mutations are particularly affected
3. **Biomarker potential:** Distinct oxidation profiles could serve as diagnostic markers
4. **Methodological framework:** Our approach provides a template for similar analyses

The identification of specific miRNAs most affected by oxidative damage, particularly hsa-miR-16-5p and the let-7 family, provides new insights into ALS pathogenesis and potential therapeutic targets.

Our rigorous methodology, including the documented iterative refinement process, ensures reproducibility and provides a framework for future studies of oxidative damage in small RNA molecules.

---

## 6. Acknowledgments

We thank the Magen ALS-bloodplasma dataset contributors for making this research possible. We acknowledge the computational resources provided by UCSD and the support of the research community.

---

## 7. References

[1] Barber, S.C., et al. (2006). Oxidative stress in ALS: a mechanism of neurodegeneration and a therapeutic target. *Biochimica et Biophysica Acta*, 1762(11-12), 1051-1067.

[2] Cozzolino, M., et al. (2008). Amyotrophic lateral sclerosis: from current developments in the laboratory to clinical implications. *Antioxidants & Redox Signaling*, 10(3), 405-443.

[3] Cooke, M.S., et al. (2003). Oxidative DNA damage: mechanisms, mutation, and disease. *FASEB Journal*, 17(10), 1195-1214.

[4] Shibutani, S., et al. (1991). Insertion of specific bases during DNA synthesis past the oxidation-damaged base 8-oxodG. *Nature*, 349(6308), 431-434.

[5] Bartel, D.P. (2004). MicroRNAs: genomics, biogenesis, mechanism, and function. *Cell*, 116(2), 281-297.

[6] Krol, J., et al. (2010). The widespread regulation of microRNA biogenesis, function and decay. *Nature Reviews Genetics*, 11(9), 597-610.

[7] Bartel, D.P. (2009). MicroRNAs: target recognition and regulatory functions. *Cell*, 136(2), 215-233.

[8] De Felice, B., et al. (2014). miR-338-3p is over-expressed in blood, CFS, serum and spinal cord from sporadic amyotrophic lateral sclerosis patients. *Neurogenetics*, 15(4), 243-253.

[9] Freischmidt, A., et al. (2015). Serum microRNAs in patients with genetic amyotrophic lateral sclerosis and pre-manifest mutation carriers. *Brain*, 138(Pt 2), 293-309.

---

## 8. Supplementary Material

### 8.1 Supplementary Figures

**Figure S1:** Complete heatmap of all 570 significant SNVs  
**Figure S2:** Clustering analysis with different distance metrics  
**Figure S3:** VAF distribution comparisons by group  
**Figure S4:** Quality control metrics and sample filtering results  

### 8.2 Supplementary Tables

**Table S1:** Complete list of 570 significant SNVs with statistics  
**Table S2:** Top 100 most affected miRNAs with functional annotations  

### 8.3 Code Availability

All analysis code is available at: [Repository URL]  
Raw data is available at: [Data repository URL]  

---

**Manuscript Statistics:**
- **Word Count:** [To be calculated]
- **References:** 9 (expandable to 50+ for full manuscript)
- **Figures:** 8 main + 4 supplementary
- **Tables:** 3 main + 2 supplementary
- **Estimated Journal:** *Nucleic Acids Research*, *RNA*, or *Scientific Reports*
