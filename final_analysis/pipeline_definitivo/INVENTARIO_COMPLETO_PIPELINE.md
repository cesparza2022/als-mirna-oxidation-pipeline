# 📋 INVENTARIO COMPLETO DEL PIPELINE

**Fecha:** 2025-10-20  
**Objetivo:** Revisar cada paso antes de reorganizar

---

## 🔍 PASO 1: `01_analisis_inicial/`

### **📊 CONTENIDO:**
- **Scripts:** `CREATE_DIAGNOSTIC_FIGURES_FINAL.R`
- **Input:** `step1_original_data.csv` (177 MB, crudo)
- **Proceso:** Split-Collapse (PM/1MM/2MM → agrupar)
- **Output:** Counts limpios (12 tipos, 23 pos)

### **📁 ARCHIVOS GENERADOS:**
```
01_analisis_inicial/
├── scripts/
│   └── CREATE_DIAGNOSTIC_FIGURES_FINAL.R
├── figures/
│   ├── STEP1_FIG1_FINAL_HEATMAP_SNVS_TODAS.png
│   ├── STEP1_FIG2_FINAL_HEATMAP_COUNTS_TODAS.png
│   ├── STEP1_FIG3_FINAL_G_MUTATIONS_SNVS.png
│   ├── STEP1_FIG4_FINAL_G_MUTATIONS_COUNTS.png
│   ├── STEP1_FIG5_FINAL_BUBBLE_SD.png
│   ├── STEP1_FIG6_FINAL_VIOLIN_DISTRIBUTIONS.png
│   └── STEP1_FIG7_FINAL_FOLD_CHANGE_INTEGRATED.png
├── tables/
│   ├── STEP1_mutation_type_summary.csv
│   ├── STEP1_sample_metrics.csv
│   └── STEP1_positional_analysis.csv
└── STEP1_DIAGNOSTIC_FIGURES_VIEWER.html
```

### **🎯 PROPÓSITO:**
- Caracterización inicial del dataset
- 7 figuras diagnósticas (datos raw)
- Todas las 12 mutaciones, todas las 23 posiciones
- Estadísticas básicas por muestra y posición

---

## 🔍 PASO 1.5: `01.5_vaf_quality_control/` ⭐ NUEVO

### **📊 CONTENIDO:**
- **Scripts:** `01_apply_vaf_filter.R`, `02_generate_diagnostic_figures.R`
- **Input:** `step1_original_data.csv` (necesita columnas de totales)
- **Proceso:** VAF Filter (>= 0.5 → NaN)
- **Output:** `ALL_MUTATIONS_VAF_FILTERED.csv` (12 tipos, 23 pos, clean)

### **📁 ARCHIVOS GENERADOS:**
```
01.5_vaf_quality_control/
├── scripts/
│   ├── 01_apply_vaf_filter.R
│   └── 02_generate_diagnostic_figures.R
├── data/
│   ├── ALL_MUTATIONS_VAF_FILTERED.csv ⭐ PRINCIPAL
│   ├── vaf_filter_report.csv (201,293 events)
│   ├── vaf_statistics_by_type.csv
│   └── vaf_statistics_by_mirna.csv
├── figures/
│   ├── QC_FIG1_VAF_DISTRIBUTION.png
│   ├── QC_FIG2_VAF_FILTER_IMPACT.png
│   ├── QC_FIG3_VAF_BY_MUTATION_TYPE.png
│   ├── QC_FIG4_VAF_BY_SAMPLE.png
│   ├── STEP1.5_FIG1_FINAL_HEATMAP_SNVS_TODAS.png
│   ├── STEP1.5_FIG2_FINAL_HEATMAP_COUNTS_TODAS.png
│   ├── STEP1.5_FIG3_FINAL_G_MUTATIONS_SNVS.png
│   ├── STEP1.5_FIG4_FINAL_G_MUTATIONS_COUNTS.png
│   ├── STEP1.5_FIG5_FINAL_BUBBLE_SD.png
│   ├── STEP1.5_FIG6_FINAL_VIOLIN_DISTRIBUTIONS.png
│   └── STEP1.5_FIG7_FINAL_FOLD_CHANGE_INTEGRATED.png
├── tables/ (3 CSV summary tables)
├── vaf_filter_execution.log
├── figure_generation.log
├── README.md
└── STEP1.5_VAF_QC_VIEWER.html
```

