# PIPELINE DE PROCESAMIENTO DE DATOS DEFINITIVO
## miRNAs y Oxidación - Análisis ALS

**Fecha de Documentación:** $(date)  
**Versión:** 1.0 - DEFINITIVA  
**Estado:** ✅ Validado y Funcionando

---

## 📋 **FORMATO DE DATOS ORIGINAL**

### **Archivo de Entrada**
```
/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt
```

### **Estructura de Columnas**
- **Total de columnas:** 834
- **Muestras:** 415 (NO 830)
- **Meta columnas:** 2 (`miRNA name`, `pos:mut`)
- **Columnas de conteos SNV:** 415 (una por muestra)
- **Columnas de totales:** 415 (una por muestra, con sufijo `(PM+1MM+2MM)`)

### **Importante: Entendimiento de las Columnas**
- **Columnas SNV:** Contienen el número de veces que se encontró ese SNV específico en esa muestra
- **Columnas `(PM+1MM+2MM)`:** Contienen el total de veces que se encontró ese miRNA en general en esa muestra
- **Emparejamiento:** Cada columna SNV tiene su correspondiente columna total
- **Ejemplo:**
  - `Magen-ALS-enrolment-bloodplasma-SRR13934430` → conteo del SNV
  - `Magen-ALS-enrolment-bloodplasma-SRR13934430 (PM+1MM+2MM)` → total del miRNA

---

## 🔄 **PIPELINE DE PROCESAMIENTO DEFINITIVO**

### **Paso 1: Conversión SNV → SNP (Split & Collapse)**

#### **Función: `split_mutations`**
```r
split_mutations <- function(df, mut_col = "pos:mut") {
  df %>% 
    separate_rows(.data[[mut_col]], sep = ",") %>% 
    mutate(!!mut_col := str_trim(.data[[mut_col]]))
}
```

**Propósito:** Separar múltiples mutaciones en una sola entrada `pos:mut` (si las hay)

#### **Función: `collapse_after_split`**
```r
collapse_after_split <- function(df, mut_col = "pos:mut") {
  df %>% 
    group_by(`miRNA name`, !!sym(mut_col)) %>% 
    summarise(
      # 1) Sumamos únicamente los conteos de SNV
      across(all_of(snv_cols), ~ sum(.x, na.rm = TRUE)),
      # 2) Tomamos el primer valor de los conteos totales (son idénticos en cada split)
      across(all_of(total_cols), ~ first(.x)),
      .groups = "drop"
    )
}
```

**Propósito:** 
- Sumar conteos SNV de mutaciones separadas
- **NO sumar** los totales `(PM+1MM+2MM)` - tomar el primer valor (son idénticos)

### **Paso 2: Filtro de Representación VAF**

#### **Función: `apply_vaf_representation_filter`**
```r
apply_vaf_representation_filter <- function(df, snv_cols, total_cols, vaf_threshold = 0.5, imputation_method = "percentile") {
  # Para cada SNV:
  # 1. Calcular VAF = snv_count / total_count para cada muestra
  # 2. Identificar muestras con VAF > 0.5 (sobrerepresentadas)
  # 3. Si hay al menos 2 muestras con VAF > 0, proceder
  # 4. Aplicar imputación a muestras sobrerepresentadas
  # 5. Remover SNVs con < 2 muestras válidas
}
```

**Parámetros:**
- `vaf_threshold = 0.5` (50%)
- `imputation_method = "percentile"` (percentil 25 de muestras válidas)

**Lógica:**
1. **VAF > 0.5:** Muestra sobrerepresentada → aplicar imputación
2. **VAF ≤ 0.5 & > 0:** Muestra válida para imputación
3. **VAF = 0:** Muestra sin el SNV
4. **< 2 muestras válidas:** Remover SNV completo

---

## 📊 **RESULTADOS DEL PIPELINE**

