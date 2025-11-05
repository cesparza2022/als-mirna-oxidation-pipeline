# 🎨 REVISIÓN Y MEJORA - FIGURAS PROFESIONALES

**Objetivo:** Aplicar estilo profesional consistente a TODAS las figuras

---

## 📊 **ANÁLISIS FIGURA POR FIGURA**

### **FIGURA 1: Dataset Characterization**

**Panel A: Dataset Evolution + Mutation Types**
- **Estado actual:** Pie chart para mutation types
- **Mejora:** Cambiar a **horizontal bar chart** (más profesional)
- **Rationale:** Bar charts son más fáciles de leer que pie charts
- **Prioridad:** ⭐⭐⭐⭐ ALTA

**Panel B: G>T Positional**
- **Estado actual:** Heatmap + barras seed/non-seed
- **Mejora:** Aplicar **theme_classic()**, colores más sutiles
- **Prioridad:** ⭐⭐⭐ MEDIA

**Panel C: Mutation Spectrum**
- **Estado actual:** Stacked bars + top 10
- **Mejora:** Mejorar a **grouped bars** con theme_classic
- **Prioridad:** ⭐⭐⭐ MEDIA

**Panel D:** Placeholder → **Agregar tabla de top miRNAs visualizada**
- **Prioridad:** ⭐⭐⭐⭐ ALTA

---

### **FIGURA 2: Mechanistic Validation**

**Panel A: G-content Correlation**
- **Estado actual:** Scatter con loess
- **Mejora:** **theme_classic()**, puntos más sutiles, línea de tendencia más clara
- **Prioridad:** ⭐⭐⭐⭐ ALTA

**Panel B:** Placeholder (requiere secuencias)
- Dejar como está
- **Prioridad:** ⭐ BAJA

**Panel C: G>T Specificity**
- **Estado actual:** Stacked bars por posición
- **Mejora:** **theme_classic()**, colores más profesionales
- **Prioridad:** ⭐⭐⭐ MEDIA

**Panel D: Position G-content**
- **Estado actual:** Barras con seed highlight
- **Mejora:** Aplicar **theme_classic()**, colores consistentes
- **Prioridad:** ⭐⭐⭐ MEDIA

---

### **FIGURA 3: Group Comparison**

**Panel B:** ✅ YA MEJORADO con tu estilo
- theme_classic() ✅
- Colores profesionales ✅
- Legend integrada ✅

**Panel A, C, D:** Aplicar mismo estilo que Panel B
- **Prioridad:** ⭐⭐⭐⭐⭐ CRÍTICA (consistencia)

---

## 🎯 **PLAN DE MEJORAS**

### **PRIORIDAD 1: Consistencia Figura 3** (30 min)
```
✅ Panel B: Ya mejorado
🔧 Panel A: Aplicar theme_classic
🔧 Panel C: Aplicar theme_classic + colores
🔧 Panel D: Aplicar theme_classic
```

### **PRIORIDAD 2: Mejorar Figura 1** (1 hora)
```
🔧 Panel A: Pie → Horizontal bars
🔧 Panel B: theme_classic
🔧 Panel C: Grouped bars más claras
🔧 Panel D: Top miRNAs table visualizada
```

### **PRIORIDAD 3: Mejorar Figura 2** (45 min)
```
🔧 Panel A: theme_classic + scatter mejorado
🔧 Panel C: theme_classic + colores
🔧 Panel D: theme_classic
```

### **PRIORIDAD 4: Integrar Tablas en HTML** (30 min)
```
🔧 Crear tab "Tables" en MASTER_VIEWER
🔧 Mostrar las 6 tablas formateadas
🔧 Links para descargar CSVs
```

---

## 🎨 **ESTILO PROFESIONAL - ESTÁNDAR**

### **Theme:**
```r
theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"),
    axis.text = element_text(size = 10),
    legend.position = c(0.85, 0.9),  # O "right" según panel
    panel.grid.major.y = element_line(color = "grey90", linewidth = 0.3)
  )
```

### **Colores:**
```r
# Tier 1 (sin grupos):
G>T:      "#FF7F00"  (naranja - menos brillante que antes)
Seed:     "grey80"   (gris suave para shading)
Others:   Viridis or Set3 (paletas profesionales)

# Tier 2 (con grupos):
ALS:      "#D62728"  (rojo oscuro)
Control:  "grey60"   (gris neutral)
Seed:     "grey80"   (shading sutil)
```

### **Barras:**
```r
geom_col(
  position = position_dodge(width = 0.8),
  width = 0.7,
  color = "black",      # Border negro fino
  linewidth = 0.3
)
```

### **Texto:**
```r
# Titles: bold, size 13, centrado
# Subtitles: size 10, gris, centrado
# Axis: size 10
# Annotations: size según espacio
```

---

## 🚀 **PLAN DE ACCIÓN - PRÓXIMAS 3 HORAS**

### **HORA 1: Figura 3 completa (consistencia)**
- Aplicar theme_classic a Panels A, C, D
- Mismo estilo que Panel B
- Regenerar figura completa

### **HORA 2: Figuras 1-2 mejoradas**
- Panel A (Fig 1): Pie → Bars
- Panel D (Fig 1): Top miRNAs visualizado
- Panel A (Fig 2): Scatter mejorado
- Aplicar theme_classic donde corresponda

### **HORA 3: HTML con Tablas**
- Integrar las 6 tablas en HTML
- Tab "Tables" con todas las tablas formateadas
- Links de descarga
- Estilo profesional

---

## 📋 **DELIVERABLES ESPERADOS**

**Después de las mejoras:**
```
FIGURAS (16+ PNG):
├── figure_1_PROFESSIONAL.png         [Versión mejorada]
├── figure_2_PROFESSIONAL.png         [Versión mejorada]
├── figure_3_PROFESSIONAL.png         [Consistente]
└── [+13 paneles mejorados]

TABLAS (6 CSV):
├── table1_dataset_summary.csv        ✅ Ya generada
├── table2_mutation_types.csv         ✅
├── table3_gt_by_position.csv         ✅
├── table4_seed_vs_nonseed.csv        ✅
├── table5_top_mirnas.csv             ✅
└── table6_gcontent_correlation.csv   ✅

HTML VIEWER (1 archivo):
└── MASTER_VIEWER_PROFESSIONAL.html   [Con figuras + tablas]
    ├── Tab Figures (3 figuras mejoradas)
    └── Tab Tables (6 tablas integradas)

DOCUMENTACIÓN:
└── STYLE_GUIDE.md                    [Estilo definido]
```

---

## ✅ **¿PROCEDEMOS?**

Voy a implementar en orden:

1. ✅ **Figura 3 completa** (Panels A,C,D con estilo profesional) - 30 min
2. ✅ **Figura 1 mejorada** (Pie→Bars, Panel D nuevo, theme_classic) - 1 hora
3. ✅ **Figura 2 mejorada** (theme_classic, scatter refinado) - 45 min
4. ✅ **HTML con tablas integradas** - 30 min

**TOTAL: ~3 horas → Pipeline 100% profesional y publication-ready**

**TODO será registrado paso a paso** 📝

**¿Empezamos? 🚀**

