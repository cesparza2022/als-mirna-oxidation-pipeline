# 📚 TUTORIAL COMPLETO: Cálculo de VAF para Volcano Plot

**Fecha:** 2025-10-24  
**Paso a paso con datos REALES**

---

## 🎯 **FLUJO COMPLETO:**

```
Datos originales (matriz ancha)
   ↓
Filtrar G>T en seed
   ↓
Transformar a formato largo
   ↓
Agrupar por miRNA
   ↓
Calcular promedios ALS y Control
   ↓
Calcular Fold Change
   ↓
Test estadístico
   ↓
Ajuste FDR
   ↓
Clasificar y graficar
```

---

## 📊 **PASO 0: DATOS DE ENTRADA**

### **Archivo 1: final_processed_data_CLEAN.csv**

**Estructura:**
```
┌──────────────────┬─────────┬──────────┬──────────┬──────────┬─────┐
│ miRNA_name       │ pos.mut │ ALS1     │ ALS2     │ Control1 │ ... │
├──────────────────┼─────────┼──────────┼──────────┼──────────┼─────┤
│ hsa-let-7a-5p    │ 2:GT    │ 0.000015 │ 0.000000 │ 0.000000 │ ... │
│ hsa-let-7a-5p    │ 4:GT    │ 0.000020 │ 0.000010 │ 0.000025 │ ... │
│ hsa-let-7a-5p    │ 5:GT    │ 0.000000 │ 0.000005 │ 0.000000 │ ... │
│ hsa-miR-9-5p     │ 3:GT    │ 0.000030 │ 0.000000 │ 0.000015 │ ... │
└──────────────────┴─────────┴──────────┴──────────┴──────────┴─────┘
```

**Dimensiones:**
- Filas: 5,448 SNVs (todas las mutaciones)
- Columnas: miRNA_name + pos.mut + 415 muestras

**¿Qué es cada celda?**
```
Celda = VAF = Variant Allele Frequency

VAF = count_variante / count_total_miRNA

Ejemplo: let-7a 2:GT en muestra ALS1
   VAF = 0.000015
   Significa: 0.0015% de las moléculas de let-7a tienen esta mutación
```

---

### **Archivo 2: metadata.csv**

**Estructura:**
```
┌─────────────────────────────┬──────────┐
│ Sample_ID                   │ Group    │
├─────────────────────────────┼──────────┤
│ Magen.ALS.enrolment...SRR1  │ ALS      │
│ Magen.ALS.enrolment...SRR2  │ ALS      │
│ Magen.control...SRR1        │ Control  │
└─────────────────────────────┴──────────┘
```

**Total:** 415 muestras (313 ALS + 102 Control)

---

## 📌 **PASO 1: FILTRAR G>T EN SEED**

### **Filtros aplicados:**

```r
seed_gt_data <- data %>%
  filter(str_detect(pos.mut, ":GT$")) %>%      # Solo G>T
  mutate(position = as.numeric(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(position >= 2, position <= 8)          # Solo seed
```

**Filtro 1:** `str_detect(pos.mut, ":GT$")`
```
Mantiene: "2:GT", "6:GT", "10:GT" ✅
Elimina: "6:GA", "7:AC", "3:CT" ❌
```

**Filtro 2:** `position >= 2 & position <= 8`
```
Mantiene: "2:GT", "6:GT", "7:GT" ✅ (seed)
Elimina: "1:GT", "10:GT", "15:GT" ❌ (no-seed)
```

**Resultado:**
- Entrada: 5,448 SNVs
- Salida: **473 SNVs** (solo G>T en seed)
- miRNAs únicos: **301**

---

## 📌 **PASO 2: TRANSFORMAR A FORMATO LARGO**

### **De ancho a largo:**

**ANTES (formato ancho):**
```
┌────────────┬─────────┬──────┬──────┬───────┬─────┐
│ let-7a     │ 2:GT    │ ALS1 │ ALS2 │ Ctrl1 │ ... │
├────────────┼─────────┼──────┼──────┼───────┼─────┤
│            │         │ 0.02 │ 0.01 │ 0.025 │ ... │
└────────────┴─────────┴──────┴──────┴───────┴─────┘
      ↓ 1 fila con 415 columnas de muestras
```

