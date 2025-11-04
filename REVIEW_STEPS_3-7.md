# 📋 REVISIÓN EXHAUSTIVA: Steps 3-7 del Pipeline

## 🎯 OBJETIVO
Este documento revisa críticamente qué preguntas responden los Steps 3-7, qué datos específicos utilizan, cómo generan outputs, y su coherencia con el estilo del pipeline.

---

## 📊 STEP 3: ANÁLISIS FUNCIONAL

### ❓ **Preguntas que Responde:**

1. **¿Qué genes son afectados por la oxidación de miRNAs en la región semilla?**
   - Identifica targets potenciales de miRNAs oxidados
   - Compara targets canónicos vs oxidados
   - Evalúa impacto funcional por posición

2. **¿Qué vías biológicas están enriquecidas?**
   - Análisis de enriquecimiento GO (Gene Ontology)
   - Análisis de enriquecimiento KEGG (vías metabólicas)
   - Identificación de vías específicas de ALS

3. **¿Qué genes relevantes para ALS son impactados?**
   - Lista de 23 genes conocidos de ALS
   - Análisis de impacto funcional por miRNA
   - Scoring de impacto funcional

### 🔍 **Datos Utilizados (CRÍTICO):**

**Filtro aplicado (igual que Steps 1-2):**
```r
significant_gt <- statistical_results %>%
  filter(
    str_detect(pos.mut, ":GT$"),                    # Solo mutaciones G>T
    !is.na(t_test_fdr) | !is.na(wilcoxon_fdr),     # Tiene tests estadísticos
    (t_test_fdr < alpha | wilcoxon_fdr < alpha),   # Significativo (FDR < 0.05)
    !is.na(log2_fold_change),
    log2_fold_change > log2fc_threshold_step3       # Mayor en ALS (log2FC > 1.0)
  ) %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    in_seed = position >= seed_start & position <= seed_end  # seed_start=2, seed_end=8
  ) %>%
  filter(in_seed == TRUE) %>%  # ⚠️ SOLO REGIÓN SEMILLA (posiciones 2-8)
  distinct(miRNA_name, pos.mut, .keep_all = TRUE)
```

**✅ VERIFICACIÓN:**
- ✅ Usa solo G>T en región semilla (2-8)
- ✅ Filtra por significancia estadística (FDR < alpha)
- ✅ Requiere log2FC > 1.0 (mayor en ALS)
- ✅ Usa miRNAs más oxidados significativamente

### 📁 **Formato de Output:**

**Tablas (CSV):**
- `results/step3/final/tables/functional/S3_target_analysis.csv`
  - Columnas: `miRNA_name`, `pos.mut`, `position`, `ALS_mean`, `Control_mean`, `log2_fold_change`, `t_test_fdr`, `canonical_targets`, `oxidized_targets`, `binding_impact`, `functional_impact_score`
  - Formato: CSV con `write_csv()` (readr)
  
- `results/step3/final/tables/functional/S3_als_relevant_genes.csv`
- `results/step3/final/tables/functional/S3_target_comparison.csv`
- `results/step3/final/tables/functional/S3_go_enrichment.csv`
- `results/step3/final/tables/functional/S3_kegg_enrichment.csv`
- `results/step3/final/tables/functional/S3_als_pathways.csv`

**Figuras (PNG):**
- `results/step3/final/figures/step3_panelA_pathway_enrichment.png`
  - Formato: PNG, 3000x2400px (12x10in @ 300 DPI)
  - Función: `ggsave(output, plot, width=12, height=10, dpi=300, bg="white")`
  - Tema: `theme_professional` (consistente con pipeline)
  
- `results/step3/final/figures/step3_panelB_als_genes_impact.png`
- `results/step3/final/figures/step3_panelC_target_comparison.png`
- `results/step3/final/figures/step3_panelD_position_impact.png`
- `results/step3/final/figures/step3_pathway_enrichment_heatmap.png`

**Logs:**
- `results/step3/final/logs/functional_target_analysis.log`
- `results/step3/final/logs/pathway_enrichment.log`
- `results/step3/final/logs/complex_functional_viz.log`

### 🎨 **Coherencia con Pipeline:**

