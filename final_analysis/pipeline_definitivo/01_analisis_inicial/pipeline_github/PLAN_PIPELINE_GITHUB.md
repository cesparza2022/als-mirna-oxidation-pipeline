# PLAN: Pipeline GitHub-Ready para Análisis de SNVs en miRNAs

**Fecha:** 14 de octubre, 2025  
**Objetivo:** Crear pipeline reproducible y automático para análisis de oxidación en miRNAs  

---

## 📊 INPUT DATA FORMAT (Entendido)

### Archivo Principal:
**Nombre:** `miRNA_count.Q33.txt` (formato TSV)

**Estructura:**
```
miRNA name | pos:mut | Sample1 | Sample2 | ... | SampleN
-----------|---------|---------|---------|-----|--------
hsa-let-7a | PM      | 0.0     | 2.0     | ... | 0.0
hsa-let-7a | 7:AT    | 0.0     | 0.0     | ... | 1.0
hsa-let-7a | 3:GT    | 1.0     | 3.0     | ... | 0.0
```

**Detalles:**
- **Columna 1:** `miRNA name` (ej: hsa-let-7a-2-3p)
- **Columna 2:** `pos:mut` (ej: "PM", "7:AT", "3:GT")
  - "PM" = Perfect Match (sin mutación)
  - "N:XY" = Posición:Mutación (ej: 3:GT = posición 3, G>T)
- **Columnas 3+:** Muestras individuales (counts)
  - Nombres: `Magen-ALS-{cohort}-bloodplasma-{SRR_ID}`

**Tipos de muestras:**
- Control
- ALS (enrolment, follow-up)
- Longitudinal (opcional)

---

## 🎯 PIPELINE PROPUESTO

### FASE 1: Preparación de Datos
**Input:** `miRNA_count.Q33.txt` (raw)

**Procesos:**
1. **Split-Collapse:** Una fila por miRNA+posición+mutación
2. **VAF Calculation:** (Count / Total) * 100
3. **Filtering:** VAFs > 50% → NA (technical artifacts)

**Outputs:**
- `01_datos_split_collapse.csv`
- `02_datos_con_vafs.csv`
- `03_datos_filtrados.csv`

---

### FASE 2: Metadata Integration
**Inputs adicionales:**
- `GSE168714_All_samples_enrolment.txt`
- `GSE168714_Data_file_related_to_fig_2_3_5_discovery.csv`

**Procesos:**
1. Mapear IDs de muestras
2. Integrar cohort, timepoint, clinical data
3. Identificar longitudinal samples

**Output:**
- `04_metadata_integrated.csv`

---

### FASE 3: Quality Control
**Procesos:**
1. Outlier detection (PCA, distribuciones)
2. Batch effect assessment
3. Sample QC metrics

**Outputs:**
- `05_outliers_identified.csv`
- `06_qc_metrics.csv`
- Figuras QC

---

### FASE 4: Core Analysis
**Procesos:**
1. G>T mutation analysis (oxidation signature)
2. Seed region enrichment (positions 2-8)
3. Positional patterns
4. VAF comparisons (ALS vs Control)

**Outputs:**
- `07_gt_mutations_annotated.csv`
- `08_seed_region_snvs.csv`
- Figuras analíticas

---

### FASE 5: Sequence Analysis
**Procesos:**
1. Motif discovery
2. Sequence logos
3. G-richness analysis
4. Family clustering

**Outputs:**
- `09_motif_analysis.csv`
- `10_sequence_families.csv`
- Figuras motivos

---

### FASE 6: Functional Analysis
**Procesos:**
1. Pathway enrichment
2. Target gene analysis
3. Disease association

**Outputs:**
- `11_pathway_enrichment.csv`
- `12_functional_summary.csv`
- Figuras pathway

---

### FASE 7: Temporal Analysis (Opcional)
**Solo si hay muestras longitudinales**

**Procesos:**
1. Pairwise comparison (enrolment vs follow-up)
2. Progression patterns
3. Individual trajectories

**Outputs:**
- `13_temporal_changes.csv`
- Figuras temporales

---

### FASE 8: Reporting
**Outputs:**
- HTML interactivo
- PDF estático
- Todas las figuras organizadas
- Tables suplementarias

---

## 📁 ESTRUCTURA PROPUESTA

```
pipeline_github/
├── README.md
├── environment.yml (conda)
├── renv.lock (R packages)
├── config.yaml
├── run_pipeline.sh (master script)
│
├── 00_setup/
│   ├── install_dependencies.R
│   ├── check_requirements.R
│   └── create_directories.R
│
├── 01_preprocessing/
│   ├── 01_split_collapse.R
│   ├── 02_calculate_vafs.R
│   ├── 03_filter_vafs.R
│   └── functions/
│       ├── split_collapse.R
│       ├── vaf_calculation.R
│       └── filters.R
│
├── 02_metadata/
│   ├── 01_load_metadata.R
│   ├── 02_integrate_metadata.R
│   └── 03_identify_longitudinal.R
│
├── 03_qc/
│   ├── 01_outlier_detection.R
│   ├── 02_batch_assessment.R
│   └── 03_sample_metrics.R
│
├── 04_core_analysis/
│   ├── 01_gt_mutations.R
│   ├── 02_seed_region.R
│   ├── 03_positional_analysis.R
│   └── 04_statistical_tests.R
│
├── 05_sequence_analysis/
│   ├── 01_motif_discovery.R
│   ├── 02_sequence_logos.R
│   ├── 03_family_clustering.R
│   └── 04_g_richness.R
│
├── 06_functional/
│   ├── 01_pathway_enrichment.R
│   ├── 02_target_genes.R
│   └── 03_disease_association.R
│
├── 07_temporal/ (opcional)
│   ├── 01_pairwise_comparison.R
│   ├── 02_progression_patterns.R
│   └── 03_trajectories.R
│
├── 08_reporting/
│   ├── 01_generate_figures.R
│   ├── 02_create_tables.R
│   ├── 03_html_report.R
│   └── 04_pdf_export.R
│
├── data/ (user provides)
│   ├── miRNA_count.Q33.txt
│   ├── GSE168714_All_samples_enrolment.txt
│   └── GSE168714_Data_file_related_to_fig_2_3_5_discovery.csv
│
├── outputs/
│   ├── processed_data/
│   ├── qc/
│   ├── analysis/
│   ├── figures/
│   └── tables/
│
└── docs/
    ├── pipeline_diagram.pdf
    ├── data_dictionary.md
    ├── methods.md
    └── interpretation_guide.md
```

---

## 🎯 PRÓXIMOS PASOS

1. ✅ Crear diagrama de flujo del pipeline
2. ✅ Organizar scripts existentes en módulos
3. ✅ Crear master script `run_pipeline.sh`
4. ✅ Documentar cada paso
5. ✅ Crear README completo
6. ✅ Preparar para GitHub

---

**¿Te parece bien esta estructura?**

Confirmando antes de empezar a organizarlo todo.

