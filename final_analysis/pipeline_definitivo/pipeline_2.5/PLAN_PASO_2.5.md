# 📊 PASO 2.5: ANÁLISIS DE PATRONES Y CARACTERÍSTICAS

**Fecha:** 2025-10-17 04:10
**Versión:** 1.0.0

---

## 🎯 OBJETIVO

**Antes de ir al análisis funcional (Paso 3), necesitamos entender:**
- ¿Hay patrones en los candidatos?
- ¿Pertenecen a familias específicas?
- ¿Hay secuencias conservadas afectadas?
- ¿Hay clustering de muestras?
- ¿Características estructurales comunes?

---

## 📋 ANÁLISIS PROPUESTOS (6 GRUPOS)

### **GRUPO A: CLUSTERING DE MUESTRAS** 🔥

#### **A.1: Clustering Jerárquico de Muestras (Solo candidatos)**
**Pregunta:** ¿Las muestras ALS se agrupan diferente de Control basándose en los candidatos?

**Método:**
```R
# Crear matriz: muestras x candidatos (VAF)
# Solo usar los N candidatos (3, 15, o 48 según preset)
# Clustering jerárquico
# ¿Las muestras ALS forman un cluster?
```

**Figuras:**
- Dendrograma con muestras coloreadas (ALS = rojo, Control = gris)
- Heatmap de muestras x candidatos
- PCA de muestras basado solo en candidatos

**¿Qué nos dice?**
- Si ALS se separa → candidatos son buenos biomarcadores
- Si no se separa → heterogeneidad en ALS

---

#### **A.2: Identificar Subtipos de ALS**
**Pregunta:** ¿Hay subtipos de ALS basados en perfil de G>T?

**Método:**
```R
# K-means clustering de muestras ALS
# Identificar 2-3 clusters
# Comparar características clínicas (si hay)
```

**Figuras:**
- K-means plot (solo muestras ALS)
- Silhouette plot
- Comparación de VAF entre clusters

**¿Qué nos dice?**
- ALS oxidativo vs no-oxidativo
- Severidad correlacionada con G>T
- Subtipos moleculares

---

### **GRUPO B: ANÁLISIS DE FAMILIAS miRNA** 🔥

#### **B.1: Familias de miRNAs Afectadas**
**Pregunta:** ¿Los candidatos pertenecen a familias específicas?

**Método:**
```R
# Extraer familia de cada candidato (ej: let-7, miR-9)
# Contar cuántos candidatos por familia
# Comparar con background (301 miRNAs)
```

**Figuras:**
- Barplot: Familias enriquecidas en candidatos
- Network de familias
- Árbol filogenético de candidatos

**Ejemplo:**
- ¿Todos los let-7 están afectados? (let-7d-5p)
- ¿Familia miR-9? (miR-9-5p, miR-9-3p)
- ¿Familia miR-30? (miR-30e-3p)

**¿Qué nos dice?**
- Si hay enriquecimiento de familias → susceptibilidad específica
- Familias comparten seed similar → afectación coordinada

---

#### **B.2: Análisis de Seed Sequences**
**Pregunta:** ¿Hay motivos conservados en las seeds afectadas?

**Método:**
```R
# Extraer seed sequences de los candidatos
# Alinear seeds
# Buscar motivos conservados
# ¿Dónde está el G>T en cada seed?
```

**Figuras:**
- Logo plot de seeds (WebLogo style)
- Posición del G>T en cada seed
- Heatmap de similitud de seeds
- Contexto nucleotídico del G (XGY patterns)

**¿Qué nos dice?**
- ¿Hay un motivo "GGX" o "XGG" susceptible?
- ¿El G afectado está en cierta posición de la seed?
- ¿Contexto específico favorece 8-oxoG?

---

### **GRUPO C: CARACTERÍSTICAS ESTRUCTURALES** 🔥

#### **C.1: Estructura Secundaria**
**Pregunta:** ¿Los candidatos tienen características estructurales comunes?

**Métricas:**
- Contenido G total (no solo seed)
- Contenido GC%
- Energía libre de plegamiento (ΔG)
- Estructura de horquilla

**Figuras:**
- Boxplot: G-content candidatos vs background
- Scatter: GC% vs FC
- Heatmap de estructura secundaria

