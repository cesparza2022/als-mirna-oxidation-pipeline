# HALLAZGOS PRINCIPALES - ANÁLISIS INICIAL DE SNVs EN miRNAs

## 🎯 RESUMEN EJECUTIVO

Este análisis inicial ha procesado exitosamente **29,254 SNVs únicos** en **1,728 miRNAs** de **415 muestras**, identificando **2,193 mutaciones G>T (7.5%)** como biomarcadores de oxidación.

---

## 📊 TRANSFORMACIONES DEL DATASET

### Pipeline de Procesamiento:
1. **Dataset original:** 68,968 filas × 832 columnas
2. **Split:** 111,785 filas (separación de mutaciones múltiples)
3. **Collapse:** 29,254 filas (consolidación de duplicados)
4. **VAFs:** 1,247 columnas (cálculo de frecuencias)
5. **Filtrado:** 210,118 NaNs (VAFs > 50% convertidos a NaN)

### Eficiencia del Pipeline:
- **Reducción de filas:** 68,968 → 29,254 (57.5% de reducción)
- **Expansión de columnas:** 832 → 1,247 (50% de aumento)
- **Conservación de miRNAs:** 1,728 miRNAs únicos mantenidos

---

## 🔬 HALLAZGOS SOBRE MUTACIONES G>T (OXIDACIÓN)