### **🎯 PROPÓSITO:**
- Filtro de calidad VAF (>= 0.5 → NaN)
- 4 figuras QC del filtro
- 7 figuras diagnósticas (VAF-filtered)
- Comparación: datos raw vs clean

---

## 🔍 PASO 2: `pipeline_2/` (ACTUAL)

### **📊 CONTENIDO:**
- **Input:** Dataset G>T seed (pos 2-8)
- **Proceso:** Análisis avanzado G>T
- **Output:** 12 figuras avanzadas

### **📁 ARCHIVOS GENERADOS:**
```
pipeline_2/
├── scripts/ (múltiples scripts R)
├── figures/ (12 figuras avanzadas)
├── data/ (datasets intermedios)
├── tables/ (tablas de resultados)
└── HTML viewer
```

### **🎯 PROPÓSITO:**
- Análisis específico G>T en seed region
- 12 figuras avanzadas
- Volcano plots, heatmaps, clustering
- Selección de candidatos

---

## 🔍 PASO 2.5: `pipeline_2.5/` (ACTUAL)

### **📊 CONTENIDO:**
- **Input:** Candidatos del Paso 2
- **Proceso:** Análisis de patrones
- **Output:** 13 figuras de patrones

### **📁 ARCHIVOS GENERADOS:**
```
pipeline_2.5/
├── scripts/
│   ├── 01_clustering_samples.R
│   ├── 02_family_analysis.R
│   ├── 03_seed_analysis.R
│   ├── 04_trinucleotide_analysis.R
│   └── 05_als_vs_control.R
├── figures/ (13 figuras de patrones)
├── data/ (datasets intermedios)
└── PASO_2.5_PATRONES.html
```

### **🎯 PROPÓSITO:**
- Clustering de muestras
- Análisis de familias miRNA
- Análisis de secuencias seed
- Contextos trinucleótido
- Comparaciones ALS vs Control

---

## 🔍 PASO 2.6: `pipeline_2.6_sequence_motifs/` (ACTUAL)

### **📊 CONTENIDO:**
- **Input:** Candidatos del Paso 2
- **Proceso:** Análisis de motivos de secuencia
- **Output:** Sequence logos, contextos trinucleótido

### **📁 ARCHIVOS GENERADOS:**
```
pipeline_2.6_sequence_motifs/
├── scripts/
│   ├── 01_download_mirbase_sequences.R
│   ├── 02_create_sequence_logos.R
│   └── 03_clustering_by_similarity.R
├── figures/
│   ├── LOGO_Position_2.png
│   ├── LOGO_Position_3.png
│   ├── LOGO_Position_5.png
│   └── LOGO_ALL_POSITIONS_COMBINED.png
├── data/
│   ├── candidates_with_sequences.csv
│   ├── snv_with_sequence_context.csv
│   ├── trinucleotide_context_summary.csv
│   └── sequence_windows_all.csv
└── VIEWER_SEQUENCE_LOGOS.html
```

### **🎯 PROPÓSITO:**
- Sequence logos por posición
- Análisis de contextos trinucleótido
- Conservación de secuencias
- Motivos GpG (oxidación)

---

## 🔍 PASO 3: `pipeline_3/` (ACTUAL)

### **📊 CONTENIDO:**
- **Input:** Candidatos del Paso 2
- **Proceso:** Análisis funcional (targets, pathways, networks)
- **Output:** 6 figuras funcionales

### **📁 ARCHIVOS GENERADOS:**
```
pipeline_3/
├── scripts/
│   ├── 01_setup_and_verify.R
│   ├── 02_query_targets.R
│   ├── 03_pathway_enrichment.R
│   ├── 04_network_analysis.R
│   ├── 05_create_figures.R
│   └── 06_create_HTML.R
├── figures/ (6 figuras funcionales)
├── data/ (targets, pathways, networks)
└── PASO_3_VIEWER_SIMPLE.html
```

