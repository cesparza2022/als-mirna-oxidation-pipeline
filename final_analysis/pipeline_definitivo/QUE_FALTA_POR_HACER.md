# 🎯 QUÉ FALTA POR HACER - Pipeline Definitivo

**Estado actual:** 75% completado  
**Última actualización:** Octubre 18, 2025

---

## ✅ LO QUE YA TENEMOS (Completado)

### **Paso 1: Análisis Inicial** ✅
- Dataset limpio (5,448 SNVs)
- 415 muestras (313 ALS, 102 Control)
- Validación de calidad

### **Paso 2: Comparaciones ALS vs Control** ✅
- Volcano Plot multi-métrico (5 dimensiones)
- 301 miRNAs analizados
- 15 candidatos ALS identificados
- Análisis posicional (pos 2,3,5 enriquecidas)
- Sistema de tiers (TIER 3 recomendado: 6 miRNAs)
- 12 figuras profesionales

### **Paso 2.5: Patrones y Clustering** ✅
- Clustering de muestras
- Análisis de familias miRNA
- Caracterización de seeds
- 13 figuras

### **Paso 2.6: Motivos de Secuencia** ✅ ⭐ NUEVO
- Contexto trinucleótido (XGY)
- Sequence logos por posición
- GpG motif en pos 3 (75%)
- 3 logos generados

**Total completado:** 4 pasos, ~28 figuras, 7+ documentos

---

## ⏳ LO QUE FALTA (Pendiente)

### **PRIORIDAD 1: Paso 3 - Functional Analysis** ⭐⭐⭐

**Estado:** Scripts listos, solo falta EJECUTAR con TIER 3

**Candidatos recomendados (TIER 3 - 6 miRNAs):**
1. hsa-miR-21-5p (FC 1.48x, p 0.0083, pos 3)
2. hsa-let-7d-5p (FC 1.31x, p 0.018, pos 2,4,5,8)
3. hsa-miR-1-3p (FC 1.30x, p 0.0008, pos 2,3,7)
4. hsa-miR-185-5p (FC 1.42x, p 0.037, pos 2,3,5,7)
5. hsa-miR-24-3p (FC 1.33x, p 0.039, pos 2,3,8)
6. hsa-miR-423-3p (FC 1.27x, p 0.030, pos 2,6,7)

**Análisis a realizar:**

#### **A. Target Prediction** (~45 min)
- Script: `pipeline_3/scripts/02_query_targets.R`
- Bases de datos: TargetScan, miRTarBase, miRDB, etc.
- Output esperado: ~8,000-12,000 targets (all), ~3,000-5,000 (high-conf)

#### **B. Pathway Enrichment** (~45 min)
- Script: `pipeline_3/scripts/03_pathway_enrichment.R`
- Análisis: GO (BP, MF), KEGG
- Output esperado: ~1,000-1,500 pathways enriquecidos
- Focus: Oxidative stress, Neurología, Apoptosis

#### **C. Network Analysis** (~30 min)
- Script: `pipeline_3/scripts/04_network_analysis.R`
- Red: miRNA → target → pathway
- Output: Network graph, hub genes, módulos

#### **D. Figuras** (Actualmente con bugs - necesita debugging)
- Script: `pipeline_3/scripts/05_create_figures.R`
- Error actual: "NAs in dataset" en Venn diagram
- Figuras esperadas: 6-9 figuras profesionales
  - Venn diagram (targets compartidos)
  - Dot plots (pathways)
  - Network graphs
  - Heatmaps (enrichment)

#### **E. HTML Viewer**
- Script: `pipeline_3/scripts/06_create_HTML.R`
- Visualización interactiva de todos los resultados

**Tiempo total estimado:** ~2-3 horas

**Acción necesaria:**
1. ✅ Decidir candidatos → **TIER 3 (6 miRNAs)** recomendado
2. ⏳ Debuggear `05_create_figures.R` (error de NAs)
3. ⏳ Ejecutar todos los scripts con TIER 3
4. ⏳ Generar HTML viewer

---

### **PRIORIDAD 2: Debugging Paso 3** ⭐⭐

