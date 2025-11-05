# 📊 ORGANIZACIÓN COMPLETA - 15 FIGURAS DEL PASO 2

**Fecha:** 27 Enero 2025  
**Objetivo:** Explicar la LÓGICA detrás de la organización de las figuras

---

## 🎯 **ESTRUCTURA LÓGICA**

Las 15 figuras están organizadas en **4 GRUPOS** que responden preguntas específicas:

```
┌─────────────────────────────────────────────────────────────────┐
│  PASO 2: ALS vs Control Group Comparisons                      │
│  Pregunta Principal: ¿Hay diferencias en G>T burden?           │
└─────────────────────────────────────────────────────────────────┘
         │
         ├─→ GRUPO A: ¿HAY DIFERENCIA GLOBAL? (3 figuras)
         ├─→ GRUPO B: ¿DÓNDE OCURREN LAS DIFERENCIAS? (6 figuras)
         ├─→ GRUPO C: ¿QUÉ TAN HETEROGÉNEOS SON? (3 figuras)
         └─→ GRUPO D: ¿QUÉ MECANISMOS Y QUÉ VALIDAR? (3 figuras)
```

---

## 📋 **GRUPO A: GLOBAL COMPARISONS** (3 figuras)

### **Pregunta Principal:**
> ¿Hay diferencia global en G>T burden entre ALS y Control?

### **Figuras:**

```
┌──────────────────────────────────────────────────────────────────┐
│ Fig 2.1: VAF Comparison (Linear Scale)                          │
├──────────────────────────────────────────────────────────────────┤
│ Script: generate_FIG_2.1_COMPARISON_LOG_VS_LINEAR.R             │
│ Output: FIG_2.1_VAF_COMPARISON_LINEAR.png                       │
│                                                                  │
│ QUÉ MUESTRA:                                                     │
│   • Violin plots (ALS vs Control)                               │
│   • Boxplots superpuestos                                       │
│   • Stats: Wilcoxon test, t-test, Cohen's d                     │
│   • Comparación directa de burden global                        │
│                                                                  │
│ HALLAZGO:                                                        │
│   ⚠️  Control > ALS (p < 0.001)                                 │
│   → Hipótesis invertida (esperábamos ALS > Control)             │
│                                                                  │
│ DATOS USADOS:                                                    │
│   • TODO el dataset (5,448 SNVs)                                │
│   • Suma total de VAF per sample                                │
│   • 313 ALS samples vs 102 Control samples                      │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ Fig 2.2: VAF Distributions                                      │
├──────────────────────────────────────────────────────────────────┤
│ Script: generate_FIG_2.2_SIMPLIFIED.R                           │
│ Output: FIG_2.2_DISTRIBUTIONS_LINEAR.png                        │
│                                                                  │
│ QUÉ MUESTRA:                                                     │
│   • Panel A: Violin plots detallados                            │
│   • Panel B: Density plots (curvas suaves)                      │
│   • Panel C: CDF (Cumulative Distribution Function)             │
│                                                                  │
│ HALLAZGO:                                                        │
│   • Distribuciones significativamente diferentes                │
│   • Control shifted hacia VAF más altos                         │
│   • Confirma resultado de Fig 2.1                               │
│                                                                  │
│ DATOS USADOS:                                                    │
│   • Mismo que Fig 2.1 (total VAF per sample)                    │
│   • Análisis de distribución completa                           │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ Fig 2.3: Volcano Plot - Differential miRNAs                     │
├──────────────────────────────────────────────────────────────────┤
│ Script: generate_FIG_2.3_CORRECTED_AND_ANALYZE.R                │
│ Output: FIG_2.3_VOLCANO_COMBINADO.png                           │
│                                                                  │
│ QUÉ MUESTRA:                                                     │
│   • Log2(Fold Change) vs -log10(FDR)                            │
│   • Fisher's exact test PER miRNA                               │
│   • FDR correction (Benjamini-Hochberg)                         │
│   • 301 miRNAs significantes destacados (puntos rojos/azules)   │
│                                                                  │
│ HALLAZGO:                                                        │
│   🔥 301 miRNAs DIFERENCIALES (FDR < 0.05)                      │
│   • ~150 enriquecidos en ALS                                    │
│   • ~150 enriquecidos en Control                                │
│   • Patrón bidireccional (no simple "ALS más alto")             │
│                                                                  │
│ DATOS USADOS:                                                    │
│   • Contingency tables per miRNA (ALS vs Control)               │
│   • 620 miRNAs analizados                                       │
│   • Fisher's exact test × 620                                   │
└──────────────────────────────────────────────────────────────────┘

RESUMEN GRUPO A:
  ✅ Establece que HAY diferencias globales
  ✅ Identifica QUÉ miRNAs son diferenciales
  ✅ Cuantifica magnitud y significancia
```

