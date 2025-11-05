# ESTADO ACTUAL DEL PROYECTO - ANÁLISIS SNVs G>T EN miRNAs PARA ALS

## 📅 **ÚLTIMA ACTUALIZACIÓN**
**Fecha:** 8 de octubre de 2025
**Fase:** Análisis Inicial Exploratorio
**Estado:** Paso 5A completado - Preparando Paso 6 (Integración de metadatos)

---

## 📊 **DATASET ACTUAL - CON QUÉ TRABAJAMOS**

### **Dataset Final: `filtered_data`**
```
Dimensiones: 29,254 SNVs únicos × 1,247 columnas × 415 muestras
├── SNVs: 29,254 (reducidos de 68,968 originales por split-collapse)
├── miRNAs: 1,728 únicos
├── Muestras: 415 (313 ALS, 102 Control)
└── Mutaciones G>T: 2,193 (7.5% del total)
```

### **Estructura de Columnas:**
```
1,247 columnas totales:
├── Metadata: 2 (miRNA name, pos:mut)
├── Counts: ~415 (conteos de SNVs por muestra)
├── Totales: ~415 (totales de miRNA, NO MODIFICADOS)
└── VAFs: ~415 (frecuencias alélicas calculadas)
    └── Con NaNs: 210,118 (VAF > 50% filtrados)
```

### **Filtros Aplicados (MUY PERMISIVOS):**
```
✅ Q33 (Phred ≥ 33) - Error < 0.05% (pre-aplicado)
✅ Split-collapse - Reorganización (NO elimina datos)
✅ VAF > 50% → NaN - Único filtro real (210,118 valores)

❌ NO aplicados:
   - Counts mínimos
   - Totales mínimos
   - VAF mínimo
   - Filtro de prevalencia
   - Eliminación de outliers
```

---

## ✅ **PASOS COMPLETADOS**

### **FASE 1: EXPLORACIÓN INICIAL DEL DATASET**

#### **Paso 1: Estructura y Transformaciones** ✅
- **1A:** Carga, split-collapse, VAFs, filtrado
  - 68,968 → 29,254 SNVs (reorganización)
  - 832 → 1,247 columnas (añadir VAFs)
  
- **1B:** Análisis de miRNAs
  - 1,728 miRNAs únicos
  - hsa-miR-191-5p con más SNVs (70)
  - hsa-miR-1908-5p con más G>T (11)
  
- **1C:** Análisis de posiciones
  - 23 posiciones totales
  - Posición 21 más mutada (1,570 SNVs)
  - Posición 22 con más G>T (180)

#### **Paso 2: Análisis Profundo de Oxidación (G>T)** ✅
- **2A:** Estadísticas generales
  - 2,193 mutaciones G>T (7.5%)
  - 783 miRNAs con G>T
  - Región 3' más afectada (40.5%)
  
- **2B:** Análisis por posición
  - Hotspots: posiciones 22, 21, 20
  - 11 posiciones con ≥100 G>T
  
- **2C:** Análisis por miRNA
  - 454 miRNAs con G>T en múltiples posiciones
  - 309 miRNAs con G>T en región semilla
  - 123 miRNAs con ≥20% G>T

#### **Paso 3: Análisis de VAFs** ✅
- **3A:** VAFs en G>T
  - VAF promedio G>T: 0.81%
  - VAF promedio otras: 1.85%
  - G>T tienen VAFs más bajos
  
- **3B:** Comparativo ALS vs Control
  - 266 SNVs con VAF mayor en ALS
  - 1,810 SNVs con VAF mayor en Control
  - Control tiene VAFs ligeramente superiores
  
- **3C:** VAFs por región
  - Región "Otro": VAF más alto (0.28%)
  - Región Seed: VAF más bajo (0.05%)

#### **Paso 4: Análisis Estadístico Inicial** ✅
- **4A:** Significancia estadística
  - 819 SNVs significativos (2.8%)
  - 390 altamente significativos (***)
  - t-tests + corrección FDR

