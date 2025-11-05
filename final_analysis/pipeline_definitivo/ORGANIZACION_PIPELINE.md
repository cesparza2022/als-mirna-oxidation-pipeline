# 📂 ORGANIZACIÓN COMPLETA DEL PIPELINE

Este documento es la **fuente de verdad** para la estructura del pipeline. Debe actualizarse **SIEMPRE** que se agreguen/eliminen scripts, viewers o salidas.

**Última actualización:** 2025-01-30

---

## 🎯 ESTRUCTURA COMPLETA POR PASO

### **PASO 1: Análisis Inicial Exploratorio**

**Ubicación:** `step1/` ⭐ **ESTANDARIZADO**

**Viewer principal:**
- `step1/viewers/STEP1.html` ⭐
- (También disponible en `STEP1_ORGANIZED/STEP1_FINAL.html` como backup)

**Qué debe contener:**
- ✅ Evolución del dataset (split vs collapse)
- ✅ Distribución de tipos de mutación (SNVs y cuentas)
- ✅ Características generales de miRNAs (total, longitudes, SNVs por miRNA)
- ✅ G-content por posición
- ✅ G>X Mutation Spectrum por posición (G>A, G>C, G>T)
- ✅ Comparación Seed vs. No-Seed (SNVs, cuentas, fracción G>T)
- ✅ Tablas de estadísticas clave

**Scripts principales:**
- `step1/run_step1.R` ⭐ **Orquestador principal**
- `step1/scripts/02_gt_count_by_position.R` - Panel B
- `step1/scripts/03_gx_spectrum.R` - Panel C
- `step1/scripts/04_positional_fraction.R` - Panel D
- `step1/scripts/05_gcontent.R` - Panel E
- `step1/scripts/06_seed_vs_nonseed.R` - Panel F
- `step1/scripts/07_gt_specificity.R` - Panel G

**Outputs:**
- Figuras: `step1/outputs/figures/step1_panel*.png` (6 figuras)
- Tablas: `step1/outputs/tables/TABLE_1.*.csv` (5 tablas)
- Logs: `step1/outputs/logs/*.log`

---

### **PASO 1.5: Control de Calidad VAF**

**Ubicación:** `step1_5/` ⭐ **ESTANDARIZADO**

**Viewer principal:**
- `step1_5/viewers/STEP1_5.html` ⭐
- (También disponible en `01.5_vaf_quality_control/STEP1.5_VAF_QC_VIEWER.html` como backup)

**Qué debe contener:**
- ✅ Distribución de VAFs por grupo (ALS vs Control)
- ✅ Análisis de calidad de VAFs
- ✅ Filtrado de VAFs > 50%
- ✅ Validación de datos antes de comparaciones

**Scripts principales:**
- `step1_5/run_step1_5.R` ⭐ **Orquestador principal**
- `step1_5/scripts/01_apply_vaf_filter.R` - Aplica filtro VAF >= 0.5
- `step1_5/scripts/02_generate_diagnostic_figures.R` - Genera 11 figuras

**Outputs:**
- Dataset filtrado: `step1_5/outputs/tables/ALL_MUTATIONS_VAF_FILTERED.csv`
- Figuras: `step1_5/outputs/figures/*.png` (11 figuras: 4 QC + 7 diagnóstico)
- Tablas: `step1_5/outputs/tables/*.csv` (estadísticas de filtrado)
- Logs: `step1_5/outputs/logs/*.log`

---

### **PASO 2: Comparaciones entre Grupos**

**Ubicación:** `step2/` (estructura nueva estandarizada)

**Viewer principal (EMBED):**
- `step2/viewers/STEP2_EMBED.html` ⭐ **Usar este para revisión** (imágenes embebidas)

**Viewer alternativo:**
- `step2/viewers/STEP2.html` (rutas relativas)

**Qué debe contener (15 figuras + tablas):**
- ✅ **2.1** VAF Comparison (lineal)
- ✅ **2.2** VAF Distributions (lineal)
- ✅ **2.3** Volcano Plot (combinado)
- ✅ **2.4** Heatmap Raw
- ✅ **2.5** Heatmap ZScore
- ✅ **2.6** Positional Profiles
- ✅ **2.7** PCA + PERMANOVA
- ✅ **2.8** Clustering
- ✅ **2.9** CV Combined
- ✅ **2.10** G>T Ratio
- ✅ **2.11** Spectrum
- ✅ **2.12** Enrichment
- ✅ **2.13** Density Heatmap ALS ⭐ (golden copy)
- ✅ **2.14** Density Heatmap Control ⭐ (golden copy)
- ✅ **2.15** Combined Density ⭐ (golden copy)

**Scripts principales:**
- `run_step2.R` ⭐ **Orquestador principal** (ejecuta todo)
- `scripts/build_step2_viewers.R` (genera HTML viewers)
- Scripts individuales de generación de figuras en `step2/scripts/` (o `pipeline_2/`)

**Outputs:**
- `step2/outputs/figures/` → Figuras finales (2.1-2.12)
- `step2/outputs/figures_clean/` → Variantes y golden copies (2.13-2.15)
- `step2/outputs/tables/` → Tablas CSV/TSV de estadísticas
- `step2/logs/` → Logs de ejecución

**Fuente de golden copies (2.13-2.15):**
- `pipeline_2/HTML_VIEWERS_FINALES/figures_paso2_CLEAN/FIG_2.13/14/15_*.png`
- Se sincronizan automáticamente al ejecutar `run_step2.R`

---

## 📝 CONVENCIONES DE NOMBRES

