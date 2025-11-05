# 🏗️ GENERIC PIPELINE DESIGN - PIPELINE_2

## 🎯 **REVISED OBJECTIVE**

Create a **modular, generic pipeline** for G>T mutation analysis in miRNA datasets that:
1. **Works standalone** without metadata (Step 1)
2. **Accepts optional metadata** via configuration (Steps 2-3)
3. **Follows reference paper structure**
4. **Can be applied to ANY dataset**

---

## 📊 **PIPELINE STEPS (MODULAR DESIGN)**

### **STEP 1: DATASET CHARACTERIZATION** ✅ COMPLETE
**Status:** DONE - Works with ANY dataset  
**Metadata required:** NONE  
**Input:** Raw miRNA mutation file  
**Output:** Figure 1 - Dataset overview & G>T landscape

**Current implementation:**
- ✅ `visualization_functions_v4.R`
- ✅ `test_figure_1_v4.R`
- ✅ `figure_1_viewer_v4.html`

**Analyses performed:**
1. Dataset evolution (Raw entries → Individual SNVs)
2. Overall mutation type distribution
3. G>T positional frequency
4. Seed vs non-seed G>T comparison
5. Mutation spectrum analysis

**Questions answered:**
- How many mutations do we have?
- What types of mutations are present?
- Where are G>T mutations located?
- Are G>T mutations enriched in seed region?

**This step is GENERIC** - runs on any miRNA mutation file with `pos:mut` column ✅

---

### **STEP 2: GROUP COMPARISON (CONFIGURABLE)** 📋 NEXT
**Status:** TO DESIGN  
**Metadata required:** YES (sample groups)  
**Input:** 
- Processed data from Step 1
- **Config file:** `sample_groups.csv` (user-provided)

**Proposed implementation:**
```r
# step2_group_comparison.R

# Load configuration (user specifies)
source("config/pipeline_config.R")

# Load sample groups (user-provided file)
sample_groups <- read.csv(config$grouping_file)
# Expected format:
# sample_id, group
# SRR123, ALS
# SRR124, Control
# ...

# Run generic comparison
results <- compare_groups(
  data = processed_data,
  groups = sample_groups,
  mutation_type = "GT",  # Configurable
  tests = c("fisher", "wilcox")  # Configurable
)
```

**Analyses to perform:**
1. G>T frequency: Group A vs Group B
2. Positional differences between groups
3. Per-miRNA enrichment analysis
4. Effect sizes (Odds Ratio, Cohen's d)

**Questions to answer:**
- Is G>T enriched in one group?
- Which positions show group differences?
- Which miRNAs are group-specific?
- What is the effect magnitude?

**This step is GENERIC** - works with any 2-group comparison ✅

---

### **STEP 3: COVARIATE ADJUSTMENT (OPTIONAL)** 📋 FUTURE
**Status:** TO DESIGN  
**Metadata required:** YES (demographics - optional)  
**Input:**
- Results from Step 2
- **Config file:** `demographics.csv` (user-provided, optional)

**Proposed implementation:**
```r
# step3_confounder_analysis.R

# Load demographics (OPTIONAL)
if (file.exists(config$demographics_file)) {
  demographics <- read.csv(config$demographics_file)
  # Expected format:
  # sample_id, age, sex, batch
  # SRR123, 65, M, batch1
  
  # Run adjusted analysis
  adjusted_results <- adjust_for_covariates(
    data = step2_results,
    covariates = demographics,
    adjust_for = c("age", "sex")  # User-specified
  )
}
```

**Analyses to perform (if data available):**
1. Age-adjusted group comparison
2. Sex-stratified analysis
3. Batch effect detection
4. Multivariate models

**This step is OPTIONAL** - only runs if user provides data ✅

---

### **STEP 4: MECHANISTIC VALIDATION (GENERIC)** 📋 FUTURE
**Status:** TO DESIGN  
**Metadata required:** NONE  
**Input:** Data from Step 1 (no groups needed)

**Analyses:**
1. 8-oxoG signature validation (pure sequence analysis)
2. G-content correlation with G>T
3. Sequence motif analysis
4. Literature comparison

**This step is GENERIC** - no metadata required ✅

---

## 📋 **WHAT WE NEED FROM REFERENCE PAPER**

To properly design Steps 2-4, we need to understand:

### **1. Initial Characterization (like our Step 1):**
- ✓ What do they show BEFORE comparing groups?
- ✓ What summary statistics do they compute?
- ✓ How do they visualize mutation patterns?

### **2. Group Comparison (Step 2):**
- ✓ What statistical tests do they use?
- ✓ How do they visualize differences?
- ✓ What effect sizes do they report?
- ✓ Multiple testing correction approach?

### **3. Figure Structure:**
- ✓ How many panels per figure?
- ✓ What information density?
- ✓ Color schemes and layouts?

---

## 🎯 **IMMEDIATE NEXT STEPS**

1. **Review reference paper** to understand their approach
2. **Design generic comparison framework** for Step 2
3. **Create configuration templates:**
   - `sample_groups_template.csv`
   - `demographics_template.csv`
   - `pipeline_config_template.R`

4. **Refactor current code:**
   - Move Figure 1 to `steps/step1_characterization.R`
   - Make it fully generic (no hardcoded paths)
   - Document input/output expectations

5. **Design Step 2 functions:**
   - Generic group comparison
   - Statistical testing framework
   - Visualization templates

---

## 📖 **QUESTIONS FOR USER**

To proceed effectively, I need to know:

1. **Which paper should I review for inspiration?**
   - Wheeler et al (oxidative RNA damage)?
   - Another specific paper you have?
   - Can you share the file name or key points?

2. **For the generic pipeline:**
   - Should Step 1 remain as-is (works without metadata)? ✅
   - Should we create configuration templates for users?
   - What should be the default behavior if no metadata provided?

3. **Priority:**
   - Focus on making Step 1 perfect first?
   - Or design the full framework (Steps 1-4) now?

---

**🎯 READY TO:**
- Review reference paper once you specify which one
- Design generic Step 2 framework
- Create configuration templates
- Refactor code for modularity

**📝 NOTE:** Everything we've done for Figure 1 is already generic and will work with any dataset - that's the right foundation!

