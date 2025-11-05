# 🎯 MASTER INTEGRATION PLAN - PIPELINE_2

## 📊 **ESTRUCTURA COMPLETA DEL PIPELINE**

### **FILOSOFÍA DE DISEÑO:**
1. **Figuras 1-2:** Análisis genérico (SIN metadata) - Completas y publicables
2. **Figuras 3+:** Framework configurable (CON metadata) - Templates para usuarios

---

## 🔬 **SCIENTIFIC NARRATIVE (INTEGRATED)**

### **PART 1: FOUNDATION** (No metadata - Works for ANY dataset)

#### **FIGURE 1: DATASET CHARACTERIZATION** ✅ COMPLETE
**Scientific Story:** "What do we have and where are the G>T mutations?"

**Panels:**
- **A.** Dataset Evolution & Mutation Types
  - Answers: SQ1.1, SQ1.3
  - Shows: 68,968 raw entries → 110,199 SNVs
  - Shows: Mutation type distribution (T>C 17.8%, G>T 7.3%)

- **B.** G>T Positional Landscape
  - Answers: SQ1.2
  - Shows: Positional frequency heatmap
  - Shows: Seed vs non-seed comparison

- **C.** Mutation Spectrum by Position
  - Answers: SQ1.3 (detailed)
  - Shows: G>X types per position (stacked bars)
  - Shows: Top 10 overall mutations

- **D.** (Placeholder - reserved)

**Status:** ✅ COMPLETE  
**Files:** 
- `functions/visualization_functions_v4.R`
- `test_figure_1_v4.R`
- `figures/figure_1_corrected.png`
- `figure_1_viewer_v4.html`

---

#### **FIGURE 2: MECHANISTIC VALIDATION** 📋 NEXT (Still no metadata!)
**Scientific Story:** "WHY are G>T mutations oxidative signatures?"

**Panels:**
- **A.** G-Content Determines Susceptibility ⭐⭐⭐⭐⭐
  - Answers: SQ3.1 (partial)
  - Shows: More G's in seed → More G>T mutations
  - Data: **ALREADY HAVE** from previous analysis!
  - Method: Correlation analysis (Spearman)
  - Evidence: Dose-response relationship

- **B.** Sequence Context Enrichment ⭐⭐⭐⭐
  - Answers: SQ3.1 (validation)
  - Shows: Nucleotides flanking G>T sites
  - Expected: GG, GC enrichment (8-oxoG preference)
  - Method: ±1 position analysis
  - Evidence: Matches known oxidative signature

- **C.** G>T Specificity Analysis ⭐⭐⭐⭐
  - Answers: SQ3.2 (partial)
  - Shows: G>T vs G>A vs G>C proportions
  - Method: Fraction G>T / all G>X
  - Evidence: G>T is THE dominant G>X type

- **D.** Position-Level G-Content Correlation ⭐⭐⭐
  - Answers: SQ1.2 + SQ3.1 (integration)
  - Shows: Per-position G-richness vs G>T frequency
  - Method: Position-by-position correlation
  - Evidence: Extends seed finding to all positions

**Status:** 📋 READY TO IMPLEMENT  
**Timeline:** Can complete TODAY  
**No metadata needed:** ✅ Generic for any dataset

---

### **PART 2: COMPARATIVE ANALYSIS** (Requires metadata - Template approach)

#### **FIGURE 3: GROUP COMPARISON** 🔧 TEMPLATE
**Scientific Story:** "ARE there differences between groups?"

**Requires user to provide:** `sample_groups.csv`
```csv
sample_id,group
SRR123,ALS
SRR124,Control
...
```

**Panels (TEMPLATE FUNCTIONS):**
- **A.** Global G>T Burden Comparison
  - Function: `compare_gt_burden(data, groups_file)`
  - Test: Wilcoxon rank-sum
  - Output: Violin plot + statistics

- **B.** Position Delta Curve (YOUR FAVORITE!) 
  - Function: `create_position_delta_curve(data, groups_file)`
  - Test: Per-position Wilcoxon + FDR
  - Output: Delta plot with seed shaded + stars
  - **This is the figure from PRD Q10!**

- **C.** Seed vs Non-Seed by Group
  - Function: `compare_seed_enrichment(data, groups_file)`
  - Test: Fisher's exact (2×2 table)
  - Output: OR with CI + interaction plot