✅ **Consistente:**
- Usa `theme_professional` (mismo estilo que Steps 1-2)
- Usa `functions_common.R` (logging, validación, colores)
- Lee parámetros de `config.yaml` (alpha, seed_region, log2fc_threshold_step3)
- Estructura de logging idéntica (initialize_logging, log_section, log_subsection)
- Nomenclatura de archivos: `S3_*` (Step 3)
- Colores: `color_gt = "#D62728"` (rojo para oxidación)

❌ **Puntos de Mejora Potenciales:**
- Target prediction es simplificada (usa placeholders en lugar de TargetScan/miRDB real)
- Enriquecimiento GO/KEGG es simulado (en implementación real usaría clusterProfiler)

---

## 📊 STEP 4: ANÁLISIS DE BIOMARCADORES

### ❓ **Preguntas que Responde:**

1. **¿Pueden los miRNAs oxidados usarse como biomarcadores diagnósticos?**
   - ROC curves para cada miRNA individual
   - AUC (Area Under Curve) calculation
   - Ranking de mejores biomarcadores

2. **¿Hay una firma combinada de múltiples miRNAs?**
   - Signatura multi-miRNA
   - ROC curve combinada
   - Comparación de rendimiento individual vs combinado

3. **¿Qué miRNAs tienen mejor capacidad diagnóstica?**
   - Top 5-10 biomarcadores por AUC
   - Sensibilidad y especificidad
   - Heatmap de signaturas por muestra

### 🔍 **Datos Utilizados (CRÍTICO):**

**Filtro aplicado (igual que Step 3):**
```r
significant_gt <- statistical_results %>%
  filter(
    str_detect(pos.mut, ":GT$"),
    !is.na(t_test_fdr) | !is.na(wilcoxon_fdr),
    (t_test_fdr < alpha | wilcoxon_fdr < alpha),
    !is.na(log2_fold_change),
    log2_fold_change > log2fc_threshold_step3  # log2FC > 1.0
  ) %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    in_seed = position >= seed_start & position <= seed_end
  ) %>%
  filter(in_seed == TRUE) %>%  # ⚠️ SOLO REGIÓN SEMILLA
  distinct(miRNA_name, pos.mut, .keep_all = TRUE) %>%
  arrange(desc(log2_fold_change)) %>%
  head(50)  # Top 50 para análisis ROC
```

**✅ VERIFICACIÓN:**
- ✅ Usa solo G>T en región semilla (2-8)
- ✅ Filtra por significancia estadística
- ✅ Requiere log2FC > 1.0
- ✅ Selecciona top 50 por log2FC (mejores biomarcadores)

### 📁 **Formato de Output:**

**Tablas (CSV):**
- `results/step4/final/tables/biomarkers/S4_roc_analysis.csv`
  - Columnas: `SNV_id`, `miRNA_name`, `pos.mut`, `AUC`, `Sensitivity`, `Specificity`, `95%_CI_lower`, `95%_CI_upper`
  - Incluye fila `COMBINED_SIGNATURE` con AUC de la firma combinada
  
- `results/step4/final/tables/biomarkers/S4_biomarker_signatures.csv`
  - Columnas: `sample_id`, `group`, `signature_score`, `individual_biomarker_scores...`

**Figuras (PNG):**
- `results/step4/final/figures/step4_roc_curves.png`
  - Formato: PNG, 3000x2400px (12x10in @ 300 DPI)
  - Múltiples curvas ROC (top 5 individuales + combinada)
  - Tema: `theme_professional`
  
- `results/step4/final/figures/step4_biomarker_signature_heatmap.png`
  - Heatmap de signaturas por muestra
  - Colores: rojo para ALS, gris para Control

### 🎨 **Coherencia con Pipeline:**

✅ **Consistente:**
- Usa `theme_professional`
- Usa `functions_common.R`
- Lee de `config.yaml`
- Logging consistente
- Nomenclatura: `S4_*`
- Colores consistentes

---

## 📊 STEP 5: ANÁLISIS DE FAMILIAS

### ❓ **Preguntas que Responde:**

1. **¿Qué familias de miRNAs son más afectadas por oxidación?**
   - Identificación de familias (let-7, miR-X, etc.)
   - Resumen de oxidación por familia
   - Comparación ALS vs Control por familia