---

## 📍 **GRUPO B: POSITIONAL ANALYSIS** (6 figuras)

### **Pregunta Principal:**
> ¿DÓNDE ocurren las diferencias? ¿Hay hotspots? ¿Seed enriquecida?

### **Figuras:**

```
┌──────────────────────────────────────────────────────────────────┐
│ Fig 2.4: Heatmap RAW (Absolute VAF Values)                     │
├──────────────────────────────────────────────────────────────────┤
│ Script: generate_FIG_2.4_HEATMAP_RAW.R                          │
│ Output: FIG_2.4_HEATMAP_ALL.png                                 │
│                                                                  │
│ QUÉ MUESTRA:                                                     │
│   • 301 miRNAs (filas) × 23 positions (columnas)                │
│   • 2 paneles: ALS | Control                                    │
│   • Valores VAF ABSOLUTOS (raw, sin normalizar)                 │
│   • Color: Plasma (purple-yellow-orange)                        │
│   • Sqrt scale (para visibilidad de VAF bajos)                  │
│                                                                  │
│ INTERPRETACIÓN:                                                  │
│   • Muestra MAGNITUD real de G>T en cada posición               │
│   • Identifica miRNAs con alto burden (top filas)               │
│   • Compara visualmente ALS vs Control                          │
│                                                                  │
│ DATOS USADOS:                                                    │
│   • 301 miRNAs con G>T en seed                                  │
│   • TODAS sus posiciones (1-23)                                 │
│   • 1,377 SNVs totales                                          │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ Fig 2.5: Heatmap Z-Score (Normalized, Outlier Detection) ⭐     │
├──────────────────────────────────────────────────────────────────┤
│ Script: generate_FIG_2.5_ZSCORE_ALL301.R                        │
│ Output: FIG_2.5_ZSCORE_HEATMAP.png                              │
│                                                                  │
│ QUÉ MUESTRA:                                                     │
│   • MISMOS datos que Fig 2.4 (301 × 23)                         │
│   • PERO: Normalizado POR miRNA (Z-score)                       │
│   • 2 paneles: ALS | Control                                    │
│   • Color: Blue-White-Red (divergente)                          │
│                                                                  │
│ DIFERENCIA CON FIG 2.4:                                          │
│   Fig 2.4: Muestra valores ABSOLUTOS                            │
│   Fig 2.5: Muestra valores RELATIVOS (al promedio del miRNA)    │
│                                                                  │
│ INTERPRETACIÓN:                                                  │
│   • Z > 2: Posición ANORMALMENTE ALTA para ese miRNA            │
│   • Z < -2: Posición ANORMALMENTE BAJA para ese miRNA           │
│   • Identifica OUTLIERS posicionales                            │
│   • Independiente de magnitud absoluta                          │
│                                                                  │
│ HALLAZGO:                                                        │
│   • 100 outliers detectados                                     │
│   • Hotspots: positions 21-23 (94 outliers en non-seed!)        │
│   • Seed region: Solo 6 outliers (NO enriquecida)               │
│                                                                  │
│ COMPLEMENTARIEDAD:                                               │
│   Fig 2.4 responde: "¿Cuánto hay?"                              │
│   Fig 2.5 responde: "¿Qué es atípico?" ⭐                        │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ Fig 2.6: Positional Profiles (Line Plots with CI)               │
├──────────────────────────────────────────────────────────────────┤
│ Script: generate_FIG_2.6_POSITIONAL.R                           │
│ Output: FIG_2.6_POSITIONAL_ANALYSIS.png                         │
│                                                                  │
│ QUÉ MUESTRA:                                                     │
│   • Line plot: Position (x-axis) vs Mean VAF (y-axis)           │
│   • 2 líneas: ALS (roja) y Control (azul)                       │
│   • Ribbons: 95% confidence intervals                           │
│   • Seed region sombreada (background azul claro)               │
│                                                                  │
│ INTERPRETACIÓN:                                                  │
│   • Perfil posicional PROMEDIADO                                │
│   • Muestra tendencias a través de posiciones                   │
│   • CI muestra incertidumbre                                    │
│                                                                  │
│ HALLAZGO:                                                        │
│   • Control > ALS en mayoría de posiciones                      │
│   • Hotspots: 22, 23, 20                                        │
│   • Seed ratio: 0.08 (NO enriquecida)                           │
│                                                                  │
│ COMPLEMENTARIEDAD:                                               │
│   Fig 2.4: Heatmap individual (detalle)                         │
│   Fig 2.5: Outliers (anomalías)                                 │
│   Fig 2.6: Trends (promedio general) ⭐                          │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ Figs 2.13-2.15: Density Heatmaps                               │
├──────────────────────────────────────────────────────────────────┤
│ Script: generate_FIG_2.13-15_DENSITY.R (genera las 3)           │
│ Outputs:                                                         │
│   • FIG_2.13_DENSITY_HEATMAP_ALS.png                            │
│   • FIG_2.14_DENSITY_HEATMAP_CONTROL.png                        │
│   • FIG_2.15_DENSITY_COMBINED.png                               │
│                                                                  │
│ QUÉ MUESTRAN:                                                    │
│   • Panel superior: Barplot de SNV count por posición           │
│   • Panel inferior: Heatmap de VAF distribution                 │
│                                                                  │
│ ESTRUCTURA DEL HEATMAP:                                          │
│   X-axis: Position (1-23)                                       │
│   Y-axis: VAF bins (0-0.001, 0.001-0.01, ... >0.2)             │
│   Color: N de SNVs en ese bin                                   │
│                                                                  │
│ INTERPRETACIÓN:                                                  │
│   • Barplot → CANTIDAD de SNVs (density)                        │
│   • Heatmap → DISTRIBUCIÓN de VAF values                        │
│   • Vertical gradient → mayoría SNVs tienen VAF bajo            │
│                                                                  │
│ HALLAZGO:                                                        │
│   • Position 22: 7,986 SNVs (hotspot mayor)                     │
│   • ALS: 43,312 SNVs totales                                    │
│   • Control: 18,579 SNVs totales                                │
│   • Hotspots COMPARTIDOS (22-23 en ambos grupos)                │
│                                                                  │
│ COMPLEMENTARIEDAD:                                               │
│   Figs 2.4-2.6: Promedios y patrones                            │
│   Figs 2.13-15: Distribuciones COMPLETAS ⭐                      │
│   → Muestra heterogeneidad dentro de cada posición              │
└──────────────────────────────────────────────────────────────────┘

RESUMEN GRUPO B:
  ✅ Responde: ¿DÓNDE están las diferencias?
  ✅ Identifica: Hotspots (positions 22-23)
  ✅ Analiza: Seed vs non-seed (NO enrichment)
  ✅ Muestra: Distribuciones completas (no solo means)
```

