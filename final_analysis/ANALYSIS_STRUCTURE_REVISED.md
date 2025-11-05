# 🔬 ESTRUCTURA DE ANÁLISIS REVISADA - Pipeline miRNA Oxidation

**Filosofía**: **General → Específico | Todos los SNVs → Solo G>T (Oxidación)**

**Fecha**: Octubre 15, 2025  
**Versión**: 2.0 (Revisada por usuario)

---

## 🎯 **FILOSOFÍA DEL ANÁLISIS**

### Progresión Lógica:

```
1. PREPARACIÓN
   └─ Dataset original → Split-collapse → VAF filtering

2. PANORAMA GENERAL (Todos los SNVs)
   ├─ A nivel de miRNA (cuáles son los más mutados)
   ├─ Comparación ALS vs Control (diferencias generales)
   └─ Distribuciones globales

3. ENFOQUE EN OXIDACIÓN (Solo G>T)
   ├─ Mismo análisis que en (2) pero filtrado a G>T
   ├─ Identificar señal específica de oxidación
   └─ Comparar con panorama general

4. ANÁLISIS POSICIONAL
   ├─ Distribución por posición (1-23)
   ├─ Identificar hotspots
   └─ Seed vs non-seed

5. miRNAs DE INTERÉS (G>T en seed)
   ├─ Top miRNAs oxidados en región funcional
   ├─ Análisis de familias (let-7, etc.)
   └─ Patrones específicos

6. ANÁLISIS AVANZADOS
   ├─ Clustering de muestras/miRNAs
   ├─ Pathway analysis
   ├─ Temporal analysis
   └─ Motifs y mecanismos
```

**Ventaja**: Primero entendemos el **panorama completo** (contexto), luego nos enfocamos en lo que **realmente nos interesa** (oxidación G>T).

---

## 📊 **ESTRUCTURA DETALLADA POR NIVELES**

---

## 🔧 **NIVEL 1: PREPARACIÓN DE DATOS**

### Paso 1.1: Cargar Dataset Original
**Input**: `miRNA_count.Q33.txt` (68,969 filas × 832 columnas)  
**Output**: `raw_data` (data.frame en memoria)

**Procesos**:
- Leer archivo TSV
- Validar formato (832 columnas, nombres correctos)
- Identificar columnas metadata, SNV, totales
- Parsear nombres de muestras (cohort, timepoint)

**Outputs**:
```
outputs/step_01_prep/
├── tables/
│   └── 01_dataset_info.csv
└── summary.txt
```

**Estadísticas**:
- Filas: 68,969
- miRNAs únicos: ~1,728
- Muestras: 415 (313 ALS, 102 Control)

---

### Paso 1.2: Split-Collapse
**Input**: `raw_data`  
**Output**: `split_collapsed_data`

**Procesos**:
- **Split**: Separar mutaciones múltiples (`5:GT,7:AG` → 2 filas)
- **Collapse**: Agrupar por (miRNA, pos:mut), sumar cuentas

**Outputs**:
```
outputs/step_01_prep/
├── tables/
│   ├── 02_split_collapse_transformation.csv
│   └── 02_antes_despues_stats.csv
└── figures/
    └── 02_split_collapse_sankey.png
```

**Estadísticas esperadas**:
- Antes split: 68,969 filas
- Después split: ~72,000 filas (algunas múltiples)
- Después collapse: ~29,000 filas (eliminadas duplicadas)

---

### Paso 1.3: Calcular VAFs
**Input**: `split_collapsed_data`  
**Output**: `vaf_data`

**Procesos**:
- Para cada muestra: VAF = SNV_count / Total_miRNA
- Crear 415 columnas nuevas: `VAF_Sample_1`, `VAF_Sample_2`, ...

**Outputs**:
```
outputs/step_01_prep/
├── tables/
│   └── 03_vaf_statistics.csv
└── figures/
    └── 03_vaf_distribution_all.png
```

---

### Paso 1.4: Filtrar VAFs > 50%
**Input**: `vaf_data`  
**Output**: `filtered_data` (dataset limpio)

**Procesos**:
- Convertir VAF > 50% → NaN (no eliminar filas)
- Calcular cobertura post-filtrado

