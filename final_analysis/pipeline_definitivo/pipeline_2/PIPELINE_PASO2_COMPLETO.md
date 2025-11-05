# 🔧 PIPELINE PASO 2 - DOCUMENTACIÓN COMPLETA PARA AUTOMATIZACIÓN

**Fecha:** 2025-10-17 02:15
**Propósito:** Documentar TODOS los pasos del Paso 2 para crear pipeline automatizado

---

## 📋 ESTRUCTURA DEL PIPELINE PASO 2

```
PASO 2
├── PARTE 1: CONTROL DE CALIDAD (QC)
│   ├── 1.1: Identificar valores VAF sospechosos
│   ├── 1.2: Aplicar filtro (VAF >= 0.5 → NA)
│   ├── 1.3: Generar datos limpios
│   ├── 1.4: Crear 4 figuras de diagnóstico
│   └── 1.5: Generar listas de afectados
│
└── PARTE 2: ANÁLISIS COMPARATIVO
    ├── 2.1: Crear metadata (ALS vs Control)
    ├── 2.2: Re-identificar miRNAs con G>T en seed
    ├── 2.3: Generar 12 figuras en 4 grupos
    │   ├── GRUPO A: Comparaciones Globales (3)
    │   ├── GRUPO B: Análisis Posicional (3)
    │   ├── GRUPO C: Heterogeneidad (3)
    │   └── GRUPO D: Especificidad G>T (3)
    └── 2.4: Crear HTML integrado
```

---

## 🔄 PARTE 1: CONTROL DE CALIDAD (QC)

### **PASO 1.1: Identificar valores VAF sospechosos**

**Objetivo:** Detectar artefactos técnicos (capping a 0.5)

**Input:**
- `final_processed_data.csv` (del Paso 1)

**Proceso:**
```r
# Cargar datos
data <- read.csv("final_processed_data.csv")
sample_cols <- names(data)[3:ncol(data)]

# Buscar valores >= 0.5
all_vaf <- data %>% 
  select(all_of(sample_cols)) %>% 
  as.matrix() %>% 
  as.vector()

values_at_05 <- sum(all_vaf == 0.5, na.rm = TRUE)
values_above_05 <- sum(all_vaf > 0.5, na.rm = TRUE)
```

**Output:**
- Número de valores sospechosos
- Lista de SNVs afectados
- Lista de miRNAs afectados

**Script:** `CORRECT_preprocess_FILTER_VAF.R`

---

### **PASO 1.2: Aplicar filtro**

**Objetivo:** Convertir VAF >= 0.5 a NA

**Proceso:**
```r
# Aplicar filtro a todas las columnas de muestra
data_clean <- data %>%
  mutate(across(all_of(sample_cols), ~ifelse(. >= 0.5, NA, .)))
```

**Output:**
- `final_processed_data_CLEAN.csv`

---

### **PASO 1.3: Generar listas de afectados**

**Objetivo:** Documentar impacto del filtro

**Proceso:**
```r
# SNVs afectados
affected_snvs <- data %>%
  select(miRNA_name, pos.mut, all_of(sample_cols)) %>%
  pivot_longer(cols = all_of(sample_cols), values_to = "VAF") %>%
  filter(VAF >= 0.5) %>%
  group_by(miRNA_name, pos.mut) %>%
  summarise(N_samples = n())

# miRNAs afectados
affected_mirnas <- affected_snvs %>%
  group_by(miRNA_name) %>%
  summarise(N_values = sum(N_samples), N_SNVs = n())
```

**Output:**
- `SNVs_REMOVED_VAF_05.csv`
- `miRNAs_AFFECTED_VAF_05.csv`

---

### **PASO 1.4: Crear figuras de diagnóstico**

**Objetivo:** Visualizar impacto del filtro

**Figuras (4):**
1. **DIAG_1:** Distribución global de VAF (antes/después)
2. **DIAG_2:** Impacto por SNV (top 20 afectados)
3. **DIAG_3:** Impacto por miRNA (top 20 afectados)
4. **DIAG_4:** Tabla resumen del filtro

**Script:** `generate_DIAGNOSTICO_REAL.R`

**Output:** `figures_diagnostico/`

---

## 🔄 PARTE 2: ANÁLISIS COMPARATIVO

### **PASO 2.1: Crear metadata**

**Objetivo:** Asignar grupos ALS/Control a muestras

