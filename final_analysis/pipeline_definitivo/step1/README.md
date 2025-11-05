# Step 1: Exploratory Analysis

Estructura estandarizada del Paso 1, siguiendo el mismo patrón que `step2/`.

## 📁 Estructura

```
step1/
├── scripts/          # Scripts generadores de figuras
│   ├── 02_gt_count_by_position.R
│   ├── 03_gx_spectrum.R
│   ├── 04_positional_fraction.R
│   ├── 05_gcontent.R
│   ├── 06_seed_vs_nonseed.R
│   └── 07_gt_specificity.R
├── viewers/          # Viewers HTML
│   └── STEP1.html
├── outputs/          # Resultados generados
│   ├── figures/      # Figuras PNG
│   ├── tables/       # Tablas CSV
│   └── logs/         # Logs de ejecución
├── config/           # Configuración (si es necesario)
└── run_step1.R       # Orquestador principal
```

## 🚀 Uso

### Ejecutar todo el Paso 1:

```bash
cd step1
Rscript run_step1.R
```

### Ejecutar un script individual:

```bash
cd step1/scripts
Rscript 02_gt_count_by_position.R
```

## 📊 Figuras generadas

- **Panel B**: `step1_panelB_gt_count_by_position.png` - G>T Count by Position
- **Panel C**: `step1_panelC_gx_spectrum.png` - G>X Mutation Spectrum by Position
- **Panel D**: `step1_panelD_positional_fraction.png` - Positional Fraction of Mutations
- **Panel E**: `step1_panelE_FINAL_BUBBLE.png` - G-Content Landscape (Bubble Plot)
- **Panel F**: `step1_panelF_seed_interaction.png` - Seed vs Non-seed Comparison
- **Panel G**: `step1_panelG_gt_specificity.png` - G>T Specificity (Overall)

## 📋 Tablas generadas

- `TABLE_1.B_gt_counts_by_position.csv`
- `TABLE_1.C_gx_spectrum_by_position.csv`
- `TABLE_1.D_positional_fractions.csv`
- `TABLE_1.F_seed_vs_nonseed.csv`
- `TABLE_1.G_gt_specificity.csv`

## 📂 Datos de entrada

- **Datos procesados (CLEAN)**: `../pipeline_2/final_processed_data_CLEAN.csv`
- **Datos RAW**: `../../UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt`

## 📄 Viewer HTML

Ver todas las figuras en:
- `viewers/STEP1.html`

## 🔄 Migración desde STEP1_ORGANIZED/

Este paso fue migrado desde `STEP1_ORGANIZED/` para mantener consistencia con `step2/`:
- Scripts adaptados para usar rutas relativas a `step1/`
- Estructura de directorios estandarizada
- `run_step1.R` creado como orquestador (similar a `run_step2.R`)


Estructura estandarizada del Paso 1, siguiendo el mismo patrón que `step2/`.

## 📁 Estructura

```
step1/
├── scripts/          # Scripts generadores de figuras
│   ├── 02_gt_count_by_position.R
│   ├── 03_gx_spectrum.R
│   ├── 04_positional_fraction.R
│   ├── 05_gcontent.R
│   ├── 06_seed_vs_nonseed.R
│   └── 07_gt_specificity.R
├── viewers/          # Viewers HTML
│   └── STEP1.html
├── outputs/          # Resultados generados
│   ├── figures/      # Figuras PNG
│   ├── tables/       # Tablas CSV
│   └── logs/         # Logs de ejecución
├── config/           # Configuración (si es necesario)
└── run_step1.R       # Orquestador principal
```

## 🚀 Uso

### Ejecutar todo el Paso 1:

```bash
cd step1
Rscript run_step1.R
```

### Ejecutar un script individual:

```bash
cd step1/scripts
Rscript 02_gt_count_by_position.R
```

## 📊 Figuras generadas

