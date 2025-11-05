# Step 1.5: VAF Quality Control

Estructura estandarizada del Paso 1.5, siguiendo el mismo patrón que `step1/` y `step2/`.

## 📁 Estructura

```
step1_5/
├── scripts/          # Scripts generadores
│   ├── 01_apply_vaf_filter.R
│   └── 02_generate_diagnostic_figures.R
├── viewers/          # Viewers HTML
│   └── STEP1_5.html
├── outputs/          # Resultados generados
│   ├── figures/      # Figuras PNG (11 total)
│   ├── tables/       # Tablas CSV (datos filtrados y estadísticas)
│   └── logs/         # Logs de ejecución
├── config/           # Configuración (si es necesario)
└── run_step1_5.R     # Orquestador principal
```

## 🚀 Uso

### Ejecutar todo el Paso 1.5:

```bash
cd step1_5
Rscript run_step1_5.R
```

### Ejecutar un script individual:

```bash
cd step1_5/scripts
Rscript 01_apply_vaf_filter.R
```

## 📊 Figuras generadas

### Quality Control (4 figuras):
- **QC_FIG1**: VAF Distribution of filtered values
- **QC_FIG2**: Filter impact by mutation type
- **QC_FIG3**: Top affected miRNAs
- **QC_FIG4**: Before vs After filtering

### Diagnostic (7 figuras):
- **FIG1**: SNVs Heatmap (VAF-filtered)
- **FIG2**: Counts Heatmap (VAF-filtered)
- **FIG3**: G Transversions SNVs
- **FIG4**: G Transversions Counts
- **FIG5**: Bubble Plot
- **FIG6**: Violin Distributions
- **FIG7**: Fold Change

## 📋 Tablas generadas

- `ALL_MUTATIONS_VAF_FILTERED.csv` - Dataset principal (VAF >= 0.5 → NaN)
- `vaf_filter_report.csv` - Reporte detallado de valores filtrados
- `vaf_statistics_by_type.csv` - Estadísticas por tipo de mutación
- `vaf_statistics_by_mirna.csv` - Estadísticas por miRNA
- `sample_metrics_vaf_filtered.csv` - Métricas por muestra
- `position_metrics_vaf_filtered.csv` - Métricas por posición
- `mutation_type_summary_vaf_filtered.csv` - Resumen por tipo

## 📂 Datos de entrada

- **Datos originales**: `../../UCSD/8OG/final_analysis/tercer_intento/step_by_step_analysis/step1_original_data.csv`
- Requiere columnas de SNV counts Y total counts para calcular VAF

## 📄 Viewer HTML

Ver todas las figuras en:
- `viewers/STEP1_5.html`

## 🔄 Migración desde 01.5_vaf_quality_control/

Este paso fue migrado desde `01.5_vaf_quality_control/` para mantener consistencia:
- Scripts adaptados para usar rutas relativas
- Estructura de directorios estandarizada
- `run_step1_5.R` creado como orquestador


Estructura estandarizada del Paso 1.5, siguiendo el mismo patrón que `step1/` y `step2/`.

## 📁 Estructura

```
step1_5/
├── scripts/          # Scripts generadores
│   ├── 01_apply_vaf_filter.R
│   └── 02_generate_diagnostic_figures.R
├── viewers/          # Viewers HTML
│   └── STEP1_5.html
├── outputs/          # Resultados generados
│   ├── figures/      # Figuras PNG (11 total)
│   ├── tables/       # Tablas CSV (datos filtrados y estadísticas)
│   └── logs/         # Logs de ejecución
├── config/           # Configuración (si es necesario)
└── run_step1_5.R     # Orquestador principal
```

## 🚀 Uso

### Ejecutar todo el Paso 1.5:

```bash
cd step1_5
Rscript run_step1_5.R
```

### Ejecutar un script individual:

```bash
cd step1_5/scripts
Rscript 01_apply_vaf_filter.R
```

## 📊 Figuras generadas

### Quality Control (4 figuras):
- **QC_FIG1**: VAF Distribution of filtered values
- **QC_FIG2**: Filter impact by mutation type
- **QC_FIG3**: Top affected miRNAs
- **QC_FIG4**: Before vs After filtering