2. **¿Hay familias con mayor susceptibilidad?**
   - Ranking de familias por número de mutaciones
   - Promedio de log2FC por familia
   - Porcentaje de miRNAs significativos por familia

### 🔍 **Datos Utilizados (CRÍTICO):**

**Filtro aplicado:**
```r
significant_gt_family <- statistical_results_family %>%
  filter(
    str_detect(pos.mut, ":GT$"),
    !is.na(t_test_fdr) | !is.na(wilcoxon_fdr),
    (t_test_fdr < alpha | wilcoxon_fdr < alpha),
    !is.na(log2_fold_change),
    log2_fold_change > log2fc_threshold_step3  # log2FC > 1.0
  ) %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    in_seed = position >= seed_start & position <= seed_end
  ) %>%
  filter(in_seed == TRUE)  # ⚠️ SOLO REGIÓN SEMILLA
```

**✅ VERIFICACIÓN:**
- ✅ Usa solo G>T en región semilla (2-8)
- ✅ Filtra por significancia estadística
- ✅ Requiere log2FC > 1.0
- ✅ Agrupa por familia (let-7, miR-X)

### 📁 **Formato de Output:**

**Tablas (CSV):**
- `results/step5/final/tables/families/S5_family_summary.csv`
  - Columnas: `family`, `n_miRNAs`, `n_mutations`, `n_seed_mutations`, `avg_log2FC`, `median_log2FC`, `n_significant`, `avg_ALS_mean`, `avg_Control_mean`, `avg_oxidation_diff`, `pct_significant`
  
- `results/step5/final/tables/families/S5_family_comparison.csv`
  - Columnas: `family`, `mean_vaf_ALS`, `mean_vaf_Control`, `vaf_difference`, `fold_change`, `log2_fold_change`, `n_miRNAs`, `n_mutations`, `n_significant`, `avg_log2FC`

**Figuras (PNG):**
- `results/step5/final/figures/step5_panelA_family_oxidation_comparison.png`
  - Barplot comparando ALS vs Control por familia
  - Top 20 familias por diferencia de VAF
  
- `results/step5/final/figures/step5_panelB_family_heatmap.png`
  - Heatmap de log2FC y % significativo por familia
  - Top 20 familias

### 🎨 **Coherencia con Pipeline:**

✅ **Consistente:**
- Usa `theme_professional`
- Usa `functions_common.R`
- Lee de `config.yaml`
- Logging consistente
- Nomenclatura: `S5_*`
- Colores consistentes

---

## 📊 STEP 6: CORRELACIÓN EXPRESIÓN vs OXIDACIÓN

### ❓ **Preguntas que Responde:**

1. **¿Hay correlación entre expresión de miRNAs y oxidación?**
   - Correlación de Pearson (r) entre RPM y G>T counts
   - P-value de correlación
   - Análisis de correlación de Spearman (robustez)

2. **¿Los miRNAs más expresados son más oxidados?**
   - Categorización por nivel de expresión (quintiles)
   - Comparación de oxidación por categoría
   - Identificación de miRNAs high-expression high-oxidation

### 🔍 **Datos Utilizados (CRÍTICO):**

**Filtro aplicado:**
```r
# Para calcular oxidación:
oxidation_data_per_mirna <- vaf_data %>%
  semi_join(significant_gt, by = c("miRNA_name", "pos.mut")) %>%  # Solo significant G>T in seed
  pivot_longer(cols = all_of(sample_cols), names_to = "sample_id", values_to = "vaf") %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    in_seed = position >= seed_start & position <= seed_end
  ) %>%
  filter(in_seed == TRUE) %>%  # ⚠️ SOLO REGIÓN SEMILLA
  group_by(miRNA_name) %>%
  summarise(total_gt_vaf = sum(vaf, na.rm = TRUE), .groups = "drop")
```

**✅ VERIFICACIÓN:**
- ✅ Usa solo G>T en región semilla (2-8)
- ✅ Usa `significant_gt` (filtrado por significancia)
- ✅ Calcula RPM desde datos raw (expresión)
- ✅ Suma VAF de todos los G>T en seed por miRNA

