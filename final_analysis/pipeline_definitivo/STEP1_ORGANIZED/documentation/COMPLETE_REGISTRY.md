# 📋 COMPLETE REGISTRY - STEP 1 REORGANIZATION

**Date:** 2025-10-24  
**Purpose:** Maintain complete record of all changes, original files, and organization

---

## 🗂️ **ORIGINAL FILES PRESERVED**

### **Original Figures Location:**
```
pipeline_2/figures/
```

### **Original Figures Used (CORRECTED versions):**
1. `panel_a_overview_CORRECTED.png` → Now: `step1_panelA_dataset_overview.png`
2. `panel_b_positional_CORRECTED.png` → Now: `step1_panelB_gt_count_by_position.png`
3. `panel_c_spectrum_CORRECTED.png` → Now: `step1_panelC_gx_spectrum.png`
4. `panel_d_positional_fraction_CORRECTED.png` → Now: `step1_panelD_positional_fraction.png`
5. `panel_a_gcontent_CORRECTED.png` → Now: `step1_panelE_FINAL_BUBBLE.png` (UPDATED: Multi-dimensional bubble plot)
6. `panel_c_seed_interaction_CORRECTED.png` → Now: `step1_panelF_seed_interaction.png`
7. `panel_c_specificity_CORRECTED.png` → Now: `step1_panelG_gt_specificity.png`
8. `panel_e_sequence_context.png` → Now: `step1_panelH_sequence_context.png`

**Note:** Original files in `pipeline_2/figures/` are PRESERVED (not deleted).

---

## 📂 **NEW ORGANIZED STRUCTURE**

```
STEP1_ORGANIZED/
├── figures/                          ← 8 renamed figures
├── scripts/                          ← R scripts (to be added)
├── data/                             ← Input/intermediate data
└── documentation/
    ├── STEP1_README.md               ← Main documentation
    ├── COMPLETE_REGISTRY.md          ← This file
    └── CLARIFICATIONS.md             ← Panel differences (to be created)
```

---

## 🔄 **MAPPING: OLD → NEW**

| Panel | Old File Name | New File Name | Section |
|-------|--------------|---------------|---------|
| A | `panel_a_overview_CORRECTED.png` | `step1_panelA_dataset_overview.png` | Overview |
| B | `panel_b_positional_CORRECTED.png` | `step1_panelB_gt_count_by_position.png` | Overview |
| C | `panel_c_spectrum_CORRECTED.png` | `step1_panelC_gx_spectrum.png` | Overview |
| D | `panel_d_positional_fraction_CORRECTED.png` | `step1_panelD_positional_fraction.png` | Positional |
| E | `panel_a_gcontent_CORRECTED.png` | `step1_panelE_gcontent.png` | Positional |
| F | `panel_c_seed_interaction_CORRECTED.png` | `step1_panelF_seed_interaction.png` | Positional |
| G | `panel_c_specificity_CORRECTED.png` | `step1_panelG_gt_specificity.png` | Specificity |
| H | `panel_e_sequence_context.png` | `step1_panelH_sequence_context.png` | Specificity |

---

## ❌ **ISSUES RESOLVED**

### **1. Panel Duplication - FIXED**
**Problem:** Multiple files with `panel_c_*` prefix:
- `panel_c_spectrum_CORRECTED.png`
- `panel_c_seed_interaction_CORRECTED.png`
- `panel_c_specificity_CORRECTED.png`

**Solution:** Renamed to unique prefixes matching panel letter:
- Panel C → `step1_panelC_gx_spectrum.png`
- Panel F → `step1_panelF_seed_interaction.png`
- Panel G → `step1_panelG_gt_specificity.png`

### **2. Inconsistent Naming - FIXED**
**Problem:** Panels E, F, G, H used wrong alphabetic prefixes
- Panel E used `panel_a_*`
- Panel F used `panel_c_*`
- Panel G used `panel_c_*`
- Panel H used `panel_e_*`

**Solution:** All panels now use correct alphabetic prefix (A-H)

### **3. Ambiguous Descriptions - FIXED**
**Problem:** Panel descriptions were unclear about what each shows

**Solutions:**
- **Panel B:** Clarified it shows ALL positions (1-22), not just seed
- **Panel D vs E:** Documented that D = mutation fraction, E = G-content (complementary, not redundant)
- **Panel C vs G:** Documented that C = spectrum by position, G = overall specificity (different perspectives)
- **Panel H:** Noted as preliminary (detailed motif analysis comes later)

### **4. HTML Title - FIXED**
**Problem:** Spanish title "Análisis Inicial Completo"  
**Solution:** English title "Exploratory Analysis of miRNA G>T Mutations"

### **5. Section Organization - IMPROVED**
**Old:** All 8 panels in one continuous list  
**New:** 3 logical sections:
1. Dataset Overview and Global Patterns (A, B, C)
2. Positional Metrics and G-Content (D, E, F)
3. G>T Specificity and Context (G, H)

---

## 🔍 **CLARIFICATIONS DOCUMENTED**

### **Panel D (Positional Fraction) vs Panel E (G-Content)**
- **D:** What **proportion** of mutations occur at each position
  - Metric: Fraction (% of total mutations)
  - Example: "Position 5 has 8% of all mutations"
- **E:** How many **Guanines** exist at each position (substrate)
  - Metric: Count (number of Gs)
  - Example: "Position 5 has 150 Guanines"
- **Relationship:** Compare to see if high-G positions have more mutations

### **Panel C (G>X Spectrum) vs Panel G (G>T Specificity)**
- **C:** **WHERE** different mutation types occur (spatial distribution)
  - Shows G>T, G>C, G>A distribution across positions 1-22
  - Answers: "Which positions have more G>T?"
