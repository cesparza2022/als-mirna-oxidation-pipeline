# 🎯 PASO 2: ANÁLISIS VAF - PLANIFICACIÓN COMPLETA

**Objetivo:** Comparar perfiles VAF entre ALS y Control, identificar diferencias significativas y patrones de estrés oxidativo específicos de la enfermedad.

---

## 📋 PREGUNTAS CLAVE A RESPONDER

### **Q1: ¿HAY DIFERENCIAS GLOBALES EN VAF ENTRE ALS Y CONTROL?**
- ¿La carga mutacional total (VAF global) es mayor en ALS?
- ¿El VAF promedio de G>T es significativamente mayor en ALS?
- ¿Cómo se distribuye el VAF entre muestras de cada grupo?

### **Q2: ¿QUÉ miRNAs ESTÁN MÁS AFECTADOS EN ALS?**
- ¿Qué miRNAs tienen VAF G>T significativamente mayor en ALS?
- ¿Hay miRNAs específicos de ALS o de Control?
- ¿Los miRNAs más afectados tienen algo en común funcionalmente?

### **Q3: ¿HAY PATRONES POSICIONALES ESPECÍFICOS DE ALS?**
- ¿El VAF G>T en la región semilla es mayor en ALS?
- ¿Hay posiciones específicas donde ALS muestra más oxidación?
- ¿El patrón posicional G>T difiere entre grupos?

### **Q4: ¿CÓMO ES LA HETEROGENEIDAD ENTRE MUESTRAS?**
- ¿Las muestras ALS son más heterogéneas que Control?
- ¿Hay subgrupos dentro de ALS o Control?
- ¿Se agrupan las muestras por grupo (ALS/Control) o por otros factores?

### **Q5: ¿QUÉ TAN ESPECÍFICO ES G>T PARA ALS?**
- ¿G>T/G>A ratio es mayor en ALS?
- ¿Otras mutaciones también aumentan en ALS o solo G>T?
- ¿El enriquecimiento de G>T es consistente entre posiciones?

---

## 📊 FIGURAS PROPUESTAS (12 FIGURAS)

### **GRUPO A: COMPARACIONES GLOBALES (3 figuras)**

#### **FIGURA 2.1: COMPARACIÓN DE CARGA VAF GLOBAL**
**Pregunta:** Q1 - Diferencias globales en VAF
**Tipo:** Boxplots + Strip plot + estadísticas
**Contenido:**
- Panel A: VAF total por muestra (ALS vs Control)
- Panel B: VAF G>T por muestra (ALS vs Control)
- Panel C: Ratio G>T/Total VAF (ALS vs Control)
- **Estadísticas:** Wilcoxon rank-sum test, Cohen's d, p-values
- **Estilo:** Boxplot con puntos individuales (jitter), colores ALS=#D62728, Control=#666666

#### **FIGURA 2.2: DISTRIBUCIONES VAF**
**Pregunta:** Q1 - Distribución de VAF entre grupos
**Tipo:** Violin plots + Density plots + CDF
**Contenido:**
- Panel A: Violin plot de VAF G>T (ALS vs Control)
- Panel B: Density plot de VAF G>T (superpuestos)
- Panel C: CDF comparativo (ALS vs Control)
- Panel D: Tabla con estadísticas (media, mediana, SD, IQR)
- **Estadísticas:** Kolmogorov-Smirnov test, mediana, Q1, Q3
- **Estilo:** Violines con ancho normalizado, líneas de mediana/cuartiles

#### **FIGURA 2.3: VOLCANO PLOT - miRNAs DIFERENCIALMENTE AFECTADOS**
**Pregunta:** Q2 - miRNAs con VAF diferencial
**Tipo:** Volcano plot interactivo
**Contenido:**
- Eje X: log2(Fold Change) de VAF G>T (ALS/Control)
- Eje Y: -log10(p-value ajustado por FDR)
- **Colores:**
  - Rojo: Enriquecidos en ALS (FC > 1.5, p < 0.05)
  - Azul: Enriquecidos en Control (FC < 0.67, p < 0.05)
  - Gris: No significativo
