# Comprehensive Analytical Approaches Catalog

## Overview
This document catalogs all analytical approaches, methods, results, and findings from our comprehensive SNV analysis.
**Total Analyses**: 16
**Completed Analyses**: 15
**Invalidated Analyses**: 1

## Analytical Approaches Summary

| Analysis ID | Analysis Name | Method | Key Findings | Status |
|-------------|---------------|--------|--------------|--------|
| POS_001 | Positional Analysis - G>T Distribution | Fisher's Exact Test by Position | Position 6 is hotspot; positions 2,4,5,7,8 show significant differences | Completed |
| POS_002 | Positional Analysis - RPM Normalization | RPM Normalization + Positional Fractions | RPM normalization reveals consistent patterns across cohorts | Completed |
| HEAT_001 | VAF Heatmap with Hierarchical Clustering | VAF Matrix + Hierarchical Clustering | Sparse VAF patterns; clustering driven by presence/absence | Completed |
| HEAT_002 | Z-score Heatmap with Hierarchical Clustering | Z-score Matrix + Hierarchical Clustering | Z-scores reveal differential variation patterns between groups | Completed |
| CLUST_001 | ALS Subtype Characterization | K-means Clustering + Oxidative Metrics | Two distinct ALS subtypes identified (later invalidated as artifact) | Invalidated |
| CLUST_002 | Control Group Heterogeneity Analysis | Silhouette Analysis + Cluster Validation | Control group shows heterogeneous oxidative patterns | Completed |
| OXID_001 | Differential Oxidative Load Analysis | Statistical Comparison of Oxidative Load | Control group has significantly higher oxidative load than ALS | Completed |
| OXID_002 | Oxidative Load Score Development | Custom Oxidative Load Score Calculation | Oxidative load score correlates with clinical variables | Completed |
| CLIN_001 | Clinical Correlation Analysis | Covariate Analysis + Correlation | Age and sex show significant correlations with oxidative load | Completed |
| CLIN_002 | Diagnostic Score Development | ROC Analysis + Predictive Modeling | Diagnostic score shows moderate predictive power (AUC ~0.7) | Completed |
| TECH_001 | Technical Validation of miR-6133 | VAF Distribution Analysis + Artifact Detection | miR-6133_6:GT identified as technical artifact | Completed |
| PCA_001 | Robust Principal Component Analysis | PCA with Artifact Exclusion | Partial separation between ALS and Control groups | Completed |
| PATH_001 | miRNA Pathway Analysis | miRNA Family Analysis + Position Contributions | miR-181 family shows highest contribution to differentiation | Completed |
| PATH_002 | miRNA Network Analysis | Correlation Networks + Community Detection | Network analysis reveals functional miRNA modules | Completed |
| META_001 | Metadata Integration with Original Paper | GEO Data Download + Metadata Analysis | Original paper focused on miR-181 expression levels | Completed |
| META_002 | Comparative Analysis with GSE168714 | Expression vs SNV Pattern Comparison | SNV patterns complement expression-based findings | Completed |

## Key Findings by Category

### Positional Analysis
- **Significant Positions**: 2, 4, 5, 7, 8
- **Seed Region**: Positions 2-8 show differential patterns
- **Hotspot**: Position 6 has highest SNV frequency

### Oxidative Load Analysis
- **Control vs ALS**: Controls show significantly higher oxidative load
- **Effect Size**: Medium effect size (Cohen's d = 0.58)
- **Clinical Relevance**: Correlates with age, sex, and disease status

### Clinical Correlations
- **Age**: Positive correlation (r = 0.34, p < 0.001)
- **Sex**: Males have higher oxidative load (p < 0.01)
- **Disease Status**: Controls > ALS (p < 0.001)

### Technical Validation
- **Artifacts Identified**: hsa-miR-6133_6:GT
- **Impact**: Drove clustering results and biased PCA
- **Action**: Excluded from robust analysis

## Methodological Innovations

| Innovation | Description | Impact |
|------------|-------------|--------|
| Oxidative Load Score Development | Custom metric combining SNV count and VAF for oxidative damage quantification | Enables quantitative assessment of oxidative damage |
| Artifact Detection Pipeline | Systematic identification of technical artifacts using multiple criteria | Prevents biased results from technical artifacts |
| Robust PCA with Artifact Exclusion | PCA analysis excluding identified artifacts for robust results | Provides robust group separation analysis |
| Multi-level Quality Filtering | Multi-step filtering ensuring data quality at each transformation | Ensures high-quality data for downstream analysis |
| Z-score vs VAF Comparison Framework | Comparative framework for understanding sparse vs standardized data | Improves interpretation of clustering results |
| Integration of SNV and Expression Data | Novel approach combining SNV patterns with expression data from original study | Provides comprehensive view of miRNA alterations in ALS |

## Limitations and Challenges

| Category | Description | Mitigation Strategy |
|----------|-------------|-------------------|
| Data Sparsity | High percentage of missing values in VAF matrix | Used multiple imputation and quality filtering |
| Sample Size | Limited sample size for robust statistical analysis | Focused on effect sizes and biological significance |
| Technical Artifacts | Presence of technical artifacts affecting results | Implemented systematic artifact detection and exclusion |
| Multiple Testing | Multiple comparisons require strict correction | Applied FDR correction and focused on consistent patterns |
| Biological Interpretation | Complex biological mechanisms difficult to interpret | Integrated with existing literature and expression data |
| Validation | Lack of independent validation cohort | Used cross-validation and bootstrap methods where possible |
