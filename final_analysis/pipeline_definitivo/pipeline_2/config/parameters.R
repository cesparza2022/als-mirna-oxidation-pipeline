# 📊 PARÁMETROS DEL PIPELINE_2

## 🎯 PREGUNTAS CIENTÍFICAS PRINCIPALES

### **1. CARACTERIZACIÓN DEL DATASET**
questions_dataset <- list(
  structure = "¿Cuál es la estructura y calidad del dataset?",
  positional = "¿Dónde ocurren las mutaciones G>T en los miRNAs?",
  mutation_types = "¿Qué tipos de mutación G→X son más prevalentes?",
  top_mirnas = "¿Cuáles son los miRNAs más susceptibles al estrés oxidativo?"
)

### **2. ANÁLISIS G>T EXCLUSIVO ALS vs CONTROL**
questions_gt_analysis <- list(
  group_differences = "¿Hay diferencias en mutaciones G>T entre grupos?",
  significant_mirnas = "¿Qué miRNAs muestran diferencias significativas?",
  positional_differences = "¿Dónde están localizadas las diferencias?",
  effect_magnitude = "¿Cuál es la magnitud del efecto?"
)

### **3. ANÁLISIS FUNCIONAL**
questions_functional <- list(
  functional_regions = "¿Las mutaciones G>T afectan regiones funcionales?",
  sequence_patterns = "¿Hay patrones de secuencia específicos?",
  pathways = "¿Qué pathways están afectados?",
  validation = "¿Cómo validamos los hallazgos?"
)

## 📊 LAYOUT DE FIGURAS

### **FIGURA 1: CARACTERIZACIÓN DEL DATASET**
figure_1_layout <- list(
  panel_a = "Evolución del dataset",
  panel_b = "Heatmap posicional de SNVs G>T",
  panel_c = "Tipos de mutación G→X por posición",
  panel_d = "Top miRNAs con más mutaciones G>T"
)

### **FIGURA 2: ANÁLISIS G>T EXCLUSIVO**
figure_2_layout <- list(
  panel_a = "Heatmap de VAFs G>T por miRNA y muestra",
  panel_b = "Distribución de VAFs G>T por grupo",
  panel_c = "Significancia estadística (volcano plot)",
  panel_d = "miRNAs más diferenciales"
)

### **FIGURA 3: ANÁLISIS FUNCIONAL**
figure_3_layout <- list(
  panel_a = "Mutaciones G>T en región seed vs no-seed",
  panel_b = "Patrones de secuencia",
  panel_c = "Análisis de pathways",
  panel_d = "Validación funcional"
)

## ⚙️ PARÁMETROS TÉCNICOS

### **Visualizaciones**
viz_params <- list(
  figure_width = 12,
  figure_height = 8,
  dpi = 300,
  theme = "minimal",
  color_palette = "viridis"
)

### **Estadísticas**
stats_params <- list(
  alpha = 0.05,
  fdr_method = "BH",
  test_type = "wilcoxon",
  min_samples = 5
)

### **Filtros**
filter_params <- list(
  vaf_threshold = 0.5,
  min_coverage = 10,
  min_mutations = 3
)

