# 🔄 PIPELINE_2 REDESIGN - GENERIC & CONFIGURABLE

## 🎯 **NEW OBJECTIVE CLARIFIED**

Create a **GENERIC pipeline** for analyzing G>T mutations in miRNA datasets that:
1. Works with ANY ALS + Control dataset
2. Does NOT hardcode specific metadata paths
3. Accepts **configuration parameters** instead of fixed values
4. Follows the approach from the reference paper

---

## 📊 **CURRENT STATUS vs TARGET**

### **❌ WHAT WE DID WRONG:**
- Assumed specific sample metadata files
- Hardcoded ALS vs Control comparisons
- Made pipeline too specific to one dataset

### **✅ WHAT WE SHOULD DO:**
- Create **Figure 1** as dataset-agnostic characterization (DONE ✅)
- Design **configurable functions** that accept group labels as parameters
- Provide **template configuration** for users to customize
- Follow **standard bioinformatics pipeline structure**

---

## 🔬 **PIPELINE STRUCTURE (GENERIC APPROACH)**

### **STEP 1: DATASET CHARACTERIZATION (GENERIC)** ✅
**Input:** Raw miRNA mutation data (any source)  
**Output:** Figure 1 - Dataset overview & G>T landscape  
**Status:** COMPLETE

**Analyses (no metadata required):**
- Data quality metrics
- Overall mutation type distribution
- G>T positional patterns
- Seed region analysis

**Questions answered:**
- SQ1.1: Dataset structure & quality
- SQ1.2: G>T positional distribution
- SQ1.3: Prevalent mutation types

---

### **STEP 2: GROUP COMPARISON (CONFIGURABLE)** 📋
**Input:** 
- Processed data from Step 1
- **User-provided:** Sample grouping file (format specified, not hardcoded)

**Output:** Figure 2 - ALS vs Control comparison  
**Status:** READY TO DESIGN

**Required user configuration:**
```r
# User provides this file according to template
sample_groups <- read.csv("user_provided_groups.csv")
# Expected columns: sample_id, group (ALS/Control)
```

**Analyses:**
- G>T enrichment test (group-agnostic)
- Positional differences between groups
- miRNA-specific enrichment
- Effect size calculations

**Questions to answer:**
- SQ2.1: Is G>T enriched in group A vs group B?
- SQ2.2: Positional differences between groups
- SQ2.3: Which miRNAs differ between groups?
- SQ2.4: Seed region vulnerability by group

---

### **STEP 3: CONFOUNDER ANALYSIS (CONFIGURABLE)** 📋
**Input:** 
- Data from Step 2
- **User-provided:** Demographic file (optional, template provided)

**Output:** Figure 3 - Confounder analysis  
**Status:** PLANNED

**Required user configuration (OPTIONAL):**
```r
# User provides if available
demographics <- read.csv("user_provided_demographics.csv")
# Expected columns: sample_id, age, sex, batch, etc.
```

**Analyses:**
- Age adjustment (if age provided)
- Sex stratification (if sex provided)
- Batch effect detection (if batch provided)
- Adjusted group comparisons

**Questions to answer:**
- SQ4.1: Age effect?
- SQ4.2: Sex effect?
- SQ4.3: Technical confounders?

---

### **STEP 4: MECHANISTIC VALIDATION (GENERIC)** 📋
**Input:** Data from Step 2  
**Output:** Figure 4 - Oxidative stress signature  
**Status:** PLANNED

**No metadata required** - pure mutation pattern analysis

**Analyses:**
- 8-oxoG signature validation
- Comprehensive G>X analysis
- Sequence context (if reference provided)
- Literature comparison

**Questions to answer:**
- SQ3.1: Does G>T pattern match 8-oxoG signature?
- SQ3.2: Are other G>X mutations informative?

---

### **STEP 5: FUNCTIONAL ANALYSIS (OPTIONAL)** 📋
**Input:** 
- Significant miRNAs from Step 2
- **User-provided:** Target databases (optional)

**Output:** Figure 5 - Functional impact  
**Status:** FUTURE

