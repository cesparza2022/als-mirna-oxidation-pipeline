# 📍 RESUMEN COMPLETO: DÓNDE ESTÁ TODO EN EL PIPELINE

Este documento te dice **exactamente dónde encontrar** scripts, viewers, figuras y tablas de cada paso.

---

## 🗂️ ESTRUCTURA GENERAL

```
pipeline_definitivo/
├── PASO 1: STEP1_ORGANIZED/
├── PASO 1.5: 01.5_vaf_quality_control/
├── PASO 2: step2/
└── Documentación: ORGANIZACION_PIPELINE.md, BITACORA_PIPELINE.md
```

---

## 📊 PASO 1: Análisis Inicial Exploratorio

### 📁 Ubicación:
```
pipeline_definitivo/STEP1_ORGANIZED/
```

### 📄 Viewer Principal:
```
STEP1_ORGANIZED/STEP1_FINAL.html
```

### 🔧 Scripts (Generadores de Figuras):
```
STEP1_ORGANIZED/scripts/
├── 02_gt_count_by_position.R
├── 03_gx_spectrum.R
├── 04_positional_fraction.R
├── 05_gcontent_FINAL_VERSION.R  ⭐ (Panel E - G-content)
├── 06_seed_vs_nonseed.R
├── 07_gt_specificity.R
└── RUN_COMPLETE_PIPELINE_PASO1.R  ⭐ (Orquestador principal)
```

### 📊 Figuras:
```
STEP1_ORGANIZED/figures/
├── step1_panelA_dataset_overview.png
├── step1_panelB_gt_count_by_position.png
├── step1_panelC_gx_spectrum.png
├── step1_panelD_positional_fraction.png
├── step1_panelE_FINAL_BUBBLE.png  ⭐
├── step1_panelF_seed_interaction.png
├── step1_panelG_gt_specificity.png
└── step1_panelH_sequence_context.png
```

### 📋 Tablas:
```
STEP1_ORGANIZED/data/
├── TABLE_1.B_gt_counts_by_position.csv
├── TABLE_1.C_gx_spectrum_by_position.csv
├── TABLE_1.D_positional_fractions.csv
├── TABLE_1.F_seed_vs_nonseed.csv
└── TABLE_1.G_gt_specificity.csv
```

### 📚 Documentación:
```
STEP1_ORGANIZED/documentation/
├── STEP1_README.md
├── COMPLETE_REGISTRY.md
└── CLARIFICACION_METRICAS_EXACTAS.md
```

### ▶️ Cómo ejecutar:
```bash
cd STEP1_ORGANIZED
Rscript RUN_COMPLETE_PIPELINE_PASO1.R
```

---

## 📊 PASO 1.5: Control de Calidad VAF

### 📁 Ubicación:
```
pipeline_definitivo/01.5_vaf_quality_control/
```

### 📄 Viewer Principal:
```
01.5_vaf_quality_control/STEP1.5_VAF_QC_VIEWER.html
```

### 🔧 Scripts:
```
01.5_vaf_quality_control/scripts/
├── 01_apply_vaf_filter.R  ⭐ (Aplica filtro VAF > 50%)
└── 02_generate_diagnostic_figures.R  ⭐ (Genera figuras QC)
```

### 📊 Figuras:
```
01.5_vaf_quality_control/figures/
├── QC_FIG1_VAF_DISTRIBUTION.png
├── QC_FIG2_FILTER_IMPACT.png
├── QC_FIG3_AFFECTED_MIRNAS.png
├── QC_FIG4_BEFORE_AFTER.png
├── STEP1.5_FIG1_HEATMAP_SNVS.png
├── STEP1.5_FIG2_HEATMAP_COUNTS.png
├── STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png
├── STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png
├── STEP1.5_FIG5_BUBBLE_PLOT.png
├── STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png
└── STEP1.5_FIG7_FOLD_CHANGE.png
```

