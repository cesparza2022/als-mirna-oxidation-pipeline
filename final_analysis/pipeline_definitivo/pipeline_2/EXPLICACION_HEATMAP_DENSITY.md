# 📊 EXPLICACIÓN DETALLADA: HEATMAP DE DENSIDAD G>T

**Fecha:** 2025-10-17 02:50
**Propósito:** Explicar el proceso paso a paso

---

## 🎯 QUÉ MUESTRA LA GRÁFICA

### **Visualmente:**
- **Columnas** = Posiciones del miRNA (1, 2, 3, ..., 22)
- **Filas** = SNVs individuales (cada uno es un miRNA:posición:GT único)
- **Color** = Intensidad del VAF promedio de ese SNV
- **Barplot inferior** = Total de SNVs en esa posición

### **Concepto:**
Imagina que **apilamos todos los SNVs** que ocurren en cada posición, ordenados de mayor a menor VAF. Las posiciones con **más SNVs** tienen columnas más "altas", y los SNVs con **mayor VAF** están en la parte superior (color más intenso).

---

## 🔬 PROCESO PASO A PASO

### **EJEMPLO CON DATOS REALES:**

Supongamos que tenemos estos SNVs G>T en **Control**:

```
miRNA_name       pos.mut    Sample_1  Sample_2  Sample_3  ... Sample_102
hsa-miR-378g     6:GT       0.02      0.05      0.01      ... 0.03
hsa-miR-378g     10:GT      0.01      0.02      0.00      ... 0.01
hsa-let-7a       6:GT       0.10      0.12      0.08      ... 0.11
hsa-miR-21       6:GT       0.03      0.04      0.02      ... 0.03
hsa-miR-21       15:GT      0.05      0.06      0.04      ... 0.05
```

---

### **PASO 1: CALCULAR VAF PROMEDIO POR SNV**

Para cada SNV único (miRNA:posición), calculamos el **promedio** de VAF entre todas las muestras:

```r
# Convertir a formato largo
gt_data <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%
  pivot_longer(cols = sample_cols, names_to = "Sample_ID", values_to = "VAF") %>%
  filter(!is.na(VAF), VAF > 0)

# Calcular promedio por SNV
df_ranked <- gt_data %>%
  group_by(miRNA_name, pos.mut, position) %>%
  summarise(avr = mean(VAF, na.rm = TRUE), .groups = "drop")
```

**Resultado:**
```
miRNA_name       pos.mut    position   avr (VAF promedio)
hsa-miR-378g     6:GT       6          0.0275  ← promedio de 102 muestras
hsa-miR-378g     10:GT      10         0.0100
hsa-let-7a       6:GT       6          0.1025  ← VAF MÁS ALTO
hsa-miR-21       6:GT       6          0.0300
hsa-miR-21       15:GT      15         0.0500
```

Ahora tenemos **1 valor por SNV** (en Control: 1,237 SNVs únicos).

---

### **PASO 2: AGRUPAR POR POSICIÓN**

Separamos los SNVs por posición:

```r
positions <- sort(unique(df_ranked$position))

for (p in positions) {
  snvs_for_pos <- df_ranked %>%
    filter(position == p) %>%
    arrange(desc(avr)) %>%  # ORDENAR DE MAYOR A MENOR VAF
    pull(avr)
}
```

**Ejemplo para POSICIÓN 6:**
```
Posición 6 tiene 3 SNVs:
  1. hsa-let-7a 6:GT     → VAF = 0.1025  (el MÁS ALTO)
  2. hsa-miR-21 6:GT     → VAF = 0.0300
  3. hsa-miR-378g 6:GT   → VAF = 0.0275  (el más bajo)

Ordenados de mayor a menor: [0.1025, 0.0300, 0.0275]
```

**Ejemplo para POSICIÓN 10:**
```
Posición 10 tiene 1 SNV:
  1. hsa-miR-378g 10:GT  → VAF = 0.0100

Ordenados: [0.0100]
```