**Outputs**:
```
outputs/step_01_prep/
├── tables/
│   ├── 04_vaf_filtered_stats.csv
│   └── 04_coverage_analysis.csv
└── figures/
    └── 04_vaf_filtering_impact.png
```

**Estadísticas esperadas**:
- ~0.2% de valores convertidos a NaN
- ~29,000 SNVs con cobertura válida

---

## 📈 **NIVEL 2: PANORAMA GENERAL - TODOS LOS SNVs**

**Objetivo**: Entender el **contexto completo** antes de enfocarnos en oxidación

---

### Paso 2.1: Análisis por miRNA (Cantidad de SNVs)
**Input**: `filtered_data`  
**Output**: Ranking de miRNAs por número de SNVs

**Preguntas**:
- ¿Cuáles miRNAs tienen más SNVs detectados?
- ¿Hay familias con más variabilidad?

**Análisis**:
```r
snv_per_mirna <- filtered_data %>%
  group_by(`miRNA name`) %>%
  summarise(
    n_snvs = n_distinct(`pos:mut`),
    n_positions = n_distinct(position)
  ) %>%
  arrange(desc(n_snvs))
```

**Outputs**:
```
outputs/step_02_general/
├── tables/
│   ├── 01_mirna_snv_counts.csv
│   └── 01_top50_mirnas_by_snvs.csv
└── figures/
    ├── 01_top20_mirnas_snv_barplot.png
    └── 01_snv_distribution_histogram.png
```

**Visualizaciones**:
- Barplot: Top 20 miRNAs por # de SNVs
- Histogram: Distribución de SNVs por miRNA

---

### Paso 2.2: Análisis por miRNA (Cantidad de Cuentas)
**Input**: `filtered_data`  
**Output**: Ranking de miRNAs por suma total de cuentas

**Preguntas**:
- ¿Cuáles SNVs tienen más reads totales?
- ¿Alta cantidad de SNVs = alta cantidad de cuentas?

**Análisis**:
```r
counts_per_mirna <- filtered_data %>%
  group_by(`miRNA name`) %>%
  summarise(
    total_snv_counts = sum(across(starts_with("Magen-"), ~sum(.x, na.rm=TRUE))),
    mean_snv_count = mean(across(starts_with("Magen-"), ~mean(.x, na.rm=TRUE)))
  ) %>%
  arrange(desc(total_snv_counts))
```

**Outputs**:
```
outputs/step_02_general/
├── tables/
│   ├── 02_mirna_count_totals.csv
│   └── 02_top50_mirnas_by_counts.csv
└── figures/
    ├── 02_top20_mirnas_counts_barplot.png
    └── 02_snvs_vs_counts_scatter.png
```

**Visualizaciones**:
- Barplot: Top 20 miRNAs por suma de cuentas
- Scatter: SNVs vs Cuentas (correlación?)

---

### Paso 2.3: Análisis por miRNA (VAF Promedio)
**Input**: `filtered_data`  
**Output**: Ranking de miRNAs por VAF promedio

**Preguntas**:
- ¿Cuáles miRNAs tienen mayor representación de mutaciones?
- ¿Alto # SNVs = alto VAF?

**Análisis**:
```r
vaf_per_mirna <- filtered_data %>%
  group_by(`miRNA name`) %>%
  summarise(
    mean_vaf = mean(across(starts_with("VAF_"), ~mean(.x, na.rm=TRUE))),
    median_vaf = median(across(starts_with("VAF_"), ~median(.x, na.rm=TRUE))),
    max_vaf = max(across(starts_with("VAF_"), ~max(.x, na.rm=TRUE)))
  ) %>%
  arrange(desc(mean_vaf))
```

**Outputs**:
```
outputs/step_02_general/
├── tables/
│   ├── 03_mirna_vaf_stats.csv
│   └── 03_top50_mirnas_by_vaf.csv
└── figures/
    ├── 03_top20_mirnas_vaf_barplot.png
    ├── 03_snvs_vs_vaf_scatter.png
    └── 03_counts_vs_vaf_scatter.png
```

**Visualizaciones**:
- Barplot: Top 20 miRNAs por VAF promedio
- Scatter: SNVs vs VAF
- Scatter: Cuentas vs VAF

