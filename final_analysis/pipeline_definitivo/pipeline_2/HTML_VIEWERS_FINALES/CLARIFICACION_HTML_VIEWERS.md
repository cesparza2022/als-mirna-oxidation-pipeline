# 📊 CLARIFICACIÓN DE HTML VIEWERS - QUÉ CONTIENE CADA UNO

## 🎯 **HTML VIEWERS CORRECTOS POR PASO:**

### **PASO 1: Análisis Inicial Exploratorio**
- **Archivo:** `PASO_1_ANALISIS_INICIAL.html`
- **Contenido:** 11 figuras exploratorias
- **Qué hace:** Análisis inicial del dataset, evolución de datos, tipos de mutaciones, características de miRNAs
- **Datos:** Raw data → Split → Filter PM → Collapse → Wide-to-Long
- **Preguntas:** ¿Cómo evoluciona el dataset? ¿Qué tipos de mutaciones vemos? ¿Cuáles miRNAs son más afectados?

### **PASO 2: Análisis Comparativo Principal**
- **Archivo:** `PASO_2_ANALISIS_COMPARATIVO.html` (633 KB - EL MÁS COMPLETO)
- **Contenido:** 12 figuras comparativas principales
- **Qué hace:** Control de calidad + Comparación ALS vs Control
- **Datos:** Clean data (sin artefactos VAF=0.5) + Método per-sample
- **Preguntas:** ¿Cuáles miRNAs muestran diferencias entre grupos? ¿Es confiable la medición VAF?
- **Resultados:** Solo 3 miRNAs significativamente enriquecidos en ALS

### **PASO 2.5: Análisis Específico Seed G>T**
- **Archivo:** `PASO_2.5_ANALISIS_SEED_GT.html`
- **Contenido:** Análisis específico de miRNAs con G>T en región semilla
- **Qué hace:** Ranking limpio de miRNAs con G>T en seed (posiciones 2-8)
- **Datos:** Solo miRNAs con G>T en seed region, sin artefactos
- **Preguntas:** ¿Cuáles miRNAs son más afectados por G>T en seed? ¿Son biológicamente relevantes?

---

## ❌ **HTML VIEWERS QUE NO DEBES USAR:**

### **FIGURA_1_INDIVIDUAL.html**
- **Problema:** Solo muestra Figura 1 individual, no todo el Paso 1
- **Usar en su lugar:** `PASO_1_ANALISIS_INICIAL.html`

### **FIGURA_2_INDIVIDUAL.html**
- **Problema:** Solo muestra Figura 2 individual, no todo el Paso 2
- **Usar en su lugar:** `PASO_2_ANALISIS_COMPARATIVO.html`

---

## 🎯 **RESUMEN DE QUÉ HACEMOS EN CADA PASO:**

### **PASO 1: EXPLORACIÓN INICIAL**
```
Raw Data → Split Mutations → Filter PM → Collapse → Wide-to-Long
```
**Objetivo:** Entender la estructura y calidad del dataset
**Método:** Análisis exploratorio de todas las mutaciones
**Resultado:** 11 figuras que caracterizan el dataset

### **PASO 2: ANÁLISIS COMPARATIVO**
```
Clean Data → Remove VAF=0.5 Artifacts → Per-Sample Analysis → Statistical Tests
```
**Objetivo:** Comparar ALS vs Control de manera estadísticamente robusta
**Método:** Análisis per-sample (suma VAF de G>T por muestra)
**Resultado:** Solo 3 miRNAs significativamente enriquecidos en ALS

### **PASO 2.5: ANÁLISIS SEED ESPECÍFICO**
```
Filter Seed G>T → Clean Ranking → Validate Candidates
```
**Objetivo:** Enfocarse en mutaciones funcionalmente relevantes (seed region)
**Método:** Solo miRNAs con G>T en posiciones 2-8
**Resultado:** Ranking limpio de candidatos biológicamente relevantes

---

## 📊 **FIGURAS EN CADA PASO:**

### **PASO 1 (11 figuras):**
1. Evolución del dataset (split vs collapse)
2. Distribución de tipos de mutación
3. Características de miRNAs
4. G-content por posición
5. G>X spectrum por posición
6. Comparación seed vs no-seed
7. Distribución de SNVs por miRNA
8. Análisis posicional
9. Características de familias de miRNAs
10. Análisis de densidad
11. Resumen estadístico

### **PASO 2 (12 figuras):**
1. VAF global distributions
2. Volcano plot (per-sample method)
3. Positional heatmaps (top 50 miRNAs)
4. PCA analysis
5. Hierarchical clustering
6. G>T specificity ratios
7. Regional enrichment
8. Sample heterogeneity
9. Quality control plots
10. Statistical validation
11. Effect size analysis
12. Multiple testing correction

### **PASO 2.5 (figuras específicas):**
1. Clean miRNA ranking
2. Seed G>T burden comparison
3. Top candidate validation
4. Biological relevance analysis

---

## 🎯 **RECOMENDACIÓN:**

**Usa solo estos 3 HTML viewers:**
1. **`PASO_1_ANALISIS_INICIAL.html`** - Para Paso 1
2. **`PASO_2_ANALISIS_COMPARATIVO.html`** - Para Paso 2 (el más completo)
3. **`PASO_2.5_ANALISIS_SEED_GT.html`** - Para Paso 2.5

**Ignora:** `FIGURA_1_INDIVIDUAL.html` y `FIGURA_2_INDIVIDUAL.html`