- **D.** Top Differential miRNAs
  - Function: `identify_differential_mirnas(data, groups_file)`
  - Test: Per-miRNA Fisher + FDR
  - Output: Volcano plot + table

**Status:** 🔧 TO DESIGN AS TEMPLATES  
**Timeline:** After Figure 2  
**How to use:** Users follow template guide

---

#### **FIGURE 4: CONFOUNDER ANALYSIS** 🔧 OPTIONAL TEMPLATE
**Scientific Story:** "Are differences robust to confounders?"

**Requires user to provide (OPTIONAL):** `demographics.csv`
```csv
sample_id,age,sex,batch
SRR123,65,M,batch1
...
```

**Panels (OPTIONAL - only if demographics provided):**
- **A.** Age Distribution & Adjustment
- **B.** Sex Stratification
- **C.** Batch Effect Assessment
- **D.** Adjusted Effect Sizes

**Status:** 💡 FUTURE TEMPLATE  
**How to use:** Optional module, activates if demographics file exists

---

#### **FIGURE 5: FUNCTIONAL ANALYSIS** 💡 FUTURE
**Scientific Story:** "What are the functional consequences?"

**Requires:** Target prediction databases (optional)

**Panels:** Target changes, pathway enrichment, etc.

**Status:** 💡 EXPLORATORY (lowest priority)

---

## 🏗️ **INTEGRATED PIPELINE ARCHITECTURE**

```
pipeline_2/
│
├── 📊 TIER 1: STANDALONE ANALYSIS (No metadata)
│   │
│   ├── step1_characterization.R        ✅ DONE
│   │   └── Generates: Figure 1
│   │
│   └── step2_mechanistic_validation.R  📋 NEXT (TODAY!)
│       └── Generates: Figure 2
│       └── Uses: G-content data (already have)
│       └── New: Sequence context analysis
│
├── 🔧 TIER 2: CONFIGURABLE ANALYSIS (With metadata)
│   │
│   ├── step3_group_comparison.R        🔧 TEMPLATE
│   │   └── Generates: Figure 3
│   │   └── Requires: sample_groups.csv (user provides)
│   │   └── Template: sample_groups_template.csv
│   │
│   └── step4_confounders.R             💡 OPTIONAL
│       └── Generates: Figure 4
│       └── Requires: demographics.csv (optional)
│       └── Template: demographics_template.csv
│
├── config/
│   ├── config_pipeline_2.R             # Current (paths, params)
│   ├── parameters.R                    # Scientific questions
│   └── pipeline_config_template.R      # For users to customize
│
├── functions/
│   ├── visualization_functions_v4.R    ✅ Figure 1 functions
│   ├── mechanistic_functions.R         📋 Figure 2 functions (NEW)
│   ├── comparison_functions.R          🔧 Figure 3 templates (NEW)
│   └── statistical_tests.R             🔧 Generic tests (NEW)
│
├── data/  (NEW)
│   ├── g_content_analysis.csv          📋 Port from previous
│   └── mirna_sequences.fasta           📋 From miRBase (optional)
│
├── templates/  (NEW)
│   ├── sample_groups_template.csv      🔧 How to format groups
│   ├── demographics_template.csv       🔧 How to format demographics
│   └── README_TEMPLATES.md             🔧 Usage guide
│
└── figures/
    ├── figure_1_corrected.png          ✅ Done
    ├── figure_2_mechanistic.png        📋 Next
    └── figure_3_comparison.png         🔧 Template (when user has data)
```

---

## 📋 **DETAILED INTEGRATION**

### **STEP 1 → FIGURE 1** ✅ COMPLETE
```r
# Input: Raw miRNA mutation file
# Config: Just file paths (generic)
# Output: Figure 1 (4 panels)
# Metadata: NONE needed
```

**Scientific Questions Answered:**
- ✅ SQ1.1: Dataset quality
- ✅ SQ1.2: G>T distribution  
- ✅ SQ1.3: Mutation types

---

### **STEP 2 → FIGURE 2** 📋 IMPLEMENT NOW
```r
# Input: 
#   - Processed data from Step 1
#   - G-content data (from previous analysis)
#   - miRNA sequences (from miRBase - public)
# 
# Config: Just file paths (generic)
# Output: Figure 2 (4 panels)
# Metadata: NONE needed
```

