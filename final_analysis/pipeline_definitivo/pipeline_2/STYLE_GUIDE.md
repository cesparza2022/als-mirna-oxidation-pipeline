# 🎨 STYLE GUIDE - PIPELINE_2 VISUALIZATIONS

**Basado en tus preferencias de diseño**

---

## 📊 **ESTILO PREFERIDO PARA COMPARACIONES DE GRUPOS**

### **Panel B: Position Delta - TU ESTILO ⭐**

**Elementos clave:**

```r
# 1. Theme
theme_classic(base_size = 14)  # Limpio, profesional

# 2. Barras lado a lado
geom_col(
  position = position_dodge(width = 0.8),  # Separación clara
  width = 0.7                               # No muy anchas
)

# 3. Seed region shading (sutil)
annotate(
  "rect",
  xmin = 2 - 0.5, xmax = 8 + 0.5,
  ymin = 0, ymax = ymax,
  fill = "grey80", alpha = 0.3            # Gris suave
)

# 4. Colores (profesionales)
scale_fill_manual(
  values = c(
    "Control" = "grey60",    # Gris para control
    "ALS"     = "#D62728"    # Rojo oscuro para ALS
  )
)

# 5. Asteriscos (solo en grupo de interés)
geom_text(
  data = filter(plot_df, group == "ALS" & p_adj < 0.05),
  aes(label = "*"),
  position = position_nudge(x = 0.2),
  vjust = -0.5, size = 5, color = "black"
)

# 6. Escala X continua
scale_x_continuous(
  breaks = 1:22,
  minor_breaks = NULL
)

# 7. Legend integrada (top-right)
theme(
  legend.position = c(0.85, 0.9),
  axis.text.x = element_text(size = 10)
)

# 8. Coord cartesian (no cortar datos)
coord_cartesian(ylim = c(0, ymax))
```

---

## 🎨 **PALETA DE COLORES - ACTUALIZADA**

### **Para Comparaciones de Grupos:**
```
Control:  "grey60"   (⚪ Gris - baseline, neutral)
ALS:      "#D62728"  (🔴 Rojo oscuro - disease, destacado)
Seed:     "grey80"   (⚪ Gris claro - shading sutil)
Stars:    "black"    (⚫ Negro - significancia)
```

**Rationale:**
- Gris para control = neutral, baseline
- Rojo oscuro para ALS = enfermedad, contraste claro
- Shading gris suave = no compite visualmente
- Negro para asteriscos = máxima claridad

---

## 📐 **DIMENSIONES Y FORMATO**

### **Tamaños de figuras:**
```r
# Panel individual (como Panel B):
width = 12, height = 7

# Figura completa (4 paneles):
width = 20, height = 16

# DPI:
dpi = 300

# Background:
bg = "white"
```

---

## 🔤 **TIPOGRAFÍA Y TEXTO**

### **Titles:**
```r
plot.title = element_text(
  face = "bold",
  size = 13,      # No muy grande
  hjust = 0.5     # Centrado
)
```

### **Subtitles:**
```r
plot.subtitle = element_text(
  size = 10,
  hjust = 0.5,
  color = "gray40"  # Más sutil
)
```

### **Axis text:**
```r
axis.text.x = element_text(size = 10)
axis.text.y = element_text(size = 10)
```

---

## ⭐ **SIGNIFICANCIA ESTADÍSTICA**

### **Estilo preferido:**

```r
# Asteriscos simples (no ***)
geom_text(
  data = filter(data, group == "ALS" & p_adj < 0.05),
  aes(label = "*"),
  position = position_nudge(x = 0.2),  # Offset to right
  vjust = -0.5,   # Above bar
  size = 5,       # Visible pero no enorme
  color = "black" # Negro sólido
)

# Subtitle incluye criterio:
subtitle = "... *p_adj<0.05"
```

**NO usar:**
- ~~Múltiples asteriscos (**)~~
- ~~Colores en asteriscos~~
- ~~Tamaños variables~~

---

## 📊 **LAYOUT PREFERENCIAS**

### **Barras lado a lado:**
```r
position = position_dodge(width = 0.8)  # Separación clara
width = 0.7                              # Barras no muy anchas
```

### **Legend:**
```r
# Preferencia: Integrada en el plot (top-right)
legend.position = c(0.85, 0.9)

# Alternativa: Right side
legend.position = "right"
```

### **Grid:**
```r
# Theme classic ya maneja grid apropiadamente
# Solo remover minor breaks en X:
scale_x_continuous(minor_breaks = NULL)
```

---

## 🎯 **APLICAR A OTRAS FIGURAS**

### **Para actualizar otros paneles:**

**Panel A (Global burden):** ✅ Aplicar theme_classic  
**Panel C (Seed interaction):** ✅ Aplicar colores grey/red  
**Panel D (Volcano):** Mantener estilo actual (apropiado)

---

## 📝 **REGISTRO DE CAMBIOS**

**Archivos actualizados:**
- ✅ `generate_panel_b_IMPROVED_STYLE.R` - Nueva versión
- ✅ `panel_b_position_delta_IMPROVED.png` - Output mejorado
- ✅ `STYLE_GUIDE.md` - Este documento
- ✅ `CHANGELOG.md` - v0.4.1

**Para implementar en pipeline:**
- Actualizar `comparison_visualizations.R` con este estilo
- Aplicar a `create_position_delta_plot()`

---

## ✅ **ESTILO FINAL DEFINIDO**

**Base:**
- `theme_classic()` con base_size = 14
- Colores: grey60 (Control), #D62728 (ALS)
- Seed shading: grey80, alpha = 0.3
- Asteriscos negros simples
- Legend integrada (0.85, 0.9)
- Position dodge width = 0.8

**Resultado:** Figuras más limpias, profesionales y publication-ready ✅