### **🎯 PROPÓSITO:**
- Predicción de targets
- Enriquecimiento de pathways
- Análisis de redes
- Interpretación biológica

---

## 📊 RESUMEN DE FLUJO ACTUAL

### **FLUJO ACTUAL:**
```
Paso 1: 01_analisis_inicial/
   ↓ (Split-Collapse)
Paso 1.5: 01.5_vaf_quality_control/ ⭐ NUEVO
   ↓ (VAF Filter)
Paso 2: pipeline_2/
   ↓ (G>T Seed Analysis)
Paso 2.5: pipeline_2.5/
   ↓ (Pattern Analysis)
Paso 2.6: pipeline_2.6_sequence_motifs/
   ↓ (Sequence Motifs)
Paso 3: pipeline_3/
   ↓ (Functional Analysis)
```

### **FLUJO PROPUESTO:**
```
Paso 1: 01_analisis_inicial/ (MANTENER)
   ↓ (Split-Collapse)
Paso 2: 02_vaf_quality_control/ (RENOMBRAR 1.5)
   ↓ (VAF Filter)
Paso 3: 03_gt_seed_analysis/ (RENOMBRAR pipeline_2)
   ↓ (G>T Seed Analysis)
Paso 4: 04_pattern_analysis/ (RENOMBRAR pipeline_2.5)
   ↓ (Pattern Analysis)
Paso 5: 05_sequence_motifs/ (RENOMBRAR pipeline_2.6)
   ↓ (Sequence Motifs)
Paso 6: 06_functional_analysis/ (RENOMBRAR pipeline_3)
   ↓ (Functional Analysis)
```

---

## 🔧 INTEGRACIÓN NECESARIA

### **CAMBIOS EN `pipeline_2` (futuro Paso 3):**
- **Input actual:** `step1_original_data.csv`
- **Input nuevo:** `ALL_MUTATIONS_VAF_FILTERED.csv` (del Paso 2)
- **Ventaja:** Ya tiene filtro VAF aplicado, más limpio

### **SCRIPT A MODIFICAR:**
- `pipeline_2/scripts/01_setup_and_verify.R`
- Cambiar path de input
- Verificar que funciona con datos VAF-filtered

---

## 📋 DECISIÓN DE REORGANIZACIÓN

### **OPCIÓN A: RENOMBRAR TODO (RECOMENDADA)**
```
01_analisis_inicial/           → Mantener
01.5_vaf_quality_control/      → 02_vaf_quality_control/
pipeline_2/                    → 03_gt_seed_analysis/
pipeline_2.5/                  → 04_pattern_analysis/
pipeline_2.6_sequence_motifs/  → 05_sequence_motifs/
pipeline_3/                    → 06_functional_analysis/
```

### **OPCIÓN B: MANTENER NUMERACIÓN ACTUAL**
```
01_analisis_inicial/           → Mantener
01.5_vaf_quality_control/      → pipeline_1.5/
pipeline_2/                    → Mantener
pipeline_2.5/                  → Mantener
pipeline_2.6_sequence_motifs/  → Mantener
pipeline_3/                    → Mantener
```

---

## 🎯 VENTAJAS DE CADA OPCIÓN

### **OPCIÓN A (Renombrar todo):**
✅ Numeración secuencial clara (01, 02, 03, 04, 05, 06)  
✅ Flujo lógico evidente  
✅ Fácil navegación  
❌ Requiere actualizar referencias en scripts  

### **OPCIÓN B (Mantener numeración):**
✅ No requiere cambios en scripts existentes  
✅ Mantiene compatibilidad  
❌ Numeración inconsistente (01, pipeline_1.5, pipeline_2, etc.)  
❌ Menos claro el flujo  

---

## 🚀 PRÓXIMOS PASOS

1. **Decidir opción de reorganización**
2. **Ejecutar renombrado**
3. **Modificar `pipeline_2` para usar datos VAF-filtered**
4. **Actualizar documentación**
5. **Validar funcionamiento**

---

**¿Cuál opción prefieres para la reorganización?**