**Ejemplo para POSICIÓN 15:**
```
Posición 15 tiene 1 SNV:
  1. hsa-miR-21 15:GT    → VAF = 0.0500

Ordenados: [0.0500]
```

---

### **PASO 3: IGUALAR NÚMERO DE FILAS**

**Problema:** Cada posición tiene diferente número de SNVs (posición 6 tiene 3, posición 10 tiene 1).

**Solución:** Rellenar con `NA` para que todas tengan el **mismo número de filas** (el máximo).

```r
# Encontrar el máximo
df_summary <- df_ranked %>%
  group_by(position) %>%
  summarise(total_snvs = n())

max_snvs <- max(df_summary$total_snvs)  # Ejemplo: 133 en ALS
```

**Ejemplo (si max = 3):**
```
Posición 6: [0.1025, 0.0300, 0.0275]  ← Ya tiene 3, OK
Posición 10: [0.0100, NA, NA]         ← Rellenamos con NA
Posición 15: [0.0500, NA, NA]         ← Rellenamos con NA
```

---

### **PASO 4: CREAR MATRIZ**

Cada columna = 1 posición, cada fila = 1 "slot" de SNV:

```r
matrix_list <- list()

for (p in positions) {
  snvs_for_pos <- df_ranked %>%
    filter(position == p) %>%
    arrange(desc(avr)) %>%
    pull(avr)
  
  n <- length(snvs_for_pos)
  if (n < max_snvs) {
    snvs_for_pos <- c(snvs_for_pos, rep(NA, max_snvs - n))
  }
  
  mat_col <- matrix(snvs_for_pos, ncol = 1)
  colnames(mat_col) <- as.character(p)
  matrix_list[[as.character(p)]] <- mat_col
}

# Combinar todas las columnas
mat <- do.call(cbind, matrix_list)
```

**Resultado (matriz simplificada):**
```
           Pos_6   Pos_10  Pos_15  ...
Fila 1    0.1025  0.0100  0.0500  ← SNVs con VAF más alto
Fila 2    0.0300  NA      NA
Fila 3    0.0275  NA      NA
```

En realidad, con nuestros datos:
```
           Pos_1   Pos_2   Pos_3   ...  Pos_22
Fila 1    X.XXX   X.XXX   X.XXX   ...  X.XXX   ← SNVs con VAF más alto
Fila 2    X.XXX   X.XXX   X.XXX   ...  NA
...
Fila 133  X.XXX   NA      NA      ...  NA      ← Máximo de SNVs en una posición
```

---

### **PASO 5: VISUALIZAR**

Convertimos los valores a colores y añadimos el barplot:

```r
# Convertir NA a 0 para visualización
mat[is.na(mat)] <- 0

# Escala de colores (de blanco a rojo)
col_fun <- colorRamp2(
  c(0, max_vaf * 0.25, max_vaf * 0.5, max_vaf * 0.75, max_vaf),
  c("#FFFFFF", "#FFCCCC", "#FF9999", "#FF6666", "#CC0000")
)

# Heatmap
Heatmap(
  mat,
  col = col_fun,
  cluster_rows = FALSE,    # NO ordenar filas (ya están por VAF)
  cluster_columns = FALSE, # NO ordenar columnas (ya están por posición)
  show_row_names = FALSE,  # Demasiadas filas para etiquetar
  bottom_annotation = HeatmapAnnotation(
    "SNV Count" = anno_barplot(df_summary$total_snvs)
  )
)
```

---

## 📊 QUÉ REPRESENTA CADA ELEMENTO

### **1. Cada COLUMNA (posición):**
- Ancho = igual para todas
- Altura visual = total de SNVs (del barplot)
- Ejemplo: Posición 6 tiene 50 SNVs → barra de 50

