# 🐍 PLAN DE MIGRACIÓN A SNAKEMAKE

**Objetivo:** Convertir el pipeline actual a Snakemake para hacerlo reproducible, versionable y GitHub-ready.

**Fecha inicio:** 2025-01-28

---

## 📍 RUTAS ABSOLUTAS BASE

```bash
# Raíz del proyecto
PROJECT_ROOT="/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo"

# Datos de entrada
DATA_RAW="/Users/cesaresparza/New_Desktop/UCSD/8OG/organized/02_data/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"
DATA_PROCESSED="/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/processed_data"

# Nueva estructura Snakemake (dentro del proyecto)
SNAKEMAKE_DIR="${PROJECT_ROOT}/snakemake_pipeline"
```

---

## 🗂️ ESTRUCTURA PROPUESTA PARA SNAKEMAKE

```
snakemake_pipeline/
├── Snakefile                    # Orquestador principal
├── config/
│   └── config.yaml             # Configuración centralizada
├── envs/
│   ├── r_base.yaml             # Conda env para R base
│   └── r_analysis.yaml         # Conda env para análisis R
├── scripts/
│   ├── step1/
│   │   ├── 01_dataset_evolution.R
│   │   ├── 02_gt_count_by_position.R
│   │   ├── 03_gx_spectrum.R
│   │   ├── 04_positional_fraction.R
│   │   ├── 05_gcontent_analysis.R
│   │   ├── 06_seed_vs_nonseed.R
│   │   └── 07_gt_specificity.R
│   ├── step1_5/
│   │   ├── 01_apply_vaf_filter.R
│   │   └── 02_generate_diagnostic_figures.R
│   ├── step2/
│   │   ├── 01_vaf_comparison.R
│   │   ├── 02_vaf_distributions.R
│   │   ├── 03_volcano.R
│   │   ├── 04_heatmap_raw.R
│   │   ├── 05_zscore_heatmap.R
│   │   ├── 06_positional.R
│   │   ├── 07_pca_permanova.R
│   │   ├── 08_clustering.R
│   │   ├── 09_cv_analysis.R
│   │   ├── 10_gt_ratio.R
│   │   ├── 11_mutation_spectrum.R
│   │   ├── 12_enrichment.R
│   │   └── 13_15_density_heatmaps.R
│   └── utils/
│       ├── functions_common.R  # Funciones compartidas
│       └── build_viewers.R     # Generador de HTML viewers
├── rules/
│   ├── step1.smk               # Reglas del Paso 1
│   ├── step1_5.smk             # Reglas del Paso 1.5
│   ├── step2.smk               # Reglas del Paso 2
│   └── viewers.smk             # Reglas para generar viewers HTML
├── outputs/
│   ├── step1/
│   │   ├── figures/
│   │   ├── tables/
│   │   └── logs/
│   ├── step1_5/
│   │   ├── figures/
│   │   ├── tables/
│   │   ├── data/
│   │   └── logs/
│   └── step2/
│       ├── figures/
│       ├── figures_clean/
│       ├── tables/
│       └── logs/
├── viewers/
│   ├── step1.html
│   ├── step1_5.html
│   └── step2.html
├── .gitignore
├── README.md
├── requirements.txt            # Python dependencies
└── environment.yml             # Conda environments
```

---

## 📋 PLAN DE EJECUCIÓN PASO A PASO

### **FASE 0: Preparación (VERIFICAR ANTES DE CONTINUAR)**

#### ✅ Paso 0.1: Crear estructura base
- [ ] Crear directorio `snakemake_pipeline/`
- [ ] Crear subdirectorios: `config/`, `scripts/`, `rules/`, `outputs/`, `viewers/`, `envs/`
- [ ] Verificar rutas absolutas de datos de entrada
- **ArchivoQR:** `snakemake_pipeline/`

#### ✅ Paso 0.2: Configuración base
- [ ] Crear `config/config.yaml` con rutas absolutas y parámetros
- [ ] Crear `.gitignore` apropiado
- [ ] Crear `README.md` básico
- **ArchivoQR:** `snakemake_pipeline/config/config.yaml`

