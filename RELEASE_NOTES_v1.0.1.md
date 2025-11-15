# 🎉 Release Notes v1.0.1

**Date:** 2025-01-21  
**Type:** Bugfix and Improvements  
**Priority:** 🔴 **Critical Update Recommended**

---

## 📋 Executive Summary

This version includes a **critical fix** for VAF calculation in Step 2, plus a **comprehensive perfectionist review** that significantly improves the quality, robustness and consistency of code and visualizations. Includes massive elimination of duplicate code, complete style standardization and improvements in scientific clarity.

### ⚠️ **IMMEDIATE UPDATE RECOMMENDED**

If you are using the pipeline for data analysis, you must update to this version because:
- **Critical fix:** Step 2 results were using incorrect metrics (counts instead of VAF)
- Without this fix, all figures and statistical analyses from Step 2 are incorrect
- **Massive improvements:** ~2000 lines of duplicate code eliminated, complete standardization of colors and dimensions, robustness and scientific clarity improvements

---

## 🔴 Critical Fixes

### 1. VAF Calculation in Step 2 (Critical)

**Problem:**
- Detailed Step 2 scripts expected VAF (Variant Allele Frequency) values as input
- They were receiving only SNV counts, without Total columns
- **Result:** Figures showed incorrect values (counts instead of VAF)
- **Impact:** All statistical analyses and visualizations from Step 2 were using incorrect metrics

**Solution:**
- Automatic detection of Total columns in `processed_clean.csv`
- Correct calculation: `VAF = SNV_Count / Total_Count`
- Automatic filtering of VAF >= 0.5 (technical artifacts) → NA
- Replacement of SNV counts with calculated VAF values
- Scripts now receive VAF directly, as expected

**Files modified:**
- `scripts/step2_figures/run_all_step2_figures.R` - Main logic
- `rules/step2_figures.smk` - Input change to `processed_clean.csv`

**How to verify:**
1. Run Step 2: `snakemake -j 1 all_step2_figures`
2. Check log: Should show "VAF calculated and filtered"
3. Verify figures: Should show values between 0 and 0.5 (valid VAF range)

### 2. Heatmap Combination FIG_2.15

**Problem:**
- ALS and Control have different number of columns (23 vs 21)
- Cannot be combined directly with `+` or `%v%` in patchwork

**Solution:**
- Implemented fallback using `grid.layout` for side-by-side layout
- FIG_2.15 now generates correctly

**File modified:**
- `scripts/step2_figures/original_scripts/generate_FIG_2.13-15_DENSITY.R`

---

## 🔧 Compatibility Fixes

### ggplot2 3.4+ Compatibility

**Problem:**
- ggplot2 3.4+ deprecated the `size` parameter in favor of `linewidth`
- Code used `size` in `geom_tile()`, `geom_hline()`, etc.

**Solution:**
- Replaced `size` with `linewidth` in all affected scripts
- Compatible with earlier and future versions of ggplot2

**Files modified:** 11 scripts total
- Steps 0, 1, 1.5, 2, 5

---

## ✨ Improvements (Perfectionist Review)

### 🔧 Code Improvements (PHASE 1)

#### Massive Duplicate Code Elimination
- **~2000 lines of duplicate code eliminated:**
  - `logging.R`: 1067 → 356 lines (67% reduction)
  - `validate_input.R`: 1144 → 383 lines (67% reduction)
  - `build_step1_viewer.R`: 1015 → 338 lines (67% reduction)
- **Style centralization:**
  - Created centralized `colors.R` with all color definitions
  - Removed duplicate definition of `theme_professional`
  - All scripts now use centralized colors and themes

#### Robustness and Validation
- **Explicit namespaces:** `readr::read_csv()`, `stringr::str_detect()` in all scripts
- **Robust validation:** Validation of empty data frames and missing columns in all scripts
- **Loop robustness:** Replaced `1:n` with `seq_len(n)` and `seq_along()` to avoid errors

#### Pattern Standardization
- 30+ scripts updated to use centralized colors
- Helper functions created for heatmap gradients
- `stringr` namespaces standardized

### 🎨 Visual Improvements (PHASE 2)

#### Visual Quality
- **Complete color standardization:** 30+ scripts updated
- **Consistent dimensions:** 13 scripts updated to use `config.yaml`
- **White background:** All `png()` calls now include `bg = "white"`

#### Consistency Between Figures
- **Standardized axis scales:** X-axis breaks, angle, Y-axis expand consistent
- **Explicit formatting:** `scales::comma` and `scales::percent` for consistency
- **Complete translation:** All text now in English