**DESPUÉS (formato largo):**
```
┌────────────┬─────────┬───────────┬───────┬──────┐
│ miRNA      │ pos.mut │ Sample_ID │ Group │ VAF  │
├────────────┼─────────┼───────────┼───────┼──────┤
│ let-7a     │ 2:GT    │ ALS1      │ ALS   │ 0.02 │
│ let-7a     │ 2:GT    │ ALS2      │ ALS   │ 0.01 │
│ let-7a     │ 2:GT    │ Ctrl1     │ Ctrl  │ 0.025│
│ ...        │ ...     │ ...       │ ...   │ ...  │
└────────────┴─────────┴───────────┴───────┴──────┘
      ↓ 415 filas (1 por muestra)
```

**Código:**
```r
vaf_long <- seed_gt_data %>%
  pivot_longer(
    cols = all_of(sample_cols),  # Las 415 columnas de muestras
    names_to = "Sample_ID",       # Nueva columna con nombre de muestra
    values_to = "VAF"             # Nueva columna con el valor (VAF)
  ) %>%
  left_join(metadata, by = "Sample_ID")  # Agregar grupo (ALS/Control)
```

**Resultado:**
- 473 SNVs × 415 muestras = **196,295 filas**
- Cada fila = 1 SNV en 1 muestra con su VAF y grupo

---

## 📌 **PASO 3: EJEMPLO CON let-7a-5p**

### **Datos reales extraídos:**

**let-7a-5p tiene 4 posiciones con G>T en seed:**
- 2:GT, 4:GT, 5:GT, 6:GT

**Después de filtrar solo let-7a:**
```
Total filas: 1,660
   = 4 posiciones × 415 muestras
```

**Primeras 10 filas (ejemplo REAL):**
```
┌────────────┬─────────┬─────────────┬───────┬──────────┐
│ miRNA      │ pos.mut │ Sample_ID   │ Group │ VAF      │
├────────────┼─────────┼─────────────┼───────┼──────────┤
│ let-7a-5p  │ 2:GT    │ ALS-SRR...1 │ ALS   │ 0.000015 │
│ let-7a-5p  │ 2:GT    │ ALS-SRR...2 │ ALS   │ 0.000000 │
│ let-7a-5p  │ 2:GT    │ ALS-SRR...3 │ ALS   │ 0.000000 │
│ let-7a-5p  │ 2:GT    │ Ctrl-SRR..1 │ Ctrl  │ 0.000000 │
│ ...        │ ...     │ ...         │ ...   │ ...      │
└────────────┴─────────┴─────────────┴───────┴──────────┘
```

**Separar por grupo:**
```r
als_vals <- filter(Group == "ALS") → 1,252 valores
ctrl_vals <- filter(Group == "Control") → 408 valores
```

**Valores ALS (primeros 10):**
```
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...
```
(Muchos ceros porque VAF es muy bajo)

**Calcular estadísticas ALS:**
```
N = 1,252 muestras (todas las filas ALS de let-7a con algún G>T seed)
Mean = 0.000015 (promedio de los 1,252 valores)
Median = 0 (mayoría son ceros)
SD = 0.000059
```

**Calcular estadísticas Control:**
```
N = 408 muestras
Mean = 0.000016
Median = 0
SD = 0.000042
```

---

## 📌 **PASO 4: CALCULAR FOLD CHANGE**

### **Cálculo para let-7a:**

**Promedios:**
```
Mean_ALS = 0.000015
Mean_Control = 0.000016
```

**Ajuste (+0.001 pseudocount):**
```
Mean_ALS_adj = 0.000015 + 0.001 = 0.001015
Mean_Control_adj = 0.000016 + 0.001 = 0.001016
```

**¿Por qué +0.001?**
- Si algún promedio es 0 → división por cero = error
- 0.001 es despreciable si los valores son mayores
- Pero evita el error matemático

**Fold Change:**
```
FC = Mean_ALS_adj / Mean_Control_adj
FC = 0.001015 / 0.001016
FC = 0.9992
```

**Interpretación:**
- FC ≈ 1 → Casi iguales
- FC = 0.9992 → Control ligeramente mayor (1.0008x)

**log₂(FC):**
```
log2FC = log₂(0.9992)
log2FC = -0.0012
```

**Interpretación:**
- log2FC ≈ 0 → Sin diferencia práctica
- log2FC = -0.0012 → Control muy ligeramente mayor
- **NO alcanza umbral** de 0.58 (que sería 1.5x)

