# 📊 LAYOUTS DE FIGURAS - PIPELINE_2

## 🎯 **FILOSOFÍA DE DISEÑO**

### **Principios guía:**
1. **Máxima información, mínimo espacio** - Cada panel debe responder múltiples preguntas
2. **Coherencia visual** - Usar paletas de colores consistentes
3. **Claridad estadística** - Incluir significancia, tamaños de efecto, intervalos de confianza
4. **Inspiración en papers** - Adaptar visualizaciones profesionales y efectivas
5. **Multi-panel** - Combinar múltiples perspectivas en una sola figura

---

## 📊 **FIGURA 1: CARACTERIZACIÓN DEL DATASET**

### **Objetivo:** Responder preguntas básicas sobre estructura y composición del dataset

### **Layout: 2x2 Grid (16" x 12")**

```
┌─────────────────┬─────────────────┐
│   PANEL A       │   PANEL B       │
│   Evolución     │   Heatmap       │
│   Dataset       │   Posicional    │
└─────────────────┴─────────────────┘
┌─────────────────┬─────────────────┐
│   PANEL C       │   PANEL D       │
│   Tipos         │   Top           │
│   Mutación      │   miRNAs        │
└─────────────────┴─────────────────┘
```

### **Panel A: Evolución del Dataset**
- **Tipo:** Barras verticales con etiquetas
- **Ejes:**
  - X: Pasos de procesamiento (Original → Split-Collapse → VAF Filter → Final)
  - Y: Número de SNVs
- **Información mostrada:**
  - Número de SNVs en cada paso
  - Número de miRNAs únicos (en etiquetas)
  - Reducción porcentual entre pasos
- **Paleta:** Viridis (degradado)
- **Pregunta respondida:** "¿Cuál es la estructura y calidad del dataset?"

### **Panel B: Heatmap Posicional de SNVs G>T** ⭐ *Inspirado en paper*
- **Tipo:** Heatmap horizontal con posiciones 1-22
- **Ejes:**
  - X: Posición en miRNA (1-22)
  - Y: Intensidad (un solo nivel)
- **Información mostrada:**
  - Total de SNVs G>T por posición (color)
  - Número de miRNAs únicos afectados (etiquetas)
  - Región seed destacada (posiciones 2-8)
- **Paleta:** Viridis (intensidad)
- **Pregunta respondida:** "¿Dónde ocurren las mutaciones G>T en los miRNAs?"

### **Panel C: Tipos de Mutación G→X por Posición** ⭐ *Inspirado en paper*
- **Tipo:** Barras apiladas
- **Ejes:**
  - X: Posición en miRNA (1-22)
  - Y: Fracción de mutaciones (0-100%)
- **Información mostrada:**
  - Fracción de cada tipo de mutación G→X
  - Dominancia de G>T (esperado: >60%)
  - Patrones posicionales
- **Paleta:** Set2 (4 colores: G>T, G>A, G>C, G>G)
- **Pregunta respondida:** "¿Qué tipos de mutación G→X son más prevalentes?"

### **Panel D: Top miRNAs con Más Mutaciones G>T**
- **Tipo:** Barras horizontales ordenadas
- **Ejes:**
  - X: Número de mutaciones G>T
  - Y: Nombres de miRNAs (ordenados)
- **Información mostrada:**
  - Total de mutaciones G>T por miRNA
  - Número de posiciones únicas afectadas (color)
  - Top 15 miRNAs más afectados
- **Paleta:** Viridis (posiciones únicas)
- **Pregunta respondida:** "¿Cuáles son los miRNAs más susceptibles al estrés oxidativo?"

---

## 📊 **FIGURA 2: ANÁLISIS G>T EXCLUSIVO ALS vs CONTROL**

### **Objetivo:** Identificar diferencias entre grupos en mutaciones de estrés oxidativo

### **Layout: 2x2 Grid (16" x 12")**