### 📋 Tablas:
```
01.5_vaf_quality_control/tables/
├── mutation_type_summary_vaf_filtered.csv
├── position_metrics_vaf_filtered.csv
└── sample_metrics_vaf_filtered.csv
```

### 📊 Datos Procesados:
```
01.5_vaf_quality_control/data/
├── ALL_MUTATIONS_VAF_FILTERED.csv  ⭐ (Datos filtrados - input para Paso 2)
├── vaf_filter_report.csv
├── vaf_statistics_by_mirna.csv
└── vaf_statistics_by_type.csv
```

### ▶️ Cómo ejecutar:
```bash
cd 01.5_vaf_quality_control
Rscript scripts/01_apply_vaf_filter.R
Rscript scripts/02_generate_diagnostic_figures.R
```

---

## 📊 PASO 2: Comparaciones entre Grupos

### 📁 Ubicación:
```
pipeline_definitivo/step2/
```

### 📄 Viewers:
atic
```
step2/viewers/
├── STEP2_EMBED.html  ⭐⭐⭐ (PRINCIPAL - imágenes embebidas)
└── STEP2.html        (alternativo - rutas relativas)
```

### 🔧 Scripts (Generadores de Figuras):
```
step2/scripts/
├── generate_FIG_2.1_COMPARISON_LOG_VS_LINEAR.R
├── generate_FIG_2.2_SIMPLIFIED.R
├── generate_FIG_2.3_CORRECTED_AND_ANALYZE.R
├── generate_FIG_2.4_HEATMAP_RAW.R
├── generate_FIG_2.5_ZSCORE_ALL301.R
├── generate_FIG_2.5_DIFFERENTIAL_ALL301.R
├── generate_FIG_2.6_POSITIONAL.R
├── generate_FIG_2.6_CORRECTED.R
├── generate_FIG_2.6_IMPROVED.R
├── generate_FIG_2.7_IMPROVED.R
├── generate_FIG_2.8_CLUSTERING.R
├── generate_FIG_2.9_IMPROVED.R
├── generate_FIG_2.10_GT_RATIO.R
├── generate_FIG_2.11_MUTATION_SPECTRUM.R
├── generate_FIG_2.11_IMPROVED.R
├── generate_FIG_2.12_ENRICHMENT.R
├── generate_FIG_2.13-15_DENSITY.R  ⭐ (Genera density heatmaps)
├── build_step2_viewers.R  ⭐ (Genera HTML viewers)
└── RUN_COMPLETE_PIPELINE_PASO2.R  (Alternativo - ejecuta todo)
```

### ⚙️ Orquestador Principal:
```
step2/run_step2.R  ⭐⭐⭐ (EJECUTAR ESTE para todo el Paso 2)
```

**Lo que hace:**
1. Ejecuta generadores de figuras 2.1-2.15
2. Sincroniza golden copies (2.13-2.15) desde `pipeline_2/HTML_VIEWERS_FINALES/`
3. Construye `STEP2_EMBED.html` y `STEP2.html` automáticamente

### 📊 Figuras Finales:
```
step2/outputs/figures/
├── FIG_2.1_VAF_COMPARISON_LINEAR.png
├── FIG_2.2_DISTRIBUTIONS_LINEAR.png
├── FIG_2.3_VOLCANO_COMBINADO.png
├── FIG_2.4_HEATMAP_ALL.png
├── FIG_2.5_ZSCORE_HEATMAP.png
├── FIG_2.6_POSITIONAL_ANALYSIS.png
├── FIG_2.7_PCA_PERMANOVA.png
├── FIG_2.8_CLUSTERING.png
├── FIG_2.9_COMBINED_IMPROVED.png
├── FIG_2.10_COMBINED.png
├── FIG_2.11_COMBINED_IMPROVED.png
└── FIG_2.12_COMBINED.png
```