### **2. Cada FILA (slot de SNV):**
- Fila 1 = SNV con **mayor VAF** de esa posición
- Fila 2 = SNV con **segundo mayor VAF**
- ...
- Fila 133 = SNV con **menor VAF** (o NA si no hay)

### **3. Cada CELDA (color):**
- **Blanco** = VAF = 0 o NA (no hay SNV)
- **Rosa claro** = VAF bajo (~0.01)
- **Rojo medio** = VAF medio (~0.1)
- **Rojo oscuro** = VAF alto (~0.3+)

### **4. BARPLOT inferior:**
- Altura = **número total de SNVs** en esa posición
- Ejemplo: Si posición 6 tiene barra de altura 50 → hay 50 SNVs diferentes con G>T en posición 6

---

## 💡 INTERPRETACIÓN

### **Columna ALTA + Color INTENSO:**
→ Esa posición tiene **muchos SNVs con VAF alto**
→ **Hotspot** de mutaciones G>T

### **Columna ALTA + Color SUAVE:**
→ Esa posición tiene **muchos SNVs pero con VAF bajo**
→ Muchas mutaciones raras

### **Columna BAJA + Color INTENSO:**
→ Esa posición tiene **pocos SNVs pero con VAF alto**
→ Mutaciones específicas frecuentes

### **Diferencia ALS vs Control:**
- Si **ALS tiene columnas más altas** → más SNVs en esa posición
- Si **ALS tiene colores más intensos** → VAF más alto
- Si **Control > ALS** → se ve en ambos gráficos

---

## 🔍 EJEMPLO REAL CON NUESTROS DATOS

### **Para ALS:**
```
Total SNVs únicos: 1,774
Posiciones con G>T: 22
Máximo en una posición: 133 SNVs

Matriz resultante: 133 filas × 22 columnas
```

**¿Qué significa "133 SNVs en una posición"?**

Ejemplo si la posición 6 tiene 133 SNVs:
```
SNV 1:  hsa-miR-XXX 6:GT  → VAF = 0.35
SNV 2:  hsa-miR-YYY 6:GT  → VAF = 0.28
SNV 3:  hsa-miR-ZZZ 6:GT  → VAF = 0.21
...
SNV 133: hsa-miR-AAA 6:GT  → VAF = 0.001
```

Todos estos **133 miRNAs diferentes** tienen una mutación G>T en la posición 6.

---

## 🎨 COMPARACIÓN CON OTRAS FIGURAS

### **vs Heatmap Posicional (Fig 2.4):**
**Fig 2.4:**
- Filas = miRNAs (top 50)
- Columnas = posiciones
- Celda = VAF **promedio** de ese miRNA en esa posición
- **Enfoque:** ¿Qué miRNAs tienen G>T en qué posiciones?

**Fig 2.13-2.15 (Densidad):**
- Filas = SNVs individuales (ordenados por VAF)
- Columnas = posiciones
- Celda = VAF de ese **SNV específico**
- **Enfoque:** ¿Cuántos SNVs hay en cada posición y qué tan intensos son?

### **vs Perfiles Posicionales (Fig 2.6):**
**Fig 2.6:**
- Line plot: posición vs VAF promedio
- **Enfoque:** Tendencia general de VAF por posición

**Fig 2.13-2.15:**
- Heatmap: muestra **distribución completa** de intensidades
- **Enfoque:** No solo el promedio, sino toda la distribución

---

## 📊 VENTAJAS DE ESTA VISUALIZACIÓN

### **1. Muestra TODO el espectro:**
- No solo top miRNAs
- No solo promedios
- **Toda la distribución** de VAF en cada posición

### **2. Revela Hotspots:**
- Posiciones con **muchos SNVs** (columna alta en barplot)
- Posiciones con **SNVs intensos** (colores rojos en la parte superior)

### **3. Comparación Visual:**
- ALS vs Control lado a lado
- Fácil ver diferencias de densidad

