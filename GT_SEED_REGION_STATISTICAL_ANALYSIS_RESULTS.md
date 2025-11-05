# ANÁLISIS ESTADÍSTICO DE SNVs G>T EN REGIÓN SEMILLA
## miRNAs y Oxidación - Análisis ALS

**Fecha:** $(date)  
**Pipeline:** Split → Collapse → Filtro VAF (50%) → Análisis Estadístico G>T Semilla  
**Datos:** 328 SNVs G>T en región semilla (posiciones 2-8)

---

## 📊 **RESUMEN EJECUTIVO**

### **Datos Analizados:**
- **SNVs G>T en región semilla:** 328
- **miRNAs únicos:** 212
- **Posiciones analizadas:** 7 (posiciones 2-8)
- **Muestras:** 415
- **Matriz VAF:** 328 x 415

### **Métricas Clave:**
- **VAF promedio general:** 0.0042 (0.42%)
- **VAF mediano general:** 0
- **VAF máximo:** 1.0 (100%)
- **Valores VAF > 0:** 10,298 (de 136,120 total)
- **Valores VAF > 0.1:** 1,201 (11.66% de valores positivos)
- **Valores VAF > 0.5:** 193 (1.87% de valores positivos)

---

## 🧬 **ESTADÍSTICAS POR POSICIÓN EN REGIÓN SEMILLA**

| Posición | SNVs | VAF Promedio | VAF Mediano | Observaciones |
|----------|------|--------------|-------------|---------------|
| **2** | 33 | 0.0002 | 0 | VAF muy bajo |
| **3** | 19 | 0.0007 | 0.0001 | VAF muy bajo |
| **4** | 29 | 0.0179 | 0 | VAF moderado |
| **5** | 39 | **0.0764** | 0 | **VAF alto** |
| **6** | 69 | **0.131** | 0.0004 | **VAF más alto** |
| **7** | 67 | 0.0113 | 0.0003 | VAF moderado |
| **8** | 72 | 0.0028 | 0.0001 | VAF bajo |

### **🔍 Hallazgos Clave por Posición:**
- **Posición 6:** Mayor VAF promedio (0.131) y mayor número de SNVs (69)
- **Posición 5:** Segundo VAF más alto (0.0764) con 39 SNVs
- **Posiciones 2-3:** VAF muy bajos, posiblemente menos propensos a mutación G>T
- **Posición 8:** Mayor número de SNVs (72) pero VAF bajo (0.0028)

---

## 🧬 **TOP 15 miRNAs CON MÁS SNVs G>T EN REGIÓN SEMILLA**

| miRNA | SNVs | Posiciones | VAF Promedio | Observaciones |
|-------|------|------------|--------------|---------------|
| **hsa-miR-423-5p** | 5 | 2,4,5,6,7 | 0.0001 | Mayor diversidad posicional |
| **hsa-miR-744-5p** | 5 | 2,4,5,6,7 | 0.0001 | Mayor diversidad posicional |
| **hsa-let-7a-5p** | 4 | 2,4,5,8 | 0 | Familia let-7, VAF muy bajo |
| **hsa-let-7b-5p** | 4 | 2,4,5,8 | 0 | Familia let-7, VAF muy bajo |
| **hsa-let-7d-5p** | 4 | 2,4,5,8 | 0 | Familia let-7, VAF muy bajo |
| **hsa-let-7e-5p** | 4 | 2,4,5,8 | 0 | Familia let-7, VAF muy bajo |
| **hsa-let-7f-5p** | 4 | 2,4,5,8 | 0 | Familia let-7, VAF muy bajo |
| **hsa-let-7g-5p** | 4 | 2,4,5,8 | 0 | Familia let-7, VAF muy bajo |
| **hsa-let-7i-5p** | 4 | 2,4,5,8 | 0 | Familia let-7, VAF muy bajo |
| **hsa-miR-122-5p** | 4 | 2,3,5,7 | 0 | VAF muy bajo |
| **hsa-miR-185-5p** | 4 | 2,3,5,7 | 0 | VAF muy bajo |
| **hsa-let-7c-5p** | 3 | 2,4,8 | 0 | Familia let-7, VAF muy bajo |
| **hsa-miR-1-3p** | 3 | 2,3,7 | 0.0001 | VAF muy bajo |
| **hsa-miR-11400** | 3 | 3,4,7 | 0 | VAF muy bajo |
| **hsa-miR-1307-3p** | 3 | 5,6,8 | 0 | VAF muy bajo |

