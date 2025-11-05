# 🤖 PLAN PIPELINE AUTOMATIZADO - PIPELINE_2

## 🎯 **OBJETIVO FINAL**

Crear un pipeline **100% automatizado** que cualquier usuario pueda ejecutar:

```bash
Rscript run_pipeline.R --input data.txt --output results/
```

Y que genere:
- ✅ Todas las figuras profesionales
- ✅ Reportes HTML interactivos
- ✅ Análisis estadísticos completos
- ✅ Documentación de resultados

---

## 📊 **ARQUITECTURA DEL PIPELINE AUTOMATIZADO**

```
run_pipeline.R (MASTER SCRIPT)
│
├── STEP 0: Configuration & Validation
│   ├── config/config_pipeline_2.R
│   ├── Validate input data
│   └── Detect/load sample groups
│
├── STEP 1: Data Processing
│   ├── Load raw data
│   ├── Split & filter PM
│   ├── Extract mutation info
│   └── Generate processed_data_final
│
├── STEP 2: TIER 1 - Standalone Analysis (NO metadata)
│   ├── FIGURE 1: Dataset Characterization ✅
│   │   └── source("functions/visualization_functions_v5.R")
│   │       └── create_figure_1_v5()
│   │
│   └── FIGURE 2: Mechanistic Validation ✅
│       └── source("functions/mechanistic_functions.R")
│           └── create_figure_2_mechanistic()
│
├── STEP 3: TIER 2 - Group Comparison (WITH metadata)
│   └── FIGURE 3: Group Comparison 🔧 (Framework listo)
│       └── source("functions/comparison_visualizations.R")
│           ├── IF groups detected/provided:
│           │   └── create_figure_3_comparison()
│           └── ELSE:
│               └── Skip with message
│
├── STEP 4: TIER 2 - Confounders (OPTIONAL)
│   └── FIGURE 4: Confounder Analysis 📋
│       └── IF demographics provided:
│           └── create_figure_4_confounders()
│
├── STEP 5: Advanced Analysis (OPTIONAL)
│   └── FIGURE 5: Functional Analysis 💡
│
└── STEP 6: Generate Reports
    ├── Create HTML viewers for all figures
    ├── Generate summary statistics
    └── Create executive report
```

---

## 🗂️ **ESTADO ACTUAL - QUÉ ESTÁ LISTO**

### ✅ **TIER 1: 100% AUTOMATIZADO**

**Código:**
```r
# Ya funciona sin intervención:
source("functions/visualization_functions_v5.R")
figure_1 <- create_figure_1_v5(data_list, figures_dir)
# ✅ Genera automáticamente los 4 paneles

source("functions/mechanistic_functions.R")
figure_2 <- create_figure_2_mechanistic(data_list, figures_dir)
# ✅ Genera automáticamente los 4 paneles
```

**Output automático:**
- `figure_1_v5_updated_colors.png` ✅
- `figure_2_mechanistic_validation.png` ✅
- Todos los paneles individuales ✅
- HTML viewers ✅

---

### 🔧 **TIER 2: 40% LISTO (Framework)**

**Lo que YA está automatizado:**
```r
# Extracción automática de grupos:
groups <- extract_groups_from_colnames(raw_data)
# ✅ Detecta automáticamente ALS vs Control de nombres

# Framework de tests:
position_stats <- compare_positions_by_group(processed_data, groups)
# ✅ Calcula estadísticas por posición

# Visualización:
panel_b <- create_position_delta_plot(position_stats)
# ✅ Genera gráfica con colores correctos
```

**Lo que FALTA para automatizar al 100%:**
```r
# TODO: Implementar análisis real per-sample
# - Convertir wide → long con grupos
# - Calcular burden per-sample real (no simulado)
# - Tests estadísticos con datos reales (no dummy)
# - Generar los 4 paneles completos
```

---

## 🚀 **PRÓXIMO PASO INMEDIATO - ANÁLISIS REAL**

### **OBJETIVO: Hacer Figura 3 100% funcional con datos reales**

