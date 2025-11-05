# 🚀 PASO 3: ANÁLISIS FUNCIONAL - PLANIFICACIÓN COMPLETA

**Fecha:** 2025-10-17 02:40
**Estado:** 📋 PLANIFICACIÓN
**Basado en:** Hallazgos del Paso 2 (3 candidatos ALS)

---

## 🎯 OBJETIVO DEL PASO 3

**Enfoque:** Análisis funcional de los **3 miRNAs candidatos ALS** identificados en el Paso 2.

**Candidatos:**
1. ⭐ **hsa-miR-196a-5p** (FC +1.78, p 2.17e-03)
2. **hsa-miR-9-5p** (FC +0.66, p 5.83e-03)
3. **hsa-miR-4746-5p** (FC +0.91, p 2.92e-02)

---

## 📊 PREGUNTAS CLAVE DEL PASO 3

### **1. Análisis de Targets:**
- ¿Qué genes están regulados por estos 3 miRNAs?
- ¿Hay targets validados experimentalmente?
- ¿Cuántos targets predichos tiene cada uno?

### **2. Análisis de Pathways:**
- ¿Qué vías biológicas están enriquecidas?
- ¿Hay relación con estrés oxidativo, neurodegeneración, ALS?
- ¿Hay overlap entre los targets de los 3 miRNAs?

### **3. Contexto Biológico:**
- ¿Qué se sabe de estos miRNAs en la literatura?
- ¿Hay evidencia previa en ALS u otras enfermedades neurodegenerativas?
- ¿Qué procesos celulares regulan?

### **4. Impacto de las Mutaciones G>T:**
- ¿Cómo afectan G>T en seed la unión a targets?
- ¿Hay cambio de targets predichos?
- ¿Pérdida o ganancia de función?

### **5. Integración de Resultados:**
- ¿Cómo se conectan los 3 miRNAs?
- ¿Forman una red funcional coherente?
- ¿Apuntan a procesos comunes?

---

## 📋 ANÁLISIS PROPUESTOS (7 COMPONENTES)

### **COMPONENTE 1: Target Prediction** 🎯
**Objetivo:** Identificar genes regulados por los 3 miRNAs

**Bases de datos a usar:**
- TargetScan (predicción por secuencia)
- miRTarBase (validados experimentalmente)
- miRDB (machine learning)
- DIANA-microT (predicción probabilística)

**Outputs:**
- Lista de targets predichos (por miRNA)
- Lista de targets validados (por miRNA)
- Tabla de overlap entre los 3 miRNAs

**Figuras:**
- 3.1: Venn diagram de targets compartidos
- 3.2: Barplot de número de targets por miRNA
- 3.3: Network de miRNA-target (top 20 targets por miRNA)

---

### **COMPONENTE 2: Pathway Enrichment** 🧬
**Objetivo:** Identificar vías biológicas enriquecidas

**Análisis:**
- Gene Ontology (GO): Biological Process, Molecular Function, Cellular Component
- KEGG Pathways
- Reactome Pathways
- WikiPathways

**Outputs:**
- Tablas de enriquecimiento (por miRNA)
- Pathways significativos (FDR < 0.05)
- Términos compartidos entre los 3 miRNAs

**Figuras:**
- 3.4: Dot plot de top GO terms (por miRNA)
- 3.5: Heatmap de pathways enriquecidos (3 miRNAs)
- 3.6: Network de pathway overlap

---

### **COMPONENTE 3: Literature Mining** 📚
**Objetivo:** Contexto biológico y evidencia previa

**Búsqueda en:**
- PubMed (asociaciones con ALS, neurodegeneración)
- miRBase (información de miRNA)
- Human miRNA Disease Database (HMDD)

**Outputs:**
- Resumen de literatura por miRNA
- Asociaciones conocidas con enfermedades
- Funciones conocidas

**Tabla:**
- 3.1: Resumen de evidencia previa (ALS, otras ND)

---

### **COMPONENTE 4: Seed Impact Analysis** 🧬
**Objetivo:** Evaluar impacto de G>T en la seed region