**New Scientific Questions to Answer:**
- 📋 **SQ3.1:** Does G-content correlate with G>T? (mechanistic)
- 📋 **SQ3.2:** Is G>T specifically enriched vs G>A, G>C? (specificity)
- 📋 **SQ3.3:** What sequence contexts favor G>T? (validation)

**Implementation Plan:**

1. **Port G-content analysis:**
   ```r
   # Source: paso9c_oxidacion_por_contenido_g.csv
   # Copy to: pipeline_2/data/g_content_analysis.csv
   # Adapt: fig04_g_content_oxidation.R → mechanistic_functions.R
   ```

2. **Add sequence context:**
   ```r
   # New function: analyze_sequence_context()
   # Extract ±1 nt around each G>T
   # Calculate enrichment vs background
   # Visualize: bar chart or sequence logo
   ```

3. **Enhance G>T specificity:**
   ```r
   # New function: calculate_gt_specificity()
   # G>T / (G>T + G>A + G>C) per position
   # Shows if G>T is uniquely enriched
   ```

4. **Create Figure 2:**
   ```r
   # New function: create_figure_2_mechanistic()
   # Combine 4 panels
   # Save: figure_2_mechanistic_validation.png
   ```

---

### **STEP 3 → FIGURE 3 (TEMPLATE)** 🔧 PREPARE FOR FUTURE
```r
# Input:
#   - Results from Step 1 & 2
#   - sample_groups.csv (USER PROVIDES)
#
# Config: Path to user's grouping file
# Output: Figure 3 (4 panels)
# Metadata: YES - but user-provided via template
```

**Framework Design:**
```r
# Generic comparison function
compare_groups <- function(data, groups_file, 
                          group_col = "group",
                          mutation_type = "GT") {
  
  # Read user's grouping file
  groups <- read.csv(groups_file)
  
  # Validate format
  required_cols <- c("sample_id", group_col)
  if (!all(required_cols %in% names(groups))) {
    stop("Grouping file must have: ", paste(required_cols, collapse = ", "))
  }
  
  # Get unique groups
  unique_groups <- unique(groups[[group_col]])
  if (length(unique_groups) != 2) {
    stop("Currently supports 2-group comparison only")
  }
  
  # Run comparison
  results <- perform_comparison(data, groups, mutation_type)
  
  return(results)
}
```

**Templates to Create:**
```
templates/
├── sample_groups_template.csv
│   # Minimal example:
│   # sample_id,group
│   # sample_001,GroupA
│   # sample_002,GroupB
│
├── demographics_template.csv (optional)
│   # sample_id,age,sex,batch
│   # sample_001,65,M,batch1
│
└── README_TEMPLATES.md
    # How to use the pipeline with your metadata
    # Step-by-step guide
    # Examples
```

---

## 🔄 **WORKFLOW INTEGRATION**

### **FOR RESEARCHERS WITHOUT METADATA:**
```bash
# Run Step 1 (Dataset Characterization)
Rscript steps/step1_characterization.R
# → Generates Figure 1 ✅

# Run Step 2 (Mechanistic Validation)
Rscript steps/step2_mechanistic_validation.R  
# → Generates Figure 2 ✅

# DONE! 2 publication-ready figures without any metadata
```

### **FOR RESEARCHERS WITH METADATA:**
```bash
# Run Steps 1-2 (same as above)
Rscript steps/step1_characterization.R
Rscript steps/step2_mechanistic_validation.R

# Prepare your grouping file (follow template)
cp templates/sample_groups_template.csv my_groups.csv
# Edit my_groups.csv with YOUR sample IDs and groups

# Configure pipeline
# Edit config/pipeline_config.R:
# grouping_file <- "my_groups.csv"

# Run Step 3 (Group Comparison)
Rscript steps/step3_group_comparison.R
# → Generates Figure 3 ✅

# Optional: If you have demographics
cp templates/demographics_template.csv my_demographics.csv
# Edit my_demographics.csv

# Run Step 4 (Confounder Analysis)
Rscript steps/step4_confounder_analysis.R
# → Generates Figure 4 ✅
```

---

## 📊 **FIGURE NUMBERING SYSTEM (INTEGRATED)**