---

## 🔬 **GRUPO C: HETEROGENEITY ANALYSIS** (3 figuras)

### **Pregunta Principal:**
> ¿Qué tan variables son los datos? ¿Hay subtipos de ALS?

### **Figuras:**

```
┌──────────────────────────────────────────────────────────────────┐
│ Fig 2.7: PCA + PERMANOVA                                        │
├──────────────────────────────────────────────────────────────────┤
│ Script: generate_FIG_2.7_IMPROVED.R                             │
│ Output: FIG_2.7_PCA_PERMANOVA.png                               │
│                                                                  │
│ QUÉ MUESTRA:                                                     │
│   • Panel A: PCA scatter (PC1 vs PC2)                           │
│   • Panel B: Variance explained (scree plot)                    │
│   • Panel C: PERMANOVA stats table                              │
│   • Puntos: ALS (rojo) vs Control (azul)                        │
│                                                                  │
│ ANÁLISIS:                                                        │
│   PCA = Principal Component Analysis                            │
│   → Reduce dimensionalidad (1,377 SNVs → 2 PCs)                │
│   → Visualiza similitud entre samples                           │
│                                                                  │
│   PERMANOVA = Test de separación de grupos                      │
│   → ¿Grupos significativamente separados?                       │
│                                                                  │
│ HALLAZGO:                                                        │
│   🔥 98% de variación es INDIVIDUAL (R² = 2%)                   │
│   • PERMANOVA: p > 0.05 (NO significativo)                      │
│   • Grupos NO claramente separados                              │
│   • Variación individual DOMINA                                 │
│                                                                  │
│ DATOS USADOS:                                                    │
│   • Matrix: 415 samples × 1,377 SNVs                            │
│   • PCA sobre matriz completa                                   │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ Fig 2.8: Hierarchical Clustering                                │
├──────────────────────────────────────────────────────────────────┤
│ Script: generate_FIG_2.8_CLUSTERING.R                           │
│ Output: FIG_2.8_CLUSTERING.png                                  │
│                                                                  │
│ QUÉ MUESTRA:                                                     │
│   • Heatmap con dendrogramas (row + column)                     │
│   • Clustering jerárquico de samples                            │
│   • Top 100 SNVs más variables                                  │
│   • Row-scaled (Z-score per SNV)                                │
│   • Annotation bar: ALS (rojo) vs Control (azul)                │
│                                                                  │
│ ANÁLISIS:                                                        │
│   • Ward.D2 clustering method                                   │
│   • Euclidean distance                                          │
│   • Identifica si samples similares agrupan juntos              │
│                                                                  │
│ HALLAZGO:                                                        │
│   • NO clustering perfecto por grupo                            │
│   • ALS y Control mezclados en dendrograma                      │
│   • Consistente con PCA (alta variación individual)             │
│                                                                  │
│ DATOS USADOS:                                                    │
│   • Top 100 SNVs más variables (por variance)                   │
│   • 415 samples                                                 │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ Fig 2.9: Coefficient of Variation (CV) Analysis ⭐⭐             │
├──────────────────────────────────────────────────────────────────┤
│ Script: generate_FIG_2.9_IMPROVED.R                             │
│ Output: FIG_2.9_COMBINED_IMPROVED.png                           │
│                                                                  │
│ QUÉ MUESTRA:                                                     │
│   • Panel A: Mean VAF con error bars                            │
│   • Panel B: CV distributions (violin)                          │
│   • Panel C: CV vs Mean scatter (correlation)                   │
│   • Panel D: Top variable miRNAs (barplot)                      │
│                                                                  │
│ ANÁLISIS:                                                        │
│   CV = (SD / Mean) × 100                                        │
│   → Mide HETEROGENEIDAD relativa                                │
│   → CV alto = muy variable entre samples                        │
│   → CV bajo = consistente entre samples                         │
│                                                                  │
│   TESTS:                                                         │
│   • F-test: ¿Variancias diferentes?                             │
│   • Levene's test: ¿Homogeneidad?                               │
│   • Wilcoxon: ¿Medianas diferentes?                             │
│   • Correlation: CV ~ Mean                                      │
│                                                                  │
│ HALLAZGO:                                                        │
│   🔥🔥 ALS 35% MÁS HETEROGÉNEO que Control                      │
│   • CV_ALS = 1015% vs CV_Control = 753%                         │
│   • F-test: p = 9.45e-08 ***                                    │
│   • Levene: p = 5.39e-05 ***                                    │
│   • Correlation CV~Mean: r = -0.33 (p < 1e-13)                  │
│                                                                  │
│   IMPLICACIÓN:                                                   │
│   → Subtipos de ALS (heterogeneidad clínica)                    │
│   → Medicina personalizada necesaria                            │
│   → Explica PCA R² = 2% (variabilidad individual)               │
│                                                                  │
│ DATOS USADOS:                                                    │
│   • VAF per miRNA (averaged across samples)                     │
│   • 620 miRNAs                                                  │
│   • CV calculado per miRNA per group                            │
└──────────────────────────────────────────────────────────────────┘

RESUMEN GRUPO B:
  ✅ Mapea diferencias a POSICIONES específicas
  ✅ Identifica hotspots (22-23)
  ✅ Analiza distribuciones completas (no solo means)
  ✅ Muestra que seed NO está enriquecida
  
  COMPLEMENTARIEDAD:
    Fig 2.4: "¿Cuánto hay?" (absolutos)
    Fig 2.5: "¿Qué es raro?" (outliers)
    Fig 2.6: "¿Cuál es el trend?" (promedios)
    Figs 2.13-15: "¿Cómo se distribuye?" (densities)
```