- **Labels:** Top 10 miRNAs más significativos
- **Líneas:** Thresholds de FC y p-value
- **Estadísticas:** t-test o Wilcoxon por miRNA, corrección FDR

---

### **GRUPO B: ANÁLISIS POSICIONAL (3 figuras)**

#### **FIGURA 2.4: HEATMAP VAF POR POSICIÓN (Normal)**
**Pregunta:** Q3 - Patrones posicionales
**Tipo:** Heatmap con clustering jerárquico
**Contenido:**
- Filas: Top 30 miRNAs con mayor diferencia VAF entre grupos
- Columnas: Posiciones 1-22 del miRNA
- **Valores:** VAF promedio por grupo (ALS y Control en paneles separados)
- **Colores:** Escala continua (blanco → rojo oscuro)
- **Clustering:** Jerárquico por similitud de perfil posicional
- **Anotaciones:** Región semilla resaltada (posiciones 2-8)

#### **FIGURA 2.5: HEATMAP VAF Z-SCORE POR POSICIÓN**
**Pregunta:** Q3 - Patrones posicionales normalizados
**Tipo:** Heatmap con Z-score
**Contenido:**
- Filas: Mismos 30 miRNAs de Figura 2.4
- Columnas: Posiciones 1-22
- **Valores:** Z-score del VAF (normalizado por fila)
- **Colores:** Escala divergente (azul ← 0 → rojo)
- **Interpretación:** Destaca posiciones con VAF inusualmente alto/bajo respecto al promedio del miRNA
- **Clustering:** Jerárquico

#### **FIGURA 2.6: PERFILES POSICIONALES VAF (Line Plots + Significancia)**
**Pregunta:** Q3 - Comparación posición por posición
**Tipo:** Line plot con intervalos de confianza + asteriscos
**Contenido:**
- Panel A: VAF promedio de G>T por posición (ALS vs Control)
  - Líneas: ALS (rojo), Control (gris)
  - Áreas sombreadas: Intervalos de confianza 95%
  - Asteriscos: Posiciones con diferencia significativa (Wilcoxon, p < 0.05)
  - Región semilla: Fondo amarillo claro
- Panel B: log2(FC) de VAF G>T por posición
  - Barras: FC positivo (ALS > Control) en rojo, FC negativo en azul
  - Línea horizontal: FC = 0
- Panel C: -log10(p-value) por posición
  - Barras: Significancia por posición
  - Línea horizontal: p = 0.05
- **Estadísticas:** Wilcoxon test por posición, corrección FDR

---

### **GRUPO C: HETEROGENEIDAD Y CLUSTERING (3 figuras)**

#### **FIGURA 2.7: PCA DE MUESTRAS POR PERFIL VAF**
**Pregunta:** Q4 - Heterogeneidad y agrupamiento
**Tipo:** PCA scatter plot
**Contenido:**
- Puntos: Cada muestra (ALS=rojo, Control=gris)
- Ejes: PC1 (X) vs PC2 (Y) con % de varianza explicada
- **Tamaño de punto:** Total VAF G>T de la muestra
- **Elipses:** Intervalos de confianza 95% por grupo
- **Loadings:** Flechas indicando qué miRNAs contribuyen más a cada PC
- **Estadísticas:** PERMANOVA para testar separación de grupos

#### **FIGURA 2.8: HEATMAP DE MUESTRAS CON CLUSTERING JERÁRQUICO**
**Pregunta:** Q4 - Agrupamiento de muestras
**Tipo:** Heatmap + dendrograma
**Contenido:**
- Filas: Todas las muestras (ALS y Control)
- Columnas: Top 50 miRNAs con mayor variabilidad de VAF G>T
- **Valores:** VAF G>T normalizado (Z-score por columna)
- **Colores:** Escala divergente
- **Dendrograma:** Clustering jerárquico (método Ward.D2)
- **Anotación lateral:** Barra de colores indicando grupo (ALS/Control)
- **Objetivo:** Ver si muestras se agrupan por enfermedad o por otros factores

