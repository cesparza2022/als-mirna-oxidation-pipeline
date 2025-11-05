# 🚀 PASO 3: PLAN DETALLADO Y ACCIONABLE

**Fecha:** 2025-10-17 03:00
**Objetivo:** Análisis funcional de los 3 candidatos ALS
**Input:** Resultados del Paso 2 (Volcano Plot)

---

## 🎯 OBJETIVO PRINCIPAL

**Responder:** ¿Qué hacen estos 3 miRNAs y por qué son relevantes para ALS?

**Los 3 Candidatos:**
1. ⭐ **hsa-miR-196a-5p** (FC +1.78, p 2.17e-03) - MEJOR
2. **hsa-miR-9-5p** (FC +0.66, p 5.83e-03)
3. **hsa-miR-4746-5p** (FC +0.91, p 2.92e-02)

---

## 📋 PLAN DE ANÁLISIS (4 COMPONENTES ESENCIALES)

### **COMPONENTE 1: PREDICCIÓN DE TARGETS** 🎯
**Tiempo estimado:** 1-2 horas

#### **Qué vamos a hacer:**
1. Consultar bases de datos de targets (TargetScan, miRTarBase, miRDB)
2. Compilar listas de genes regulados por cada miRNA
3. Identificar targets compartidos entre los 3
4. Filtrar por confianza (score alto, validados experimentalmente)

#### **Outputs:**
- 3 CSV: `targets_miR-196a-5p.csv`, `targets_miR-9-5p.csv`, `targets_miR-4746-5p.csv`
- 1 CSV: `targets_shared.csv` (overlap)
- 1 CSV: `targets_all_combined.csv`

#### **Figuras (3):**
- **3.1:** Venn diagram - Overlap de targets
- **3.2:** Barplot - Número de targets por miRNA
- **3.3:** Network - Top 50 targets por miRNA

#### **Herramientas R:**
```r
library(multiMiR)    # Query múltiples DBs
library(VennDiagram) # Venn diagrams
library(ggplot2)     # Barplots
library(igraph)      # Networks
```

---

### **COMPONENTE 2: ENRICHMENT DE PATHWAYS** 🧬
**Tiempo estimado:** 1 hora

#### **Qué vamos a hacer:**
1. Análisis GO (Gene Ontology): Biological Process, Molecular Function
2. Análisis KEGG (vías metabólicas)
3. Identificar términos sobre-representados
4. Buscar pathways relacionados con oxidación, neurodegeneración, ALS

#### **Outputs:**
- 3 CSV: `GO_enrichment_miR-XXX.csv` (uno por miRNA)
- 1 CSV: `pathways_shared.csv` (términos compartidos)
- 1 CSV: `pathways_oxidative.csv` (filtrados por oxidación)

#### **Figuras (3):**
- **3.4:** Dot plot - Top 20 GO terms por miRNA
- **3.5:** Heatmap - Pathways compartidos (filas=términos, cols=miRNAs)
- **3.6:** Network - Conexiones pathway-miRNA

#### **Herramientas R:**
```r
library(clusterProfiler)  # GO/KEGG enrichment
library(enrichplot)       # Visualización
library(ReactomePA)       # Reactome (opcional)
```

---

### **COMPONENTE 3: LITERATURA Y CONTEXTO** 📚
**Tiempo estimado:** 30 min - 1 hora

#### **Qué vamos a hacer:**
1. Búsqueda en PubMed: "miRNA + ALS"
2. Búsqueda en bases de datos especializadas (HMDD, miR2Disease)
3. Revisar funciones conocidas de cada miRNA
4. Compilar evidencia previa en ALS o neurodegeneración

#### **Outputs:**
- 1 tabla resumen: `literature_summary.csv`
  - Columnas: miRNA, Disease, Evidence, PMID, Summary
- 1 documento: `CONTEXTO_BIOLOGICO.md`

#### **Figura (1):**
- **3.7:** Tabla visual - Resumen de literatura por miRNA

#### **Fuentes:**
- PubMed / PubTator
- HMDD v4.0
- miRBase
- miR2Disease

---

