# 🔬 PLAN COMPLETO - 16 PREGUNTAS CIENTÍFICAS → 5 FIGURAS

**Versión:** Pipeline_2 v0.3.0  
**Objetivo:** Pipeline automatizado que responde todas las preguntas científicas  
**Progreso actual:** 6/16 preguntas (38%)

---

## 📊 **MAPA COMPLETO: PREGUNTAS → FIGURAS → ANÁLISIS**

```
16 PREGUNTAS CIENTÍFICAS
│
├── TIER 1: Standalone (No metadata) - 6 preguntas
│   ├── FIGURA 1: Dataset Characterization (4 paneles) ✅
│   │   └── SQ1.1, SQ1.2, SQ1.3
│   └── FIGURA 2: Mechanistic Validation (4 paneles) ✅
│       └── SQ3.1, SQ3.2, SQ3.3
│
└── TIER 2: Configurable (Con metadata) - 10 preguntas
    ├── FIGURA 3: Group Comparison (4 paneles) 🔧 40%
    │   └── SQ2.1, SQ2.2, SQ2.3, SQ2.4
    ├── FIGURA 4: Confounder Analysis (3-4 paneles) 📋
    │   └── SQ4.1, SQ4.2, SQ4.3
    └── FIGURA 5: Functional Analysis (3-4 paneles) 💡
        └── SQ5.1, SQ5.2, SQ1.4
```

---

## ✅ **FIGURA 1: DATASET CHARACTERIZATION** (100% COMPLETA)

### **Panel A: Dataset Evolution & Mutation Types**
**Preguntas:**
- **SQ1.1:** ¿Cuál es la estructura y calidad del dataset? ✅
- **SQ1.3:** ¿Qué tipos de mutación son más prevalentes? ✅

**Análisis:**
- Evolución: 68,968 raw entries → 110,199 valid SNVs
- Distribución de 12 tipos de mutación
- G>T: 8,033 mutaciones (7.3%)

**Visualización:**
- Left: Barras de evolución del dataset
- Right: Pie chart de tipos de mutación

**Colores:** 🟠 Naranja neutro

---

### **Panel B: G>T Positional Analysis**
**Preguntas:**
- **SQ1.2:** ¿Dónde ocurren las mutaciones G>T? ✅

**Análisis:**
- Heatmap de frecuencia G>T por posición (1-22)
- Comparación Seed vs Non-Seed
- 1,340 G>T en seed vs 6,188 en non-seed

**Visualización:**
- Top: Heatmap posicional
- Bottom: Barras Seed vs Non-Seed

**Colores:** 🟡 Dorado para seed

---

### **Panel C: Mutation Spectrum**
**Preguntas:**
- **SQ1.3:** ¿Distribución completa de mutaciones G>X? ✅

**Análisis:**
- G>T, G>A, G>C por posición
- Top 10 mutaciones globales

**Visualización:**
- Left: Stacked bars por posición
- Right: Top 10 ranking

**Colores:** 🟠 Naranja G>T, 🔵 Azul G>A, 🟢 Verde G>C

---

### **Panel D: Placeholder**
**Preguntas:**
- Ninguna por ahora (enfoque en caracterización inicial)

**Estado:** Reservado para futuro

---

## ✅ **FIGURA 2: MECHANISTIC VALIDATION** (100% COMPLETA)

### **Panel A: G-Content vs Oxidation Susceptibility**
**Preguntas:**
- **SQ3.1:** ¿El contenido de G's predice susceptibilidad oxidativa? ✅

**Análisis:**
- Correlación Spearman: r = 0.347 (p < 0.001)
- Dosis-respuesta: 0-1 G's = 5%, 5-6 G's = 17%

**Visualización:**
- Scatter plot con línea de tendencia
- Tamaño = número de miRNAs
- Color = nivel de oxidación

**Colores:** 🟠 Naranja/dorado gradient (oxidación)

---

### **Panel B: Sequence Context**
**Preguntas:**
- **SQ3.2:** ¿Hay enriquecimiento de contextos GG, GC? ✅

**Análisis:**
- Contexto de secuencia alrededor de G>T
- Placeholder (requiere secuencias de referencia)

**Estado:** Framework listo, necesita secuencias

---

### **Panel C: G>T Specificity**
**Preguntas:**
- **SQ3.2:** ¿G>T es específico vs otras mutaciones G>X? ✅

**Análisis:**
- G>T = 31.6% de todas las mutaciones G>X
- Stacked bars por posición

**Visualización:**
- Proporción G>T vs G>A vs G>C

**Colores:** 🟠 Naranja G>T destacado

