# 🗺️ MAPA COMPLETO DEL PIPELINE - ORGANIZACIÓN OFICIAL

**Fecha:** 27 Enero 2025  
**Propósito:** Mapa COMPLETO y DEFINITIVO de TODO el pipeline

---

## 🎯 **ESTRUCTURA OFICIAL CONSOLIDADA**

```
pipeline_definitivo/
│
├── ✅ PASO 1: EXPLORATORY ANALYSIS
│   📁 STEP1_ORGANIZED/  ⭐ CARPETA OFICIAL
│
├── ✅ PASO 1.5: VAF QUALITY CONTROL
│   📁 01.5_vaf_quality_control/  ⭐ CARPETA OFICIAL
│
├── ✅ PASO 2: GROUP COMPARISONS (ALS vs Control)
│   📁 pipeline_2/  ⭐ CARPETA OFICIAL
│
├── ⏳ PASO 2.5: SEED REGION ANALYSIS
│   📁 pipeline_2.5/  (en revisión)
│
├── ⏳ PASO 2.6: SEQUENCE MOTIFS
│   📁 pipeline_2.6_sequence_motifs/  (en revisión)
│
├── ⏳ PASO 3: FUNCTIONAL ANALYSIS
│   📁 pipeline_3/  (en revisión)
│
└── 🗑️ ARCHIVOS LEGACY (NO USAR)
    📁 01_analisis_inicial/  (versiones antiguas)
    📁 results_threshold_*/  (tests viejos)
```

---

## ✅ **PASO 1: EXPLORATORY ANALYSIS** (CONSOLIDADO)

### **📁 Ubicación Oficial:**

```
STEP1_ORGANIZED/  ⭐⭐⭐

CONTENIDO:
  ├── 🌐 STEP1_FINAL.html  ← HTML viewer
  ├── 📄 STEP1_FINAL_SUMMARY.md  ← Documentación principal
  ├── 📁 figures/  ← 8 figuras finales
  │   ├── step1_panelA_dataset_overview.png
  │   ├── step1_panelB_gt_count_by_position.png
  │   ├── step1_panelC_gx_spectrum.png
  │   ├── step1_panelD_positional_fraction.png
  │   ├── step1_panelE_FINAL_BUBBLE.png  ⭐
  │   ├── step1_panelF_seed_interaction.png
  │   ├── step1_panelG_gt_specificity.png
  │   └── step1_panelH_sequence_context.png
  ├── 📁 scripts/  ← Scripts R (solo Panel E disponible)
  └── 📁 documentation/  ← Docs técnicos
```

### **8 Figuras del Paso 1:**

| Panel | Nombre | Qué Muestra | Archivo |
|-------|--------|-------------|---------|
| A | Dataset Overview | Evolution (raw→split→collapse) | `step1_panelA_*.png` |
| B | G>T Count by Position | Counts absolutos (pos 1-23) | `step1_panelB_*.png` |
| C | G>X Mutation Spectrum | G>T, G>C, G>A por posición | `step1_panelC_*.png` |
| D | Positional Fraction | Enrichment por posición | `step1_panelD_*.png` |
| E | G-Content Landscape | Bubble plot 3D ⭐ | `step1_panelE_FINAL_BUBBLE.png` |
| F | Seed Interaction | Seed vs non-seed | `step1_panelF_*.png` |
| G | G>T Specificity | vs otras G transversions | `step1_panelG_*.png` |
| H | Sequence Context | Nucleótidos adyacentes | `step1_panelH_*.png` |

### **Status:**

```
✅ Figuras: 8/8 generadas y consolidadas
✅ HTML viewer: STEP1_FINAL.html funcional
✅ Documentación: STEP1_FINAL_SUMMARY.md clara
⚠️  Scripts: Solo Panel E disponible (otros faltan)
❌ Master script: NO existe (pendiente crear)
```

### **Acceso Rápido:**

```bash
# Ver figuras
open STEP1_ORGANIZED/STEP1_FINAL.html

# Leer documentación
open STEP1_ORGANIZED/STEP1_FINAL_SUMMARY.md

# Symlink (atajo)
open STEP1_VIEWER.html  → STEP1_ORGANIZED/STEP1_FINAL.html
```