---

## 🎲 **GRUPO C CONTINUACIÓN**

```
RESUMEN GRUPO C:
  ✅ Cuantifica heterogeneidad DENTRO de grupos
  ✅ Responde: ¿Por qué diferencia global es pequeña?
  ✅ Hallazgo clave: ALS 35% más heterogéneo
  ✅ Implicación: Subtipos de ALS, medicina personalizada
```

---

## 🔍 **GRUPO D: SPECIFICITY & ENRICHMENT** (3 figuras)

### **Pregunta Principal:**
> ¿Es oxidación específica? ¿Qué mecanismos? ¿Qué miRNAs validar?

### **Figuras:**

```
┌──────────────────────────────────────────────────────────────────┐
│ Fig 2.10: G>T Ratio (G>T Specificity)                          │
├──────────────────────────────────────────────────────────────────┤
│ Script: generate_FIG_2.10_GT_RATIO.R                            │
│ Output: FIG_2.10_COMBINED.png                                   │
│                                                                  │
│ QUÉ MUESTRA:                                                     │
│   • Panel A: Global ratio (G>T / todas G>X)                     │
│   • Panel B: Positional ratio (por posición)                    │
│   • Panel C: Seed vs non-seed ratio                             │
│   • Panel D: Mutation breakdown (G>T, G>A, G>C)                 │
│                                                                  │
│ ANÁLISIS:                                                        │
│   G>X = G>T + G>A + G>C (todas las mutaciones desde G)         │
│   Ratio = G>T / G>X                                             │
│   → ¿Qué fracción de mutaciones G son específicamente G>T?      │
│                                                                  │
│ HALLAZGO:                                                        │
│   • G>T = 87% de todas G>X (DOMINANTE)                          │
│   • Control más específico: 88.6% vs ALS 86.1%                  │
│   • Consistente en todas las posiciones                         │
│                                                                  │
│ INTERPRETACIÓN:                                                  │
│   → 8-oxoG (oxidación) es mecanismo PRINCIPAL                   │
│   → Otras mutaciones G (G>A, G>C) son minoritarias              │
│                                                                  │
│ DATOS USADOS:                                                    │
│   • Todas las mutaciones G>X                                    │
│   • Comparación count-based y VAF-weighted                      │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ Fig 2.11: Complete Mutation Spectrum ⭐⭐⭐                       │
├──────────────────────────────────────────────────────────────────┤
│ Script: generate_FIG_2.11_IMPROVED.R                            │
│ Output: FIG_2.11_COMBINED_IMPROVED.png                          │
│                                                                  │
│ QUÉ MUESTRA:                                                     │
│   • Panel A: 5 categorías biológicas (simplified)               │
│   • Panel B: G mutations only (G>T, G>A, G>C)                   │
│   • Panel C: Ts/Tv ratio explanation                            │
│   • Panel D: Top 10 mutation types                              │
│                                                                  │
│ 5 CATEGORÍAS BIOLÓGICAS:                                         │
│   1. G>T (Oxidation) - Orange/Red                               │
│   2. Other G>X (G>A + G>C) - Teal                               │
│   3. C>T (Deamination) - Pink                                   │
│   4. Transitions (A↔G, T↔C) - Green                             │
│   5. Other Transversions - Gray                                 │
│                                                                  │
│ HALLAZGOS CRÍTICOS:                                              │
│   🔥🔥🔥 MÚLTIPLES HALLAZGOS MAYORES:                            │
│                                                                  │
│   1. G>T DOMINANTE: 71-74% del burden total                     │
│      → Hipótesis oxidativa CONFIRMADA                           │
│                                                                  │
│   2. SPECTRUM DIFERENTE: Chi² = 217, p < 2e-16                  │
│      → ALS y Control perfiles mutacionales DISTINTOS            │
│      → ALS enriquecido: T>A, A>G, G>C                           │
│      → Control más puro en oxidación (74.2% vs 71.0%)           │
│                                                                  │
│   3. Ts/Tv INVERTIDO: 0.12 vs normal 2.0-2.5                    │
│      → PRUEBA: NO es envejecimiento normal                      │
│      → Envejecimiento: Transitions dominan (C>T mayormente)     │
│      → Aquí: Transversions dominan (G>T específicamente)        │
│      → ES daño oxidativo ESPECÍFICO                             │
│                                                                  │
│   4. C>T (Deamination) MÍNIMA: 3%                               │
│      → En aging normal: C>T = 20-30%                            │
│      → Aquí: C>T = 3% (10x menor)                               │
│      → CONFIRMA: NO es aging signature                          │
│                                                                  │
│ DATOS USADOS:                                                    │
│   • LOS 12 TIPOS DE MUTACIONES (no solo G>T)                    │
│   • 5,448 SNVs completos                                        │
│   • Chi-square test for independence                            │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ Fig 2.12: Enrichment Analysis & Biomarker Identification       │
├──────────────────────────────────────────────────────────────────┤
│ Script: generate_FIG_2.12_ENRICHMENT.R                          │
│ Output: FIG_2.12_COMBINED.png                                   │
│                                                                  │
│ QUÉ MUESTRA:                                                     │
│   • Panel A: Top miRNAs (ranked by burden)                      │
│   • Panel B: Top miRNA families (enrichment)                    │
│   • Panel C: Positional hotspots (barplot)                      │
│   • Panel D: Biomarker candidates (filtered)                    │
│                                                                  │
│ CRITERIOS DE SELECCIÓN:                                          │
│   Biomarker candidates deben tener:                             │
│   ✅ High burden (top tercile)                                  │
│   ✅ Low CV (< 1000%, confiables)                               │
│   ✅ High N (> 50 samples, representativos)                     │
│                                                                  │
│ HALLAZGO:                                                        │
│   🔥 112 BIOMARKER CANDIDATES identificados                     │
│                                                                  │
│   TOP 5 PARA VALIDACIÓN:                                        │
│   1. hsa-miR-432-5p  (burden=149, CV=145%)                      │
│   2. hsa-miR-584-5p  (burden=123, CV=88%) ⭐ Más confiable      │
│   3. hsa-miR-152-3p  (burden=72, CV=133%)                       │
│   4. hsa-miR-6129    (burden=44, CV=25%) ⭐ MÁS reliable        │
│   5. hsa-miR-503-5p  (burden=41, CV=52%)                        │
│                                                                  │
│   FAMILIAS ENRIQUECIDAS:                                         │
│   • 123 miRNA families identificadas                            │
│   • Positional hotspots: 22-23                                  │
│                                                                  │
│ DATOS USADOS:                                                    │
│   • 620 miRNAs analizados                                       │
│   • Burden + CV metrics (from Fig 2.9)                          │
│   • Family annotations                                          │
│   • Positional data                                             │
└──────────────────────────────────────────────────────────────────┘

RESUMEN GRUPO D:
  ✅ Caracteriza especificidad de G>T (87% de G>X)
  ✅ Valida mecanismo oxidativo (Ts/Tv invertido)
  ✅ Identifica targets para validación (112 candidates)
  ✅ Prioritiza experimentación (top 5 con mejor reliability)
```

