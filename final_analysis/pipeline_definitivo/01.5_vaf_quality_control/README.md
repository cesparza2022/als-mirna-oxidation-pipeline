# 🔬 STEP 1.5: VAF QUALITY CONTROL

**Version:** 1.0.0  
**Date:** 2025-10-20  
**Status:** ✅ COMPLETED

---

## 🎯 PURPOSE

This step performs **quality control** by filtering technical artifacts where the Variant Allele Frequency (VAF) is >= 50%.

**Why is this important?**
- VAF >= 0.5 is biologically implausible for somatic mutations
- Likely represents sequencing errors, alignment artifacts, or contamination
- Removing these ensures all downstream analyses use high-confidence data only

**Key feature:**
- Maintains **ALL 12 mutation types** and **ALL 23 positions**
- Creates a universal VAF-filtered dataset usable for any analysis
- Not limited to G>T or seed region

---

## 📥 INPUT

**File:** `step1_original_data.csv`  
**Source:** Original sequencing data (177 MB)  
**Why this file?** It contains both SNV counts AND total counts needed to calculate VAF

**Structure:**
- Rows: 68,968 SNVs (miRNA + position + mutation)
- Columns: 832 (2 metadata + 415 SNV counts + 415 total counts)
- Samples: 415 (ALS: 313, Control: 102)

---

## 🔄 PROCESS

### **Step 1: Calculate VAF**
For each SNV in each sample:
```
VAF = count_SNV / count_total_miRNA
```

### **Step 2: Identify Artifacts**
Where `VAF >= 0.5`:
- Mark as suspicious (technical artifact)
- Log the event for reporting

### **Step 3: Filter Data**
In the counts matrix:
- Where `VAF >= 0.5` → set to `NaN`
- All other values → keep unchanged

### **Step 4: Save Results**
- VAF-filtered dataset (main output)
- Filter report (detailed log)
- Statistics by type and miRNA

---

## 📤 OUTPUT

### **Main Dataset:**
**File:** `data/ALL_MUTATIONS_VAF_FILTERED.csv`

**Characteristics:**
- **12 mutation types** ✅ (AT, AG, AC, GC, GT, GA, CG, CA, CT, TA, TG, TC)
- **23 positions** ✅ (1-23, full miRNA length)
- **415 samples** ✅ (ALS: 313, Control: 102)
- **NaN values**: Where VAF >= 0.5 (technical artifacts)
- **Other values**: Original counts (unchanged)
- **Format**: Identical to input (wide format)

### **Filter Report:**
**File:** `data/vaf_filter_report.csv`

**Contains:**
- Row number
- miRNA name
- Position and mutation
- Sample ID
- SNV count
- Total count
- Calculated VAF

**Total events logged:** 201,293

### **Statistics:**
1. `vaf_statistics_by_type.csv` - Impact per mutation type
2. `vaf_statistics_by_mirna.csv` - Impact per miRNA
3. Summary tables in `tables/` directory

---

## 📊 FIGURES

### **QC Figures (4):**
Show the impact and validation of VAF filtering

1. **QC_FIG1_VAF_DISTRIBUTION.png**
   - Distribution of VAF values that were filtered
   - All shown values had VAF >= 0.5
   - Validates filter threshold

2. **QC_FIG2_FILTER_IMPACT.png**
   - Number of filtered values per mutation type
   - Identifies types more prone to artifacts

3. **QC_FIG3_AFFECTED_MIRNAS.png**
   - Top 20 miRNAs with most filtered values
   - Quality assessment per miRNA

4. **QC_FIG4_BEFORE_AFTER.png**
   - Total valid values before/after filtering
   - Percentage of data retained

### **Diagnostic Figures (7):**
Same as Step 1, but with VAF-filtered data