---

## ✅ **PASO 1.5: VAF QUALITY CONTROL** (CONSOLIDADO)

### **📁 Ubicación Oficial:**

```
01.5_vaf_quality_control/  ⭐⭐⭐

CONTENIDO:
  ├── 🌐 STEP1.5_VAF_QC_VIEWER.html  ← HTML viewer
  ├── 📄 README.md  ← Documentación completa ⭐
  ├── 📄 STEP1.5_CHANGELOG.md
  ├── 📄 filter_vaf_threshold.R  ← MASTER SCRIPT (todo-en-uno)
  ├── 📁 data/
  │   ├── ALL_MUTATIONS_VAF_FILTERED.csv  ← OUTPUT principal
  │   └── vaf_filter_report.csv  ← Log de filtrado
  └── 📁 figures/  ← 10 figuras QC
      ├── QC_FIG1_VAF_DISTRIBUTION.png
      ├── QC_FIG2_FILTER_IMPACT.png
      ├── QC_FIG3_BEFORE_AFTER.png
      ├── STEP1.5_FIG1_HEATMAP_SNVS.png
      ├── STEP1.5_FIG2_HEATMAP_COUNTS.png
      ├── STEP1.5_FIG3_G_TRANSVERSIONS_SNVS.png
      ├── STEP1.5_FIG4_G_TRANSVERSIONS_COUNTS.png
      ├── STEP1.5_FIG5_BUBBLE_PLOT.png
      ├── STEP1.5_FIG6_VIOLIN_DISTRIBUTIONS.png
      └── STEP1.5_FIG7_FOLD_CHANGE.png
```

### **10 Figuras del Paso 1.5:**

| Tipo | Figura | Qué Muestra |
|------|--------|-------------|
| QC | QC_FIG1 | VAF distribution (filtered values) |
| QC | QC_FIG2 | Filter impact by mutation type |
| QC | QC_FIG3 | Before vs After filtering |
| Diagnostic | FIG1 | SNVs Heatmap (VAF-filtered) |
| Diagnostic | FIG2 | Counts Heatmap (VAF-filtered) |
| Diagnostic | FIG3 | G Transversions SNVs |
| Diagnostic | FIG4 | G Transversions Counts |
| Diagnostic | FIG5 | Bubble Plot |
| Diagnostic | FIG6 | Violin Distributions |
| Diagnostic | FIG7 | Fold Change |

### **Status:**

```
✅✅ Figuras: 10/10 generadas
✅✅ HTML viewer: Funcional y bien diseñado
✅✅ Documentación: README.md excelente
✅✅ Script: filter_vaf_threshold.R (todo-en-uno)
✅✅ Master script: SÍ existe (genera las 10 figuras)
✅✅ Pipeline: 100% automatizado

CALIDAD: ⭐⭐⭐ EXCELENTE
```

### **Acceso Rápido:**

```bash
# Ver figuras
open 01.5_vaf_quality_control/STEP1.5_VAF_QC_VIEWER.html

# Leer documentación
open 01.5_vaf_quality_control/README.md

# Ejecutar pipeline
cd 01.5_vaf_quality_control/
Rscript filter_vaf_threshold.R

# Symlink (atajo)
open STEP1.5_VIEWER.html  → 01.5_vaf_quality_control/STEP1.5_VAF_QC_VIEWER.html
```

---

## ✅ **PASO 2: GROUP COMPARISONS** (CONSOLIDADO)

### **📁 Ubicación Oficial:**

