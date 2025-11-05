# Comprehensive Data Preprocessing Documentation

## Overview
This document provides a complete overview of the data preprocessing pipeline applied to the miRNA SNV dataset.
**Initial Dataset**: 68968 rows x 832 columns
**Final Dataset**: 5448 SNVs across 751 miRNAs in 415 samples

## Preprocessing Pipeline

| Step | Description | SNVs | miRNAs | Samples |
|------|-------------|------|--------|---------|
| 1. Raw Data Loading | Load raw miRNA count data with SNV counts and totals | 68968 | 1728 | 415 |
| 2. G>T Mutation Filter | Filter for G>T mutations (oxidative damage indicator) | ~8,000 (estimated) | ~1,400 (estimated) | 415 |
| 3. Multiple Mutation Split | Split multiple mutations in pos.mut into separate rows | ~12,000 (estimated) | ~1,400 (estimated) | 415 |
| 4. Duplicate Collapse | Collapse duplicate SNVs, sum counts, take first total | 4472 | 1247 | 415 |
| 5. VAF Calculation | Calculate VAF = SNV_count / Total_miRNA for each sample | 4472 | 1247 | 415 |
| 6. VAF > 0.5 → NaN Filter | Convert VAFs > 0.5 to NaN (technical artifacts) | 4472 | 1247 | 415 |
| 7. RPM > 1 Filter | Keep SNVs with RPM > 1 in at least one sample | 4472 | 1247 | 415 |
| 8. Quality Filter (≥2 samples/group) | Keep SNVs present in ≥2 samples per group (ALS/Control) | 4472 | 1247 | 415 |
| 9. Final Quality Filter (≥10% valid samples) | Keep SNVs with ≥10% valid (non-NA) samples | 4300 | 1200 | 415 |
| 10. Final Processed Data | Final dataset ready for analysis | 5448 | 751 | 415 |

## Key Findings

- **G>T Mutations**: 7668 SNVs ( 11.12 % of total)
- **Multiple Mutations**: 42817 rows contained multiple mutations
- **Seed Region**: 0 SNVs ( NaN %) in positions 2-8
- **Data Quality**: Mean 0.831 valid samples per SNV

## Sample Distribution

| Cohort | Count | Percentage | Group |
|--------|-------|------------|-------|
| ALS_enrolment | 249 | 60 %| ALS |
| ALS_longitudinal_2 | 21 | 5.06 %| ALS |
| ALS_longitudinal_3 | 21 | 5.06 %| ALS |
| ALS_longitudinal_4 | 22 | 5.3 %| ALS |
| Control | 102 | 24.58 %| Control |

## Mutation Type Distribution

| Mutation Type | Count | Percentage |
|---------------|-------|------------|
| :AC | 130 | 2.39 %|
| :AG | 498 | 9.14 %|
| :AT | 260 | 4.77 %|
| :CA | 180 | 3.3 %|
| :CG | 161 | 2.96 %|
| :CT | 360 | 6.61 %|
| :GA | 408 | 7.49 %|
| :GC | 160 | 2.94 %|
| :GT | 2142 | 39.32 %|
| :TA | 288 | 5.29 %|
| :TC | 599 | 10.99 %|
| :TG | 262 | 4.81 %|