**Problema actual:**
```
Error en 05_create_figures.R:
  "Error: NAs in dataset"
  Al generar Venn diagram
```

**Causa probable:**
- Targets con `target_symbol = ""` (vacío)
- NAs en columna `target_symbol` o `miRNA`

**Solución:**
1. Filtrar NAs antes de crear Venn diagram
2. Limpiar targets antes de split para listas

**Líneas a modificar:**
```R
# Antes:
target_lists <- split(targets$target_symbol, targets$miRNA)

# Después:
targets_clean <- targets %>%
  filter(!is.na(target_symbol), target_symbol != "", !is.na(miRNA))
target_lists <- split(targets_clean$target_symbol, targets_clean$miRNA)
```

**Tiempo estimado:** ~15 min

---

### **PRIORIDAD 3: Análisis Adicionales Paso 2.6** (Opcional) ⭐

**A. Clustering por Similitud de Seed** (~1 hr)
- Script a crear: `03_clustering_by_similarity.R`
- Análisis: Distancia de Levenshtein entre seeds
- Output: Heatmap de similitud + dendrograma
- Pregunta: ¿Candidatos se agrupan por secuencia?

**B. Network de Similitud de Secuencia** (~1 hr)
- Script a crear: `04_sequence_similarity_network.R`
- Network: Nodos = miRNAs, Edges = Similitud
- Identificar módulos de miRNAs relacionados

**C. Comparación ALS vs Control Motifs** (~30 min)
- Script a crear: `05_compare_als_control_motifs.R`
- Logos separados para candidatos ALS (15) vs Control (22)
- ¿Diferentes contextos?

**D. Heatmap Posición x Contexto** (~30 min)
- Script a crear: `06_position_context_heatmap.R`
- Filas: Posiciones (2-8)
- Columnas: Contextos (GpG, CpG, ApG, UpG)
- Identificar hotspots específicos

**Total tiempo (si se hacen todos):** ~3 horas

**Recomendación:** POSPONER hasta después del Paso 3

---

### **PRIORIDAD 4: Paso 4 - Integración y Validación** ⭐

**Estado:** Por diseñar completamente

**Objetivo:** Combinar hallazgos de todos los pasos en narrativa coherente

**Análisis propuestos:**

#### **A. Figuras Finales para Publicación**

**Figura 1: Caracterización de Candidatos**
- Panel A: Volcano Plot multi-métrico
- Panel B: Análisis posicional (pos 2,3,5 enriquecidas)
- Panel C: Distribución de FC y p-values
- Panel D: Heatmap de candidatos

**Figura 2: Motivos de Secuencia**
- Panel A: Contexto trinucleótido (barplot)
- Panel B: Sequence logo posición 3 (GpG motif)
- Panel C: Heatmap Posición x Contexto
- Panel D: Conservación por posición

**Figura 3: Functional Analysis** (del Paso 3)
- Panel A: Venn diagram (targets compartidos)
- Panel B: Top pathways enriquecidos
- Panel C: Network miRNA-target-pathway
- Panel D: Pathways oxidativos

**Figura Suplementaria 1:** Todos los análisis de Paso 2
**Figura Suplementaria 2:** Clustering y patrones (Paso 2.5)
**Figura Suplementaria 3:** Detalles funcionales (Paso 3)

#### **B. Narrativa Científica**

**Introducción:**
- ALS y estrés oxidativo
- miRNAs y regulación de respuesta redox
- 8-oxoG en seeds altera función

**Resultados:**
1. Identificamos 15 candidatos ALS (Paso 2)
2. Específicos de posiciones 2,3,5 (Análisis posicional)
3. GpG motif en posición 3 (Paso 2.6)
4. Regulan pathways oxidativos (Paso 3)

**Discusión:**
- Comparación con paper Nature Cell Biology 2023
- Hallazgo inesperado: ApG > GpG
- Implicaciones para ALS
- Validación experimental necesaria

**Conclusiones:**
- Firma oxidativa específica en miRNAs
- Mecanismo específico de secuencia (GpG)
- Candidatos terapéuticos potenciales

