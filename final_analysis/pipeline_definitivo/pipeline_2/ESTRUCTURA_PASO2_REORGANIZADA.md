# 📊 PASO 2 - ESTRUCTURA REORGANIZADA

**Organización Final:** Diagnóstico primero, luego análisis comparativo

---

## 🎯 NUEVA ESTRUCTURA DEL PASO 2

### **PARTE 1: CONTROL DE CALIDAD Y DIAGNÓSTICO** ⭐
**Objetivo:** Verificar calidad de datos y filtrar artefactos

#### **Figuras (4):**
1. `DIAGNOSTICO_1_DISTRIBUCION_VAF.png` - Distribución global de VAF
2. `DIAGNOSTICO_2_IMPACTO_POR_SNV.png` - Análisis por SNV
3. `DIAGNOSTICO_3_IMPACTO_POR_miRNA.png` - Análisis por miRNA
4. `DIAGNOSTICO_4_TABLA_RESUMEN.png` - Resumen estadístico

#### **Hallazgos:**
- ✅ 458 valores VAF = 0.5 identificados (artefactos)
- ✅ 192 SNVs afectados
- ✅ 126 miRNAs afectados
- ✅ Filtro aplicado → Datos limpios generados

#### **Archivos:**
- `final_processed_data_CLEAN.csv` - Datos sin VAF ≥ 0.5
- `SNVs_REMOVED_VAF_05.csv` - Lista de SNVs removidos
- `miRNAs_AFFECTED_VAF_05.csv` - Lista de miRNAs afectados

---

### **PARTE 2: ANÁLISIS COMPARATIVO (ALS vs Control)**
**Objetivo:** Comparar perfiles VAF entre grupos usando datos limpios

#### **GRUPO A - Comparaciones Globales (3 figuras):**
1. `FIG_2.1_VAF_GLOBAL_CLEAN.png` - Boxplots VAF (Total, G>T, Ratio)
2. `FIG_2.2_DISTRIBUTIONS_CLEAN.png` - Violin + Density + CDF
3. `FIG_2.3_VOLCANO_CLEAN.png` - Volcano plot (301 seed G>T miRNAs)

#### **GRUPO B - Análisis Posicional (3 figuras):**
4. `FIG_2.4_HEATMAP_POSITIONAL_CLEAN.png` - Heatmap VAF por posición
5. `FIG_2.5_HEATMAP_ZSCORE_CLEAN.png` - Heatmap Z-score
6. `FIG_2.6_POSITIONAL_PROFILES_CLEAN.png` - Perfiles + significancia

#### **GRUPO C - Heterogeneidad (3 figuras):**
7. `FIG_2.7_PCA_CLEAN.png` - PCA de muestras
8. `FIG_2.8_CLUSTERING_CLEAN.png` - Clustering jerárquico
9. `FIG_2.9_CV_CLEAN.png` - Coeficiente de variación

#### **GRUPO D - Especificidad G>T (3 figuras):**
10. `FIG_2.10_RATIO_GT_GA_CLEAN.png` - Ratio G>T/G>A
11. `FIG_2.11_MUTATION_TYPES_CLEAN.png` - Heatmap tipos de mutación
12. `FIG_2.12_ENRICHMENT_REGIONS_CLEAN.png` - Enriquecimiento por región

---

## 📁 ORGANIZACIÓN DE ARCHIVOS

```
pipeline_2/
├── PARTE 1 - DIAGNÓSTICO:
│   ├── figures_diagnostico/
│   │   ├── DIAG_1_DISTRIBUCION_REAL.png
│   │   ├── DIAG_2_IMPACTO_SNV_REAL.png
│   │   ├── DIAG_3_IMPACTO_miRNA_REAL.png
│   │   └── DIAG_4_TABLA_RESUMEN_REAL.png
│   │
│   ├── DIAGNOSTICO_VAF_REAL.html (viewer)
│   │
│   └── Datos generados:
│       ├── final_processed_data_CLEAN.csv
│       ├── SNVs_REMOVED_VAF_05.csv
│       └── miRNAs_AFFECTED_VAF_05.csv
│
└── PARTE 2 - ANÁLISIS COMPARATIVO:
    ├── figures_paso2_CLEAN/
    │   ├── FIG_2.1_VAF_GLOBAL_CLEAN.png
    │   ├── FIG_2.2_DISTRIBUTIONS_CLEAN.png
    │   ├── FIG_2.3_VOLCANO_CLEAN.png
    │   ├── FIG_2.4_HEATMAP_POSITIONAL_CLEAN.png
    │   ├── FIG_2.5_HEATMAP_ZSCORE_CLEAN.png
    │   ├── FIG_2.6_POSITIONAL_PROFILES_CLEAN.png
    │   ├── FIG_2.7_PCA_CLEAN.png
    │   ├── FIG_2.8_CLUSTERING_CLEAN.png
    │   ├── FIG_2.9_CV_CLEAN.png
    │   ├── FIG_2.10_RATIO_GT_GA_CLEAN.png
    │   ├── FIG_2.11_MUTATION_TYPES_CLEAN.png
    │   └── FIG_2.12_ENRICHMENT_REGIONS_CLEAN.png
    │
    ├── SEED_GT_miRNAs_CLEAN_RANKING.csv (301 miRNAs)
    │
    └── PASO_2_CLEAN_COMPLETO.html (viewer final)
```

---

## 🌐 HTML VIEWERS

### **Viewer Principal del Paso 2:**
`PASO_2_CLEAN_COMPLETO.html` contendrá:

**SECCIÓN 1: Control de Calidad (Parte 1)**
- Banner: "458 valores removidos"
- 4 figuras de diagnóstico
- Interpretación del filtro
- Lista de miRNAs afectados

**SECCIÓN 2: Análisis Comparativo (Parte 2)**
- Banner: "Datos limpios - 301 miRNAs seed G>T"
- 12 figuras en 4 grupos
- Nuevo ranking de miRNAs
- Tests estadísticos con datos limpios

---

## 🔄 ESTADO ACTUAL

### **✅ Completado:**
- Parte 1 (Diagnóstico): 4 figuras + HTML
- Figuras 2.1, 2.2, 2.3 de Parte 2
- Nuevo ranking de miRNAs

### **🔄 En Proceso:**
- Figuras 2.4-2.12 (resto de Parte 2)
- HTML viewer integrado

### **⏸️ Pendiente:**
- Interpretación completa
- Comparación ANTES vs DESPUÉS
- Planificación Paso 3

---

**Reorganización completada:** 2025-10-17 01:15
**Estructura:** Parte 1 (QC) → Parte 2 (Análisis)
**HTML viewer:** Integrado con ambas partes

