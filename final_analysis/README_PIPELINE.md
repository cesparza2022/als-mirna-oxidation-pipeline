# 🧬 Pipeline de Análisis de SNVs en miRNAs para ALS

**Pipeline modular, reproducible y auto-detectable para análisis de oxidación de miRNAs**

---

## 🎯 **Visión General**

Este pipeline analiza **Single Nucleotide Variants (SNVs)** en miRNAs para detectar **oxidación (8-oxo-guanosina)** usando mutaciones **G>T** como proxy, en el contexto de **Amyotrophic Lateral Sclerosis (ALS)**.

### **Características Clave**:
- ✅ **Auto-detectable**: Funciona con cualquier número de muestras/SNVs
- ✅ **Modular**: Cada módulo es independiente y reutilizable  
- ✅ **Reproducible**: Configuración YAML centralizada
- ✅ **Flexible**: Parámetros configurables sin modificar código
- ✅ **Validado**: Control de calidad integrado

---

## 🏗️ **Estructura del Pipeline**

### **Módulos del Pipeline**:

```
MÓDULO 1: PREPARACIÓN DE DATOS
├─ Auto-detección de estructura del input
├─ Split-collapse (separar múltiples mutaciones)
├─ Cálculo de VAFs (Variant Allele Frequencies)
├─ Filtrado VAF > 50% → NaN (isoformas, no oxidación)
├─ Parsing de metadatos de muestras
└─ Control de calidad básico

MÓDULO 2: PANORAMA GENERAL (TODOS los SNVs)
├─ Análisis descriptivo global
├─ Top miRNAs por cantidad de SNVs
├─ Top miRNAs por cantidad de cuentas
├─ Top miRNAs por VAF promedio
└─ Comparación ALS vs Control (todos los SNVs)

MÓDULO 3: ENFOQUE EN OXIDACIÓN (SOLO G>T)
├─ Filtrado de SNVs G>T
├─ Top miRNAs por SNVs G>T
├─ Comparación ALS vs Control (solo G>T)
└─ Comparación Módulo 2 vs Módulo 3

MÓDULO 4: ANÁLISIS POSICIONAL
├─ Distribución de SNVs por posición (todos)
├─ Distribución de SNVs por posición (G>T)
└─ Comparación Seed vs Non-Seed

MÓDULO 5: TOP miRNAs CON G>T EN REGIÓN SEED
├─ Identificación de miRNAs relevantes
├─ Caracterización detallada
├─ Análisis de familias (ej. let-7)
└─ Patrones en posiciones específicas

MÓDULO 6: ANÁLISIS AVANZADOS
├─ Clustering de muestras/SNVs/miRNAs
├─ Análisis de enriquecimiento de vías
├─ Análisis temporal (si aplica)
├─ Descubrimiento de motivos
└─ Análisis de especificidad
```

---

## 📁 **Estructura de Directorios**

```
miRNA-Oxidation-Pipeline/
├── config/
│   └── default_config.yaml          # Configuración centralizada
├── data/
│   ├── raw/
│   │   └── miRNA_count.Q33.txt      # Dataset original
│   └── processed/                   # Datos procesados
├── src/
│   ├── core/
│   │   ├── io.R                     # Funciones de I/O
│   │   ├── preprocessing.R          # Funciones de procesamiento
│   │   ├── statistics.R             # Funciones estadísticas
│   │   └── visualization.R          # Funciones de visualización
│   └── modules/
│       ├── module_01_data_loading.R # Módulo 1
│       ├── module_02_general.R      # Módulo 2
│       ├── module_03_gt_specific.R  # Módulo 3
│       ├── module_04_positional.R   # Módulo 4
│       ├── module_05_gt_seed.R      # Módulo 5
│       └── module_06_advanced.R     # Módulo 6
├── outputs/
│   ├── step_01_prep/               # Salidas del Módulo 1
│   ├── step_02_general/            # Salidas del Módulo 2
│   ├── step_03_gt_specific/        # Salidas del Módulo 3
│   ├── step_04_positional/         # Salidas del Módulo 4
│   ├── step_05_gt_seed/            # Salidas del Módulo 5
│   └── step_06_advanced/           # Salidas del Módulo 6
├── tests/
│   └── test_module_01.R            # Tests de validación
├── logs/                           # Archivos de log
└── README_PIPELINE.md              # Este archivo
```