| Figure | Title | Metadata? | Scientific Questions | Status |
|--------|-------|-----------|---------------------|--------|
| **1** | Dataset Characterization & G>T Landscape | NO | SQ1.1, SQ1.2, SQ1.3 | ✅ DONE |
| **2** | Mechanistic Validation of Oxidative Signature | NO | SQ3.1, SQ3.2, SQ3.3 | 📋 TODAY |
| **3** | Group Comparison (ALS vs Control) | YES | SQ2.1, SQ2.2, SQ2.3, SQ2.4 | 🔧 TEMPLATE |
| **4** | Confounder & Covariate Analysis | YES (opt) | SQ4.1, SQ4.2, SQ4.3 | 💡 OPTIONAL |
| **5** | Functional Impact & Targets | Optional | SQ5.1, SQ5.2 | 💡 FUTURE |

---

## 🎯 **SCIENTIFIC QUESTIONS MAPPED**

### **TIER 1: CHARACTERIZATION** (Figure 1) ✅
- ✅ SQ1.1: Dataset structure & quality
- ✅ SQ1.2: G>T positional distribution
- ✅ SQ1.3: Prevalent mutation types

### **TIER 2: VALIDATION** (Figure 2) 📋
- 📋 SQ3.1: G-content correlation (mechanistic evidence)
- 📋 SQ3.2: G>T specificity (vs other G>X)
- 📋 SQ3.3: Sequence context (8-oxoG signature)

### **TIER 3: COMPARISON** (Figure 3 - requires metadata) 🔧
- 🔧 SQ2.1: G>T enrichment in Group A vs B
- 🔧 SQ2.2: Positional differences between groups
- 🔧 SQ2.3: miRNA-specific enrichment
- 🔧 SQ2.4: Seed region vulnerability by group

### **TIER 4: CONFOUNDERS** (Figure 4 - optional) 💡
- 💡 SQ4.1: Age effect
- 💡 SQ4.2: Sex effect
- 💡 SQ4.3: Technical confounders

### **TIER 5: FUNCTIONAL** (Figure 5 - future) 💡
- 💡 SQ5.1: Target prediction changes
- 💡 SQ5.2: miRNA family patterns
- 💡 SQ1.4: Top miRNAs (deferred from Figure 1)

**Total: 16 scientific questions across 5 tiers**

---

## 📁 **FILE ORGANIZATION (INTEGRATED)**

### **Current Structure:**
```
pipeline_2/
├── steps/                              # Modular pipeline steps
│   ├── step1_characterization.R        ✅ Figure 1 (DONE)
│   ├── step2_mechanistic.R             📋 Figure 2 (TODAY)
│   ├── step3_comparison.R              🔧 Figure 3 (template)
│   └── step4_confounders.R             💡 Figure 4 (optional)
│
├── functions/
│   ├── visualization_functions_v4.R    ✅ Figure 1
│   ├── mechanistic_functions.R         📋 Figure 2 (NEW)
│   ├── comparison_functions.R          🔧 Figure 3 (NEW)
│   └── statistical_tests.R             🔧 Generic tests (NEW)
│
├── data/                               # Supporting data
│   ├── g_content_analysis.csv          📋 Port from previous
│   └── mirna_sequences.fasta           📋 From miRBase (optional)
│
├── templates/                          # User templates
│   ├── sample_groups_template.csv      🔧 NEW
│   ├── demographics_template.csv       🔧 NEW
│   └── README_TEMPLATES.md             🔧 Usage guide
│
├── config/
│   ├── config_pipeline_2.R             ✅ Current paths
│   ├── parameters.R                    ✅ Scientific params
│   └── pipeline_config_template.R      🔧 For users (NEW)
│
├── figures/                            # All generated figures
│   ├── figure_1_corrected.png          ✅ Done
│   ├── figure_2_mechanistic.png        📋 Next
│   └── figure_3_comparison.png         🔧 When user has data
│
├── viewers/                            # HTML viewers
│   ├── figure_1_viewer_v4.html         ✅ Done
│   ├── figure_2_viewer.html            📋 Next
│   └── figure_3_viewer.html            🔧 Template
│
└── docs/                               # Documentation
    ├── README.md                        ✅ Updated
    ├── CHANGELOG.md                     ✅ Updated (v0.1.4)
    ├── SCIENTIFIC_QUESTIONS_ANALYSIS.md ✅ Created
    ├── IMPLEMENTATION_PLAN.md           ✅ Created
    ├── MASTER_INTEGRATION_PLAN.md       ✅ This file
    ├── USER_GUIDE.md                    📋 To create
    └── DEVELOPER_GUIDE.md               📋 To create
```