**Análisis:**
- Posiciones específicas de G>T en cada miRNA
- Cambio en secuencia seed (si G→T)
- Predicción de nuevos targets (seed mutado)

**Outputs:**
- Secuencias seed: WT vs mutado
- Targets perdidos por mutación
- Targets ganados por mutación

**Figuras:**
- 3.7: Alignment de seeds (WT vs mutado)
- 3.8: Heatmap de cambio de afinidad (ΔG)

---

### **COMPONENTE 5: Expression Context** 📊
**Objetivo:** Contexto de expresión de targets

**Datos externos (si disponibles):**
- Expresión de targets en ALS (RNA-seq público)
- Expresión de miRNAs en ALS (si hay datos)
- Correlación miRNA-target

**Figuras:**
- 3.9: Scatter plot de expresión (si hay datos)
- 3.10: Heatmap de correlación miRNA-target

---

### **COMPONENTE 6: Functional Network** 🕸️
**Objetivo:** Red de interacciones miRNA-gene-pathway

**Análisis:**
- Network de los 3 miRNAs
- Targets compartidos
- Pathways conectados
- Hubs funcionales

**Figuras:**
- 3.11: Network completo (miRNA → targets → pathways) ⭐
- 3.12: Simplified network (solo high-confidence)

---

### **COMPONENTE 7: Oxidative Stress Focus** 🔥
**Objetivo:** Relación específica con estrés oxidativo

**Búsqueda:**
- Targets relacionados con:
  - Respuesta antioxidante (NRF2, SOD, GPX)
  - Vías de reparación de ADN
  - Apoptosis y neurodegeneración
  - Inflamación

**Outputs:**
- Lista de targets oxidativos
- Evidencia de rol en estrés oxidativo

**Figuras:**
- 3.13: Barplot de targets por categoría funcional
- 3.14: Heatmap de targets oxidativos (expresión si hay datos)

---

## 🔄 FLUJO DE TRABAJO PASO 3

```
ENTRADA (del Paso 2)
├── 3 candidatos ALS identificados
├── Datos limpios (final_processed_data_CLEAN.csv)
├── Ranking completo (SEED_GT_miRNAs_CLEAN_RANKING.csv)
└── Volcano Plot data (VOLCANO_PLOT_DATA_PER_SAMPLE.csv)

↓

PASO 3.1: Target Prediction
├── Query a bases de datos (TargetScan, miRTarBase, etc.)
├── Compilar listas de targets
└── Identificar targets compartidos

↓

PASO 3.2: Pathway Enrichment
├── Análisis GO/KEGG por miRNA
├── Identificar pathways significativos
└── Overlap analysis

↓

PASO 3.3: Literature Mining
├── Búsqueda PubMed
├── Compilar evidencia previa
└── Crear tabla resumen

↓

PASO 3.4: Seed Impact
├── Analizar mutaciones específicas
├── Predecir cambio de targets
└── Evaluar impacto funcional

↓

PASO 3.5: Network Analysis
├── Construir red miRNA-gene-pathway
├── Identificar hubs
└── Visualizar conexiones

↓

PASO 3.6: Oxidative Stress
├── Filtrar targets oxidativos
├── Análisis específico
└── Integración con hipótesis

↓

SALIDA
├── 14 figuras (3.1-3.14)
├── Tablas de targets y pathways
├── Network files
├── Resumen de literatura
└── HTML viewer Paso 3
```

---

## 📂 ESTRUCTURA DE OUTPUTS