**Proceso:**
```r
# Extraer IDs de muestras de nombres de columnas
sample_ids <- names(data_clean)[3:ncol(data_clean)]

# Asignar grupos basado en patrón de ID
metadata <- data.frame(
  Sample_ID = sample_ids,
  Group = ifelse(grepl("ALS", sample_ids, ignore.case = TRUE), "ALS", "Control")
)
```

**Output:**
- `metadata.csv` (415 muestras: 313 ALS, 102 Control)

**Script:** `create_metadata.R`

**⚠️ NOTA PARA PIPELINE:** Este paso debe ser CONFIGURABLE por el usuario.

---

### **PASO 2.2: Re-identificar miRNAs con G>T en seed**

**Objetivo:** Ranking actualizado con datos limpios

**Proceso:**
```r
# Filtrar G>T en seed (posiciones 2-8)
seed_gt_data <- data_clean %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(position >= 2, position <= 8)

# Calcular VAF total por miRNA
ranking <- seed_gt_data %>%
  select(all_of(c("miRNA_name", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), values_to = "VAF") %>%
  group_by(miRNA_name) %>%
  summarise(
    Total_Seed_GT_VAF = sum(VAF, na.rm = TRUE),
    Mean_Seed_GT_VAF = mean(VAF, na.rm = TRUE),
    N_Seed_GT_SNVs = n_distinct(pos.mut)
  ) %>%
  arrange(desc(Total_Seed_GT_VAF))
```

**Output:**
- `SEED_GT_miRNAs_CLEAN_RANKING.csv` (301 miRNAs)

**Script:** `REGENERATE_PASO2_CLEAN_DATA.R`

---

### **PASO 2.3: Generar 12 figuras**

#### **GRUPO A: COMPARACIONES GLOBALES (3 figuras)**

**Figura 2.1: VAF Global (Boxplots)**
- **Objetivo:** Comparar VAF total y G>T entre ALS y Control
- **Método:** Boxplots + Wilcoxon test
- **Datos:** VAF total por muestra (método por muestra)
- **Proceso:**
  ```r
  # Calcular VAF total por muestra
  per_sample <- data_clean %>%
    pivot_longer(cols = sample_cols, values_to = "VAF") %>%
    left_join(metadata) %>%
    group_by(Sample_ID, Group) %>%
    summarise(Total_VAF = sum(VAF, na.rm = TRUE))
  
  # Test estadístico
  wilcox.test(Total_VAF ~ Group, data = per_sample)
  ```

**Figura 2.2: Distribuciones VAF**
- **Objetivo:** Comparar distribuciones entre grupos
- **Método:** Histograms + Density plots
- **Datos:** VAF por grupo

**Figura 2.3: Volcano Plot ⭐ (MÉTODO CRÍTICO)**
- **Objetivo:** Identificar miRNAs diferencialmente afectados
- **Método:** Método por muestra (Opción B)
- **Proceso COMPLETO:**
  ```r
  # Para cada miRNA:
  volcano_data <- lapply(all_seed_mirnas, function(mirna) {
    # 1. Extraer datos del miRNA
    mirna_data <- vaf_gt %>% filter(miRNA_name == mirna)
    
    # 2. Calcular VAF total POR MUESTRA
    per_sample <- mirna_data %>%
      group_by(Sample_ID, Group) %>%
      summarise(Total_GT_VAF = sum(VAF, na.rm = TRUE))
    
    # 3. Separar por grupo (valores por muestra)
    als_vals <- per_sample %>% filter(Group == "ALS") %>% pull(Total_GT_VAF)
    ctrl_vals <- per_sample %>% filter(Group == "Control") %>% pull(Total_GT_VAF)
    
    # 4. Calcular medias
    mean_als <- mean(als_vals)
    mean_ctrl <- mean(ctrl_vals)
    
    # 5. Fold Change
    log2FC <- log2((mean_als + 0.0001) / (mean_ctrl + 0.0001))
    
    # 6. Test estadístico (comparando muestras)
    pval <- wilcox.test(als_vals, ctrl_vals)$p.value
    
    return(data.frame(miRNA = mirna, log2FC = log2FC, pvalue = pval))
  })
  
  # 7. Ajuste FDR
  volcano_data$padj <- p.adjust(volcano_data$pvalue, method = "fdr")
  volcano_data$neg_log10_padj <- -log10(volcano_data$padj)
  ```
- **Thresholds:**
  - log2FC: ±0.58 (1.5x)
  - FDR-adjusted p-value: < 0.05