#### **Paso 5: Evaluación de Calidad (QC Estadístico)** ✅
- **5A:** Outliers en muestras
  - 84 outliers identificados (20.2%)
  - 0 outliers severos (≥2 criterios)
  - Impacto: 31.88% de G>T afectados
  - **Región semilla: 24.9% de G>T solo en outliers**
  - **DECISIÓN: MANTENER outliers**

---

## 📂 **ORGANIZACIÓN DE ARCHIVOS**

### **Estructura de Directorios:**
```
pipeline_definitivo/
├── config_pipeline.R (configuración centralizada)
└── 01_analisis_inicial/
    ├── functions_pipeline.R (funciones del pipeline)
    ├── run_initial_analysis.R (script maestro)
    │
    ├── SCRIPTS DE ANÁLISIS:
    ├── paso1a_cargar_datos.R
    ├── paso1b_analisis_mirnas.R
    ├── paso1c_analisis_posiciones.R
    ├── paso2a_analisis_gt_basico.R
    ├── paso2b_analisis_gt_por_posicion.R
    ├── paso2c_analisis_mirnas_oxidacion.R
    ├── paso3a_analisis_vafs_gt_final.R
    ├── paso3b_analisis_comparativo_als_control.R
    ├── paso3c_analisis_vafs_por_region.R
    ├── paso4a_analisis_significancia_estadistica.R
    ├── paso5a_outliers_muestras.R
    └── paso5a_profundizar_outliers_gt.R
    │
    ├── DOCUMENTACIÓN:
    ├── RESUMEN_PASOS_COMPLETADOS.md (⭐ resumen de progreso)
    ├── HALLAZGOS_PRINCIPALES.md (hallazgos clave)
    ├── RESUMEN_EJECUTIVO_ANALISIS_INICIAL.md
    ├── RESUMEN_PASO5A_OUTLIERS.md
    ├── FILTROS_APLICADOS.md
    ├── PIPELINE_VISUAL.md
    ├── PLAN_PASOS_SIGUIENTES.md
    ├── EXPLICACION_OUTLIERS.md
    └── ESTADO_ACTUAL_PROYECTO.md (este archivo)
    │
    ├── outputs/ (tablas CSV)
    │   ├── paso1a_cargar_datos/
    │   ├── paso1b_analisis_mirnas/
    │   ├── paso1c_analisis_posiciones/
    │   ├── paso2a_analisis_gt/
    │   ├── paso2b_gt_por_posicion/
    │   ├── paso2c_mirnas_oxidacion/
    │   ├── paso3a_vafs_gt/
    │   ├── paso3b_als_control/
    │   ├── paso3c_vafs_region/
    │   ├── paso4a_significancia_estadistica/
    │   ├── paso5a_outliers_muestras/
    │   └── paso5a_profundizar_outliers/
    │
    └── figures/ (figuras PNG)
        ├── paso1b_analisis_mirnas/
        ├── paso1c_analisis_posiciones/
        ├── paso2a_analisis_gt/
        ├── paso2b_gt_por_posicion/
        ├── paso2c_mirnas_oxidacion/
        ├── paso3a_vafs_gt/
        ├── paso3b_als_control/
        ├── paso3c_vafs_region/
        ├── paso4a_significancia_estadistica/
        ├── paso5a_outliers_muestras/
        └── paso5a_profundizar_outliers/
```

### **Archivos Generados (Total):**
```
Total: ~100+ archivos
├── Tablas CSV: ~60 archivos
├── Figuras PNG: ~30 archivos
└── Documentación MD: ~10 archivos
```

---

## 🎯 **HALLAZGOS PRINCIPALES HASTA AHORA**

