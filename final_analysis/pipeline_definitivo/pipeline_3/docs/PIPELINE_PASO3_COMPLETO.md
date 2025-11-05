# 🔧 PIPELINE PASO 3 - DOCUMENTACIÓN COMPLETA

**Fecha:** 2025-10-17 03:15
**Versión:** 1.0.0
**Propósito:** Automatización del análisis funcional

---

## 📋 RESUMEN

El Paso 3 realiza análisis funcional de los candidatos ALS identificados en el Paso 2, incluyendo:
- Predicción de targets (genes regulados)
- Enrichment de pathways (GO/KEGG)
- Análisis de redes (miRNA-gene-pathway)
- Visualización integrada

---

## 🔄 ESTRUCTURA DEL PIPELINE

```
PASO 3
├── 3.1: Setup y Verificación (1 min)
│   ├── Verificar packages
│   ├── Cargar candidatos del Paso 2
│   └── Crear configuración
│
├── 3.2: Target Prediction (5-10 min)
│   ├── Query a multiMiR (TargetScan, miRTarBase, miRDB)
│   ├── Filtrar por confianza
│   ├── Identificar targets compartidos
│   └── Guardar listas de targets
│
├── 3.3: Pathway Enrichment (2-5 min)
│   ├── GO enrichment (BP, MF)
│   ├── KEGG enrichment
│   ├── Identificar pathways compartidos
│   └── Filtrar por oxidación/neurodegeneración
│
├── 3.4: Network Analysis (1-2 min)
│   ├── Crear grafo dirigido
│   ├── Calcular métricas (degree, betweenness)
│   ├── Identificar hub genes
│   └── Guardar red (edges, nodes, graphml)
│
├── 3.5: Crear Figuras (2-3 min)
│   ├── 9 figuras profesionales
│   └── Guardar en figures/
│
└── 3.6: Crear HTML (1 min)
    ├── Integrar todas las figuras
    ├── Añadir estadísticas
    └── Generar viewer interactivo

TIEMPO TOTAL: 12-25 minutos
```

---

## 📂 INPUTS Y OUTPUTS

### **INPUTS (del Paso 2):**
```
../pipeline_2/VOLCANO_PLOT_DATA_PER_SAMPLE.csv  ← Lista de candidatos ALS
```

### **OUTPUTS:**

#### **Datos (15+ archivos CSV):**
```
data/
├── ALS_candidates.csv                          ← 3 candidatos
├── paso3_config.json                           ← Configuración
├── candidates_als.rds                          ← Para scripts
│
├── targets/
│   ├── targets_hsa_miR_196a_5p_all.csv
│   ├── targets_hsa_miR_196a_5p_highconf.csv
│   ├── targets_hsa_miR_9_5p_all.csv
│   ├── targets_hsa_miR_9_5p_highconf.csv
│   ├── targets_hsa_miR_142_5p_all.csv
│   ├── targets_hsa_miR_142_5p_highconf.csv
│   ├── targets_all_combined.csv                ← CONSOLIDADO
│   ├── targets_highconf_combined.csv           ← HIGH-CONFIDENCE
│   ├── targets_shared.csv                      ← COMPARTIDOS
│   └── summary_by_mirna.csv                    ← ESTADÍSTICAS
│
├── pathways/
│   ├── GO_BP_hsa_miR_196a_5p.csv
│   ├── GO_MF_hsa_miR_196a_5p.csv
│   ├── KEGG_hsa_miR_196a_5p.csv
│   ├── (similar para otros 2 miRNAs)
│   ├── GO_shared.csv                           ← COMPARTIDOS
│   ├── GO_oxidative.csv                        ← FILTRADOS
│   └── enrichment_results.rds                  ← Para scripts
│
└── network/
    ├── network_edges.csv                       ← EDGES
    ├── network_nodes.csv                       ← NODOS
    ├── network.graphml                         ← CYTOSCAPE
    ├── node_metrics.csv                        ← MÉTRICAS
    ├── hub_genes.csv                           ← HUBS
    └── network_graph.rds                       ← Para scripts
```

