# 📋 TEMPLATES GUIDE - PIPELINE_2

## 🎯 **PURPOSE**

These templates allow you to use Pipeline_2 with **your own dataset and metadata**. The pipeline is designed to be generic and configurable.

---

## 🏗️ **PIPELINE STRUCTURE**

### **TIER 1: Standalone Analysis (No Metadata Required)** ✅
These steps work with ANY miRNA mutation dataset:

- **Step 1 → Figure 1:** Dataset Characterization
- **Step 2 → Figure 2:** Mechanistic Validation

**You can run these immediately without any metadata!**

---

### **TIER 2: Comparative Analysis (Metadata Required)** 🔧
These steps require sample grouping information:

- **Step 3 → Figure 3:** Group Comparison (e.g., ALS vs Control)
- **Step 4 → Figure 4:** Confounder Analysis (optional)

**Follow templates below to provide your metadata.**

---

## 📝 **TEMPLATE 1: Sample Groups** (Required for Figure 3)

### **File:** `sample_groups_template.csv`

**Purpose:** Define which samples belong to which group (e.g., ALS vs Control, Treatment vs Placebo, etc.)

**Format:**
```csv
sample_id,group
sample_001,GroupA
sample_002,GroupB
sample_003,GroupA
sample_004,GroupB
```

**Requirements:**
- **Column 1:** `sample_id` - Must match your data file's sample column names
- **Column 2:** `group` - Your group labels (e.g., ALS, Control, Treatment, Placebo)
- **Groups:** Currently supports 2-group comparisons
- **All samples:** Include all samples from your dataset

**How to use:**
1. Copy `sample_groups_template.csv` to `my_groups.csv`
2. Edit with YOUR sample IDs and groups
3. Update `config/pipeline_config.R`:
   ```r
   grouping_file <- "my_groups.csv"
   ```
4. Run Step 3: `Rscript steps/step3_group_comparison.R`

**Example (ALS study):**
```csv
sample_id,group
SRR12345,ALS
SRR12346,Control
SRR12347,ALS
SRR12348,Control
```

---

## 📝 **TEMPLATE 2: Demographics** (Optional for Figure 4)

### **File:** `demographics_template.csv`

**Purpose:** Provide demographic/clinical data for confounder analysis

**Format:**
```csv
sample_id,age,sex,batch
sample_001,65,M,batch1
sample_002,58,F,batch1
sample_003,72,M,batch2
sample_004,61,F,batch2
```

**Requirements:**
- **Column 1:** `sample_id` - Must match sample_groups.csv
- **Column 2+:** Demographic variables
  - `age` - Numeric (years)
  - `sex` - Character (M/F or Male/Female)
  - `batch` - Character (batch identifier)
  - Add any other covariates you want to adjust for

**How to use:**
1. Copy `demographics_template.csv` to `my_demographics.csv`
2. Edit with YOUR demographic data
3. Update `config/pipeline_config.R`:
   ```r
   demographics_file <- "my_demographics.csv"
   covariates_to_adjust <- c("age", "sex", "batch")
   ```
4. Run Step 4: `Rscript steps/step4_confounder_analysis.R`

**Note:** This is OPTIONAL. If you don't have demographic data, skip Step 4.

---

## ⚙️ **CONFIGURATION FILE**

### **File:** `config/pipeline_config_template.R`

**Purpose:** Central configuration for all pipeline parameters

**Copy and customize:**
```r
# Copy template
cp config/pipeline_config_template.R config/pipeline_config.R

# Edit config/pipeline_config.R with YOUR paths:
```

**Key settings:**
```r
# === DATA PATHS ===
raw_data_path <- "path/to/YOUR/miRNA_count.txt"
output_dir <- "path/to/YOUR/results/"

# === METADATA (Optional) ===
grouping_file <- "my_groups.csv"              # For Step 3
demographics_file <- "my_demographics.csv"    # For Step 4 (optional)

# === ANALYSIS PARAMETERS ===
mutation_type_focus <- "GT"  # G>T for oxidative stress
seed_region <- c(2, 8)       # Positions 2-8
alpha_threshold <- 0.05      # Significance level
fdr_method <- "BH"           # Benjamini-Hochberg

# === GROUP COMPARISON (if using Step 3) ===
group_column <- "group"      # Column name in grouping file
group_labels <- c("GroupA", "GroupB")  # Your actual group names
reference_group <- "GroupB"  # Reference for comparison

# === COVARIATES (if using Step 4) ===
covariates_to_adjust <- c("age", "sex")  # Which variables to adjust for
```