```
pipeline_3/
├── data/
│   ├── targets_hsa-miR-196a-5p.csv
│   ├── targets_hsa-miR-9-5p.csv
│   ├── targets_hsa-miR-4746-5p.csv
│   ├── targets_shared.csv
│   ├── pathways_enriched_GO.csv
│   ├── pathways_enriched_KEGG.csv
│   └── literature_summary.csv
│
├── figures/
│   ├── FIG_3.1_TARGETS_VENN.png
│   ├── FIG_3.2_TARGETS_BARPLOT.png
│   ├── FIG_3.3_NETWORK_TARGETS.png
│   ├── FIG_3.4_GO_DOTPLOT.png
│   ├── FIG_3.5_PATHWAYS_HEATMAP.png
│   ├── FIG_3.6_PATHWAY_NETWORK.png
│   ├── FIG_3.7_SEED_ALIGNMENT.png
│   ├── FIG_3.8_AFFINITY_CHANGE.png
│   ├── FIG_3.9_EXPRESSION_SCATTER.png
│   ├── FIG_3.10_CORRELATION_HEATMAP.png
│   ├── FIG_3.11_FULL_NETWORK.png ⭐
│   ├── FIG_3.12_SIMPLE_NETWORK.png
│   ├── FIG_3.13_FUNCTIONAL_CATEGORIES.png
│   └── FIG_3.14_OXIDATIVE_TARGETS.png
│
├── scripts/
│   ├── 01_query_targets.R
│   ├── 02_pathway_enrichment.R
│   ├── 03_literature_mining.R
│   ├── 04_seed_impact.R
│   ├── 05_network_analysis.R
│   ├── 06_oxidative_focus.R
│   └── 07_create_HTML.R
│
└── docs/
    ├── PASO_3_PLANIFICACION.md (este archivo)
    ├── METODO_TARGETS.md
    ├── HALLAZGOS_FUNCIONALES.md
    └── README_PASO3.md
```

---

## 🔧 HERRAMIENTAS NECESARIAS

### **R Packages:**
```r
# Target prediction & pathway
library(multiMiR)         # Query múltiples DBs
library(clusterProfiler)  # GO/KEGG enrichment
library(enrichplot)       # Visualización
library(ReactomePA)       # Reactome pathways

# Networks
library(igraph)           # Network analysis
library(visNetwork)       # Interactive networks
library(ggraph)           # Network plots

# Sequence analysis
library(Biostrings)       # Manejo de secuencias
library(seqLogo)          # Sequence logos

# Otros
library(VennDiagram)      # Venn diagrams
library(UpSetR)           # UpSet plots
library(ComplexHeatmap)   # Heatmaps avanzados
```

### **APIs/Bases de Datos:**
- TargetScan: http://www.targetscan.org/
- miRTarBase: https://mirtarbase.cuhk.edu.cn/
- miRDB: http://mirdb.org/
- DIANA-microT: http://diana.imis.athena-innovation.gr/

---

## ⚠️ CONSIDERACIONES ESPECIALES

### **1. Datos Experimentales:**
- Si hay **RNA-seq de ALS disponible** → análisis de expresión de targets
- Si **NO hay datos** → solo análisis predicho

### **2. Validación:**
- Priorizar **targets validados** experimentalmente
- Destacar targets con **múltiples fuentes** de evidencia

### **3. Enfoque en Estrés Oxidativo:**
- Filtrar/destacar targets relacionados con:
  - NRF2 pathway
  - Antioxidant response
  - DNA damage response
  - Mitochondrial function

### **4. Comparación con Control:**
- También analizar los **top 5 miRNAs Control**
- Ver si hay **patrones funcionales distintos**

---

## 📊 FIGURAS PRIORITARIAS

### **Esenciales (6):**
1. ✅ Fig 3.1: Venn de targets compartidos
2. ✅ Fig 3.3: Network miRNA-targets
3. ✅ Fig 3.5: Heatmap de pathways
4. ✅ Fig 3.11: Network completo ⭐
5. ✅ Fig 3.13: Categorías funcionales
6. ✅ Fig 3.14: Targets oxidativos

### **Opcionales (según datos disponibles):**
- Fig 3.9-3.10: Si hay RNA-seq
- Fig 3.7-3.8: Si hacemos análisis de seed mutation

---

## 🎯 DELIVERABLES DEL PASO 3

### **Datos:**
1. ✅ Listas de targets (validados + predichos)
2. ✅ Pathways enriquecidos (GO + KEGG)
3. ✅ Tabla de literatura
4. ✅ Network files (formato para Cytoscape)

### **Figuras:**
1. ✅ 6-14 figuras (según disponibilidad de datos)
2. ✅ Network interactivo (HTML)

