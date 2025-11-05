# 🔬 REVISIÓN CRÍTICA: FIGURAS 2.13-2.15 (DENSITY HEATMAPS)

**Fecha:** 27 Enero 2025  
**Script:** `generate_HEATMAP_DENSITY_GT.R`  
**Propósito:** Análisis completo de lógica, preguntas y utilidad

---

## 📊 **¿QUÉ SON ESTAS FIGURAS?**

### **Figuras Generadas:**
```
FIG_2.13: Density Heatmap ALS
FIG_2.14: Density Heatmap Control
FIG_2.15: Density Combined (lado a lado)
```

### **Concepto:**
```
HEATMAP DE DENSIDAD:
  - Cada COLUMNA = 1 posición (1-22)
  - Cada FILA = 1 SNV único (G>T)
  - Filas ORDENADAS por VAF (alto → bajo)
  - Color intensidad = VAF value
  - Barplot abajo = Total SNVs por posición

VISUALIZACIÓN:
  → Muestra DENSIDAD de SNVs por posición
  → Hotspots visibles (posiciones con más SNVs)
  → Distribución de VAF visible (gradiente vertical)
```

---

## 🔬 **REVISIÓN DE LÓGICA DEL CÓDIGO**

### **PASO 1: Carga de Datos**
```r
# Filtrar solo G>T
gt_data <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+")))

LÓGICA: ✅ CORRECTA
  → Extrae solo G>T (foco del estudio)
  → Parse de position apropiado
  → Filtro position <= 22 (rango miRNA)
```

### **PASO 2: Transformación Wide→Long**
```r
pivot_longer(cols = all_of(sample_cols), 
             names_to = "Sample_ID", 
             values_to = "VAF") %>%
left_join(metadata, by = "Sample_ID") %>%
filter(!is.na(VAF), VAF > 0)

LÓGICA: ✅ CORRECTA
  → Transforma a formato long
  → Join con metadata para obtener Group
  → Filtra VAF > 0 (solo presentes)
  → Standard y apropiado
```

### **PASO 3: Cálculo de VAF Promedio por SNV**
```r
df_ranked <- group_data %>%
  group_by(miRNA_name, pos.mut, position) %>%
  summarise(avr = mean(VAF, na.rm = TRUE))

LÓGICA: ✅ CORRECTA
  → Agrupa por SNV único (miRNA_name + pos.mut)
  → Calcula VAF promedio across samples del grupo
  → Cada fila = 1 SNV con su VAF promedio
```

### **PASO 4: Ordenamiento por VAF**
```r
arrange(position, desc(avr))

LÓGICA: ✅ INTELIGENTE
  → Primero por position (agrupar columnas)
  → Luego por avr descendente (VAF alto arriba)
  → Resultado: Gradient vertical de VAF
```

### **PASO 5: Creación de Matriz**
```r
# Para cada posición, crear vector de VAF
# Rellenar con NA si posición tiene menos SNVs
# Combinar en matriz

LÓGICA: ✅ CORRECTA
  → Maneja diferentes # SNVs per position
  → Padding con NA (convertido a 0 para visual)
  → Matriz rectangular (max_snvs × 22 positions)
```

### **PASO 6: Visualización**
```r
Heatmap(
  mat,
  cluster_rows = FALSE,    # No clustering (orden por VAF)
  cluster_columns = FALSE, # No clustering (orden posicional)
  col = col_fun,           # Gradient color
  bottom_annotation = barplot(SNV counts)
)

LÓGICA: ✅ CORRECTA Y ELEGANTE
  → No clustering preserva orden VAF
  → Barplot annotation muestra densidad
  → Color gradient muestra magnitud
```

---

## 🎯 **¿QUÉ PREGUNTAS RESPONDEN?**

