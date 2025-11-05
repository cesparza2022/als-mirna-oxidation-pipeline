# 🎯 PLAN FIGURA 1 - ANÁLISIS INICIAL COMPLETO

## 📋 **OBJETIVO:** Responder paso a paso las preguntas básicas del dataset

---

## 📊 **ESTRUCTURA PROPUESTA: 2x3 Grid (6 Paneles)**

```
┌─────────────────┬─────────────────┬─────────────────┐
│   PANEL A       │   PANEL B       │   PANEL C       │
│   Evolución     │   Distribución  │   miRNAs        │
│   Dataset       │   Mutation      │   y Familias    │
│                 │   Types         │                 │
└─────────────────┴─────────────────┴─────────────────┘
┌─────────────────┬─────────────────┬─────────────────┐
│   PANEL D       │   PANEL E       │   PANEL F       │
│   G-Content     │   G>X Spectrum  │   Seed vs       │
│   por Posición  │   por Posición  │   No-Seed       │
└─────────────────┴─────────────────┴─────────────────┘
```

---

## 📊 **PANEL A: Evolución del Dataset**

### **Pregunta:** ¿Cómo cambia el dataset con split-collapse?

### **Visualización:** Barras horizontales
- **Split:** # SNVs, # miRNAs
- **Collapse:** # SNVs, # miRNAs  
- **Reducción:** % perdido en cada paso
- **Colores:** Azul (split), Verde (collapse)

### **Información mostrada:**
- Números exactos en barras
- Porcentajes de reducción
- Justificación de filtros

---

## 📊 **PANEL B: Distribución de Tipos de Mutación**

### **Pregunta:** ¿Qué proporción de SNVs son de cada tipo?

### **Visualización:** Barras horizontales apiladas
- **12 tipos:** A>C, A>G, A>T, C>A, C>G, C>T, G>A, G>C, G>T, T>A, T>C, T>G
- **G>T en ROJO** (oxidación)
- **Números:** Count y % de cada tipo

### **Información mostrada:**
- Total SNVs por tipo
- Porcentaje de cada tipo
- Dominancia de G>T

---

## 📊 **PANEL C: miRNAs y Familias**

### **Pregunta:** ¿Cuántos miRNAs únicos tenemos y hay familias?

### **Visualización:** 
- **Subpanel C1:** # miRNAs únicos (número grande)
- **Subpanel C2:** Top familias de miRNAs (si aplica)
- **Subpanel C3:** Distribución de longitud de miRNAs

### **Información mostrada:**
- Total miRNAs únicos
- Familias más representadas
- Rango de longitudes

---

## 📊 **PANEL D: G-Content por Posición**

### **Pregunta:** ¿Cuántas Gs hay en cada posición?

### **Visualización:** Barras verticales con números
- **Eje X:** Posición (1-22)
- **Eje Y:** Número de Gs
- **Seed region:** Destacada en amarillo
- **Números:** Count exacto en cada barra

### **Información mostrada:**
- Count de Gs por posición
- Mean ± SD
- Seed vs No-Seed comparison

---

## 📊 **PANEL E: G>X Spectrum por Posición** ⭐ *Basado en tu figura favorita*

### **Pregunta:** ¿Proporción de G>T vs otras mutaciones G>X por posición?

### **Visualización:** Barras agrupadas (como tu figura)
- **G>A:** Azul
- **G>C:** Verde  
- **G>T:** ROJO (oxidación)
- **Seed region:** Fondo amarillo
- **Números:** Count en cada barra

### **Información mostrada:**
- Count de cada tipo por posición
- Proporción G>T vs resto
- Patrones posicionales

---

## 📊 **PANEL F: Comparación Seed vs No-Seed**

### **Pregunta:** ¿Diferencias entre regiones funcionales?

### **Visualización:** Boxplot + estadísticas
- **Seed (2-8):** Amarillo
- **No-Seed (9-22):** Verde
- **Métricas:** SNV count, G>T count, G-content

### **Información mostrada:**
- Mean ± SD por región
- Test estadístico (t-test o Wilcoxon)
- P-value y tamaño de efecto

---

## 🎨 **ESPECIFICACIONES DE ESTILO:**

### **Colores:**
- **G>T (oxidación):** #D62728 (rojo)
- **Seed region:** #FFF2CC (amarillo claro)
- **No-Seed:** #D5E8D4 (verde claro)
- **Otros tipos:** Paleta Set2

### **Tipografía:**
- **Base size:** 12
- **Títulos:** 14, bold
- **Números:** 10, bold
- **Fuente:** Arial

### **Elementos:**
- **Números en barras:** Siempre visibles
- **Estadísticas:** Mean ± SD, p-values
- **Leyendas:** Claramente posicionadas
- **Grid:** Sutil, no intrusivo

---

## 📊 **INFORMACIÓN ESTADÍSTICA REQUERIDA:**

### **Para cada panel:**
1. **Counts exactos** (números en gráficas)
2. **Porcentajes** (donde aplique)
3. **Mean ± SD** (para distribuciones)
4. **Test estadístico** (para comparaciones)
5. **P-values** (para significancia)

### **Resumen ejecutivo:**
- Total SNVs procesados
- % de G>T mutations
- miRNAs más afectados
- Seed vs No-Seed differences

---

## 🔧 **IMPLEMENTACIÓN:**

### **Scripts a crear/modificar:**
1. `generate_FIGURE_1_INICIAL_COMPLETA.R` - Script principal
2. Funciones individuales por panel
3. `VIEWER_FIGURA_1_INICIAL.html` - Visualizador

### **Datos requeridos:**
- Raw data (split)
- Processed data (collapse)
- Mutation types distribution
- miRNA families (si disponible)
- Position-specific counts

---

## ✅ **CHECKLIST DE COMPLETITUD:**

- [ ] Panel A: Evolución dataset con números
- [ ] Panel B: 12 tipos de mutación con %
- [ ] Panel C: miRNAs únicos y familias
- [ ] Panel D: G-content por posición
- [ ] Panel E: G>X spectrum (como tu figura)
- [ ] Panel F: Seed vs No-Seed comparison
- [ ] Colores profesionales (G>T en rojo)
- [ ] Números visibles en todas las barras
- [ ] Estadísticas completas
- [ ] HTML viewer integrado

---

**¿Procedemos a implementar esta Figura 1 completa?** 🚀