**¿Qué nos dice?**
- ¿miRNAs con más G son más susceptibles?
- ¿Estructura afecta susceptibilidad a oxidación?

---

#### **C.2: Análisis Posicional Detallado**
**Pregunta:** ¿Qué posiciones específicas de la seed están afectadas?

**Método:**
```R
# Para cada candidato:
# - Identificar posición exacta del G>T (2, 3, 4, 5, 6, 7, o 8)
# - Contar frecuencia por posición
# - Comparar con esperado
```

**Figuras:**
- Heatmap: Candidato x Posición seed (2-8)
- Barplot: Frecuencia de G>T por posición
- Logo plot con G>T marcado

**¿Qué nos dice?**
- ¿Posiciones específicas más afectadas? (ej: posición 2-3)
- ¿Patrón posicional específico de ALS?

---

### **GRUPO D: CONTEXTO DE SECUENCIA** 🔥

#### **D.1: Análisis de Trinucleótidos (XGY)**
**Pregunta:** ¿El contexto nucleotídico alrededor del G afecta la oxidación?

**Método:**
```R
# Extraer trinucleótidos XGY (X = base antes, Y = base después)
# Comparar candidatos vs background
# Enriquecimiento de ciertos contextos (ej: GGG, CGG, TGG, AGG)
```

**Figuras:**
- Heatmap: Candidato x Contexto (16 trinucleótidos posibles)
- Barplot: Frecuencia de contextos
- Logo plot de región extendida (seed ± 2 nt)

**Conocido en literatura:**
- **GpG** es más susceptible a 8-oxoG
- **CpG** islas también
- Contexto afecta tasa de mutación

**¿Qué nos dice?**
- ¿Los G en contexto GpG están más oxidados?
- ¿Secuencia específica predice susceptibilidad?

---

#### **D.2: Regiones Flanqueantes**
**Pregunta:** ¿Las regiones alrededor de la seed tienen características?

**Método:**
```R
# Analizar 5' UTR (antes de seed) y 3' región
# Contenido G, estructura
# Accesibilidad (predicción)
```

---

### **GRUPO E: COMPARACIÓN CANDIDATOS ALS vs CONTROL**

#### **E.1: Los 22 Candidatos Control**
**Pregunta:** ¿Por qué 22 miRNAs tienen MÁS G>T en Control?

**Método:**
```R
# Analizar los 22 enriquecidos en Control
# Comparar familias, estructuras, seeds
# ¿Son diferentes de los ALS?
```

**Figuras:**
- Venn: ALS vs Control candidates
- Comparación de características (G-content, familias, etc.)
- Heatmap ALS vs Control

**¿Qué nos dice?**
- ¿Mecanismo protector en Control?
- ¿Respuesta compensatoria?
- ¿Diferentes tipos de oxidación?

---

### **GRUPO F: ANÁLISIS MULTI-PRESET**

#### **F.1: Análisis de Sensibilidad**
**Pregunta:** ¿Qué características son robustas entre presets?

**Método:**
```R
# Comparar candidatos de:
#   - STRICT (1)
#   - MODERATE (3)
#   - PERMISSIVE (15)
# ¿Qué comparten los 15?
# ¿Los top 3 son diferentes del resto?
```

**Figuras:**
- Venn de 3 presets
- Características compartidas vs únicas
- Gradiente de robustez

---

## 📊 FIGURAS TOTALES DEL PASO 2.5

### **Estimado: 18-25 figuras**

**Grupo A: Clustering (5)**
- Dendrograma muestras
- Heatmap muestras x candidatos
- PCA muestras
- K-means ALS subtypes
- Silhouette plot

**Grupo B: Familias (4)**
- Familias enriquecidas
- Network familias
- Árbol filogenético
- Seed similarity

**Grupo C: Estructura (4)**
- G-content candidatos vs background
- GC% vs FC
- Estructura secundaria
- Posiciones seed afectadas

**Grupo D: Contexto (4)**
- Trinucleótidos XGY
- Contexto nucleotídico
- Logo plot extendido
- Flanking regions

**Grupo E: ALS vs Control (3)**
- Venn ALS/Control
- Comparación características
- Heatmap diferencias

**Grupo F: Multi-preset (3)**
- Venn 3 presets
- Características compartidas
- Gradiente robustez

---

## 🔥 ANÁLISIS PRIORITARIOS (TOP 5)

