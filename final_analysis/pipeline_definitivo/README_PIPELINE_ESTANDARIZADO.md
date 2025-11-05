# 🚀 Pipeline Estandarizado - Guía de Uso

**Versión:** 2.0 (Estandarizada)  
**Fecha:** 2025-01-30  
**Estado:** ✅ Completo y funcional

---

## 📋 RESUMEN

Pipeline estandarizado para análisis de mutaciones G>T en miRNAs. Todos los pasos siguen la misma estructura para facilitar mantenimiento y uso.

---

## 📁 ESTRUCTURA

```
pipeline_definitivo/
├── step1/              # Análisis Exploratorio
│   ├── scripts/        # 6 scripts generadores
│   ├── viewers/        # STEP1.html
│   ├── outputs/        # figures/, tables/, logs/
│   └── run_step1.R     # Orquestador
│
├── step1_5/            # Control de Calidad VAF
│   ├── scripts/        # 2 scripts generadores
│   ├── viewers/        # STEP1_5.html
│   ├── outputs/        # figures/, tables/, logs/
│   └── run_step1_5.R   # Orquestador
│
├── step2/              # Análisis Comparativo (ALS vs Control)
│   ├── scripts/        # Scripts generadores
│   ├── viewers/        # STEP2_EMBED.html
│   ├── outputs/        # figures/, tables/, logs/
│   └── run_step2.R     # Orquestador
│
└── run_pipeline_completo.R  # 🎯 Ejecuta todos los pasos
```

---

## 🚀 USO RÁPIDO

### Ejecutar todo el pipeline:

```bash
cd pipeline_definitivo
Rscript run_pipeline_completo.R
```

Esto ejecuta:
1. **Paso 1**: Análisis exploratorio (6 figuras)
2. **Paso 1.5**: Control de calidad VAF (11 figuras)
3. **Paso 2**: Análisis comparativo (15 figuras)

### Ejecutar un paso individual:

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

---

## 📊 PASOS DEL PIPELINE

### **PASO 1: Análisis Exploratorio**

**Objetivo:** Caracterizar los datos antes de filtrado VAF

**Scripts:**
- `02_gt_count_by_position.R` - Panel B
- `03_gx_spectrum.R` - Panel C
- `04_positional_fraction.R` - Panel D
- `05_gcontent.R` - Panel E
- `06_seed_vs_nonseed.R` - Panel F
- `07_gt_specificity.R` - Panel G

**Outputs:**
- 6 figuras PNG
- 5 tablas CSV
- Viewer: `step1/viewers/STEP1.html`

---

### **PASO 1.5: Control de Calidad VAF**

**Objetivo:** Filtrar artefactos técnicos (VAF >= 0.5)

**Scripts:**
- `01_apply_vaf_filter.R` - Aplica filtro VAF
- `02_generate_diagnostic_figures.R` - Genera figuras

**Outputs:**
- Dataset filtrado: `outputs/tables/ALL_MUTATIONS_VAF_FILTERED.csv`
- 11 figuras (4 QC + 7 diagnóstico)
- Estadísticas de filtrado
- Viewer: `step1_5/viewers/STEP1_5.html`

---

### **PASO 2: Análisis Comparativo**

**Objetivo:** Comparar ALS vs Control (requiere metadata)

**Scripts:**
- Múltiples scripts generadores (ver `step2/scripts/`)

**Outputs:**
- 15 figuras
- Tablas estadísticas
- Viewer: `step2/viewers/STEP2_EMBED.html`

---

## 📂 DATOS DE ENTRADA

**Paso 1:**
- `pipeline_2/final_processed_data_CLEAN.csv` (datos procesados)
- `../../UCSD/8OG/results/.../miRNA_count.Q33.txt` (datos RAW para algunos scripts)

**Paso 1.5:**
- `../../UCSD/8OG/final_analysis/tercer_intento/step_by_step_analysis/step1_original_data.csv`