**PASO 1: Implementar per-sample analysis** (1.5 horas)

Crear: `functions/data_transformation.R`

```r
#' Convert Wide Format to Long with Groups
#' 
#' Transforma el formato original (muestras en columnas) a formato long
#' con asignación de grupos
#' 
#' @param raw_data Datos originales (wide format)
#' @param groups Data frame con sample_id y group
#' @return Datos en formato long con grupos asignados
transform_wide_to_long_with_groups <- function(raw_data, groups) {
  
  # 1. Separar columnas de muestras vs metadata
  sample_cols <- setdiff(names(raw_data), c("miRNA name", "pos:mut"))
  
  # 2. Pivot to long
  data_long <- raw_data %>%
    pivot_longer(
      cols = all_of(sample_cols),
      names_to = "sample_id",
      values_to = "vaf"
    ) %>%
    # 3. Join with groups
    left_join(groups, by = "sample_id") %>%
    # 4. Separate rows for multiple mutations
    separate_rows(`pos:mut`, sep = ",") %>%
    filter(`pos:mut` != "PM") %>%
    # 5. Extract position and mutation type
    separate(`pos:mut`, into = c("position", "mutation_type"), 
             sep = ":", remove = FALSE) %>%
    mutate(
      position = as.numeric(position),
      mutation_type = case_when(
        mutation_type == "GT" ~ "G>T",
        mutation_type == "GA" ~ "G>A",
        mutation_type == "GC" ~ "G>C",
        mutation_type == "TC" ~ "T>C",
        mutation_type == "AG" ~ "A>G",
        mutation_type == "CT" ~ "C>T",
        TRUE ~ mutation_type
      )
    ) %>%
    filter(position >= 1 & position <= 22)
  
  return(data_long)
}
```

**Output esperado:**
```
# A tibble: ~millions × 7
  `miRNA name`   sample_id                  group   vaf position mutation_type
  <chr>          <chr>                      <chr> <dbl>    <dbl> <chr>        
1 hsa-let-7a-5p  Magen-ALS-SRR13934430      ALS    0.15        3 G>T          
2 hsa-let-7a-5p  Magen-control-SRR14631747  Control 0.08       3 G>T          
3 ...
```

---

**PASO 2: Re-implementar comparaciones con datos reales** (1 hora)

Actualizar: `functions/comparison_functions.R`

```r
# Versión REAL de compare_global_gt_burden:
compare_global_gt_burden_REAL <- function(data_long) {
  
  # Calculate per-sample G>T burden
  per_sample_burden <- data_long %>%
    filter(mutation_type == "G>T") %>%
    group_by(sample_id, group) %>%
    summarise(
      gt_count = n(),
      total_mutations = ...,
      gt_fraction = gt_count / total_mutations,
      .groups = "drop"
    )
  
  # Wilcoxon test between groups
  test_result <- wilcoxon_test_generic(
    values = per_sample_burden$gt_fraction,
    groups = per_sample_burden$group
  )
  
  return(list(
    per_sample_burden = per_sample_burden,
    test_result = test_result
  ))
}

# Versión REAL de compare_positions_by_group:
compare_positions_by_group_REAL <- function(data_long) {
  
  # Calculate G>T frequency per position per group
  position_by_group <- data_long %>%
    filter(mutation_type == "G>T") %>%
    group_by(position, group) %>%
    summarise(gt_count = n(), .groups = "drop") %>%
    # Add total mutations per position per group for denominator
    ...
  
  # Wilcoxon test per position (22 tests)
  position_tests <- map_dfr(1:22, function(pos) {
    # Extract data for this position
    # Test ALS vs Control
    # Return p-value
  })
  
  # FDR correction
  position_tests$qvalue <- p.adjust(position_tests$pvalue, method = "BH")
  position_tests$stars <- get_significance_stars(position_tests$qvalue)
  
  return(position_tests)
}
```

---

**PASO 3: Generar Figura 3 completa** (30 min)