### **1. CLUSTERING DE MUESTRAS** ⭐⭐⭐
¿ALS se separa de Control usando solo candidatos?
→ Valida que son buenos biomarcadores

### **2. FAMILIAS DE miRNAs** ⭐⭐⭐
¿Los candidatos son de familias específicas?
→ Susceptibilidad familiar a oxidación

### **3. SEED SEQUENCES** ⭐⭐⭐
¿Hay motivos conservados en seeds?
→ Identifica secuencia vulnerable

### **4. TRINUCLEÓTIDOS (XGY)** ⭐⭐
¿Contexto GpG o CpG enriquecido?
→ Mecanismo molecular de 8-oxoG

### **5. ALS vs CONTROL CANDIDATES** ⭐⭐
¿Por qué 22 en Control?
→ Mecanismos opuestos

---

## 🚀 WORKFLOW SUGERIDO

### **OPCIÓN 1: Análisis Completo (Recomendado)**

```bash
# 1. Ejecutar PERMISSIVE (15 candidatos)
cd pipeline_definitivo/
Rscript RUN_WITH_THRESHOLDS.R permissive

# 2. NUEVO: Ejecutar Paso 2.5 (Patrones)
cd pipeline_2.5/
cp ../results_threshold_permissive/ALS_candidates.csv data/
Rscript RUN_PASO2.5_COMPLETE.R
# Tiempo: ~30 minutos
# Output: ~20 figuras de patrones

# 3. Revisar HTML del Paso 2.5
open PASO_2.5_PATRONES.html

# 4. LUEGO Paso 3 (Funcional)
cd ../pipeline_3/
cp ../results_threshold_permissive/ALS_candidates.csv data/
Rscript RUN_PASO3_COMPLETE.R
```

---

### **OPCIÓN 2: Análisis Rápido (Solo prioritarios)**

```bash
# Solo los 5 análisis prioritarios
cd pipeline_2.5/
Rscript RUN_PASO2.5_PRIORITARIOS.R
# Tiempo: ~15 minutos
# Output: ~10 figuras esenciales
```

---

## 📂 ESTRUCTURA PROPUESTA

```
pipeline_2.5/                        ← NUEVO PASO
├── scripts/
│   ├── 01_clustering_samples.R      ← Clustering de muestras
│   ├── 02_family_analysis.R         ← Análisis de familias
│   ├── 03_seed_sequences.R          ← Seeds y motivos
│   ├── 04_structure_analysis.R      ← G-content, GC%, etc.
│   ├── 05_trinucleotide_context.R   ← Análisis XGY
│   ├── 06_als_vs_control_candidates.R ← Comparar ALS/Control
│   └── 07_multipreset_comparison.R  ← Comparar presets
│
├── RUN_PASO2.5_COMPLETE.R           ← Script maestro
├── RUN_PASO2.5_PRIORITARIOS.R       ← Solo top 5
│
├── data/
│   ├── ALS_candidates.csv           ← Input (de RUN_WITH_THRESHOLDS)
│   └── (outputs de cada análisis)
│
├── figures/                         ← ~20 figuras
│
└── PASO_2.5_PATRONES.html           ← HTML viewer
```

---

## 🎯 PREGUNTAS QUE RESPONDERÁ

### **Del Clustering:**
1. ¿ALS se separa de Control?
2. ¿Hay subtipos de ALS?
3. ¿Candidatos son buenos biomarcadores?

### **De Familias:**
4. ¿Familias específicas enriquecidas? (let-7, miR-9, etc.)
5. ¿Seeds similares entre candidatos?
6. ¿Relación evolutiva?

### **De Secuencias:**
7. ¿Motivos conservados en seeds?
8. ¿Posiciones específicas más afectadas?
9. ¿Contexto GpG enriquecido?

### **De Estructura:**
10. ¿G-content correlaciona con FC?
11. ¿GC% afecta susceptibilidad?
12. ¿Estructura secundaria relevante?

### **De Comparación:**
13. ¿Por qué 22 en Control?
14. ¿ALS vs Control diferentes?
15. ¿Características robustas entre presets?

---

## 💡 HIPÓTESIS A TESTEAR

### **Hipótesis 1: Clustering**
**H0:** Muestras ALS y Control se mezclan aleatoriamente
**H1:** Muestras ALS forman cluster separado