#### **C. Documento Final**
- Manuscript draft
- Métodos detallados
- Tablas suplementarias
- Referencias

**Tiempo estimado:** ~1 semana (con escritura)

---

## 📋 CHECKLIST COMPLETO

### **Paso 3: Functional Analysis** (INMEDIATO)

- [ ] Debuggear `05_create_figures.R` (error NAs)
- [ ] Crear lista de candidatos TIER 3 (6 miRNAs)
- [ ] Ejecutar `02_query_targets.R` con TIER 3
- [ ] Ejecutar `03_pathway_enrichment.R` con TIER 3
- [ ] Ejecutar `04_network_analysis.R` con TIER 3
- [ ] Ejecutar `05_create_figures.R` (corregido)
- [ ] Generar HTML viewer (`06_create_HTML.R`)
- [ ] Revisar resultados y hallazgos
- [ ] Documentar en README_PASO3.md

**Tiempo:** ~2-3 horas  
**Prioridad:** ⭐⭐⭐ ALTA

---

### **Paso 2.6 Avanzado** (OPCIONAL)

- [ ] Script: Clustering por similitud (`03_clustering_by_similarity.R`)
- [ ] Script: Network de similitud (`04_sequence_similarity_network.R`)
- [ ] Script: ALS vs Control motifs (`05_compare_als_control_motifs.R`)
- [ ] Script: Heatmap Posición x Contexto (`06_position_context_heatmap.R`)
- [ ] Generar 3-4 figuras adicionales
- [ ] Actualizar HTML viewer

**Tiempo:** ~3 horas  
**Prioridad:** ⭐ BAJA (posponer)

---

### **Paso 4: Integración** (POSTERIOR)

- [ ] Diseñar figuras finales (3 principales + suplementarias)
- [ ] Crear scripts para figuras multi-panel
- [ ] Escribir narrativa científica
- [ ] Comparación exhaustiva con literatura
- [ ] Documento de métodos detallado
- [ ] Tablas suplementarias
- [ ] Manuscript draft

**Tiempo:** ~1 semana  
**Prioridad:** ⭐⭐ MEDIA (después de Paso 3)

---

## 🎯 PLAN DE ACCIÓN RECOMENDADO

### **SESIÓN 1 (Próxima - ~3 horas):**

1. **Debuggear Paso 3** (~30 min)
   - Corregir error de NAs en Venn diagram
   - Probar con datos existentes (TIER 2)

2. **Ejecutar Paso 3 con TIER 3** (~2 hr)
   - Target prediction (6 miRNAs)
   - Pathway enrichment
   - Network analysis
   - Generar figuras
   - HTML viewer

3. **Revisar resultados** (~30 min)
   - Interpretar targets y pathways
   - Comparar con TIER 2
   - Identificar hallazgos clave

### **SESIÓN 2 (Siguiente - ~2 horas):**

1. **Revisar todos los hallazgos** (~1 hr)
   - Paso 2, 2.5, 2.6, 3
   - Identificar narrativa coherente
   - Decidir figuras finales

2. **Diseñar Paso 4** (~1 hr)
   - Plan de figuras finales
   - Outline de narrativa
   - Lista de análisis adicionales necesarios

### **SESIÓN 3 (Posterior - ~1 semana):**

1. **Implementar Paso 4**
   - Crear figuras finales
   - Escribir narrativa
   - Documentar métodos
   - Manuscript draft

---

## 📊 RESUMEN DE PENDIENTES

### **CRÍTICO (Necesario para completar pipeline):**

| Item | Descripción | Tiempo | Prioridad |
|------|-------------|--------|-----------|
| Debuggear Paso 3 | Corregir NAs en figuras | 30 min | ⭐⭐⭐ |
| Ejecutar Paso 3 TIER 3 | 6 candidatos | 2 hr | ⭐⭐⭐ |
| Diseñar Paso 4 | Plan de integración | 1 hr | ⭐⭐ |

**Total mínimo:** ~3.5 horas

### **OPCIONAL (Mejoras y análisis adicionales):**