#### **Figuras (9 archivos PNG):**
```
figures/
├── FIG_3.1_TARGETS_VENN.png                    ← Overlap de targets
├── FIG_3.2_TARGETS_BARPLOT.png                 ← # targets por miRNA
├── FIG_3.3_TARGETS_NETWORK.png                 ← Red miRNA-targets
├── FIG_3.4_GO_DOTPLOT.png                      ← GO enrichment
├── FIG_3.5_PATHWAYS_HEATMAP.png                ← Pathways compartidos
├── FIG_3.6_NETWORK_FULL.png                    ← Red completa ⭐
├── FIG_3.7_NETWORK_SIMPLE.png                  ← Red simplificada
├── FIG_3.8_SHARED_TARGETS.png                  ← Targets compartidos
└── FIG_3.9_SUMMARY_STATS.png                   ← Estadísticas
```

#### **HTML:**
```
PASO_3_ANALISIS_FUNCIONAL.html                  ← Viewer integrado
```

---

## 🚀 CÓMO EJECUTAR EL PIPELINE

### **Opción 1: Script Maestro (Automático)**
```bash
cd pipeline_3/
Rscript RUN_PASO3_COMPLETE.R
```

Ejecuta TODO el pipeline automáticamente (12-25 minutos).

### **Opción 2: Paso a Paso (Manual)**
```bash
cd pipeline_3/

# 1. Setup (1 min)
Rscript scripts/01_setup_and_verify.R

# 2. Targets (5-10 min) ⚠️  LENTO
Rscript scripts/02_query_targets.R

# 3. Pathways (2-5 min)
Rscript scripts/03_pathway_enrichment.R

# 4. Network (1-2 min)
Rscript scripts/04_network_analysis.R

# 5. Figuras (2-3 min)
Rscript scripts/05_create_figures.R

# 6. HTML (1 min)
Rscript scripts/06_create_HTML.R
```

---

## ⚙️ PARÁMETROS CONFIGURABLES

### **En `paso3_config.json`:**
```json
{
  "thresholds": {
    "target_score_targetscan": 0.7,      ← Mínimo score TargetScan
    "target_score_mirdb": 80,            ← Mínimo score miRDB
    "pathway_pvalue": 0.05,              ← Threshold p-value
    "pathway_qvalue": 0.05,              ← Threshold FDR
    "min_databases": 2                   ← Targets en >=2 DBs
  },
  "databases": {
    "targetscan": true,
    "mirtarbase": true,
    "mirdb": true
  },
  "analysis": {
    "go_ontology": ["BP", "MF", "CC"],
    "kegg": true,
    "reactome": false
  }
}
```

### **Modificar configuración:**
```r
# Editar data/paso3_config.json antes de ejecutar
# O modificar en scripts/01_setup_and_verify.R
```

---

## 🔍 DESCRIPCIÓN DE CADA SCRIPT

### **01_setup_and_verify.R**
**Propósito:** Verificación inicial y preparación
**Tiempo:** ~1 min
**Outputs:**
- `data/ALS_candidates.csv`
- `data/paso3_config.json`
- `data/candidates_als.rds`

**Proceso:**
1. Verifica/instala packages necesarios
2. Carga candidatos del Paso 2
3. Filtra por FC > 1.5x y FDR < 0.05
4. Crea configuración
5. Verifica conectividad a APIs

---

### **02_query_targets.R**
**Propósito:** Predicción de targets
**Tiempo:** ~5-10 min (depende de API)
**Outputs:**
- `data/targets/targets_*_all.csv` (3 archivos)
- `data/targets/targets_*_highconf.csv` (3 archivos)
- `data/targets/targets_all_combined.csv`
- `data/targets/targets_highconf_combined.csv`
- `data/targets/targets_shared.csv`
- `data/targets/summary_by_mirna.csv`

**Proceso:**
1. Para cada miRNA: Query a multiMiR
2. Procesar resultados (clasificar por evidencia)
3. Filtrar high-confidence (>=2 DBs o validados)
4. Identificar targets compartidos
5. Calcular estadísticas

**⚠️ NOTA:** Este es el paso más lento (APIs online).

---

### **03_pathway_enrichment.R**
**Propósito:** Enrichment de pathways
**Tiempo:** ~2-5 min
**Outputs:**
- `data/pathways/GO_BP_*.csv` (3 archivos)
- `data/pathways/GO_MF_*.csv` (3 archivos)
- `data/pathways/KEGG_*.csv` (3 archivos)
- `data/pathways/GO_shared.csv`
- `data/pathways/GO_oxidative.csv`
- `data/pathways/enrichment_results.rds`

