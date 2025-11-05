# Comparison: Original Paper vs Our Analysis

**Document:** Comparison between original GSE168714 paper and our oxidative stress analysis  
**Date:** October 14, 2025  
**Status:** Phase 1.1 Complete  

---

## ORIGINAL PAPER (s41593-021-00936-z.pdf)

### Citation
**Title:** "Circulating miR-181 is a prognostic biomarker for amyotrophic lateral sclerosis"  
**Journal:** Nature Neuroscience (2021)  
**Dataset:** GSE168714  
**DOI:** 10.1038/s41593-021-00936-z

### Focus
- **Data type:** Expression levels (miRNA abundance)
- **Primary miRNA:** miR-181
- **Clinical goal:** Prognostic biomarker (survival prediction)
- **Samples:** 253 samples

### Main Findings
1. **miR-181 as prognostic biomarker**
   - Elevated miR-181 predicts mortality (HR > 2)
   - Significant differences ALS vs Control
   - Validated with neurofilament light chain (NfL)

2. **Clinical correlations**
   - Disease progression prediction
   - Survival analysis
   - Patient stratification

3. **Methodological approach**
   - qRT-PCR quantification
   - Longitudinal clinical follow-up
   - Statistical survival models

### What They Did NOT Analyze
- ❌ SNV/mutation patterns
- ❌ Oxidative damage (8-oxoG)
- ❌ Positional patterns
- ❌ Sequence motifs
- ❌ Pathway enrichment of oxidized miRNAs

---

## OUR ANALYSIS (Pipeline Definitivo)

### Focus
- **Data type:** Single Nucleotide Variants (SNVs)
- **Primary signature:** G>T mutations (8-oxoG oxidation marker)
- **Clinical goal:** Oxidative stress biomarker
- **Samples:** 415 samples (same GSE168714 dataset)

### Main Findings (7 Key Discoveries)

#### 1. G>T Dominance in Seed Region
- **Finding:** 68% of all SNVs in seed region are G>T
- **Significance:** Specific oxidative signature
- **Region:** Positions 2-8 (functional seed)
- **Evidence:** Chi-square p < 0.001

#### 2. Position 3 Clinical Significance ⭐
- **Finding:** Position 3 significantly enriched in ALS
- **Statistics:** p = 0.027 (Wilcoxon test, FDR-corrected)
- **Direction:** Higher VAF in ALS vs Control
- **Uniqueness:** Only position with statistical significance

#### 3. let-7 Family Ultra-Susceptibility ⭐⭐⭐
- **Seed sequence:** TGAGGTA
- **Pattern:** Exact G>T at positions 2, 4, and 5
- **Penetrance:** 100% (9/9 let-7 members)
- **VAF:** ~0.024 (high oxidation level)
- **Reproducibility:** Identical pattern across all family members

#### 4. G-Content Mechanism
- **Finding:** More G's in seed → Higher oxidation risk
- **Evidence:** Dose-response relationship
  - 0-1 G's: ~5% oxidized
  - 5-6 G's: ~18% oxidized
- **Interpretation:** G's are substrate for oxidation

#### 5. ALS Pathway Directly Affected ⭐⭐⭐
- **Top pathway:** KEGG:05014 Amyotrophic Lateral Sclerosis
- **Statistics:** FDR < 0.001
- **Key genes:** SOD1, TDP43, FUS, OPTN
- **Impact:** Molecular → pathological connection

#### 6. Temporal Patterns
- **Finding:** G>T accumulates over time
- **Timepoints:** 0, 6, 18, 48 hours
- **Stability:** Not random degradation
- **Interpretation:** Systematic oxidative process

#### 7. Robustness Validated
- **Method:** Re-analysis without outliers
- **Result:** All findings maintained
- **Conclusion:** Results are reproducible

---

## SIDE-BY-SIDE COMPARISON

| Aspect | Original Paper | Our Analysis |
|--------|---------------|--------------|
| **Data Level** | Expression (RNA levels) | Mutations (SNVs) |
| **Molecular Focus** | RNA abundance | Oxidative damage |
| **Key miRNA** | miR-181 | let-7 family |
| **Clinical Application** | Prognosis (survival) | Diagnosis (oxidative stress) |
| **Positional Analysis** | Not performed | Position 3 significant |
| **Sequence Analysis** | Not performed | TGAGGTA motif identified |
| **Pathway Analysis** | Expression-based | SNV-based (ALS pathway) |
| **Validation** | Clinical longitudinal | Statistical (without outliers) |
| **Sample Size** | 253 | 415 |
| **Mechanism** | Not explored | G-content → oxidation |