```
pipeline_2/  ⭐⭐⭐

CONTENIDO:
  ├── 🌐 PASO_2_VIEWER_COMPLETO_FINAL.html  ← HTML viewer oficial
  │
  ├── 📄 DOCUMENTACIÓN (5 archivos):
  │   ├── PIPELINE_PASO2_100_COMPLETO.md  ⭐ Resumen ejecutivo
  │   ├── ORGANIZACION_15_FIGURAS_COMPLETA.md  ⭐⭐ Guía principal
  │   ├── TABLA_RESUMEN_15_FIGURAS.md  (referencia rápida)
  │   ├── QUE_ES_EL_PIPELINE_EXPLICACION.md  (técnico)
  │   └── DIAGRAMA_PIPELINE_VISUAL.md  (diagramas)
  │
  ├── 📄 RUN_COMPLETE_PIPELINE_PASO2.R  ← MASTER SCRIPT
  │
  ├── 📄 15 SCRIPTS INDIVIDUALES:
  │   ├── generate_FIG_2.1_COMPARISON_LOG_VS_LINEAR.R
  │   ├── generate_FIG_2.2_SIMPLIFIED.R
  │   ├── generate_FIG_2.3_CORRECTED_AND_ANALYZE.R
  │   ├── generate_FIG_2.4_HEATMAP_RAW.R
  │   ├── generate_FIG_2.5_ZSCORE_ALL301.R
  │   ├── generate_FIG_2.6_POSITIONAL.R
  │   ├── generate_FIG_2.7_IMPROVED.R
  │   ├── generate_FIG_2.8_CLUSTERING.R
  │   ├── generate_FIG_2.9_IMPROVED.R
  │   ├── generate_FIG_2.10_GT_RATIO.R
  │   ├── generate_FIG_2.11_IMPROVED.R
  │   ├── generate_FIG_2.12_ENRICHMENT.R
  │   └── generate_FIG_2.13-15_DENSITY.R  (genera 3)
  │
  ├── 📁 figures/  ← 15 figuras finales
  └── 📁 figures_paso2_CLEAN/  ← Archivos intermedios
```

### **15 Figuras del Paso 2:**

| Grupo | Figuras | Propósito |
|-------|---------|-----------|
| A (Global) | 2.1-2.3 | ¿Hay diferencia? → Control > ALS |
| B (Positional) | 2.4-2.6, 2.13-15 | ¿Dónde? → Hotspots 22-23 |
| C (Heterogeneity) | 2.7-2.9 | ¿Por qué pequeña? → ALS +35% heterogéneo |
| D (Specificity) | 2.10-2.12 | ¿Mecanismo? → Oxidación (Ts/Tv=0.12) |

### **Status:**

```
✅✅✅ Figuras: 15/15 generadas
✅✅✅ HTML viewer: PASO_2_VIEWER_COMPLETO_FINAL.html
✅✅✅ Documentación: 5 archivos MD completos
✅✅✅ Scripts: 15 individuales + 1 master
✅✅✅ Pipeline: 100% automatizado
✅✅✅ Master script: RUN_COMPLETE_PIPELINE_PASO2.R

CALIDAD: ⭐⭐⭐ EXCELENTE (mejor de los 3)
```

### **Acceso Rápido:**

```bash
# Ver figuras
open pipeline_2/PASO_2_VIEWER_COMPLETO_FINAL.html

# Leer documentación principal
open pipeline_2/ORGANIZACION_15_FIGURAS_COMPLETA.md

# Ejecutar pipeline completo
cd pipeline_2/
Rscript RUN_COMPLETE_PIPELINE_PASO2.R
```

---

## ⏳ **PASOS ADICIONALES (EN REVISIÓN)**

### **PASO 2.5: Seed Region Analysis**

```
📁 pipeline_2.5/

CONTENIDO:
  ├── 🌐 PASO_2.5_PATRONES.html
  ├── 📄 PLAN_PASO_2.5.md
  ├── 📄 RUN_PASO2.5_PRIORITARIOS.R  ← Script principal
  ├── 📁 data/
  ├── 📁 figures/  (~13 figuras)
  └── 📁 scripts/

STATUS:
  ⏳ Requiere revisión y consolidación
  ⏳ Integrar con pipeline principal
```

---

### **PASO 2.6: Sequence Motifs**

```
📁 pipeline_2.6_sequence_motifs/

CONTENIDO:
  ├── 🌐 VIEWER_SEQUENCE_LOGOS.html
  ├── 📄 README_PASO_2.6.md
  ├── 📄 RUN_PASO_2.6_COMPLETE.R  ← Master script
  ├── 📄 01_download_mirbase_sequences.R
  ├── 📄 02_create_sequence_logos.R
  ├── 📁 data/
  └── 📁 figures/  (sequence logos)

STATUS:
  ⏳ Requiere revisión
  ✅ Tiene master script
```