**Paso 2:**
- `pipeline_2/final_processed_data_CLEAN.csv`
- Metadata de grupos (ALS vs Control)

---

## 📄 VIEWERS HTML

Todos los pasos generan viewers HTML con todas las figuras:

- **Paso 1**: `step1/viewers/STEP1.html`
- **Paso 1.5**: `step1_5/viewers/STEP1_5.html`
- **Paso 2**: `step2/viewers/STEP2_EMBED.html` (imágenes embebidas)

---

## 🔄 MIGRACIÓN Y CAMBIOS

Este pipeline fue migrado desde estructuras anteriores:
- `STEP1_ORGANIZED/` → `step1/`
- `01.5_vaf_quality_control/` → `step1_5/`
- `pipeline_2/` → `step2/` (ya estaba estandarizado)

Todos los scripts fueron adaptados para usar rutas relativas y estructura estandarizada.

---

## 📝 DOCUMENTACIÓN ADICIONAL

- `BITACORA_PIPELINE.md` - Registro de cambios
- `ORGANIZACION_PIPELINE.md` - Organización detallada
- `step1/README.md` - Documentación Paso 1
- `step1_5/README.md` - Documentación Paso 1.5

---

## ✅ ESTADO ACTUAL

- ✅ Paso 1: Estandarizado y funcional
- ✅ Paso 1.5: Estandarizado y funcional
- ✅ Paso 2: Ya estaba estandarizado
- ✅ Runner maestro: Creado y funcional

---

**Última actualización:** 2025-01-30


**Versión:** 2.0 (Estandarizada)  
**Fecha:** 2025-01-30  
**Estado:** ✅ Completo y funcional

---

## 📋 RESUMEN

Pipeline estandarizado para análisis de mutaciones G>T en miRNAs. Todos los pasos siguen la misma estructura para facilitar mantenimiento y uso.

---

## 📁 ESTRUCTURA

```
pipeline_definitivo/
├── step1/              # Análisis Exploratorio
│   ├── scripts/        # 6 scripts generadores
│   ├── viewers/        # STEP1.html
│   ├── outputs/        # figures/, tables/, logs/
│   └── run_step1.R     # Orquestador
│
├── step1_5/            # Control de Calidad VAF
│   ├── scripts/        # 2 scripts generadores
│   ├── viewers/        # STEP1_5.html
│   ├── outputs/        # figures/, tables/, logs/
│   └── run_step1_5.R   # Orquestador
│
├── step2/              # Análisis Comparativo (ALS vs Control)
│   ├── scripts/        # Scripts generadores
│   ├── viewers/        # STEP2_EMBED.html
│   ├── outputs/        # figures/, tables/, logs/
│   └── run_step2.R     # Orquestador
│
└── run_pipeline_completo.R  # 🎯 Ejecuta todos los pasos
```

---

## 🚀 USO RÁPIDO

### Ejecutar todo el pipeline:

```bash
cd pipeline_definitivo
Rscript run_pipeline_completo.R
```

Esto ejecuta:
1. **Paso 1**: Análisis exploratorio (6 figuras)
2. **Paso 1.5**: Control de calidad VAF (11 figuras)
3. **Paso 2**: Análisis comparativo (15 figuras)

### Ejecutar un paso individual:

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

---

## 📊 PASOS DEL PIPELINE

### **PASO 1: Análisis Exploratorio**

**Objetivo:** Caracterizar los datos antes de filtrado VAF

**Scripts:**
- `02_gt_count_by_position.R` - Panel B
- `03_gx_spectrum.R` - Panel C
- `04_positional_fraction.R` - Panel D
- `05_gcontent.R` - Panel E
- `06_seed_vs_nonseed.R` - Panel F
- `07_gt_specificity.R` - Panel G

**Outputs:**
- 6 figuras PNG
- 5 tablas CSV
- Viewer: `step1/viewers/STEP1.html`

---

### **PASO 1.5: Control de Calidad VAF**

**Objetivo:** Filtrar artefactos técnicos (VAF >= 0.5)

