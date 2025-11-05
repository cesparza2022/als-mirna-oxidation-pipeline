# ESTRATEGIA DE INVESTIGACIÓN - ANÁLISIS FINAL
## miRNA Oxidation in ALS: Global Patterns and Functional Implications

---

## 🎯 **PREGUNTAS PRINCIPALES DE INVESTIGACIÓN**

### **A. SEÑAL GLOBAL DE OXIDACIÓN (ALS vs Control)**
1. **¿Los niveles agregados de G>T son más altos en ALS que en controles?**
2. **¿Cómo se compara G>T con otros cambios de base?**
3. **¿Qué miRNAs están suficientemente expresados para ser funcionalmente relevantes?**

### **B. SEÑALES POSICIONALES (seed vs non-seed)**
4. **¿Qué posiciones (1..n) están más mutadas globalmente?**
5. **¿Dentro de la región seed (2..8), qué posiciones están más mutadas?**
6. **¿Qué posiciones están diferencialmente mutadas (ALS vs Control)?**
7. **¿Hay enriquecimiento de seed vs non-seed (cantidad y diferencial)?**
8. **¿Cuáles son las curvas de diferencia G>T por posición (ALS–Control)?**

### **C. ANÁLISIS PROFUNDO POR miRNA**
9. **¿Para cada miRNA altamente expresado, qué posiciones seed impulsan la señal ALS?**
10. **¿Hay consistencia entre lotes/timepoints/sitios?**

### **D. DESCUBRIMIENTO DE CLUSTERS DE SEED (De Novo)**
11. **¿Qué vectores de seed [VAF en pos 2..8] existen?**
12. **¿Qué clusters estables se pueden descubrir?**
13. **¿Los clusters descubiertos están sesgados hacia ALS?**

### **E. CAPA FUNCIONAL (post-cluster)**
14. **¿Qué semillas de oxidación-mimic se pueden construir?**
15. **¿Cuáles son los targets canónicos vs mimic?**
16. **¿Qué vías/procesos se ganan/pierden? ¿Son relevantes para ALS?**

---

## 📋 **PLAN DE TAREAS ESTRATÉGICO**

### **FASE 1: ANÁLISIS FUNDAMENTAL (PRIORIDAD ALTA)**
**Objetivo**: Establecer la base sólida del paper con datos correctamente procesados

#### **Tarea 1.1: Análisis de Expresión y Calidad de Datos**
- [ ] **Q1**: Identificar miRNAs suficientemente expresados
- [ ] **Q2**: Verificar metadatos de muestras/cohortes
- **Código**: Reciclar de `global_patterns_visualization.R` secciones 1-2
- **Outputs**: `expr_summary.tsv`, `top_miRNAs.tsv`, `fig/top_miRNAs_bar.png`

#### **Tarea 1.2: Señal Global de Oxidación**
- [ ] **Q3**: Comparar niveles agregados G>T (ALS vs Control)
- [ ] **Q4**: Composición de cambios de base
- **Código**: Reciclar secciones 3-4 de `global_patterns_visualization.R`
- **Outputs**: `global_gt_tests.tsv`, `fig/gt_violin_by_group.png`, `composition_by_group.tsv`

#### **Tarea 1.3: Análisis Posicional Básico**
- [ ] **Q5**: Ranking de posiciones más mutadas globalmente
- [ ] **Q6**: Ranking de posiciones seed más mutadas
- [ ] **Q7**: Tipos de mutación en posiciones top
- **Código**: Reciclar secciones 5-6 de `global_patterns_visualization.R`
- **Outputs**: `position_overall_rank.tsv`, `seed_position_rank.tsv`, `fig/position_barplot_*.png`

### **FASE 2: ANÁLISIS DIFERENCIAL (PRIORIDAD ALTA)**
**Objetivo**: Identificar diferencias específicas entre grupos

#### **Tarea 2.1: Tests Diferenciales por Posición**
- [ ] **Q8**: Tests diferenciales por posición (ALS vs Control)
- [ ] **Q9**: Enriquecimiento seed vs non-seed
- [ ] **Q10**: Curvas de diferencia por posición
- **Código**: Nuevo, basado en GLMM y tests estadísticos
- **Outputs**: `position_tests.tsv`, `seed_nonseed_enrichment.tsv`, `fig/volcano_position_effects.png`

#### **Tarea 2.2: Análisis por miRNA Individual**
- [ ] **Q11**: Tests por miRNA y posición
- [ ] **Q12**: Consistencia entre lotes
- **Código**: Nuevo, tests estratificados
- **Outputs**: `miRNA_position_tests.tsv`, `batch_stratified_tests.tsv`

### **FASE 3: DESCUBRIMIENTO DE PATRONES (PRIORIDAD MEDIA)**
**Objetivo**: Identificar patrones complejos y clusters