---

### Paso 2.4: Comparación ALS vs Control (General)
**Input**: `filtered_data` + metadata (cohorts)  
**Output**: Diferencias globales entre grupos

**Preguntas**:
- ¿ALS tiene más SNVs que Control en general?
- ¿Diferencias en VAF entre grupos?

**Análisis**:
```r
# Separar muestras ALS vs Control
als_samples <- filter(metadata, cohort == "ALS")$sample_id
ctrl_samples <- filter(metadata, cohort == "control")$sample_id

# Comparar VAFs
vaf_comparison <- filtered_data %>%
  mutate(
    mean_vaf_als = rowMeans(select(., all_of(paste0("VAF_", als_samples))), na.rm=TRUE),
    mean_vaf_ctrl = rowMeans(select(., all_of(paste0("VAF_", ctrl_samples))), na.rm=TRUE),
    vaf_diff = mean_vaf_als - mean_vaf_ctrl
  )

# Test estadístico
t_test_results <- vaf_comparison %>%
  rowwise() %>%
  mutate(
    p_value = t.test(
      c_across(starts_with("VAF_") & matches(paste(als_samples, collapse="|"))),
      c_across(starts_with("VAF_") & matches(paste(ctrl_samples, collapse="|")))
    )$p.value
  )
```

**Outputs**:
```
outputs/step_02_general/
├── tables/
│   ├── 04_als_vs_control_vaf_comparison.csv
│   ├── 04_significant_snvs.csv (FDR < 0.05)
│   └── 04_summary_stats_by_group.csv
└── figures/
    ├── 04_vaf_als_vs_control_boxplot.png
    ├── 04_vaf_als_vs_control_scatter.png
    ├── 04_volcano_plot.png
    └── 04_pvalue_distribution.png
```

**Visualizaciones**:
- Boxplot: Distribución VAF en ALS vs Control
- Scatter: VAF_ALS vs VAF_Control
- Volcano plot: Fold-change vs p-value
- Histogram: Distribución de p-values

---

## 🔥 **NIVEL 3: ENFOQUE EN OXIDACIÓN - SOLO G>T**

**Objetivo**: Replicar análisis de Nivel 2 **pero solo con mutaciones G>T**

**Filtro**:
```r
gt_data <- filtered_data %>%
  filter(str_detect(`pos:mut`, "GT$"))  # Solo mutaciones G→T
```

---

### Paso 3.1: Análisis por miRNA - G>T (Cantidad)
**Input**: `gt_data`  
**Output**: Ranking de miRNAs por # de G>T

**Preguntas**:
- ¿Cuáles miRNAs tienen más G>T?
- ¿Coinciden con los más mutados en general (Paso 2.1)?

**Outputs**:
```
outputs/step_03_gt_specific/
├── tables/
│   ├── 01_mirna_gt_counts.csv
│   └── 01_top50_mirnas_gt.csv
└── figures/
    ├── 01_top20_mirnas_gt_barplot.png
    └── 01_gt_vs_all_snvs_comparison.png
```

**Visualización clave**:
- Comparación lado-a-lado: Top 20 (Todos SNVs) vs Top 20 (Solo G>T)
- ¿Hay overlap? ¿Hay miRNAs enriquecidos en G>T?

---

### Paso 3.2: Análisis por miRNA - G>T (Cuentas)
**Input**: `gt_data`  
**Output**: Ranking de miRNAs por suma de cuentas G>T

**Outputs**:
```
outputs/step_03_gt_specific/
├── tables/
│   ├── 02_mirna_gt_count_totals.csv
│   └── 02_top50_mirnas_gt_counts.csv
└── figures/
    ├── 02_top20_mirnas_gt_counts_barplot.png
    └── 02_gt_counts_vs_all_counts_scatter.png
```

---

### Paso 3.3: Análisis por miRNA - G>T (VAF)
**Input**: `gt_data`  
**Output**: Ranking de miRNAs por VAF promedio de G>T

**Outputs**:
```
outputs/step_03_gt_specific/
├── tables/
│   ├── 03_mirna_gt_vaf_stats.csv
│   └── 03_top50_mirnas_gt_vaf.csv
└── figures/
    ├── 03_top20_mirnas_gt_vaf_barplot.png
    └── 03_gt_vaf_vs_all_vaf_scatter.png
```

