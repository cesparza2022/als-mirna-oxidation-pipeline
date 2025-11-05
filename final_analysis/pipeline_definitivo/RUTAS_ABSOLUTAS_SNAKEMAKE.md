# 📍 RUTAS ABSOLUTAS PARA SNAKEMAKE PIPELINE

Este documento contiene todas las rutas absolutas necesarias para configurar el pipeline Snakemake.

---

## 🗂️ RUTAS BASE

```bash
# Raíz del proyecto actual
PROJECT_ROOT="/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo"

# Nueva estructura Snakemake (se creará dentro del proyecto)
SNAKEMAKE_DIR="${PROJECT_ROOT}/snakemake_pipeline"
```

---

## 📥 RUTAS DE DATOS DE ENTRADA

```bash
# Datos raw (input principal)
DATA_RAW="/Users/cesaresparza/New_Desktop/UCSD/8OG/organized/02_data/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"

# Datos procesados (si ya existen)
DATA_PROCESSED_DIR="/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/processed_data"
```

---

## 📤 RUTAS DE SALIDA (SNAKEMAKE)

```bash
# Outputs del Paso 1
OUTPUT_STEP1="${SNAKEMAKE_DIR}/outputs/step1"
OUTPUT_STEP1_FIGURES="${OUTPUT_STEP1}/figures"
OUTPUT_STEP1_TABLES="${OUTPUT_STEP1}/tables"
OUTPUT_STEP1_LOGS="${OUTPUT_STEP1}/logs"

# Outputs del Paso 1.5
OUTPUT_STEP1_5="${SNAKEMAKE_DIR}/outputs/step1_5"
OUTPUT_STEP1_5_FIGURES="${OUTPUT_STEP1_5}/figures"
OUTPUT_STEP1_5_TABLES="${OUTPUT_STEP1_5}/tables"
OUTPUT_STEP1_5_DATA="${OUTPUT_STEP1_5}/data"
OUTPUT_STEP1_5_LOGS="${OUTPUT_STEP1_5}/logs"

# Outputs del Paso 2
OUTPUT_STEP2="${SNAKEMAKE_DIR}/outputs/step2"
OUTPUT_STEP2_FIGURES="${OUTPUT_STEP2}/figures"
OUTPUT_STEP2_FIGURES_CLEAN="${OUTPUT_STEP2}/figures_clean"
OUTPUT_STEP2_TABLES="${OUTPUT_STEP2}/tables"
OUTPUT_STEP2_LOGS="${OUTPUT_STEP2}/logs"
```

---

## 🔧 RUTAS DE SCRIPTS

```bash
# Scripts R del Paso 1
SCRIPTS_STEP1="${SNAKEMAKE_DIR}/scripts/step1"

# Scripts R del Paso 1.5
SCRIPTS_STEP1_5="${SNAKEMAKE_DIR}/scripts/step1_5"

# Scripts R del Paso 2
SCRIPTS_STEP2="${SNAKEMAKE_DIR}/scripts/step2"

# Utilidades compartidas
SCRIPTS_UTILS="${SNAKEMAKE_DIR}/scripts/utils"
```

---

## 📋 RUTAS DE CONFIGURACIÓN

```bash
# Archivo de configuración principal
CONFIG_FILE="${SNAKEMAKE_DIR}/config/config.yaml"

# Conda environments
ENV_R_BASE="${SNAKEMAKE_DIR}/envs/r_base.yaml"
ENV_R_ANALYSIS="${SNAKEMAKE_DIR}/envs/r_analysis.yaml"
```

---

## 📊 RUTAS DE VIEWERS

```bash
# Viewers HTML generados
VIEWERS_DIR="${SNAKEMAKE_DIR}/viewers"
VIEWER_STEP1="${VIEWERS_DIR}/step1.html"
VIEWER_STEP1_5="${VIEWERS_DIR}/step1_5.html"
VIEWER_STEP2="${VIEWERS_DIR}/step2.html"
```

---

## 🔗 RUTAS DE REFERENCIA (Golden Copies)

```bash
# Golden copies de density heatmaps (Paso 2)
GOLDEN_COPIES_DIR="${PROJECT_ROOT}/pipeline_2/HTML_VIEWERS_FINALES/figures_paso2_CLEAN"
GOLDEN_2_13="${GOLDEN_COPIES_DIR}/FIG_2.13_DENSITY_HEATMAP_ALS.png"
GOLDEN_2_14="${GOLDEN_COPIES_DIR}/FIG_2.14_DENSITY_HEATMAP_CONTROL.png"
GOLDEN_2_15="${GOLDEN_COPIES_DIR}/FIG_2.15_DENSITY_COMBINED.png"
```

---

## 📝 USO EN CONFIG.YAML

Estas rutas se usarán en `config/config.yaml` así:

```yaml
paths:
  project_root: "/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo"
  snakemake_dir: "${paths.project_root}/snakemake_pipeline"
  
  data:
    raw: "/Users/cesaresparza/New_Desktop/UCSD/8OG/organized/02_data/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"
    processed_dir: "/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/processed_data"
  
  outputs:
    step1: "${paths.snakemake_dir}/outputs/step1"
    step1_5: "${paths.snakemake_dir}/outputs/step1_5"
    step2: "${paths.snakemake_dir}/outputs/step2"
  
  golden_copies:
    dir: "${paths.project_root}/pipeline_2/HTML_VIEWERS_FINALES/figures_paso2_CLEAN"
    fig_2_13: "${paths.golden_copies.dir}/FIG_2.13_DENSITY_HEATMAP_ALS.png"
    fig_2_14: "${paths.golden_copies.dir}/FIG_2.14_DENSITY_HEATMAP_CONTROL.png"
    fig_2_15: "${paths.golden_copies.dir}/FIG_2.15_DENSITY_COMBINED.png"
```

---

## ✅ VERIFICACIÓN

Para verificar que estas rutas existen, ejecutar:

```bash
echo "PROJECT_ROOT: $PROJECT_ROOT"
ls -d "$PROJECT_ROOT" && echo "✅ PROJECT_ROOT existe" || echo "❌ PROJECT_ROOT no existe"

echo "DATA_RAW: $DATA_RAW"
ls -f "$DATA_RAW" && echo "✅ DATA_RAW existe" || echo "❌ DATA_RAW no existe"

echo "DATA_PROCESSED_DIR: $DATA_PROCESSED_DIR"
ls -d "$DATA_PROCESSED_DIR" && echo "✅ DATA_PROCESSED_DIR existe" || echo "❌ DATA_PROCESSED_DIR no existe"
```

---

**Última actualización:** 2025-01-28