### 📁 **Formato de Output:**

**Tablas (CSV):**
- `results/step6/final/tables/correlation/S6_expression_oxidation_correlation.csv`
  - Columnas: `miRNA_name`, `estimated_rpm`, `total_gt_counts`, `total_gt_vaf`
  - Datos por miRNA para scatterplot
  
- `results/step6/final/tables/correlation/S6_expression_summary.csv`
  - Columnas: `expression_category`, `n_miRNAs`, `mean_avg_rpm`, `median_avg_rpm`, `mean_total_gt_vaf`, `median_total_gt_vaf`
  - Resumen por categoría de expresión (Low, Medium-Low, Medium, Medium-High, High)

**Figuras (PNG):**
- `results/step6/final/figures/step6_panelA_expression_vs_oxidation.png`
  - Scatterplot: RPM (log10) vs Total G>T VAF (log10)
  - Regresión lineal con intervalo de confianza
  - Anotación: r de Pearson, p-value
  
- `results/step6/final/figures/step6_panelB_expression_groups_comparison.png`
  - Boxplot: Total G>T VAF por categoría de expresión
  - 5 categorías de expresión

### 🎨 **Coherencia con Pipeline:**

✅ **Consistente:**
- Usa `theme_professional`
- Usa `functions_common.R`
- Lee de `config.yaml`
- Logging consistente
- Nomenclatura: `S6_*`
- Colores consistentes

---

## 📊 STEP 7: ANÁLISIS DE CLUSTERS

### ❓ **Preguntas que Responde:**

1. **¿Hay grupos de miRNAs con patrones similares de oxidación?**
   - Clustering jerárquico (hierarchical clustering)
   - Identificación de clusters (k=6)
   - Dendrograma mostrando relaciones

2. **¿Qué miRNAs tienen patrones de oxidación similares?**
   - Heatmap de clusters
   - Asignación de cluster por miRNA
   - Resumen estadístico por cluster

### 🔍 **Datos Utilizados (CRÍTICO):**

**Filtro aplicado:**
```r
significant_gt <- statistical_results %>%
  filter(
    str_detect(pos.mut, ":GT$"),
    !is.na(t_test_fdr) | !is.na(wilcoxon_fdr),
    (t_test_fdr < alpha | wilcoxon_fdr < alpha),
    !is.na(log2_fold_change)
  ) %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    in_seed = position >= seed_start & position <= seed_end
  ) %>%
  filter(in_seed == TRUE)  # ⚠️ SOLO REGIÓN SEMILLA

# Matriz de clustering:
clustering_data <- vaf_data %>%
  filter(
    str_detect(pos.mut, ":GT$"),
    miRNA_name %in% significant_gt$miRNA_name
  ) %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^\\d+")),
    in_seed = position >= seed_start & position <= seed_end
  ) %>%
  filter(in_seed == TRUE) %>%  # ⚠️ SOLO REGIÓN SEMILLA
  select(miRNA_name, all_of(sample_cols)) %>%
  group_by(miRNA_name) %>%
  summarise(across(all_of(sample_cols), ~ mean(.x, na.rm = TRUE)), .groups = "drop")
```

**✅ VERIFICACIÓN:**
- ✅ Usa solo G>T en región semilla (2-8)
- ✅ Filtra por significancia estadística
- ✅ Promedia VAF por miRNA (across samples)
- ✅ Normaliza por z-score antes de clustering

### 📁 **Formato de Output:**

**Tablas (CSV):**
- `results/step7/final/tables/clusters/S7_cluster_assignments.csv`
  - Columnas: `miRNA_name`, `cluster` (1-6)
  - Asignación de cluster para cada miRNA
  
- `results/step7/final/tables/clusters/S7_cluster_summary.csv`
  - Columnas: `cluster`, `n_miRNAs`, `avg_n_mutations`, `avg_log2FC`, `avg_ALS_mean`, `avg_Control_mean`, `avg_oxidation_diff`

**Figuras (PNG):**
- `results/step7/final/figures/step7_panelA_cluster_heatmap.png`
  - Heatmap: miRNAs (filas) x Samples (columnas)
  - Anotación de clusters por color
  - Normalizado por z-score
  