---

### **PASO 3: Functional Analysis**

```
📁 pipeline_3/

CONTENIDO:
  ├── 🌐 PASO_3_VIEWER.html
  └── ... (otros archivos)

STATUS:
  ⏳ En desarrollo
```

---

## 🗑️ **CARPETAS LEGACY (NO USAR)**

### **01_analisis_inicial/ - VERSIONES ANTIGUAS**

```
CONTENIDO:
  • ~40 archivos MD (resúmenes viejos)
  • ~8 HTMLs (versiones antiguas)
  • Scripts dispersos y no consolidados
  • Múltiples versiones de las mismas figuras

PROBLEMA:
  ⚠️  Redundante con STEP1_ORGANIZED/
  ⚠️  No está organizado
  ⚠️  Confuso (múltiples versiones)

RECOMENDACIÓN:
  🗑️ ARCHIVAR o ELIMINAR
  ✅ Usar STEP1_ORGANIZED/ en su lugar
```

---

## 📊 **RESUMEN DE CONSOLIDACIÓN**

```
┌──────────┬──────────────────┬──────────┬─────────┬──────────┐
│ Paso     │ Carpeta Oficial  │ Figuras  │ Scripts │ Status   │
├──────────┼──────────────────┼──────────┼─────────┼──────────┤
│ 1        │ STEP1_ORGANIZED  │ 8/8 ✅   │ 1/8 ⚠️  │ PARCIAL  │
│ 1.5      │ 01.5_vaf_qc      │ 10/10 ✅ │ 1/1 ✅  │ COMPLETO │
│ 2        │ pipeline_2       │ 15/15 ✅ │ 15/15 ✅│ COMPLETO │
│ 2.5      │ pipeline_2.5     │ ~13 ⏳   │ ? ⏳    │ REVISAR  │
│ 2.6      │ pipeline_2.6     │ 3 ⏳     │ 2/2 ✅  │ REVISAR  │
│ 3        │ pipeline_3       │ ? ⏳     │ ? ⏳    │ REVISAR  │
├──────────┼──────────────────┼──────────┼─────────┼──────────┤
│ TOTAL    │ 6 carpetas       │ 33+ ✅   │ Varies  │ MIXTO    │
└──────────┴──────────────────┴──────────┴─────────┴──────────┘

LEGACY:
  🗑️ 01_analisis_inicial/  (NO USAR)
  🗑️ results_threshold_*/   (NO USAR)
```

---

## 🎯 **ESTRUCTURA RECOMENDADA FINAL**

### **Carpetas a MANTENER:**

```
✅ STEP1_ORGANIZED/             (Paso 1)
✅ 01.5_vaf_quality_control/    (Paso 1.5)
✅ pipeline_2/                  (Paso 2) ⭐ MEJOR ORGANIZADO
⏳ pipeline_2.5/                (revisar y consolidar)
⏳ pipeline_2.6_sequence_motifs/ (revisar y consolidar)
⏳ pipeline_3/                  (revisar y consolidar)
```

### **Carpetas a ARCHIVAR:**

```
🗑️ 01_analisis_inicial/  → Mover a ARCHIVE/
🗑️ results_threshold_*/   → Mover a ARCHIVE/
```

---

## 📝 **DOCUMENTACIÓN POR PASO**

### **PASO 1:**

```
📄 PRINCIPAL:
   STEP1_ORGANIZED/STEP1_FINAL_SUMMARY.md

📄 ADICIONALES:
   STEP1_ORGANIZED/documentation/STEP1_README.md
   
🌐 VIEWER:
   STEP1_ORGANIZED/STEP1_FINAL.html
```

### **PASO 1.5:**

```
📄 PRINCIPAL:
   01.5_vaf_quality_control/README.md  ⭐⭐

🌐 VIEWER:
   01.5_vaf_quality_control/STEP1.5_VAF_QC_VIEWER.html
```

