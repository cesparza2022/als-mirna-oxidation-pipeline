# RESUMEN DEL ANÁLISIS INICIAL DEL DATASET

## 📊 **RESULTADOS PRINCIPALES**

### **1. ESTRUCTURA DEL DATASET**
- **SNVs originales:** 68,968
- **SNVs después split-collapse:** 29,254 (reducción del 57.6%)
- **miRNAs únicos:** 1,728
- **Muestras:** 830 (415 columnas de cuentas + 415 columnas de totales)
- **Total de columnas:** 832

### **2. MUTACIONES G>T (BIOMARCADORES DE DAÑO OXIDATIVO)**
- **Total SNVs G>T:** 2,193
- **Porcentaje de mutaciones G>T:** 7.5%
- **miRNAs con mutaciones G>T:** 783 (45.3% de todos los miRNAs)

### **3. VARIANT ALLELE FREQUENCIES (VAFs)**
- **VAF promedio:** 1.77%
- **VAF mediana:** 0%
- **VAF máximo:** 100%
- **VAF mínimo:** 0%
- **Desviación estándar:** 12.52%

### **4. FILTRADO VAF > 50%**
- **Total VAFs calculadas:** 1,225,980
- **VAFs filtradas (>50%):** 210,118 (17.14%)
- **VAFs restantes (≤50%):** 1,015,862 (82.86%)
- **NaNs generados:** 210,118
- **Promedio de NaNs por muestra:** 506.31

### **5. DISTRIBUCIÓN POR REGIONES**
- **Región No-semilla:** 20,709 SNVs (70.79%)
- **Región Semilla (posiciones 2-8):** 6,959 SNVs (23.79%)
- **Posiciones no identificadas:** 1,586 SNVs (5.42%)

## 📈 **FIGURAS GENERADAS**

### **1. `01_snvs_por_mirna.png`**
- **Descripción:** Top 20 miRNAs con más SNVs
- **Insight:** Identifica los miRNAs más mutados en el dataset

### **2. `02_posiciones_mas_mutadas.png`**
- **Descripción:** Top 20 posiciones más mutadas en miRNAs
- **Insight:** Muestra qué posiciones en los miRNAs son más propensas a mutaciones

### **3. `03_gt_por_mirna.png`**
- **Descripción:** Top 20 miRNAs con más mutaciones G>T
- **Insight:** Identifica miRNAs con mayor daño oxidativo

### **4. `04_distribucion_vafs.png`**
- **Descripción:** Distribución de VAFs con línea de corte en 50%
- **Insight:** Muestra la distribución de frecuencias alélicas y el impacto del filtrado

### **5. `05_snvs_por_region.png`**
- **Descripción:** Distribución de SNVs por región (semilla vs no-semilla)
- **Insight:** Compara la mutabilidad entre regiones funcionalmente importantes

## 📋 **TABLAS GENERADAS**

### **1. `01_resumen_general_dataset.csv`**
- Resumen estadístico general del dataset

### **2. `02_estadisticas_GT.csv`**
- Estadísticas específicas de mutaciones G>T

### **3. `03_estadisticas_vaf.csv`**
- Estadísticas descriptivas de las VAFs

### **4. `04_estadisticas_filtrado.csv`**
- Impacto del filtrado VAF > 50%

### **5. `05_estadisticas_regiones.csv`**
- Distribución de SNVs por regiones funcionales

## 🔍 **INSIGHTS CLAVE**

### **1. EFECTO DEL SPLIT-COLLAPSE**
- Reducción significativa de SNVs (57.6%) indica que había muchas mutaciones múltiples
- El proceso de separación y colapso fue efectivo para limpiar el dataset

### **2. MUTACIONES G>T**
- 7.5% de mutaciones G>T es un porcentaje significativo
- 783 miRNAs afectados sugiere daño oxidativo generalizado
- Importante para estudios de estrés oxidativo en ALS

### **3. DISTRIBUCIÓN DE VAFs**
- VAF promedio baja (1.77%) indica mutaciones raras
- 17.14% de VAFs > 50% sugiere posibles artefactos o mutaciones somáticas

### **4. REGIONES FUNCIONALES**
- 23.79% de SNVs en región semilla es significativo
- Las mutaciones en semilla pueden afectar la función del miRNA
- Importante para análisis funcional

## 🎯 **PRÓXIMOS PASOS RECOMENDADOS**

1. **Análisis comparativo ALS vs Control**
2. **Análisis de enriquecimiento de vías**
3. **Análisis de clustering jerárquico**
4. **Análisis de componentes principales (PCA)**
5. **Análisis estadístico (t-tests, GLMM)**

## 📁 **ARCHIVOS GENERADOS**

- **Figuras:** 5 archivos PNG en `figures/`
- **Tablas:** 5 archivos CSV en `tables/`
- **Scripts:** Funciones modulares en `functions_pipeline.R`
- **Configuración:** Parámetros centralizados en `config_pipeline.R`

---
*Análisis generado el: 2024-10-07*
*Pipeline: Análisis inicial de SNVs en miRNAs para ALS*