### **COMPONENTE 4: NETWORK INTEGRADO** 🕸️
**Tiempo estimado:** 1-2 horas

#### **Qué vamos a hacer:**
1. Construir red: 3 miRNAs → targets → pathways
2. Identificar targets hub (altamente conectados)
3. Buscar módulos funcionales
4. Destacar genes relacionados con oxidación

#### **Outputs:**
- 1 archivo de red: `network_edges.csv`
- 1 archivo de nodos: `network_nodes.csv`
- 1 archivo Cytoscape: `network.cys` (opcional)

#### **Figuras (2):**
- **3.8:** Network completo (miRNA → genes → pathways) ⭐
- **3.9:** Network simplificado (solo high-confidence)

#### **Herramientas R:**
```r
library(igraph)      # Network analysis
library(ggraph)      # Network plots
library(visNetwork)  # Interactive (opcional)
```

---

## 📊 RESUMEN DE OUTPUTS

### **Datos (10 archivos CSV):**
1. `targets_miR-196a-5p.csv`
2. `targets_miR-9-5p.csv`
3. `targets_miR-4746-5p.csv`
4. `targets_shared.csv`
5. `targets_all_combined.csv`
6. `GO_enrichment_miR-196a-5p.csv`
7. `GO_enrichment_miR-9-5p.csv`
8. `GO_enrichment_miR-4746-5p.csv`
9. `pathways_shared.csv`
10. `literature_summary.csv`

### **Figuras (9 esenciales):**
1. 3.1: Venn de targets
2. 3.2: Barplot de targets
3. 3.3: Network de targets
4. 3.4: Dot plot GO
5. 3.5: Heatmap pathways
6. 3.6: Network pathways
7. 3.7: Tabla literatura
8. 3.8: Network completo ⭐
9. 3.9: Network simplificado

### **HTML:**
- `PASO_3_ANALISIS_FUNCIONAL.html`

---

## 🔄 FLUJO DE TRABAJO

```
PASO 3.1: PREPARACIÓN (15 min)
├── Crear directorio pipeline_3/
├── Instalar/verificar packages
└── Cargar lista de 3 candidatos

↓

PASO 3.2: TARGET PREDICTION (1-2 hr)
├── Query TargetScan
├── Query miRTarBase
├── Query miRDB
├── Consolidar resultados
├── Filtrar por confianza
└── Identificar overlap

↓

PASO 3.3: PATHWAY ENRICHMENT (1 hr)
├── GO enrichment (3 miRNAs)
├── KEGG enrichment (3 miRNAs)
├── Identificar términos compartidos
└── Filtrar por oxidación/ALS

↓

PASO 3.4: LITERATURA (30 min)
├── Búsqueda PubMed
├── Consultar HMDD
└── Compilar evidencia

↓

PASO 3.5: NETWORK ANALYSIS (1-2 hr)
├── Construir red integrada
├── Identificar hubs
└── Detectar módulos

↓

PASO 3.6: VISUALIZACIÓN (1 hr)
├── Crear 9 figuras
└── Generar HTML

↓

PASO 3.7: DOCUMENTACIÓN (30 min)
├── Registrar métodos
├── Documentar hallazgos
└── Preparar para pipeline

TIEMPO TOTAL: 5-7 horas
```

---

## 🔧 PREPARACIÓN NECESARIA

### **Packages de R a verificar/instalar:**
```r
# CRAN packages
install.packages(c("dplyr", "tidyr", "ggplot2", "igraph", 
                   "ggraph", "VennDiagram", "UpSetR"))

# Bioconductor packages
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install(c("clusterProfiler", "enrichplot", 
                       "org.Hs.eg.db", "multiMiR", "ReactomePA"))
```

### **Verificar conectividad:**
- [ ] Internet disponible (para APIs)
- [ ] Acceso a TargetScan online
- [ ] Acceso a miRTarBase
- [ ] Acceso a PubMed

---

## 📊 ESTRUCTURA DE DIRECTORIOS (PASO 3)