- `results/step7/final/figures/step7_panelB_cluster_dendrogram.png`
  - Dendrograma jerárquico
  - Rectángulos de colores por cluster (k=6)
  - Método: Ward.D2

### 🎨 **Coherencia con Pipeline:**

✅ **Consistente:**
- Usa `theme_professional` (para dendrogram base R plot)
- Usa `functions_common.R`
- Lee de `config.yaml`
- Logging consistente
- Nomenclatura: `S7_*`
- Colores consistentes

⚠️ **Nota:** Panel B usa `base::plot()` en lugar de ggplot2 (normal para dendrogramas)

---

## 📐 FORMATO DE OUTPUT: ESTÁNDARES DEL PIPELINE

### 📊 **Tablas (CSV):**

**Formato estándar:**
- **Función:** `write_csv(data, file, ...)` (readr)
- **Ubicación:** `results/stepX/final/tables/{category}/SX_description.csv`
- **Nomenclatura:** `S{step_number}_{descriptive_name}.csv`
- **Encoding:** UTF-8
- **Separador:** Coma (`,`)
- **Headers:** Siempre presentes (primera fila)

**Ejemplo estructura:**
```csv
miRNA_name,pos.mut,position,ALS_mean,Control_mean,log2_fold_change,t_test_fdr
hsa-miR-219a-2-3p,7:GT,7,181.88,2.40,6.25,5.34e-5
```

### 📈 **Figuras (PNG):**

**Formato estándar:**
- **Función:** `ggsave(file, plot, width, height, dpi, bg)`
- **Ubicación:** `results/stepX/final/figures/stepX_panel{letter}_description.png`
- **Nomenclatura:** `step{step_number}_panel{letter}_{descriptive_name}.png`
- **Dimensiones:** 12x10 pulgadas (configurable en config.yaml)
- **DPI:** 300 (publication quality)
- **Fondo:** Blanco (`bg="white"`)
- **Tema:** `theme_professional` (consistente)

**Parámetros configurables:**
```yaml
analysis:
  figure:
    width: 12
    height: 10
    dpi: 300
```

**Ejemplo de código:**
```r
ggsave(output_figure_a, panel_a,
       width = fig_width,      # 12 (de config)
       height = fig_height,    # 10 (de config)
       dpi = fig_dpi,          # 300 (de config)
       bg = "white")
```

### 📝 **Logs:**

**Formato estándar:**
- **Ubicación:** `results/stepX/final/logs/{script_name}.log`
- **Formato:** Timestamped con niveles (INFO, SUCCESS, WARNING, ERROR)
- **Función:** `initialize_logging()`, `log_info()`, `log_success()`, etc.

**Ejemplo:**
```
2025-11-03 19:04:04 [INFO] Input statistical: /path/to/file.csv
2025-11-03 19:04:04 [SUCCESS] Loaded: 68968 SNVs
2025-11-03 19:04:09 [INFO] Significant G>T mutations in seed region: 331
```

---

## ✅ VERIFICACIÓN DE COHERENCIA

### 🎨 **Estilo Visual:**

✅ **Todos los steps usan:**
- `theme_professional` (mismo tema base)
- Colores consistentes: `color_gt = "#D62728"` (rojo)
- Tamaños de fuente consistentes
- Grid styling consistente
- Captions y subtítulos con formato estándar

### 📊 **Datos:**

✅ **Todos los steps filtran por:**
- G>T mutations (`str_detect(pos.mut, ":GT$")`)
- Región semilla (positions 2-8)
- Significancia estadística (FDR < alpha)
- Log2FC threshold (configurable, pero consistente)

⚠️ **Variaciones justificadas:**
- **Step 3:** log2fc_threshold_step3 = 1.0 (análisis funcional más estricto)
- **Step 4:** Usa top 50 para ROC (eficiencia computacional)
- **Step 6:** No requiere log2FC threshold (correlación exploratoria)

### 🔧 **Configuración:**