---

## 🚀 **Inicio Rápido**

### **1. Configuración Inicial**

```bash
# Clonar o descargar el pipeline
cd miRNA-Oxidation-Pipeline

# Verificar que el archivo de datos esté en su lugar
ls data/raw/miRNA_count.Q33.txt
```

### **2. Ejecutar Módulo 1 (Preparación de Datos)**

```r
# En R o RStudio
setwd("miRNA-Oxidation-Pipeline")

# Cargar y ejecutar Módulo 1
source("src/modules/module_01_data_loading.R")

results <- run_module_01_data_loading(
  input_file = "data/raw/miRNA_count.Q33.txt",
  config_path = "config/default_config.yaml"
)
```

### **3. Verificar Resultados**

```bash
# Verificar archivos generados
ls outputs/step_01_prep/tables/
ls outputs/step_01_prep/figures/
ls outputs/step_01_prep/reports/

# Ver resumen
cat outputs/step_01_prep/reports/summary.txt
```

---

## ⚙️ **Configuración**

### **Archivo de Configuración**: `config/default_config.yaml`

#### **Parámetros Clave**:

```yaml
# Filtrado de VAFs
filtering:
  vaf_filtering:
    threshold: 0.5                    # VAF > 50% → NaN
    action: "to_nan"                  # Convertir a NaN (no eliminar)

# Regiones funcionales
analysis:
  position_analysis:
    seed_region: [2, 3, 4, 5, 6, 7, 8]  # Región seed canónica

# Tipos de mutaciones
  mutation_types:
    oxidation_proxy: ["G>T"]          # Proxy para oxidación
    all_types: ["A>C", "A>G", "A>T", "C>A", "C>G", "C>T", "G>A", "G>C", "G>T", "T>A", "T>C", "T>G"]

# Análisis por grupos
  group_analysis:
    cohorts: ["ALS", "control"]       # Grupos a comparar
```

---

## 📊 **Formato de Input**

### **Patrón del Archivo de Entrada**:

```
┌──────────────┬──────────┬──────────────────────┬──────────────────────┐
│ miRNA name   │ pos:mut  │ Sample_1             │ Sample_1 (PM+1MM+2MM)│
│              │          │ Sample_2             │ Sample_2 (PM+1MM+2MM)│
│              │          │ ...                  │ ...                  │
│              │          │ Sample_N             │ Sample_N (PM+1MM+2MM)│
└──────────────┴──────────┴──────────────────────┴──────────────────────┘

Fórmula: Total_Columnas = 2 + 2N
donde N = número de muestras (auto-detectado)
```

### **Características del Input**:
- ✅ **TSV (Tab-Separated Values)**
- ✅ **2 columnas metadata**: `miRNA name`, `pos:mut`
- ✅ **N columnas counts**: nombres de muestras (sin sufijo)
- ✅ **N columnas totales**: nombres + `" (PM+1MM+2MM)"`
- ✅ **Emparejamiento automático**: count "X" ↔ total "X (PM+1MM+2MM)"

### **Ejemplo de Datos**:

| miRNA name | pos:mut | Count_S1 | Count_S2 | Total_S1 | Total_S2 |
|------------|---------|----------|----------|----------|----------|
| hsa-let-7a-5p | PM | 599187.0 | 24967.0 | 611158.0 | 25598.0 |
| hsa-let-7a-5p | 2:GT | 9.0 | 0.0 | **611158.0** | **25598.0** |

**Interpretación**:
- Sample 1: 9 reads con G→T de 611,158 totales → VAF = 0.0015%
- Sample 2: 0 reads con G→T de 25,598 totales → VAF = 0%