### Diagnostic (7 figuras):
- **FIG1**: SNVs Heatmap (VAF-filtered)
- **FIG2**: Counts Heatmap (VAF-filtered)
- **FIG3**: G Transversions SNVs
- **FIG4**: G Transversions Counts
- **FIG5**: Bubble Plot
- **FIG6**: Violin Distributions
- **FIG7**: Fold Change

## 📋 Tablas generadas

- `ALL_MUTATIONS_VAF_FILTERED.csv` - Dataset principal (VAF >= 0.5 → NaN)
- `vaf_filter_report.csv` - Reporte detallado de valores filtrados
- `vaf_statistics_by_type.csv` - Estadísticas por tipo de mutación
- `vaf_statistics_by_mirna.csv` - Estadísticas por miRNA
- `sample_metrics_vaf_filtered.csv` - Métricas por muestra
- `position_metrics_vaf_filtered.csv` - Métricas por posición
- `mutation_type_summary_vaf_filtered.csv` - Resumen por tipo

## 📂 Datos de entrada

- **Datos originales**: `../../UCSD/8OG/final_analysis/tercer_intento/step_by_step_analysis/step1_original_data.csv`
- Requiere columnas de SNV counts Y total counts para calcular VAF

## 📄 Viewer HTML

Ver todas las figuras en:
- `viewers/STEP1_5.html`

## 🔄 Migración desde 01.5_vaf_quality_control/

Este paso fue migrado desde `01.5_vaf_quality_control/` para mantener consistencia:
- Scripts adaptados para usar rutas relativas
- Estructura de directorios estandarizada
- `run_step1_5.R` creado como orquestador


Estructura estandarizada del Paso 1.5, siguiendo el mismo patrón que `step1/` y `step2/`.

## 📁 Estructura

```
step1_5/
├── scripts/          # Scripts generadores
│   ├── 01_apply_vaf_filter.R
│   └── 02_generate_diagnostic_figures.R
├── viewers/          # Viewers HTML
│   └── STEP1_5.html
├── outputs/          # Resultados generados
│   ├── figures/      # Figuras PNG (11 total)
│   ├── tables/       # Tablas CSV (datos filtrados y estadísticas)
│   └── logs/         # Logs de ejecución
├── config/           # Configuración (si es necesario)
└── run_step1_5.R     # Orquestador principal
```

## 🚀 Uso

### Ejecutar todo el Paso 1.5:

```bash
cd step1_5
Rscript run_step1_5.R
```

### Ejecutar un script individual:

```bash
cd step1_5/scripts
Rscript 01_apply_vaf_filter.R
```

## 📊 Figuras generadas

### Quality Control (4 figuras):
- **QC_FIG1**: VAF Distribution of filtered values
- **QC_FIG2**: Filter impact by mutation type
- **QC_FIG3**: Top affected miRNAs
- **QC_FIG4**: Before vs After filtering

### Diagnostic (7 figuras):
- **FIG1**: SNVs Heatmap (VAF-filtered)
- **FIG2**: Counts Heatmap (VAF-filtered)
- **FIG3**: G Transversions SNVs
- **FIG4**: G Transversions Counts
- **FIG5**: Bubble Plot
- **FIG6**: Violin Distributions
- **FIG7**: Fold Change

## 📋 Tablas generadas

- `ALL_MUTATIONS_VAF_FILTERED.csv` - Dataset principal (VAF >= 0.5 → NaN)
- `vaf_filter_report.csv` - Reporte detallado de valores filtrados
- `vaf_statistics_by_type.csv` - Estadísticas por tipo de mutación
- `vaf_statistics_by_mirna.csv` - Estadísticas por miRNA
- `sample_metrics_vaf_filtered.csv` - Métricas por muestra
- `position_metrics_vaf_filtered.csv` - Métricas por posición
- `mutation_type_summary_vaf_filtered.csv` - Resumen por tipo

## 📂 Datos de entrada

- **Datos originales**: `../../UCSD/8OG/final_analysis/tercer_intento/step_by_step_analysis/step1_original_data.csv`
- Requiere columnas de SNV counts Y total counts para calcular VAF

## 📄 Viewer HTML

Ver todas las figuras en:
- `viewers/STEP1_5.html`

## 🔄 Migración desde 01.5_vaf_quality_control/

Este paso fue migrado desde `01.5_vaf_quality_control/` para mantener consistencia:
- Scripts adaptados para usar rutas relativas
- Estructura de directorios estandarizada
- `run_step1_5.R` creado como orquestador