### **PASO 2:**

```
📄 PRINCIPALES:
   pipeline_2/ORGANIZACION_15_FIGURAS_COMPLETA.md  ⭐⭐
   pipeline_2/PIPELINE_PASO2_100_COMPLETO.md
   
📄 REFERENCIA:
   pipeline_2/TABLA_RESUMEN_15_FIGURAS.md
   
📄 TÉCNICOS:
   pipeline_2/QUE_ES_EL_PIPELINE_EXPLICACION.md
   pipeline_2/DIAGRAMA_PIPELINE_VISUAL.md
   
🌐 VIEWER:
   pipeline_2/PASO_2_VIEWER_COMPLETO_FINAL.html  ⭐
```

---

## 🚀 **CÓMO USAR EL PIPELINE COMPLETO**

### **Paso a Paso:**

```
PASO 1: Exploratory Analysis (SIN grupos)
  ❌ NO hay master script aún
  ✅ Figuras ya generadas en STEP1_ORGANIZED/figures/
  👀 Ver: STEP1_FINAL.html

PASO 1.5: VAF QC (Filtro técnico)
  ✅ Master script: filter_vaf_threshold.R
  📂 Input: step1_original_data.csv
  📤 Output: ALL_MUTATIONS_VAF_FILTERED.csv
  ⏱️  Tiempo: ~2 minutos
  👀 Ver: STEP1.5_VAF_QC_VIEWER.html

PASO 2: Group Comparisons (ALS vs Control)
  ✅ Master script: RUN_COMPLETE_PIPELINE_PASO2.R
  📂 Input: final_processed_data_CLEAN.csv + metadata.csv
  📤 Output: 15 figuras en figures/
  ⏱️  Tiempo: ~3-5 minutos
  👀 Ver: PASO_2_VIEWER_COMPLETO_FINAL.html
```

---

## 🎯 **ACCIÓN: REGISTRAR PASO 2 COMO CONSOLIDADO**

### **Documento Oficial Creado:**

```
📄 REGISTRO_OFICIAL_PASO_2_CONSOLIDADO.md

CERTIFICA:
  ✅ 15/15 figuras completas
  ✅ Pipeline 100% funcional
  ✅ Documentación completa
  ✅ Listo para producción
  
FECHA: 27 Enero 2025
VERSION: 1.0.0 FINAL
```

---

## 🔍 **PRÓXIMOS PASOS SUGERIDOS**

```
ACCIÓN 1: Completar Paso 1
  → Crear scripts para panels A-D, F-H (faltan 7)
  → Crear master script (RUN_COMPLETE_PIPELINE_PASO1.R)
  → Consolidar documentación

ACCIÓN 2: Revisar Paso 2.5
  → Validar figuras
  → Consolidar scripts
  → Crear documentación estilo Paso 2

ACCIÓN 3: Revisar Paso 2.6
  → Ya tiene master script
  → Validar outputs
  → Integrar con pipeline principal

ACCIÓN 4: Limpiar Archivos Legacy
  → Archivar 01_analisis_inicial/
  → Eliminar duplicados
  → Mantener solo carpetas oficiales
```

---

## 📋 **CHECKLIST DE ORGANIZACIÓN**

```
PASO 1:
  ✅ Figuras consolidadas (8/8)
  ✅ HTML viewer funcional
  ✅ Documentación clara
  ❌ Scripts completos (1/8)
  ❌ Master script
  
PASO 1.5:
  ✅✅✅ TODO CONSOLIDADO Y FUNCIONAL

PASO 2:
  ✅✅✅ TODO CONSOLIDADO Y FUNCIONAL
  ✅✅✅ REGISTRADO OFICIALMENTE (27/01/25)

PASOS 2.5-3:
  ⏳ Requieren revisión
```

---

**¿Quieres que ahora:**
1. **Creemos los scripts faltantes del Paso 1** (7 scripts + master)? 🔧
2. **Revisemos y consolidemos Paso 2.5**? 📊
3. **Limpiemos carpetas legacy** (archivar 01_analisis_inicial/)? 🗑️

**¿Qué prefieres hacer primero?** 🎯

