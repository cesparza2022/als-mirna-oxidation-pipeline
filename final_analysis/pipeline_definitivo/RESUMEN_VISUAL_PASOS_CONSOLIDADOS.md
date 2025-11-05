# 📋 RESUMEN VISUAL DE PASOS CONSOLIDADOS

**Fecha:** 2025-10-20  
**Objetivo:** Revisar contenido consolidado de cada paso

---

## 🔍 PASO 1: `01_analisis_inicial/`

### **📄 HTML PRINCIPAL:**
- **`STEP1_DIAGNOSTIC_FIGURES_VIEWER.html`**

### **📊 CONTENIDO CONSOLIDADO:**
- **7 Figuras Diagnósticas (datos raw):**
  1. **Heatmap SNVs** - Todas las mutaciones por muestra y posición
  2. **Heatmap Counts** - Todas las mutaciones por muestra y posición  
  3. **Mutaciones G (SNVs)** - Solo mutaciones G por muestra y posición
  4. **Mutaciones G (Counts)** - Solo mutaciones G por muestra y posición
  5. **Bubble plot (SD)** - Variabilidad por muestra y posición
  6. **Violin plots** - Distribuciones por tipo de mutación
  7. **Fold Change integrado** - Comparación ALS vs Control

### **🎯 PROPÓSITO:**
- **Input:** `step1_original_data.csv` (177 MB, crudo)
- **Proceso:** Split-Collapse (PM/1MM/2MM → agrupar)
- **Output:** Counts limpios (12 tipos, 23 pos)
- **Análisis:** Caracterización inicial del dataset

---

## 🔍 PASO 1.5: `01.5_vaf_quality_control/` ⭐ NUEVO

### **📄 HTML PRINCIPAL:**
- **`STEP1.5_VAF_QC_VIEWER.html`**

### **📊 CONTENIDO CONSOLIDADO:**
- **4 Figuras QC del Filtro VAF:**
  1. **VAF Distribution** - Distribución de VAF antes del filtro
  2. **VAF Filter Impact** - Impacto del filtro VAF >= 0.5
  3. **VAF by Mutation Type** - VAF por tipo de mutación
  4. **VAF by Sample** - VAF por muestra

- **7 Figuras Diagnósticas (VAF-filtered):**
  1. **Heatmap SNVs** - Todas las mutaciones (VAF-filtered)
  2. **Heatmap Counts** - Todas las mutaciones (VAF-filtered)
  3. **Mutaciones G (SNVs)** - Solo mutaciones G (VAF-filtered)
  4. **Mutaciones G (Counts)** - Solo mutaciones G (VAF-filtered)
  5. **Bubble plot (SD)** - Variabilidad (VAF-filtered)
  6. **Violin plots** - Distribuciones (VAF-filtered)
  7. **Fold Change integrado** - Comparación (VAF-filtered)

### **🎯 PROPÓSITO:**
- **Input:** `step1_original_data.csv` (necesita totales)
- **Proceso:** VAF Filter (>= 0.5 → NaN)
- **Output:** `ALL_MUTATIONS_VAF_FILTERED.csv` (12 tipos, 23 pos, clean)
- **Análisis:** Quality Control + Diagnóstico (VAF-filtered)

---

## 🔍 PASO 2: `pipeline_2/` (ACTUAL)

### **📄 HTML PRINCIPAL:**
- **`VIEWER_FINAL_COMPLETO.html`**

### **📊 CONTENIDO CONSOLIDADO:**
- **12 Figuras Avanzadas G>T Seed:**
  1. **Volcano Plot (Multi-métrico)** - Selección de candidatos
  2. **Heatmap de correlación** - Correlaciones entre miRNAs
  3. **PCA por perfil de mutaciones** - Clustering de muestras
  4. **Enriquecimiento G>T por miRNA** - Análisis de enriquecimiento
  5. **Boxplot Seed vs Non-Seed** - Comparación de regiones
  6. **Heatmap posicional G>T** - Patrones por posición
  7. **Line plot ALS vs Control** - Comparación temporal
  8. **Cumulative distribution G>T** - Distribución acumulada
  9. **Ridge plot G>T** - Distribuciones por muestra
  10. **Clustering de muestras** - Agrupación por similitud
  11. **Análisis de familias miRNA** - Clasificación por familia
  12. **Contextos trinucleótido** - Análisis de contexto

### **🎯 PROPÓSITO:**
- **Input:** Dataset G>T seed (pos 2-8)
- **Proceso:** Análisis avanzado G>T
- **Output:** 12 figuras avanzadas
- **Análisis:** Volcano plots, heatmaps, clustering, selección de candidatos

---

## 🔍 PASO 2.5: `pipeline_2.5/` (ACTUAL)

### **📄 HTML PRINCIPAL:**
- **`PASO_2.5_PATRONES.html`**

### **📊 CONTENIDO CONSOLIDADO:**
- **13 Figuras de Patrones:**
  1. **Clustering de muestras (PCA, K-means)** - Agrupación por similitud
  2. **Análisis de familias miRNA** - Clasificación por familia
  3. **Análisis de secuencias seed** - Patrones en región seed
  4. **Contextos trinucleótido** - Análisis de contexto
  5. **Comparaciones ALS vs Control** - Análisis comparativo
  6. **Análisis de outliers** - Identificación de valores extremos
  7. **Análisis temporal** - Patrones temporales
  8. **Análisis de metadatos** - Correlación con metadatos
  9. **Análisis de co-mutaciones** - Mutaciones simultáneas
  10. **Análisis de motivos extendidos** - Motivos de secuencia
  11. **Análisis de conservación** - Conservación de secuencias
  12. **Análisis de enriquecimiento** - Enriquecimiento funcional
  13. **Análisis de redes** - Redes de interacción

### **🎯 PROPÓSITO:**
- **Input:** Candidatos del Paso 2
- **Proceso:** Análisis de patrones
- **Output:** 13 figuras de patrones
- **Análisis:** Clustering, familias, motivos, contextos, comparaciones

---

## 🔍 PASO 2.6: `pipeline_2.6_sequence_motifs/` (ACTUAL)

### **📄 HTML PRINCIPAL:**
- **`VIEWER_SEQUENCE_LOGOS.html`**

### **📊 CONTENIDO CONSOLIDADO:**
- **4 Sequence Logos:**
  1. **LOGO_Position_2.png** - Logo posición 2
  2. **LOGO_Position_3.png** - Logo posición 3
  3. **LOGO_Position_5.png** - Logo posición 5
  4. **LOGO_ALL_POSITIONS_COMBINED.png** - Logo combinado

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

### **📊 CONTENIDO CONSOLIDADO:**
- **6 Figuras Funcionales:**
  1. **Venn diagram** - Intersección de targets por miRNA
  2. **GO enrichment (Biological Process)** - Procesos biológicos
  3. **GO enrichment (Molecular Function)** - Funciones moleculares
  4. **KEGG pathway enrichment** - Vías metabólicas
  5. **Network analysis** - Redes de interacción
  6. **Integrated functional analysis** - Análisis integrado

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