#### **FIGURA 2.9: COEFICIENTE DE VARIACIÓN (CV) POR GRUPO**
**Pregunta:** Q4 - Heterogeneidad intra-grupo
**Tipo:** Barplot + boxplot
**Contenido:**
- Panel A: CV de VAF G>T por miRNA (ALS vs Control)
  - Barras: CV promedio por grupo
  - Test: ¿Es mayor el CV en ALS? (F-test)
- Panel B: Distribución de CV entre miRNAs
  - Boxplot: CV de todos los miRNAs por grupo
- **Interpretación:** CV mayor = más heterogeneidad entre muestras del mismo grupo

---

### **GRUPO D: ESPECIFICIDAD G>T (3 figuras)**

#### **FIGURA 2.10: RATIO G>T / G>A POR GRUPO**
**Pregunta:** Q5 - Especificidad de G>T
**Tipo:** Scatter plot + ratio plot
**Contenido:**
- Panel A: Scatter plot VAF G>T (Y) vs VAF G>A (X) por muestra
  - Puntos: ALS (rojo), Control (gris)
  - Línea diagonal: G>T = G>A (ratio 1:1)
  - Área sombreada: Zona de enriquecimiento G>T (arriba de diagonal)
- Panel B: Boxplot de ratio G>T/G>A (ALS vs Control)
  - Test estadístico: Wilcoxon
- Panel C: Density plot de ratio G>T/G>A
  - Curvas superpuestas (ALS rojo, Control gris)

#### **FIGURA 2.11: HEATMAP DE TIPOS DE MUTACIÓN (ALS vs Control)**
**Pregunta:** Q5 - Perfil completo de mutaciones
**Tipo:** Heatmap comparativo
**Contenido:**
- Filas: Los 12 tipos de mutación (A>C, A>G, ..., T>G)
- Columnas: Posiciones 1-22
- **Paneles:** Lado a lado (ALS | Control)
- **Valores:** VAF promedio por tipo de mutación y posición
- **Colores:** Escala continua, G>T en escala roja diferente
- **Objetivo:** Ver si solo G>T aumenta o también otros tipos

#### **FIGURA 2.12: ENRIQUECIMIENTO G>T POR REGIÓN (Seed vs Non-Seed)**
**Pregunta:** Q3 + Q5 - Especificidad posicional de G>T
**Tipo:** Grouped barplot + heatmap
**Contenido:**
- Panel A: VAF G>T en Seed vs Non-Seed (ALS y Control)
  - Barras agrupadas: 2 grupos (Seed, Non-Seed) x 2 categorías (ALS, Control)
  - Asteriscos: Significancia de diferencias
    - ALS-Seed vs Control-Seed
    - ALS-NonSeed vs Control-NonSeed
    - ALS-Seed vs ALS-NonSeed
- Panel B: Tabla con estadísticas y ratios
  - VAF promedio, SD, p-values
  - Ratio Seed/NonSeed por grupo
- **Estadísticas:** Wilcoxon + corrección Bonferroni

---

## 🧪 TESTS ESTADÍSTICOS A IMPLEMENTAR

### **Comparaciones entre grupos (ALS vs Control):**
1. **Wilcoxon rank-sum test (Mann-Whitney U)** - Comparaciones no paramétricas
2. **t-test (Welch)** - Si las distribuciones son aproximadamente normales
3. **Kolmogorov-Smirnov test** - Comparar distribuciones completas
4. **Cohen's d** - Tamaño del efecto
5. **Odds Ratio** - Para proporciones

### **Ajuste de p-values:**
- **FDR (Benjamini-Hochberg)** - Para comparaciones múltiples (e.g., por miRNA, por posición)
- **Bonferroni** - Para comparaciones planificadas (e.g., Seed vs Non-Seed)