**Scripts:**
- `01_apply_vaf_filter.R` - Aplica filtro VAF
- `02_generate_diagnostic_figures.R` - Genera figuras

**Outputs:**
- Dataset filtrado: `outputs/tables/ALL_MUTATIONS_VAF_FILTERED.csv`
- 11 figuras (4 QC + 7 diagnóstico)
- Estadísticas de filtrado
- Viewer: `step1_5/viewers/STEP1_5.html`

---

### **PASO 2: Análisis Comparativo**

**Objetivo:** Comparar ALS vs Control (requiere metadata)

**Scripts:**
- Múltiples scripts generadores (ver `step2/scripts/`)

**Outputs:**
- 15 figuras
- Tablas estadísticas
- Viewer: `step2/viewers/STEP2_EMBED.html`

---

## 📂 DATOS DE ENTRADA

**Paso 1:**
- `pipeline_2/final_processed_data_CLEAN.csv` (datos procesados)
- `../../UCSD/8OG/results/.../miRNA_count.Q33.txt` (datos RAW para algunos scripts)

**Paso 1.5:**
- `../../UCSD/8OG/final_analysis/tercer_intento/step_by_step_analysis/step1_original_data.csv`

**Paso 2:**
- `pipeline_2/final_processed_data_CLEAN.csv`
- Metadata de grupos (ALS vs Control)

---

## 📄 VIEWERS HTML

Todos los pasos generan viewers HTML con todas las figuras:

- **Paso 1**: `step1/viewers/STEP1.html`
- **Paso 1.5**: `step1_5/viewers/STEP1_5.html`
- **Paso 2**: `step2/viewers/STEP2_EMBED.html` (imágenes embebidas)

---

## 🔄 MIGRACIÓN Y CAMBIOS

Este pipeline fue migrado desde estructuras anteriores:
- `STEP1_ORGANIZED/` → `step1/`
- `01.5_vaf_quality_control/` → `step1_5/`
- `pipeline_2/` → `step2/` (ya estaba estandarizado)

Todos los scripts fueron adaptados para usar rutas relativas y estructura estandarizada.

---

## 📝 DOCUMENTACIÓN ADICIONAL

- `BITACORA_PIPELINE.md` - Registro de cambios
- `ORGANIZACION_PIPELINE.md` - Organización detallada
- `step1/README.md` - Documentación Paso 1
- `step1_5/README.md` - Documentación Paso 1.5

---

## ✅ ESTADO ACTUAL

- ✅ Paso 1: Estandarizado y funcional
- ✅ Paso 1.5: Estandarizado y funcional
- ✅ Paso 2: Ya estaba estandarizado
- ✅ Runner maestro: Creado y funcional

---

**Última actualización:** 2025-01-30


**Versión:** 2.0 (Estandarizada)  
**Fecha:** 2025-01-30  
**Estado:** ✅ Completo y funcional

---

## 📋 RESUMEN

Pipeline estandarizado para análisis de mutaciones G>T en miRNAs. Todos los pasos siguen la misma estructura para facilitar mantenimiento y uso.

---

## 📁 ESTRUCTURA

```
pipeline_definitivo/
├── step1/              # Análisis Exploratorio
│   ├── scripts/        # 6 scripts generadores
│   ├── viewers/        # STEP1.html
│   ├── outputs/        # figures/, tables/, logs/
│   └── run_step1.R     # Orquestador
│
├── step1_5/            # Control de Calidad VAF
│   ├── scripts/        # 2 scripts generadores
│   ├── viewers/        # STEP1_5.html
│   ├── outputs/        # figures/, tables/, logs/
│   └── run_step1_5.R   # Orquestador
│
├── step2/              # Análisis Comparativo (ALS vs Control)
│   ├── scripts/        # Scripts generadores
│   ├── viewers/        # STEP2_EMBED.html
│   ├── outputs/        # figures/, tables/, logs/
│   └── run_step2.R     # Orquestador
│
└── run_pipeline_completo.R  # 🎯 Ejecuta todos los pasos
```