#### **Tarea 3.1: Clustering de Seed Vectors**
- [ ] **Q13**: Construir vectores de seed [VAF pos 2..8]
- [ ] **Q14**: Descubrir clusters (Ward/HDBSCAN/Spectral)
- [ ] **Q15**: Tests de sesgo ALS en clusters
- **Código**: Nuevo, clustering y análisis de estabilidad
- **Outputs**: `seed_vectors.tsv`, `cluster_membership.tsv`, `fig/cluster_consensus_map.png`

### **FASE 4: ANÁLISIS FUNCIONAL (PRIORIDAD MEDIA)**
**Objetivo**: Implicaciones funcionales de los patrones encontrados

#### **Tarea 4.1: Predicción de Targets**
- [ ] **Q16**: Construir semillas de oxidación-mimic
- [ ] **Q17**: Targets canónicos vs mimic
- **Código**: Nuevo, predicción de targets
- **Outputs**: `mimic_seeds.tsv`, `targets_*`, `fig/upset_delta_targets.png`

#### **Tarea 4.2: Análisis de Enriquecimiento**
- [ ] **Q18**: Enriquecimiento de vías/procesos
- [ ] **Q19**: Estabilidad de targets/terms
- [ ] **Q20**: Ranking de hipótesis
- **Código**: Nuevo, análisis de enriquecimiento
- **Outputs**: `enrichment_*`, `fig/enrichment_heatmap.png`, `hypothesis_ranking.tsv`

### **FASE 5: VALIDACIÓN Y CONTROLES (PRIORIDAD BAJA)**
**Objetivo**: Validar y controlar confounders

#### **Tarea 5.1: Controles Técnicos**
- [ ] **Q21**: Contexto de secuencia alrededor de G oxidado
- [ ] **Q22**: Sesgos de mapeo/técnicos
- [ ] **Q23**: Señales a nivel de familia
- **Código**: Nuevo, análisis de controles
- **Outputs**: `sequence_context.tsv`, `tech_covariate_effects.tsv`, `family_position_tests.tsv`

---

## 🔄 **ESTRATEGIA DE RECICLAJE DE CÓDIGO**

### **Código a Reciclar (con correcciones):**
1. **Preprocesamiento**: ✅ Ya corregido en `01_data_preprocessing.R`
2. **Análisis de expresión**: Secciones 1-2 de `global_patterns_visualization.R`
3. **Visualizaciones básicas**: Secciones 5-6 de `global_patterns_visualization.R`
4. **Estructura de funciones**: Funciones de manejo de VAF, heatmaps, etc.

### **Código a Desarrollar:**
1. **Tests estadísticos diferenciales**: GLMM, tests de enriquecimiento
2. **Clustering**: Ward, HDBSCAN, Spectral clustering
3. **Predicción de targets**: Algoritmos de matching de seed
4. **Análisis de enriquecimiento**: GO/KEGG, análisis de vías

---

## 📊 **ESTRATEGIA DE PAPER**

### **Estructura Propuesta:**
1. **Introducción**: Oxidación de miRNAs en ALS, importancia de G>T
2. **Métodos**: Preprocesamiento, tests estadísticos, clustering
3. **Resultados**:
   - 3.1: Señal global de oxidación
   - 3.2: Patrones posicionales (seed vs non-seed)
   - 3.3: Análisis diferencial por posición
   - 3.4: Clusters de patrones de oxidación
   - 3.5: Implicaciones funcionales
4. **Discusión**: Significado biológico, implicaciones clínicas
5. **Conclusión**: Resumen y direcciones futuras

### **Figuras Clave:**
1. **Figura 1**: Señal global G>T (ALS vs Control)
2. **Figura 2**: Patrones posicionales (heatmap + barras)
3. **Figura 3**: Análisis diferencial por posición
4. **Figura 4**: Clusters de patrones de oxidación
5. **Figura 5**: Implicaciones funcionales (targets, vías)

---

## ⚡ **PRÓXIMOS PASOS INMEDIATOS**

1. **Ejecutar Tarea 1.1**: Análisis de expresión con datos correctos
2. **Ejecutar Tarea 1.2**: Señal global de oxidación
3. **Ejecutar Tarea 1.3**: Análisis posicional básico
4. **Evaluar resultados** y ajustar estrategia según hallazgos

---

## 🎯 **CRITERIOS DE ÉXITO**

- **Estadísticamente robusto**: Tests apropiados, corrección FDR
- **Biológicamente relevante**: Enfoque en región seed, vías ALS
- **Técnicamente sólido**: Preprocesamiento correcto, controles adecuados
- **Visualmente claro**: Figuras que cuentan la historia completa
- **Reproducible**: Código documentado, datos procesados guardados