- **Script:** `generate_VOLCANO_CORRECTO.R`

**⚠️ CLAVE:** Este es el método correcto y debe ser el usado en el pipeline.

---

#### **GRUPO B: ANÁLISIS POSICIONAL (3 figuras)**

**Figura 2.4: Heatmap Posicional (top 50)**
- **Objetivo:** Visualizar VAF promedio por posición
- **Método:** Heatmaps ALS y Control lado a lado
- **Datos:** Top 50 miRNAs, mean VAF por posición (1-22)

**Figura 2.5: Heatmap Z-score (top 50)**
- **Objetivo:** Normalizar y comparar patrones
- **Método:** Z-score por miRNA, clustering jerárquico
- **Datos:** Top 50, Z-score de VAF por posición

**Figura 2.6: Perfiles Posicionales**
- **Objetivo:** Comparar VAF promedio por posición
- **Método:** Line plots ALS vs Control
- **Datos:** Mean VAF por posición (1-22)

---

#### **GRUPO C: HETEROGENEIDAD (3 figuras)**

**Figura 2.7: PCA**
- **Objetivo:** Visualizar separación ALS/Control
- **Método:** PCA sobre matriz de VAF por muestra
- **Datos:** Matriz (muestras × miRNAs), filtrar varianza > 0.001
- **Proceso:**
  ```r
  # Crear matriz de VAF por muestra
  pca_matrix <- vaf_gt %>%
    group_by(Sample_ID, miRNA_name) %>%
    summarise(Total_VAF = sum(VAF, na.rm = TRUE)) %>%
    pivot_wider(names_from = miRNA_name, values_from = Total_VAF, values_fill = 0)
  
  # PCA
  pca_result <- prcomp(pca_matrix[, -1], scale = TRUE, center = TRUE)
  ```

**Figura 2.8: Clustering Jerárquico**
- **Objetivo:** Agrupar muestras por perfil de G>T
- **Método:** Heatmap + dendrograma
- **Datos:** Z-score de VAF, clustering ward.D2

**Figura 2.9: Coeficiente de Variación**
- **Objetivo:** Cuantificar variabilidad intra-grupo
- **Método:** CV = SD/mean por miRNA y grupo
- **Datos:** Top miRNAs, comparar CV ALS vs Control

---

#### **GRUPO D: ESPECIFICIDAD G>T (3 figuras)**

**Figura 2.10: Ratio G>T/G>A**
- **Objetivo:** Cuantificar preferencia por G>T vs G>A
- **Método:** Scatter plot, ratio por miRNA
- **Datos:** VAF G>T vs VAF G>A

**Figura 2.11: Heatmap de Tipos de Mutación**
- **Objetivo:** Visualizar todos los tipos de mutación
- **Método:** Heatmaps ALS y Control, todas las mutaciones
- **Datos:** Mean VAF por tipo de mutación y posición

**Figura 2.12: Enriquecimiento Regional**
- **Objetivo:** Comparar seed vs non-seed
- **Método:** Boxplots G>T VAF por región
- **Datos:** VAF por región (seed: 2-8, non-seed: resto)

---

### **PASO 2.4: Crear HTML integrado**

**Objetivo:** Viewer interactivo con todas las figuras

**Estructura HTML:**
```
PASO 2 COMPLETO
├── PARTE 1: QC
│   ├── Estadísticas resumen (cards)
│   ├── Hallazgo crítico (highlight box)
│   └── 4 figuras diagnóstico
│
└── PARTE 2: ANÁLISIS
    ├── Método explicado (key finding box)
    ├── Hallazgo principal (warning box)
    ├── GRUPO A (3 figuras)
    ├── GRUPO B (3 figuras)
    ├── GRUPO C (3 figuras)
    └── GRUPO D (3 figuras)
```

**Script:** `create_HTML_FINAL_COMPLETO.R`

**Output:** `PASO_2_COMPLETO_FINAL.html`

---

## 📊 DEPENDENCIAS Y ORDEN DE EJECUCIÓN

### **Secuencia Obligatoria:**

```
1. CORRECT_preprocess_FILTER_VAF.R
   ↓
2. create_metadata.R
   ↓
3. REGENERATE_PASO2_CLEAN_DATA.R
   ↓
4. generate_DIAGNOSTICO_REAL.R (paralelo)
   ↓
5. generate_VOLCANO_CORRECTO.R
   ↓
6. generate_FIGURAS_RESTANTES.R
   ↓
7. create_HTML_FINAL_COMPLETO.R
```