```
pipeline_3/
├── data/
│   ├── targets/
│   │   ├── targets_miR-196a-5p.csv
│   │   ├── targets_miR-9-5p.csv
│   │   ├── targets_miR-4746-5p.csv
│   │   ├── targets_shared.csv
│   │   └── targets_all_combined.csv
│   │
│   ├── pathways/
│   │   ├── GO_enrichment_miR-196a-5p.csv
│   │   ├── GO_enrichment_miR-9-5p.csv
│   │   ├── GO_enrichment_miR-4746-5p.csv
│   │   ├── pathways_shared.csv
│   │   └── pathways_oxidative.csv
│   │
│   └── literature/
│       └── literature_summary.csv
│
├── figures/
│   ├── FIG_3.1_TARGETS_VENN.png
│   ├── FIG_3.2_TARGETS_BARPLOT.png
│   ├── FIG_3.3_TARGETS_NETWORK.png
│   ├── FIG_3.4_GO_DOTPLOT.png
│   ├── FIG_3.5_PATHWAYS_HEATMAP.png
│   ├── FIG_3.6_PATHWAYS_NETWORK.png
│   ├── FIG_3.7_LITERATURE_TABLE.png
│   ├── FIG_3.8_NETWORK_FULL.png ⭐
│   └── FIG_3.9_NETWORK_SIMPLE.png
│
├── scripts/
│   ├── 01_setup.R
│   ├── 02_query_targets.R
│   ├── 03_pathway_enrichment.R
│   ├── 04_literature_mining.R
│   ├── 05_network_analysis.R
│   ├── 06_create_figures.R
│   └── 07_create_HTML.R
│
└── docs/
    ├── METODO_TARGETS.md
    ├── HALLAZGOS_FUNCIONALES.md
    ├── CONTEXTO_BIOLOGICO.md
    └── README_PASO3.md
```

---

## 🎯 PREGUNTAS CLAVE A RESPONDER

### **1. Targets:**
- [ ] ¿Cuántos targets tiene cada miRNA?
- [ ] ¿Hay targets compartidos entre los 3?
- [ ] ¿Hay targets validados experimentalmente?

### **2. Pathways:**
- [ ] ¿Qué vías biológicas regulan?
- [ ] ¿Hay relación con oxidación?
- [ ] ¿Hay relación con neurodegeneración?
- [ ] ¿Convergen en procesos comunes?

### **3. Contexto:**
- [ ] ¿Qué se sabe de estos miRNAs en literatura?
- [ ] ¿Hay evidencia previa en ALS?
- [ ] ¿Hay evidencia en otras enfermedades neurodegenerativas?

### **4. Integración:**
- [ ] ¿Forman una red funcional coherente?
- [ ] ¿Apuntan a los mismos procesos?
- [ ] ¿Hay un mecanismo común?

---

## 💡 HIPÓTESIS A EXPLORAR

### **Hipótesis 1: Regulación de Estrés Oxidativo**
Los 3 miRNAs regulan genes de:
- Respuesta antioxidante (NRF2, SOD, GPX)
- Reparación de ADN (OGG1, MUTYH)
- Apoptosis mitocondrial

**Test:** Buscar enriquecimiento en GO terms relacionados con oxidación

---

### **Hipótesis 2: Neurodegeneración**
Los 3 miRNAs regulan genes relacionados con:
- Muerte neuronal
- Agregación de proteínas
- Inflamación neuronal

**Test:** Buscar enriquecimiento en pathways de neurodegeneración

---

### **Hipótesis 3: Red Convergente**
Los 3 miRNAs:
- Tienen targets compartidos
- Regulan el mismo proceso
- Forman un módulo funcional

**Test:** Análisis de overlap y network clustering

---

## 🔬 ANÁLISIS ESPECÍFICOS

### **ANÁLISIS 1: Target Prediction**

#### **Bases de datos a consultar:**
1. **TargetScan 8.0** (predicción por seed matching)
   - URL: http://www.targetscan.org/
   - Criterio: Context++ score > -0.3

2. **miRTarBase 9.0** (validados experimentalmente)
   - URL: https://mirtarbase.cuhk.edu.cn/
   - Criterio: Strong evidence (Reporter assay, Western blot, qPCR)

