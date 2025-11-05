# 📁 ORGANIZACIÓN COMPLETA - Pipeline 2

## 🎯 **ESTRUCTURA ACTUAL**

### **FIGURAS PRINCIPALES:**
- **Figura 1 COMPLETE** (6 paneles) - Lo mejor de ambas versiones
- **Figura 1.5** (4 paneles) - Análisis preliminares extras
- **Figura 2** - Panel A corregido (te gustó)
- **Figura 3** - Group comparison (en progreso)

### **UBICACIÓN DE ARCHIVOS:**

```
pipeline_2/
├── figures/                          # TODAS las figuras generadas
│   ├── panel_a_overview_COMPLETE.png         # Figura 1 Panel A
│   ├── panel_b_gt_count_by_position_COMPLETE.png
│   ├── panel_c_spectrum_COMPLETE.png         # RESTAURADO
│   ├── panel_d_top_mirnas_gt_COMPLETE.png    # RESTAURADO
│   ├── panel_e_total_snv_by_position_COMPLETE.png
│   ├── panel_f_snv_per_mirna_COMPLETE.png
│   ├── panel_a_snv_per_mirna_detailed_1_5.png    # Figura 1.5 Panel A
│   ├── panel_b_gt_per_mirna_detailed_1_5.png     # Figura 1.5 Panel B
│   ├── panel_c_gt_per_sample_detailed_1_5.png    # Figura 1.5 Panel C
│   ├── panel_d_position_comparison_detailed_1_5.png
│   ├── panel_a_gcontent_CLEAR.png                # Figura 2 Panel A (corregido)
│   └── [50+ figuras adicionales de versiones anteriores]
│
├── figures/                          # TABLAS generadas
│   ├── tabla_top_25_mirnas_snv_1_5.csv
│   ├── tabla_top_20_mirnas_gt_1_5.csv
│   ├── tabla_top_15_samples_gt_1_5.csv
│   ├── tabla_position_stats_1_5.csv
│   └── [tablas de versiones anteriores]
│
├── config/
│   └── config_pipeline_2.R           # Configuración principal
│
├── scripts/
│   ├── generate_figure_1_COMPLETE.R              # Figura 1 completa
│   ├── generate_figure_1_5_PRELIMINARES.R        # Figura 1.5 análisis extras
│   ├── generate_figure_2_CORRECTED_PANEL_A.R     # Figura 2 Panel A corregido
│   ├── generate_figure_3_OPTIMIZED.R             # Figura 3 (en progreso)
│   └── [scripts de versiones anteriores]
│
├── HTML_VIEWERS/
│   ├── FIGURAS_COMPARACION_COMPLETA.html         # Viewer principal
│   ├── FIGURAS_CORREGIDAS_FINAL.html             # Viewer versiones anteriores
│   └── [otros viewers]
│
└── DOCUMENTACION/
    ├── ORGANIZACION_COMPLETA.md                   # Este archivo
    ├── DEFINICIONES_METRICAS.md
    ├── CORRECCIONES_COMPLETADAS.md
    ├── STYLE_GUIDE.md
    └── [otros docs]
```

---

## 🎨 **FIGURAS ORGANIZADAS POR VERSIÓN**

### **FIGURA 1 COMPLETE (6 Paneles):**
1. **Panel A:** Dataset Evolution + Mutation COUNTS + STATISTICS
2. **Panel B:** G>T COUNT by Position + STATISTICS (Seed vs Non-Seed)
3. **Panel C:** G>X Spectrum (RESTAURADO de versión anterior)
4. **Panel D:** Top miRNAs with G>T (RESTAURADO + STATISTICS)
5. **Panel E:** Total SNV COUNT by Position (NUEVO)
6. **Panel F:** SNV COUNT per miRNA - ALL mutations (NUEVO)

### **FIGURA 1.5 PRELIMINARES (4 Paneles):**
1. **Panel A:** SNV COUNT per miRNA - TOP 25 (DETAILED)
2. **Panel B:** G>T SNV COUNT per miRNA - TOP 20
3. **Panel C:** G>T SNV COUNT per Sample - TOP 15
4. **Panel D:** SNV COUNT by Position - ALL vs G>T

