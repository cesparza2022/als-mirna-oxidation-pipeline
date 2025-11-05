# 🔬 SCIENTIFIC QUESTIONS ANALYSIS - PIPELINE_2

## 📋 **QUESTIONS ANSWERED SO FAR (Figure 1)**

### ✅ **SQ1.1: Dataset Structure & Quality**
**Question:** What is the structure and quality of our miRNA mutation dataset?

**Answer:**
- Original file contains **68,968 raw entries** (rows)
- After splitting concatenated mutations → **111,785 individual entries**
- After filtering "PM" (Perfect Match) → **110,199 valid SNVs**
- Coverage: **1,462 unique miRNAs**
- **Conclusion:** High-quality dataset with sufficient coverage for analysis

---

### ✅ **SQ1.2: G>T Positional Distribution**
**Question:** Where are G>T mutations located across miRNA positions?

**Answer:**
- Total G>T mutations: **8,033** (7.3% of all mutations)
- **Positional frequency heatmap** shows distribution across positions 1-22
- **Seed region (2-8) vs Non-seed comparison** available
- **Conclusion:** G>T mutations show specific positional patterns (visualization ready)

---

### ✅ **SQ1.3: Prevalent Mutation Types**
**Question:** What are the most frequent mutation types in our dataset?

**Answer:**
Top 10 mutation types identified:
1. **T>C**: 19,569 (17.8%)
2. **A>G**: 17,081 (15.5%)
3. **G>A**: 13,403 (12.2%)
4. **C>T**: 10,742 (9.8%)
5. **T>A**: 8,802 (8.0%)
6. **G>T**: 8,033 (7.3%) ← Our target
7. **T>G**: 7,607 (6.9%)
8. **A>T**: 6,921 (6.3%)
9. **C>A**: 5,455 (5.0%)
10. **C>G**: 4,908 (4.5%)

**Conclusion:** G>T is the 6th most frequent mutation type, representing a substantial portion of the dataset

---

### ⏳ **SQ1.4: Top miRNAs with G>T** (Pending)
**Question:** Which miRNAs show the highest G>T mutation burden?

**Status:** Deferred to focus on initial characterization
**Reason:** Need to complete foundational analysis before miRNA-specific investigation

---

## 🔍 **QUESTIONS WE SHOULD ADDRESS NEXT**

### 🆕 **SQ2: COMPARATIVE ANALYSIS (ALS vs Control)**

#### **SQ2.1: G>T Enrichment in ALS**
**Question:** Are G>T mutations more frequent in ALS patients compared to controls?
**Why important:** Core hypothesis - oxidative stress biomarker
**Required analysis:**
- Chi-squared test or Fisher's exact test
- Effect size calculation (Odds Ratio)
- Volcano plot visualization
**Priority:** ⭐⭐⭐⭐⭐ (CRITICAL)

#### **SQ2.2: Positional Differences ALS vs Control**
**Question:** Do ALS patients show different G>T positional patterns compared to controls?
**Why important:** Could reveal functional consequences
**Required analysis:**
- Position-by-position comparison (seed vs non-seed)
- Wilcoxon rank-sum test per position
- Heatmap comparison side-by-side
**Priority:** ⭐⭐⭐⭐ (HIGH)

#### **SQ2.3: miRNA-Specific G>T Changes**
**Question:** Which specific miRNAs show significant G>T enrichment in ALS?
**Why important:** Identify candidate biomarkers
**Required analysis:**
- Per-miRNA G>T fraction comparison
- FDR-corrected p-values
- Top 20 most significant miRNAs
**Priority:** ⭐⭐⭐⭐ (HIGH)

#### **SQ2.4: Seed Region Vulnerability**
**Question:** Is the seed region more affected by G>T in ALS vs Control?
**Why important:** Seed region is functionally critical
**Required analysis:**
- Seed vs non-seed G>T fraction by group
- Interaction effect (position × group)
- Functional impact assessment
**Priority:** ⭐⭐⭐⭐ (HIGH)

---

### 🆕 **SQ3: OXIDATIVE STRESS SIGNATURE**