- **Panel B**: `step1_panelB_gt_count_by_position.png` - G>T Count by Position
- **Panel C**: `step1_panelC_gx_spectrum.png` - G>X Mutation Spectrum by Position
- **Panel D**: `step1_panelD_positional_fraction.png` - Positional Fraction of Mutations
- **Panel E**: `step1_panelE_FINAL_BUBBLE.png` - G-Content Landscape (Bubble Plot)
- **Panel F**: `step1_panelF_seed_interaction.png` - Seed vs Non-seed Comparison
- **Panel G**: `step1_panelG_gt_specificity.png` - G>T Specificity (Overall)

## 📋 Tablas generadas

- `TABLE_1.B_gt_counts_by_position.csv`
- `TABLE_1.C_gx_spectrum_by_position.csv`
- `TABLE_1.D_positional_fractions.csv`
- `TABLE_1.F_seed_vs_nonseed.csv`
- `TABLE_1.G_gt_specificity.csv`

## 📂 Datos de entrada

- **Datos procesados (CLEAN)**: `../pipeline_2/final_processed_data_CLEAN.csv`
- **Datos RAW**: `../../UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt`

## 📄 Viewer HTML

Ver todas las figuras en:
- `viewers/STEP1.html`

## 🔄 Migración desde STEP1_ORGANIZED/

Este paso fue migrado desde `STEP1_ORGANIZED/` para mantener consistencia con `step2/`:
- Scripts adaptados para usar rutas relativas a `step1/`
- Estructura de directorios estandarizada
- `run_step1.R` creado como orquestador (similar a `run_step2.R`)


Estructura estandarizada del Paso 1, siguiendo el mismo patrón que `step2/`.

## 📁 Estructura

```
step1/
├── scripts/          # Scripts generadores de figuras
│   ├── 02_gt_count_by_position.R
│   ├── 03_gx_spectrum.R
│   ├── 04_positional_fraction.R
│   ├── 05_gcontent.R
│   ├── 06_seed_vs_nonseed.R
│   └── 07_gt_specificity.R
├── viewers/          # Viewers HTML
│   └── STEP1.html
├── outputs/          # Resultados generados
│   ├── figures/      # Figuras PNG
│   ├── tables/       # Tablas CSV
│   └── logs/         # Logs de ejecución
├── config/           # Configuración (si es necesario)
└── run_step1.R       # Orquestador principal
```

## 🚀 Uso

### Ejecutar todo el Paso 1:

```bash
cd step1
Rscript run_step1.R
```

### Ejecutar un script individual:

```bash
cd step1/scripts
Rscript 02_gt_count_by_position.R
```

## 📊 Figuras generadas

- **Panel B**: `step1_panelB_gt_count_by_position.png` - G>T Count by Position
- **Panel C**: `step1_panelC_gx_spectrum.png` - G>X Mutation Spectrum by Position
- **Panel D**: `step1_panelD_positional_fraction.png` - Positional Fraction of Mutations
- **Panel E**: `step1_panelE_FINAL_BUBBLE.png` - G-Content Landscape (Bubble Plot)
- **Panel F**: `step1_panelF_seed_interaction.png` - Seed vs Non-seed Comparison
- **Panel G**: `step1_panelG_gt_specificity.png` - G>T Specificity (Overall)

## 📋 Tablas generadas

- `TABLE_1.B_gt_counts_by_position.csv`
- `TABLE_1.C_gx_spectrum_by_position.csv`
- `TABLE_1.D_positional_fractions.csv`
- `TABLE_1.F_seed_vs_nonseed.csv`
- `TABLE_1.G_gt_specificity.csv`

## 📂 Datos de entrada

- **Datos procesados (CLEAN)**: `../pipeline_2/final_processed_data_CLEAN.csv`
- **Datos RAW**: `../../UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt`

## 📄 Viewer HTML

Ver todas las figuras en:
- `viewers/STEP1.html`

## 🔄 Migración desde STEP1_ORGANIZED/

Este paso fue migrado desde `STEP1_ORGANIZED/` para mantener consistencia con `step2/`:
- Scripts adaptados para usar rutas relativas a `step1/`
- Estructura de directorios estandarizada
- `run_step1.R` creado como orquestador (similar a `run_step2.R`)