---

## 🗂️ **ORGANIZACIÓN POR PROPÓSITO**

### **Comparación Visual:**

```
ESTABLECER DIFERENCIA GLOBAL:
  → Fig 2.1: Global comparison (statistical test)
  → Fig 2.2: Distributions (shape comparison)
  → Fig 2.3: Differential miRNAs (identify which ones)

MAPEAR ESPACIALMENTE:
  → Fig 2.4: Raw values (absolute magnitudes)
  → Fig 2.5: Z-scores (identify outliers)
  → Fig 2.6: Positional profiles (trends)
  → Figs 2.13-15: Density maps (complete distributions)

CUANTIFICAR HETEROGENEIDAD:
  → Fig 2.7: PCA (multivariate space)
  → Fig 2.8: Clustering (hierarchical structure)
  → Fig 2.9: CV analysis (variability quantification)

CARACTERIZAR MECANISMO:
  → Fig 2.10: G>T specificity
  → Fig 2.11: Complete spectrum (Ts/Tv)
  → Fig 2.12: Validation targets
```

---

## 📊 **MATRIZ DE FIGURAS**

```
┌────────┬─────────────────┬──────────────┬─────────────┬──────────────┐
│ Figura │ Grupo           │ Pregunta     │ Método      │ Hallazgo     │
├────────┼─────────────────┼──────────────┼─────────────┼──────────────┤
│ 2.1    │ A (Global)      │ ¿Diferencia? │ Violin      │ Ctrl > ALS   │
│ 2.2    │ A (Global)      │ ¿Distrib?    │ Density     │ Diferentes   │
│ 2.3    │ A (Global)      │ ¿Cuáles?     │ Volcano     │ 301 miRNAs   │
├────────┼─────────────────┼──────────────┼─────────────┼──────────────┤
│ 2.4    │ B (Positional)  │ ¿Magnitud?   │ Heat RAW    │ Hotspot 22   │
│ 2.5    │ B (Positional)  │ ¿Outliers?   │ Heat Zscore │ 100 outliers │
│ 2.6    │ B (Positional)  │ ¿Trends?     │ Line+CI     │ Ctrl>ALS     │
│ 2.13   │ B (Positional)  │ ¿Density?    │ Heat+bar    │ ALS 43K SNVs │
│ 2.14   │ B (Positional)  │ ¿Density?    │ Heat+bar    │ Ctrl 18K     │
│ 2.15   │ B (Positional)  │ ¿Compare?    │ Combined    │ Same hotspot │
├────────┼─────────────────┼──────────────┼─────────────┼──────────────┤
│ 2.7    │ C (Heterog)     │ ¿Separado?   │ PCA         │ R²=2% (NO)   │
│ 2.8    │ C (Heterog)     │ ¿Clusters?   │ Hclust      │ Mixto        │
│ 2.9    │ C (Heterog)     │ ¿Variable?   │ CV          │ ALS +35% ⭐  │
├────────┼─────────────────┼──────────────┼─────────────┼──────────────┤
│ 2.10   │ D (Specificity) │ ¿G>T ratio?  │ Proportion  │ 87% G>T      │
│ 2.11   │ D (Specificity) │ ¿Spectrum?   │ 12 types    │ Ts/Tv=0.12 ⭐│
│ 2.12   │ D (Specificity) │ ¿Validar?    │ Enrichment  │ 112 cands    │
└────────┴─────────────────┴──────────────┴─────────────┴──────────────┘
```