---

## 🚀 **IMPLEMENTATION TIMELINE**

### **TODAY (Session 1):**
1. ✅ ~~Figure 1 complete~~
2. 📋 Port G-content data
3. 📋 Create mechanistic_functions.R
4. 📋 Implement sequence context analysis
5. 📋 Generate Figure 2
6. 📋 Create Figure 2 HTML viewer

**Deliverable:** 2 complete figures (1 & 2)

---

### **NEXT SESSION (Session 2):**
1. 🔧 Design comparison_functions.R
2. 🔧 Create statistical_tests.R
3. 🔧 Generate templates (sample_groups, demographics)
4. 🔧 Write USER_GUIDE.md
5. 🔧 Create example with dummy data

**Deliverable:** Ready-to-use comparison framework

---

### **FUTURE (Session 3+):**
1. 💡 Implement optional confounder analysis
2. 💡 Add functional analysis modules
3. 💡 Create advanced clustering
4. 💡 Add longitudinal analysis (if applicable)

**Deliverable:** Complete pipeline ecosystem

---

## 🎯 **IMMEDIATE NEXT STEPS (TODAY)**

### **Step 1: Port G-Content Data** ⏱️ 15 min
```r
# Copy data file
# Adapt visualization function
# Test with current data
```

### **Step 2: Create mechanistic_functions.R** ⏱️ 1 hour
```r
# Function 1: create_gcontent_correlation()
# Function 2: analyze_sequence_context()  
# Function 3: calculate_gt_specificity()
# Function 4: create_figure_2_mechanistic()
```

### **Step 3: Implement Sequence Context** ⏱️ 1.5 hours
```r
# Get miRNA sequences
# Extract flanking nucleotides
# Calculate enrichment
# Create visualization
```

### **Step 4: Generate Figure 2** ⏱️ 30 min
```r
# Combine all panels
# Create HTML viewer
# Update documentation
```

**Total time estimate: ~3 hours for complete Figure 2**

---

## 📊 **PROGRESS TRACKING (UPDATED)**

| Metric | Before | After Today | Final Goal |
|--------|--------|-------------|------------|
| Figures Complete | 1/5 (20%) | 2/5 (40%) | 5/5 (100%) |
| Questions Answered | 3/16 (19%) | 6/16 (38%) | 16/16 (100%) |
| No-Metadata Analysis | 19% | 38% | 50% |
| With-Metadata Templates | 0% | 0% | 50% |
| Code Foundation | 60% | 90% | 100% |
| Documentation | 80% | 100% | 100% |

---

## 🎉 **VALUE PROPOSITION**

### **After Today:**
✅ **2 complete, publication-ready figures** (no metadata needed)
✅ **6/16 scientific questions answered** (38% complete)
✅ **Strong mechanistic validation** (G>T is oxidative)
✅ **Generic pipeline** (works with any dataset)
📋 **Ready for metadata integration** (when available)

### **For Users:**
- Can use pipeline_2 immediately with their data
- Get meaningful results without metadata
- Option to enhance with metadata later
- Clear templates and guides provided

---

## ✅ **INTEGRATION SUMMARY**

**Figure 1 + Figure 2 = COMPLETE STORY (No metadata):**

1. **Figure 1:** "Here's our dataset and where G>T mutations are"
2. **Figure 2:** "Here's WHY these are oxidative signatures (mechanistic proof)"

**Figure 3+ = ENHANCED STORY (With metadata):**

3. **Figure 3:** "Here are the differences between groups" (template)
4. **Figure 4:** "Here's validation against confounders" (optional template)
5. **Figure 5:** "Here's the functional impact" (future)

---

## 🚀 **READY TO START?**

**I propose we start implementing Figure 2 NOW:**

1. Copy G-content data ✅
2. Create mechanistic_functions.R ✅
3. Implement sequence context analysis ✅
4. Generate Figure 2 ✅
5. Create HTML viewer ✅
6. Update all documentation ✅

**Estimated completion: ~3 hours**

**¿Procedemos con la implementación? 🎯**