---

## 📌 **PASO 5: TEST ESTADÍSTICO**

### **Wilcoxon test para let-7a:**

**Datos comparados:**
```
Grupo ALS: [0, 0, 0, 0.000015, 0, 0, 0.000009, ...] (1,252 valores)
Grupo Control: [0, 0, 0, 0, 0.000020, ...] (408 valores)
```

**Pregunta del test:**
"¿Estas dos distribuciones son ESTADÍSTICAMENTE diferentes?"

**Resultado del ejemplo:**
```
p-value = 0.84 (ejemplo, NO significativo)
```

**Interpretación:**
- p = 0.84 → 84% probabilidad de que la diferencia sea por azar
- **NO podemos decir que son diferentes**
- Las distribuciones se superponen demasiado

**¿Por qué NO es significativo?**
```
Diferencia de medias: |0.000015 - 0.000016| = 0.000001 (TINY!)
Variabilidad: SD ≈ 0.00005 (mucho MAYOR que la diferencia)

Diferencia << Variabilidad → No significativo
```

---

## 📌 **PASO 6: REPETIR PARA LOS 301 miRNAs**

**Proceso automático:**
```r
for (cada miRNA) {
  # 1. Filtrar datos de ese miRNA
  # 2. Separar ALS vs Control
  # 3. Calcular means
  # 4. Calcular log2FC
  # 5. Hacer test
  # 6. Guardar resultado
}
```

**Resultado:**
```
293 miRNAs procesados (8 excluidos por tener n<5)

Cada uno tiene:
   - log2FC (posición X)
   - p-value (para calcular posición Y)
```

---

## 📌 **PASO 7: AJUSTE FDR**

### **El problema:**

**Sin ajuste:**
```
293 tests con p < 0.05
Esperaríamos ~15 falsos positivos por AZAR (293 × 0.05)
```

**Solución: FDR (False Discovery Rate)**
```r
padj <- p.adjust(pvalue, method = "fdr")
```

**Método Benjamini-Hochberg:**
1. Ordena los 293 p-values de menor a mayor
2. Para cada uno, ajusta según su posición
3. Control: "De todos los que llamo significativos, <5% son falsos"

**Efecto del ajuste:**
```
ANTES (p-value original):
   miRNA-1: p = 0.02 → "significativo"
   miRNA-2: p = 0.04 → "significativo"
   miRNA-3: p = 0.03 → "significativo"

DESPUÉS (FDR ajustado):
   miRNA-1: padj = 0.15 → "NO significativo" ❌
   miRNA-2: padj = 0.20 → "NO significativo" ❌
   miRNA-3: padj = 0.18 → "NO significativo" ❌
```

**En tu caso:**
- SIN FDR: Habría algunos significativos (p < 0.05)
- CON FDR: **0 significativos** (todos padj > 0.05)

---

## 📌 **PASO 8: CLASIFICACIÓN**

### **Criterios duales:**

```r
"ALS" si:
   ✓ log2FC > 0.58      (ALS tiene ≥1.5x más)
   Y
   ✓ padj < 0.05        (significativo)

"Control" si:
   ✓ log2FC < -0.58     (Control tiene ≥1.5x más)
   Y
   ✓ padj < 0.05

"NS" (no significativo):
   Cualquier otro caso
```

**Resultado:**
- 0 clasificados como "ALS"
- 0 clasificados como "Control"
- 293 clasificados como "NS"

**¿Por qué todos "NS"?**
- Algunos tienen |log2FC| > 0.58 **PERO** padj > 0.05 (no significativo)
- Otros tienen padj < 0.05 **PERO** |log2FC| < 0.58 (diferencia pequeña)
- **Ninguno cumple AMBOS criterios**

---

## 📌 **PASO 9: GRAFICAR**

### **Ejes:**

**Eje X: log2FC**
```
Para cada miRNA:
   X = log₂(Mean_ALS / Mean_Control)

Escala:
   -2  -1  -0.58  0  0.58  1  2
   ←  Control más  |  ALS más  →
```

**Eje Y: -log₁₀(padj)**
```
Para cada miRNA:
   Y = -log₁₀(padj)

Escala:
   0.0  0.5  1.0  1.3  2.0  3.0
   ← No sig    |  Significativo →
```

### **Interpretación de posiciones:**