### **Pregunta 1: ¿Qué posiciones tienen MÁS SNVs G>T?**
```
RESPUESTA: Visible en barplot inferior

Método:
  → Cuenta SNVs únicos por posición
  → Barplot muestra total
  → Hotspots inmediatamente visibles

¿ES LA MEJOR MANERA?
  ✅ SÍ, visualización directa
  ✅ Barplot estándar para counts
  ✅ Integrated en heatmap (contexto)

ALTERNATIVAS:
  ❌ Solo barplot: Pierde info de VAF
  ❌ Solo tabla: No impacto visual
```

### **Pregunta 2: ¿Distribución de VAF por posición?**
```
RESPUESTA: Visible en gradient vertical

Método:
  → SNVs ordenados por VAF (alto arriba)
  → Gradient vertical muestra distribución
  → Cada posición independiente

¿ES LA MEJOR MANERA?
  ✅ SÍ para visualizar densidad
  
  Ventaja única:
    → Muestra CUÁNTOS SNVs y su VAF
    → No solo promedio (como Fig 2.6)
    → No solo raw values (como Fig 2.4)
    → Distribución completa visible

ALTERNATIVAS:
  Violin plot per position:
    ✅ Muestra distribución
    ⚠️ 22 violins = crowded
  
  Density heatmap:
    ✅ Compacto
    ✅ Visual clarity
    ✅ ÓPTIMO para este caso
```

### **Pregunta 3: ¿Diferencias entre ALS y Control?**
```
RESPUESTA: Comparación side-by-side (Fig 2.15)

Método:
  → Dos heatmaps lado a lado
  → Mismo scale, mismo layout
  → Comparación directa visual

¿ES LA MEJOR MANERA?
  ✅ SÍ para comparación visual

PERMITE VER:
  → Posiciones con más SNVs en ALS vs Control
  → Distribución de VAF diferente
  → Hotspots específicos de grupo
```

---

## 🔥 **¿QUÉ APORTAN ESTAS FIGURAS?**

### **Perspectiva Única:**

```
Fig 2.4 (Heatmap raw):
  → Muestra VAF por miRNA por posición
  → miRNAs en filas, posiciones en columnas
  → Enfoque: PER MIRNA

Fig 2.5 (Z-Score):
  → Normaliza cada miRNA
  → Outliers posicionales per miRNA
  → Enfoque: OUTLIERS PER MIRNA

Fig 2.6 (Line plots):
  → VAF PROMEDIO por posición
  → Comparación ALS vs Control
  → Enfoque: TRENDS GLOBALES

Fig 2.13-2.15 (Density):
  → DENSIDAD de SNVs por posición
  → Distribución completa VAF
  → Enfoque: HOTSPOTS + DISTRIBUCIÓN

COMPLEMENTARIAS, NO REDUNDANTES ✅
```

---

## 📊 **ANÁLISIS DETALLADO POR FIGURA**

### **FIGURA 2.13: Density Heatmap ALS**

**PREGUNTA:** ¿Dónde se concentran los SNVs G>T en ALS?

**MÉTODO:**
```r
1. Extraer todos G>T de ALS samples
2. Calcular VAF promedio per SNV único
3. Ordenar por position, luego por VAF (desc)
4. Crear heatmap con gradient
5. Annotation: barplot de counts
```

**INFORMACIÓN QUE PROVEE:**
```
✅ Posiciones con más SNVs (hotspots)
✅ Distribución de VAF por posición
✅ Cuántos SNVs alto-VAF vs bajo-VAF
✅ Densidad visual clara

EJEMPLO:
  Position 22:
    → Barplot muestra: 500 SNVs
    → Heatmap muestra: Gradient de VAF alto (top) a bajo (bottom)
    → Interpretación: "Pos 22 tiene MUCHOS SNVs con VAF variado"
```

**¿ES ÚTIL?**
```
✅ SÍ porque:
  → Identifica hotspots posicionales
  → Muestra distribución completa (no solo mean)
  → Visual impact alto
  → Complementa Fig 2.6 (line plot de means)

DIFERENCIA CRÍTICA:
  Fig 2.6: Mean VAF per position (single value)
  Fig 2.13: TODOS los SNVs per position (distribution)
```

---