### **4. Detecta Patrones:**
- ¿Hay posiciones con **concentración de SNVs intensos**?
- ¿Seed region (2-8) tiene más densidad?
- ¿ALS tiene distribución diferente a Control?

---

## 🔢 EJEMPLO NUMÉRICO COMPLETO

### **Datos de entrada (simplificado):**

```
# Control tiene estos SNVs G>T:

miRNA           pos.mut   Muestra_1  Muestra_2  Muestra_3
miR-A           6:GT      0.05       0.07       0.06
miR-B           6:GT      0.10       0.12       0.11
miR-C           6:GT      0.02       0.01       0.03
miR-D           10:GT     0.08       0.09       0.07
miR-E           10:GT     0.04       0.05       0.03
```

---

### **PASO 1: Calcular promedio por SNV**

```r
# Posición 6:
miR-A 6:GT  → mean(0.05, 0.07, 0.06) = 0.060
miR-B 6:GT  → mean(0.10, 0.12, 0.11) = 0.110  ← MÁS ALTO
miR-C 6:GT  → mean(0.02, 0.01, 0.03) = 0.020

# Posición 10:
miR-D 10:GT → mean(0.08, 0.09, 0.07) = 0.080
miR-E 10:GT → mean(0.04, 0.05, 0.03) = 0.040
```

**Resultado:**
```
miRNA    pos.mut   position   avr
miR-A    6:GT      6          0.060
miR-B    6:GT      6          0.110
miR-C    6:GT      6          0.020
miR-D    10:GT     10         0.080
miR-E    10:GT     10         0.040
```

---

### **PASO 2: Ordenar por posición y VAF**

```r
# Posición 6 (ordenar descendente por avr):
1. miR-B 6:GT → 0.110
2. miR-A 6:GT → 0.060
3. miR-C 6:GT → 0.020

# Posición 10 (ordenar descendente por avr):
1. miR-D 10:GT → 0.080
2. miR-E 10:GT → 0.040
```

---

### **PASO 3: Crear matriz (igualar filas)**

Máximo de SNVs en una posición = 3 (posición 6)

```r
# Posición 6 (tiene 3):
[0.110]   ← Fila 1
[0.060]   ← Fila 2
[0.020]   ← Fila 3

# Posición 10 (tiene 2, rellenar con NA):
[0.080]   ← Fila 1
[0.040]   ← Fila 2
[NA]      ← Fila 3 (rellenada)
```

**Matriz final:**
```
           Col_6   Col_10
Fila 1    0.110   0.080   ← SNVs con VAF más alto
Fila 2    0.060   0.040
Fila 3    0.020   0.000   ← (NA convertido a 0)
```

---

### **PASO 4: Añadir Barplot**

Contar total de SNVs por posición:

```r
df_summary <- df_ranked %>%
  group_by(position) %>%
  summarise(total_snvs = n())
```

**Resultado:**
```
position   total_snvs
6          3           ← Barra de altura 3
10         2           ← Barra de altura 2
```

---

### **PASO 5: Visualizar con ComplexHeatmap**

```r
Heatmap(
  mat,                          # Matriz 3×2
  col = col_fun,                # Escala blanco→rojo
  cluster_rows = FALSE,         # Mantener orden por VAF
  cluster_columns = FALSE,      # Mantener orden por posición
  bottom_annotation = HeatmapAnnotation(
    "SNV Count" = anno_barplot(
      df_summary$total_snvs     # [3, 2]
    )
  )
)
```

**Resultado visual:**
```
┌─────────┬─────────┐
│ Rojo    │ Rojo    │ ← Fila 1 (VAF alto)
│ oscuro  │ medio   │
├─────────┼─────────┤
│ Rojo    │ Rosa    │ ← Fila 2 (VAF medio)
│ medio   │         │
├─────────┼─────────┤
│ Rosa    │ Blanco  │ ← Fila 3 (VAF bajo/NA)
│         │         │
├─────────┴─────────┤
│    ▓▓▓      ▓▓    │ ← Barplot (altura = # SNVs)
│    3        2     │
└───────────────────┘
  Pos 6    Pos 10
```

