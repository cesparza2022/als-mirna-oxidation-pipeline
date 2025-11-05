# 📊 STEP 1: Exploratory Analysis of miRNA G>T Mutations

**Date:** 2025-10-24  
**Version:** 1.0 - Reorganized  
**Status:** ✅ Consolidated and Organized

---

## 🎯 **OBJECTIVE**

Perform initial exploratory analysis of the miRNA sequencing dataset to characterize:
1. Dataset composition and processing effects
2. G>T mutation distribution across miRNA positions
3. Positional enrichment patterns
4. G-content correlation with mutation frequency
5. Seed region (pos 2-8) vs non-seed differences

**Important:** This is a **pre-filtering** analysis - NO VAF filtering, NO group comparison (ALS vs Control).

---

## 📊 **8 VISUALIZATION PANELS**

### **Section 1: Dataset Overview and Global Patterns**

#### **Panel A: Dataset Overview**
- **File:** `step1_panelA_dataset_overview.png`
- **Shows:** SNV evolution through processing (raw → split → collapse), sample distribution
- **Purpose:** Understand data transformation and basic statistics

#### **Panel B: G>T Count by Position**
- **File:** `step1_panelB_gt_count_by_position.png`
- **Shows:** Absolute G>T mutation count across all positions (1-22)
- **Purpose:** Identify positional hotspots for G>T mutations

#### **Panel C: G>X Mutation Spectrum by Position**
- **File:** `step1_panelC_gx_spectrum.png`
- **Shows:** Complete G mutation spectrum (G>T, G>C, G>A) by position
- **Purpose:** Demonstrate G>T predominance (oxidative damage signature)

---

### **Section 2: Positional Metrics and G-Content**

#### **Panel D: Positional Fraction of Mutations**
- **File:** `step1_panelD_positional_fraction.png`
- **Shows:** Proportion of mutations at each position (relative to total)
- **Purpose:** Identify positional enrichment independent of absolute counts
- **Note:** This is DIFFERENT from Panel E (G-content) - Panel D shows mutation distribution, Panel E shows substrate availability

#### **Panel E: G-Content Landscape (Multi-Dimensional)**
- **File:** `step1_panelE_FINAL_BUBBLE.png`
- **Shows:** Three-dimensional G-content analysis:
  - **Bubble height (Y-axis):** Total miRNA copies with G at position (substrate availability)
  - **Bubble size:** Number of unique miRNAs with G (diversity)
  - **Bubble color (red intensity):** G>T SNV counts at specific position (oxidation burden)
- **Purpose:** Comprehensive substrate-product relationship visualization
- **Script:** `scripts/05_gcontent_analysis.R`
- **Note:** Multi-dimensional plot integrating substrate availability, miRNA diversity, and oxidation burden in single visualization

#### **Panel F: Seed Region Interaction**
- **File:** `step1_panelF_seed_interaction.png`
- **Shows:** Mutation pattern comparison: seed (2-8) vs non-seed
- **Purpose:** Assess functional region importance (seed is critical for target recognition)

---

### **Section 3: G>T Specificity and Context**

#### **Panel G: G>T Specificity Analysis**
- **File:** `step1_panelG_gt_specificity.png`
- **Shows:** G>T proportion vs other G transversions (G>C, G>A)
- **Purpose:** Quantify oxidative damage specificity
- **Note:** This is DIFFERENT from Panel C - Panel C shows distribution by position, Panel G shows overall specificity ratio

#### **Panel H: Sequence Context Around G>T Sites**
- **File:** `step1_panelH_sequence_context.png`
- **Shows:** Preliminary analysis of adjacent nucleotides around G>T sites
- **Purpose:** Initial context exploration (detailed motif analysis will be done after VAF filtering)
- **Status:** Preliminary - not as critical as other panels for initial exploration

---

## 🔄 **DATA PROCESSING STEPS**

### **1. Split**
- **Input:** Raw dataset with multi-position entries (e.g., "1,2:GT")
- **Process:** Separate into individual rows (1:GT, 2:GT)
- **Purpose:** Enable position-specific analysis

### **2. Collapse**
- **Input:** Split dataset with potential duplicates
- **Process:** Combine identical SNVs (same miRNA, position, mutation) across samples
- **Purpose:** Consolidate redundant entries

### **3. No Filtering (for Step 1)**
- **VAF filtering:** NOT applied (all variants included regardless of allele frequency)
- **Group separation:** NOT applied (ALS + Control combined)
- **Purpose:** Get unbiased overview of entire dataset

---

## 📂 **FILE STRUCTURE**

