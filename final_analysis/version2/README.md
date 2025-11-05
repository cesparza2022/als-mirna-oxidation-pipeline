# Análisis Versión 2: 4,472 SNVs

## 📊 **RESUMEN EJECUTIVO**

Este análisis utiliza los **4,472 SNVs** resultantes del preprocesamiento (split y collapse) sin filtros adicionales innecesarios.

## 🔢 **NÚMEROS CLAVE**

### **Datos de entrada:**
- **SNVs iniciales**: 68,968
- **SNVs G>T**: 5,496
- **SNVs individuales (split)**: 9,099
- **SNVs únicos finales (collapse)**: 4,472
- **miRNAs únicos**: 725
- **Muestras**: 415 (313 ALS, 102 Control)

### **VAFs calculados:**
- **Total VAFs**: 1,855,880
- **VAFs válidos (>0)**: 88,324
- **VAFs > 0.5 (convertidos a NA)**: 0

## 📈 **RESULTADOS PRINCIPALES**

### **1. Comparación General ALS vs Control:**
- **VAF medio ALS**: 0.000896
- **VAF medio Control**: 0.00118
- **Diferencia**: Control > ALS (p < 0.001)
- **Test t**: t = -9.93, p < 0.001

### **2. Análisis por Región:**
- **Región Seed**: No hay diferencia significativa (p = 0.429)
- **Región Non-seed**: Control > ALS

### **3. miRNAs Significativos:**
- **miRNAs analizados**: 725
- **miRNAs significativos en VAF**: 2
- **miRNAs significativos en SNVs**: 0

### **4. Top miRNAs Diferenciales:**
1. **hsa-miR-503-5p**: Mayor diferencia (VAF Control > ALS)
2. **hsa-miR-181c-3p**: Segunda mayor diferencia
3. **hsa-miR-4738-3p**: Tercera mayor diferencia

### **5. Análisis de Z-scores:**
- **SNVs con z-score calculado**: 3,377
- **Z-scores > 2**: 11
- **Z-scores > 3**: 6

### **6. Posiciones Más Diferenciales:**
1. **Posición 23**: Mayor diferencia (z-score = -1.53)
2. **Posición 22**: Segunda mayor diferencia (z-score = -0.46)
3. **Posición 21**: Tercera mayor diferencia (z-score = -0.22)

## 📁 **ARCHIVOS GENERADOS**

### **Scripts:**
- `01_analysis_v2.R`: Análisis general
- `02_heatmaps_simple.R`: Análisis de z-scores y clustering
- `03_individual_mirna_analysis.R`: Análisis individual de miRNAs

### **Resultados:**
- `zscore_by_snv.csv`: Z-scores por SNV
- `zscore_by_position.csv`: Z-scores por posición
- `sample_clusters.csv`: Información de clusters
- `mirna_summary.csv`: Resumen de miRNAs
- `vaf_matrix.csv`: Matriz de VAFs
- `mirna_test_results.csv`: Resultados de tests diferenciales
- `seed_analysis.csv`: Análisis de región seed

### **Figuras:**
- `vaf_by_mirna_top20.pdf`: VAFs por miRNA (top 20)
- `snvs_by_mirna_top20.pdf`: SNVs por miRNA (top 20)
- `heatmap_significant_mirnas.pdf`: Heatmap de miRNAs significativos

## 🔍 **HALLAZGOS CLAVE**

1. **Patrón Inesperado**: Control > ALS en VAF general
2. **Pocos miRNAs Significativos**: Solo 2 de 725 miRNAs son significativos
3. **Posición 23**: Mayor diferencia entre grupos
4. **Clustering**: Los clusters no separan perfectamente por cohorte

## ⚠️ **LIMITACIONES**

1. **Datos Constantes**: No se puede realizar test t para número de SNVs por muestra
2. **Pocos Significativos**: Solo 2 miRNAs significativos después de corrección FDR
3. **Patrón Inesperado**: Control > ALS requiere investigación adicional

## 🎯 **PRÓXIMOS PASOS**

1. **Investigar Confounders**: Edad, sexo, batch effects
2. **Análisis Funcional**: Enriquecimiento de miRNAs diferenciales
3. **Validación**: Confirmar resultados con métodos alternativos
4. **Interpretación**: Explicar por qué Control > ALS

## 📊 **INTERPRETACIÓN**

Los resultados muestran un patrón inesperado donde el grupo Control tiene mayor VAF que el grupo ALS. Esto sugiere que:

1. **Posibles confounders** no controlados
2. **Diferencias en el procesamiento** de muestras
3. **Características poblacionales** diferentes entre grupos
4. **Necesidad de análisis adicional** para entender el patrón

Este análisis proporciona una base sólida para investigaciones posteriores y la identificación de factores que puedan explicar estos resultados inesperados.