### **1. Mutaciones G>T (Oxidación):**
- **Total:** 2,193 mutaciones (7.5% de todos los SNVs)
- **Distribución por región:**
  - Región 3': 888 (40.5%)
  - Región Central: 759 (34.6%)
  - **Región Semilla: 397 (18.1%)** ⭐
  - Otra: 64 (2.9%)

### **2. Región Semilla (Crítica):**
- **397 mutaciones G>T** en posiciones 1-7
- **Posición 6:** 97 mutaciones (la más crítica para función)
- **Top miRNAs afectados en pos 6:**
  - hsa-miR-16-5p (406 muestras)
  - hsa-miR-423-5p (286 muestras)
  - hsa-miR-191-5p (212 muestras)

### **3. Significancia Estadística:**
- **819 SNVs significativos** entre ALS vs Control (2.8%)
- **390 altamente significativos** (p < 0.001)
- Corrección FDR aplicada

### **4. Outliers (Paso 5A):**
- **84 muestras outliers** (20.2%)
- **0 outliers severos** (ninguno cumple ≥2 criterios)
- **Impacto en G>T:**
  - 280 G>T solo en outliers (12.77%)
  - 99 G>T en semilla solo en outliers (24.9%) ⚠️
  - **DECISIÓN: MANTENER outliers**

---

## 📋 **PLAN COMPLETO DE PASOS**

### **✅ COMPLETADOS (Pasos 1-5A):**

```
Paso 1: Estructura del Dataset
├─ 1A: Carga y transformaciones ✅
├─ 1B: Análisis de miRNAs ✅
└─ 1C: Análisis de posiciones ✅

Paso 2: Análisis de Oxidación (G>T)
├─ 2A: Estadísticas generales ✅
├─ 2B: Análisis por posición ✅
└─ 2C: Análisis por miRNA ✅

Paso 3: Análisis de VAFs
├─ 3A: VAFs en G>T ✅
├─ 3B: Comparativo ALS vs Control ✅
└─ 3C: VAFs por región ✅

Paso 4: Análisis Estadístico
└─ 4A: t-tests y FDR ✅

Paso 5: QC Estadístico (sin eliminar datos)
└─ 5A: Outliers en muestras ✅
    ├─ Identificación (4 criterios)
    ├─ Impacto en G>T
    └─ Análisis profundo de región semilla
```

### **⏸️ SIGUIENTE: Paso 6 - Integración de Metadatos**

```
Paso 6: Integración de Metadatos Clínicos
├─ 6A: Preparación de metadatos ⏳ SIGUIENTE
│   ├─ Cargar GSE168714 metadata
│   ├─ Mapear IDs (SRR → BLT/BUH/UCH/TST)
│   ├─ Limpiar y estandarizar
│   └─ Vincular con dataset actual
│
├─ 6B: Análisis exploratorio de metadatos ⏳
│   ├─ Distribuciones de variables clínicas
│   ├─ Correlaciones
│   └─ Balance ALS vs Control por subgrupo
│
└─ 6C: Caracterización de outliers con metadatos ⏳
    ├─ ¿Outliers son Bulbar vs Non-bulbar?
    ├─ ¿Outliers tienen mayor severidad (ALSFRS)?
    ├─ ¿Outliers tienen progresión diferente (slope)?
    └─ Validación biológica de outliers
```

### **🔜 PENDIENTES (Pasos 7-10):**

```
Paso 7: Análisis por Subgrupos Clínicos
├─ 7A: Bulbar vs Non-bulbar
├─ 7B: Por severidad (ALSFRS)
├─ 7C: Por velocidad de progresión (slope)
└─ 7D: Temporal (Enrolment vs Longitudinal)

Paso 8: Análisis de Biomarcadores
├─ 8A: miR-181 (biomarcador del paper)
├─ 8B: G>T como biomarcador de oxidación
└─ 8C: Combinaciones de biomarcadores

Paso 9: Análisis de Supervivencia
├─ 9A: Kaplan-Meier
├─ 9B: Cox regression
└─ 9C: G>T y supervivencia

Paso 10: Modelos Multivariados
├─ 10A: GLMM (control de confusores)
├─ 10B: Corrección de batch effects (si necesario)
└─ 10C: Modelos predictivos
```