- **G:** **WHAT** proportion of G mutations are G>T (overall)
  - Shows G>T ratio vs other G transversions
  - Answers: "Is G>T predominant among G mutations?"
- **Relationship:** C shows spatial pattern, G shows overall selectivity

### **Panel H - Status**
- **Current:** Preliminary adjacent nucleotide conservation
- **Why preliminary:** Detailed motif analysis requires VAF-filtered, high-confidence variants
- **Future:** Sequence logos, trinucleotide context (Step 2+)
- **Importance:** Useful for context but not critical for initial exploration

---

## 📝 **HTML FILES**

### **Original HTML:**
- `PASO_1_CONSOLIDADO_FINAL.html` (Spanish, inconsistent naming)

### **New Reorganized HTML:**
- `PASO_1_REORGANIZED.html` (English, organized sections, new figure paths)

**Key Changes:**
1. English title and descriptions
2. 3-section organization
3. Updated image paths → `STEP1_ORGANIZED/figures/`
4. Added notes explaining Panel H and panel differences
5. Clarified processing steps (Split, Collapse)
6. Added "Key Insights" section

---

## 🗄️ **DATA FILES TO BE ORGANIZED**

### **Input Data:**
- `raw_data.csv` - Original sequencing data
- `split_data.csv` - After split operation
- `collapsed_data.csv` - After collapse operation

### **Intermediate Data (to be saved):**
- `panel_A_dataset_stats.csv`
- `panel_B_gt_by_position.csv`
- `panel_C_gx_spectrum.csv`
- `panel_D_positional_fractions.csv`
- `panel_E_gcontent_by_position.csv`
- `panel_F_seed_comparison.csv`
- `panel_G_gt_specificity.csv`
- `panel_H_sequence_context.csv`

**Status:** TO BE COLLECTED (need to identify where these are currently saved)

---

## 📜 **SCRIPTS TO BE DOCUMENTED**

### **Expected Scripts (to be verified/created):**
1. `01_dataset_evolution.R` - Generates Panel A
2. `02_gt_count_analysis.R` - Generates Panel B
3. `03_gx_spectrum_analysis.R` - Generates Panel C
4. `04_positional_fraction.R` - Generates Panel D
5. `05_gcontent_analysis.R` - Generates Panel E
6. `06_seed_interaction.R` - Generates Panel F
7. `07_gt_specificity.R` - Generates Panel G
8. `08_sequence_context.R` - Generates Panel H

**Status:** TO BE COLLECTED (need to identify actual scripts used)

**Likely Locations:**
- `pipeline_2/scripts/`
- `01_analisis_inicial/`
- Individual analysis directories

---

## ⚠️ **TODO FOR COMPLETE PIPELINE AUTOMATION**

### **High Priority:**
1. [ ] Identify and document actual R scripts used
2. [ ] Remove hardcoded metadata (5,448 SNVs, 415 samples)
3. [ ] Generate HTML dynamically from data
4. [ ] Verify all 8 figures render correctly in new HTML

### **Medium Priority:**
5. [ ] Create master script to run entire Step 1
6. [ ] Add statistical summaries to each panel
7. [ ] Create data validation checks
8. [ ] Document dependencies (R packages)

### **Low Priority:**
9. [ ] Create alternative layouts (single multi-panel figure)
10. [ ] Add interactive elements to HTML
11. [ ] Generate PDF report version
12. [ ] Create panel comparison document

---

## 📊 **STEPS BEYOND STEP 1**

### **Step 2: Comparative Analysis (ALS vs Control)**
- Location: `pipeline_2/HTML_VIEWERS_FINALES/PASO_2_ANALISIS_COMPARATIVO.html`
- Status: TO BE REVIEWED AND ORGANIZED NEXT

### **Step 2.5: Advanced Seed Analysis**
- Location: `pipeline_2/HTML_VIEWERS_FINALES/PASO_2.5_ANALISIS_SEED_GT.html`
- Status: TO BE REVIEWED AND ORGANIZED NEXT

### **Step 3: Functional Analysis**
- Location: `pipeline_3/PASO_3_ANALISIS_FUNCIONAL.html`
- Status: TO BE REVIEWED AND ORGANIZED NEXT

---

## 🔐 **PRESERVATION GUARANTEE**

**All original files are PRESERVED:**
- Original figures in `pipeline_2/figures/` → NOT DELETED
- Original HTML viewers → NOT DELETED
- All versions of figures (PROFESSIONAL, COMPLETE, etc.) → PRESERVED
- Previous documentation → PRESERVED

**New structure adds organization WITHOUT deleting history.**

---

## 📅 **VERSION HISTORY**

| Date | Version | Changes |
|------|---------|---------|
| 2025-10-24 | 1.0 | Initial reorganization, 8 figures consolidated, HTML in English |
| 2025-10-24 | 1.0 | Documentation created (README, REGISTRY) |
| 2025-10-24 | 1.1 | **Panel E upgraded to multi-dimensional bubble plot** |
| 2025-10-24 | 1.1 | Extended X-axis to position 23, moved seed label to avoid overlap |
| 2025-10-24 | 1.1 | Panel E now shows: G-content (height), miRNA diversity (size), G>T burden (color) |
| (future) | 1.2 | Scripts documented and verified for all panels |
| (future) | 2.0 | Dynamic HTML generation implemented |

---

## 📧 **CONTACT & NOTES**

**Created by:** AI Assistant  
**Date:** 2025-10-24  
**Purpose:** Ensure NO information is lost during reorganization  
**Status:** Step 1 organized, ready to proceed to Steps 2, 2.5, 3

**Next Action:** Review new HTML (`PASO_1_REORGANIZED.html`) and verify all figures display correctly.

---

**END OF REGISTRY**