---

### Paso 3.4: Comparación ALS vs Control - G>T
**Input**: `gt_data` + metadata  
**Output**: Diferencias en G>T entre grupos

**Preguntas**:
- ¿ALS tiene más G>T que Control? (señal de oxidación)
- ¿Más significativo que con todos los SNVs?

**Análisis**:
- Mismo que Paso 2.4 pero solo con G>T
- Comparar significancia: ¿más SNVs significativos?

**Outputs**:
```
outputs/step_03_gt_specific/
├── tables/
│   ├── 04_als_vs_control_gt_comparison.csv
│   ├── 04_significant_gt_snvs.csv
│   └── 04_comparison_all_vs_gt.csv  # Meta-análisis
└── figures/
    ├── 04_gt_vaf_als_vs_control_boxplot.png
    ├── 04_gt_volcano_plot.png
    └── 04_significance_all_vs_gt_comparison.png
```

**Visualización clave**:
- Comparar volcano plots: Todos SNVs vs Solo G>T
- ¿Señal de oxidación más fuerte en G>T?

---

## 📍 **NIVEL 4: ANÁLISIS POSICIONAL**

**Objetivo**: Entender **dónde** ocurren las mutaciones (posiciones 1-23)

---

### Paso 4.1: Distribución por Posición (Todos los SNVs)
**Input**: `filtered_data` + anotación de posición  
**Output**: Frecuencia de SNVs por posición

**Análisis**:
```r
# Extraer posición de pos:mut
positional_data <- filtered_data %>%
  mutate(position = as.integer(str_extract(`pos:mut`, "^\\d+")))

# Contar por posición
snvs_per_position <- positional_data %>%
  group_by(position) %>%
  summarise(
    n_snvs = n(),
    mean_vaf = mean(across(starts_with("VAF_"), ~mean(.x, na.rm=TRUE)))
  )
```

**Outputs**:
```
outputs/step_04_positional/
├── tables/
│   ├── 01_snvs_by_position.csv
│   └── 01_vaf_by_position.csv
└── figures/
    ├── 01_snvs_per_position_barplot.png
    ├── 01_vaf_per_position_lineplot.png
    └── 01_position_heatmap_all.png
```

**Visualizaciones**:
- Barplot: # SNVs en cada posición 1-23
- Lineplot: VAF promedio por posición
- Heatmap: VAF por posición × miRNA (top 50 miRNAs)

---

### Paso 4.2: Distribución por Posición (Solo G>T)
**Input**: `gt_data` + anotación de posición  
**Output**: Frecuencia de G>T por posición

**Preguntas**:
- ¿Hay posiciones hotspot para G>T?
- ¿Enriquecimiento en seed (2-8)?

**Outputs**:
```
outputs/step_04_positional/
├── tables/
│   ├── 02_gt_by_position.csv
│   └── 02_gt_hotspots.csv
└── figures/
    ├── 02_gt_per_position_barplot.png
    ├── 02_gt_vaf_per_position_lineplot.png
    ├── 02_position_heatmap_gt.png
    └── 02_all_vs_gt_position_comparison.png
```

**Visualización clave**:
- Comparar lado-a-lado: Distribución posicional (Todos) vs (Solo G>T)
- Highlight seed region (2-8)

---

### Paso 4.3: Seed vs Non-Seed (G>T)
**Input**: `gt_data` + anotación de región  
**Output**: Comparación seed (2-8) vs resto

**Análisis**:
```r
gt_by_region <- gt_data %>%
  mutate(
    position = as.integer(str_extract(`pos:mut`, "^\\d+")),
    region = ifelse(position >= 2 & position <= 8, "Seed", "Non-Seed")
  ) %>%
  group_by(region) %>%
  summarise(
    n_gt = n(),
    mean_vaf = mean(across(starts_with("VAF_"), ~mean(.x, na.rm=TRUE))),
    n_mirnas = n_distinct(`miRNA name`)
  )
```