### **Estadísticas de Procesamiento**
- **SNVs totales:** 21,526
- **SNVs PM (Perfect Match):** 1,450
- **SNVs no-PM (mutaciones reales):** 20,076
- **SNVs retenidos:** 21,365 (99.3%)
- **SNVs removidos:** 161 (datos insuficientes)
- **SNVs con muestras sobrerepresentadas:** 1,400

### **Archivo de Salida**
```
/Users/cesaresparza/New_Desktop/UCSD/8OG/outputs/processed_snv_data_vaf_filtered.tsv
```

---

## 🧬 **EJEMPLOS DE FUNCIONAMIENTO**

### **Ejemplo 1: SNV Normal (hsa-let-7a-3p, 10:CG)**
- **Muestras con VAF > 0:** 2
- **Muestras con VAF > 0.5:** 0
- **VAFs:** 0.0294, 0.0556
- **Resultado:** ✅ Retenido (sin imputación necesaria)

### **Ejemplo 2: SNV Sobrerepresentado (hsa-let-7b-3p, 22:CT)**
- **Muestras con VAF > 0:** 251
- **Muestras con VAF > 0.5:** 251 (TODAS)
- **VAF promedio:** 0.5943
- **Resultado:** ✅ Retenido (con imputación aplicada)

### **Ejemplo 3: SNV PM (hsa-let-7a-2-3p, PM)**
- **Muestras con VAF > 0:** 6
- **Muestras con VAF > 0.5:** 6 (TODAS)
- **VAF:** 1.0 (normal para PM)
- **Resultado:** ✅ Retenido (VAF = 1 es esperado para PM)

---

## 🔧 **SCRIPTS DE IMPLEMENTACIÓN**

### **Script Principal**
```
/Users/cesaresparza/New_Desktop/UCSD/8OG/R/data_preprocessing_pipeline_v2.R
```

### **Scripts de Validación**
```
/Users/cesaresparza/New_Desktop/UCSD/8OG/R/step_by_step_debug.R
/Users/cesaresparza/New_Desktop/UCSD/8OG/R/vaf_filter_summary.R
```

---

## ✅ **VALIDACIÓN DEL PIPELINE**

### **Verificaciones Realizadas**
1. ✅ **Identificación correcta de columnas** (SNV vs totales)
2. ✅ **Emparejamiento correcto** de columnas SNV-totales
3. ✅ **Cálculo correcto de VAFs**
4. ✅ **Aplicación correcta del filtro de representación**
5. ✅ **Imputación funcionando** para muestras sobrerepresentadas
6. ✅ **Retención alta** (99.3% de SNVs)
7. ✅ **Manejo correcto de SNVs PM** (VAF = 1 es normal)

### **Casos Edge Manejados**
- ✅ SNVs con VAF = 1 en todas las muestras (PM)
- ✅ SNVs con VAF > 0.5 en todas las muestras (sobrerepresentación extrema)
- ✅ SNVs con < 2 muestras válidas (removidos)
- ✅ Imputación cuando no hay muestras válidas para referencia

---

## 🎯 **PRÓXIMOS PASOS**

Con este pipeline validado, podemos proceder a:

1. **Análisis de miRNAs top** (filtro 50% + ranking por G>T en región semilla)
2. **Análisis de clustering** por posición
3. **Heatmaps con clustering jerárquico**
4. **Análisis estadístico** de diferencias G>T por posición

---

## 📝 **NOTAS IMPORTANTES**

- **NO confundir:** 415 muestras, NO 830
- **Columnas totales:** Representan totales del miRNA, NO se suman en el colapso
- **VAF = 1:** Normal para SNVs PM, no indica error
- **Imputación:** Usa percentil 25 de muestras válidas (VAF ≤ 0.5 & > 0)
- **Pipeline robusto:** Maneja casos edge y mantiene integridad de datos

---

**✅ ESTE ES EL PIPELINE DEFINITIVO PARA LIMPIEZA INICIAL**  
**📅 Documentado:** $(date)  
**🔄 Estado:** Listo para pruebas y análisis posteriores