---

## 🎯 **FLUJO LÓGICO DE PREGUNTAS**

```
PREGUNTA 1: ¿Hay diferencia entre ALS y Control?
  → Figs 2.1-2.3 (Grupo A)
  ✅ RESPUESTA: SÍ (pero Control > ALS, invertido)

PREGUNTA 2: ¿Dónde están las diferencias?
  → Figs 2.4-2.6, 2.13-15 (Grupo B)
  ✅ RESPUESTA: Hotspots en positions 22-23
               NO enriquecida en seed
               
PREGUNTA 3: ¿Por qué diferencia global pequeña?
  → Figs 2.7-2.9 (Grupo C)
  ✅ RESPUESTA: Alta heterogeneidad individual
               ALS especialmente heterogéneo (+35%)
               
PREGUNTA 4: ¿Qué mecanismo? ¿Qué validar?
  → Figs 2.10-2.12 (Grupo D)
  ✅ RESPUESTA: Oxidación específica (Ts/Tv=0.12)
               112 biomarker candidates identificados
```

---

## 📚 **DEPENDENCIAS ENTRE FIGURAS**

```
FIGURAS INDEPENDIENTES (se pueden generar solas):
  • Fig 2.1: Solo necesita sumas globales
  • Fig 2.2: Solo necesita distribuciones
  • Fig 2.4: Solo necesita matrix miRNA×position
  • Fig 2.10: Solo necesita mutations G>X
  • Fig 2.11: Solo necesita todos los mutation types

FIGURAS DEPENDIENTES (necesitan outputs previos):
  • Fig 2.3: Usa Fisher's exact (necesita counts)
  • Fig 2.5: Usa mismo filtro que Fig 2.4 (301 miRNAs)
  • Fig 2.6: Usa stats de Fig 2.4-2.5
  • Fig 2.9: Calcula CV (usado en Fig 2.12)
  • Fig 2.12: Usa CV de Fig 2.9 + volcano de Fig 2.3
  
RECOMENDACIÓN: Ejecutar en orden (2.1 → 2.15)
```