**Outputs**:
```
outputs/step_04_positional/
├── tables/
│   ├── 03_seed_vs_nonseed_gt.csv
│   └── 03_gt_by_functional_region.csv (seed, central, 3')
└── figures/
    ├── 03_seed_vs_nonseed_barplot.png
    ├── 03_seed_vs_nonseed_vaf_boxplot.png
    └── 03_functional_regions_comparison.png
```

---

## 🎯 **NIVEL 5: TOP miRNAs CON G>T EN SEED**

**Objetivo**: Enfocarnos en miRNAs con **oxidación en región funcional crítica**

**Filtro**:
```r
mirnas_gt_in_seed <- gt_data %>%
  mutate(position = as.integer(str_extract(`pos:mut`, "^\\d+"))) %>%
  filter(position >= 2 & position <= 8) %>%
  distinct(`miRNA name`)

# ~270 miRNAs esperados
```

---

### Paso 5.1: Caracterización de miRNAs con G>T en Seed
**Input**: Lista de ~270 miRNAs  
**Output**: Perfil completo de estos miRNAs

**Análisis**:
```r
mirna_gt_seed_profile <- filtered_data %>%
  filter(`miRNA name` %in% mirnas_gt_in_seed$`miRNA name`) %>%
  group_by(`miRNA name`) %>%
  summarise(
    n_total_snvs = n(),
    n_gt_snvs = sum(str_detect(`pos:mut`, "GT$")),
    n_gt_in_seed = sum(str_detect(`pos:mut`, "GT$") & 
                       as.integer(str_extract(`pos:mut`, "^\\d+")) %in% 2:8),
    prop_gt = n_gt_snvs / n_total_snvs,
    mean_vaf_all = ...,
    mean_vaf_gt = ...
  ) %>%
  arrange(desc(n_gt_in_seed))
```

**Outputs**:
```
outputs/step_05_gt_seed/
├── tables/
│   ├── 01_mirnas_with_gt_in_seed.csv (270 miRNAs)
│   ├── 01_top50_by_gt_seed_count.csv
│   └── 01_mirna_profiles.csv
└── figures/
    ├── 01_top20_mirnas_gt_seed.png
    ├── 01_gt_seed_distribution_histogram.png
    └── 01_proportion_gt_vs_all_scatter.png
```

---

### Paso 5.2: Análisis de Familias (let-7, miR-30, etc.)
**Input**: miRNAs con G>T en seed + anotación de familias  
**Output**: Patrones por familia

**Análisis**:
```r
# Extraer familia del nombre
family_analysis <- mirna_gt_seed_profile %>%
  mutate(
    family = str_extract(`miRNA name`, "^hsa-(let-7|miR-\\d+)")
  ) %>%
  group_by(family) %>%
  summarise(
    n_members = n(),
    total_gt_seed = sum(n_gt_in_seed),
    mean_gt_per_member = mean(n_gt_in_seed)
  ) %>%
  arrange(desc(total_gt_seed))
```

**Outputs**:
```
outputs/step_05_gt_seed/
├── tables/
│   ├── 02_family_analysis.csv
│   ├── 02_let7_family_detail.csv
│   └── 02_top10_families_gt_seed.csv
└── figures/
    ├── 02_top10_families_barplot.png
    ├── 02_let7_members_heatmap.png
    └── 02_family_comparison.png
```

---

### Paso 5.3: Posiciones Específicas en Seed (2, 4, 5, 6, 7, 8)
**Input**: G>T en seed  
**Output**: Frecuencia por posición específica del seed

**Preguntas**:
- ¿Todas las posiciones del seed igual de oxidadas?
- ¿Patrón específico? (ej. let-7: posiciones 2, 4, 5)

**Outputs**:
```
outputs/step_05_gt_seed/
├── tables/
│   ├── 03_gt_by_seed_position.csv
│   └── 03_position_specific_patterns.csv
└── figures/
    ├── 03_seed_position_barplot.png
    ├── 03_seed_position_heatmap.png (miRNA × posición)
    └── 03_let7_position_pattern.png
```

**Visualización clave**:
- Heatmap: Top 50 miRNAs × Posiciones seed (2-8)
- Identificar patrones específicos (ej. let-7: siempre 2,4,5)

---

## 🧬 **NIVEL 6: ANÁLISIS AVANZADOS**

