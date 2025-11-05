# ANÁLISIS INICIAL DETALLADO Y PROFUNDO - RESULTADOS

## 🔬 **ANÁLISIS DE TRANSFORMACIONES DEL DATASET**

### **Evolución del Dataset:**
- **Dataset original:** 68,968 SNVs × 832 columnas
- **Después split:** 111,785 SNVs (62% aumento por separación de mutaciones múltiples)
- **Después collapse:** 29,254 SNVs (74% reducción por colapso de duplicados)
- **Después cálculo VAFs:** 29,254 SNVs × 1,247 columnas (415 VAFs + 832 originales)
- **Después filtrado VAF > 50%:** 29,254 SNVs × 1,247 columnas (210,118 NaNs generados)

## 🧬 **ANÁLISIS PROFUNDO DE MUTACIONES G>T (OXIDACIÓN)**

### **Distribución de Mutaciones G>T por Región Funcional:**
- **Región 3' (posiciones 16-22):** 888 mutaciones G>T (40.49%)
- **Región Central (posiciones 9-15):** 759 mutaciones G>T (34.61%)
- **Región Semilla (posiciones 2-8):** 482 mutaciones G>T (21.98%)
- **Otras posiciones:** 64 mutaciones G>T (2.92%)

### **Insights Clave:**
- **40.49% de mutaciones G>T en región 3'** - Mayor susceptibilidad al daño oxidativo
- **21.98% en región semilla** - Impacto funcional potencial en la regulación génica
- **575 miRNAs afectados en región 3'** vs **309 en semilla**

## 🔄 **ANÁLISIS COMPARATIVO DE TIPOS DE MUTACIÓN**

### **Ranking de Frecuencia de Mutaciones:**
1. **T>C:** 3,986 SNVs (13.63%) - Mutación más frecuente
2. **A>G:** 3,216 SNVs (10.99%)
3. **G>A:** 3,074 SNVs (10.51%)
4. **C>T:** 2,671 SNVs (9.13%)
5. **T>A:** 2,320 SNVs (7.93%)
6. **T>G:** 2,221 SNVs (7.59%)
7. **G>T:** 2,193 SNVs (7.50%) - **Biomarcador de oxidación**
8. **A>T:** 1,817 SNVs (6.21%)

### **Análisis de Oxidación:**
- **G>T es la 7ª mutación más frecuente** (7.50%)
- **Posición intermedia** en el ranking de mutaciones
- **Significativa** considerando que es específica de daño oxidativo

## 📊 **ANÁLISIS DETALLADO DE VAFs**

### **Distribución por Categorías:**
- **0-1%:** 872,848 VAFs (71.20%) - Mutaciones muy raras
- **1-5%:** 79,285 VAFs (6.47%) - Mutaciones raras
- **5-10%:** 21,444 VAFs (1.75%) - Mutaciones moderadas
- **10-20%:** 17,157 VAFs (1.40%) - Mutaciones frecuentes
- **20-50%:** 25,128 VAFs (2.05%) - Mutaciones muy frecuentes
- **>50%:** 210,118 VAFs (17.14%) - **Filtradas como artefactos**

### **Insights:**
- **77.67% de VAFs < 5%** - Predominio de mutaciones raras
- **17.14% de VAFs > 50%** - Posibles artefactos técnicos
- **Filtrado efectivo** de 210,118 VAFs potencialmente problemáticas

## 🆚 **ANÁLISIS COMPARATIVO ALS vs CONTROL**

### **Mutaciones G>T Específicas:**
- **Total mutaciones G>T:** 2,193
- **VAF promedio ALS:** 0.768%
- **VAF promedio Control:** 0.942%
- **Diferencia:** -0.174% (Control ligeramente mayor)

### **Interpretación:**
- **Control muestra VAFs ligeramente mayores** en mutaciones G>T
- **Diferencia pequeña pero consistente** (-0.174%)
- **Necesario análisis estadístico** para determinar significancia