**Analyses:**
- Target prediction (configurable database)
- Pathway enrichment
- miRNA family analysis

---

## 🏗️ **REVISED PIPELINE ARCHITECTURE**

### **CORE PRINCIPLE:** Configuration over Hardcoding

```
pipeline_2/
├── config/
│   ├── pipeline_config_template.R    # TEMPLATE for users to copy & customize
│   ├── pipeline_config.R              # User's actual config (gitignored)
│   └── parameters.R                   # Scientific parameters (fixed)
│
├── functions/
│   ├── data_processing.R              # Generic data processing
│   ├── statistical_tests.R            # Group-agnostic tests
│   ├── visualization_core.R           # Core viz functions
│   └── metadata_integration.R         # OPTIONAL metadata handling
│
├── steps/
│   ├── step1_characterization.R       # NO metadata (DONE ✅)
│   ├── step2_comparison.R             # Accepts grouping file
│   ├── step3_confounders.R            # Accepts demographics file (optional)
│   ├── step4_validation.R             # NO metadata
│   └── step5_functional.R             # Optional advanced analysis
│
├── templates/
│   ├── sample_groups_template.csv     # How to format group labels
│   ├── demographics_template.csv      # How to format demographics
│   └── config_examples.R              # Example configurations
│
├── run_pipeline.R                     # Master script with steps
└── README.md                          # How to configure & run
```

---

## 📝 **USER WORKFLOW (GENERIC)**

### **For ANY dataset:**

1. **Copy template config:**
   ```r
   cp config/pipeline_config_template.R config/pipeline_config.R
   ```

2. **Edit config with YOUR paths:**
   ```r
   # In pipeline_config.R
   data_path <- "path/to/YOUR/miRNA_count.txt"
   output_dir <- "path/to/YOUR/results/"
   ```

3. **Run Step 1 (no metadata):**
   ```r
   source("steps/step1_characterization.R")
   # Generates Figure 1
   ```

4. **If you have group labels, create grouping file:**
   ```csv
   sample_id,group
   sample_1,ALS
   sample_2,Control
   ...
   ```

5. **Configure Step 2:**
   ```r
   # In pipeline_config.R
   grouping_file <- "path/to/your/groups.csv"
   ```

6. **Run Step 2:**
   ```r
   source("steps/step2_comparison.R")
   # Generates Figure 2
   ```

7. **Optional: Add demographics for Step 3**
8. **Run remaining steps as needed**

---

## 🎯 **WHAT THIS ACHIEVES**

### **✅ Advantages:**
1. **Generic:** Works with any miRNA mutation dataset
2. **Configurable:** Users provide their own paths and parameters
3. **Modular:** Can run Step 1 without metadata
4. **Scalable:** Easy to add new analyses
5. **Reproducible:** Templates ensure correct format
6. **Standard:** Follows bioinformatics best practices

### **📋 What we need to implement:**

1. **Refactor current code:**
   - Move Figure 1 code to `step1_characterization.R`
   - Create configuration template
   - Add sample grouping template
   - Update documentation

2. **Create Step 2 framework:**
   - Generic group comparison functions
   - Accept grouping file as parameter
   - Statistical tests (group-agnostic)

3. **Design remaining steps:**
   - Step 3: Optional confounder analysis
   - Step 4: Mechanistic validation (no metadata)
   - Step 5: Functional analysis (optional)

---

## 📖 **INSPIRATION FROM PAPER**

Let me review what analyses the reference paper performs in their initial steps to ensure our Figure 1 aligns with their approach, and then design the subsequent steps accordingly.

**Key questions to answer from paper:**
1. What figures do they show BEFORE group comparisons?
2. How do they structure their comparative analysis?
3. What statistical framework do they use?
4. How do they visualize G>T patterns?

---

## 🚀 **NEXT ACTIONS**

1. **Review reference paper** for figure structure
2. **Refactor current Figure 1** into `step1_characterization.R`
3. **Create configuration template**
4. **Design Step 2** (generic group comparison)
5. **Update all documentation** to reflect generic approach

---

**🎯 GOAL: Create a pipeline that researchers can use with THEIR OWN data, not just one specific dataset**