### Paso 6.1: Clustering de Muestras
**Input**: Matriz VAF (miRNAs × muestras)  
**Output**: Clusters de muestras

**Preguntas**:
- ¿Las muestras se agrupan por cohort (ALS vs Control)?
- ¿Hay subgrupos dentro de ALS?

**Métodos**:
- PCA
- Hierarchical clustering (Ward.D2)
- Silhouette analysis

**Outputs**:
```
outputs/step_06_advanced/
├── tables/
│   ├── 01_pca_results.csv
│   ├── 01_cluster_assignments.csv
│   └── 01_cluster_characteristics.csv
└── figures/
    ├── 01_pca_plot.png
    ├── 01_dendrogram.png
    └── 01_cluster_heatmap.png
```

---

### Paso 6.2: Clustering de miRNAs
**Input**: Matriz VAF transpuesta (muestras × miRNAs)  
**Output**: Clusters de miRNAs

**Preguntas**:
- ¿Hay grupos de miRNAs co-oxidados?
- ¿Clusters corresponden a familias?

**Outputs**:
```
outputs/step_06_advanced/
├── tables/
│   ├── 02_mirna_clusters.csv
│   └── 02_cluster_enrichment.csv (¿enriquecimiento en familias?)
└── figures/
    ├── 02_mirna_dendrogram.png
    └── 02_mirna_heatmap.png
```

---

### Paso 6.3: Pathway Analysis
**Input**: Lista de miRNAs con G>T en seed (~270)  
**Output**: Pathways enriquecidos

**Procesos**:
- Predicción de targets (TargetScan)
- Enrichment (KEGG, Reactome, GO)
- Overlap con genes ALS conocidos

**Outputs**:
```
outputs/step_06_advanced/
├── tables/
│   ├── 03_predicted_targets.csv
│   ├── 03_pathway_enrichment.csv
│   ├── 03_als_gene_overlap.csv
│   └── 03_functional_impact_summary.csv
└── figures/
    ├── 03_enrichment_barplot.png
    ├── 03_network_diagram.png
    └── 03_als_overlap_venn.png
```

---

### Paso 6.4: Análisis Temporal (Longitudinal)
**Input**: Muestras longitudinales (enrolment, long_2, long_3, long_4)  
**Output**: Cambios en G>T a lo largo del tiempo

**Preguntas**:
- ¿Aumenta G>T con progresión de ALS?
- ¿Clearance de miRNAs oxidados?

**Outputs**:
```
outputs/step_06_advanced/
├── tables/
│   ├── 04_temporal_changes.csv
│   └── 04_clearance_rates.csv
└── figures/
    ├── 04_temporal_scatter.png
    └── 04_clearance_boxplot.png
```

---

### Paso 6.5: Análisis de Motivos y Mecanismos
**Input**: Secuencias de miRNAs + G>T  
**Output**: Contexto de secuencia enriquecido

**Preguntas**:
- ¿G>T ocurre en contexto G-rich?
- ¿Motivos específicos (GGG, GGGG)?

**Outputs**:
```
outputs/step_06_advanced/
├── tables/
│   ├── 05_sequence_context.csv
│   ├── 05_g_rich_enrichment.csv
│   └── 05_motif_analysis.csv
└── figures/
    ├── 05_sequence_logo.png
    └── 05_g_content_enrichment.png
```

---

## 📋 **RESUMEN: ESTRUCTURA DE MÓDULOS FINAL**

### Nuevo Esquema (Lógico y Progresivo):