---

## 🔬 **Decisiones de Diseño**

### **1. VAF Threshold (50%)**

**Justificación**: VAFs > 50% probablemente representan:
- **Isoformas de miRNAs** (let-7a-5p vs let-7a-3p)
- **miRNAs no descritos** en miRBase
- **IsomiRs** (variantes de procesamiento)
- **Artefactos de alineamiento**

**NO representan oxidación** (8-oxo-guanosina), cuya frecuencia esperada es 0.01-5%.

### **2. Seed Region (Posiciones 2-8)**

**Justificación**: Región canónica más crítica para:
- Reconocimiento de mRNA targets
- Función del complejo RISC
- Conservación evolutiva
- Impacto funcional de mutaciones

---

## 📈 **Outputs del Pipeline**

### **Por Módulo**:

#### **Módulo 1 - Preparación**:
- `processed_data.csv`: Dataset procesado con VAFs
- `sample_metadata.csv`: Metadatos de muestras parseados
- `quality_analysis.json`: Análisis de calidad detallado
- `vaf_distribution.png`: Distribución de VAFs
- `mutation_type_distribution.png`: Distribución de tipos de mutación
- `position_distribution.png`: Distribución por posición
- `summary.txt`: Reporte de resumen

#### **Módulos 2-6**:
- **Tablas**: Resultados estadísticos, rankings, comparaciones
- **Figuras**: Heatmaps, boxplots, scatter plots, dendrogramas
- **Reportes**: Resúmenes ejecutivos y análisis detallados

---

## 🧪 **Testing y Validación**

### **Ejecutar Tests**:

```r
# Test completo del Módulo 1
source("test_module_01.R")
```

### **Validaciones Incluidas**:
- ✅ Auto-detección de estructura
- ✅ Validación de datos
- ✅ Procesamiento completo
- ✅ Generación de outputs
- ✅ Análisis de calidad

---

## 🔧 **Dependencias**

### **R Packages Requeridos**:

```r
# Core packages
library(tidyverse)    # Manipulación de datos
library(yaml)         # Configuración
library(jsonlite)     # JSON I/O

# Statistical packages
library(stats)        # Tests estadísticos
library(lme4)         # Modelos de efectos mixtos

# Visualization packages
library(ggplot2)      # Gráficos
library(pheatmap)     # Heatmaps
library(RColorBrewer) # Paletas de colores

# Analysis packages
library(clusterProfiler) # Análisis de enriquecimiento
library(DirichletMultinomial) # Modelos multinomiales
```

### **Instalación**:

```r
# Instalar paquetes requeridos
install.packages(c("tidyverse", "yaml", "jsonlite", "lme4", 
                   "pheatmap", "RColorBrewer", "clusterProfiler"))
```

---

## 📚 **Documentación Adicional**

- **`INPUT_FORMAT_PATTERN.md`**: Patrón detallado del formato de input
- **`DESIGN_DECISIONS.md`**: Decisiones de diseño y justificaciones
- **`ANALYSIS_STRUCTURE_REVISED.md`**: Estructura de análisis detallada
- **`RESUMEN_EJECUTIVO_PIPELINE.md`**: Resumen ejecutivo del plan

---

## 🚀 **Próximos Pasos**

1. ✅ **Módulo 1**: Completado y validado
2. 🔄 **Módulo 2**: Panorama General (todos SNVs)
3. 🔄 **Módulo 3**: Enfoque G>T (oxidación)
4. 🔄 **Módulos 4-6**: Análisis posicional, seed, y avanzados
5. 🔄 **Testing completo**: Validación end-to-end
6. 🔄 **Documentación final**: Guías de usuario y ejemplos

---

## 📞 **Soporte**

Para preguntas o problemas:
1. Revisar logs en `logs/pipeline.log`
2. Verificar configuración en `config/default_config.yaml`
3. Ejecutar tests de validación
4. Consultar documentación en `docs/`

---

**Pipeline desarrollado por César Esparza - Octubre 2025**