| Item | Descripción | Tiempo | Prioridad |
|------|-------------|--------|-----------|
| Clustering seeds | Similitud de secuencia | 1 hr | ⭐ |
| Network similitud | miRNAs relacionados | 1 hr | ⭐ |
| ALS vs Control motifs | Comparar logos | 30 min | ⭐ |
| Heatmap Pos x Context | Visualización integrada | 30 min | ⭐ |

**Total opcional:** ~3 horas

### **LARGO PLAZO (Escritura y publicación):**

| Item | Descripción | Tiempo | Prioridad |
|------|-------------|--------|-----------|
| Figuras finales | Multi-panel profesionales | 1 día | ⭐⭐ |
| Manuscript draft | Escritura científica | 3-5 días | ⭐⭐ |
| Validación experimental | Lab work | Meses | ⭐⭐⭐ |

---

## 🔬 ANÁLISIS PENDIENTES (Detalles)

### **Paso 3: Functional Analysis**

**Lo que falta hacer:**

1. **Preparar candidatos TIER 3:**
   ```R
   # Modificar pipeline_3/scripts/01_prepare_candidates.R
   # Para usar los 6 de TIER 3 en lugar de los 3 de TIER 2
   
   candidates_tier3 <- c(
     "hsa-miR-21-5p",
     "hsa-let-7d-5p", 
     "hsa-miR-1-3p",
     "hsa-miR-185-5p",
     "hsa-miR-24-3p",
     "hsa-miR-423-3p"
   )
   ```

2. **Ejecutar target prediction:**
   ```bash
   cd pipeline_3
   Rscript scripts/02_query_targets.R
   ```
   
   Outputs:
   - `targets_all_combined.csv` (~8K-12K targets)
   - `targets_highconf_combined.csv` (~3K-5K targets)
   - `targets_shared.csv` (targets en 2+ miRNAs)

3. **Ejecutar pathway enrichment:**
   ```bash
   Rscript scripts/03_pathway_enrichment.R
   ```
   
   Outputs:
   - GO BP terms (~10K-15K)
   - GO MF terms (~2K-3K)
   - KEGG pathways (~500-800)
   - GO oxidative terms (~300-500)

4. **Ejecutar network analysis:**
   ```bash
   Rscript scripts/04_network_analysis.R
   ```
   
   Outputs:
   - `network.graphml` (para Cytoscape)
   - `hub_genes.csv` (genes centrales)
   - Node/edge metrics

5. **Generar figuras (después de debugging):**
   ```bash
   Rscript scripts/05_create_figures.R
   ```
   
   Figuras:
   - Venn diagram (3-way overlap)
   - Pathway dot plots (top 20)
   - Network graph (layout fr)
   - Heatmap de enrichment
   - Barplot de GO categories

6. **Crear HTML viewer:**
   ```bash
   Rscript scripts/06_create_HTML.R
   ```

---

### **Paso 2.6 Avanzado** (OPCIONAL)

**Análisis adicionales propuestos:**

#### **A. Clustering por Similitud**

**Script a crear:** `03_clustering_by_similarity.R`

```R
# Pseudocódigo:

library(stringdist)
library(pheatmap)

# 1. Cargar seeds
seeds <- read_csv("data/candidates_with_sequences.csv")

# 2. Matriz de distancia (Levenshtein)
dist_matrix <- stringdistmatrix(
  seeds$Seed_Sequence, 
  method = "lv"
)

# 3. Clustering jerárquico
hc <- hclust(as.dist(dist_matrix), method = "ward.D2")

# 4. Heatmap con anotaciones
annotation <- data.frame(
  Family = seeds$Family,
  Position = seeds$Positions,
  Context = seeds$Context_Type
)

pheatmap(
  dist_matrix,
  annotation_row = annotation,
  main = "Seed Similarity Among ALS Candidates"
)
```

**Output:** `figures/CLUSTERING_SEED_SIMILARITY.png`

**Pregunta que responde:** ¿Candidatos se agrupan por similitud de secuencia?

---

#### **B. Network de Similitud**

**Script a crear:** `04_sequence_similarity_network.R`