---

## 📚 **METADATOS DISPONIBLES**

### **Archivos de Metadatos:**
```
1. sample_metadata.csv
   └─ cohort, sex, batch, timepoint, site

2. GSE168714_All_samples_enrolment.txt
   └─ Onset, Riluzole, sex, batch

3. GSE168714_Data_file_related_to_fig_2_3_5_discovery.csv
   └─ Variables clínicas completas (supervivencia, severidad, etc.)
```

### **Variables Clínicas Disponibles:**
```
Demográficas:
├─ sex (M/F)
├─ Age_at_onset
└─ Age_enrolment

Clínicas:
├─ onset (Bulbar/Non-bulbar) 🔥
├─ ALSFRS (severidad) 🔥
├─ slope (velocidad progresión) 🔥
├─ FVC (capacidad pulmonar)
├─ cognitive (estado cognitivo)
└─ C9ORF72 (genética)

Técnicas:
├─ batch (SRR ID)
└─ timepoint (Enrolment/Longitudinal)

Supervivencia:
├─ survival_enrolment 🔥
├─ status (vivo/fallecido) 🔥
└─ miR_181_numeric (biomarcador) 🔥
```

---

## 🔥 **HALLAZGOS CRÍTICOS SOBRE OUTLIERS**

### **Impacto en Mutaciones G>T:**
```
Si eliminamos 84 outliers:

Total G>T: 2,193
├─ Pérdida directa: 280 (12.77%)
├─ Pérdida de potencia: 419 (19.11%)
└─ Total afectado: 699 (31.88%) ⚠️

Región SEMILLA: 397 G>T
├─ Solo en outliers: 99 (24.9%) ⚠️⚠️ MÁS AFECTADA
├─ Mayormente en outliers: 166 (41.8%)
└─ Preservados: 232 (58.4%)

Posición 6 (crítica): 97 G>T
├─ Solo en outliers: 17 (17.5%)
└─ Preservados: 80 (82.5%) ✅
```

### **Características de Outliers:**
```
84 muestras (20.2% del total)
├─ ALS: 69 (22.0%)
├─ Control: 15 (14.7%)
└─ Outliers severos: 0 (ninguno cumple ≥2 criterios) ✅

Distribución por criterio:
├─ Counts totales: 42 (21 bajos, 21 altos)
├─ Totales promedio: 42 (21 bajos, 21 altos)
├─ PCA: 21 (TODAS ALS)
└─ VAFs promedio: 42 (21 bajos, 21 altos)
```

### **Decisión Tomada:**
✅ **MANTENER todos los 84 outliers**

**Razones:**
1. Ninguno es outlier severo (0 con ≥2 criterios)
2. **Alto impacto en región semilla (24.9%)**
3. Probablemente heterogeneidad clínica legítima
4. Las mutaciones raras pueden ser importantes
5. Requieren validación con metadatos clínicos

---

## 🚀 **PRÓXIMO PASO INMEDIATO**

### **Paso 6A: Preparación e Integración de Metadatos** ⏳

**Objetivos:**
1. Cargar metadatos clínicos del estudio original (GSE168714)
2. Mapear IDs de muestras (SRR → códigos de paciente)
3. Limpiar y estandarizar variables
4. Vincular metadatos con dataset de SNVs/VAFs
5. **Caracterizar los 84 outliers con datos clínicos:**
   - ¿Son Bulbar o Non-bulbar?
   - ¿Tienen mayor severidad (ALSFRS bajo)?
   - ¿Tienen progresión rápida (slope alto)?
   - ¿Son casos extremos legítimos?

**Archivos a generar:**
- `paso6a_metadatos_completos.csv`
- `paso6a_mapeo_muestras.csv`
- `paso6a_outliers_caracterizados.csv` ⭐
- `paso6a_resumen_metadatos.csv`