```r
# El wrapper ya existe, solo necesita datos reales:
figure_3 <- create_figure_3_comparison(
  data_long = data_long,  # Datos transformados
  output_dir = figures_dir
)
# ✅ Genera automáticamente los 4 paneles con datos reales
```

---

**PASO 4: Integrar en master script** (30 min)

Crear: `run_pipeline.R` (MASTER)

```r
#!/usr/bin/env Rscript

# 🤖 PIPELINE_2 - MASTER SCRIPT
# Automated miRNA G>T analysis pipeline

# Load configuration
source("config/config_pipeline_2.R")

# Load all functions
source("functions/visualization_functions_v5.R")
source("functions/mechanistic_functions.R")
source("functions/data_transformation.R")      # NUEVO
source("functions/comparison_visualizations.R")
source("functions/statistical_tests.R")
source("functions/comparison_functions.R")

cat("🚀 PIPELINE_2 - AUTOMATED ANALYSIS\n\n")

# STEP 1: Load data
cat("📥 STEP 1: Loading data...\n")
raw_data <- read_tsv(data_path)
cat("   ✅ Loaded:", nrow(raw_data), "rows\n\n")

# STEP 2: Process data
cat("🔧 STEP 2: Processing data...\n")
processed_data <- raw_data %>% separate_rows(...) %>% filter(...)
data_list <- create_data_list(raw_data, processed_data)
cat("   ✅ Processed:", nrow(processed_data), "SNVs\n\n")

# STEP 3: TIER 1 - Standalone
cat("📊 STEP 3: TIER 1 Analysis (No metadata required)...\n")
figure_1 <- create_figure_1_v5(data_list, figures_dir)
figure_2 <- create_figure_2_mechanistic(data_list, figures_dir)
cat("   ✅ Figures 1-2 generated\n\n")

# STEP 4: TIER 2 - Group Comparison
cat("📊 STEP 4: TIER 2 Analysis (Group comparison)...\n")

# Try to extract groups
groups <- tryCatch({
  extract_groups_from_colnames(raw_data)
}, error = function(e) NULL)

if (!is.null(groups) && nrow(groups) > 0) {
  cat("   ✅ Groups detected automatically\n")
  
  # Transform data
  data_long <- transform_wide_to_long_with_groups(raw_data, groups)
  
  # Generate Figure 3
  figure_3 <- create_figure_3_comparison(data_long, figures_dir)
  cat("   ✅ Figure 3 generated\n")
} else {
  cat("   ⚠️  No groups detected - Skipping Figure 3\n")
  cat("   💡 Provide sample_groups.csv to enable comparison\n")
}

cat("\n✅ PIPELINE COMPLETED\n")
cat("📁 Results saved in:", figures_dir, "\n")
```

---

## 📋 **PLAN DE IMPLEMENTACIÓN - SIGUIENTE PASO**

### **OPCIÓN A: Completar Figura 3 con datos REALES** ⭐ RECOMENDADO

**Tiempo:** 3-4 horas  
**Prioridad:** ALTA (es el siguiente paso lógico)

**Subtareas:**
1. ✅ Crear `functions/data_transformation.R` (1 hora)
   - `transform_wide_to_long_with_groups()`
   - Validación de formato
   
2. ✅ Re-implementar funciones de comparación REALES (1 hora)
   - `compare_global_gt_burden_REAL()`
   - `compare_positions_by_group_REAL()`
   - Tests estadísticos con datos reales
   
3. ✅ Generar Figura 3 completa (30 min)
   - 4 paneles con datos reales
   - Tests + FDR + estrellas
   
4. ✅ Crear master script `run_pipeline.R` (1 hora)
   - Automatizar flujo completo
   - Detección automática de grupos
   - Manejo de errores

**Resultado:** Pipeline que genera Figuras 1-3 automáticamente

---

### **OPCIÓN B: Avanzar a Figura 4/5** (Menos recomendado)

**Problema:** Sin completar Figura 3 real, el pipeline queda incompleto

**Recomendación:** Completar Figura 3 primero

---

## 🗂️ **REGISTRO PARA PIPELINE AUTOMATIZADO**

### **LO QUE YA ESTÁ REGISTRADO Y LISTO:**