#### ✅ Paso 导师.3: Conda environments
- [ ] Crear `envs/r_base.yaml` con R y paquetes básicos
- [ ] Crear `envs/r_analysis.yaml` con todos los paquetes R necesarios
- [ ] Verificar que los environments se crean correctamente
- **ArchivoQR:** `snakemake_pipeline/envs/r_base.yaml`, `envs/r_analysis.yaml`

---

### **FASE 1: Migrar Paso 1 (Análisis Inicial)**

#### ✅ Paso 1.1: Preparar scripts R
- [ ] Copiar scripts de `STEP1_ORGANIZED/scripts/` a `snakemake_pipeline/scripts/step1/`
- [ ] Adaptar scripts para recibir parámetros desde Snakemake (_idir_, _odir_)
- [ ] Extraer funciones comunes a `scripts/utils/functions_common.R`
- **ArchivoQR:** `snakemake_pipeline/scripts/step1/`

#### ✅ Paso 1.2: Crear reglas Snakemake (Paso 1)
- [ ] Crear `rules/step1.smk` con reglas para cada figura/tabla
- [ ] Definir inputs, outputs, y parámetros
- [ ] Probar ejecución de una sola regla: `snakemake -s rules/step1.smk figure_1a`
- **ArchivoQR:** `snakemake_pipeline/rules/step1.smk`

#### ✅ Paso 1.3: Integrar en Snakefile principal
- [ ] Incluir `rules/step1.smk` en `Snakefile`
- [ ] Probar ejecución completa: `snakemake -j 1 all_step1`
- [ ] Verificar que todas las figuras/tablas se generen correctamente
- **ArchivoQR:** `snakemake_pipeline/Snakefile`

#### ✅ Paso 1.4: Generar viewer HTML
- [ ] Crear regla para generar `viewers/step1.html`
- [ ] Verificar que el viewer se vea correctamente
- **ArchivoQR:** `snakemake_pipeline/viewers/step1.html`

---

### **FASE 2: Migrar Paso 1.5 (Control VAF)**

#### ✅ Paso 2.1: Preparar scripts R
- [ ] Copiar scripts de `01.5_vaf_quality_control/scripts/` a `snakemake_pipeline/scripts/step1_5/`
- [ ] Adaptar para Snakemake (inputs/outputs)
- **ArchivoQR:** `snakemake_pipeline/scripts/step1_5/`

#### ✅ Paso 2.2: Crear reglas Snakemake (Paso 1.5)
- [ ] Crear `rules/step1_5.smk`
- [ ] Definir dependencia: output del Paso 1.5 → input del Paso 2
- [ ] Probar ejecución: `snakemake -률 rules/step1_5.smk all_step1_5`
- **ArchivoQR:** `snakemake_pipeline/rules/step1_5.smk`

#### ✅ Paso 2.3: Integrar y verificar
- [ ] Incluir en `Snakefile`
- [ ] Verificar que los datos filtrados (`ALL_MUTATIONS_VAF_FILTERED.csv`) se generen
- [ ] Generar viewer: `viewers/step1_5.html`
- **ArchivoQR:** `snakemake_pipeline/outputs/step1_5/data/ALL_MUTATIONS_VAF_FILTERED.csv`

---

### **FASE 3: Migrar Paso 2 (Comparaciones)**

#### ✅ Paso 3.1: Preparar scripts R
- [ ] Copiar scripts de `step2/scripts/` a `snakemake_pipeline/scripts/step2/`
- [ ] Adaptar rutas y parámetros
- [ ] Identificar dependencias entre figuras (orden de ejecución)
- **ArchivoQR:** `snakemake_pipeline/scripts/step2/`

#### ✅ Paso 3.2: Crear reglas Snakemake (Paso 2)
- [ ] Crear `rules/step2.smk` con reglas para 15 figuras
- [ ] Definir dependencias: Paso 1.5 → Paso 2
- [ ] Manejar golden copies (2.13-2.15) como inputs externos o reglas de copy
- [ ] Probar ejecución de figura individual: `snakemake figure_2_1`
- **ArchivoQR:** `snakemake_pipeline/rules/step2.smk`