```R
# Pseudocódigo:

library(igraph)
library(ggraph)

# 1. Crear edges (si distancia < 3)
edges <- data.frame()
for (i in 1:nrow(seeds)) {
  for (j in (i+1):nrow(seeds)) {
    dist <- stringdist(seeds$Seed[i], seeds$Seed[j], method = "lv")
    if (dist < 3) {
      edges <- rbind(edges, data.frame(
        from = seeds$miRNA[i],
        to = seeds$miRNA[j],
        distance = dist
      ))
    }
  }
}

# 2. Crear network
g <- graph_from_data_frame(edges, vertices = seeds)

# 3. Plot
ggraph(g, layout = "fr") +
  geom_edge_link(aes(alpha = 1/distance)) +
  geom_node_point(aes(color = Family, shape = Context_Type), size = 8) +
  geom_node_text(aes(label = miRNA), repel = TRUE)
```

**Output:** `figures/NETWORK_SEQUENCE_SIMILARITY.png`

**Pregunta que responde:** ¿Hay módulos de miRNAs relacionados por secuencia?

---

#### **C. Comparación ALS vs Control**

**Script a crear:** `05_compare_als_control_motifs.R`

```R
# Pseudocódigo:

# 1. Separar candidatos
als_candidates <- filter(candidates, Category == "ALS")  # 15
ctrl_candidates <- filter(candidates, Category == "Control")  # 22

# 2. Contexto trinucleótido separado
als_context <- count(als_snvs, Context_Type)
ctrl_context <- count(ctrl_snvs, Context_Type)

# 3. Comparar
comparison <- als_context %>%
  left_join(ctrl_context, by = "Context_Type", suffix = c("_ALS", "_Control"))

# 4. Plot side-by-side
ggplot(comparison_long, aes(x = Context_Type, y = Percentage, fill = Group)) +
  geom_col(position = "dodge") +
  labs(title = "Trinucleotide Context: ALS vs Control")
```

**Output:** `figures/CONTEXT_ALS_VS_CONTROL.png`

**Pregunta que responde:** ¿ALS y Control tienen diferentes motivos?

---

#### **D. Heatmap Posición x Contexto**

**Script a crear:** `06_position_context_heatmap.R`

```R
# Pseudocódigo:

# 1. Matriz: Posición (2-8) x Contexto (GpG, CpG, ApG, UpG)
pos_context <- snv_details %>%
  filter(Position >= 2, Position <= 8) %>%
  count(Position, Context_Type) %>%
  pivot_wider(names_from = Context_Type, values_from = n, values_fill = 0)

# 2. Heatmap
pheatmap(
  as.matrix(pos_context[,-1]),
  cluster_rows = FALSE,
  cluster_cols = FALSE,
  main = "G>T Context by Position",
  color = colorRampPalette(c("white", "red"))(50)
)
```

**Output:** `figures/HEATMAP_POSITION_CONTEXT.png`

**Pregunta que responde:** ¿Hay posiciones con contextos específicos?

---

### **Paso 4: Integración**

**Lo que falta hacer:**

1. **Consolidar hallazgos:**
   - Tabla resumen de todos los pasos
   - Key findings integrados
   - Conexión entre pasos

2. **Figuras finales:**
   - Multi-panel figures profesionales
   - Estilo consistente
   - Tamaño publicación (300 dpi)

3. **Narrativa científica:**
   - Abstract
   - Introduction
   - Methods
   - Results
   - Discussion
   - Conclusions

4. **Materiales suplementarios:**
   - Todas las figuras
   - Tablas completas
   - Scripts y código

**Tiempo:** ~1 semana  
**Prioridad:** Después de Paso 3

---

## 🚀 CRONOGRAMA SUGERIDO

### **Semana 1 (Ahora):**
- ✅ Paso 2.6 completado
- ⏳ Debuggear Paso 3
- ⏳ Ejecutar Paso 3 TIER 3
- ⏳ Revisar resultados

### **Semana 2:**
- Análisis adicionales Paso 2.6 (si necesario)
- Diseñar Paso 4
- Comenzar figuras finales