---

## 📁 **ORGANIZACIÓN DE ARCHIVOS**

### **Por Grupo:**

```
GRUPO A (Global Comparisons):
  📄 generate_FIG_2.1_COMPARISON_LOG_VS_LINEAR.R
  📄 generate_FIG_2.2_SIMPLIFIED.R
  📄 generate_FIG_2.3_CORRECTED_AND_ANALYZE.R
  
GRUPO B (Positional Analysis):
  📄 generate_FIG_2.4_HEATMAP_RAW.R
  📄 generate_FIG_2.5_ZSCORE_ALL301.R
  📄 generate_FIG_2.6_POSITIONAL.R
  📄 generate_FIG_2.13-15_DENSITY.R  (genera 3 figuras)
  
GRUPO C (Heterogeneity):
  📄 generate_FIG_2.7_IMPROVED.R
  📄 generate_FIG_2.8_CLUSTERING.R
  📄 generate_FIG_2.9_IMPROVED.R
  
GRUPO D (Specificity):
  📄 generate_FIG_2.10_GT_RATIO.R
  📄 generate_FIG_2.11_IMPROVED.R
  📄 generate_FIG_2.12_ENRICHMENT.R
```

### **Por Output:**

```
figures/                     ← FINALES (para HTML)
  ├── FIG_2.1_*.png
  ├── FIG_2.2_*.png
  └── ... (15 figuras)

figures_paso2_CLEAN/         ← INTERMEDIOS
  ├── FIG_2.X_*.png (todas las versiones)
  ├── Stats tables (CSV)
  ├── Test results
  └── Alternative versions
```

