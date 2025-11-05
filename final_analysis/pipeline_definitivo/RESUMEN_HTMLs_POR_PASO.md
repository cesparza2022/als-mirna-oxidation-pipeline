# 📋 RESUMEN DE HTMLs POR PASO

**Fecha:** 2025-10-20  
**Objetivo:** Revisar contenido de cada paso para reorganización

---

## 🔍 PASO 1: `01_analisis_inicial/`

### **📄 HTML PRINCIPAL:**
- **`STEP1_DIAGNOSTIC_FIGURES_VIEWER.html`**

### **📊 CONTENIDO:**
- **7 Figuras Diagnósticas:**
  1. `STEP1_FIG1_FINAL_HEATMAP_SNVS_TODAS.png` - Heatmap SNVs (todas mutaciones)
  2. `STEP1_FIG2_FINAL_HEATMAP_COUNTS_TODAS.png` - Heatmap Counts (todas mutaciones)
  3. `STEP1_FIG3_FINAL_G_MUTATIONS_SNVS.png` - Mutaciones G (SNVs)
  4. `STEP1_FIG4_FINAL_G_MUTATIONS_COUNTS.png` - Mutaciones G (Counts)
  5. `STEP1_FIG5_FINAL_BUBBLE_SD.png` - Bubble plot (SD)
  6. `STEP1_FIG6_FINAL_VIOLIN_DISTRIBUTIONS.png` - Violin plots
  7. `STEP1_FIG7_FINAL_FOLD_CHANGE_INTEGRATED.png` - Fold Change integrado

### **🎯 PROPÓSITO:**
- **Input:** `step1_original_data.csv` (177 MB, crudo)
- **Proceso:** Split-Collapse (PM/1MM/2MM → agrupar)
- **Output:** Counts limpios (12 tipos, 23 pos)
- **Análisis:** Caracterización inicial del dataset

---

## 🔍 PASO 1.5: `01.5_vaf_quality_control/` ⭐ NUEVO

### **📄 HTML PRINCIPAL:**
- **`STEP1.5_VAF_QC_VIEWER.html`**

### **📊 CONTENIDO:**
- **4 Figuras QC del Filtro VAF:**
  1. `QC_FIG1_VAF_DISTRIBUTION.png` - Distribución VAF
  2. `QC_FIG2_VAF_FILTER_IMPACT.png` - Impacto del filtro
  3. `QC_FIG3_VAF_BY_MUTATION_TYPE.png` - VAF por tipo de mutación
  4. `QC_FIG4_VAF_BY_SAMPLE.png` - VAF por muestra

- **7 Figuras Diagnósticas (VAF-filtered):**
  1. `STEP1.5_FIG1_FINAL_HEATMAP_SNVS_TODAS.png` - Heatmap SNVs (VAF-filtered)
  2. `STEP1.5_FIG2_FINAL_HEATMAP_COUNTS_TODAS.png` - Heatmap Counts (VAF-filtered)
  3. `STEP1.5_FIG3_FINAL_G_MUTATIONS_SNVS.png` - Mutaciones G (VAF-filtered)
  4. `STEP1.5_FIG4_FINAL_G_MUTATIONS_COUNTS.png` - Mutaciones G (VAF-filtered)
  5. `STEP1.5_FIG5_FINAL_BUBBLE_SD.png` - Bubble plot (VAF-filtered)
  6. `STEP1.5_FIG6_FINAL_VIOLIN_DISTRIBUTIONS.png` - Violin plots (VAF-filtered)
  7. `STEP1.5_FIG7_FINAL_FOLD_CHANGE_INTEGRATED.png` - Fold Change (VAF-filtered)

### **🎯 PROPÓSITO:**
- **Input:** `step1_original_data.csv` (necesita totales)
- **Proceso:** VAF Filter (>= 0.5 → NaN)
- **Output:** `ALL_MUTATIONS_VAF_FILTERED.csv` (12 tipos, 23 pos, clean)
- **Análisis:** Quality Control + Diagnóstico (VAF-filtered)

---

## 🔍 PASO 2: `pipeline_2/` (ACTUAL)

### **📄 HTML PRINCIPAL:**
- **`VIEWER_FINAL_COMPLETO.html`**

### **📊 CONTENIDO:**
- **12 Figuras Avanzadas G>T Seed:**
  1. Volcano Plot (Multi-métrico)
  2. Heatmap de correlación
  3. PCA por perfil de mutaciones
  4. Enriquecimiento G>T por miRNA
  5. Boxplot Seed vs Non-Seed
  6. Heatmap posicional G>T
  7. Line plot ALS vs Control
  8. Cumulative distribution G>T
  9. Ridge plot G>T
  10. Clustering de muestras
  11. Análisis de familias miRNA
  12. Contextos trinucleótido

### **🎯 PROPÓSITO:**
- **Input:** Dataset G>T seed (pos 2-8)
- **Proceso:** Análisis avanzado G>T
- **Output:** 12 figuras avanzadas
- **Análisis:** Volcano plots, heatmaps, clustering, selección de candidatos

---

## 🔍 PASO 2.5: `pipeline_2.5/` (ACTUAL)

### **📄 HTML PRINCIPAL:**
- **`PASO_2.5_PATRONES.html`**