### **Archivos de Entrada (Pipeline):**
- `final_processed_data.csv` (del Paso 1)

### **Archivos de Salida (Pipeline):**
- `final_processed_data_CLEAN.csv`
- `metadata.csv`
- `SEED_GT_miRNAs_CLEAN_RANKING.csv`
- `VOLCANO_PLOT_DATA_PER_SAMPLE.csv`
- `SNVs_REMOVED_VAF_05.csv`
- `miRNAs_AFFECTED_VAF_05.csv`
- `figures_diagnostico/` (4 PNGs)
- `figures_paso2_CLEAN/` (12 PNGs)
- `PASO_2_COMPLETO_FINAL.html`

---

## 🔧 PARÁMETROS CONFIGURABLES (Para Pipeline)

### **Nivel 1: Esenciales**
1. **Input file:** Path al archivo de datos procesados
2. **Metadata source:** Automático (por patrón) o archivo externo
3. **VAF threshold:** Umbral para filtro (default: 0.5)
4. **Seed region:** Posiciones (default: 2-8)

### **Nivel 2: Estadísticos**
1. **Statistical test:** wilcox, t-test, etc. (default: wilcox)
2. **FDR method:** BH, bonferroni, etc. (default: BH/fdr)
3. **FC threshold:** log2FC threshold (default: 0.58 = 1.5x)
4. **P-value threshold:** FDR threshold (default: 0.05)

### **Nivel 3: Visualización**
1. **Top N:** Número de top miRNAs para heatmaps (default: 50)
2. **Color scheme:** ALS color, Control color
3. **Figure resolution:** DPI (default: 300)
4. **Figure size:** Width, height en pulgadas

---

## 📋 CHECKLIST DE VALIDACIÓN (Pipeline)

**Antes de ejecutar:**
- [ ] Input file existe y tiene formato correcto
- [ ] Metadata disponible o generada
- [ ] Todas las librerías instaladas

**Durante ejecución:**
- [ ] QC: Valores filtrados detectados y reportados
- [ ] Metadata: N muestras correcto por grupo
- [ ] Ranking: N miRNAs seed G>T correcto
- [ ] Volcano: N tests = N miRNAs

**Después de ejecución:**
- [ ] Todos los archivos de output creados
- [ ] 12 figuras generadas en `figures_paso2_CLEAN/`
- [ ] HTML generado y abre correctamente
- [ ] Volcano Plot muestra método correcto

---

## 🎯 SALIDAS CRÍTICAS PARA VALIDAR

### **1. QC Report:**
```
Valores removidos: N (X%)
SNVs afectados: N
miRNAs afectados: N
Top miRNA afectado: [nombre] (N valores)
```

### **2. Volcano Plot:**
```
miRNAs testeados: 301
ALS enriched: N (FC > 1.5x, FDR < 0.05)
Control enriched: N (FC < 0.67x, FDR < 0.05)
No significativo: N
```

### **3. Top 3 ALS Candidates:**
```
1. [miRNA] (FC = X, p = Y)
2. [miRNA] (FC = X, p = Y)
3. [miRNA] (FC = X, p = Y)
```

---

## 💡 NOTAS IMPORTANTES PARA EL PIPELINE

### **1. Método del Volcano Plot:**
⚠️ **CRÍTICO:** Usar siempre método por muestra (Opción B)
- Cada punto = 1 miRNA
- Cálculo: VAF total por muestra → comparar medias de grupos
- NO mezclar SNVs y muestras en un solo promedio

### **2. Filtro de VAF:**
- Siempre aplicar filtro >= threshold antes de análisis
- Documentar impacto del filtro
- Generar figuras de diagnóstico

### **3. Metadata:**
- Debe ser configurable por el usuario
- Validar que todos los sample IDs tengan grupo asignado
- Verificar balance de grupos (N_ALS, N_Control)

### **4. Outputs:**
- Todas las figuras en un directorio
- HTML siempre generado al final
- CSV de resultados (volcano data, ranking, etc.)

---

**Documentado para automatización:** 2025-10-17 02:15
**Scripts totales:** 7
**Figuras totales:** 16 (4 QC + 12 análisis)
**Archivos output:** 10+

---

## 📊 **ACTUALIZACIÓN: FIGURA 2.5 (NUEVA) - DIFFERENTIAL HEATMAP**