```
STEP1_ORGANIZED/
├── figures/
│   ├── step1_panelA_dataset_overview.png
│   ├── step1_panelB_gt_count_by_position.png
│   ├── step1_panelC_gx_spectrum.png
│   ├── step1_panelD_positional_fraction.png
│   ├── step1_panelE_gcontent.png
│   ├── step1_panelF_seed_interaction.png
│   ├── step1_panelG_gt_specificity.png
│   └── step1_panelH_sequence_context.png
│
├── scripts/
│   ├── 01_dataset_evolution.R       (Panel A)
│   ├── 02_gt_count_analysis.R       (Panel B)
│   ├── 03_gx_spectrum_analysis.R    (Panel C)
│   ├── 04_positional_fraction.R     (Panel D)
│   ├── 05_gcontent_analysis.R       (Panel E)
│   ├── 06_seed_interaction.R        (Panel F)
│   ├── 07_gt_specificity.R          (Panel G)
│   └── 08_sequence_context.R        (Panel H)
│
├── data/
│   ├── raw_data.csv
│   ├── split_data.csv
│   ├── collapsed_data.csv
│   └── (intermediate CSVs for each analysis)
│
└── documentation/
    ├── STEP1_README.md              (this file)
    ├── CLARIFICATIONS.md            (panel differences explained)
    └── PROCESSING_DETAILS.md        (technical details)
```

---

## 🔍 **KEY CLARIFICATIONS**

### **Panel D vs Panel E - Not Redundant**
- **Panel D:** Positional **fraction** (proportion of mutations at each position)
  - Example: Position 5 has 8% of all mutations
- **Panel E:** G-**content** (number of Guanines at each position)
  - Example: Position 5 has 150 Guanines across all miRNAs
- **Relationship:** Compare D and E to see if high G-content positions have more mutations

### **Panel C vs Panel G - Different Perspectives**
- **Panel C:** G>X spectrum **by position** (spatial distribution)
  - Shows WHERE each mutation type occurs
- **Panel G:** G>T **specificity** (overall ratio)
  - Shows WHAT proportion of G mutations are G>T (vs G>C, G>A)
- **Complementary:** C shows distribution, G shows selectivity

### **Panel H - Preliminary Status**
- **Current:** Basic adjacent nucleotide conservation
- **Future (Step 2+):** Advanced motif analysis (sequence logos, trinucleotide context) after VAF filtering
- **Why delay:** VAF filtering removes low-confidence variants, improving motif signal

---

## 💡 **KEY INSIGHTS**

1. **G>T Enrichment:** G>T is the predominant mutation type (oxidative damage signature)
2. **Positional Heterogeneity:** Mutations are NOT uniformly distributed
3. **Seed Region Importance:** Functional consequences likely higher in seed (2-8)
4. **G-Content Correlation:** Preliminary evidence of G-content influence on mutation frequency
5. **Next Steps:** VAF filtering and ALS vs Control comparison (Step 2)

---

## 🔧 **TECHNICAL NOTES**

### **Nomenclature Corrections (2025-10-24)**
- **Old:** Inconsistent panel_X prefixes (multiple files with panel_c_*)
- **New:** Consistent step1_panelX_description naming
- **Reason:** Avoid confusion, improve traceability

### **HTML Improvements**
- **Title:** English, more precise ("Exploratory Analysis" not just "Análisis Inicial")
- **Sections:** Organized into 3 logical sections (Overview, Positional, Specificity)
- **Descriptions:** Clarified what each panel shows and why it's important
- **Notes:** Added context for Panel H (preliminary) and Panel D/E/C/G differences

### **No Hardcoded Metadata**
- **Issue:** Previous HTML had hardcoded values (5,448 SNVs, 415 samples)
- **Solution:** For future automation, these should be calculated dynamically from data
- **Status:** Documented as TODO for pipeline automation

---

## ✅ **COMPLETION CHECKLIST**

- [x] 8 figures saved with consistent naming
- [x] HTML reorganized with clear sections
- [x] Panel descriptions clarified (D vs E, C vs G)
- [x] Processing steps documented (Split, Collapse)
- [x] Panel H status noted (preliminary, not critical)
- [x] File structure created
- [ ] Scripts R documented and verified (TODO)
- [ ] Dynamic HTML generation (TODO for automation)

---

## 🚀 **NEXT STEPS (STEP 2)**

1. **VAF Filtering:** Apply VAF >= 0.5 threshold
2. **Group Comparison:** ALS vs Control differential analysis
3. **Statistical Testing:** Wilcoxon, Fisher's exact, FDR correction
4. **Advanced Context:** Trinucleotide motif analysis with high-confidence variants
5. **Volcano Plots:** Identify differentially mutated miRNAs

---

**Consolidated by:** AI Assistant  
**Date:** 2025-10-24  
**Status:** Ready for Step 2

