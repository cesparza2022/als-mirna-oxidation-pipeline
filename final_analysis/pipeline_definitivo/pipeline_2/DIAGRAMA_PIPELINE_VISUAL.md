# 🎨 DIAGRAMA VISUAL DEL PIPELINE - PASO 2

---

## 📊 **FLUJO COMPLETO**

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                         INPUTS                              ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

          📂 final_processed_data_CLEAN.csv
                 5,448 SNVs × 415 samples
                      |
                      |
          📂 metadata.csv
                 415 samples: 313 ALS, 102 Control

                      ↓
                      
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                  MASTER SCRIPT                              ┃
┃         RUN_COMPLETE_PIPELINE_PASO2.R                       ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

        ┌──────────┐
        │ Validar  │ ← ¿Existen los archivos?
        │  inputs  │ ← ¿Formato correcto?
        └────┬─────┘
             │
             ↓
        ┌──────────┐
        │  Cargar  │ ← Leer CSVs
        │   datos  │ ← Contar samples, SNVs
        └────┬─────┘
             │
             ↓
     ┌───────────────────┐
     │  Ejecutar 15      │
     │  scripts          │
     │  (uno por figura) │
     └───────┬───────────┘
             │
             ├─────────────────────────────────────┐
             │                                     │
             ↓                                     ↓
    
    ┌──────────────────┐              ┌──────────────────┐
    │   GRUPO A        │              │   GRUPO B        │
    │   (Global)       │              │   (Positional)   │
    └──────────────────┘              └──────────────────┘
             │                                     │
    ┌────────┼────────┐              ┌─────┬──────┼──────┬─────┬─────┐
    ↓        ↓        ↓              ↓     ↓      ↓      ↓     ↓     ↓
  Fig 2.1  2.2     2.3           Fig 2.4  2.5   2.6   2.13  2.14  2.15
    │        │        │              │     │      │      │     │     │
    ↓        ↓        ↓              ↓     ↓      ↓      ↓     ↓     ↓
  Violin   Dens   Volcano        Raw   Zscore Line  Dens  Dens  Comb
  plots    plots   plot          heat   heat  plots  ALS   Ctrl  
    │        │        │              │     │      │      │     │     │
    └────────┴────────┴──────────────┴─────┴──────┴──────┴─────┴─────┘
                                     │
                                     ↓
    
    ┌──────────────────┐              ┌──────────────────┐
    │   GRUPO C        │              │   GRUPO D        │
    │ (Heterogeneity)  │              │  (Specificity)   │
    └──────────────────┘              └──────────────────┘
             │                                     │
    ┌────────┼────────┐              ┌─────┬──────┼──────┐
    ↓        ↓        ↓              ↓     ↓      ↓      
  Fig 2.7  2.8     2.9           Fig 2.10 2.11  2.12
    │        │        │              │     │      │      
    ↓        ↓        ↓              ↓     ↓      ↓      
   PCA   Cluster   CV             Ratio Spectrum Enrich
  PERMA   heat   analysis                        112 
  NOVA                                           cands
    │        │        │              │     │      │
    └────────┴────────┴──────────────┴─────┴──────┘
                      │
                      ↓
                      
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                      OUTPUTS                                ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

    📁 figures/
       ├── FIG_2.1_VAF_COMPARISON_LINEAR.png       (806 KB)
       ├── FIG_2.2_DISTRIBUTIONS_LINEAR.png        (219 KB)
       ├── FIG_2.3_VOLCANO_COMBINADO.png           (398 KB)
       ├── FIG_2.4_HEATMAP_ALL.png                 (222 KB)
       ├── FIG_2.5_ZSCORE_HEATMAP.png              (251 KB) ⭐
       ├── FIG_2.6_POSITIONAL_ANALYSIS.png         (315 KB)
       ├── FIG_2.7_PCA_PERMANOVA.png               (687 KB)
       ├── FIG_2.8_CLUSTERING.png                  (416 KB)
       ├── FIG_2.9_COMBINED_IMPROVED.png           (1.1 MB)
       ├── FIG_2.10_COMBINED.png                   (502 KB)
       ├── FIG_2.11_COMBINED_IMPROVED.png          (462 KB)
       ├── FIG_2.12_COMBINED.png                   (607 KB)
       ├── FIG_2.13_DENSITY_HEATMAP_ALS.png        (126 KB)
       ├── FIG_2.14_DENSITY_HEATMAP_CONTROL.png    (131 KB)
       └── FIG_2.15_DENSITY_COMBINED.png           (154 KB)

    📊 TOTAL: 15 figuras, ~6.3 MB

    🌐 PASO_2_VIEWER_COMPLETO_FINAL.html
       → Viewer interactivo con todas las figuras
