# Análisis de Clustering Jerárquico - Heatmaps de VAF y Z-score

## Resumen Ejecutivo

Se generaron exitosamente heatmaps comprehensivos con clustering jerárquico para analizar patrones de agrupamiento en mutaciones G>T de miRNAs. El análisis incluye **todos los SNVs G>T** (no solo región semilla) aplicando filtros de calidad (VAF>50%).

## Archivos Generados

### 1. Heatmap Principal
- **`vaf_heatmap_hierarchical_clustering.pdf`** - Heatmap principal con clustering jerárquico de VAF
  - 18 SNVs G>T × 415 muestras
  - Clustering de filas (SNVs) y columnas (muestras)
  - Anotaciones de familias de miRNAs, posición, y tipo de región

### 2. Análisis de Clustering
- **`sample_clustering_analysis.pdf`** - Distribución de muestras ALS vs Control por cluster
- **`snv_clustering_analysis.pdf`** - Distribución de SNVs por posición y región semilla por cluster

## Hallazgos Clave

### 📊 Clustering de Muestras
```
Cluster 1: ALS (266) + Control (102) = 368 muestras
Cluster 2: ALS (1) = 1 muestra
Cluster 3: ALS (46) = 46 muestras
```

**Interpretación:**
- **Cluster 1**: Muestras mixtas (ALS + Control) - posiblemente muestras con patrones similares
- **Cluster 2**: Muestra ALS única - posiblemente patrón atípico
- **Cluster 3**: Grupo de muestras ALS - posiblemente patrón específico de enfermedad

### 🧬 Clustering de SNVs
```
Cluster 1: Posición 2 (6 SNVs), Posición 4 (2 SNVs), Posición 5 (2 SNVs)
Cluster 2: Posición 2 (1 SNV), Posición 3 (1 SNV), Posición 5 (4 SNVs)
Cluster 3: Posición 5 (2 SNVs)
```

**Interpretación:**
- **Cluster 1**: SNVs distribuidos en múltiples posiciones (2, 4, 5)
- **Cluster 2**: Concentración en posición 5 con algunos en posiciones 2 y 3
- **Cluster 3**: Exclusivamente posición 5

### 🎯 Análisis de Familias de miRNAs

#### Familias Más Afectadas:
1. **let-7**: 8 SNVs totales
   - Posición 2: 4 SNVs
   - Posición 5: 3 SNVs
   - Posición 4: 1 SNV

2. **miR-1**: 5 SNVs totales
   - Posición 2: 2 SNVs
   - Posición 5: 2 SNVs
   - Posición 3: 1 SNV

3. **miR-423**: 3 SNVs totales
   - Posición 2: 1 SNV
   - Posición 4: 1 SNV
   - Posición 5: 1 SNV

### 📍 Análisis de Secuencias Conservadas

#### Posiciones Más Vulnerables:
1. **Posición 5**: 8 SNVs únicos, 8 miRNAs afectados, 5 familias
2. **Posición 2**: 7 SNVs únicos, 7 miRNAs afectados, 3 familias
3. **Posición 4**: 2 SNVs únicos, 2 miRNAs afectados, 2 familias
4. **Posición 3**: 1 SNV único, 1 miRNA afectado, 1 familia

## Patrones de Agrupamiento Identificados

### 🔍 Coincidencias entre Familias y Secuencias Conservadas

1. **Posición 5 como Hotspot Universal**:
   - Afecta múltiples familias (let-7, miR-1, miR-423, miR-486, miR-93)
   - Mayor diversidad de familias afectadas
   - Posiblemente secuencia conservada vulnerable

2. **Posición 2 como Vulnerabilidad Específica**:
   - Principalmente familias let-7 y miR-1
   - Patrón más específico de familias
   - Posiblemente secuencia conservada específica

3. **Clustering por Patrones de Vulnerabilidad**:
   - **Cluster 1**: Patrón generalizado (múltiples posiciones)
   - **Cluster 2**: Patrón concentrado (principalmente posición 5)
   - **Cluster 3**: Patrón específico (solo posición 5)

## Implicaciones Biológicas

### 🧬 Mecanismos de Oxidación
1. **Posición 5**: Hotspot universal - posiblemente secuencia altamente conservada y vulnerable
2. **Posición 2**: Vulnerabilidad específica - posiblemente secuencia conservada en familias específicas
3. **Familias let-7 y miR-1**: Más susceptibles a oxidación G>T

### 🎯 Significado Clínico
1. **Clustering de Muestras**: Diferentes patrones de enfermedad ALS
2. **Clustering de SNVs**: Diferentes mecanismos de vulnerabilidad
3. **Posiciones 2 y 5**: Objetivos prioritarios para terapias antioxidantes

## Conclusiones

1. **Clustering Jerárquico Exitoso**: Se identificaron patrones claros de agrupamiento tanto en muestras como en SNVs
2. **Posiciones Críticas**: Posiciones 2 y 5 son los principales hotspots de oxidación G>T
3. **Familias Vulnerables**: let-7 y miR-1 son las familias más afectadas
4. **Patrones de Enfermedad**: Diferentes clusters de muestras sugieren subtipos de ALS
5. **Mecanismos Conservados**: Las posiciones más afectadas probablemente corresponden a secuencias altamente conservadas

## Próximos Pasos

1. **Análisis Funcional**: Investigar las funciones de los miRNAs más afectados
2. **Validación Experimental**: Confirmar los patrones identificados experimentalmente
3. **Desarrollo Terapéutico**: Diseñar estrategias antioxidantes específicas para posiciones 2 y 5
4. **Análisis de Subtipos**: Investigar las diferencias entre clusters de muestras ALS

---

**Fecha de Análisis**: 29 de Septiembre, 2025  
**Datos Analizados**: 18 SNVs G>T × 415 muestras (313 ALS + 102 Control)  
**Filtros Aplicados**: VAF > 50% (representación)  
**Método de Clustering**: Ward.D2 (jerárquico)