#### Scientific Clarity
- **Improved titles and subtitles:** 13 scripts with consistent biological explanations
- **Improved captions:** Explanation of statistical methods (FDR, Cohen's d, Wilcoxon, ROC, AUC)
- **Standardized terminology:** "seed region (functional binding domain)", "oxidative signature"

### 📚 Documentation Improvements (PHASE 3)

#### User Documentation
- **README.md corrected:** Typographical error, broken references removed, figure count corrected
- **QUICK_START.md updated:** Broken references replaced with useful references
- **Consistent version:** `config.yaml.example` updated to "1.0.1"

#### Visual Improvements (Initial Version)
- **Highlight G>T in red** in QC FIGURE 2 for consistency with pipeline standard
- Better outlier visibility (`outlier.size` increased to 1.0)
- Captions explaining approximations in calculations
- Clarification in QC FIGURE 4 about approximate values

---

## 📚 New Documentation

### CRITICAL_ISSUES_STATUS.md
- Identification of 5 critical cohesion issues in the pipeline
- All issues identified have been resolved or improved:
  - ✅ Input file inconsistency (Step 1) - RESOLVED
  - 🟡 Metric inconsistency (Step 1) - IMPROVED (different metrics are appropriate)
  - ✅ Panel E Metric 1 - RESOLVED
  - ✅ Data structure assumption (Step 0) - DOCUMENTED
  - ✅ Unused data in figures - RESOLVED
- Complete status report of all critical issues

---

## 🔄 Detailed Technical Changes

### Files Modified (18 files)

#### Critical Fixes (3 files)
1. `scripts/step2_figures/run_all_step2_figures.R` - VAF calculation
2. `scripts/step2_figures/original_scripts/generate_FIG_2.13-15_DENSITY.R` - Heatmap layout
3. `rules/step2_figures.smk` - Input configuration

#### ggplot2 Compatibility (11 files)
- `scripts/step0/01_generate_overview.R`
- `scripts/step1/01_panel_b_gt_count_by_position.R`
- `scripts/step1/02_panel_c_gx_spectrum.R`
- `scripts/step1/03_panel_d_positional_fraction.R`
- `scripts/step1/04_panel_e_gcontent.R`
- `scripts/step1/05_panel_f_seed_vs_nonseed.R`
- `scripts/step1/06_panel_g_gt_specificity.R`
- `scripts/step1_5/02_generate_diagnostic_figures.R`
- `scripts/step2/03_effect_size_analysis.R`
- `scripts/step2/05_position_specific_analysis.R`
- `scripts/step5/02_family_comparison_visualization.R`

#### Other minor changes (4 files)
- `rules/step1.smk` - Minor adjustments

### Statistics (Complete Version 1.0.1)
- **Lines added:** +831 (initial) + ~500 (perfectionist review)
- **Lines removed:** -96 (initial) + ~2000 (duplicate code eliminated)
- **Net:** -~765 lines (significant reduction)
- **New files:** 3 (initial documentation) + 1 (`colors.R`)
- **Files modified:** 18 (initial) + 70+ (perfectionist review)
- **Scripts reviewed:** All pipeline scripts (100% coverage)

---

## ⚙️ Installation and Update

### If you already have the pipeline installed:

```bash
cd miRNA-oxidation-pipeline
git pull origin main
```

### If this is a new installation:

```bash
git clone https://github.com/cesparza2022/miRNA-oxidation-pipeline.git
cd miRNA-oxidation-pipeline
bash setup.sh --mamba  # or --conda
```

### Verification after updating:

```bash
# Verify that changes are present
git log --oneline -3

# Should show:
# 7d6ea94 fix: Critical VAF Step 2 fixes and compatibility improvements
```

---

## ⚠️ Important Notes

### If you already ran Step 2 with the previous version:

1. **Re-run Step 2** with this version:
   ```bash
   snakemake -j 1 all_step2_figures --forceall
   ```

2. **Review the results:**
   - Figures should show values between 0 and 0.5 (VAF)
   - Statistical analyses should be different (now correct)

### Critical Issues Status:

**All originally identified critical issues have been resolved or improved.**  
See `CRITICAL_ISSUES_STATUS.md` for complete details:

- ✅ **Input file inconsistency (Step 1)** - RESOLVED
- 🟡 **Metric inconsistency (Step 1)** - IMPROVED (different metrics are appropriate)
- ✅ **Panel E Metric 1 (incorrect sum)** - RESOLVED
- ✅ **Data structure assumption (Step 0)** - DOCUMENTED
- ✅ **Unused data in figures** - RESOLVED

---

## 🙏 Acknowledgments

Thanks to the exhaustive review that identified these critical issues, especially:
- Review of calculation logic
- Identification of incompatibilities with ggplot2
- Documentation of pending issues

---

## 📞 Support

If you encounter problems after updating:
1. Review Step 2 VAF calculation logic in `scripts/step2_figures/run_all_step2_figures.R` for technical details
2. Review logs in `results/step2/final/logs/`
3. Verify that `processed_clean.csv` has Total columns

---

**Last updated:** 2025-01-21  
**Commit:** 7d6ea94