## 🎯 **ANÁLISIS DE REGIONES FUNCIONALES**

### **Distribución de SNVs por Región:**
- **Región No-semilla:** 20,709 SNVs (70.79%)
- **Región Semilla:** 6,959 SNVs (23.79%)
- **Posiciones no identificadas:** 1,586 SNVs (5.42%)

### **Mutaciones G>T por Región:**
- **Región 3':** 888 G>T (40.49% del total G>T)
- **Región Central:** 759 G>T (34.61% del total G>T)
- **Región Semilla:** 482 G>T (21.98% del total G>T)

## 📈 **FIGURAS GENERADAS (9)**

1. **`01_distribucion_tipos_mutacion.png`** - Ranking completo de tipos de mutación
2. **`02_gt_por_region.png`** - Distribución de G>T por región funcional
3. **`03_distribucion_categorias_vaf.png`** - Distribución de VAFs por categoría
4. **`04_snvs_por_region_funcional.png`** - SNVs por región con % de G>T
5. **`01_snvs_por_mirna.png`** - miRNAs con más SNVs
6. **`02_posiciones_mas_mutadas.png`** - Posiciones más mutadas
7. **`03_gt_por_mirna.png`** - miRNAs con más mutaciones G>T
8. **`04_distribucion_vafs.png`** - Histograma de VAFs
9. **`05_snvs_por_region.png`** - Distribución por región

## 📋 **TABLAS GENERADAS (17)**

### **Análisis Estructural:**
- `01_analisis_transformaciones.csv` - Evolución del dataset
- `02_analisis_mirnas.csv` - Análisis detallado por miRNA
- `03_analisis_posiciones.csv` - Análisis detallado por posición

### **Análisis de Oxidación:**
- `04_analisis_gt_por_region.csv` - G>T por región funcional
- `05_analisis_gt_por_posicion.csv` - G>T por posición específica
- `10_analisis_gt_als_control.csv` - Comparación G>T ALS vs Control

### **Análisis de Mutaciones:**
- `06_analisis_tipos_mutacion.csv` - Ranking de tipos de mutación
- `11_analisis_regiones_funcionales.csv` - Análisis por región funcional
- `12_analisis_gt_por_region_posicion.csv` - G>T detallado por región y posición

### **Análisis de VAFs:**
- `07_estadisticas_vaf_por_muestra.csv` - Estadísticas VAF por muestra
- `08_distribucion_categorias_vaf.csv` - Distribución por categorías
- `09_diferencias_vaf_als_control.csv` - Diferencias VAF entre grupos

## 🔍 **CONCLUSIONES PRINCIPALES**

### **1. Daño Oxidativo (G>T):**
- **7.50% de todas las mutaciones** son G>T
- **40.49% de G>T en región 3'** - Mayor susceptibilidad
- **21.98% de G>T en semilla** - Impacto funcional potencial

### **2. Patrones de Mutación:**
- **T>C es la mutación más frecuente** (13.63%)
- **G>T ocupa posición 7** en frecuencia
- **Distribución heterogénea** por regiones funcionales

### **3. VAFs y Calidad:**
- **71.20% de VAFs < 1%** - Mutaciones muy raras
- **17.14% de VAFs > 50%** - Filtradas como artefactos
- **Filtrado efectivo** de 210,118 VAFs problemáticas

### **4. Comparación ALS vs Control:**
- **Control muestra VAFs ligeramente mayores** en G>T
- **Diferencia de -0.174%** (no significativa sin test estadístico)
- **Necesario análisis estadístico** para confirmar diferencias

### **5. Regiones Funcionales:**
- **70.79% de SNVs en no-semilla** vs **23.79% en semilla**
- **Región 3' más susceptible** a mutaciones G>T
- **Semilla funcionalmente importante** pero menos afectada

---
*Análisis completado: 2024-10-07*
*Pipeline: Análisis inicial detallado de SNVs en miRNAs para ALS*








