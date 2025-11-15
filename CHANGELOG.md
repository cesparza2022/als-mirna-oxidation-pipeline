# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.1] - 2025-01-21

### 🔴 Fixed (Critical)

#### Step 2 - VAF Calculation
- **Critical fix for VAF calculation in detailed figures**
  - Step 2 scripts (FIG_2.1 to FIG_2.15) expected VAF values as input, but received only SNV counts
  - **Problem:** Figures showed incorrect values (counts instead of VAF)
  - **Solution implemented:**
    - Automatic detection of Total columns (pattern `(PM+1MM+2MM)`)
    - Correct VAF calculation: `VAF = SNV_Count / Total_Count`
    - Filtering of VAF >= 0.5 (technical artifacts) → NA
    - Replacement of SNV columns with calculated VAF values
    - Removal of Total columns (scripts now have VAF directly)
  - **Files affected:**
    - `scripts/step2_figures/run_all_step2_figures.R` - Main VAF calculation logic
    - `rules/step2_figures.smk` - Input change from `VAF_FILTERED` to `PRIMARY` (processed_clean.csv)
  - **Impact:** Without this fix, all Step 2 analyses were using incorrect metrics

#### Step 2 - Heatmap Combination FIG_2.15
- **Fix for heatmap combination for FIG_2.15**
  - **Problem:** ALS and Control have different number of columns (23 vs 21), cannot be combined with `+` or `%v%`
  - **Solution:** Implemented fallback using `grid.layout` for side-by-side layout
  - **File affected:** `scripts/step2_figures/original_scripts/generate_FIG_2.13-15_DENSITY.R`
  - **Impact:** FIG_2.15 now generates correctly

### 🔧 Fixed (Compatibility)

#### ggplot2 3.4+ Compatibility
- **Deprecated parameter update**
  - Replaced `size` with `linewidth` in ggplot2 functions
  - Affects: `geom_tile()`, `geom_hline()`, `geom_vline()`, etc.
  - **Files affected:**
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
  - **Impact:** Avoids warnings/errors in ggplot2 3.4+ and ensures future compatibility

#### Minor compatibility improvements
- Fixed `outlier.size = 0.5` → `outlier.size = 1.0` for better visibility
- Minor adjustments in linewidth for better visualization

### ✨ Added (Improvements)

#### Visual Improvements
- **Highlight G>T in red for consistency**
  - QC FIGURE 2 panel now highlights G>T mutations in red
  - Consistency with visualization standard across the pipeline
  - **File affected:** `scripts/step1_5/02_generate_diagnostic_figures.R`

#### Improved Documentation
- **Documentation of approximations in calculations**
  - Added captions explaining that some values are approximations
  - Clarification in QC FIGURE 4 about approximation of original values
  - **File affected:** `scripts/step1_5/02_generate_diagnostic_figures.R`

### 📚 Added (Documentation)

#### New Analysis Documents
- **COMPARACION_LOCAL_vs_GITHUB.md**
  - Detailed comparison between local and GitHub versions
  - Summary of all changes and their importance
  - Recommended action plan

- **CORRECCION_STEP2_VAF.md**
  - Detailed documentation of the critical VAF calculation fix
  - Explanation of problem, solution, and verification
  - Corrected data flow

- **ESTADO_PROBLEMAS_CRITICOS.md** (now `CRITICAL_ISSUES_STATUS.md`)
  - Identification of 5 critical cohesion issues in the pipeline
  - Issues identified but **NOT yet fixed**:
    1. 🔴 Input file inconsistency (Step 1)
    2. 🔴 Metric inconsistency (Step 1)
    3. 🔴 Panel E Metric 1 - Sums reads from other positions
    4. 🔴 Data structure assumption (Step 0)
    5. 🟡 Unused data in figures
  - Recommended action plan for future fixes

### 🔄 Changed (Major Refactoring - Perfectionist Review)

#### PHASE 1.1: Massive Duplicate Code Elimination
- **Critical fix for tripled duplicate code:**
  - `scripts/utils/logging.R`: Reduced from 1067 → 356 lines (67% reduction)
  - `scripts/utils/validate_input.R`: Reduced from 1144 → 383 lines (67% reduction)
  - `scripts/utils/build_step1_viewer.R`: Reduced from 1015 → 338 lines (67% reduction)
  - **Impact:** Eliminated ~2000 lines of duplicate code, improving maintainability

- **Style centralization:**
  - Created centralized `scripts/utils/colors.R` with all color definitions
  - Removed duplicate definition of `theme_professional` in `functions_common.R`
  - All scripts now use centralized colors and themes

#### PHASE 1.2: Robustness, Efficiency and Clarity Improvements
- **Explicit namespaces:**
  - Replaced `read_csv()` with `readr::read_csv()` in all scripts
  - Replaced `str_detect()` with `stringr::str_detect()` where applicable
  - Added `suppressPackageStartupMessages()` for silent imports

- **Robust data validation:**
  - Added validation for empty data frames (`nrow == 0`, `ncol == 0`)
  - Validation of missing critical columns in all scripts
  - Better handling of edge cases (empty data, missing columns)

- **Loop robustness:**
  - Replaced `1:n` with `seq_len(n)` and `seq_along()` to avoid problems with empty vectors
  - Improved `safe_execute()` in `error_handling.R` for correct expression evaluation

#### PHASE 1.3: Pattern Standardization
- **Centralized colors:**
  - 11 scripts updated to use `COLOR_GT`, `COLOR_ALS`, `COLOR_CONTROL` from `colors.R`
  - Created helper functions for heatmap gradients: `get_heatmap_gradient()`, `get_blue_red_heatmap_gradient()`
  - Eliminated hardcoded color values