```

---

## 🔄 **FLUJO DE DATOS**

### **Para Fig 2.5 (ejemplo detallado):**

```
INPUT DATA:
  5,448 SNVs × 415 samples
  
       ↓ FILTER: G>T en seed (positions 2-8)
       
  301 miRNAs identificados
  
       ↓ EXTRACT: Todos los G>T de esos 301 miRNAs
       
  1,377 SNVs (301 miRNAs × posiciones variables)
  
       ↓ TRANSFORM: Wide → Long format
       
  61,891 observaciones (1,377 SNVs × 415 samples, filtered)
  
       ↓ GROUP: Por miRNA + position + Group
       
  2,754 promedios (1,377 SNVs × 2 groups)
  
       ↓ NORMALIZE: Z-score per miRNA
       
  2,754 Z-scores
  
       ↓ PLOT: Heatmap
       
  📊 FIG_2.5_ZSCORE_HEATMAP.png
     301 miRNAs × 23 positions × 2 panels
```

---

## 🧮 **CÁLCULOS ESTADÍSTICOS**

### **Lo que hace cada figura:**

```
Fig 2.1:  Wilcoxon test, t-test, Cohen's d
Fig 2.2:  KS test, distribuciones
Fig 2.3:  Fisher's exact (per miRNA), FDR correction
Fig 2.4:  Descriptive stats, clustering
Fig 2.5:  Z-score normalization, outlier detection
Fig 2.6:  Mean, SE, CI (95%), comparisons
Fig 2.7:  PCA, PERMANOVA, variance decomposition
Fig 2.8:  Hierarchical clustering (Ward.D2)
Fig 2.9:  CV, F-test, Levene's test, correlations
Fig 2.10: Proportions, Chi-square
Fig 2.11: Complete spectrum, Ts/Tv ratio
Fig 2.12: Enrichment, ranking, filtering
Fig 2.13-15: Density, binning, hotspot identification
```

---

## ⏱️ **TIEMPO DE EJECUCIÓN**

### **Estimaciones por figura:**

```
Fig 2.1:  ~15 segundos  (comparisons simples)
Fig 2.2:  ~20 segundos  (distributions)
Fig 2.3:  ~60 segundos  (Fisher's exact × 620 miRNAs)
Fig 2.4:  ~30 segundos  (heatmap grande)
Fig 2.5:  ~35 segundos  (Z-scores + heatmap)
Fig 2.6:  ~25 segundos  (stats posicionales)
Fig 2.7:  ~40 segundos  (PCA + PERMANOVA)
Fig 2.8:  ~30 segundos  (clustering)
Fig 2.9:  ~45 segundos  (CV + múltiples tests)
Fig 2.10: ~30 segundos  (ratios)
Fig 2.11: ~35 segundos  (spectrum completo)
Fig 2.12: ~40 segundos  (enrichment analysis)
Fig 2.13-15: ~45 segundos (3 density heatmaps)

TOTAL ESTIMADO: 3-5 minutos
  (depende de tu computadora)
```

---

## 🎯 **PRÓXIMO PASO: PROBARLO**

### **¿Qué quieres hacer?**

```
A) Ver el HTML viewer (YA está abierto)
   → Ver las 15 figuras ya generadas

B) Ejecutar UNA figura de prueba
   → Para entender cómo funciona un script individual

C) Ejecutar el pipeline COMPLETO
   → Regenerar todas las 15 figuras desde cero
   → Validar que todo funciona
   
D) Revisar el código de un script específico
   → Para entender la lógica en detalle
```

---

**¿Cuál opción prefieres?** 🤔