```
┌─────────────────┬─────────────────┐
│   PANEL A       │   PANEL B       │
│   Heatmap       │   Distribución  │
│   VAFs G>T      │   VAFs          │
└─────────────────┴─────────────────┘
┌─────────────────┬─────────────────┐
│   PANEL C       │   PANEL D       │
│   Volcano       │   miRNAs        │
│   Plot          │   Diferenciales │
└─────────────────┴─────────────────┘
```

### **Panel A: Heatmap de VAFs G>T por miRNA y Muestra**
- **Tipo:** Heatmap con clustering jerárquico
- **Ejes:**
  - X: Muestras (agrupadas por ALS/Control)
  - Y: miRNAs (ordenados por clustering)
- **Información mostrada:**
  - VAF de mutaciones G>T (color)
  - Clustering de muestras
  - Patrones de expresión
- **Paleta:** RdYlBu (divergente)
- **Anotaciones:** Barra lateral indicando grupo (ALS/Control)
- **Pregunta respondida:** "¿Hay patrones de VAFs G>T entre muestras?"

### **Panel B: Distribución de VAFs G>T por Grupo**
- **Tipo:** Boxplot + violin plot + puntos
- **Ejes:**
  - X: Grupo (ALS vs Control)
  - Y: VAF de mutaciones G>T
- **Información mostrada:**
  - Distribución de VAFs por grupo
  - Mediana, cuartiles, outliers
  - Test estadístico (Wilcoxon) con p-valor
  - Tamaño de efecto (d de Cohen)
- **Paleta:** Set1 (ALS: rojo, Control: azul)
- **Pregunta respondida:** "¿Hay diferencias en mutaciones G>T entre grupos?"

### **Panel C: Volcano Plot de Significancia**
- **Tipo:** Scatter plot con umbrales
- **Ejes:**
  - X: log2(Fold Change) ALS vs Control
  - Y: -log10(p-valor ajustado)
- **Información mostrada:**
  - Cada punto = un miRNA
  - Color según significancia (rojo: sig ALS, azul: sig Control, gris: no sig)
  - Umbrales: FDR < 0.05, |log2FC| > 0.5
  - miRNAs significativos etiquetados
- **Paleta:** RdBu (divergente)
- **Pregunta respondida:** "¿Qué miRNAs muestran diferencias significativas?"

### **Panel D: Top miRNAs Diferenciales**
- **Tipo:** Barras horizontales con intervalos de confianza
- **Ejes:**
  - X: Diferencia promedio VAF (ALS - Control)
  - Y: Nombres de miRNAs (ordenados por efecto)
- **Información mostrada:**
  - Diferencia promedio con IC 95%
  - p-valores ajustados (FDR)
  - Top 15 miRNAs más diferenciales
  - Anotación de región (seed/no-seed)
- **Paleta:** RdBu (positivo/negativo)
- **Pregunta respondida:** "¿Cuál es la magnitud del efecto y su significancia?"

---

## 📊 **FIGURA 3: ANÁLISIS FUNCIONAL**

### **Objetivo:** Evaluar impacto funcional de mutaciones G>T

### **Layout: 2x2 Grid (16" x 12")**

```
┌─────────────────┬─────────────────┐
│   PANEL A       │   PANEL B       │
│   Seed vs       │   Patrones      │
│   No-Seed       │   Secuencia     │
└─────────────────┴─────────────────┘
┌─────────────────┬─────────────────┐
│   PANEL C       │   PANEL D       │
│   Pathways      │   Validación    │
│   Enriquecidos  │   Funcional     │
└─────────────────┴─────────────────┘
```

### **Panel A: Mutaciones G>T en Región Seed vs No-Seed**
- **Tipo:** Barras agrupadas + heatmap
- **Ejes:**
  - X: Región (Seed [2-8] vs No-Seed [9-22])
  - Y: Número de mutaciones G>T
- **Información mostrada:**
  - Total de mutaciones por región
  - Comparación ALS vs Control
  - Test estadístico (Chi-cuadrado)
  - Distribución posicional detallada (subpanel)
- **Paleta:** Set1 (Seed: amarillo, No-Seed: verde)
- **Pregunta respondida:** "¿Las mutaciones G>T afectan regiones funcionales?"