#### **1. Funciones Tier 1** ✅ 100% LISTAS
```
functions/
├── visualization_functions_v5.R     ✅ Figura 1 completa
└── mechanistic_functions.R          ✅ Figura 2 completa

Uso:
  create_figure_1_v5(data_list, output_dir)  # Automático
  create_figure_2_mechanistic(data_list, output_dir)  # Automático
```

#### **2. Funciones Tier 2** 🔧 40% LISTAS (Framework)
```
functions/
├── statistical_tests.R              ✅ Tests genéricos (listo)
├── comparison_functions.R           🔧 Framework (necesita REAL)
└── comparison_visualizations.R      ✅ Visualizaciones (listas)

Estado:
  - Framework genérico: ✅ Listo
  - Datos simulados: ✅ Funciona
  - Datos reales: 🔧 Falta implementar transformación
```

#### **3. Scripts de Prueba** ✅
```
test_figure_1_v5.R                   ✅ Tier 1 completo
test_figure_2.R                      ✅ Tier 1 completo
test_figure_3_simplified.R           ✅ Tier 2 demo Panel B
```

#### **4. Templates para Usuarios** ✅
```
templates/
├── sample_groups_template.csv       ✅ Cómo dar grupos
├── demographics_template.csv        ✅ Cómo dar metadata
└── README_TEMPLATES.md              ✅ Guía de uso
```

---

## 🎯 **SIGUIENTE PASO ESPECÍFICO - IMPLEMENTACIÓN REAL**

### **Tarea 1: Data Transformation** (Prioridad CRÍTICA)

**Crear:** `functions/data_transformation.R`

**Función principal:**
```r
transform_wide_to_long_with_groups(raw_data, groups) {
  # Input:  Wide format (muestras en columnas)
  # Output: Long format (sample_id | group | miRNA | position | mutation | vaf)
  
  # Pasos:
  # 1. Pivot longer (columnas → filas)
  # 2. Join con grupos
  # 3. Separate rows (split comas)
  # 4. Extract position/mutation
  # 5. Filter valid positions
  
  return(data_long)
}
```

**Tiempo estimado:** 1 hora  
**Complejidad:** Media  
**Bloquea:** Todo Tier 2 con datos reales

---

### **Tarea 2: Real Comparison Functions** (Prioridad ALTA)

**Actualizar:** `functions/comparison_functions.R`

**Agregar versiones REAL:**
```r
compare_global_gt_burden_REAL()      # Per-sample burden
compare_positions_by_group_REAL()    # Tests por posición
compare_seed_by_group_REAL()         # Seed interaction
identify_differential_mirnas_REAL()  # Volcano plot
```

**Tiempo estimado:** 1.5 horas  
**Complejidad:** Media-Alta  
**Requiere:** Tarea 1 completa

---

### **Tarea 3: Master Pipeline Script** (Prioridad ALTA)

**Crear:** `run_pipeline.R`

**Funcionalidad:**
```r
# Argumentos de línea de comandos
args <- commandArgs(trailingOnly = TRUE)

# Opciones:
# --input <file>        Datos de entrada
# --output <dir>        Directorio de salida
# --groups <file>       Archivo de grupos (opcional, se auto-detecta)
# --skip-tier2          Saltar análisis de grupos
# --demographics <file> Metadata adicional (opcional)

# Flow:
# 1. Validar inputs
# 2. Cargar y procesar datos
# 3. Generar Tier 1 (siempre)
# 4. Detectar/cargar grupos
# 5. Generar Tier 2 (si aplica)
# 6. Generar reportes HTML
# 7. Summary de resultados
```

**Tiempo estimado:** 1 hora  
**Complejidad:** Baja (integración)  
**Requiere:** Tareas 1-2 completas

---

## 📊 **ROADMAP DETALLADO - PRÓXIMAS 4 HORAS**

### **Hora 1: Data Transformation**
- [ ] Crear `data_transformation.R`
- [ ] Implementar `transform_wide_to_long_with_groups()`
- [ ] Testear con datos reales
- [ ] Validar output (verificar que grupos se asignan correctamente)

