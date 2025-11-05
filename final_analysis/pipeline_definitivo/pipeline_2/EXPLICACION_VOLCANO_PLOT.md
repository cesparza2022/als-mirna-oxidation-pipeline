# 📊 EXPLICACIÓN: CÓMO SE GENERA EL VOLCANO PLOT

---

## 🎯 OBJETIVO DEL VOLCANO PLOT

Identificar **qué miRNAs tienen diferencias significativas en G>T VAF** entre ALS y Control.

**Ejes:**
- **Eje X:** log2(Fold Change) = log2(VAF_ALS / VAF_Control)
- **Eje Y:** -log10(p-value ajustado por FDR)

---

## 📝 LÓGICA PASO A PASO

### **PASO 1: SELECCIÓN DE miRNAs**

```r
# Solo miRNAs con G>T en región SEED (posiciones 2-8)
all_seed_gt_mirnas  # 301 miRNAs
```

**Por qué:** Enfocarnos en miRNAs funcionalmente relevantes.

---

### **PASO 2: PARA CADA miRNA**

Para cada uno de los 301 miRNAs, hago lo siguiente:

#### **2.1. Extraer valores VAF por grupo:**

```r
for (mirna in all_seed_gt_mirnas) {
  mirna_data <- vaf_gt_all %>% filter(miRNA_name == mirna)
  
  # Valores de ALS
  als_vals <- mirna_data %>% 
    filter(Group == "ALS") %>% 
    pull(VAF) %>% 
    na.omit()
  
  # Valores de Control
  ctrl_vals <- mirna_data %>% 
    filter(Group == "Control") %>% 
    pull(VAF) %>% 
    na.omit()
```

**Qué estoy extrayendo:**
- Todos los valores VAF de **TODAS las posiciones con G>T** de ese miRNA (no solo seed)
- Por grupo (ALS o Control)
- Removiendo NAs

**Ejemplo para hsa-miR-6129:**
- ALS: 313 muestras × N posiciones con G>T = vector de ~1000+ valores VAF
- Control: 102 muestras × N posiciones con G>T = vector de ~300+ valores VAF

---

#### **2.2. Verificar suficientes datos:**

```r
if (length(als_vals) > 5 && length(ctrl_vals) > 5) {
```

**Por qué:** Necesitamos al menos 5 observaciones por grupo para un test estadístico robusto.

**Si NO hay suficientes datos:** Ese miRNA se SALTA (no aparece en el volcano plot).

---

#### **2.3. Calcular medias por grupo:**

```r
mean_als <- mean(als_vals, na.rm = TRUE) + 0.001
mean_ctrl <- mean(ctrl_vals, na.rm = TRUE) + 0.001
```

**¿Qué son estos valores?**
- **mean_als:** VAF promedio de G>T en ALS para este miRNA
- **mean_ctrl:** VAF promedio de G>T en Control para este miRNA