### **Hipótesis 2: Familias**
**H0:** Candidatos son de familias aleatorias
**H1:** Familias específicas enriquecidas (ej: let-7, miR-9)

### **Hipótesis 3: Contexto GpG**
**H0:** G>T ocurre en cualquier contexto
**H1:** G>T enriquecido en contexto GpG (más susceptible)

### **Hipótesis 4: Susceptibilidad**
**H0:** G-content NO correlaciona con oxidación
**H1:** miRNAs con más G tienen más G>T

---

## 🔬 ANÁLISIS DETALLADOS

### **1. CLUSTERING DE MUESTRAS (Prioritario)**

**Script:** `01_clustering_samples.R`

```R
# Crear matriz solo con candidatos
mat <- data_long %>%
  filter(miRNA_name %in% candidates$miRNA) %>%
  select(miRNA_name, Sample_ID, VAF) %>%
  pivot_wider(names_from = miRNA_name, values_from = VAF)

# Clustering jerárquico
dist_mat <- dist(mat[,-1])
hc <- hclust(dist_mat, method = "ward.D2")

# PCA
pca <- prcomp(mat[,-1], scale = TRUE)

# K-means (solo ALS)
als_samples <- mat %>% filter(Sample_ID %in% metadata_als$Sample_ID)
km <- kmeans(als_samples[,-1], centers = 3)
```

**Figuras:**
1. Dendrograma coloreado (ALS/Control)
2. Heatmap samples x candidates (con clustering)
3. PCA (PC1 vs PC2)
4. K-means ALS subtypes
5. Silhouette plot

---

### **2. FAMILIAS miRNA (Prioritario)**

**Script:** `02_family_analysis.R`

```R
# Extraer familia de cada miRNA
extract_family <- function(mirna) {
  # ej: hsa-miR-196a-5p → miR-196
  # ej: hsa-let-7d-5p → let-7
  str_extract(mirna, "(let-\\d+|miR-\\d+)")
}

candidates$family <- sapply(candidates$miRNA, extract_family)

# Enriquecimiento de familias
family_counts <- candidates %>%
  count(family) %>%
  arrange(desc(n))

# Comparar con background
background_families <- all_301 %>%
  mutate(family = sapply(miRNA_name, extract_family)) %>%
  count(family)

# Test de enriquecimiento
enrichment <- test_family_enrichment(candidates, background_families)
```

**Figuras:**
1. Barplot familias en candidatos
2. Enrichment plot (familias sobre-representadas)
3. Network de familias
4. Seed similarity dentro de familias

---

### **3. SEED SEQUENCES (Prioritario)**

**Script:** `03_seed_sequences.R`

```R
# Cargar secuencias completas de miRNAs (miRBase)
# Extraer seed (pos 2-8)
# Alinear
# Crear logo plot

# Para cada candidato:
seeds <- candidates %>%
  mutate(
    seed_seq = extract_seed(miRNA),  # de miRBase
    gt_position = extract_gt_position(miRNA)  # del dataset
  )

# Análisis de motivos
motifs <- find_conserved_motifs(seeds$seed_seq)

# Contexto del G
g_context <- analyze_g_context(seeds)
```

**Figuras:**
1. **Logo plot de seeds** (WebLogo style)
2. Posición de G>T en cada seed (heatmap)
3. Alineamiento múltiple de seeds
4. Contexto nucleotídico (XGY)

---

### **4. TRINUCLEÓTIDOS XGY (Prioritario)**

**Script:** `05_trinucleotide_context.R`

```R
# Extraer trinucleótidos alrededor de cada G>T
# Formato: XGY donde G es el que muta
# 16 posibilidades: AGY, CGY, GGY, TGY (Y = A,C,G,T)

trinuc <- data_gt %>%
  filter(miRNA_name %in% candidates$miRNA) %>%
  mutate(
    context = extract_trinucleotide(pos.mut, sequence)
  )

# Contar frecuencias
trinuc_counts <- trinuc %>%
  count(context) %>%
  arrange(desc(n))

# Comparar con esperado (background)
expected <- calculate_expected_trinuc_freq(all_sequences)

# Test de enriquecimiento
enrichment <- test_trinuc_enrichment(trinuc_counts, expected)
```