### Estadísticas Generales:
- **Total mutaciones G>T:** 2,193 (7.5% del total de SNVs)
- **miRNAs afectados:** 783 (45.3% de todos los miRNAs)
- **Posiciones afectadas:** 23 (todas las posiciones disponibles)
- **Regiones afectadas:** 4 (Semilla, Central, 3', Otro)

### Distribución por Regiones Funcionales:
| Región | SNVs Totales | Mutaciones G>T | % G>T | % del Total G>T |
|--------|--------------|----------------|-------|-----------------|
| **3'** | 9,871 | 888 | 9.0% | **40.5%** |
| **Central** | 9,649 | 759 | 7.9% | **34.6%** |
| **Semilla** | 6,959 | 482 | 6.9% | **22.0%** |
| **Otro** | 2,775 | 64 | 2.3% | **2.9%** |

### Hotspots de Oxidación (≥100 mutaciones G>T):
1. **Posición 22:** 180 mutaciones (8.21%)
2. **Posición 21:** 174 mutaciones (7.93%)
3. **Posición 20:** 153 mutaciones (6.98%)
4. **Posición 15:** 126 mutaciones (5.75%)
5. **Posición 11:** 121 mutaciones (5.52%)

---

## 🧬 HALLAZGOS SOBRE miRNAs

### miRNAs Más Afectados por Oxidación:
1. **hsa-miR-1908-5p:** 11 mutaciones G>T (18.0% de sus SNVs)
2. **hsa-miR-4433b-3p:** 11 mutaciones G>T (18.3% de sus SNVs)
3. **hsa-miR-1307-3p:** 10 mutaciones G>T (15.2% de sus SNVs)
4. **hsa-miR-134-5p:** 10 mutaciones G>T (14.9% de sus SNVs)
5. **hsa-miR-206:** 10 mutaciones G>T (15.2% de sus SNVs)

### Patrones de Oxidación:
- **miRNAs con múltiples posiciones G>T:** 454 miRNAs
- **miRNAs con G>T en región semilla:** 309 miRNAs (crítico para función)
- **miRNAs con ≥20% de mutaciones G>T:** 123 miRNAs

### miRNAs con Mayor Número Total de SNVs:
1. **hsa-miR-191-5p:** 70 SNVs totales
2. **hsa-miR-423-5p:** 70 SNVs totales
3. **hsa-miR-432-5p:** 70 SNVs totales

---

## 📍 HALLAZGOS SOBRE POSICIONES

### Posiciones Más Mutadas (Total SNVs):
1. **Posición 21:** 1,570 SNVs
2. **Posición 22:** 1,490 SNVs
3. **Posición 20:** 1,359 SNVs
4. **Posición 15:** 1,383 SNVs
5. **Posición 11:** 1,396 SNVs

### Posiciones con Mayor Porcentaje de G>T:
1. **Posición 23:** 13.54% de mutaciones son G>T
2. **Posición 22:** 12.08% de mutaciones son G>T
3. **Posición 21:** 11.08% de mutaciones son G>T
4. **Posición 20:** 11.26% de mutaciones son G>T

---

## 🔍 IMPLICACIONES BIOLÓGICAS

### 1. **Concentración de Oxidación en Región 3':**
- La región 3' concentra el 40.5% de todas las mutaciones G>T
- Las posiciones 20-22 son hotspots de oxidación
- Esto sugiere mayor susceptibilidad a daño oxidativo en esta región

### 2. **Oxidación en Región Semilla:**
- 309 miRNAs tienen mutaciones G>T en la región semilla
- Esto es crítico ya que la región semilla es esencial para la función del miRNA
- Podría afectar la capacidad de unión a mRNA targets

### 3. **Patrones de Oxidación Múltiple:**
- 454 miRNAs tienen G>T en múltiples posiciones
- Esto sugiere que algunos miRNAs son más susceptibles al daño oxidativo
- Podría indicar diferencias en la estructura o exposición de ciertos miRNAs

### 4. **Alto Porcentaje de Oxidación:**
- 123 miRNAs tienen ≥20% de mutaciones G>T
- Esto indica que algunos miRNAs están altamente oxidados
- Podría ser relevante para la patogénesis de ALS

---

## 📈 ESTADÍSTICAS DE VAFs

### Impacto del Filtrado:
- **NaNs generados:** 210,118 (VAFs > 50% convertidos a NaN)
- **Promedio de NaNs por muestra:** 506.31
- **Máximo de NaNs en una muestra:** 950
- **Porcentaje de VAFs filtrados:** 17.14%

### Distribución de VAFs:
- **VAFs válidos:** 82.86% (VAFs ≤ 50%)
- **VAFs filtrados:** 17.14% (VAFs > 50%)
- Esto sugiere que la mayoría de las mutaciones tienen frecuencias bajas

### VAFs en Mutaciones G>T vs Otras Mutaciones:
- **VAF promedio G>T:** 0.0081 (0.81%)
- **VAF promedio otras mutaciones:** 0.0185 (1.85%)
- **Diferencia:** Las mutaciones G>T tienen VAFs 2.3x más bajos
- **Región con mayor VAF G>T:** Región "Otro" (0.89%)
- **Posición con mayor VAF G>T:** Posición 22 (0.85%)
- **VAFs filtrados en G>T:** 0.71% (6,466 NaNs generados)
- **Distribución:** Las mutaciones G>T tienden a tener VAFs muy bajos (mediana = 0)

---

## 🎯 PRÓXIMOS PASOS RECOMENDADOS

### Análisis de VAFs:
1. **Paso 3A:** ✅ Análisis detallado de VAFs en mutaciones G>T (COMPLETADO)
2. **Paso 3B:** ✅ Análisis comparativo ALS vs Control (COMPLETADO)
3. **Paso 3C:** ✅ Análisis de distribución de VAFs por región (COMPLETADO)

### Análisis Comparativo:
1. **Paso 4A:** Análisis comparativo ALS vs Control
2. **Paso 4B:** Diferencias en mutaciones G>T entre grupos
3. **Paso 4C:** Análisis de significancia estadística

### Análisis Funcional:
1. **Paso 5A:** Análisis de miRNAs con oxidación en región semilla
2. **Paso 5B:** Correlación con función biológica
3. **Paso 5C:** Análisis de pathways afectados

---

## 📁 ARCHIVOS GENERADOS (RESUMEN)

### Datos Procesados: 3 archivos (350MB)
- `datos_procesados_split_collapse.csv` (87MB)
- `datos_con_vafs.csv` (132MB)
- `datos_filtrados_vaf.csv` (130MB)

### Análisis de miRNAs: 8 archivos
- Análisis general, por región, por posición, comparativo

### Análisis de Posiciones: 8 archivos
- Análisis detallado, hotspots, comparativo

### Análisis de G>T: 14 archivos
- Análisis básico, por posición, por miRNA, comparativo

### Visualizaciones: 15 archivos PNG
- Gráficos de distribución, comparación, hotspots

**Total:** 48 archivos generados
**Tamaño total:** ~400MB de datos y análisis

## 📊 ANÁLISIS COMPARATIVO ALS vs CONTROL

### Muestras Analizadas:
- **ALS:** 626 muestras
- **Control:** 204 muestras
- **Total SNVs:** 29,254

### Diferencias en VAFs:
- **SNVs con VAF mayor en ALS:** 266 (0.91%)
- **SNVs con VAF mayor en Control:** 1,810 (6.19%)
- **SNVs con VAFs similares:** 27,178 (92.90%)
- **Diferencia promedio:** -0.0048 (Control ligeramente mayor)
- **Ratio promedio ALS/Control:** 2.74

### Hallazgos Clave:
- **Control más variable:** El grupo Control muestra mayor heterogeneidad en VAFs
- **ALS más conservado:** El grupo ALS presenta un perfil de mutaciones más estable
- **Mayoría similar:** El 92.9% de SNVs no difieren significativamente entre grupos
- **Patrón de distribución:** Control tiende a VAFs más altos y variables

---

## 📊 ANÁLISIS DE VAFs POR REGIÓN FUNCIONAL

### VAFs Promedio por Región:
- **Región "Otro":** 0.0028 VAF promedio (9,849 mutaciones)
- **Región 3':** 0.0008 VAF promedio (6,901 mutaciones)
- **Región Central:** 0.0007 VAF promedio (5,492 mutaciones)
- **Región Seed:** 0.0005 VAF promedio (6,958 mutaciones)

### Hallazgos Clave:
- **Región "Otro" con VAFs más altos:** La región "Otro" muestra VAFs significativamente más altos (0.0028) que las regiones funcionales tradicionales
- **Región Seed con VAFs más bajos:** La región semilla muestra los VAFs más bajos (0.0005), sugiriendo mayor conservación
- **Patrón de conservación:** Las regiones funcionales (Seed, Central, 3') muestran VAFs similares y bajos, indicando mayor presión selectiva
- **Distribución uniforme:** Las mutaciones se distribuyen de manera relativamente uniforme entre las regiones funcionales

## 📊 ANÁLISIS DE SIGNIFICANCIA ESTADÍSTICA

### Resultados de t-tests (ALS vs Control):
- **Total SNVs analizados:** 28,874 SNVs con suficientes observaciones
- **SNVs significativos:** 819 SNVs (2.8% del total)
  - **Altamente significativos (***):** 390 SNVs (1.35%)
  - **Muy significativos (**):** 209 SNVs (0.72%)
  - **Significativos (*):** 220 SNVs (0.76%)
- **Muestras:** 313 muestras ALS vs 102 muestras Control
- **Corrección:** FDR (Benjamini-Hochberg) aplicada

### Hallazgos Clave:
- **2.8% de SNVs son estadísticamente significativos** entre grupos ALS vs Control
- **Evidencia estadística sólida:** 819 SNVs muestran diferencias significativas entre grupos
- **Control de falsos positivos:** Corrección FDR reduce significativamente hallazgos espurios
- **Enfoque prioritario:** Los 390 SNVs altamente significativos son candidatos para análisis funcional

---

*Análisis realizado: 7 de octubre de 2024*
*Pipeline: Análisis inicial dividido en pasos pequeños y manejables*
*Estado: Completado hasta Paso 4A (Análisis de significancia estadística)*