---

## 🎯 EN NUESTROS DATOS REALES

### **ALS:**
```
1,774 SNVs únicos
22 posiciones
Max 133 SNVs en una posición

Matriz: 133 filas × 22 columnas
```

**Interpretación:**
- **Fila 1 (top):** Los 22 SNVs con **mayor VAF** de cada posición
- **Fila 133 (bottom):** Los SNVs con **menor VAF** (o 0 si no hay)
- **Barplot:** Altura máxima = 133 en alguna posición

### **Control:**
```
1,237 SNVs únicos
20 posiciones (no tiene SNVs en 2 posiciones)
Max 122 SNVs en una posición

Matriz: 122 filas × 20 columnas
```

---

## 💡 QUÉ PREGUNTAS RESPONDE

### **1. ¿Qué posiciones tienen más SNVs G>T?**
→ Ver el **barplot inferior** (columnas más altas)

### **2. ¿Qué posiciones tienen SNVs con VAF más alto?**
→ Ver la **parte superior del heatmap** (filas 1-10, colores rojos)

### **3. ¿La seed region (2-8) tiene más SNVs?**
→ Comparar altura del barplot en columnas 2-8 vs resto

### **4. ¿Hay diferencia ALS vs Control?**
→ Comparar:
- **Altura de barplots** (más SNVs en ALS o Control?)
- **Intensidad de colores** (VAF más alto en ALS o Control?)
- **Distribución** (ALS más concentrado en seed?)

### **5. ¿Hay hotspots específicos?**
→ Buscar columnas con:
- Barplot muy alto
- Colores rojos intensos en las primeras filas

---

## 🔬 DIFERENCIA CON TU CÓDIGO ORIGINAL

### **Tu código (Control data):**
```r
# Usaba "avr" directamente de df_ranked
# No especificaba cómo calcular "avr"
# Asumía datos ya procesados
```

### **Nuestro código (ALS vs Control):**
```r
# 1. Carga datos crudos (VAF por muestra)
# 2. Pivotea a formato largo
# 3. Calcula mean(VAF) por SNV único
# 4. Separa por grupo (ALS/Control)
# 5. Crea heatmap por grupo
# 6. Combina ALS y Control lado a lado
```

**Ventaja:** Generamos **2 heatmaps** (ALS y Control) para comparación directa.

---

## 📊 RESUMEN VISUAL

```
DATOS CRUDOS
   ↓
Calcular VAF promedio por SNV (1 valor por miRNA:posición:GT)
   ↓
Agrupar por posición
   ↓
Ordenar por VAF (descendente)
   ↓
Rellenar con NA para igualar filas
   ↓
Crear matriz (filas = SNVs, columnas = posiciones)
   ↓
Visualizar con ComplexHeatmap + Barplot
   ↓
HEATMAP DE DENSIDAD
```

---

## 🎯 INTERPRETACIÓN DE NUESTRAS FIGURAS

### **Si en FIG 2.15 vemos:**

**Posición 6 con barplot alto en ALS:**
→ Muchos miRNAs diferentes tienen G>T en posición 6 en ALS

**Posición 6 con colores rojos arriba en Control:**
→ Los SNVs en posición 6 en Control tienen VAF más alto

**Seed region (2-8) con más densidad:**
→ Confirma que G>T se concentra en seed

**ALS y Control similares:**
→ El patrón posicional de G>T es similar entre grupos

---

**Documentado:** 2025-10-17 02:50
**Script:** `generate_HEATMAP_DENSITY_GT.R`
**Figuras:** FIG_2.13, FIG_2.14, FIG_2.15
**Método:** Inspirado en análisis de densidad posicional

