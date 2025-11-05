# 🎯 FIGURA 3: GROUP COMPARISON - IMPLEMENTATION PLAN

## 🔬 **OBJETIVO**

Crear framework **genérico** para comparación de grupos (ALS vs Control) con:
- Tests estadísticos por posición
- FDR correction
- Visualización con estrellas de significancia
- Colores: 🔴 Rojo=ALS, 🔵 Azul=Control

---

## 📊 **FIGURA 3: 4 PANELES**

### **Panel A: Global G>T Burden Comparison** ⭐⭐⭐⭐⭐
**Pregunta:** ¿El burden global de G>T es diferente entre grupos?

**Análisis:**
- Per-sample G>T count/fraction
- Wilcoxon rank-sum test
- Effect size (Cohen's d)

**Visualización:**
- Violin plot o boxplot
- 🔴 ALS vs 🔵 Control
- P-value y effect size anotados

**Input requerido:**
```csv
sample_id,group
sample_1,ALS
sample_2,Control
...
```

---

### **Panel B: Position-Specific Differences** ⭐⭐⭐⭐⭐ TU FAVORITA
**Pregunta:** ¿Qué posiciones muestran diferencias significativas entre grupos?

**Análisis:**
- Per-position Wilcoxon test (1-22 positions)
- FDR correction (Benjamini-Hochberg)
- Effect sizes per position

**Visualización:**
- Barras lado a lado por posición
- 🔴 ALS vs 🔵 Control
- 🟡 Seed region sombreada (2-8)
- ⭐ Estrellas donde q < 0.05
  - * q < 0.05
  - ** q < 0.01
  - *** q < 0.001

**Inspiración:** Tu PDF `distribucion_por_posicion_filtrado.pdf`

---

### **Panel C: Seed vs Non-Seed Enrichment by Group** ⭐⭐⭐⭐
**Pregunta:** ¿La región seed es MÁS afectada en un grupo específico?

**Análisis:**
- 2×2 contingency table (Seed/Non-seed × ALS/Control)
- Fisher's exact test
- Odds Ratio con CI
- Test de interacción

**Visualización:**
- Barras agrupadas (Seed vs Non-seed) por grupo
- Interaction plot
- 🔴 ALS, 🔵 Control, 🟡 Seed highlighted

---

### **Panel D: Differential miRNAs (Volcano Plot)** ⭐⭐⭐⭐
**Pregunta:** ¿Qué miRNAs específicos son diferenciales?

**Análisis:**
- Per-miRNA Fisher's exact test
- FDR correction
- Log2 fold-change calculation

**Visualización:**
- Volcano plot (log2FC vs -log10(q-value))
- Top 10 miRNAs labeled
- Threshold lines (q < 0.05, |FC| > 1.5)
- Colores por significancia

---

## 💻 **IMPLEMENTACIÓN TÉCNICA**

### **Función 1: Load and Validate Groups**
```r
load_sample_groups <- function(groups_file, data) {
  # Read user file
  groups <- read.csv(groups_file)
  
  # Validate format
  required_cols <- c("sample_id", "group")
  if (!all(required_cols %in% names(groups))) {
    stop("File must have columns: sample_id, group")
  }
  
  # Validate groups (must be 2)
  unique_groups <- unique(groups$group)
  if (length(unique_groups) != 2) {
    stop("Currently supports 2-group comparison only. Found: ", 
         paste(unique_groups, collapse = ", "))
  }
  
  # Match with data (extract sample IDs from column names)
  # This needs to be adapted based on data structure
  
  return(groups)
}
```

---

### **Función 2: Global G>T Burden**
```r
compare_global_gt_burden <- function(data, groups) {
  # Calculate per-sample G>T count
  # Group by user-provided groups
  # Wilcoxon test
  # Cohen's d
  
  return(list(
    summary_stats = ...,
    test_results = ...,
    plot_data = ...
  ))
}
```

---

### **Función 3: Position-Specific Tests** ⭐ CRÍTICA
```r
compare_positions_by_group <- function(data, groups) {
  # For each position 1-22:
  #   - Calculate G>T frequency in Group A
  #   - Calculate G>T frequency in Group B
  #   - Wilcoxon rank-sum test
  #   - Store p-value
  
  # FDR correction across all positions
  # Calculate effect sizes
  
  return(list(
    position_stats = data.frame(
      position = 1:22,
      freq_groupA = ...,
      freq_groupB = ...,
      pvalue = ...,
      qvalue = ...,  # FDR-adjusted
      effect_size = ...,
      significant = qvalue < 0.05
    )
  ))
}
```

---

### **Función 4: Create Position Delta Plot** ⭐ TU FAVORITA
```r
create_position_delta_plot <- function(position_stats, groups) {
  # Barras lado a lado
  # Colores: ALS=red, Control=blue
  # Seed region sombreada
  # Estrellas donde significant==TRUE
  
  p <- ggplot(position_stats_long, aes(x = position, y = frequency, fill = group)) +
    # Seed region shading
    annotate("rect", xmin = 1.5, xmax = 8.5, ymin = 0, ymax = Inf,
             fill = "#FFD700", alpha = 0.1) +
    
    # Bars
    geom_col(position = "dodge", color = "black", linewidth = 0.3) +
    
    # Colors
    scale_fill_manual(
      values = c("ALS" = "#E31A1C", "Control" = "#1F78B4"),
      name = "Group"
    ) +
    
    # Significance stars
    geom_text(
      data = position_stats %>% filter(significant),
      aes(label = case_when(
        qvalue < 0.001 ~ "***",
        qvalue < 0.01 ~ "**",
        qvalue < 0.05 ~ "*"
      )),
      position = position_dodge(width = 0.9),
      vjust = -0.5, size = 5
    ) +
    
    labs(
      title = "Position-Specific G>T Differences (ALS vs Control)",
      subtitle = "Seed region (2-8) shaded | * q<0.05, ** q<0.01, *** q<0.001",
      x = "Position in miRNA",
      y = "G>T Frequency (%)"
    ) +
    theme_minimal()
  
  return(p)
}
```

---

### **Función 5: Seed vs Non-Seed Interaction**
```r
compare_seed_by_group <- function(data, groups) {
  # Create 2×2 table
  # Fisher's exact test
  # OR with CI
  # Interaction test
  
  return(results)
}
```

---

### **Función 6: Differential miRNAs (Volcano)**
```r
identify_differential_mirnas <- function(data, groups) {
  # For each miRNA:
  #   - G>T count in ALS vs Control
  #   - Fisher's exact test
  #   - Log2 fold-change
  
  # FDR correction
  # Label top miRNAs
  
  return(volcano_data)
}
```

---

## 🧪 **TESTING STRATEGY**

### **Opción A: Datos Dummy (Recomendado para testing)**
```r
# Crear datos dummy para testing sin metadata real
create_dummy_groups <- function(n_als = 40, n_control = 40) {
  tibble(
    sample_id = paste0("sample_", 1:(n_als + n_control)),
    group = c(rep("ALS", n_als), rep("Control", n_control))
  )
}
```

### **Opción B: Usar Metadata Real (Si disponible)**
```r
# Si tienes archivo de grupos real
real_groups <- read.csv("path/to/real/groups.csv")
```

---

## 📋 **PLAN DE IMPLEMENTACIÓN**

### **Fase 1: Statistical Framework** (1 hora)
```r
# Crear functions/statistical_tests.R:
# - wilcoxon_test_generic()
# - fisher_test_generic()
# - fdr_correction()
# - effect_size_cohens_d()
# - effect_size_odds_ratio()
```

### **Fase 2: Comparison Functions** (1.5 horas)
```r
# Crear functions/comparison_functions.R:
# - load_sample_groups()
# - compare_global_gt_burden()
# - compare_positions_by_group()
# - compare_seed_by_group()
# - identify_differential_mirnas()
```

### **Fase 3: Visualization Functions** (1 hora)
```r
# Crear functions/comparison_visualizations.R:
# - create_global_burden_plot()
# - create_position_delta_plot() ⭐
# - create_seed_interaction_plot()
# - create_volcano_plot()
# - create_figure_3_comparison()
```

### **Fase 4: Testing & Validation** (30 min)
```r
# Crear test_figure_3_dummy.R:
# - Generar datos dummy
# - Ejecutar pipeline completo
# - Validar outputs
```

**TOTAL: ~4 horas**

---

## 🎯 **PRÓXIMO PASO INMEDIATO**

Voy a crear:
1. ✅ `functions/statistical_tests.R` - Tests genéricos
2. ✅ `functions/comparison_functions.R` - Comparaciones
3. ✅ `functions/comparison_visualizations.R` - Visualizaciones
4. ✅ `test_figure_3_dummy.R` - Script de prueba con datos dummy
5. ✅ Generar Figura 3 con datos simulados

**¿Procedemos con la implementación? 🚀**