3. **miRDB** (machine learning)
   - URL: http://mirdb.org/
   - Criterio: Target Score > 80

#### **Proceso:**
```r
# 1. Query para cada miRNA
targets_196a <- multiMiR::get_multimir(
  mirna = "hsa-miR-196a-5p",
  summary = TRUE
)

# 2. Filtrar por confianza
high_conf <- targets_196a %>%
  filter(
    (database == "miRTarBase" & experiments != "Weak") |
    (database == "TargetScan" & score > 0.7) |
    (database == "miRDB" & score > 80)
  )

# 3. Consolidar
targets_final <- high_conf %>%
  group_by(target_symbol) %>%
  summarise(
    N_databases = n(),
    Databases = paste(unique(database), collapse = ", "),
    Max_score = max(score, na.rm = TRUE)
  ) %>%
  arrange(desc(N_databases), desc(Max_score))
```

#### **Criterios de selección:**
- **High confidence:** Aparece en 2+ bases de datos
- **Validated:** Evidencia experimental en miRTarBase
- **Strong prediction:** Score alto en TargetScan o miRDB

---

### **ANÁLISIS 2: Pathway Enrichment**

#### **Análisis GO:**
```r
library(clusterProfiler)
library(org.Hs.eg.db)

# Para cada miRNA
ego <- enrichGO(
  gene = target_genes,
  OrgDb = org.Hs.eg.db,
  ont = "BP",           # Biological Process
  pAdjustMethod = "BH", # FDR
  pvalueCutoff = 0.05,
  qvalueCutoff = 0.05
)

# Filtrar términos relacionados con oxidación
oxidative_terms <- ego %>%
  filter(str_detect(Description, 
    "oxidativ|antioxid|reactive oxygen|ROS|redox|DNA damage"))
```

#### **Análisis KEGG:**
```r
kegg <- enrichKEGG(
  gene = target_entrez_ids,
  organism = "hsa",
  pvalueCutoff = 0.05
)

# Filtrar por neurodegeneración
neuro_pathways <- kegg %>%
  filter(str_detect(Description,
    "ALS|Parkinson|Alzheimer|neurodegeneration|neuron|synapse"))
```

---

### **ANÁLISIS 3: Literatura**

#### **Búsqueda PubMed:**
```r
# Query para cada miRNA
query_196a <- "hsa-miR-196a-5p AND (ALS OR amyotrophic lateral sclerosis OR motor neuron OR neurodegeneration)"

# Usar RISmed o rentrez
library(RISmed)
search <- EUtilsSummary(query_196a, type = "esearch", db = "pubmed")
records <- EUtilsGet(search)
```

#### **Compilar evidencia:**
- Número de papers por miRNA + ALS
- Funciones conocidas
- Enfermedades asociadas
- Nivel de evidencia

---

### **ANÁLISIS 4: Network Integrado**

#### **Construcción de la red:**
```r
library(igraph)

# Crear edges
edges <- data.frame(
  from = c(rep("miR-196a-5p", 50), rep("miR-9-5p", 50), ...),
  to = c(targets_196a$top50, targets_9$top50, ...),
  weight = c(scores_196a, scores_9, ...),
  type = "miRNA-target"
)

# Añadir edges target-pathway
pathway_edges <- data.frame(
  from = target_genes,
  to = pathway_names,
  type = "target-pathway"
)

# Combinar
all_edges <- rbind(edges, pathway_edges)

# Crear grafo
g <- graph_from_data_frame(all_edges, directed = TRUE)

# Detectar comunidades
communities <- cluster_louvain(g)
```

#### **Métricas a calcular:**
- **Degree:** Número de conexiones por nodo
- **Betweenness:** Importancia en la red
- **Hub genes:** Targets con más conexiones
- **Módulos:** Grupos funcionales

---

## 🎨 FIGURAS CLAVE

### **FIGURA 3.8: NETWORK COMPLETO** ⭐