#### **SQ3.1: G>T as 8-oxoG Biomarker**
**Question:** Does our G>T pattern match expected 8-oxoguanine signature?
**Why important:** Validates oxidative stress hypothesis
**Required analysis:**
- Compare with known 8-oxoG positional preferences
- Literature comparison
- Sequence context analysis (if available)
**Priority:** ⭐⭐⭐⭐ (HIGH)

#### **SQ3.2: Other G>X Mutations**
**Question:** Are other G>X mutations (G>A, G>C) also enriched in ALS?
**Why important:** Comprehensive oxidative damage assessment
**Required analysis:**
- All G>X mutations comparison (not just G>T)
- Specificity of G>T vs other G>X
**Priority:** ⭐⭐⭐ (MEDIUM)

#### **SQ3.3: Dose-Response Relationship**
**Question:** Is there a correlation between G>T burden and disease severity? (if clinical data available)
**Why important:** Clinical relevance
**Required analysis:**
- Correlation with ALSFRS-R scores (if available)
- Survival analysis (if available)
**Priority:** ⭐⭐ (LOW - depends on data availability)

---

### 🆕 **SQ4: CONFOUNDERS & VALIDATION**

#### **SQ4.1: Age Effect**
**Question:** Is G>T enrichment driven by age differences between groups?
**Why important:** Age is known to increase oxidative stress
**Required analysis:**
- Age distribution ALS vs Control
- Age-adjusted analysis (linear model)
- Stratified analysis by age groups
**Priority:** ⭐⭐⭐⭐⭐ (CRITICAL)

#### **SQ4.2: Sex Effect**
**Question:** Does sex influence G>T patterns?
**Why important:** Sex-specific oxidative stress responses exist
**Required analysis:**
- Sex distribution check
- Sex-stratified analysis
- Interaction effect (sex × group)
**Priority:** ⭐⭐⭐⭐ (HIGH)

#### **SQ4.3: Technical Confounders**
**Question:** Are there batch effects or sequencing depth differences?
**Why important:** Technical artifacts can mimic biological signals
**Required analysis:**
- Sequencing depth comparison
- Batch effect assessment (if batch info available)
- PCA colored by technical variables
**Priority:** ⭐⭐⭐⭐ (HIGH)

---

### 🆕 **SQ5: FUNCTIONAL IMPACT**

#### **SQ5.1: Predicted Target Changes**
**Question:** How do G>T mutations in seed regions affect predicted mRNA targets?
**Why important:** Understand functional consequences
**Required analysis:**
- Target prediction with mutated seeds
- GO enrichment of affected pathways
**Priority:** ⭐⭐⭐ (MEDIUM - computationally intensive)

#### **SQ5.2: miRNA Family Analysis**
**Question:** Are certain miRNA families more vulnerable to G>T?
**Why important:** Could reveal sequence-specific vulnerability
**Required analysis:**
- Group miRNAs by family
- Family-level G>T enrichment
**Priority:** ⭐⭐ (LOW - exploratory)

---

## 📊 **RECOMMENDED ANALYSIS PIPELINE**

### **PHASE 1: CORE COMPARISONS (Figure 2)** ⭐⭐⭐⭐⭐
**Priority:** IMMEDIATE
1. **SQ2.1**: G>T enrichment ALS vs Control (primary outcome)
2. **SQ2.2**: Positional differences
3. **SQ2.3**: miRNA-specific changes
4. **SQ2.4**: Seed region vulnerability

**Deliverable:** Figure 2 - "ALS vs Control G>T Analysis"

---

### **PHASE 2: CONFOUNDER ANALYSIS (Figure 3)** ⭐⭐⭐⭐⭐
**Priority:** HIGH (critical for validity)
1. **SQ4.1**: Age adjustment
2. **SQ4.2**: Sex effects
3. **SQ4.3**: Technical validation

**Deliverable:** Figure 3 - "Confounder Analysis & Validation"

---