**Ejemplo hsa-miR-378g (NUEVO #2):**
- `mean_als` = 0.0158
- `mean_ctrl` = 0.0150 (aproximado)

**¿Por qué +0.001?**
Para evitar `log2(0)` que daría `-Inf`. Es un pseudocount.

---

#### **2.4. Calcular Fold Change (FC):**

```r
fc <- log2(mean_als / mean_ctrl)
```

**Interpretación:**
- **FC > 0:** ALS tiene MAYOR VAF que Control (enriquecido en ALS)
- **FC < 0:** Control tiene MAYOR VAF que ALS (enriquecido en Control)
- **FC ≈ 0:** VAF similar en ambos grupos

**Ejemplo hsa-miR-378g:**
- Si `mean_als = 0.0158` y `mean_ctrl = 0.0150`
- FC = log2(0.0158 / 0.0150) = log2(1.053) = **+0.074**
- **Interpretación:** Ligeramente más alto en ALS

**Thresholds comunes:**
- **FC > +0.58** (ratio 1.5x) = Enriquecido en ALS
- **FC < -0.58** (ratio 0.67x) = Enriquecido en Control

---

#### **2.5. Test Estadístico (Wilcoxon):**

```r
test_result <- tryCatch({
  wilcox.test(als_vals, ctrl_vals)
}, error = function(e) list(p.value = 1))
```

**¿Qué hace?**
- Compara las **distribuciones completas** de VAF entre grupos
- **No paramétrico** (no asume normalidad)
- Devuelve un **p-value**

**p-value:**
- **p < 0.05:** Diferencia significativa entre ALS y Control
- **p ≥ 0.05:** No hay diferencia significativa

**¿Por qué tryCatch?**
Por si el test falla (e.g., sin varianza), asigna p = 1 (no significativo).

---

### **PASO 3: AJUSTE DE MÚLTIPLES COMPARACIONES**

```r
volcano_data$padj <- p.adjust(volcano_data$pvalue, method = "fdr")
```

**¿Qué es FDR (False Discovery Rate)?**
- Corrección de **Benjamini-Hochberg**
- Estamos haciendo ~295 tests (uno por miRNA)
- **Sin corrección:** Alta probabilidad de falsos positivos
- **Con FDR:** Controla la tasa de falsos descubrimientos

**Ejemplo:**
- miRNA_A: p-value raw = 0.01
- Después de FDR con 295 tests: p-adj = 0.15 (ya no significativo)

---

### **PASO 4: TRANSFORMAR P-VALUE PARA EL EJE Y**

```r
volcano_data$neg_log10_padj <- -log10(volcano_data$padj)
```

**¿Por qué -log10?**
- **p = 0.05** → -log10(0.05) = **1.3**
- **p = 0.001** → -log10(0.001) = **3**
- **p = 0.00001** → -log10(0.00001) = **5**

**Interpretación del eje Y:**
- Más alto = más significativo
- Línea horizontal en -log10(0.05) = **1.3** marca el threshold de significancia

---

### **PASO 5: CLASIFICAR miRNAs**

```r
volcano_data$Significance <- "NS"  # No significativo por defecto

# Enriquecidos en ALS
volcano_data$Significance[volcano_data$log2FC > 0.58 & 
                          volcano_data$padj < 0.05] <- "ALS enriched"

# Enriquecidos en Control
volcano_data$Significance[volcano_data$log2FC < -0.58 & 
                          volcano_data$padj < 0.05] <- "Control enriched"
```

**Criterios:**
- **ALS enriched:** FC > 1.5x (log2FC > 0.58) **Y** p-adj < 0.05
- **Control enriched:** FC < 0.67x (log2FC < -0.58) **Y** p-adj < 0.05
- **NS (No significativo):** No cumple ambos criterios

---

### **PASO 6: ETIQUETAR TOP miRNAs**

```r
top_labels <- volcano_data %>%
  filter(Significance != "NS") %>%
  arrange(padj) %>%
  head(15)
```

**Selecciona:** Los 15 miRNAs más significativos (menor p-adj) para mostrar sus nombres en el plot.

---

## 📊 INTERPRETACIÓN DEL VOLCANO PLOT

### **Regiones del Gráfico:**

```
           Control enriched    |    ALS enriched
                  ↓            |         ↓
     -log10(p)                 |
         ↑                     |
         |        •            |      •
   Sig  |    •       •         |  •       •
   ---  |--------------------1.3----------------------
         |  •   •   •   •  •  |  •  •  •  •  •
   NS   |        MAYORIA      |
         |                     |
         +-------------------------------------------------→
                -0.58    0    +0.58     log2(FC)
```

**Cuadrantes:**
- **Superior derecha:** ALS > Control, significativo (ROJO)
- **Superior izquierda:** Control > ALS, significativo (AZUL)
- **Centro/abajo:** No significativo (GRIS)

---

## ⚠️ LIMITACIONES ACTUALES

### **Potencial Problema: Agregación de Posiciones**

**Lo que estoy haciendo:**
```r
# Extraigo TODOS los G>T del miRNA (todas las posiciones)
als_vals <- [VAF pos1, VAF pos2, ..., VAF pos22] de todas las muestras ALS
```

**Esto significa:**
- Un miRNA con G>T en 5 posiciones diferentes contribuye 5× más valores
- **Puede sesgar** el promedio

### **Alternativas Posibles:**

#### **Opción A (ACTUAL): Promedio de TODOS los valores**
```r
mean_als <- mean(all_GT_VAF_values_from_all_positions)
```
**Pro:** Más datos, test más robusto
**Con:** Mezcla posiciones, puede sesgar por cantidad

#### **Opción B: Promedio por MUESTRA primero**
```r
# 1. Sumar VAF de todas las posiciones G>T por muestra
per_sample_vaf <- group_by(Sample_ID) %>% summarise(Total_GT = sum(VAF))

# 2. Luego promediar entre muestras del grupo
mean_als <- mean(per_sample_vaf$Total_GT[Group == "ALS"])
```
**Pro:** Cada muestra pesa igual
**Con:** Menos valores para el test

#### **Opción C: Solo posiciones SEED**
```r
# Solo G>T en posiciones 2-8
seed_only_vals <- filter(position >= 2, position <= 8)
mean_als <- mean(seed_only_vals)
```
**Pro:** Más específico funcionalmente
**Con:** Menos datos, algunos miRNAs sin valores

---

## 🤔 PREGUNTA PARA TI:

**¿Cuál método prefieres para el Volcano Plot?**

**A.** Promedio de TODOS los valores G>T (actual)
**B.** Promedio por muestra primero (cada muestra pesa igual)
**C.** Solo valores G>T en posiciones SEED

**O una cuarta opción que tengas en mente?**

---

**Código actual en:** `GENERATE_ALL_12_FIGURES_CLEAN.R` líneas ~30-60