**Figuras:**
1. Heatmap 4x4 (XGY)
2. Barplot contextos enriquecidos
3. Logo plot región extendida
4. Comparación ALS vs Control contexts

**Literatura relevante:**
- GpG → 8-oxoG más frecuente
- CpG → islas CpG oxidables
- Contexto afecta tasa de mutación

---

### **5. ALS vs CONTROL CANDIDATES (Prioritario)**

**Script:** `06_als_vs_control_candidates.R`

```R
# Candidatos ALS (3-15)
als_cand <- volcano_data %>%
  filter(log2FC > threshold, padj < p_threshold)

# Candidatos Control (22)
ctrl_cand <- volcano_data %>%
  filter(log2FC < -threshold, padj < p_threshold)

# Comparar:
# - Familias
# - G-content
# - Seed sequences
# - Estructura

comparison <- compare_groups(als_cand, ctrl_cand)
```

**Figuras:**
1. Venn ALS/Control/No-sig
2. Familias ALS vs Control
3. G-content ALS vs Control
4. Seeds ALS vs Control

---

## 📊 OUTPUTS ESPERADOS

### **Archivos de datos:**
```
data/
├── clustering_results.csv       ← Clusters de muestras
├── family_enrichment.csv        ← Familias enriquecidas
├── seed_sequences.csv           ← Seeds de candidatos
├── trinucleotide_enrichment.csv ← Contextos XGY
├── structure_metrics.csv        ← G-content, GC%, etc.
└── als_vs_control_comparison.csv
```

### **Figuras (~20):**
```
figures/
├── FIG_2.5_A1_CLUSTERING_SAMPLES.png
├── FIG_2.5_A2_PCA_SAMPLES.png
├── FIG_2.5_A3_KMEANS_ALS.png
├── FIG_2.5_B1_FAMILIES_ENRICHED.png
├── FIG_2.5_B2_SEED_SIMILARITY.png
├── FIG_2.5_C1_GCONTENT_BOXPLOT.png
├── FIG_2.5_C2_SEED_POSITIONS.png
├── FIG_2.5_D1_TRINUCLEOTIDE_HEATMAP.png ⭐
├── FIG_2.5_D2_LOGO_PLOT.png ⭐
├── FIG_2.5_E1_ALS_VS_CONTROL.png
└── ... (10-15 más)
```

### **HTML:**
```
PASO_2.5_PATRONES.html
```

---

## 🎯 INTEGRACIÓN CON PIPELINE COMPLETO

```
PASO 1: Análisis Inicial (11 figuras)
  ↓ (301 miRNAs con G>T en seed)
  
PASO 2: QC + Comparativo (15 figuras)
  ↓ (3-15 candidatos según preset)
  
PASO 2.5: PATRONES Y CARACTERÍSTICAS (20 figuras) ← NUEVO
  ↓ (Características de candidatos)
  
PASO 3: Análisis Funcional (9 figuras)
  ↓ (Targets, pathways, networks)
  
PASO 4: Validación (futuro)
```

---

## 💡 POR QUÉ ESTE PASO ES CRUCIAL

### **Antes de targets/pathways, necesitas saber:**

1. **¿Los candidatos son buenos biomarcadores?**
   → Clustering dirá si separan ALS de Control

2. **¿Hay patrón de secuencia?**
   → Seeds/contexto dirán mecanismo molecular

3. **¿Familias específicas?**
   → Susceptibilidad evolutiva/funcional

4. **¿Características estructurales?**
   → G-content predice oxidación

5. **¿Control tiene mecanismo diferente?**
   → 22 candidatos Control son interesantes

---

## 🚀 SIGUIENTE PASO

**¿Quieres que cree el Paso 2.5 completo?**

**Incluiría:**
- 7 scripts R para cada análisis
- Script maestro para ejecutar todo
- ~20 figuras profesionales
- HTML integrado
- Documentación completa

**Tiempo estimado:**
- Crear scripts: ~30 min
- Ejecutar Paso 2.5: ~30 min
- **Total:** ~1 hora

**¿Procedo con la creación del Paso 2.5?** O prefieres que primero hagamos solo los 5 análisis prioritarios?

---

**Documentado:** 2025-10-17 04:10  
**Propuesta:** Paso 2.5 intermedio  
**Análisis:** 6 grupos, ~20 figuras  
**Siguiente:** Crear scripts del Paso 2.5

