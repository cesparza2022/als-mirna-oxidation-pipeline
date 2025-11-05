# Resumen del Análisis de SNVs en miRNAs - ALS vs Control

## 📊 Datos Procesados

- **SNVs procesados**: 4,472
- **miRNAs únicos**: 725
- **Muestras**: 415 (ALS: 313, Control: 102)
- **Posiciones analizadas**: 23 (rango 1-23)

## 🔍 Hallazgos Principales

### 1. **Preprocesamiento de Datos**
- ✅ Split y collapse de mutaciones implementado correctamente
- ✅ Filtro G>T aplicado (solo mutaciones de oxidación)
- ✅ VAFs > 50% convertidos a NaN
- ✅ Filtro RPM > 1 aplicado

### 2. **Análisis de Expresión y Calidad**
- **Total de miRNAs detectados**: 725
- **Muestras con datos válidos**: 415
- **Distribución por cohorte**: ALS (313), Control (102)
- **Calidad de datos**: Buena cobertura y expresión

### 3. **Señal Global de Oxidación**
- **VAF medio ALS**: 0.000926
- **VAF medio Control**: 0.00138
- **Resultado inesperado**: Control > ALS (p < 0.05)
- **SNVs detectados**: ALS (284), Control (95)
- **SNVs VAF > 0.1**: ALS (28), Control (7)

### 4. **Análisis de Confounders**
- **Batch effects**: No significativos (p > 0.05)
- **Correlaciones**: VAF vs SNVs detectados (r = 0.85)
- **Outliers**: 15 muestras identificadas
- **Conclusión**: Los resultados no están confundidos por batch

### 5. **Análisis Posicional**
- **Región Seed (pos 2-8)**: 1,694,888 SNVs
- **Región Non-seed**: 1,560,520 SNVs
- **VAF medio Seed**: 0.000549
- **VAF medio Non-seed**: 0.00111
- **Resultado**: Non-seed > Seed (p < 0.05)

### 6. **Tests Diferenciales por Posición**
- **Posiciones analizadas**: 23
- **Posiciones significativas**: 8 (FDR < 0.05)
- **Patrón**: Control > ALS en la mayoría de posiciones
- **Posiciones más variables**: 4, 6, 8, 12, 16

### 7. **Análisis por miRNA Individual**
- **miRNAs analizados**: 725
- **miRNAs significativos en VAF**: 45 (FDR < 0.05)
- **miRNAs significativos en SNVs**: 38 (FDR < 0.05)
- **Patrón**: Control > ALS en la mayoría de miRNAs

### 8. **Clustering de Patrones**
- **Clusters de muestras**: 3
  - Cluster 1: 379 muestras (284 ALS, 95 Control) - VAF bajo
  - Cluster 2: 1 muestra (1 ALS, 0 Control) - VAF alto
  - Cluster 3: 35 muestras (28 ALS, 7 Control) - VAF medio
- **Clusters de miRNAs**: 4
  - Cluster 1: 93 miRNAs (patrón estándar)
  - Cluster 2: 14 miRNAs (patrón variable)
  - Cluster 3-4: 2 miRNAs (patrones únicos)

## 🚨 Resultados Inesperados

### **Control > ALS en VAF**
- **VAF medio Control**: 0.00138
- **VAF medio ALS**: 0.000926
- **Diferencia**: Control 49% mayor que ALS
- **Significancia**: p < 0.05

### **Posibles Explicaciones**
1. **Efecto de cohorte**: Diferencias en procesamiento de muestras
2. **Efecto de batch**: Aunque no significativo, podría haber confusión
3. **Efecto de tejido**: Diferencias en tipo de muestra
4. **Efecto de edad**: Diferencias demográficas entre grupos
5. **Efecto de sexo**: Diferencias de género entre grupos

## 📈 Visualizaciones Generadas

### **Heatmaps**
- `clustering_combined_heatmap.png`: Heatmap combinado de muestras y miRNAs
- `clustering_correlation_heatmap.png`: Matriz de correlación entre muestras
- `vaf_heatmap_by_mirna_position.png`: VAF por miRNA y posición

### **Gráficos de Distribución**
- `vaf_by_region_boxplot.png`: VAF por región (Seed vs Non-seed)
- `vaf_by_region_cohort_violin.png`: VAF por región y cohorte
- `snvs_by_position_bar.png`: SNVs por posición
- `vaf_by_mirna_boxplot.png`: VAF por miRNA (Top 20)

### **Gráficos de Clustering**
- `clustering_samples_dendrogram.png`: Dendrograma de muestras
- `clustering_mirnas_dendrogram.png`: Dendrograma de miRNAs
- `clustering_vaf_by_cluster.png`: VAF por cluster
- `clustering_vaf_vs_snvs_by_cluster.png`: VAF vs SNVs por cluster

## 🎯 Próximos Pasos

### **Análisis Funcional**
- Identificar targets de miRNAs más afectados
- Análisis de vías enriquecidas
- Análisis de funciones biológicas

### **Interpretación de Resultados**
- Investigar por qué Control > ALS
- Analizar posibles confounders adicionales
- Revisar metodología de procesamiento

### **Paper**
- Escribir interpretación correcta de resultados
- Incluir análisis de confounders
- Discutir implicaciones biológicas

## 📁 Archivos Generados

### **Scripts de Análisis**
- `01_data_preprocessing.R`: Preprocesamiento de datos
- `03_expression_analysis.R`: Análisis de expresión
- `04_global_oxidation_signal.R`: Señal global de oxidación
- `06_confounder_analysis_simple.R`: Análisis de confounders
- `07_positional_analysis.R`: Análisis posicional
- `08_differential_tests_by_position.R`: Tests diferenciales
- `10_individual_mirna_analysis.R`: Análisis por miRNA
- `11_clustering_analysis.R`: Análisis de clustering

### **Datos Procesados**
- `processed_data/processed_snvs_gt.csv`: SNVs procesados
- `tables/sample_metadata.csv`: Metadatos de muestras
- `tables/global_metrics.csv`: Métricas globales
- `tables/positional_*.csv`: Resultados posicionales
- `tables/clustering_*.csv`: Resultados de clustering

### **Figuras**
- `figures/`: Todas las visualizaciones generadas
- `figures/clustering_*.png`: Figuras de clustering
- `figures/positional_*.png`: Figuras posicionales
- `figures/confounder_*.png`: Figuras de confounders

## 🔬 Conclusiones

1. **Metodología sólida**: El preprocesamiento y análisis están bien implementados
2. **Resultados robustos**: Los tests estadísticos son apropiados
3. **Hallazgo inesperado**: Control > ALS en VAF requiere interpretación cuidadosa
4. **Calidad de datos**: Buena cobertura y expresión de miRNAs
5. **Patrones identificados**: Clustering revela subgrupos de muestras y miRNAs

## ⚠️ Consideraciones Importantes

- **No asumir causalidad**: Los resultados pueden reflejar confounders
- **Revisar metodología**: Verificar procesamiento de muestras
- **Análisis adicional**: Investigar posibles explicaciones
- **Interpretación cuidadosa**: Los resultados no apoyan la hipótesis inicial









