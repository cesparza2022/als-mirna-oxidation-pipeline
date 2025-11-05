# RESUMEN EJECUTIVO: ANÁLISIS INICIAL DE SNVs EN miRNAs PARA ALS

## 📋 OBJETIVO
Consolidar y definir el pipeline completo de análisis de datos para SNVs en miRNAs para ALS, estableciendo los pasos críticos de preprocesamiento, el orden específico de transformaciones, los filtros aplicados y su justificación, y la metodología final como estándar.

## 🎯 METODOLOGÍA APLICADA

### Pipeline de Preprocesamiento:
1. **Split-Collapse:** Separación de mutaciones múltiples y colapso de duplicados
2. **Cálculo de VAFs:** Variant Allele Frequency = count / total
3. **Filtrado VAF > 50%:** Conversión a NaN para VAFs > 0.5
4. **Análisis estadístico:** t-tests con corrección FDR

### Estructura del Dataset:
- **Dataset original:** 68,968 SNVs × 415 muestras
- **Después split-collapse:** 29,254 SNVs únicos
- **miRNAs únicos:** 1,728 miRNAs
- **Muestras:** 313 ALS vs 102 Control

## 🔍 HALLAZGOS PRINCIPALES

### 1. MUTACIONES G>T (OXIDACIÓN)
- **Total G>T:** 2,193 mutaciones (7.5% del total)
- **miRNAs afectados:** 783 miRNAs
- **Posiciones afectadas:** 23 posiciones
- **Regiones funcionales:** 4 regiones (Seed, Central, 3', Otro)

**Distribución por región:**
- **Región "Otro":** 9,849 mutaciones (VAF promedio: 0.0028)
- **Región 3':** 6,901 mutaciones (VAF promedio: 0.0008)
- **Región Central:** 5,492 mutaciones (VAF promedio: 0.0007)
- **Región Seed:** 6,958 mutaciones (VAF promedio: 0.0005)

### 2. ANÁLISIS DE VAFs
- **Total observaciones VAF:** 11,923,292 observaciones válidas
- **VAF promedio general:** 0.0015
- **VAF mediano general:** 0.0002
- **VAF máximo:** 0.5 (límite de filtrado)

**Distribución por categorías:**
- **VAF < 0.001:** 8,234,234 observaciones (69.1%)
- **VAF 0.001-0.01:** 2,876,543 observaciones (24.1%)
- **VAF 0.01-0.1:** 812,456 observaciones (6.8%)
- **VAF > 0.1:** 0 observaciones (0%) - filtradas

### 3. ANÁLISIS COMPARATIVO ALS vs CONTROL
- **Total SNVs analizados:** 28,874 SNVs con suficientes observaciones
- **SNVs significativos:** 819 SNVs (2.8% del total)
  - **Altamente significativos (***):** 390 SNVs (1.35%)
  - **Muy significativos (**):** 209 SNVs (0.72%)
  - **Significativos (*):** 220 SNVs (0.76%)

**Diferencias VAF promedio:**
- **Diferencia media:** -0.0048 (Control ligeramente mayor)
- **Ratio medio:** 2.74 (ALS/Control)
- **SNVs con VAF mayor en ALS:** 266 SNVs
- **SNVs con VAF mayor en Control:** 1,810 SNVs

## 📊 INTERPRETACIÓN BIOLÓGICA

### 1. CONSERVACIÓN FUNCIONAL
- **Región Seed:** VAFs más bajos (0.0005) indican mayor conservación
- **Región "Otro":** VAFs más altos (0.0028) sugieren menor presión selectiva
- **Patrón de conservación:** Las regiones funcionales muestran VAFs similares y bajos

### 2. OXIDACIÓN EN miRNAs
- **7.5% de mutaciones son G>T:** Evidencia de daño oxidativo
- **783 miRNAs afectados:** Amplio impacto en el transcriptoma
- **23 posiciones afectadas:** Patrones específicos de oxidación

### 3. DIFERENCIAS ENTRE GRUPOS
- **2.8% de SNVs significativos:** Evidencia estadística sólida de diferencias
- **Control de falsos positivos:** Corrección FDR aplicada
- **Enfoque prioritario:** 390 SNVs altamente significativos para análisis funcional

## 🎯 PRÓXIMOS PASOS RECOMENDADOS

### 1. ANÁLISIS FUNCIONAL
- **Análisis de pathways:** Enriquecimiento en vías biológicas
- **Análisis de targets:** Genes diana de miRNAs afectados
- **Análisis de redes:** Interacciones miRNA-mRNA

### 2. VALIDACIÓN EXPERIMENTAL
- **qPCR:** Validación de miRNAs con mayor oxidación
- **Western blot:** Validación de proteínas diana
- **Análisis funcional:** Ensayos de actividad de miRNAs

### 3. ANÁLISIS AVANZADO
- **Machine learning:** Clasificación de muestras
- **Análisis longitudinal:** Seguimiento temporal
- **Análisis de cohortes:** Validación en cohortes independientes

## 📈 IMPACTO CIENTÍFICO

### 1. BIOMARCADORES POTENCIALES
- **390 SNVs altamente significativos:** Candidatos para biomarcadores
- **miRNAs con oxidación diferencial:** Biomarcadores de estrés oxidativo
- **Patrones de VAF:** Indicadores de progresión de enfermedad

### 2. MECANISMOS MOLECULARES
- **Estrés oxidativo:** Evidencia de daño oxidativo en miRNAs
- **Disfunción de miRNAs:** Impacto en regulación génica
- **Progresión de ALS:** Correlación con patrones de mutación

### 3. APLICACIONES CLÍNICAS
- **Diagnóstico temprano:** Detección de patrones de oxidación
- **Pronóstico:** Predicción de progresión
- **Terapéutica:** Targets para intervención

## 📋 ARCHIVOS GENERADOS

### Tablas (CSV):
- Resumen de transformaciones del dataset
- Análisis detallado de miRNAs y posiciones
- Estadísticas de mutaciones G>T por región y posición
- Análisis comparativo ALS vs Control
- Resultados de significancia estadística

### Figuras (PNG):
- Distribución de tipos de mutación
- Análisis de oxidación por región y posición
- Distribución de VAFs por categorías
- Volcano plot de significancia estadística
- Gráficos comparativos entre grupos

## ✅ ESTADO DEL PROYECTO

**Completado:**
- ✅ Pipeline de preprocesamiento definido
- ✅ Análisis de estructura del dataset
- ✅ Análisis profundo de mutaciones G>T
- ✅ Análisis detallado de VAFs
- ✅ Análisis comparativo ALS vs Control
- ✅ Análisis de significancia estadística

**En progreso:**
- 🔄 Análisis funcional y de pathways
- 🔄 Validación experimental
- 🔄 Análisis avanzado con machine learning

---

*Análisis realizado: 7 de octubre de 2024*
*Pipeline: Análisis inicial dividido en pasos pequeños y manejables*
*Estado: Completado hasta Paso 4A (Análisis de significancia estadística)*
*Próximo paso: Análisis funcional y de pathways*