---

## 🎨 **RESUMEN VISUAL**

```
        PASO 2: ALS vs Control G>T Analysis
                     (15 Figuras)
                          │
          ┌───────────────┼───────────────┐
          │               │               │
    ┌─────────┐    ┌─────────┐    ┌─────────┐
    │COMPARAR │    │ MAPEAR  │    │VALIDAR  │
    │(¿HAY?)  │    │(¿DÓNDE?)│    │(¿QUÉ?)  │
    └─────────┘    └─────────┘    └─────────┘
          │               │               │
    ┌─────┴─────┐   ┌─────┴─────┐   ┌─────┴─────┐
    │           │   │           │   │           │
  GRUPO A    GRUPO C GRUPO B    GRUPO D
  (3 figs)   (3 figs)(6 figs)   (3 figs)
    │           │   │           │
    ↓           ↓   ↓           ↓
    
  Global    Heterog Positional  Mechanism
  tests     CV,PCA  heatmaps    spectrum
                    profiles    biomarkers

         ↓
         
    15 FIGURAS PUBLICATION-READY
    Responden TODAS las preguntas del Paso 2
```

---

## 📖 **GUÍA RÁPIDA DE REFERENCIA**

### **Si necesitas saber...**

```
"¿Cuál es la diferencia global?"
  → Fig 2.1 (p < 0.001, Control > ALS)

"¿Qué miRNAs son diferenciales?"
  → Fig 2.3 (301 miRNAs, FDR < 0.05)

"¿En qué posiciones hay más G>T?"
  → Fig 2.6 (hotspots: 22, 23, 20)
  → Figs 2.13-15 (density visualization)

"¿Hay outliers posicionales?"
  → Fig 2.5 (100 outliers, mayoría en 21-23)

"¿Por qué diferencia pequeña?"
  → Fig 2.9 (ALS 35% más heterogéneo)
  → Fig 2.7 (R² = 2%, variación individual)

"¿Es oxidación?"
  → Fig 2.11 (Ts/Tv = 0.12, 71-74% G>T)

"¿Qué validar experimentalmente?"
  → Fig 2.12 (112 candidates, top 5 listados)
```

---

## 🎯 **CONCLUSIÓN: ORGANIZACIÓN PERFECTA**

```
✅ 4 GRUPOS temáticos (A, B, C, D)
✅ 15 FIGURAS complementarias (no redundantes)
✅ FLUJO lógico de preguntas → respuestas
✅ CADA figura tiene propósito específico
✅ CONJUNTO responde pregunta completa del Paso 2

ORGANIZACIÓN:
  📊 Por pregunta científica (grupos A-D)
  📁 Por archivos (scripts separados)
  🌐 Por visualización (HTML viewer)
  📋 Por documentación (este archivo)
```

---

**¿Tiene sentido la organización? ¿Quieres que ajustemos algo?** 🤔