### **PHASE 3: OXIDATIVE STRESS VALIDATION (Figure 4)** ⭐⭐⭐⭐
**Priority:** HIGH (mechanistic insight)
1. **SQ3.1**: 8-oxoG signature validation
2. **SQ3.2**: Comprehensive G>X analysis
3. **SQ2.2 extended**: Detailed positional analysis

**Deliverable:** Figure 4 - "Oxidative Stress Signature Characterization"

---

### **PHASE 4: FUNCTIONAL EXPLORATION (Figure 5)** ⭐⭐⭐
**Priority:** MEDIUM (exploratory)
1. **SQ5.1**: Target prediction analysis
2. **SQ5.2**: miRNA family vulnerability
3. **SQ3.3**: Clinical correlations (if data available)

**Deliverable:** Figure 5 - "Functional Impact & Clinical Relevance"

---

## 🎯 **IMMEDIATE NEXT STEPS**

### **What we should work on NOW:**

1. **Verify data availability:**
   - Do we have sample metadata (ALS vs Control labels)?
   - Do we have age/sex information?
   - Do we have batch information?

2. **Prepare for Figure 2 (ALS vs Control):**
   - Load sample groupings
   - Calculate group-specific G>T statistics
   - Design comparison visualizations

3. **Statistical framework:**
   - Choose appropriate tests
   - Set significance thresholds
   - Plan multiple testing correction

---

## 📝 **QUESTIONS FOR USER**

Before proceeding with Figure 2, we need to confirm:

1. **Do you have sample metadata?** (ALS vs Control labels, age, sex, etc.)
2. **Where is this metadata located?**
3. **What is your primary research question?** (to prioritize analyses)
4. **Any specific hypotheses to test?**
5. **Do you have clinical data?** (ALSFRS-R, survival, etc.)

---

## 🔄 **ANALYSIS STATUS TRACKING**

| Question | Status | Priority | Figure | Notes |
|----------|--------|----------|--------|-------|
| SQ1.1 | ✅ Complete | ⭐⭐⭐⭐⭐ | Fig 1 | Dataset characterization done |
| SQ1.2 | ✅ Complete | ⭐⭐⭐⭐⭐ | Fig 1 | Positional distribution visualized |
| SQ1.3 | ✅ Complete | ⭐⭐⭐⭐⭐ | Fig 1 | Mutation spectrum characterized |
| SQ1.4 | ⏸️ Deferred | ⭐⭐⭐ | Later | Focus on initial characterization |
| SQ2.1 | 📋 Planned | ⭐⭐⭐⭐⭐ | Fig 2 | **NEXT PRIORITY** |
| SQ2.2 | 📋 Planned | ⭐⭐⭐⭐ | Fig 2 | After SQ2.1 |
| SQ2.3 | 📋 Planned | ⭐⭐⭐⭐ | Fig 2 | After SQ2.1 |
| SQ2.4 | 📋 Planned | ⭐⭐⭐⭐ | Fig 2 | After SQ2.1 |
| SQ3.1 | 📋 Planned | ⭐⭐⭐⭐ | Fig 4 | Mechanistic validation |
| SQ3.2 | 📋 Planned | ⭐⭐⭐ | Fig 4 | Comprehensive G>X |
| SQ3.3 | 🔍 Pending | ⭐⭐ | Fig 5 | Data-dependent |
| SQ4.1 | 📋 Planned | ⭐⭐⭐⭐⭐ | Fig 3 | **CRITICAL** |
| SQ4.2 | 📋 Planned | ⭐⭐⭐⭐ | Fig 3 | Important validation |
| SQ4.3 | 📋 Planned | ⭐⭐⭐⭐ | Fig 3 | Technical QC |
| SQ5.1 | 💡 Future | ⭐⭐⭐ | Fig 5 | Functional analysis |
| SQ5.2 | 💡 Future | ⭐⭐ | Fig 5 | Exploratory |

**Legend:**
- ✅ Complete
- 📋 Planned (ready to implement)
- ⏸️ Deferred
- 🔍 Pending (data-dependent)
- 💡 Future (lower priority)

---

**Last Updated:** 2025-01-16
**Current Phase:** Figure 1 Complete → Ready for Figure 2 (Comparative Analysis)