### **Clustering y heterogeneidad:**
- **PERMANOVA** - Testar separación de grupos en PCA
- **Silhouette score** - Evaluar calidad del clustering
- **F-test** - Comparar varianzas entre grupos

### **Correlaciones:**
- **Pearson** - Si distribuciones son normales
- **Spearman** - No paramétrico, más robusto

---

## 🎨 ESTILO Y PALETA DE COLORES

### **Colores principales:**
- **ALS:** `#D62728` (rojo)
- **Control:** `#666666` (gris oscuro)
- **G>T específico:** `#D62728` (rojo)
- **Región Seed:** `#FFE135` (amarillo claro, fondo)
- **Significativo:** `#2ECC71` (verde) o asteriscos
- **No significativo:** `#95A5A6` (gris claro)

### **Escalas de colores:**
- **Heatmaps VAF:** Blanco → Rojo oscuro (`viridis` o `Reds`)
- **Heatmaps Z-score:** Azul ← Blanco → Rojo (`RdBu` o `coolwarm`)
- **p-values:** Gris → Amarillo → Rojo (`YlOrRd`)

### **Tema base:**
```r
theme_professional <- theme_minimal() +
  theme(
    text = element_text(size = 14, family = "Helvetica"),
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray40"),
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 12),
    legend.title = element_text(size = 12, face = "bold"),
    legend.text = element_text(size = 11),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.5),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "gray30", fill = NA, linewidth = 1)
  )
```

---

## 📂 ESTRUCTURA DE DATOS NECESARIA

### **Archivo de metadata (crear si no existe):**
`metadata.csv` con columnas:
- `Sample_ID` - Identificador de muestra (debe coincidir con columnas en dataset)
- `Group` - "ALS" o "Control"
- `Age` - Edad (opcional, para análisis de confounders)
- `Sex` - Sexo (opcional)
- `Batch` - Lote de secuenciación (opcional)

### **Datos procesados actuales:**
- `final_processed_data.csv` - Con columnas de VAF por muestra
- Ya tenemos: `miRNA_name`, `pos.mut`, `Magen_S1`, `Magen_S2`, etc.

### **Necesitamos extraer:**
1. Nombres de todas las columnas de muestras (empiezan con "Magen")
2. Agruparlas en ALS vs Control (basado en metadata)
3. Calcular métricas agregadas (VAF promedio, total, por tipo de mutación, etc.)

---

## 🚀 ORDEN DE IMPLEMENTACIÓN RECOMENDADO

### **FASE 1: PREPARACIÓN (1 script)**
1. Crear/validar metadata
2. Función para cargar y procesar datos con metadata
3. Funciones auxiliares para cálculos estadísticos

### **FASE 2: FIGURAS BÁSICAS (Grupo A - 3 figuras)**
- Más directas, establecen las bases
- Responden Q1 y Q2

### **FASE 3: FIGURAS POSICIONALES (Grupo B - 3 figuras)**
- Requieren análisis por posición
- Responden Q3

### **FASE 4: FIGURAS DE HETEROGENEIDAD (Grupo C - 3 figuras)**
- Más complejas (PCA, clustering)
- Responden Q4

### **FASE 5: FIGURAS DE ESPECIFICIDAD (Grupo D - 3 figuras)**
- Análisis más refinados
- Responden Q5

### **FASE 6: HTML FINAL**
- Combinar todas las figuras
- Incluir interpretaciones y estadísticas

---

## ✅ CHECKLIST ANTES DE EMPEZAR

- [ ] Confirmar estructura de datos actual
- [ ] Decidir cómo asignar muestras a grupos (crear metadata)
- [ ] Acordar figuras prioritarias (¿todas las 12 o empezar con subconjunto?)
- [ ] Confirmar tests estadísticos apropiados
- [ ] Revisar si necesitamos datos adicionales

---

**¿Qué te parece este plan? ¿Modificarías alguna figura o añadirías algo más?**
**¿Empezamos creando el metadata y las funciones base, o prefieres ajustar el plan primero?**