### **FIGURA 2 (Panel A Corregido):**
- **Panel A:** G-Content vs Oxidation (CORREGIDO - Scatter + Bar Chart)

### **FIGURA 3 (En Progreso):**
- Group comparison con datos reales

---

## 📊 **TABLAS GENERADAS**

### **Figura 1.5 Tablas:**
1. `tabla_top_25_mirnas_snv_1_5.csv` - Top 25 miRNAs con más SNVs
2. `tabla_top_20_mirnas_gt_1_5.csv` - Top 20 miRNAs con más G>T
3. `tabla_top_15_samples_gt_1_5.csv` - Top 15 muestras con más G>T
4. `tabla_position_stats_1_5.csv` - Estadísticas por posición

---

## 🎯 **ANÁLISIS INCLUIDOS**

### **Estadísticas en TODOS los paneles:**
- ✅ Mean, SD, median, percentages
- ✅ Peak positions identificadas
- ✅ Top contributors
- ✅ Seed vs Non-Seed comparisons
- ✅ Números explícitos en barras
- ✅ Subtítulos con estadísticas clave

### **Tendencias mostradas:**
- ✅ Which positions have most G>T mutations
- ✅ Which miRNAs contribute most to total SNVs
- ✅ Which samples have most G>T mutations
- ✅ Seed vs Non-Seed distribution patterns
- ✅ G>X mutation spectrum by position
- ✅ Statistical summaries (mean, SD, percentages)

---

## 🌐 **VIEWERS HTML**

### **Viewer Principal:**
- `FIGURAS_COMPARACION_COMPLETA.html` - Muestra Figura 1 COMPLETE + Figura 2 Panel A corregido

### **Viewers Secundarios:**
- `FIGURAS_CORREGIDAS_FINAL.html` - Versiones anteriores
- [Otros viewers específicos]

---

## 📝 **SCRIPTS DE GENERACIÓN**

### **Scripts Principales:**
1. `generate_figure_1_COMPLETE.R` - Figura 1 completa (6 paneles)
2. `generate_figure_1_5_PRELIMINARES.R` - Figura 1.5 análisis extras (4 paneles)
3. `generate_figure_2_CORRECTED_PANEL_A.R` - Figura 2 Panel A corregido
4. `generate_figure_3_OPTIMIZED.R` - Figura 3 group comparison

### **Scripts de Versiones Anteriores:**
- [50+ scripts de desarrollo y versiones anteriores]

---

## 🔄 **VERSIONADO**

### **Versión Actual:**
- **Figura 1 COMPLETE:** v1.0 (6 paneles completos)
- **Figura 1.5:** v1.0 (4 paneles preliminares)
- **Figura 2:** v2.0 (Panel A corregido)
- **Figura 3:** v0.5 (En desarrollo)

### **Historial:**
- Versiones anteriores preservadas en `figures/`
- Scripts de versiones anteriores preservados
- Documentación de cambios en `CHANGELOG.md`

---

## 🎯 **PRÓXIMOS PASOS**

1. **Completar Figura 3** (group comparison)
2. **Generar HTML viewer final** con todas las figuras
3. **Crear documentación final** del pipeline
4. **Validar estadísticas** con datos reales
5. **Optimizar rendimiento** para datasets grandes

---

## 📍 **DÓNDE ENCONTRAR TODO**

### **Para ver figuras:**
- Abrir: `FIGURAS_COMPARACION_COMPLETA.html`

### **Para regenerar figuras:**
- Ejecutar scripts en `scripts/`

### **Para ver tablas:**
- Archivos CSV en `figures/`

### **Para entender organización:**
- Este archivo: `ORGANIZACION_COMPLETA.md`

---

**Última actualización:** 16 Octubre 2025
**Estado:** ✅ COMPLETO - Figura 1, Figura 1.5, Figura 2 Panel A
**En progreso:** Figura 3 group comparison