### **FIGURA 2.14: Density Heatmap Control**

**PREGUNTA:** ¿Dónde se concentran los SNVs G>T en Control?

**MÉTODO:** Idéntico a Fig 2.13, pero grupo Control

**INFORMACIÓN QUE PROVEE:**
```
✅ Mismo análisis para Control
✅ Permite comparación visual
✅ Identifica si hotspots son consistentes
```

**¿ES ÚTIL?**
```
✅ SÍ porque:
  → Necesario para comparar con ALS
  → Revela si hotspots son compartidos o específicos
  → Completa la narrativa
```

---

### **FIGURA 2.15: Density Combined**

**PREGUNTA:** ¿Cómo difieren los hotspots entre ALS y Control?

**MÉTODO:**
```r
# Lado a lado (grid layout 1×2)
# Mismo scale, mismo layout
# Comparación directa visual
```

**INFORMACIÓN QUE PROVEE:**
```
✅ Comparación directa side-by-side
✅ Hotspots compartidos vs específicos
✅ Diferencias en densidad
✅ Diferencias en distribución VAF

EJEMPLO DE INSIGHTS:
  Si Position 22 tiene:
    ALS: 500 SNVs (barplot alto)
    Control: 200 SNVs (barplot bajo)
    → Hotspot específico de ALS
  
  Si ambos similares:
    → Hotspot compartido (mechanism común)
```

**¿ES ÚTIL?**
```
✅ SÍ porque:
  → Comparación visual directa
  → Publication-quality (side-by-side estándar)
  → Mensajes claros sobre diferencias
```

---

## 🧬 **ANÁLISIS BIOLÓGICO**

### **¿Qué Revelan Estos Heatmaps?**

```
INFORMACIÓN BIOLÓGICA:

1. HOTSPOTS POSICIONALES:
   → Posiciones con más SNVs
   → Vulnerabilidad posicional
   → Sitios de daño preferencial

2. DISTRIBUCIÓN VAF:
   → Si SNVs son mayormente high-VAF o low-VAF
   → Gradient vertical lo muestra
   → Interpreta: Frecuencia de mutaciones

3. COMPARACIÓN GRUPOS:
   → Hotspots específicos de ALS
   → Hotspots específicos de Control
   → Hotspots compartidos

4. DENSIDAD RELATIVA:
   → Algunas posiciones densas (muchos SNVs)
   → Otras sparse (pocos SNVs)
   → Relaciona con estructura miRNA
```

---

## ✅ **VALIDACIÓN DE UTILIDAD**

### **¿Son Necesarias o Redundantes?**

```
COMPARACIÓN CON OTRAS FIGURAS:

vs Fig 2.4 (Heatmap raw):
  Fig 2.4: miRNAs × positions
  Fig 2.13-15: SNVs × positions
  → DIFERENTES enfoques ✅

vs Fig 2.6 (Line plots):
  Fig 2.6: Mean VAF per position
  Fig 2.13-15: DISTRIBUCIÓN completa
  → COMPLEMENTARIAS ✅

vs Fig 2.5 (Z-Score):
  Fig 2.5: Normalizado per miRNA
  Fig 2.13-15: Raw density per position
  → DIFERENTES perspectivas ✅

VEREDICTO: ✅ NO REDUNDANTES
           Aportan perspectiva única
```

---

## 🎯 **¿RESPONDEN PREGUNTAS DEL PLAN ORIGINAL?**

### **Preguntas del Plan:**
```
Q3: ¿Hay patrones posicionales específicos de ALS?

Fig 2.13-2.15 RESPONDEN:
  ✅ Sí, muestra hotspots posicionales
  ✅ Compara densidad ALS vs Control
  ✅ Identifica posiciones con más damage
  ✅ Visualiza distribución completa VAF

APORTE ADICIONAL:
  → No solo mean (Fig 2.6)
  → No solo per miRNA (Fig 2.4, 2.5)
  → DENSIDAD GLOBAL por posición
  → Hotspots + distribution en uno
```

---