#### ✅ Paso 3.3: Integrar y verificar
- [ ] Incluir en `Snakefile`
- [ ] Probar ejecución completa: `snakemake -j 4 all_step2` (paralelo)
- [ ] Verificar todas las figuras se generen
- **ArchivoQR:** `snakemake_pipeline/outputs/step2/figures/`

#### ✅ Paso 3.4: Generar viewer embebido
- [ ] Crear regla para `viewers/step2.html` con imágenes embebidas
- [ ] Verificar visualización
- **ArchivoQR:** `snakemake_pipeline/viewers/step2.html`

---

### **FASE 4: Optimización y Documentación**

#### ✅ Paso 4.1: Snakemake principal (all)
- [ ] Crear regla `all` que ejecute los 3 pasos en orden
- [ ] Agregar checkpoints para validación
- [ ] Agregar logging
- **ArchivoQR:** `snakemake_pipeline/Snakefile` (completo)

#### ✅ Paso 4.2: Documentación
- [ ] Actualizar `README.md` con instrucciones de uso
- [ ] Documentar cada regla en comentarios
- [ ] Crear `docs/PIPELINE_DOCUMENTATION.md`
- **ArchivoQR:** `snakemake_pipeline/README.md`

#### ✅ Paso 4.3: GitHub preparation
- [ ] Agregar `.gitignore` completo
- [ ] Agregar `LICENSE`
- [ ] Crear `.github/workflows/` para CI (opcional)
- [ ] Verificar que no haya rutas absolutas hardcodeadas (solo en config)
- **ArchivoQR:** `snakemake_pipeline/.gitignore`

#### ✅ Paso 4.4: Testing completo
- [ ] Ejecutar pipeline completo desde cero: `snakemake --delete-all-output && snakemake -j 1`
- [ ] Verificar todos los outputs
- [ ] Verificar viewers HTML
- **ArchivoQR:** Logs en `snakemake_pipeline/outputs/*/logs/`

---

## 🔧 COMANDOS SNAKEMAKE CLAVE

```bash
# Ejecutar todo el pipeline
snakemake -j 1

# Ejecutar solo Paso 1
snakemake -j 1 all_step1

# Ejecutar una regla específica
snakemake figure_1a

# Ver qué se ejecutaría (dry-run)
snakemake -n

# Generar diagrama del pipeline
snakemake --dag | dot -Tpng > pipeline_dag.png

# Ejecutar en modo verbose
snakemake -j 1 --printshellcmds

# Limpiar outputs y volver a ejecutar
snakemake --delete-all-output && snakemake -j 1
```

---

## 📝 CHECKLIST DE VERIFICACIÓN POR FASE

### Después de cada fase, verificar:
- [ ] Todas las figuras se generan correctamente
- [ ] Todas las tablas se generan correctamente
- [ ] Los viewers HTML funcionan y muestran todas las figuras
- [ ] Los logs no muestran errores
- [ ] Las rutas en los scripts son relativas o desde config
- [ ] El pipeline es reproducible (ejecutar 2 veces da mismos resultados)

---

## 🎯 ORDEN DE EJECUCIÓN RECOMENDADO

1. **FASE 0** → Preparar estructura base
2. **FASE 1** → Migrar Paso 1 (más simple)
3. **Verificar FASE 1** antes de continuar
4. **FASE 2** → Migrar Paso 1.5
5. **Verificar FASE 2** antes de continuar
6. **FASE 3** → Migrar Paso 2 (más complejo)
7. **Verificar FASE 3** antes de continuar
8. **FASE 4** → Optimización final

---

## 📊 ARCHIVOS DE VERIFICACIÓN (QR = Quick Reference)

Cada paso tiene un "ArchivoQR" que debes revisar para verificar que el paso se completó correctamente.

---

**Estado actual:** 🟡 Plan creado - Pendiente inicio de FASE 0

**Próximo paso:** Ejecutar FASE 0, Paso 0.1 (Crear estructura base)