**Fecha actualización:** 2025-10-24  
**Status:** ✅ **APPROVED**

### **NUEVA FIGURA AGREGADA AL PIPELINE:**

**File:** `FIG_2.5_DIFFERENTIAL_ALL301_PROFESSIONAL.png`

**Question answered:** "Which miRNAs and positions show G>T differential burden between ALS and Control?"

### **METHOD: Direct Subtraction**

```r
# For each (miRNA, position):
Differential = Mean_VAF_ALS - Mean_VAF_Control

Where:
  Mean_VAF_ALS = mean(VAF across 313 ALS samples)
  Mean_VAF_Control = mean(VAF across 102 Control samples)
```

### **COMPLETE DOCUMENTATION:**

**Mathematical explanation:** `FIGURE_2.5_DATA_FLOW_AND_MATH.md`

This document includes:
1. Complete data flow from raw data to final figure
2. Step-by-step mathematical formulas
3. Numerical examples with real data
4. Comparison with old Z-score method
5. Explanation of why most cells are light-colored
6. Interpretation guide

### **KEY PIPELINE DETAILS:**

**Input:**
- `final_processed_data_CLEAN.csv` (from Step 1)
- All 301 miRNAs with G>T in seed
- All 22 positions (not just seed)
- All 415 samples (313 ALS + 102 Control)

**Processing:**
1. Filter: G>T mutations in seed positions (2-8)
2. Identify: 301 unique miRNAs
3. Expand: Include all G>T positions (1-22) for these 301 miRNAs
4. Transform: Wide → Long format
5. Calculate: Mean VAF per (miRNA, position, group)
6. Subtract: ALS mean - Control mean
7. Create matrix: 301 miRNAs × 22 positions
8. Visualize: Blue-White-Red diverging heatmap

**Output:**
- Heatmap PNG (300 DPI, 12×16 inches)
- Color scale: Blue (Control > ALS) - White (Equal) - Red (ALS > Control)
- Seed region marked with dashed blue lines (positions 2-8)

### **R SCRIPT FOR PIPELINE:**

**File:** `generate_FIG_2.5_DIFFERENTIAL_ALL301.R`

```r
# Complete script available in:
# /figures_paso2_CLEAN/generate_FIG_2.5_DIFFERENTIAL_ALL301.R

# Key steps:
# 1. Load data
# 2. Filter G>T in seed → get 301 miRNAs
# 3. Expand to all positions for these miRNAs
# 4. Pivot to long format
# 5. Add metadata (ALS/Control)
# 6. Calculate mean VAF per (miRNA, pos, group)
# 7. Calculate differential (ALS - Control)
# 8. Rank miRNAs by burden
# 9. Create heatmap with ComplexHeatmap
# 10. Add seed region markers
```

### **INTERPRETATION:**

**Findings:**
- Predominantly light colors → Small differences (distributed effect)
- Few dark blue cells → Specific Control-elevated miRNAs
- Overall blue tint → Control > ALS globally
- Consistent with Figures 2.1, 2.2, 2.3

**Why different from old Fig 2.5 (Z-score)?**
- OLD: Normalized per row (amplifies small variations, many colors)
- NEW: Direct differences (preserves magnitude, accurate representation)
- NEW is biologically more meaningful

### **PIPELINE INTEGRATION:**

**Add to automated workflow:**
1. Run after `final_processed_data_CLEAN.csv` is generated
2. Requires `ComplexHeatmap` package
3. Execution time: ~2-3 minutes (301 miRNAs × 22 positions)
4. Memory: ~500 MB

**Dependencies:**
- tidyverse
- ComplexHeatmap
- circlize (for colorRamp2)

---

**Updated:** 2025-10-24  
**Scripts totales:** 8 (added FIG 2.5)
**Figuras totales:** 17 (4 QC + 13 análisis)
**New documentation:** FIGURE_2.5_DATA_FLOW_AND_MATH.md


---

## 📊 **FIGURA 2.6 (MEJORADA): POSITIONAL ANALYSIS**

**Fecha actualización:** 2025-10-27  
**Status:** ✅ **APPROVED**

### **Question:** "Does G>T burden vary by position, and does this differ between ALS and Control?"

### **CRITICAL FINDING:** 🔥

**Non-seed region has 10x MORE G>T burden than seed region!**