```
MÓDULO 1: PREPARACIÓN
├─ 1.1: Cargar dataset
├─ 1.2: Split-collapse
├─ 1.3: Calcular VAFs
└─ 1.4: Filtrar VAF > 50%

MÓDULO 2: PANORAMA GENERAL (Todos los SNVs)
├─ 2.1: Por miRNA (# SNVs)
├─ 2.2: Por miRNA (Cuentas)
├─ 2.3: Por miRNA (VAF)
└─ 2.4: ALS vs Control

MÓDULO 3: OXIDACIÓN (Solo G>T)
├─ 3.1: Por miRNA (# G>T)
├─ 3.2: Por miRNA (Cuentas G>T)
├─ 3.3: Por miRNA (VAF G>T)
└─ 3.4: ALS vs Control (G>T)

MÓDULO 4: ANÁLISIS POSICIONAL
├─ 4.1: Distribución por posición (Todos)
├─ 4.2: Distribución por posición (G>T)
└─ 4.3: Seed vs Non-Seed (G>T)

MÓDULO 5: TOP miRNAs (G>T en Seed)
├─ 5.1: Caracterización ~270 miRNAs
├─ 5.2: Análisis de familias
└─ 5.3: Posiciones específicas seed

MÓDULO 6: ANÁLISIS AVANZADOS
├─ 6.1: Clustering muestras
├─ 6.2: Clustering miRNAs
├─ 6.3: Pathway analysis
├─ 6.4: Temporal analysis
└─ 6.5: Motivos y mecanismos
```

**Total**: 6 módulos principales, 21 sub-análisis

---

## 🎯 **VENTAJAS DE ESTA ESTRUCTURA**

### 1. **Progresión Lógica**:
```
General → Específico
Todos los SNVs → Solo G>T
Contexto → Enfoque
```

### 2. **Comparaciones Directas**:
- Módulo 2 vs Módulo 3: ¿G>T diferente del resto?
- Paso 2.4 vs 3.4: ¿Señal ALS más fuerte en G>T?
- Paso 4.1 vs 4.2: ¿Hotspots específicos de G>T?

### 3. **Interpretación Facilitada**:
- Sabemos si hallazgos en G>T son **específicos** o **generales**
- Podemos identificar si G>T tiene **enriquecimiento funcional** (seed)
- Entendemos **contexto completo** antes de conclusiones

### 4. **Reproducible y Modular**:
- Cada módulo independiente
- Puedo correr solo Módulo 2 (panorama general)
- O solo Módulo 3 (enfoque oxidación)
- O completo (1-6)

---

## 🔄 **FLUJO DE EJECUCIÓN**

### Opción A: Completo (Recomendado para primera vez)
```r
run_complete_pipeline(input_file, config, modules = c(1,2,3,4,5,6))
```
**Tiempo**: ~20-25 minutos

---

### Opción B: Solo Preparación + Panorama General
```r
run_complete_pipeline(input_file, config, modules = c(1,2))
```
**Tiempo**: ~5 minutos  
**Uso**: Entender dataset completo

---

### Opción C: Solo Oxidación (Módulos 1, 3-6)
```r
run_complete_pipeline(input_file, config, modules = c(1,3,4,5,6))
```
**Tiempo**: ~15 minutos  
**Uso**: Enfoque directo en G>T (skip panorama general)

---

### Opción D: Modular (Paso a Paso)
```r
# Preparación
module_01 <- run_module_01(input_file)

# Panorama general
module_02 <- run_module_02(input_file)

# Revisar resultados, ajustar config si necesario

# Oxidación
module_03 <- run_module_03(input_file, custom_config)
```

---

## 📊 **OUTPUTS TOTALES ESPERADOS**

### Tablas: ~60 archivos CSV
### Figuras: ~80 imágenes PNG
### Resúmenes: 6 archivos `summary.txt`

### Estructura de outputs:
```
outputs/
├── step_01_prep/                  (4 tablas, 3 figuras)
├── step_02_general/              (12 tablas, 15 figuras)
├── step_03_gt_specific/          (12 tablas, 15 figuras)
├── step_04_positional/           (9 tablas, 12 figuras)
├── step_05_gt_seed/              (9 tablas, 10 figuras)
└── step_06_advanced/             (15 tablas, 20 figuras)
```

---

## ✅ **SIGUIENTE PASO**

Con esta estructura:
1. ✅ Filosofía clara: General → Específico
2. ✅ Comparaciones directas (Módulo 2 vs 3)
3. ✅ Enfoque progresivo en oxidación
4. ✅ Contexto antes de conclusiones

**Próxima acción**: Implementar **Módulo 1 (Preparación)** completo

¿Empezamos con el código de Módulo 1?

---

**Versión**: 2.0 (Revisada)  
**Estado**: ✅ Estructura confirmada  
**Última actualización**: Octubre 15, 2025