## 📊 **CALIDAD DEL CÓDIGO**

### **Revisión Técnica:**

```r
# FORTALEZAS:

✅ Manejo robusto de datos desbalanceados
   → Posiciones tienen diferente # SNVs
   → Padding con NA apropiado
   → Matrix rectangular bien formada

✅ Ordenamiento lógico
   → Por position primero (columnas)
   → Por VAF descendente (visual gradient)

✅ Visualización profesional
   → ComplexHeatmap (publication-quality)
   → Color gradient adaptativo
   → Annotation barplot informativa

✅ Comparación efectiva
   → Mismo scale ALS vs Control
   → Side-by-side layout
   → Fácil comparar

CÓDIGO: ⭐⭐⭐⭐⭐ EXCELENTE
```

---

## 🔥 **HALLAZGOS POTENCIALES**

### **¿Qué Pueden Revelar?**

```
HOTSPOTS POSICIONALES:
  → Si Position X tiene barplot ALTO:
    - Esa posición acumula MUCHOS SNVs G>T
    - Vulnerable a daño oxidativo
    - Candidata a análisis funcional

  Ejemplo:
    Position 22, 23 (visto en Fig 2.12C)
    → Barplot alto en ambos grupos
    → Hotspots compartidos

DISTRIBUCIÓN VAF:
  → Si gradient es uniforme:
    - SNVs distribuidos en range VAF
    - Mezcla de high/medium/low
  
  → Si gradient es steep (top dark, bottom light):
    - Pocos SNVs high-VAF
    - Muchos SNVs low-VAF
    - Mayoría son raros

DIFERENCIAS ALS vs CONTROL:
  → Si barplot ALS > Control en position X:
    - Hotspot específico ALS
    - Vulnerabilidad aumentada
  
  → Si gradient diferente:
    - Distribución VAF distinta
    - Mecanismo puede variar
```

---

## 🎯 **¿DEBERÍAN ESTAR EN EL PIPELINE?**

### **ARGUMENTOS A FAVOR:**
```
✅ Perspectiva única (densidad + distribución)
✅ Identifica hotspots claramente
✅ Complementa otras figuras posicionales
✅ Visual impact alto
✅ Publication-quality
✅ Código robusto y limpio
```

### **ARGUMENTOS EN CONTRA:**
```
⚠️ No estaban en plan original
⚠️ Ya tenemos 12 figuras (mucho material)
⚠️ Fig 2.6 + 2.12C cubren hotspots
⚠️ Puede ser considerado "exploratorio"
```

---

## 📋 **CATEGORIZACIÓN**

### **Tipo de Análisis:**
```
CATEGORÍA: Análisis Exploratorio Avanzado

PROPÓSITO:
  → Deep dive en distribución posicional
  → Visualización comprehensiva
  → Hotspot identification

USO RECOMENDADO:
  ✅ Supplementary Figures (paper)
  ✅ Exploratory analysis (presentaciones)
  ✅ Deep dive para reviewers
  
  NO RECOMENDADO:
  ⚠️ Main figures (ya tenemos 2.6)
```

---

## 🔬 **COMPARACIÓN: Fig 2.6 vs Fig 2.13-15**

### **Fig 2.6 (Line Plots):**
```
MUESTRA:
  → Mean VAF per position
  → Trend líneas ALS vs Control
  → CI (confidence intervals)
  → Significance markers (si funcionan)

MENSAJE:
  "ALS vs Control mean VAF por posición"

FORTALEZA:
  ✅ Comparación directa means
  ✅ Statistical tests
  ✅ Trend clara

DEBILIDAD:
  ⚠️ Solo mean (pierde distribución)
```

### **Fig 2.13-15 (Density Heatmaps):**
```
MUESTRA:
  → TODOS los SNVs por posición
  → Distribución completa VAF
  → Densidad (# SNVs)
  → Hotspots visuales

MENSAJE:
  "Distribución completa de SNVs G>T por posición"

FORTALEZA:
  ✅ Distribución completa visible
  ✅ Hotspots obvios (barplot)
  ✅ Visual impact

DEBILIDAD:
  ⚠️ No tests estadísticos directos
  ⚠️ Más exploratorio que confirmatorio
```