### 📊 Figuras Clean / Golden Copies:
```
step2/outputs/figures_clean/
├── FIG_2.13_DENSITY_HEATMAP_ALS.png  ⭐ (golden copy)
├── FIG_2.14_DENSITY_HEATMAP_CONTROL.png  ⭐ (golden copy)
└── FIG_2.15_DENSITY_COMBINED.png  ⭐ (golden copy)
```

**Fuente de golden copies:**
```
pipeline_2/HTML_VIEWERS_FINALES/figures_paso2_CLEAN/
├── FIG_2.13_DENSITY_HEATMAP_ALS.png
├── FIG_2.14_DENSITY_HEATMAP_CONTROL.png
└── FIG_2.15_DENSITY_COMBINED.png
```

### 📋 Tablas:
```
step2/outputs/tables/
├── TABLE_2.6_*.csv (análisis posicional)
├── TABLE_2.7_*.csv (PCA/PERMANOVA)
├── TABLE_2.9_*.csv (CV analysis)
├── TABLE_2.10_*.csv (G>T ratios)
├── TABLE_2.11_*.csv (mutation spectrum)
└── TABLE_2.12_*.csv (enrichment/biomaps)
```

### ▶️ Cómo ejecutar:
```bash
cd pipeline_definitivo
Rscript step2/run_step2.R
```

---

## 📚 DOCUMENTACIÓN PRINCIPAL

### 📄 Documentos Maestros:
```
pipeline_definitivo/
├── ORGANIZACION_PIPELINE.md  ⭐ (Estructura completa y reglas)
├── BITACORA_PIPELINE.md  ⭐ (Registro de cambios)
└── RESUMEN_ORGANIZACION_PIPELINE.md  ⭐ (Este documento)
```

### 📄 Documentos Adicionales (muchos en `pipeline_definitivo/`):
- `README.md` - Guía general
- `INVENTARIO_COMPLETO_PIPELINE.md` - Inventario de archivos
- `ESTADO_PIPELINE_COMPLETO.md` - Estado actual

---

## 🎯 RUTA RÁPIDA: CÓMO EJECUTAR TODO

### Paso 1:
```bash
cd pipeline_definitivo/STEP1_ORGANIZED
Rscript RUN_COMPLETE_PIPELINE_PASO1.R
# Ver: STEP1_ORGANIZED/STEP1_FINAL.html
```

### Paso 1.5:
```bash
cd pipeline_definitivo/01.5_vaf_quality_control
Rscript scripts/01_apply_vaf_filter.R
Rscript scripts/02_generate_diagnostic_figures.R
# Ver: 01.5_vaf_quality_control/STEP1.5_VAF_QC_VIEWER.html
```

### Paso 2:
```bash
cd pipeline_definitivo
Rscript step2/run_step2.R
# Ver: step2/viewers/STEP2_EMBED.html
```

---

## 📍 RESUMEN VISUAL DE VIEWERS

| Paso | McCarthy Viewer | Ubicación |
|------|----------------|-----------|
| **1** | `STEP1_FINAL.html` | `STEP1_ORGANIZED/STEP1_FINAL.html` |
| **1.5** | `STEP1.5_VAF_QC_VIEWER.html` | `01.5_vaf_quality_control/STEP1.5_VAF_QC_VIEWER.html` |
| **2** | `STEP2_EMBED.html` ⭐ | `step2/viewers/STEP2_EMBED.html` |

---

## 🔑 PUNTOS CLAVE

1. **Paso 1:** Estructura en `STEP1_ORGANIZED/`, viewer en raíz de esa carpeta
2. **Paso 1.5:** Estructura en `01.5_vaf_quality_control/`, scripts en subcarpeta `scripts/`
3. **Paso 2:** Estructura estandarizada en `step2/`, con `run_step2.R` como orquestador
4. **Golden copies (2.13-2.15):** Se sincronizan automáticamente desde `pipeline_2/HTML_VIEWERS_FINALES/`
5. **Documentación:** Siempre revisar `ORGANIZACION_PIPELINE.md` para estructura actualizada

---

**Última actualización:** 2025-01-28