**Concepto:**
```
         ┌─────────────────┐
         │  miR-196a-5p   │ ← miRNA (rojo)
         └────┬───┬───┬────┘
              │   │   │
         ┌────┴───┴───┴────┐
         │  Target genes   │ ← Genes (azul)
         └────┬───┬───┬────┘
              │   │   │
         ┌────┴───┴───┴────┐
         │    Pathways     │ ← Vías (verde)
         └─────────────────┘
```

**Elementos:**
- Nodos: 3 miRNAs + ~150 targets + ~20 pathways
- Edges: miRNA → target (grosor = score)
- Colores: Por tipo de nodo
- Tamaño: Por degree (conexiones)

---

## 📋 CHECKLIST DE PREPARACIÓN

**Antes de empezar:**
- [x] Paso 2 completo
- [x] 3 candidatos identificados
- [x] Volcano Plot data disponible
- [ ] Crear directorio `pipeline_3/`
- [ ] Instalar packages de Bioconductor
- [ ] Verificar acceso a internet/APIs
- [ ] Verificar multiMiR funciona

---

## 🎯 ORDEN DE EJECUCIÓN (RECOMENDADO)

```bash
# Preparación
mkdir -p pipeline_3/{data,figures,scripts,docs}
cd pipeline_3/

# 1. Setup y verificación
Rscript scripts/01_setup.R

# 2. Target prediction (más lento, 1-2 hr)
Rscript scripts/02_query_targets.R

# 3. Pathway enrichment (necesita targets)
Rscript scripts/03_pathway_enrichment.R

# 4. Literatura (paralelo, independiente)
Rscript scripts/04_literature_mining.R

# 5. Network (necesita targets + pathways)
Rscript scripts/05_network_analysis.R

# 6. Figuras (necesita todo lo anterior)
Rscript scripts/06_create_figures.R

# 7. HTML final
Rscript scripts/07_create_HTML.R
```

---

## ⚠️ CONSIDERACIONES IMPORTANTES

### **1. APIs y Rate Limits:**
- TargetScan: Puede ser lento, considerar cache
- PubMed: Max 3 requests/segundo
- multiMiR: Puede tardar varios minutos por miRNA

### **2. Datos Faltantes:**
- No todos los miRNAs tienen targets validados
- Algunos pathways pueden no ser significativos
- Literatura puede ser limitada para miR-4746-5p

### **3. Filtrado:**
- Usar **high confidence** targets (2+ databases)
- Pathways con FDR < 0.05
- Priorizar targets con evidencia experimental

### **4. Enfoque:**
- **Primario:** Los 3 candidatos ALS
- **Secundario (opcional):** Top 5 Control (para comparar)

---

## 💡 OUTPUTS ESPERADOS

### **Principales hallazgos esperados:**
1. **50-200 targets** por miRNA (high confidence)
2. **10-50 targets compartidos** entre los 3
3. **5-20 pathways significativos** por miRNA
4. **1-5 pathways compartidos** relacionados con oxidación/neuro
5. **Evidencia de literatura** para al menos 1-2 miRNAs

### **Figura estrella:**
- **FIG 3.8: Network completo** mostrando cómo los 3 miRNAs convergen en procesos comunes

---

## 🚀 SIGUIENTE PASO INMEDIATO

**ACCIÓN 1:** Crear estructura de directorios
```bash
cd /Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo
mkdir -p pipeline_3/{data/{targets,pathways,literature},figures,scripts,docs}
```

**ACCIÓN 2:** Crear script de setup y verificación de packages

**ACCIÓN 3:** Comenzar con target prediction para hsa-miR-196a-5p

---

## 📊 MÉTRICAS DE ÉXITO

**Paso 3 será exitoso si:**
- [ ] Identificamos > 50 targets por miRNA
- [ ] Encontramos overlap funcional entre los 3
- [ ] Identificamos pathways oxidativos
- [ ] Encontramos evidencia de al menos 1 miRNA en ALS
- [ ] Creamos network coherente
- [ ] Generamos 9 figuras profesionales
- [ ] HTML integrado funciona

---

**Plan documentado:** 2025-10-17 03:00
**Componentes:** 4 esenciales
**Figuras esperadas:** 9
**Tiempo estimado:** 5-7 horas
**Estado:** ✅ LISTO PARA COMENZAR