### **Documentación:**
1. ✅ Método de predicción de targets
2. ✅ Resultados de enrichment
3. ✅ Interpretación funcional
4. ✅ Conexión con hipótesis oxidativa

### **HTML:**
1. ✅ Viewer completo del Paso 3
2. ✅ Integración con Pasos 1 y 2

---

## 🔄 CONEXIÓN CON PASOS ANTERIORES

### **Del Paso 1:**
- Caracterización general del dataset
- Identificación de G>T como mutación prevalente
- Enfoque en seed region

### **Del Paso 2:**
- 3 candidatos ALS identificados
- Método robusto de comparación
- Hallazgo "Control > ALS" (22 miRNAs)

### **Al Paso 3:**
- **Funcionalidad** de los 3 candidatos
- **Mecanismo** de G>T en seed
- **Relevancia biológica** para ALS

---

## 📊 MÉTRICAS DE ÉXITO

### **Paso 3 será exitoso si:**
1. ✅ Identificamos al menos **50 targets** por miRNA
2. ✅ Encontramos **overlap funcional** entre los 3
3. ✅ Identificamos **pathways relacionados con oxidación**
4. ✅ Encontramos **evidencia previa** de al menos 1 miRNA en ALS
5. ✅ Creamos un **modelo funcional** coherente

---

## 🚀 PRIORIDADES INICIALES

### **ALTA PRIORIDAD:**
1. Target prediction (TargetScan + miRTarBase)
2. Pathway enrichment (GO + KEGG)
3. Network visualization
4. Enfoque oxidativo

### **MEDIA PRIORIDAD:**
5. Literature mining
6. Seed impact analysis

### **BAJA PRIORIDAD (si hay tiempo):**
7. Expression correlation (solo si hay datos)

---

## 💡 HIPÓTESIS PARA VALIDAR

### **Hipótesis 1: Oxidación Dirigida**
Los 3 miRNAs con G>T en seed en ALS regulan genes de:
- Respuesta antioxidante
- Reparación de ADN
- Apoptosis neuronal

### **Hipótesis 2: Pérdida de Función**
G>T en seed → cambio de targets → pérdida de regulación neuroprotectora

### **Hipótesis 3: Red Coherente**
Los 3 miRNAs convergen en pathways comunes relacionados con neurodegeneración

---

## 🔧 IMPLEMENTACIÓN

### **Fase 1: Setup (30 min)**
- Instalar/verificar packages
- Configurar APIs/bases de datos
- Preparar lista de 3 miRNAs

### **Fase 2: Target Prediction (1-2 hr)**
- Query a TargetScan, miRTarBase, miRDB
- Consolidar resultados
- Filtrar por confidence score

### **Fase 3: Enrichment (1 hr)**
- GO enrichment por miRNA
- KEGG enrichment por miRNA
- Identificar overlap

### **Fase 4: Visualization (2 hr)**
- Crear 6-8 figuras esenciales
- Network analysis
- Heatmaps de pathways

### **Fase 5: Integration (1 hr)**
- HTML viewer
- Documentación
- Resumen de hallazgos

**Tiempo total estimado:** 5-6 horas

---

## 📋 CHECKLIST DE PREPARACIÓN

**Antes de empezar Paso 3:**
- [x] Paso 2 completado (12 figuras)
- [x] 3 candidatos ALS identificados
- [x] Volcano Plot con método correcto
- [x] Datos limpios disponibles
- [ ] Verificar acceso a bases de datos
- [ ] Instalar packages necesarios
- [ ] Crear directorio `pipeline_3/`

---

## 🎯 SIGUIENTE PASO INMEDIATO

1. Crear estructura de directorios para Paso 3
2. Verificar/instalar packages de bioconductor
3. Comenzar con target prediction (miRNA #1: hsa-miR-196a-5p)

---

**Planificación completada:** 2025-10-17 02:40
**Componentes planeados:** 7
**Figuras esperadas:** 6-14 (según datos)
**Estado:** ✅ LISTO PARA COMENZAR PASO 3

