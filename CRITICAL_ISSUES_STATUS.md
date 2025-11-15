# 📊 CRITICAL ISSUES STATUS

**Date:** 2025-01-21  
**Version:** v1.0.1

---

## ✅ ISSUE #1: INPUT FILE INCONSISTENCY (STEP 1) - **FIXED**

### Status: ✅ **RESOLVED**

### Changes Applied:
- ✅ All panels (B, C, D, E, F, G) now use `processed_clean.csv`
- ✅ `rules/step1.smk` updated: Panels C and D now use `INPUT_DATA_CLEAN`
- ✅ Scripts updated: `02_panel_c_gx_spectrum.R` and `03_panel_d_positional_fraction.R` use `processed_clean`
- ✅ Comments added: "Load processed_clean data (same as other panels for consistency"

### Evidence:
- `rules/step1.smk`: Lines 60, 80 - Comments indicate use of `processed_clean`
- `scripts/step1/02_panel_c_gx_spectrum.R`: Line 43 - Uses `processed_clean`
- `scripts/step1/03_panel_d_positional_fraction.R`: Line 44 - Uses `processed_clean`

---

## 🟡 ISSUE #2: METRIC INCONSISTENCY (STEP 1) - **PARTIALLY FIXED**

### Status: 🟡 **IMPROVED** (Documentation added, but metrics remain different by design)

### Changes Applied:
- ✅ Panel C: Added caption explaining that it counts SNVs, not sums reads (line 94)
  - Caption: "Shows percentage of G>X SNVs (unique events) at each position, not read counts"
- ✅ Panel G: Uses sum of reads (intentional design to show "percentage of G mutation reads")
- ✅ Panels B, E, F: Use sum of reads (intentional design)

### Analysis:
**Different metrics are INTENTIONAL and APPROPRIATE:**
- **Panel C** (unique SNVs): Shows which G>X mutation types occur more frequently as unique events
- **Panel G** (sum of reads): Shows what percentage of G mutation reads are G>T (abundance measure)

**These metrics are complementary, not contradictory:**
- Unique SNVs = diversity of events
- Sum of reads = abundance of events

### Final Recommendation:
✅ **No additional correction required** - Different metrics are appropriate and now well documented.

---

## ✅ ISSUE #3: PANEL E METRIC 1 (G-CONTENT LANDSCAPE) - **FIXED**

### Status: ✅ **RESOLVED**

### Changes Applied:
- ✅ **Corrected logic:** Now sums only reads from that specific position, not all reads from the miRNA
- ✅ **Updated code:** Lines 76-87 in `04_panel_e_gcontent.R`
  - Before: Summed `total_miRNA_counts` (all reads from the miRNA)
  - Now: Sums `position_specific_counts` (only reads from that position)

### Corrected Code:
```r
# ✅ CORRECTED: Sum only reads from that specific position
total_copies_by_position <- data %>%
  filter(str_detect(pos.mut, "^\\d+:G[TCAG]")) %>%
  mutate(Position = as.numeric(str_extract(pos.mut, "^\\d+"))) %>%
  rowwise() %>%
  mutate(position_specific_counts = sum(c_across(all_of(sample_cols)), na.rm = TRUE)) %>%  # Only this position
  ungroup() %>%
  group_by(Position) %>%
  summarise(
    total_G_copies = sum(position_specific_counts, na.rm = TRUE),  # ✅ Only reads from that position
    .groups = 'drop'
  )
```

### Improved Documentation:
- ✅ Updated caption: "Y-axis: Total read counts for G mutations at position | ..."
- ✅ Specific caption: "Each bubble represents a position. Y-position = total read counts for G mutations at that SPECIFIC position (not all reads from miRNAs with G)."

---

## ✅ ISSUE #4: UNUSED DATA IN FIGURES - **FIXED**

### Status: ✅ **RESOLVED**

### Changes Applied:

#### Panel B (Step 1):
- ✅ `n_SNVs` and `n_miRNAs` removed from calculation (comment line 103)
- ✅ Only `total_GT_count` is calculated, which is what is shown

#### Panel F (Step 1):
- ✅ `n_SNVs` removed from calculation (comment line 85)
- ✅ Only `total_mutations` is calculated, which is what is shown

#### Step 0:
- ℹ️ `total_read_counts` and `n_samples_with_snv` in Figures 4 and 5 are calculated because they are used in other figures (Figures 6 and 7)
- ✅ **No correction required** - Calculations are necessary for other visualizations

---

## ✅ ISSUE #5: DATA STRUCTURE ASSUMPTION (STEP 0) - **DOCUMENTED**

### Status: ✅ **DOCUMENTED AND VALIDATED**

### Changes Applied:
- ✅ **Added documentation:** Lines 74-79 in `01_generate_overview.R`
  - Clearly explains what `processed_clean.csv` contains
  - Specifies that sample columns contain SNV counts (not total counts)
- ✅ **Improved validation:** Line 94 - Log clearly indicates what columns contain
- ✅ **Clarifying comments:** Explain that `counts_matrix` contains SNV counts

### Documentation Added:
```r
# ✅ DOCUMENTED: processed_clean.csv contains:
#   - miRNA_name, pos.mut: Identification columns
#   - Sample columns: SNV counts (number of reads supporting each specific SNV)
#   - VAF_* columns: Variant Allele Frequency (if present)
# IMPORTANT: Sample columns contain SNV counts (not total miRNA counts)
# Each row represents one unique SNV event, and sample columns contain read counts for that specific SNV
```

### Validation:
- ✅ Log clearly shows what was detected: "Detected X count columns and Y VAF columns"
- ✅ Log explains: "NOTE: Count columns contain SNV counts (reads supporting each specific SNV), not total miRNA counts"

---

## 📊 FINAL SUMMARY

| # | Issue | Status | Action Required |
|---|-------|--------|-----------------|
| 1 | Input file inconsistency | ✅ FIXED | None |
| 2 | Metric inconsistency | 🟡 IMPROVED | None (different metrics are appropriate) |
| 3 | Panel E Metric 1 | ✅ FIXED | None |
| 4 | Unused data | ✅ FIXED | None |
| 5 | Data structure assumption | ✅ DOCUMENTED | None |

---

## ✅ CONCLUSION

**All critical issues identified have been addressed:**

- **3 issues completely fixed** (Issues 1, 3, 4)
- **1 issue improved with documentation** (Issue 2 - different metrics are appropriate)
- **1 issue documented and validated** (Issue 5 - data structure clarified)

### Next Steps:
1. ✅ **Test the pipeline** with all fixes applied
2. ✅ **Update README** if necessary
3. ✅ **Create release tag v1.0.1**

---

**Last updated:** 2025-01-21