1. **STEP1.5_FIG1_HEATMAP_SNVS.png** - SNVs by position (all types)
2. **STEP1.5_FIG2_HEATMAP_COUNTS.png** - Counts by position (log scale)
3. **STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png** - G>T vs G>A vs G>C (SNVs)
4. **STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png** - G>T vs G>A vs G>C (Counts)
5. **STEP1.5_FIG5_BUBBLE_PLOT.png** - SNVs vs Counts (SD)
6. **STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png** - Complete distributions
7. **STEP1.5_FIG7_FOLD_CHANGE.png** - Fold Change vs G>T

**Purpose of diagnostic figures:**
- Direct comparison with Step 1
- Validate that mutation patterns are robust after QC
- Show impact of artifact removal on overall statistics

---

## 🚀 QUICK START

### **View Results:**
```bash
open STEP1.5_VAF_QC_VIEWER.html
```

### **Reproduce Analysis:**
```bash
# 1. Apply VAF filter
cd 01.5_vaf_quality_control
Rscript scripts/01_apply_vaf_filter.R

# 2. Generate figures
Rscript scripts/02_generate_diagnostic_figures.R

# 3. Open HTML viewer
open STEP1.5_VAF_QC_VIEWER.html
```

**Estimated runtime:** ~10-15 minutes total

---

## 🔥 KEY FINDINGS

### **Filter Statistics:**
- **201,293 values filtered** (VAF >= 0.5)
- **Impact varies by mutation type** (see QC_FIG2)
- **Some miRNAs more affected** (see QC_FIG3)
- **Overall patterns remain robust** (see diagnostic figures)

### **Data Quality:**
- High-confidence dataset created
- All technical artifacts removed
- 12 mutation types preserved
- 23 positions preserved
- Ready for downstream analysis

---

## 💡 ADVANTAGES OF THIS STEP

### **1. Universal Dataset:**
Not limited to G>T or seed region - can be used for:
- Any mutation type analysis
- Any position/region analysis
- Comparative studies
- Quality-controlled baseline

### **2. Transparent QC:**
- Detailed log of what was filtered
- Statistics by type and miRNA
- Visual validation through figures
- Reproducible process

### **3. Modular Design:**
- Independent QC step
- Doesn't modify original data
- Easy to adjust threshold if needed
- Clear documentation

### **4. Comparison Enabled:**
- Same figures as Step 1
- Direct before/after comparison
- Validates pattern robustness
- Identifies filter impact

---

## 📖 DOCUMENTATION

### **Execution Logs:**
- `vaf_filter_execution.log` - Filter process log
- `figure_generation.log` - Figure generation log

### **Related Documents:**
- `../REGISTRO_PASO_1_Y_1.5_COMPLETO.md` - Complete registry
- `../01_analisis_inicial/README.md` - Step 1 documentation

### **HTML Viewers:**
- `STEP1.5_VAF_QC_VIEWER.html` - This step
- `../01_analisis_inicial/STEP1_DIAGNOSTIC_FIGURES_VIEWER.html` - Step 1

---

## 🔗 INTEGRATION WITH PIPELINE

### **Upstream (Step 1):**
- Receives original data
- Applies split-collapse
- Generates baseline figures

### **This Step (Step 1.5):**
- Applies VAF quality control
- Maintains complete dataset
- Creates clean baseline

### **Downstream (Step 2+):**
- Can filter for specific analyses (G>T seed, etc.)
- Uses clean, high-confidence data
- Builds on solid foundation

---

## ⚙️ TECHNICAL DETAILS

### **VAF Calculation:**
```r
VAF = count_SNV / count_total_miRNA
```

### **Filter Criterion:**
```r
if (VAF >= 0.5) {
  count_SNV <- NaN  # Mark as artifact
}
```

### **Threshold Rationale:**
- VAF 0.5 = 50% of reads show the mutation
- For somatic mutations, typical VAF < 0.1 (10%)
- VAF >= 0.5 suggests technical issue, not biology

---

**Last updated:** 2025-10-20  
**Status:** ✅ COMPLETE AND VALIDATED  
**Next:** Review HTML viewer and integrate with Step 2