- **stringr namespaces:**
  - 5 scripts updated to use explicit `stringr::` namespace
  - Consistency in string manipulation function usage

#### PHASE 1.4: Validation and Testing
- Complete review of existing validation scripts
- Confirmed robustness of validations implemented in PHASE 1.2
- Documented hybrid strategy (centralized + ad-hoc) as optimal

#### PHASE 2.1: Visual Quality of Graphics
- **Color standardization:**
  - 30+ scripts updated to use centralized colors from `colors.R`
  - Created new constants: `COLOR_SEED`, `COLOR_NONSEED`, `COLOR_SEED_HIGHLIGHT`, etc.
  - Helper functions for color gradients in heatmaps

- **Figure dimensions:**
  - 13 scripts updated to use `fig_width`, `fig_height`, `fig_dpi` from `config.yaml`
  - Eliminated hardcoded dimension values
  - Consistency across all pipeline figures

#### PHASE 2.2: Consistency Between Figures
- **Standardized axis scales:**
  - X-axis breaks: All Step 1 panels now show all positions (1-23)
  - X-axis angle: Standard 45° for better readability
  - Y-axis expand: Consistent `expansion(mult = c(0, 0.1))` across all panels

- **Labels and formatting:**
  - Explicit use of `scales::comma` and `scales::percent` for formatting
  - Complete translation of `step2/05_position_specific_analysis.R` to English
  - Improved axis labels with scientific explanations

#### PHASE 2.3: Scientific Clarity
- **Improved titles and subtitles:**
  - 13 scripts updated with consistent biological explanations
  - Scientific terms explained: "seed region (functional binding domain)", "oxidative signature"
  - More descriptive subtitles with biological context

- **Improved captions:**
  - Step 1: Clarification on "unique SNVs" vs "read counts"
  - Step 2: Explanation of statistical methods (FDR, Cohen's d, Wilcoxon)
  - Step 6-7: Analysis details (ROC, AUC, Pearson correlation, linear regression)

- **Legends and annotations:**
  - Improved legends with clear explanations
  - Improved seed region annotations in multiple scripts
  - Standardized terminology ("Non-Seed" → "Non-seed")

#### PHASE 2.4: Technical Quality
- **Output format:**
  - All `png()` calls now include `bg = "white"` for consistent white background
  - 7 scripts updated with `bg = "white"`
  - `par(bg = "white")` added for base R plots

- **Final dimensions:**
  - `step0/01_generate_overview.R` updated to use config for all 8 figures
  - Complete consistency in dimensions across all pipeline figures

#### PHASE 3.1: User Documentation
- **README.md corrections:**
  - Typographical error fixed: "datas´" → "data"
  - Removed 11 broken references to non-existent files
  - Reorganized documentation section without broken references
  - Fixed Step 2 figure count: "73" → "21" (5 basic + 16 detailed)

- **Consistent version:**
  - `config/config.yaml.example` updated from "1.0.0" → "1.0.1"

- **QUICK_START.md updated:**
  - Removed broken references
  - Replaced with useful references to specific sections of README.md

### 🔄 Changed (Minor Refactoring - Initial Version 1.0.1)

- Improvements in comments and internal documentation
- Minor adjustments in visualization logic
- Improvements in log messages and output

---

## [1.0.0] - 2025-01-21

### Initial Release
- Complete functional pipeline (Steps 0-7)
- Complete exhaustive review of all scripts
- Complete documentation
- Flexible group system
- Robust statistical analysis with assumption validation
- Batch effects and confounders analysis

---

## Version Notes

### Version 1.0.1
- **Release date:** 2025-01-21
- **Release type:** Bugfix, improvements and major refactoring (perfectionist review)
- **Compatibility:** Requires ggplot2 3.4+ for best experience (but compatible with earlier versions)
- **Breaking changes:** None
- **Recommendation:** Update immediately due to critical VAF fix and massive code improvements
- **Main improvements:**
  - Critical VAF calculation fix in Step 2
  - Elimination of ~2000 lines of duplicate code
  - Complete standardization of colors, themes and figure dimensions
  - Improved robustness in data validation and error handling
  - Improved scientific clarity in all figures
  - Updated and corrected user documentation

### Version 1.0.0
- **Release date:** 2025-01-21
- **Release type:** Stable
- **Status:** Complete and functional pipeline

---

## Critical Issues Status

**All originally identified critical issues have been resolved or improved.**  
See `CRITICAL_ISSUES_STATUS.md` for complete details:

1. ✅ **Input file inconsistency (Step 1)** - **RESOLVED**
   - All panels now use `processed_clean.csv` consistently
   - `rules/step1.smk` updated to use `INPUT_DATA_CLEAN` in all panels

2. 🟡 **Metric inconsistency (Step 1)** - **IMPROVED**
   - Different metrics are intentional and appropriate (diversity vs abundance)
   - Documentation added explaining the differences and their purpose

3. ✅ **Panel E Metric 1 (G-Content Landscape)** - **RESOLVED**
   - Corrected logic: now sums only reads from the specific position
   - Caption updated for clarity

4. ✅ **Data structure assumption (Step 0)** - **DOCUMENTED**
   - Clear documentation added about `processed_clean.csv` structure
   - Improved validation with descriptive logs

5. ✅ **Unused data in figures** - **RESOLVED**
   - Unnecessary calculations removed (Panel B, F from Step 1)
   - Calculations necessary for other visualizations maintained and documented

---

**Changelog format:** Based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