### **🔍 Observaciones Importantes:**
- **Familia let-7:** Dominante en el top 15, pero con VAF muy bajos (0)
- **miR-423-5p y miR-744-5p:** Mayor diversidad posicional (5 posiciones diferentes)
- **VAF general muy bajo:** La mayoría de miRNAs tienen VAF promedio de 0

---

## 📈 **DISTRIBUCIÓN DE VAF**

### **Distribución General:**
- **VAF = 0:** 125,822 valores (92.4% del total)
- **VAF > 0:** 10,298 valores (7.6% del total)
- **VAF > 0.1:** 1,201 valores (11.66% de valores positivos)
- **VAF > 0.5:** 193 valores (1.87% de valores positivos)
- **VAF > 0.8:** 75 valores (0.73% de valores positivos)

### **Interpretación:**
- **Mayoría de VAF = 0:** Indica que la mayoría de SNVs G>T en región semilla no están presentes en la mayoría de muestras
- **VAF > 0.1 (11.66%):** Proporción significativa de SNVs con VAF moderado
- **VAF > 0.5 (1.87%):** Pequeña proporción de SNVs con VAF alto, posiblemente importantes

---

## 🔥 **VISUALIZACIONES GENERADAS**

### **1. Heatmap de VAF (gt_seed_region_vaf_heatmap.pdf)**
- **Contenido:** Top 20 miRNAs con más SNVs G>T en región semilla
- **Dimensiones:** 328 SNVs x 415 muestras
- **Anotaciones:** Posición en región semilla (2-8)
- **Clustering:** Jerárquico por filas y columnas
- **Escala de colores:** Blanco (VAF=0) → Amarillo → Naranja → Rojo (VAF=1)

### **2. Distribución de VAF (gt_seed_region_vaf_distribution.pdf)**
- **Panel 1:** Histograma de distribución de VAF
- **Panel 2:** Boxplot de VAF por posición en región semilla
- **Información:** Distribución general y comparación entre posiciones

---

## 🎯 **CONCLUSIONES PRINCIPALES**

### **1. Patrones de Mutación G>T en Región Semilla:**
- **Posiciones 5 y 6:** VAF más altos (0.0764 y 0.131 respectivamente)
- **Posiciones 2-3:** VAF muy bajos, menos propensos a mutación G>T
- **Posición 8:** Mayor número de SNVs pero VAF bajo

### **2. miRNAs Más Afectados:**
- **Familia let-7:** Dominante en número de SNVs pero con VAF muy bajos
- **miR-423-5p y miR-744-5p:** Mayor diversidad posicional
- **VAF general muy bajo:** Sugiere que las mutaciones G>T en región semilla son raras

### **3. Implicaciones Biológicas:**
- **Región semilla crítica:** Las posiciones 5-6 muestran mayor susceptibilidad a mutación G>T
- **Impacto funcional:** VAF bajos sugieren que las mutaciones G>T en región semilla pueden ser deletéreas
- **Patrones específicos:** Diferentes miRNAs muestran diferentes patrones de mutación

### **4. Próximos Pasos Sugeridos:**
- **Análisis funcional:** Evaluar impacto de mutaciones G>T en posiciones 5-6
- **Comparación con controles:** Analizar si estos patrones son específicos de ALS
- **Validación experimental:** Confirmar impacto funcional de mutaciones G>T en región semilla

---

## 📁 **ARCHIVOS GENERADOS**

- **outputs/gt_seed_region_vaf_heatmap.pdf:** Heatmap de VAF con clustering
- **outputs/gt_seed_region_vaf_distribution.pdf:** Distribución de VAF por posición
- **R/statistical_analysis_gt_seed_region.R:** Script de análisis estadístico

---

**✅ ANÁLISIS ESTADÍSTICO COMPLETADO EXITOSAMENTE**