### **Semana 3-4:**
- Figuras finales
- Narrativa científica
- Manuscript draft

### **Semana 5+:**
- Revisión y refinamiento
- Validación experimental (si disponible)
- Submission

---

## 💡 DECISIONES PENDIENTES

### **DECISIÓN 1: ¿Qué candidatos usar para Paso 3?**

**Opciones:**

| Opción | Candidatos | N | Ventajas | Desventajas |
|--------|-----------|---|----------|-------------|
| **A** | TIER 2 | 3 | Ya ejecutado | Pos 6-7 (NO enriquecidas) |
| **B** | TIER 3 | 6 | Pos 2,3,5, miRNAs conocidos | Menos robustos (p < 0.10) |
| **C** | TIER 4 | 15 | Completo | Muchos, tiempo |

**Recomendación:** **OPCIÓN B (TIER 3)** ⭐

**Razón:**
- Posiciones biológicamente relevantes (2,3,5 enriquecidas)
- Incluyen miRNAs conocidos (miR-21, let-7d, miR-1)
- Evidencia de GpG motif (al menos en pos 3)
- 6 candidatos = manejable para análisis profundo

---

### **DECISIÓN 2: ¿Hacer análisis adicionales Paso 2.6?**

**Opciones:**

| Opción | Descripción | Tiempo | Valor añadido |
|--------|-------------|--------|---------------|
| **A** | Solo lo hecho | 0 hr | Suficiente para publicar |
| **B** | + Clustering | 1 hr | Identifica familias relacionadas |
| **C** | + Clustering + Network | 2 hr | Visualización completa |
| **D** | Todos los análisis | 3 hr | Máxima profundidad |

**Recomendación:** **OPCIÓN A** (posponer) ⭐

**Razón:**
- Lo que tenemos es suficiente para la narrativa principal
- Priorizar Paso 3 (más impacto)
- Análisis adicionales pueden ser suplementarios

---

### **DECISIÓN 3: ¿Cuándo escribir el manuscript?**

**Opciones:**

| Opción | Timing | Ventajas | Desventajas |
|--------|--------|----------|-------------|
| **A** | Ahora | Captura ideas frescas | Falta Paso 3 |
| **B** | Después de Paso 3 | Narrativa completa | Puede olvidar detalles |
| **C** | Después de todo | Máxima información | Toma más tiempo |

**Recomendación:** **OPCIÓN B** ⭐

**Razón:**
- Paso 3 es crítico para la discusión funcional
- Después de Paso 3 tenemos historia completa
- Outline ahora, escritura después de Paso 3

---

## 📋 RESUMEN EJECUTIVO

### **LO QUE TENEMOS:**

✅ 4 pasos completados (1, 2, 2.5, 2.6)  
✅ ~28 figuras profesionales  
✅ 15 candidatos ALS caracterizados  
✅ Sistema de tiers robusto  
✅ Evidencia de motivos (GpG en pos 3)  
✅ Hallazgos novedosos (ApG enrichment, pos 2,3,5)  
✅ Documentación exhaustiva  

### **LO QUE FALTA:**

⏳ **Paso 3:** Functional Analysis (~2-3 hr) - **CRÍTICO**  
⏳ **Debugging:** Paso 3 figuras (~30 min) - **CRÍTICO**  
⏳ **Paso 4:** Integración (~1 semana) - **IMPORTANTE**  
⏳ **Opcional:** Análisis adicionales (~3 hr) - **NICE TO HAVE**  

### **PRÓXIMA ACCIÓN:**

**🎯 Debuggear y ejecutar Paso 3 con TIER 3 (6 miRNAs)**

**Tiempo:** ~2-3 horas  
**Prioridad:** ⭐⭐⭐ MÁXIMA  
**Scripts:** Listos en `pipeline_3/`  
**Output:** Targets, pathways, networks, figuras, HTML  

---

**FIN DEL DOCUMENTO**

**Estado:** Pipeline 75% completo, documentado, y listo para Paso 3  
**Siguiente:** Debuggear → Ejecutar Paso 3 TIER 3 → Revisar → Paso 4