---

## 🚀 USO RÁPIDO

### Ejecutar todo el pipeline:

```bash
cd pipeline_definitivo
Rscript run_pipeline_completo.R
```

Esto ejecuta:
1. **Paso 1**: Análisis exploratorio (6 figuras)
2. **Paso 1.5**: Control de calidad VAF (11 figuras)
3. **Paso 2**: Análisis comparativo (15 figuras)

### Ejecutar un paso individual:

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

---

## 📊 PASOS DEL PIPELINE

### **PASO 1: Análisis Exploratorio**

**Objetivo:** Caracterizar los datos antes de filtrado VAF

**Scripts:**
- `02_gt_count_by_position.R` - Panel B
- `03_gx_spectrum.R` - Panel C
- `04_positional_fraction.R` - Panel D
- `05_gcontent.R` - Panel E
- `06_seed_vs_nonseed.R` - Panel F
- `07_gt_specificity.R` - Panel G

**Outputs:**
- 6 figuras PNG
- 5 tablas CSV
- Viewer: `step1/viewers/STEP1.html`

---

### **PASO 1.5: Control de Calidad VAF**

**Objetivo:** Filtrar artefactos técnicos (VAF >= 0.5)

**Scripts:**
- `01_apply_vaf_filter.R` - Aplica filtro VAF
- `02_generate_diagnostic_figures.R` - Genera figuras

**Outputs:**
- Dataset filtrado: `outputs/tables/ALL_MUTATIONS_VAF_FILTERED.csv`
- 11 figuras (4 QC + 7 diagnóstico)
- Estadísticas de filtrado
- Viewer: `step1_5/viewers/STEP1_5.html`

---

### **PASO 2: Análisis Comparativo**

**Objetivo:** Comparar ALS vs Control (requiere metadata)

**Scripts:**
- Múltiples scripts generadores (ver `step2/scripts/`)

**Outputs:**
- 15 figuras
- Tablas estadísticas
- Viewer: `step2/viewers/STEP2_EMBED.html`

---

## 📂 DATOS DE ENTRADA

**Paso 1:**
- `pipeline_2/final_processed_data_CLEAN.csv` (datos procesados)
- `../../UCSD/8OG/results/.../miRNA_count.Q33.txt` (datos RAW para algunos scripts)

**Paso 1.5:**
- `../../UCSD/8OG/final_analysis/tercer_intento/step_by_step_analysis/step1_original_data.csv`

**Paso 2:**
- `pipeline_2/final_processed_data_CLEAN.csv`
- Metadata de grupos (ALS vs Control)

---

## 📄 VIEWERS HTML

Todos los pasos generan viewers HTML con todas las figuras:

- **Paso 1**: `step1/viewers/STEP1.html`
- **Paso 1.5**: `step1_5/viewers/STEP1_5.html`
- **Paso 2**: `step2/viewers/STEP2_EMBED.html` (imágenes embebidas)

---

## 🔄 MIGRACIÓN Y CAMBIOS

Este pipeline fue migrado desde estructuras anteriores:
- `STEP1_ORGANIZED/` → `step1/`
- `01.5_vaf_quality_control/` → `step1_5/`
- `pipeline_2/` → `step2/` (ya estaba estandarizado)

Todos los scripts fueron adaptados para usar rutas relativas y estructura estandarizada.

---

## 📝 DOCUMENTACIÓN ADICIONAL

- `BITACORA_PIPELINE.md` - Registro de cambios
- `ORGANIZACION_PIPELINE.md` - Organización detallada
- `step1/README.md` - Documentación Paso 1
- `step1_5/README.md` - Documentación Paso 1.5

---

## ✅ ESTADO ACTUAL

- ✅ Paso 1: Estandarizado y funcional
- ✅ Paso 1.5: Estandarizado y funcional
- ✅ Paso 2: Ya estaba estandarizado
- ✅ Runner maestro: Creado y funcional

---

**Última actualización:** 2025-01-30