### **Hora 2-3: Real Analysis Functions**
- [ ] Implementar `compare_global_gt_burden_REAL()`
- [ ] Implementar `compare_positions_by_group_REAL()`
  - [ ] Per-position Wilcoxon tests
  - [ ] FDR correction
  - [ ] Effect sizes
- [ ] Implementar `compare_seed_by_group_REAL()`
- [ ] Implementar `identify_differential_mirnas_REAL()`

### **Hora 4: Integration & Testing**
- [ ] Crear `run_pipeline.R` master script
- [ ] Testear flujo completo
- [ ] Generar Figura 3 completa (4 paneles)
- [ ] Crear HTML viewer
- [ ] Actualizar documentación

---

## ✅ **LO QUE SE GUARDARÁ PARA EL PIPELINE**

### **Scripts Automatizados:**
```
run_pipeline.R                       🔧 Master script (próximo)
config/config_pipeline_2.R           ✅ Ya existe

functions/
├── visualization_functions_v5.R     ✅ Figura 1 (automatizado)
├── mechanistic_functions.R          ✅ Figura 2 (automatizado)
├── data_transformation.R            🔧 Próximo paso
├── statistical_tests.R              ✅ Tests (listo)
├── comparison_functions.R           🔧 Necesita versiones REAL
└── comparison_visualizations.R      ✅ Visualizaciones (listas)
```

### **Documentación del Pipeline:**
```
README.md                            ✅ Cómo usar pipeline
USAGE_GUIDE.md                       🔧 Próximo (tutorial completo)
CHANGELOG.md                         ✅ Versionado completo
```

### **Templates:**
```
templates/
├── sample_groups_template.csv       ✅ Ya existe
├── demographics_template.csv        ✅ Ya existe
└── README_TEMPLATES.md              ✅ Guía de uso
```

---

## 🎯 **DECISIÓN INMEDIATA**

### **Voy a proceder con:**

**PASO 1:** Crear `data_transformation.R` (función crítica)
- Convertir wide → long
- Asignar grupos automáticamente
- Output listo para análisis

**PASO 2:** Implementar versiones REAL de comparaciones
- Global burden con datos reales
- Position tests con datos reales
- Seed interaction real
- Volcano plot real

**PASO 3:** Generar Figura 3 completa (4 paneles)

**PASO 4:** Crear master script `run_pipeline.R`

**Resultado final:**
```bash
# Usuario ejecuta:
Rscript run_pipeline.R --input data.txt

# Pipeline genera automáticamente:
# ✅ Figura 1 (characterization)
# ✅ Figura 2 (mechanistic)
# ✅ Figura 3 (comparison) - CON DATOS REALES
# ✅ HTML viewers
# ✅ Reportes estadísticos
```

---

## 📝 **REGISTRO DE TODO LO IMPLEMENTADO**

### **Documentos de Registro:**
1. ✅ `CHANGELOG.md` - Todas las versiones y cambios
2. ✅ `ROADMAP_COMPLETO.md` - Pasos del pipeline
3. ✅ `RESUMEN_SESION_FIGURA_3.md` - Logros de sesión
4. ✅ `PLAN_PIPELINE_AUTOMATIZADO.md` - Este documento
5. ✅ `FIGURA_3_IMPLEMENTATION_PLAN.md` - Plan técnico Figura 3

### **Código Versionado:**
- Todas las funciones en `functions/`
- Todos los scripts de prueba
- Todos los templates
- Todo comentado y documentado

---

## 🚀 **¿PROCEDEMOS?**

**Plan inmediato (próximas 3-4 horas):**

1. Crear `data_transformation.R`
2. Implementar análisis REAL
3. Generar Figura 3 completa con datos reales
4. Crear master script automatizado
5. Testear pipeline end-to-end

**Resultado:**
- Pipeline 80% automatizado
- Figuras 1-3 generadas automáticamente
- Listo para cualquier dataset similar

**¿Empezamos con la transformación de datos? 🚀**