### **Panel B: Patrones de Secuencia**
- **Tipo:** Logos de secuencia + motifs
- **Información mostrada:**
  - Contexto de secuencia alrededor de G>T
  - Motifs enriquecidos
  - Comparación con expectativa aleatoria
  - Frecuencia de dinucleótidos (GG, GA, GC, GT)
- **Paleta:** DNA (A:verde, T:rojo, G:amarillo, C:azul)
- **Pregunta respondida:** "¿Hay patrones de secuencia específicos?"

### **Panel C: Análisis de Pathways Enriquecidos**
- **Tipo:** Dot plot de enriquecimiento
- **Ejes:**
  - X: Gene Ratio (genes en pathway / total)
  - Y: Pathways (ordenados por FDR)
- **Información mostrada:**
  - Top 10 pathways más enriquecidos
  - Tamaño del punto = número de genes
  - Color = FDR (significancia)
  - p-valores ajustados
- **Paleta:** Viridis (inverso: más rojo = más significativo)
- **Pregunta respondida:** "¿Qué pathways están afectados?"

### **Panel D: Validación Funcional**
- **Tipo:** Gráfica de red + tabla resumen
- **Información mostrada:**
  - Red de interacciones miRNA-target
  - miRNAs más afectados (nodos)
  - Genes target predichos (nodos)
  - Evidencia experimental (color de arista)
  - Tabla: Top 5 miRNAs con validación
- **Paleta:** Set3 (multi-categoría)
- **Pregunta respondida:** "¿Cómo validamos los hallazgos?"

---

## 📊 **FIGURAS ADICIONALES (OPCIONALES)**

### **FIGURA 4: ANÁLISIS TEMPORAL/LONGITUDINAL** (Si hay datos)
- Panel A: Evolución de VAFs G>T en el tiempo
- Panel B: Progresión de síntomas vs mutaciones
- Panel C: Clustering temporal
- Panel D: Predicción de progresión

### **FIGURA 5: ANÁLISIS DE CONFOUNDERS**
- Panel A: Edad vs VAFs G>T
- Panel B: Sexo vs VAFs G>T
- Panel C: Medicamentos vs VAFs G>T
- Panel D: Regresión multivariada

---

## 🎨 **ESPECIFICACIONES TÉCNICAS**

### **Dimensiones estándar:**
- **Figuras principales**: 16" x 12" (horizontal)
- **Figuras suplementarias**: 12" x 9"
- **DPI**: 300 (publicación)
- **Formato**: PNG (principal), PDF (vectorial)

### **Paletas de colores:**
- **Categórico**: Set1, Set2, Set3
- **Continuo**: Viridis, Plasma, Inferno
- **Divergente**: RdBu, RdYlBu, PiYG
- **Grupos**: RdBu (ALS: rojo, Control: azul)

### **Tipografía:**
- **Títulos**: Arial Bold, 16pt
- **Subtítulos**: Arial, 12pt
- **Ejes**: Arial, 10pt
- **Etiquetas**: Arial, 8pt

### **Elementos requeridos:**
- **Títulos descriptivos** en cada panel
- **Etiquetas de ejes** claras y completas
- **Leyendas** con unidades
- **Estadísticas** visibles (p-valores, IC)
- **N** (tamaño de muestra) en cada panel

---

## 📋 **CHECKLIST PRE-PUBLICACIÓN**

### **Para cada figura:**
- [ ] ¿Responde claramente las preguntas científicas?
- [ ] ¿Tiene título descriptivo?
- [ ] ¿Ejes etiquetados correctamente?
- [ ] ¿Incluye estadísticas relevantes?
- [ ] ¿Paleta de colores accesible (colorblind-friendly)?
- [ ] ¿Tamaño de fuente legible (>8pt)?
- [ ] ¿DPI adecuado (300)?
- [ ] ¿Leyenda completa?
- [ ] ¿N reportado?
- [ ] ¿Archivos fuente guardados (.R)?