**Statistical Evidence:**
- **ALS:** Seed = 0.0128, Non-seed = 0.1253 (Ratio: 9.76x, p < 2e-16)
- **Control:** Seed = 0.0167, Non-seed = 0.1809 (Ratio: 10.85x, p = 3e-144)

**Interpretation:**
- Seed region mutations are functionally deleterious
- Strong purifying selection removes seed mutations
- Non-seed mutations are tolerated (neutral)
- Pattern is UNIVERSAL (both ALS and Control)

### **APPROVED FIGURES:**

**Primary (for publication):**
- `FIG_2.6C_SEED_VS_NONSEED_IMPROVED.png` - Direct seed vs non-seed comparison

**Supplementary:**
- `FIG_2.6A_LINE_CI_IMPROVED.png` - Line plot with 95% CI
- `FIG_2.6B_DIFFERENTIAL_IMPROVED.png` - Differential plot
- `FIG_2.6_COMBINED_IMPROVED.png` - Combined panels

### **METHOD:**

**Per-sample aggregation (correct approach):**
```r
# 1. For each sample: sum VAF at each position
vaf_per_sample <- vaf_long %>%
  group_by(Sample_ID, position, Group) %>%
  summarise(Total_VAF = sum(VAF))

# 2. Calculate statistics per position and group
positional_stats <- vaf_per_sample %>%
  group_by(position, Group) %>%
  summarise(
    Mean_VAF = mean(Total_VAF),
    SE_VAF = sd(Total_VAF) / sqrt(n()),
    CI_lower = Mean_VAF - 1.96*SE_VAF,
    CI_upper = Mean_VAF + 1.96*SE_VAF
  )

# 3. Statistical tests per position
for (pos in 1:22) {
  wilcox.test(ALS_vals, Control_vals)
  # FDR correction across all 22 tests
}
```

### **STATISTICAL RESULTS:**

**Position-by-position tests:**
- 22 positions tested
- 16/22 significant (FDR < 0.05)
- Control > ALS at most positions
- Mean difference: +0.037 VAF

**Seed vs Non-seed tests:**
- ALS: p < 2.2e-16 (highly significant)
- Control: p = 3.4e-144 (extremely significant)
- Both groups show 10x difference

### **FILES:**

**Figures:**
- `figures_paso2_CLEAN/FIG_2.6A_LINE_CI_IMPROVED.png`
- `figures_paso2_CLEAN/FIG_2.6B_DIFFERENTIAL_IMPROVED.png`
- `figures_paso2_CLEAN/FIG_2.6C_SEED_VS_NONSEED_IMPROVED.png`
- `figures_paso2_CLEAN/FIG_2.6_COMBINED_IMPROVED.png`

**Statistical Tables:**
- `figures_paso2_CLEAN/TABLE_2.6_position_tests.csv`
- `figures_paso2_CLEAN/TABLE_2.6_region_stats.csv`
- `figures_paso2_CLEAN/TABLE_2.6_seed_vs_nonseed_tests.csv`

**Documentation:**
- `CRITICAL_ANALYSIS_FIG_2.6.md` (expert review)
- `FIG_2.6_IMPROVEMENTS_SUMMARY.md` (improvements)
- `FIG_2.6_CRITICAL_FINDINGS.md` (main findings)
- `FIG_2.6_RESULTS_VIEWER.html` (interactive viewer)

### **R SCRIPT:**

**File:** `generate_FIG_2.6_CORRECTED.R`

**Key features:**
- Correct metadata pattern: `.ALS.` and `.control.`
- Per-sample aggregation method
- Statistical rigor (CI, FDR, effect sizes)
- Multiple visualization options
- Results export to CSV

### **CONSISTENCY WITH OTHER FIGURES:**

✅ **Figure 2.1-2.2:** Control > ALS globally → Confirmed in both regions  
✅ **Figure 2.3:** Few significantly different miRNAs → Effect distributed  
✅ **Figure 2.5:** Small differences, distributed → Position-level confirmation  

### **BIOLOGICAL IMPLICATIONS:**

**Major conclusion:**
- Seed region is NOT an oxidative hotspot
- Functional constraint drives observed pattern
- Selection removes seed mutations efficiently
- Non-seed mutations accumulate (neutral)

**This changes the narrative:** Original hypothesis rejected, new model supported

---

**Updated:** 2025-10-27  
**Scripts totales:** 9 (added FIG 2.6)
**Figuras totales:** 21 (4 QC + 17 analysis)
**New major finding:** 10x seed depletion