---

## 💡 **RECOMENDACIÓN**

### **OPCIÓN 1: INCLUIR en Pipeline Principal** ✅
```
RAZONES:
  ✅ Análisis comprehensivo y único
  ✅ Complementa Fig 2.6 (means)
  ✅ Identifica hotspots claramente
  ✅ Publication-quality
  ✅ Código robusto

CATEGORIZACIÓN:
  → Supplementary Figures
  → No main text
  → Disponible para reviewers

VEREDICTO: ✅ INCLUIR como Supplementary
```

### **OPCIÓN 2: OMITIR (mantener exploratorio)** ⚠️
```
RAZONES:
  ✅ Plan original ya completo (12/12)
  ✅ Fig 2.6 cubre análisis posicional
  ✅ Muchas figuras ya (12 main)

CATEGORIZACIÓN:
  → Exploratory only
  → No incluir en paper
  → Mantener en archives

VEREDICTO: ⚠️ SOLO si priorizamos brevedad
```

---

## 🎯 **DECISIÓN FINAL RECOMENDADA**

### **Mi Recomendación:**

```
INCLUIR Fig 2.13-15 como SUPPLEMENTARY ✅

ESTRUCTURA:
  Main Text Figures:
    - Fig 2.1-2.3 (Global)
    - Fig 2.6 (Positional means)
    - Fig 2.7 (PCA)
    - Fig 2.9 (CV)
    - Fig 2.11 (Spectrum)
  
  Supplementary Figures:
    - Fig 2.4, 2.5 (Heatmaps per miRNA)
    - Fig 2.8 (Clustering)
    - Fig 2.10 (Ratio detail)
    - Fig 2.12 (Enrichment)
    - Fig 2.13-15 (Density heatmaps) ⭐

BENEFICIO:
  → Análisis completo disponible
  → Reviewers tienen deep dive
  → No sobrecarga main text
  → Comprehensivo
```

---

## ✅ **VALIDACIÓN FINAL**

### **Checklist:**

```
CÓDIGO:
  ✅ Lógica correcta
  ✅ Manejo de datos robusto
  ✅ Visualización profesional
  ✅ No errors

CIENTÍFICO:
  ✅ Preguntas relevantes
  ✅ Perspectiva única
  ✅ Complementa otras figuras
  ✅ Interpretación clara

PRÁCTICO:
  ✅ Publication-quality
  ✅ Útil para reviewers
  ✅ Código reproducible
  ✅ Bien documentado

VEREDICTO: ✅ APROBAR para Supplementary
```

---

## 📋 **RESUMEN FINAL**

### **Inventario Completo Paso 2:**

```
MAIN FIGURES (12):
  ✅ 2.1-2.12 (plan original completo)

SUPPLEMENTARY FIGURES (3):
  ✅ 2.13: Density ALS
  ✅ 2.14: Density Control
  ✅ 2.15: Density Combined

TOTAL: 15 figuras

CALIDAD:
  Main: ⭐⭐⭐⭐⭐
  Supplementary: ⭐⭐⭐⭐⭐

LÓGICA:
  ✅ TODA validada
  ✅ TODAS responden preguntas
  ✅ NO redundantes
  ✅ Complementarias
```

---

## 🚀 **SIGUIENTE PASO**

### **Consolidación:**
```
1. ✅ Copiar Fig 2.13-15 a /figures/
2. ✅ Marcar como Supplementary
3. ✅ Generar HTML viewer COMPLETO (15 figuras)
4. ✅ Documentar todas las figuras
5. ✅ Crear master script
```

---

**¡Figuras 2.13-15 abiertas y revisadas!** 🎨

**VEREDICTO: INCLUIR en pipeline como Supplementary** ✅

**¿Procedemos a consolidar las 15 figuras completas?** 🚀