### **📊 CONTENIDO:**
- **13 Figuras de Patrones:**
  1. Clustering de muestras (PCA, K-means)
  2. Análisis de familias miRNA
  3. Análisis de secuencias seed
  4. Contextos trinucleótido
  5. Comparaciones ALS vs Control
  6. Análisis de outliers
  7. Análisis temporal
  8. Análisis de metadatos
  9. Análisis de co-mutaciones
  10. Análisis de motivos extendidos
  11. Análisis de conservación
  12. Análisis de enriquecimiento
  13. Análisis de redes

### **🎯 PROPÓSITO:**
- **Input:** Candidatos del Paso 2
- **Proceso:** Análisis de patrones
- **Output:** 13 figuras de patrones
- **Análisis:** Clustering, familias, motivos, contextos, comparaciones

---

## 🔍 PASO 2.6: `pipeline_2.6_sequence_motifs/` (ACTUAL)

### **📄 HTML PRINCIPAL:**
- **`VIEWER_SEQUENCE_LOGOS.html`**

### **📊 CONTENIDO:**
- **4 Sequence Logos:**
  1. `LOGO_Position_2.png` - Logo posición 2
  2. `LOGO_Position_3.png` - Logo posición 3
  3. `LOGO_Position_5.png` - Logo posición 5
  4. `LOGO_ALL_POSITIONS_COMBINED.png` - Logo combinado

- **Análisis de Contextos:**
  - Contextos trinucleótido
  - Conservación de secuencias
  - Motivos GpG (oxidación)
  - Análisis de enriquecimiento

### **🎯 PROPÓSITO:**
- **Input:** Candidatos del Paso 2
- **Proceso:** Análisis de motivos de secuencia
- **Output:** Sequence logos, contextos trinucleótido
- **Análisis:** Motivos GpG, conservación de secuencias

---

## 🔍 PASO 3: `pipeline_3/` (ACTUAL)

### **📄 HTML PRINCIPAL:**
- **`PASO_3_VIEWER_SIMPLE.html`**

### **📊 CONTENIDO:**
- **6 Figuras Funcionales:**
  1. Venn diagram (miRNA targets)
  2. GO enrichment (Biological Process)
  3. GO enrichment (Molecular Function)
  4. KEGG pathway enrichment
  5. Network analysis
  6. Integrated functional analysis

- **Análisis Funcional:**
  - Predicción de targets
  - Enriquecimiento de pathways
  - Análisis de redes
  - Interpretación biológica

### **🎯 PROPÓSITO:**
- **Input:** Candidatos del Paso 2
- **Proceso:** Análisis funcional (targets, pathways, networks)
- **Output:** 6 figuras funcionales
- **Análisis:** Targets, pathways, networks, interpretación biológica

---

## 📊 COMPARACIÓN DE CONTENIDO

### **PASO 1 vs PASO 1.5:**
- **Paso 1:** 7 figuras (datos raw)
- **Paso 1.5:** 4 QC + 7 figuras (VAF-filtered)
- **Diferencia:** Paso 1.5 tiene filtro VAF aplicado

### **PASO 2 vs PASO 2.5 vs PASO 2.6:**
- **Paso 2:** 12 figuras avanzadas G>T
- **Paso 2.5:** 13 figuras de patrones
- **Paso 2.6:** 4 sequence logos
- **Relación:** Secuencial, cada uno profundiza más

### **PASO 3:**
- **Paso 3:** 6 figuras funcionales
- **Propósito:** Interpretación biológica final

---

## 🔧 INTEGRACIÓN NECESARIA

### **CAMBIOS EN `pipeline_2` (futuro Paso 3):**
- **Input actual:** `step1_original_data.csv`
- **Input nuevo:** `ALL_MUTATIONS_VAF_FILTERED.csv` (del nuevo Paso 2)
- **Ventaja:** Ya tiene filtro VAF aplicado, más limpio

### **SCRIPT A MODIFICAR:**
- `pipeline_2/scripts/01_setup_and_verify.R`
- Cambiar path de input
- Verificar que funciona con datos VAF-filtered

---

## 🎯 RECOMENDACIÓN DE REORGANIZACIÓN

### **OPCIÓN A: RENOMBRAR TODO (RECOMENDADA)**
```
01_analisis_inicial/           → Mantener (Paso 1)
01.5_vaf_quality_control/      → 02_vaf_quality_control/ (Paso 2)
pipeline_2/                    → 03_gt_seed_analysis/ (Paso 3)
pipeline_2.5/                  → 04_pattern_analysis/ (Paso 4)
pipeline_2.6_sequence_motifs/  → 05_sequence_motifs/ (Paso 5)
pipeline_3/                    → 06_functional_analysis/ (Paso 6)
```

### **VENTAJAS:**
- ✅ Numeración secuencial clara (01, 02, 03, 04, 05, 06)
- ✅ Flujo lógico evidente
- ✅ Fácil navegación
- ✅ Cada paso tiene propósito claro

### **DESVENTAJAS:**
- ❌ Requiere actualizar referencias en scripts
- ❌ Requiere modificar `pipeline_2` para usar datos VAF-filtered

---

## 🚀 PRÓXIMOS PASOS

1. **Decidir opción de reorganización**
2. **Ejecutar renombrado**
3. **Modificar `pipeline_2` para usar datos VAF-filtered**
4. **Actualizar documentación**
5. **Validar funcionamiento**

---

**¿Cuál opción prefieres para la reorganización?**