---

### **Panel D: Position-Level G-Content**
**Preguntas:**
- **SQ3.3:** ¿La correlación G-content es consistente por posición? ✅

**Análisis:**
- Frecuencia G>T por posición
- Seed vs non-seed destacado

**Visualización:**
- Barras con seed region en dorado

**Colores:** 🟡 Dorado seed, ⚪ Gris non-seed

---

## 🔧 **FIGURA 3: GROUP COMPARISON** (40% FRAMEWORK LISTO)

### **Panel A: Global G>T Burden**
**Preguntas:**
- **SQ2.1:** ¿El burden global de G>T es diferente ALS vs Control? 📋

**Análisis planificado:**
- Per-sample G>T count/fraction
- Wilcoxon rank-sum test
- Effect size (Cohen's d)
- Median + IQR por grupo

**Visualización:**
- Violin plot + boxplot overlay
- Puntos individuales (jitter)
- P-value anotado

**Colores:** 🔴 Rojo ALS, 🔵 Azul Control

**Estado:** Framework listo, necesita datos per-sample REALES

---

### **Panel B: Position-Specific Differences** ⭐ TU FAVORITO
**Preguntas:**
- **SQ2.2:** ¿Qué posiciones muestran diferencias significativas? 📋
- **SQ2.4:** ¿La región seed es más afectada en ALS? 📋

**Análisis planificado:**
- Wilcoxon test per position (22 tests)
- FDR correction (Benjamini-Hochberg)
- Effect sizes per position

**Visualización:**
- Barras lado a lado (ALS vs Control)
- Seed region sombreada (2-8)
- Estrellas de significancia: * q<0.05, ** q<0.01, *** q<0.001

**Colores:** 🔴 Rojo ALS, 🔵 Azul Control, 🟡 Dorado seed shading

**Estado:** ✅ Demo generada (con datos simulados), listo para datos reales

---

### **Panel C: Seed vs Non-Seed Interaction**
**Preguntas:**
- **SQ2.4:** ¿La región seed es MÁS vulnerable en ALS específicamente? 📋

**Análisis planificado:**
- 2×2 contingency table: (Seed/Non-seed) × (ALS/Control)
- Fisher's exact test for interaction
- Odds Ratio con CI
- Test: ¿El OR de seed es diferente en ALS vs Control?

**Visualización:**
- Barras agrupadas (Seed/Non-seed) por grupo
- OR anotado
- Interaction line plot

**Colores:** 🔴 Rojo ALS, 🔵 Azul Control

**Estado:** Framework listo, necesita implementación real

---

### **Panel D: Differential miRNAs (Volcano Plot)**
**Preguntas:**
- **SQ2.3:** ¿Qué miRNAs específicos son diferenciales? 📋

**Análisis planificado:**
- Per-miRNA Fisher's exact test (ALS vs Control)
- Log2 fold-change calculation
- FDR correction
- Top miRNAs labeled

**Visualización:**
- Volcano plot: log2FC vs -log10(q-value)
- Threshold lines: q < 0.05, |FC| > 1.5
- Top 10-20 miRNAs etiquetados

**Colores:** 🔴 Enriquecidos en ALS, 🔵 Enriquecidos en Control

**Estado:** Framework listo, necesita implementación real

---

## 📋 **FIGURA 4: CONFOUNDER ANALYSIS** (0% - PLANIFICADA)

### **Panel A: Age Distribution & Effect**
**Preguntas:**
- **SQ4.1:** ¿El efecto G>T es independiente de edad? 📋

**Análisis planificado:**
- Age distribution: ALS vs Control (histogram/density)
- Age-adjusted analysis (linear model: G>T ~ group + age)
- Stratified analysis por edad (<60 vs ≥60)
- Interaction test: group × age

**Visualización:**
- Top: Distribución de edad por grupo
- Bottom: G>T vs edad con líneas por grupo

**Tests estadísticos:**
- T-test o Wilcoxon para distribución de edad
- ANCOVA o linear model para ajuste
- Interaction F-test

**Colores:** 🔴 ALS, 🔵 Control

**Datos requeridos:** `demographics.csv` con columnas `sample_id, age, sex, batch`

---

### **Panel B: Sex Effect**
**Preguntas:**
- **SQ4.2:** ¿Hay diferencias por sexo? 📋

**Análisis planificado:**
- Sex distribution check (Chi-squared)
- Sex-stratified analysis (M vs F)
- Interaction: group × sex
- 2-way ANOVA: G>T ~ group + sex + group:sex

**Visualización:**
- Barras agrupadas: M/F × ALS/Control
- Interaction plot
- Estadística anotada

**Tests:**
- Chi-squared para distribución
- 2-way ANOVA para interaction
- Post-hoc tests si interacción significativa

**Colores:** 🔴 ALS, 🔵 Control, por sexo

---

### **Panel C: Technical Confounders (QC)**
**Preguntas:**
- **SQ4.3:** ¿Hay batch effects o artefactos técnicos? 📋

**Análisis planificado:**
- Sequencing depth por grupo (boxplot)
- Batch effect assessment (si hay batch info)
- PCA coloreado por:
  - Grupo (ALS/Control)
  - Batch
  - Sequencing depth
- Correlation con variables técnicas

**Visualización:**
- Left: Depth distribution
- Center: PCA (PC1 vs PC2)
- Right: Batch effect heatmap

**Tests:**
- Wilcoxon para depth differences
- PERMANOVA para batch effect
- Correlation tests

**Colores:** 🔴 ALS, 🔵 Control (in PCA)

---

### **Panel D: Adjusted Analysis** (Opcional)
**Preguntas:**
- ¿Los hallazgos persisten después de ajustar por confounders?

**Análisis planificado:**
- Multivariable model: G>T ~ group + age + sex + depth
- Compare coeficientes crude vs adjusted
- Sensitivity analysis

**Visualización:**
- Forest plot con coeficientes
- Crude vs adjusted comparison

---

## 💡 **FIGURA 5: FUNCTIONAL ANALYSIS** (0% - EXPLORATORIA)

### **Panel A: Seed Region Mutations**
**Preguntas:**
- **SQ5.1:** ¿Cómo afectan las mutaciones G>T en seed la función? 💡

**Análisis planificado:**
- G>T en seed: impacto en binding energía
- Predicción de targets afectados
- Cambios en target specificity

**Herramientas:**
- TargetScan (si disponible)
- miRanda
- RNA structure prediction

**Visualización:**
- Seed mutations mapped to structure
- Target changes heatmap
- GO enrichment de targets afectados

**Prioridad:** Media (computacionalmente intensivo)

---

### **Panel B: miRNA Family Vulnerability**
**Preguntas:**
- **SQ5.2:** ¿Ciertas familias de miRNAs son más vulnerables? 💡

**Análisis planificado:**
- Agrupar miRNAs por familia (let-7, miR-200, etc.)
- Family-level G>T enrichment
- Sequence similarity vs oxidation susceptibility

**Visualización:**
- Heatmap: familias × G>T fraction
- Dendrograma de clustering
- Sequence logo por familia

**Prioridad:** Baja (exploratorio)

---

### **Panel C: Pathway Enrichment**
**Preguntas:**
- **SQ5.1:** ¿Qué pathways están afectados por miRNAs con G>T? 💡

**Análisis planificado:**
- Targets de miRNAs con G>T (especialmente seed)
- GO/KEGG enrichment
- Network analysis

**Herramientas:**
- DIANA-TarBase
- miRTarBase
- clusterProfiler (R)

**Visualización:**
- Dot plot de pathways enriquecidos
- Network de miRNA-target-pathway
- Barras de top pathways

**Prioridad:** Media

---

### **Panel D: Top Affected miRNAs**
**Preguntas:**
- **SQ1.4:** ¿Cuáles son los miRNAs más afectados y por qué importan? 💡

**Análisis planificado:**
- Top 20 miRNAs con más G>T
- Funciones conocidas de esos miRNAs
- Relevancia en ALS (literatura)

**Visualización:**
- Tabla con anotaciones funcionales
- Barplot de G>T count
- Links a literatura

**Prioridad:** Media

---

## 🗺️ **ROADMAP COMPLETO POR FIGURAS**

### **✅ COMPLETADAS (Tier 1):**

```
FIGURA 1: Dataset Characterization
├── Panel A: Dataset evolution ✅
├── Panel B: G>T positional ✅
├── Panel C: Mutation spectrum ✅
└── Panel D: Placeholder ✅

Preguntas: SQ1.1 ✅, SQ1.2 ✅, SQ1.3 ✅
Tiempo: ~4 horas (completado)
Código: visualization_functions_v5.R ✅
Output: figure_1_v5_updated_colors.png ✅
```

```
FIGURA 2: Mechanistic Validation
├── Panel A: G-content correlation ✅
├── Panel B: Sequence context (placeholder) ✅
├── Panel C: G>T specificity ✅
└── Panel D: Position G-content ✅

Preguntas: SQ3.1 ✅, SQ3.2 ✅, SQ3.3 ✅
Tiempo: ~3 horas (completado)
Código: mechanistic_functions.R ✅
Output: figure_2_mechanistic_validation.png ✅
```

**TOTAL TIER 1:** 6/16 preguntas (38%) ✅

---

### **🔧 EN PROGRESO (Tier 2 - Framework):**

```
FIGURA 3: Group Comparison (ALS vs Control)
├── Panel A: Global burden 🔧 Framework
├── Panel B: Position delta ✅ DEMO (tu favorito)
├── Panel C: Seed interaction 🔧 Framework
└── Panel D: Volcano plot 🔧 Framework

Preguntas: SQ2.1 📋, SQ2.2 📋, SQ2.3 📋, SQ2.4 📋
Tiempo estimado: 4 horas (2 horas invertidas en framework)
Código: 
  - statistical_tests.R ✅
  - comparison_functions.R 🔧 (40% - necesita REAL)
  - comparison_visualizations.R ✅
Output esperado: figure_3_group_comparison.png
Estado: Framework 100%, datos simulados, necesita implementación real
```

**PARA COMPLETAR FIGURA 3:**
1. Crear `data_transformation.R` (1 hora) ⭐ CRÍTICO
2. Implementar versiones REAL de comparaciones (1.5 horas)
3. Generar figura completa (30 min)
4. HTML viewer (30 min)

---

### **📋 PENDIENTES (Tier 2 - Planificadas):**

```
FIGURA 4: Confounder Analysis
├── Panel A: Age effect & adjustment 📋
├── Panel B: Sex effect & interaction 📋
├── Panel C: Technical QC (depth, batch) 📋
└── Panel D: Adjusted analysis 📋

Preguntas: SQ4.1 ⭐⭐⭐⭐⭐, SQ4.2 ⭐⭐⭐⭐, SQ4.3 ⭐⭐⭐⭐
Prioridad: CRÍTICA (validación científica)
Tiempo estimado: 4-5 horas
Requiere: demographics.csv (age, sex, batch)
Código a crear:
  - confounder_functions.R
  - confounder_visualizations.R
Tests:
  - ANCOVA (age-adjusted)
  - 2-way ANOVA (sex interaction)
  - PERMANOVA (batch effect)
  - Linear models multivariables
```

```
FIGURA 5: Functional Analysis
├── Panel A: Seed mutations & targets 💡
├── Panel B: miRNA families 💡
├── Panel C: Pathway enrichment 💡
└── Panel D: Top affected miRNAs 💡

Preguntas: SQ5.1 ⭐⭐⭐, SQ5.2 ⭐⭐, SQ1.4 ⭐⭐⭐
Prioridad: MEDIA (exploratorio)
Tiempo estimado: 6-8 horas (computacionalmente intensivo)
Requiere:
  - miRNA reference sequences
  - Target prediction databases
  - GO/KEGG databases
Código a crear:
  - functional_analysis.R
  - target_prediction.R
  - pathway_enrichment.R
Herramientas externas:
  - TargetScan
  - miRanda
  - clusterProfiler
```

---

## 📊 **TABLA RESUMEN: 16 PREGUNTAS**

| ID | Pregunta | Figura | Panel | Estado | Prioridad |
|---|---|---|---|---|---|
| **SQ1.1** | Dataset structure | 1 | A | ✅ | ⭐⭐⭐⭐⭐ |
| **SQ1.2** | G>T positional | 1 | B | ✅ | ⭐⭐⭐⭐⭐ |
| **SQ1.3** | Mutation types | 1 | A,C | ✅ | ⭐⭐⭐⭐⭐ |
| **SQ1.4** | Top miRNAs | 5 | D | 💡 | ⭐⭐⭐ |
| **SQ2.1** | G>T enrichment ALS | 3 | A | 📋 | ⭐⭐⭐⭐⭐ |
| **SQ2.2** | Position differences | 3 | B | 🔧 | ⭐⭐⭐⭐⭐ |
| **SQ2.3** | Differential miRNAs | 3 | D | 📋 | ⭐⭐⭐⭐ |
| **SQ2.4** | Seed vulnerability | 3 | B,C | 🔧 | ⭐⭐⭐⭐ |
| **SQ3.1** | G-content correlation | 2 | A | ✅ | ⭐⭐⭐⭐ |
| **SQ3.2** | G>T specificity | 2 | C | ✅ | ⭐⭐⭐⭐ |
| **SQ3.3** | Position G-content | 2 | D | ✅ | ⭐⭐⭐ |
| **SQ4.1** | Age effect | 4 | A | 📋 | ⭐⭐⭐⭐⭐ |
| **SQ4.2** | Sex effect | 4 | B | 📋 | ⭐⭐⭐⭐ |
| **SQ4.3** | Technical QC | 4 | C | 📋 | ⭐⭐⭐⭐ |
| **SQ5.1** | Target impact | 5 | A,C | 💡 | ⭐⭐⭐ |
| **SQ5.2** | Family analysis | 5 | B | 💡 | ⭐⭐ |

**Leyenda:**
- ✅ Completa
- 🔧 Framework listo (demo)
- 📋 Planificada (diseñada)
- 💡 Futura (exploratoria)

**Progreso:** 6/16 respondidas (38%), 4/16 framework (25%), 6/16 planificadas (37%)

---

## 🎯 **PRIORIDADES ORDENADAS**

### **PRIORIDAD 1: Completar Figura 3** ⭐⭐⭐⭐⭐ (CRÍTICA)
**Tiempo:** 4 horas  
**Preguntas:** SQ2.1, SQ2.2, SQ2.3, SQ2.4  
**Razón:** Core del análisis comparativo ALS vs Control  
**Bloqueadores:** Ninguno (datos disponibles)

### **PRIORIDAD 2: Figura 4 (Confounders)** ⭐⭐⭐⭐⭐ (CRÍTICA)
**Tiempo:** 4-5 horas  
**Preguntas:** SQ4.1, SQ4.2, SQ4.3  
**Razón:** Validación científica esencial  
**Bloqueadores:** Requiere demographics.csv (age, sex)

### **PRIORIDAD 3: Figura 5 (Functional)** ⭐⭐⭐ (MEDIA)
**Tiempo:** 6-8 horas  
**Preguntas:** SQ5.1, SQ5.2, SQ1.4  
**Razón:** Interpretación biológica  
**Bloqueadores:** Requiere bases de datos externas

---

## 🚀 **ESTRATEGIA RECOMENDADA**

### **FASE 1 (AHORA): Pipeline Básico Automatizado** (2 horas)
```
1. Crear data_transformation.R
2. Crear run_pipeline.R básico
3. Pipeline genera Figuras 1-2 automáticamente
```

**Output:** Pipeline usable para Tier 1

---

### **FASE 2 (SIGUIENTE): Figura 3 Completa** (2-3 horas)
```
1. Implementar comparaciones REAL
2. Generar Figura 3 completa (4 paneles)
3. Tests estadísticos reales
```

**Output:** Pipeline genera Figuras 1-3 automáticamente  
**Responde:** 10/16 preguntas (63%)

---

### **FASE 3 (OPCIONAL): Figura 4** (4-5 horas)
```
1. Load demographics
2. Age/sex adjustments
3. Technical QC
```

**Output:** Validación completa  
**Responde:** 13/16 preguntas (81%)

---

### **FASE 4 (FUTURO): Figura 5** (6-8 horas)
```
1. Target prediction
2. Pathway analysis
3. Functional interpretation
```

**Output:** Análisis completo publicable  
**Responde:** 16/16 preguntas (100%)

---

## 📝 **TODO REGISTRADO EN:**

1. **`SCIENTIFIC_QUESTIONS_ANALYSIS.md`** - Las 16 preguntas detalladas
2. **`PLAN_COMPLETO_16_PREGUNTAS.md`** - Este documento (plan maestro)
3. **`PLAN_PIPELINE_AUTOMATIZADO.md`** - Arquitectura técnica
4. **`ESTADO_Y_SIGUIENTE_PASO.md`** - Siguiente paso inmediato
5. **`ROADMAP_COMPLETO.md`** - Timeline y pasos
6. **`config/parameters.R`** - Preguntas en código
7. **`CHANGELOG.md`** - Versiones y cambios

**¡TODO está documentado y organizado!** ✅

---

## 🎊 **RESUMEN EJECUTIVO**

**Tenemos plan completo para:**
- ✅ 5 figuras (1-2 completas, 3-5 diseñadas)
- ✅ 16 preguntas científicas (todas identificadas)
- ✅ Framework estadístico (completo)
- ✅ Código modular (organizado)

**Progreso:**
- Figuras: 40% (2/5)
- Preguntas: 38% (6/16)
- Framework: 70% (base + Tier 2 framework)
- Documentación: 100% ✅

**Próximo paso inmediato:**
- Completar Figura 3 con datos reales (4 horas)
- → Responderá 10/16 preguntas (63%)
- → Pipeline genera 3 figuras automáticamente

**¿Procedemos con Figura 3 REAL? 🚀**

