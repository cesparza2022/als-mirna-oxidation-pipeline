# ALS miRNA Oxidation Research Project

## Overview

This project investigates the role of oxidation in microRNAs (miRNAs) in Amyotrophic Lateral Sclerosis (ALS) through comprehensive analysis of mutation patterns, seed region effects, and target prediction changes.

## Project Structure

```
8OG/
├── R/                    # R scripts and modules
├── fig/                  # Generated figures and plots
├── tables/               # Output tables and results
├── runs/                 # Run logs and metadata
├── .taskmaster/          # Task management files
├── config.yaml           # Project configuration
├── data_schema.json      # Data validation schema
└── README.md            # This file
```

## Research Objectives

1. **Global G>T Signal Analysis**: Quantify aggregate G>T levels in ALS vs Control using GLM/GLMM and stratified permutation
2. **Base Change Composition Analysis**: Compare G>T to other base changes (G>A, G>C) by group using multinomial/Dirichlet-multinomial models
3. **Position-Specific Mutation Testing**: Test for differential mutation rates per position using GLMM and permutation with BH-FDR correction
4. **Seed vs Non-Seed Enrichment Analysis**: Quantify enrichment of mutations in seed vs non-seed regions using binomial/permutation tests
5. **De Novo Seed-Cluster Discovery**: Cluster seed vectors using Ward, HDBSCAN, and Spectral methods with model selection
6. **Target Prediction and Pathway Enrichment**: Predict canonical vs mimic targets and analyze pathway enrichment

## Key Features

- **Reproducible Analysis**: Uses `renv` for dependency management
- **Modular R Code**: Organized into reusable modules with strict APIs
- **Comprehensive Testing**: Statistical validation with multiple testing corrections
- **Adaptive Workflow**: Live, question-driven notebook with de novo seed-cluster discovery
- **Quality Control**: Data validation, schema checking, and coverage analysis

## Dependencies

- R ≥ 4.2.0
- renv ≥ 0.17.3
- data.table ≥ 1.14.8
- lme4 ≥ 1.1-34
- DirichletMultinomial ≥ 1.40.0
- boot ≥ 1.3-28
- clusterProfiler ≥ 4.8.1
- And other packages (see `renv.lock`)

## Getting Started

1. **Restore R Environment**:
   ```r
   renv::restore()
   ```

2. **Run Analysis**:
   ```r
   source("R/main.R")
   ```

3. **View Results**:
   - Check `fig/` for generated plots
   - Check `tables/` for output tables
   - Check `runs/` for run logs

## Data Requirements

- Input matrix with SNV and TOTAL columns
- Sample metadata with group, timepoint, subject_id, and batch information
- miRNA sequences and position annotations

## Output Files

- `tables/sample_metadata.tsv`: Parsed sample metadata
- `tables/qc_report.tsv`: Quality control results
- `tables/global_gt_tests.tsv`: Global G>T analysis results
- `tables/position_delta.tsv`: Position-specific differences
- `tables/seed_vectors.tsv`: Per-miRNA seed vectors
- `tables/cluster_bias_tests.tsv`: Cluster bias analysis
- `tables/mimic_seeds.tsv`: Generated mimic seed sequences
- `tables/enrichment_results.tsv`: Pathway enrichment results

## Figures

- `fig/gt_violin_by_group.png`: G>T levels by group
- `fig/position_delta_curve.png`: Position-specific difference curves
- `fig/seed_vs_nonseed_odds.png`: Seed enrichment analysis
- `fig/cluster_consensus_map.png`: Cluster discovery results
- `fig/enrichment_heatmap.png`: Pathway enrichment visualization

## Methodology

This project implements a comprehensive pipeline for analyzing miRNA oxidation patterns in ALS:

1. **Data Processing**: Quality control, normalization, and metadata parsing
2. **Statistical Analysis**: GLMM modeling, permutation testing, and multiple testing correction
3. **Clustering**: De novo discovery of seed clusters using multiple algorithms
4. **Target Prediction**: Canonical vs mimic target prediction and comparison
5. **Pathway Analysis**: GO/KEGG enrichment analysis with ALS-relevance tagging

## Contact

For questions about this research project, please refer to the project documentation or contact the research team.

## License

This project is for research purposes. Please cite appropriately if using this code or methodology.

