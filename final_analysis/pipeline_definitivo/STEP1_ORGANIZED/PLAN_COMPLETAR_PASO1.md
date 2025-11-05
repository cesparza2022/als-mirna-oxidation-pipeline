# 📋 PLAN: Completar Paso 1 - Scripts Faltantes

**Fecha:** 2025-01-29  
**Objetivo:** Crear scripts R para todos los 8 paneles de Paso 1

---

## 📊 **ESTADO ACTUAL**

### **Scripts Existentes:**
- ✅ `05_gcontent_FINAL_VERSION.R` (Panel E) - FUNCIONAL

### **Scripts Faltantes:**
- ❌ `01_dataset_overview.R` (Panel A)
- ❌ `02_gt_count_by_position.R` (Panel B)
- ❌ `03_gx_spectrum.R` (Panel C)
- ❌ `04_positional_fraction.R` (Panel D)
- ❌ `06_seed_vs_nonseed.R` (Panel F)
- ❌ `07_gt_specificity.R` (Panel G)
- ❌ `08_sequence_context_adjacent.R` (Panel H)

**Total:** 7 scripts por crear

---

## 🎯 **ESTRATEGIA**

### **Patrón a seguir:**

Todos los scripts seguirán el mismo formato que `05_gcontent_FINAL_VERSION.R`:

```r
#!/usr/bin/env Rscript
# ============================================================================
# PANEL X: [Description]
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(readr)
  library(stringr)
})

# Load data
data <- read_csv("../../pipeline_2/final_processed_data_CLEAN.csv", ...)

# Process data
# ...

# Generate figure
ggsave("figures/step1_panelX_*.png", ...)

# Export tables (if applicable)
write_csv(table, "data/TABLE_1.X_*.csv")
```

---

## 📝 **ESPECIFICACIONES POR PANEL**

### **Panel A: Dataset Overview**

**Propósito:** Mostrar evolución del dataset (raw → split → collapse)

**Necesita:**
- Datos antes de split (raw)
- Datos después de split
- Datos después de collapse (ya tenemos)

**Figura actual:** `step1_panelA_dataset_overview.png`

**Script:** `01_dataset_overview.R`

**Tabla a exportar:** `TABLE_1.A_dataset_evolution.csv`

---

### **Panel B: G>T Count by Position**

**Propósito:** Conteo absoluto de mutaciones G>T por posición

**Input:** `final_processed_data_CLEAN.csv`

**Procesamiento:**
- Filtrar solo G>T: `str_detect(pos.mut, ":GT$")`
- Extraer posición: `as.numeric(str_extract(pos.mut, "^\\d+"))`
- Sumar counts por posición

**Figura actual:** `step1_panelB_gt_count_by_position.png`

**Script:** `02_gt_count_by_position.R`

**Tabla a exportar:** `TABLE_1.B_gt_counts_by_position.csv`

---

### **Panel C: G>X Mutation Spectrum**

**Propósito:** Espectro completo de mutaciones G (G>T, G>C, G>A) por posición

**Input:** `final_processed_data_CLEAN.csv`

**Procesamiento:**
- Filtrar mutaciones G: `str_detect(pos.mut, "^\\d+:G[TCAG]")`
- Categorizar: G>T, G>C, G>A
- Extraer posición
- Agrupar y sumar

**Figura actual:** `step1_panelC_gx_spectrum.png`

**Script:** `03_gx_spectrum.R`

**Tabla a exportar:** `TABLE_1.C_gx_spectrum_by_position.csv`

---

### **Panel D: Positional Fraction**

**Propósito:** Proporción de mutaciones en cada posición (relativo al total)

**Input:** `final_processed_data_CLEAN.csv`

**Procesamiento:**
- Contar todas las mutaciones por posición
- Calcular fracción = count_position / total_mutations

**Figura actual:** `step1_panelD_positional_fraction.png`

**Script:** `04_positional_fraction.R`

**Tabla a exportar:** `TABLE_1.D_positional_fractions.csv`

---

### **Panel E: G-Content Landscape** ✅

**Ya existe:** `05_gcontent_FINAL_VERSION.R`

---

### **Panel F: Seed vs Non-seed**

**Propósito:** Comparar mutaciones en seed (2-8) vs non-seed

**Input:** `final_processed_data_CLEAN.csv`

**Procesamiento:**
- Clasificar posiciones: seed (2-8) vs non-seed
- Comparar counts, fracciones, etc.

**Figura actual:** `step1_panelF_seed_interaction.png`

**Script:** `06_seed_vs_nonseed.R`

**Tabla a exportar:** `TABLE_1.F_seed_vs_nonseed.csv`

---

### **Panel G: G>T Specificity**

**Propósito:** Proporción de G>T vs otras transversiones G (G>C, G>A)

**Input:** `final_processed_data_CLEAN.csv`

**Procesamiento:**
- Filtrar mutaciones G: G>T, G>C, G>A
- Calcular proporciones

**Figura actual:** `step1_panelG_gt_specificity.png`

**Script:** `07_gt_specificity.R`

**Tabla a exportar:** `TABLE_1.G_gt_specificity.csv`

---

### **Panel H: Sequence Context**

**Propósito:** Nucleótidos adyacentes a sitios G>T

**Input:** `final_processed_data_CLEAN.csv` + secuencias de referencia miRNA

**Nota:** Requiere referencia de secuencias miRNA (miRBase)

**Figura actual:** `step1_panelH_sequence_context.png`

**Script:** `08_sequence_context_adjacent.R`

**Tabla a exportar:** `TABLE_1.H_sequence_context.csv`

---

## ✅ **IMPLEMENTACIÓN**

**Orden sugerido:**
1. Panel B (más simple - solo G>T)
2. Panel C (similar a B pero más tipos)
3. Panel D (cálculos simples)
4. Panel F (clasificación seed/non-seed)
5. Panel G (proporciones)
6. Panel A (más complejo - necesita datos intermedios)
7. Panel H (más complejo - necesita secuencias de referencia)

**¿Procedemos a crear los scripts uno por uno?** 🚀