### Scripts R:
- **Orquestadores:** `run_stepX.R`
- **Generadores de figuras:** `generate_FIG_2.XX_DescriptiveName.R`
- **Builders de viewers:** `build_stepX_viewers.R` o `create_VIEWER_*.R`

### Figuras (PNG):
- **Finales:** `FIG_2.XX_DescriptiveName.png` o `FIGURE_X_PanelName.png`
- **Variantes:** `...CLEAN.png` o `...IMPROVED.png`

### Tablas (CSV/TSV):
- **Formato:** `T2.XX_SummaryName.csv` o `pasoX_tablename.csv`

### Viewers HTML:
- **Principal:** `STEPX.html` o `STEPX_EMBED.html` (para embebido)
- **Alternativos:** `STEPX_VIEWER_NAME.html`

---

## ⚙️ FLUJO DE TRABAJO Y AUTOMATIZACIÓN

### **Ejecutar Pipeline Completo:**
```bash
cd /path/to/pipeline_definitivo
Rscript run_pipeline_completo.R
```

Esto ejecuta Paso 1 → Paso 1.5 → Paso 2 en secuencia.

### **Ejecutar Pasos Individuales:**
```bash
# Paso 1
cd step1
Rscript run_step1.R

# Paso 1.5
cd step1_5
Rscript run_step1_5.R

# Paso 2
cd step2
Rscript run_step2.R
```

**Lo que hace `run_step2.R`:**
1. Ejecuta generadores de figuras (2.1-2.12)
2. Ejecuta generador de density heatmaps (2.13-2.15)
3. Sincroniza golden copies de 2.13-2.15 desde `HTML_VIEWERS_FINALES/`
4. Construye `STEP2_EMBED.html` con todas las imágenes embebidas (base64)
5. Construye `STEP2.html` con rutas relativas
6. Guarda outputs en `step2/outputs/`

### **Estructura de outputs esperada:**

```
step2/
├── scripts/
│   └── build_step2_viewers.R
├── viewers/
│   ├── STEP2_EMBED.html  ⭐ (para revisión)
│   └── STEP2.html        (con rutas)
└── outputs/
    ├── figures/          (2.1-2.12)
    ├── figures_clean/    (2.13-2.15 golden copies)
    ├── tables/           (CSV/TSV)
    └── logs/             (logs de ejecución)
```

---

## 🔄 REGLAS Y MEJORES PRÁCTICAS

### ✅ HACER:
1. **Actualizar este archivo** cuando se agreguen/quiten figuras o scripts
2. **Registrar cambios** en bitácora (CHANGELOG.md o similar)
3. **Usar `STEP2_EMBED.html`** para revisión diaria (garantiza visibilidad)
4. **Mantener golden copies** de 2.13-2.15 en `HTML_VIEWERS_FINALES/`
5. **Sincronizar automáticamente** las golden copies al ejecutar `run_step2.R`
6. **Usar colores consistentes:** G>T en rojo `#D62728`, Control en gris

### ❌ NO HACER:
1. **No borrar archivos originales** sin respaldo; primero copiar a estructura `stepX/`
2. **No hardcodear rutas absolutas** en scripts (usar `file.path()` con root relativo)
3. **No duplicar figuras** innecesariamente entre `figures/` y `figures_clean/`
4. **No modificar viewers manualmente** si se pueden regenerar automáticamente

---

## 📊 ESTADO ACTUAL DEL PIPELINE

### ✅ Consolidado y Estandarizado:
- **Paso 1:** Estructura estandarizada en `step1/` con `run_step1.R` funcional ✅
- **Paso 1.5:** Estructura estandarizada en `step1_5/` con `run_step1_5.R` funcional ✅
- **Paso 2:** Estructura completa en `step2/` con `run_step2.R` funcional ✅
- **Runner maestro:** `run_pipeline_completo.R` ejecuta todos los pasos en secuencia ✅

### 📁 Estructura Estandarizada:
Todos los pasos siguen la misma estructura:
```
stepX/
├── scripts/     # Scripts generadores
├── viewers/     # Viewers HTML
├── outputs/     # Resultados
│   ├── figures/ # Figuras PNG
│   ├── tables/  # Tablas CSV
│   └── logs/    # Logs de ejecución
└── run_stepX.R  # Orquestador
```

### 📝 Registro de cambios:
- Ver `CHANGELOG.md` o `BITACORA_PIPELINE.md` (crear si no existe)

---

## 🔗 ENLACES Y RUTAS

### Viewers principales:
- Paso 1: `step1/viewers/STEP1.html` ⭐
- Paso 1.5: `step1_5/viewers/STEP1_5.html` ⭐
- Paso 2 (EMBED): `step2/viewers/STEP2_EMBED.html` ⭐ **Recomendado**
- Paso 2 (rutas): `step2/viewers/STEP2.html`

### Fuente de datos:
- Raw: `../final_analysis/data/raw/miRNA_count.Q33.txt`
- Processed: `../final_analysis/processed_data/final_processed_data.csv`

### Golden copies (Paso 2):
- `pipeline_2/HTML_VIEWERS_FINALES/figures_paso2_CLEAN/FIG_2.13/14/15_*.png`

---

## 📚 DOCUMENTACIÓN ADICIONAL

- Ver `README_PIPELINE.md` (si existe) para guía de uso
- Ver scripts individuales para documentación de figuras específicas
- Ver viewers HTML para descripciones de cada figura

---

**⚠️ IMPORTANTE:** Este documento debe actualizarse cada vez que se modifique la estructura del pipeline, se agreguen/quiten figuras, o se cambien las convenciones.