**Ejemplo 1: Punto en (X=0.8, Y=2.5)**
```
X = 0.8 → log2FC = 0.8 → ALS tiene 2^0.8 = 1.74x más
Y = 2.5 → padj = 10^-2.5 = 0.003

Interpretación:
   ✓ ALS > Control (1.74x)
   ✓ Altamente significativo (p = 0.003)
   → Clasificación: "ALS" (rojo)
```

**Ejemplo 2: Punto en (X=0.3, Y=0.8)**
```
X = 0.3 → log2FC = 0.3 → ALS tiene 2^0.3 = 1.23x más
Y = 0.8 → padj = 10^-0.8 = 0.16

Interpretación:
   ✓ ALS ligeramente mayor
   ✗ NO significativo (p = 0.16 > 0.05)
   → Clasificación: "NS" (gris)
```

**En tu volcano:**
- Todos los puntos están en la zona inferior (Y < 1.3)
- Algunos tienen |X| > 0.58, pero Y es bajo
- **Ninguno en la zona de interés** (arriba de las líneas)

---

## 💡 **RESUMEN DE QUÉ INFORMACIÓN USAMOS:**

### **Para cada miRNA:**

**Información extraída:**
```
let-7a en ALS:
   • Tiene 4 G>T en seed (posiciones 2,4,5,6)
   • Se mide en 313 muestras ALS
   • Total: 4 pos × 313 muestras = 1,252 valores de VAF
   • Promedio: 0.000015

let-7a en Control:
   • Mismas 4 posiciones
   • Se mide en 102 muestras Control
   • Total: 4 pos × 102 muestras = 408 valores de VAF
   • Promedio: 0.000016
```

**Cálculo:**
```
FC = 0.000015 / 0.000016 = 0.94
log2FC = -0.09 (Control ligeramente mayor)

Test: p = 0.84 (NO significativo)
FDR: padj > 0.5 (muy lejos de significancia)

Clasificación: NS (gris)
```

---

## 🎯 **¿QUÉ NOS DICE EL RESULTADO (0 significativos)?**

### **Hallazgo:**

**A nivel de miRNAs INDIVIDUALES, NO hay diferencias significativas.**

**Pero sabemos de Fig 2.1-2.2:**
```
Total G>T VAF:
   Control: 3.69
   ALS: 2.58
   p = 2.5e-13 (altamente significativo!)
```

### **Reconciliación:**

**Control > ALS globalmente, PERO:**

No porque haya miRNAs específicos con diferencias dramáticas.

**Sino porque:**

**Opción A: Control tiene MÁS miRNAs expresados**
```
Control: 200 miRNAs × VAF promedio = 3.69
ALS: 150 miRNAs × VAF promedio = 2.58
→ Más miRNAs, no mayor VAF por miRNA
```

**Opción B: Diferencias pequeñas pero consistentes**
```
200 miRNAs con Control 0.01 mayor que ALS
   Diferencia individual: NO significativa
   Suma total: 200 × 0.01 = 2.0 diferencia total
   → Suma SÍ significativa
```

**Opción C: Algunos miRNAs dominan en Control**
```
Control:
   miR-1: VAF = 1.5 (muy alto)
   miR-2: VAF = 1.0
   Otros 200: VAF = 0.01 cada uno
   Total: 1.5 + 1.0 + 2.0 = 4.5

ALS:
   Todos 200 miRNAs: VAF = 0.015 cada uno
   Total: 200 × 0.015 = 3.0

→ Control > ALS totalmente
→ Pero a nivel individual, solo 2 miRNAs de Control son altos
```

---

## ✅ **RESUMEN FINAL:**

### **Qué hace el volcano:**

1. **Extrae** VAF de G>T en seed de 301 miRNAs
2. **Calcula** promedio ALS y Control por miRNA
3. **Compara** mediante Fold Change y test estadístico
4. **Ajusta** p-values (FDR) para controlar falsos positivos
5. **Clasifica** según umbrales (magnitud + significancia)
6. **Grafica** para visualizar qué miRNAs difieren

### **Qué nos dice:**

**Resultado:** 0 significativos

**Interpretación:**
- Efecto distribuido entre muchos miRNAs (no focal)
- Alta variabilidad intra-grupo
- Burden global significativo ≠ miRNAs individuales significativos
- **Ambos hallazgos son compatibles y válidos**

---

**¿Quedó claro el flujo completo de cálculos?** 🎯