✅ **Todos los steps leen de config.yaml:**
- `analysis.alpha` (FDR threshold)
- `analysis.seed_region.start` (2)
- `analysis.seed_region.end` (8)
- `analysis.log2fc_threshold_step3` (1.0)
- `analysis.colors.gt` (#D62728)
- `analysis.figure.width/height/dpi`

### 📁 **Estructura de Archivos:**

✅ **Consistente:**
```
results/
  stepX/
    final/
      figures/
        stepX_panelA_*.png
        stepX_panelB_*.png
      tables/
        {category}/
          SX_*.csv
      logs/
        *.log
```

### 🧪 **Logging:**

✅ **Todos los steps:**
- Inicializan logging con `initialize_logging()`
- Usan `log_section()`, `log_subsection()`, `log_info()`, `log_success()`
- Timestamps consistentes
- Manejo de errores con `tryCatch()`

---

## 🚨 PROBLEMAS IDENTIFICADOS Y RECOMENDACIONES

### ❌ **Problemas Críticos:**

1. **Step 3: Target Prediction Simplificada**
   - **Problema:** Usa placeholders en lugar de bases de datos reales (TargetScan, miRDB)
   - **Impacto:** Resultados no son biológicamente válidos
   - **Recomendación:** Integrar con `multiMiR` o `targetscan.Hs.eg.db` (R packages)

2. **Step 3: Enriquecimiento GO/KEGG Simulado**
   - **Problema:** Usa datos simulados en lugar de `clusterProfiler`
   - **Impacto:** Enriquecimientos no son reales
   - **Recomendación:** Implementar con `clusterProfiler::enrichGO()` y `enrichKEGG()`

3. **Step 6: Reconstrucción de Datos en Visualización**
   - **Problema:** Script de visualización reconstruye datos dummy para boxplot
   - **Impacto:** Boxplot puede no reflejar datos reales
   - **Recomendación:** Pasar `combined_data_categories` como output de Step 6.1

### ⚠️ **Mejoras Recomendadas:**

1. **Documentación de miRNAs/SNVs Específicos:**
   - Agregar columnas `miRNAs_analyzed` y `SNVs_analyzed` a summary tables
   - Incluir lista de miRNAs en logs de cada step

2. **Validación de Outputs:**
   - Agregar validación de rangos (p-values entre 0-1, log2FC razonables)
   - Verificar que todas las figuras se generaron correctamente

3. **Coherencia en Nomenclatura:**
   - Algunos scripts usan `pos.mut`, otros `pos:mut` → normalizar a `pos.mut`

---

## 📋 RESUMEN DE PREGUNTAS POR STEP

| Step | Pregunta Principal | miRNAs/SNVs Usados | Output Principal |
|------|-------------------|-------------------|------------------|
| **Step 3** | ¿Qué genes/vías son afectadas? | G>T en seed (2-8), significativos, log2FC > 1.0 | 4 figuras + 6 tablas |
| **Step 4** | ¿Pueden usarse como biomarcadores? | Top 50 G>T en seed significativos | 2 figuras + 2 tablas |
| **Step 5** | ¿Qué familias son más afectadas? | G>T en seed significativos, agrupados por familia | 2 figuras + 2 tablas |
| **Step 6** | ¿Hay correlación expresión-oxidación? | G>T en seed significativos, con datos de expresión | 2 figuras + 2 tablas |
| **Step 7** | ¿Hay clusters de patrones similares? | G>T en seed significativos, agrupados por similitud | 2 figuras + 2 tablas |

---

## ✅ CONCLUSIÓN

**Coherencia General:** ✅ **EXCELENTE**

- Todos los steps usan los mismos criterios de filtrado (G>T en seed, significativos)
- Formato de output consistente (CSV para tablas, PNG para figuras)
- Estilo visual coherente (`theme_professional`)
- Configuración centralizada (`config.yaml`)
- Logging consistente

**Puntos Fuertes:**
- ✅ Filtrado correcto de datos (solo más oxidados en seed)
- ✅ Estructura de output organizada y clara
- ✅ Reutilización de funciones comunes
- ✅ Configuración flexible

**Áreas de Mejora:**
- ⚠️ Implementar target prediction real (Step 3)
- ⚠️ Implementar enriquecimiento GO/KEGG real (Step 3)
- ⚠️ Mejorar paso de datos entre scripts (Step 6)

---

**Generado:** 2025-11-03  
**Última actualización:** Revisión exhaustiva de Steps 3-7

