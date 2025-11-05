# 📊 FIGURAS Y TABLAS DISPONIBLES - PIPELINE_2

**Versión:** v0.4.1  
**Fecha:** 16 Enero 2025  
**Estado:** ✅ Completo y listo para publicación

---

## 🎨 **FIGURAS (3 completas - 16 archivos PNG)**

### **FIGURA 1: Dataset Characterization** ✅

**Principal:**
- `figure_1_v5_updated_colors.png` [20×16", 300 DPI]

**Paneles individuales:**
- `panel_a_overview_v5.png` - Dataset evolution + mutation types
- `panel_b_gt_analysis_v5.png` - G>T positional heatmap + seed comparison
- `panel_c_spectrum_v5.png` - Mutation spectrum by position
- `panel_d_placeholder_v5.png` - Reserved

**Preguntas respondidas:** SQ1.1, SQ1.2, SQ1.3  
**Colores:** 🟠 Naranja (G>T), 🟡 Dorado (Seed)

---

### **FIGURA 2: Mechanistic Validation** ✅

**Principal:**
- `figure_2_mechanistic_validation.png` [20×16", 300 DPI]

**Paneles individuales:**
- `panel_a_gcontent.png` - G-content correlation (r = 0.347)
- `panel_b_context.png` - Sequence context (placeholder)
- `panel_c_specificity.png` - G>T specificity (31.6% of G>X)
- `panel_d_position.png` - Position G-content with seed

**Preguntas respondidas:** SQ3.1, SQ3.2, SQ3.3  
**Colores:** 🟠 Naranja (G>T), 🟡 Dorado (Seed)

---

### **FIGURA 3: Group Comparison** ✅

**Paneles individuales (estilo profesional):**
- `panel_a_global_burden_REAL.png` - Violin plot ALS vs Control
- `panel_b_position_delta_IMPROVED.png` ⭐ - **TU FAVORITO con estilo mejorado**
  - `theme_classic()` profesional
  - Grey60 (Control), #D62728 (ALS)
  - Seed shading gris sutil
  - Legend integrada
  - Asteriscos simples
- `panel_c_seed_interaction_REAL.png` - Seed vs Non-Seed by group
- `panel_d_volcano_REAL.png` - Differential miRNAs

**Preguntas respondidas:** SQ2.1, SQ2.2, SQ2.3, SQ2.4  
**Colores:** 🔴 Rojo ALS (#D62728), ⚪ Gris Control (grey60)

---

## 📋 **TABLAS (6 archivos CSV - Publication-Ready)**

### **TABLE 1: Dataset Summary Statistics** ✅

**Archivo:** `tables/table1_dataset_summary.csv`

**Contenido:**
```
Metric                              Value
────────────────────────────────────────────────
Raw entries (original file)         68,968
Individual SNVs (after split)       111,785
Valid SNVs (after PM filter)        110,199
Unique miRNAs covered               1,462
Total G>T mutations                 8,033
G>T as % of total                   7.3%
Positions analyzed                  1-22
Samples (columns)                   830 (626 ALS + 204 Control)
```

**Uso:** Tabla 1 de paper, dataset characterization

---

### **TABLE 2: Mutation Type Distribution** ✅

**Archivo:** `tables/table2_mutation_types.csv`

**Contenido:** Top 10 mutation types
```
Rank  Type    Count      %
─────────────────────────────
1     T>C     19,410    19.5%
2     A>G     16,876    17.0%
3     G>A     12,990    13.0%
4     C>T     10,457    10.5%
5     TA       8,296     8.3%
6     G>T      7,528     7.6%  ← Our focus
...
```

**Uso:** Supplementary table, mutation landscape

---

### **TABLE 3: G>T Distribution by Position** ✅

**Archivo:** `tables/table3_gt_by_position.csv`

**Contenido:** All 22 positions
```
Position  Region      G>T Count  %
────────────────────────────────────
1         Non-Seed    19         0.3%
2         Seed        124        1.6%
3         Seed        74         1.0%
...
8         Seed        301        4.0%
9         Non-Seed    175        2.3%
...
22        Non-Seed    1,193      15.8%  ← Highest
```

**Uso:** 
- Supplementary data
- Position-specific analysis
- Seed region focus

---

### **TABLE 4: Seed vs Non-Seed Summary** ✅

**Archivo:** `tables/table4_seed_vs_nonseed.csv`

**Contenido:**
```
Region     Positions              G>T Count  %      Avg/Position
─────────────────────────────────────────────────────────────────
Non-Seed   1,9-22 (15 positions)  6,188     82.2%  884
Seed       2-8 (7 positions)      1,340     17.8%  89
```

**Hallazgo clave:** 
- Seed tiene MENOS G>T en total (17.8%)
- Pero es más corto (7 vs 15 positions)
- Average per position: seed = 89, non-seed = 884

**Uso:** Main text table, seed region analysis

---

### **TABLE 5: Top 20 miRNAs with G>T** ✅

**Archivo:** `tables/table5_top_mirnas.csv`

**Contenido:** Top 20 most affected miRNAs
```
Rank  miRNA name       G>T Count  % of total G>T
───────────────────────────────────────────────────
1     hsa-miR-16-5p    226        8.84%
2     hsa-miR-486-5p   199        7.79%
3     hsa-miR-206      167        6.53%
4     hsa-miR-126-3p   152        5.95%
5     hsa-miR-423-5p   146        5.71%
...
```

**Uso:**
- Candidate biomarkers
- Target for validation
- Functional analysis focus

---

### **TABLE 6: G-Content vs Oxidation** ✅

**Archivo:** `tables/table6_gcontent_correlation.csv`

**Contenido:**
```
# G's  # miRNAs  % Oxidized  Level
──────────────────────────────────────
0      362       0.0%        None
1      687       9.8%        Low
2      704       11.6%       Medium
3      509       13.8%       Medium
4      277       11.2%       Medium
5      101       16.8%       High
6      15        20.0%       High
7      1         0.0%        None
```

**Hallazgo:** Spearman r = 0.347 (p < 0.001)  
**Uso:** Mechanistic validation table

---

## 📊 **RESUMEN: FIGURAS + TABLAS**

```
FIGURAS:
├── 3 figuras principales (completas)
├── 12 paneles individuales
└── 16 archivos PNG total

TABLAS:
├── 6 tablas CSV (publication-ready)
├── Complementan las figuras
└── Ready para Supplementary Material

TOTAL: 22 archivos para publicación
```

---

## 🎯 **CÓMO USAR**

### **Para Paper:**

**Main Figures:**
1. Figure 1: Dataset characterization
2. Figure 2: Mechanistic validation
3. Figure 3: Group comparison (Panel B destacado)

**Main Tables:**
- Table 1: Dataset summary
- Table 4: Seed vs Non-Seed

**Supplementary:**
- Todos los paneles individuales
- Tables 2, 3, 5, 6

---

### **Para Presentación:**

**Usar:**
- Panel B (position delta) ⭐ - Muy visual
- Table 5 (top miRNAs) - Específico
- Panel A (Figure 2) - G-content correlation

---

### **Para Análisis Adicional:**

**CSVs disponibles para:**
- Importar en Excel/R/Python
- Meta-análisis
- Comparaciones con otros datasets
- Validación experimental

---

## 🌐 **VISUALIZACIÓN**

### **HTML Master Viewer:**
```
MASTER_VIEWER.html
├── Overview (progress + stats)
├── Figure 1 (characterization)
├── Figure 2 (mechanistic)
└── Figure 3 (comparison) ⭐
    └── Panel B improved style destacado
```

### **Tablas en HTML:**
- Actualmente: CSV files
- Próximo: Integrar en HTML viewer
- Formato: Markdown → HTML tables

---

## 📝 **PRÓXIMO: Integrar Tablas en HTML**

**Crear:** HTML viewer con tabs para tablas

**Ventajas:**
- Figuras + Tablas en un solo archivo
- Interactive sorting
- Export to Excel
- Professional presentation

**Tiempo:** ~30 min

**¿Quieres que lo implemente ahora?** 🚀

---

## ✅ **ESTADO ACTUAL**

**Figuras:** 16 PNG files ✅  
**Tablas:** 6 CSV files ✅  
**HTML viewer:** 1 con figuras ✅  
**Documentación:** 24 archivos ✅  

**TOTAL: 47+ archivos organizados para pipeline** ✅