**Tiempo estimado:** 20-30 minutos

---

## 📊 **ESTADÍSTICAS CLAVE DEL PROYECTO**

### **Dataset:**
- **29,254 SNVs únicos**
- **1,728 miRNAs únicos**
- **415 muestras** (313 ALS, 102 Control)
- **2,193 mutaciones G>T** (7.5%)

### **Región Semilla:**
- **397 G>T** (18.1% de todos los G>T)
- **99 solo en outliers** (24.9%)
- **Posición 6:** 97 G>T (la más crítica)

### **Análisis Estadístico:**
- **819 SNVs significativos** (2.8%)
- **390 altamente significativos** (1.35%)

### **Outliers:**
- **84 muestras** (20.2%)
- **0 severos** (≥2 criterios)
- **Impacto en G>T:** 31.88%
- **Decisión:** MANTENER

---

## 🎯 **OBJETIVOS DEL PROYECTO**

### **Objetivo Principal:**
> Consolidar y definir el pipeline completo de análisis de SNVs en miRNAs para ALS, con énfasis en mutaciones G>T como biomarcadores de estrés oxidativo.

### **Objetivos Específicos Completados:**
✅ 1. Definir transformaciones críticas (split-collapse, VAFs)
✅ 2. Identificar y cuantificar mutaciones G>T
✅ 3. Analizar distribución por región funcional
✅ 4. Identificar SNVs significativos ALS vs Control
✅ 5. Evaluar outliers y su impacto en G>T

### **Objetivos Específicos Pendientes:**
⏳ 6. Integrar metadatos clínicos
⏳ 7. Análisis por subgrupos clínicos
⏳ 8. Validar biomarcadores
⏳ 9. Análisis de supervivencia
⏳ 10. Modelos predictivos
⏳ 11. Presentación HTML en inglés

---

## 📈 **PROGRESO ACTUAL**

```
Fase 1: Exploración Inicial ████████████░░ 90% (Paso 5A completado)
Fase 2: Análisis Clínico    ░░░░░░░░░░░░░░  0% (Pendiente Paso 6)
Fase 3: Análisis Funcional  ░░░░░░░░░░░░░░  0% (Futuro)
Fase 4: Presentación        ░░░░░░░░░░░░░░  0% (Futuro)
```

**Pasos completados:** 5 de ~15 (33%)
**Archivos generados:** ~100
**Dataset:** Listo y validado
**Metadatos:** Identificados, pendiente integración

---

## 💼 **DECISIONES TOMADAS**

### **Filtros:**
✅ Mantener filtros muy permisivos (solo VAF > 50%)
✅ NO aplicar filtros de counts/totales/prevalencia (por ahora)

### **Outliers:**
✅ Mantener los 84 outliers identificados
✅ Validar con metadatos clínicos antes de decidir eliminación

### **Estrategia:**
✅ Análisis exploratorio completo primero
✅ Integrar metadatos para análisis clínicos
✅ Decisiones de filtrado basadas en datos, no arbitrarias

---

## 🎯 **PRÓXIMA ACCIÓN**

**Paso 6A: Preparación de Metadatos Clínicos**

**Tareas específicas:**
1. Cargar `GSE168714_All_samples_enrolment.txt`
2. Cargar `GSE168714_Data_file_related_to_fig_2_3_5_discovery.csv`
3. Mapear IDs de muestras
4. Crear dataset integrado (SNVs + VAFs + Metadatos)
5. **Caracterizar los 84 outliers:**
   - ¿Qué subtipo clínico son?
   - ¿Por qué tienen perfil diferente?
   - ¿Son casos extremos legítimos?

**¿Procedemos con Paso 6A?**

---

*Este documento resume el estado completo del proyecto*
*Actualizado: 8 de octubre de 2025*
*Fase: Exploración Inicial (90% completa)*