---

## 🚀 **QUICK START GUIDE**

### **Scenario 1: No Metadata (Just characterize your dataset)**

```bash
# 1. Place your data file
# 2. Edit config/pipeline_config.R with your data path
# 3. Run Steps 1-2

cd pipeline_2
Rscript steps/step1_characterization.R
Rscript steps/step2_mechanistic_validation.R

# Done! You now have Figures 1 & 2
```

---

### **Scenario 2: With Group Labels (Compare 2 groups)**

```bash
# 1-3. Same as Scenario 1

# 4. Create your grouping file
cp templates/sample_groups_template.csv my_groups.csv
# Edit my_groups.csv with your sample IDs and groups

# 5. Update config
# Edit config/pipeline_config.R:
# grouping_file <- "my_groups.csv"
# group_labels <- c("ALS", "Control")

# 6. Run Step 3
Rscript steps/step3_group_comparison.R

# Done! You now have Figures 1, 2, & 3
```

---

### **Scenario 3: With Demographics (Full analysis)**

```bash
# 1-6. Same as Scenario 2

# 7. Create demographics file
cp templates/demographics_template.csv my_demographics.csv
# Edit my_demographics.csv

# 8. Update config
# Edit config/pipeline_config.R:
# demographics_file <- "my_demographics.csv"
# covariates_to_adjust <- c("age", "sex")

# 9. Run Step 4
Rscript steps/step4_confounder_analysis.R

# Done! You have Figures 1, 2, 3, & 4
```

---

## ❓ **FAQ**

### **Q: What if my sample IDs have a different format?**
**A:** No problem! The templates just show the structure. Use YOUR actual sample IDs - they can be any format (SRR numbers, patient IDs, etc.)

### **Q: Can I use more than 2 groups?**
**A:** Currently, the pipeline is optimized for 2-group comparisons (most common). Multi-group support can be added in future versions.

### **Q: What if I don't have age/sex data?**
**A:** Skip Step 4 entirely. Steps 1-3 provide comprehensive analysis without demographics.

### **Q: Can I add custom covariates?**
**A:** Yes! Add any columns to demographics_template.csv and specify them in `covariates_to_adjust` in the config.

### **Q: Do I need to modify the R scripts?**
**A:** No! Just edit the CSV templates and config file. The scripts are generic and read from your config.

---

## 📊 **EXPECTED OUTPUTS**

### **With No Metadata:**
- Figure 1: Dataset characterization (4 panels)
- Figure 2: Mechanistic validation (4 panels)
- HTML viewers for both figures
- **Total:** 2 publication-ready figures

### **With Group Labels:**
- Figures 1 & 2 (same as above)
- Figure 3: Group comparison (4 panels)
- Statistical test results (CSV tables)
- **Total:** 3 publication-ready figures + statistics

### **With Demographics:**
- Figures 1, 2, & 3 (same as above)
- Figure 4: Confounder analysis (3-4 panels)
- Adjusted statistics
- **Total:** 4 publication-ready figures + comprehensive statistics

---

## 🛠️ **TROUBLESHOOTING**

### **Error: "Cannot find grouping file"**
- Check that `my_groups.csv` exists in pipeline_2 directory
- Verify path in `config/pipeline_config.R`

### **Error: "Sample IDs don't match"**
- Ensure sample_ids in grouping file match your data file exactly
- Check for typos, spaces, or case differences

### **Error: "Group column not found"**
- Ensure your grouping file has a column named `group`
- Or update `group_column` in config to match your column name

---

## 📖 **ADDITIONAL RESOURCES**

- **MASTER_INTEGRATION_PLAN.md** - Complete pipeline overview
- **SCIENTIFIC_QUESTIONS_ANALYSIS.md** - What questions each figure answers
- **IMPLEMENTATION_PLAN.md** - Technical implementation details
- **README.md** - Project overview

---

**🎉 The pipeline is designed to be flexible - use as much or as little metadata as you have!**

**Last Updated:** 2025-01-16