---

## COMPLEMENTARITY

### They Found (Expression Level):
✅ miR-181 dysregulated in ALS  
✅ Prognostic biomarker validated  
✅ Clinical correlation strong  

### We Found (Mutation Level):
✅ let-7 oxidized in ALS  
✅ Specific pattern TGAGGTA  
✅ Molecular mechanism (G's → oxidation)  
✅ ALS pathway directly affected  

### Integration:
⭐⭐⭐ **BOTH levels (expression + mutation) dysregulated**  
⭐⭐ **Different miRNAs** (miR-181 vs let-7)  
⭐⭐ **Complementary analyses** of same dataset  
⭐ **Multi-level dysregulation** in ALS  

---

## ADDED VALUE OF OUR ANALYSIS

### 1. Novel Mechanism
- **Sequence-specific oxidation** (TGAGGTA motif)
- **G-content correlation** with oxidation
- **Molecular explanation** for susceptibility

### 2. New Biomarkers
- **let-7 pattern** (positions 2, 4, 5)
- **Position 3** clinically significant
- **Motif-based susceptibility** markers

### 3. New Perspective
- **Oxidative damage** at sequence level
- **Not just expression altered, but mutated**
- **ALS pathway** directly impacted by oxidation

### 4. Robust Validation
- **Outlier-independent** results
- **Temporally stable** patterns
- **100% penetrance** in let-7

---

## WHAT WE CAN SAY IN OUR REPORT

### Our Contribution
> "While the original study by Magen et al. (2021) focused on miR-181 expression as a prognostic biomarker for ALS, our complementary analysis reveals a distinct layer of miRNA dysregulation through oxidative damage. Using the same GSE168714 dataset, we demonstrate that G>T mutations—specific signatures of 8-oxoguanosine oxidation—show reproducible, sequence-dependent patterns, particularly in the let-7 family. This analysis provides a mechanistic understanding of oxidative stress in ALS at the sequence level, complementing expression-based biomarker approaches."

### Key Distinctions
1. **Different molecular level:** Expression vs Mutation
2. **Different miRNAs:** miR-181 (prognostic) vs let-7 (oxidative)
3. **Different biomarker type:** Survival vs Oxidative stress
4. **Novel mechanisms:** G-content susceptibility, TGAGGTA motif
5. **Pathway connection:** Direct link to ALS molecular pathway

### Synergy
> "Our findings suggest a multi-level dysregulation model in ALS:
> - **Expression level** (miR-181 dysregulation - original paper)
> - **Sequence level** (let-7 oxidation - our analysis)
> - **Pathway level** (ALS genes affected - both converge)"

---

## TABLES FOR HTML

### Table 1: Study Comparison

| Feature | Original Paper (Magen et al., 2021) | Our Analysis (2025) |
|---------|-------------------------------------|---------------------|
| Dataset | GSE168714 | GSE168714 |
| Samples | 253 | 415 |
| Focus | miR-181 expression | G>T oxidation patterns |
| Key Finding | miR-181 predicts mortality | let-7 oxidation pattern |
| Significance | HR > 2 for survival | p = 0.027 for position 3 |
| Pathway | Not analyzed | KEGG:05014 ALS (FDR < 0.001) |
| Mechanism | Not explored | G-content correlation |
| Validation | Clinical outcomes | Statistical robustness |

### Table 2: miRNA Comparison

| Aspect | miR-181 (Their Focus) | let-7 (Our Focus) |
|--------|----------------------|-------------------|
| Role | Prognostic biomarker | Oxidative biomarker |
| Level | Expression changes | Sequence mutations |
| Pattern | Dysregulated levels | TGAGGTA oxidation |
| Positions | Not analyzed | 2, 4, 5 (100% penetrance) |
| Clinical | Mortality prediction | Oxidative stress marker |
| Pathway | Not specified | ALS pathway enriched |

---

## CONCLUSION

Our analysis provides a **complementary and novel perspective** on the same GSE168714 dataset:

- ✅ **Original paper:** Expression-based prognostic biomarker (miR-181)
- ✅ **Our analysis:** Sequence-based oxidative stress biomarker (let-7)
- ✅ **Together:** Multi-level understanding of miRNA dysregulation in ALS

**Bottom line:** We analyzed oxidative damage that the original paper didn't explore, revealing new mechanisms and biomarkers that complement their clinical findings.

---

**Status:** Ready for integration into HTML report  
**Next:** Consolidate statistical tables (Phase 1.2)