**Proceso:**
1. Para cada miRNA: Extraer targets (entrez IDs)
2. GO enrichment (BP, MF, CC)
3. KEGG enrichment
4. Consolidar resultados
5. Identificar pathways compartidos
6. Filtrar por términos oxidativos

---

### **04_network_analysis.R**
**Propósito:** Construcción de red
**Tiempo:** ~1-2 min
**Outputs:**
- `data/network/network_edges.csv`
- `data/network/network_nodes.csv`
- `data/network/network.graphml`
- `data/network/node_metrics.csv`
- `data/network/hub_genes.csv`
- `data/network/network_graph.rds`

**Proceso:**
1. Crear edges: miRNA → target, target → pathway
2. Crear nodos: miRNA, genes, pathways
3. Construir grafo dirigido (igraph)
4. Calcular métricas (degree, betweenness)
5. Identificar hub genes
6. Guardar en múltiples formatos

---

### **05_create_figures.R**
**Propósito:** Generar figuras
**Tiempo:** ~2-3 min
**Outputs:** 9 PNGs en `figures/`

**Figuras:**
1. **3.1:** Venn diagram (overlap targets)
2. **3.2:** Barplot (# targets por miRNA)
3. **3.3:** Network miRNA-targets (top 30)
4. **3.4:** GO dot plot (top terms)
5. **3.5:** Heatmap pathways compartidos
6. **3.6:** Network completo (miRNA-gene-pathway) ⭐
7. **3.7:** Network simplificado (solo hubs)
8. **3.8:** Shared targets barplot
9. **3.9:** Summary statistics

---

### **06_create_HTML.R**
**Propósito:** Viewer interactivo
**Tiempo:** ~1 min
**Outputs:** `PASO_3_ANALISIS_FUNCIONAL.html`

**Contenido HTML:**
- Cards de estadísticas
- Hallazgos destacados
- 9 figuras organizadas por sección
- Referencias a archivos de datos

---

## 📊 VALIDACIÓN DE RESULTADOS

### **Después de ejecutar, verificar:**

**1. Archivos generados:**
```bash
ls data/targets/*.csv | wc -l     # Debe ser 9-10
ls data/pathways/*.csv | wc -l    # Debe ser 7-12
ls data/network/*.csv | wc -l     # Debe ser 4-5
ls figures/*.png | wc -l          # Debe ser 6-9
```

**2. Números esperados:**
- **Candidatos ALS:** 3
- **Total targets (all):** 500-2000
- **Total targets (high-conf):** 100-500
- **Targets compartidos:** 5-50
- **GO terms:** 20-200
- **Hub genes:** 10-50
- **Figuras:** 6-9

**3. HTML funciona:**
```bash
open PASO_3_ANALISIS_FUNCIONAL.html
# Debe mostrar figuras y estadísticas
```

---

## ⚠️ CONSIDERACIONES

### **Dependencias Críticas:**
1. **Internet:** Requerido para APIs (multiMiR, Bioconductor)
2. **Tiempo:** Target prediction puede tardar 10+ minutos
3. **Memoria:** Network analysis requiere ~2GB RAM

### **Manejo de Errores:**
- Si `multiMiR` falla → usar solo archivos locales (si existen)
- Si enrichment falla → continuar sin pathways
- Si network falla → crear solo figuras de targets

### **Rate Limits:**
- multiMiR: ~30 segundos por query
- Incluye `Sys.sleep(2)` entre queries
- No ejecutar en loop rápido

---

## 🔧 PERSONALIZACIÓN

### **Para cambiar thresholds:**
Editar `data/paso3_config.json` después del setup:
```json
{
  "thresholds": {
    "min_databases": 3,           ← Más estricto
    "pathway_pvalue": 0.01        ← Más estricto
  }
}
```

### **Para usar solo targets validados:**
En `02_query_targets.R`, cambiar línea de filtro:
```r
# Original
filter(N_Databases >= 2 | Evidence_Level == "Validated")

# Solo validados
filter(Evidence_Level == "Validated")
```

### **Para incluir más miRNAs:**
En `01_setup_and_verify.R`, cambiar threshold:
```r
# Original
filter(log2FC > 0.58, padj < 0.05)

# Más permisivo
filter(log2FC > 0.3, padj < 0.1)
```

---

## 📊 MÉTRICAS DE CALIDAD

### **Target Prediction:**
- **Mínimo aceptable:** 50 targets high-conf por miRNA
- **Óptimo:** 100-300 targets
- **Targets compartidos:** Al menos 5-10

### **Pathway Enrichment:**
- **Mínimo:** 5 GO terms significativos por miRNA
- **Óptimo:** 20-50 términos
- **Pathways compartidos:** Al menos 2-5

### **Network:**
- **Nodos:** 100-500 (depende de targets)
- **Edges:** 200-1000
- **Hub genes:** 10-50 (degree >= 2)

---

## 🐛 TROUBLESHOOTING

### **Error: "multiMiR no funciona"**
**Solución:**
```r
# Reinstalar
BiocManager::install("multiMiR", force = TRUE)

# O usar versión de desarrollo
devtools::install_github("KechrisLab/multiMiR")
```

### **Error: "No targets encontrados"**
**Posibles causas:**
1. Nombre de miRNA incorrecto (verificar formato: "hsa-miR-XXX")
2. miRNA muy raro (no en bases de datos)
3. API caída

**Solución:** Verificar manualmente en http://www.targetscan.org/

### **Error: "Enrichment falla"**
**Posibles causas:**
1. Muy pocos targets (<10)
2. Targets sin entrez IDs

**Solución:** Verificar conversión de gene symbols a entrez IDs

---

## 📋 CHECKLIST DE EJECUCIÓN

**Antes de ejecutar:**
- [ ] Paso 2 completado
- [ ] Archivo `VOLCANO_PLOT_DATA_PER_SAMPLE.csv` existe
- [ ] Internet disponible
- [ ] Packages de Bioconductor instalados

**Durante ejecución:**
- [ ] Setup completa sin errores
- [ ] Target prediction encuentra > 50 targets por miRNA
- [ ] Enrichment identifica pathways significativos
- [ ] Network se crea correctamente

**Después de ejecución:**
- [ ] 9-10 archivos CSV en data/targets/
- [ ] 7-12 archivos CSV en data/pathways/
- [ ] 4-5 archivos CSV en data/network/
- [ ] 6-9 figuras PNG en figures/
- [ ] HTML generado y funciona

---

## 🎯 INTEGRACIÓN CON PIPELINE COMPLETO

### **Conexión Paso 2 → Paso 3:**
```
PASO 2 Output:
  VOLCANO_PLOT_DATA_PER_SAMPLE.csv
    ↓
    Filtrar: log2FC > 0.58, padj < 0.05
    ↓
  3 candidatos ALS
    ↓
PASO 3 Input:
  data/ALS_candidates.csv
```

### **Para automatizar todo (Paso 1 + 2 + 3):**
```bash
# Desde pipeline_definitivo/
Rscript pipeline_1/run_pipeline.R  # (si existe)
Rscript pipeline_2/scripts_consolidados/run_all.R  # (crear)
Rscript pipeline_3/RUN_PASO3_COMPLETE.R
```

---

## 📖 DOCUMENTOS RELACIONADOS

- `PLAN_PASO3_DETALLADO.md` ← Planificación original
- `README_PASO3.md` ← Guía de usuario
- `PIPELINE_PASO3_COMPLETO.md` ← Este documento
- `HALLAZGOS_FUNCIONALES.md` ← Resultados (crear después)

---

## 🎉 RESULTADO FINAL

**Al completar Paso 3, tendrás:**
- ✅ Lista completa de targets de los 3 candidatos
- ✅ Pathways biológicos regulados
- ✅ Red integrada miRNA-gene-pathway
- ✅ Identificación de genes hub
- ✅ Evidencia de relación con oxidación (si existe)
- ✅ 9 figuras profesionales
- ✅ HTML viewer para explorar resultados
- ✅ TODO documentado para el pipeline

---

**Documentado:** 2025-10-17 03:15
**Scripts:** 6 funcionales
**Outputs:** 30+ archivos
**Tiempo:** 12-25 minutos
**Estado:** ✅ LISTO PARA EJECUTAR

