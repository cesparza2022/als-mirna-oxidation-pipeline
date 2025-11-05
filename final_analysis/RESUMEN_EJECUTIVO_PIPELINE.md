# 📊 RESUMEN EJECUTIVO - Pipeline miRNA Oxidation ALS

**Fecha**: Octubre 15, 2025  
**Estado**: ✅ Diseño confirmado y listo para implementación

---

## ✅ **DECISIONES CONFIRMADAS**

### 1. VAF Threshold: **50%**
**Justificación**: Isoformas de miRNAs y miRNAs no descritos. VAFs > 50% probablemente reflejan variantes estructurales del miRNA, no oxidación (esperada 0.01-5%).

### 2. Seed Region: **Posiciones 2-8**
**Justificación**: Estándar canónico (Bartel 2009, TargetScan 8.0). Posiciones críticas para reconocimiento de target.

### 3. VAF Action: **to_nan** (no eliminar)
**Justificación**: Mantener trazabilidad completa y permitir análisis de cobertura.

---

## 📋 **INPUT DEFINIDO**

### Archivo: `miRNA_count.Q33.txt`

```
68,969 filas × 832 columnas
├─ 2 metadata: miRNA name, pos:mut
├─ 415 SNV counts (313 ALS + 102 Control)
└─ 415 Totales (PM+1MM+2MM)

Formato:
miRNA name      pos:mut   Sample_1   ...   Sample_415   Sample_1_Total   ...
hsa-let-7a-5p   PM        599187.0   ...   118908.0     611158.0        ...
hsa-let-7a-5p   2:GT      9.0        ...   0.0          611158.0        ...

Mutaciones:
├─ PM = Perfect match (sin mutación)
├─ 2:GT = Posición 2, G→T (oxidación)
└─ 4:TC,18:TC = Múltiples (split-collapse)
```

**Especificación completa**: `INPUT_SPECIFICATION.md`

---

## 🏗️ **ESTRUCTURA DE ANÁLISIS REVISADA**

### **Filosofía**: General → Específico | Todos los SNVs → Solo G>T

---

## 📦 **6 MÓDULOS PRINCIPALES**

### **MÓDULO 1: PREPARACIÓN** (4 pasos)
```
Input: Dataset original TSV
Output: Dataset limpio con VAFs

1.1 Cargar dataset
1.2 Split-collapse (mutaciones múltiples)
1.3 Calcular VAFs (SNV_count / Total)
1.4 Filtrar VAF > 50% → NaN

Output: ~29,000 SNVs × ~850 columnas
Tiempo: ~2 min
```

---

### **MÓDULO 2: PANORAMA GENERAL** (Todos los SNVs) (4 pasos)
```
Objetivo: Entender contexto COMPLETO antes de enfocarnos en oxidación

2.1 Análisis por miRNA - # de SNVs
    └─ ¿Cuáles miRNAs más mutados?
    
2.2 Análisis por miRNA - Cuentas totales
    └─ ¿Cuáles SNVs con más reads?
    
2.3 Análisis por miRNA - VAF promedio
    └─ ¿Cuáles con mayor representación?
    
2.4 Comparación ALS vs Control (general)
    └─ ¿Diferencias globales entre grupos?

Outputs: 12 tablas, 15 figuras
Tiempo: ~3 min
```

---

### **MÓDULO 3: ENFOQUE OXIDACIÓN** (Solo G>T) (4 pasos)
```
Objetivo: Replicar análisis de Módulo 2 SOLO con G>T

3.1 Análisis por miRNA - # de G>T
    └─ ¿Cuáles miRNAs más oxidados?
    └─ Comparar con ranking general (Módulo 2.1)
    
3.2 Análisis por miRNA - Cuentas G>T
    └─ ¿Alta cantidad de G>T?
    
3.3 Análisis por miRNA - VAF de G>T
    └─ ¿Alta representación de oxidación?
    
3.4 Comparación ALS vs Control (G>T)
    └─ ¿Señal de oxidación más fuerte en G>T que en general?
    └─ Comparar con Módulo 2.4

Outputs: 12 tablas, 15 figuras
Tiempo: ~3 min

CLAVE: Figuras comparativas (Módulo 2 vs 3)
```

---

### **MÓDULO 4: ANÁLISIS POSICIONAL** (3 pasos)
```
Objetivo: Entender DÓNDE ocurren las mutaciones (posiciones 1-23)

4.1 Distribución por posición (Todos los SNVs)
    └─ ¿Hay posiciones más variables?
    
4.2 Distribución por posición (Solo G>T)
    └─ ¿Hotspots de oxidación?
    └─ Comparar con 4.1
    
4.3 Seed vs Non-Seed (G>T)
    └─ ¿Enriquecimiento en región funcional?

Outputs: 9 tablas, 12 figuras
Tiempo: ~2 min

CLAVE: ¿G>T enriquecido en seed (2-8)?
```

---

### **MÓDULO 5: TOP miRNAs (G>T en Seed)** (3 pasos)
```
Objetivo: Analizar ~270 miRNAs con oxidación en región crítica

5.1 Caracterización de miRNAs con G>T en seed
    └─ Perfil completo de estos 270 miRNAs
    
5.2 Análisis de familias (let-7, miR-30, etc.)
    └─ ¿Patrones familiares?
    └─ let-7: posiciones 2, 4, 5 (patrón específico)
    
5.3 Posiciones específicas en seed (2-8)
    └─ ¿Todas las posiciones igual de oxidadas?
    └─ Heatmap: miRNA × posición seed

Outputs: 9 tablas, 10 figuras
Tiempo: ~3 min

HALLAZGO CLAVE: Patrón let-7 (2,4,5)
```

---

### **MÓDULO 6: ANÁLISIS AVANZADOS** (5 pasos)
```
Objetivo: Clustering, pathways, temporal, motivos

6.1 Clustering de muestras
    └─ ¿Se agrupan por ALS vs Control?
    
6.2 Clustering de miRNAs
    └─ ¿Grupos co-oxidados?
    
6.3 Pathway analysis
    └─ Targets de los 270 miRNAs
    └─ Enriquecimiento en pathways ALS
    
6.4 Análisis temporal (longitudinal)
    └─ ¿Aumenta oxidación con progresión?
    
6.5 Motivos de secuencia
    └─ Contexto G-rich enriquecido
    └─ Mecanismos de resistencia (miR-4500)

Outputs: 15 tablas, 20 figuras
Tiempo: ~8 min

HALLAZGOS CLAVE:
- let-7 vs miR-4500 (paradoja)
- 24× enriquecimiento G-rich
- 2 mecanismos de resistencia
```

---

## 📊 **COMPARACIONES CLAVE ENTRE MÓDULOS**

### Comparación 1: **General vs Oxidación** (Módulo 2 vs 3)

```
Pregunta: ¿Los miRNAs más oxidados (G>T) son diferentes de los más mutados en general?

Análisis:
├─ Top 20 miRNAs (Todos SNVs) - Módulo 2.1
├─ Top 20 miRNAs (Solo G>T) - Módulo 3.1
└─ ¿Overlap? ¿Enriquecimiento específico en G>T?

Figura sugerida:
Venn diagram: Top 20 (All) ∩ Top 20 (G>T)
```

---

### Comparación 2: **ALS vs Control** (Paso 2.4 vs 3.4)

```
Pregunta: ¿La señal de diferencia ALS vs Control es más fuerte en G>T?

Análisis:
├─ # SNVs significativos (Todos) - Módulo 2.4
├─ # SNVs significativos (G>T) - Módulo 3.4
└─ Comparar p-values, fold-changes

Figura sugerida:
Volcano plots lado-a-lado: All SNVs vs G>T only
```

---

### Comparación 3: **Posicional** (Paso 4.1 vs 4.2)

```
Pregunta: ¿G>T tiene distribución posicional diferente del resto?

Análisis:
├─ Distribución posicional (Todos) - Módulo 4.1
├─ Distribución posicional (G>T) - Módulo 4.2
└─ ¿Enriquecimiento en seed (2-8) específico de G>T?

Figura sugerida:
Barplot doble: All SNVs vs G>T, coloreado por región (seed, central, 3')
```

---

## 🔄 **FLUJO DE INFORMACIÓN**

### Diagrama de Dependencias:

```
MÓDULO 1 (Preparación)
    │
    ├──→ MÓDULO 2 (General - Todos SNVs)
    │         │
    │         └──→ Comparación ←──┐
    │                             │
    └──→ MÓDULO 3 (Oxidación - G>T)
              │
              └──→ MÓDULO 4 (Posicional)
                        │
                        └──→ MÓDULO 5 (Top miRNAs G>T seed)
                                  │
                                  └──→ MÓDULO 6 (Avanzados)
```

**Ventaja**: Cada módulo puede compararse con el anterior para identificar **especificidad de la señal de oxidación**.

---

## 🎯 **OUTPUTS CLAVE POR MÓDULO**

### Módulo 1: Preparación
**Figura principal**: Sankey diagram (transformaciones de datos)

### Módulo 2: Panorama General
**Figuras principales**:
- Top 20 miRNAs por SNVs, Cuentas, VAF
- ALS vs Control volcano plot (todos SNVs)

### Módulo 3: Oxidación
**Figuras principales**:
- Top 20 miRNAs por G>T
- ALS vs Control volcano plot (G>T)
- **Comparación lado-a-lado con Módulo 2**

### Módulo 4: Posicional
**Figuras principales**:
- Distribución posicional (barplot 1-23)
- Seed vs Non-Seed comparison
- Heatmap: miRNA × posición (G>T)

### Módulo 5: Top miRNAs (G>T seed)
**Figuras principales**:
- Caracterización de 270 miRNAs
- let-7 family heatmap (patrón 2,4,5)
- Posiciones específicas en seed

### Módulo 6: Avanzados
**Figuras principales**:
- PCA plot (muestras agrupadas)
- Dendrogram (miRNAs co-oxidados)
- Pathway enrichment heatmap
- let-7 vs miR-4500 comparison

---

## 📈 **MÉTRICAS DE ÉXITO**

### Pipeline funcional cuando:
- ✅ Corre end-to-end sin errores
- ✅ Genera todos los outputs esperados (~60 tablas, ~80 figuras)
- ✅ Resultados coinciden con análisis exploratorio original
- ✅ Tiempo de ejecución < 30 minutos

### Hallazgos replicados:
- ✅ let-7 patrón específico (posiciones 2, 4, 5)
- ✅ miR-4500 resistente (0 G>T en seed)
- ✅ Enriquecimiento G-rich (24×)
- ✅ ALS > Control en G>T (si confirmado en análisis general)

---

## 🚀 **PLAN DE IMPLEMENTACIÓN**

### Fase 1: Core + Módulo 1 (2 días)
- [x] Definir input (HECHO)
- [x] Definir decisiones de diseño (HECHO)
- [x] Diseñar estructura de análisis (HECHO)
- [ ] Implementar core functions (io, preprocessing)
- [ ] Implementar Módulo 1 completo
- [ ] Test con `example_input_mini.tsv`

### Fase 2: Módulos 2-3 (2 días)
- [ ] Implementar Módulo 2 (Panorama general)
- [ ] Implementar Módulo 3 (Oxidación)
- [ ] Crear figuras comparativas (2 vs 3)
- [ ] Validar con dataset completo

### Fase 3: Módulos 4-5 (2 días)
- [ ] Implementar Módulo 4 (Posicional)
- [ ] Implementar Módulo 5 (Top miRNAs)
- [ ] Validar hallazgo let-7

### Fase 4: Módulo 6 + Documentación (3 días)
- [ ] Implementar Módulo 6 (Avanzados)
- [ ] Crear README.md principal
- [ ] Documentación de parámetros
- [ ] Ejemplos de uso

### Fase 5: Testing y GitHub (2 días)
- [ ] Tests unitarios
- [ ] Análisis de sensibilidad
- [ ] Preparar para GitHub
- [ ] Tag release v1.0.0

**Total**: ~11-12 días

---

## 📁 **ARCHIVOS DE DOCUMENTACIÓN CREADOS**

1. ✅ **`INPUT_SPECIFICATION.md`** (15 KB)
   - Formato completo del archivo TSV
   - Columnas, tipos de datos, ejemplos
   - Parsing de nombres de muestras
   - Función de validación

2. ✅ **`DESIGN_DECISIONS.md`** (15 KB)
   - Justificación VAF 50% (CORREGIDA)
   - Justificación Seed 2-8
   - Tabla de decisiones consolidada
   - Plan de sensibilidad

3. ✅ **`ANALYSIS_STRUCTURE_REVISED.md`** (20 KB)
   - 6 módulos, 21 sub-análisis
   - Progresión lógica: General → Específico
   - Comparaciones clave entre módulos
   - Outputs esperados (~60 tablas, ~80 figuras)

4. ✅ **`PLAN_PIPELINE_MODULAR_GITHUB.md`** (51 KB)
   - Estructura completa del repositorio
   - Core functions reutilizables
   - Sistema de configuración YAML
   - Patrón de módulos estándar
   - Roadmap de implementación

5. ✅ **`data/example_input_mini.tsv`** (8.3 KB)
   - Dataset de ejemplo (50 filas, 22 columnas)
   - let-7a-5p con 49 mutaciones
   - Para testing rápido

6. ✅ **`data/README.md`** (3 KB)
   - Descripción de archivos de datos
   - Instrucciones de uso
   - Cómo crear ejemplos personalizados

---

## 🎯 **COMPARACIONES CRÍTICAS**

### Comparación A: **Módulo 2 vs Módulo 3**
```
PREGUNTA: ¿G>T es diferente del resto de SNVs?

Módulo 2 (Todos):
- Top 20 miRNAs por SNVs
- ALS vs Control (todos SNVs)
- # SNVs significativos

Módulo 3 (Solo G>T):
- Top 20 miRNAs por G>T
- ALS vs Control (solo G>T)
- # G>T significativos

COMPARAR:
- ¿Overlap en Top 20?
- ¿Señal ALS más fuerte en G>T?
- ¿Enriquecimiento específico?
```

---

### Comparación B: **Paso 4.1 vs 4.2**
```
PREGUNTA: ¿G>T tiene distribución posicional diferente?

Paso 4.1 (Todos):
- Distribución por posición 1-23 (todos SNVs)

Paso 4.2 (G>T):
- Distribución por posición 1-23 (solo G>T)

COMPARAR:
- ¿Enriquecimiento en seed (2-8) específico de G>T?
- ¿Hotspots diferentes?
```

---

## 🔢 **OUTPUTS ESPERADOS (Total)**

### Tablas: ~60 CSV files
```
Módulo 1: 4 tablas
Módulo 2: 12 tablas
Módulo 3: 12 tablas
Módulo 4: 9 tablas
Módulo 5: 9 tablas
Módulo 6: 15 tablas
```

### Figuras: ~80 PNG files (300 DPI)
```
Módulo 1: 3 figuras
Módulo 2: 15 figuras
Módulo 3: 15 figuras (+ comparativas con Módulo 2)
Módulo 4: 12 figuras (+ comparativas con 4.1)
Módulo 5: 10 figuras
Módulo 6: 20 figuras
```

### Resúmenes: 6 `summary.txt`
```
Uno por cada módulo
```

### Tiempo de ejecución total: ~20-25 minutos
```
Módulo 1: ~2 min
Módulo 2: ~3 min
Módulo 3: ~3 min
Módulo 4: ~2 min
Módulo 5: ~3 min
Módulo 6: ~8 min
```

---

## 🎨 **FIGURAS COMPARATIVAS CLAVE**

### 1. **Top miRNAs: Todos vs G>T** (Módulo 2.1 vs 3.1)
```
┌─────────────────────────────────────────────┐
│ TOP 20 miRNAs                               │
├──────────────────┬──────────────────────────┤
│ Todos los SNVs   │ Solo G>T                 │
│                  │                          │
│ 1. miR-xxx (150) │ 1. let-7a-5p (12)       │
│ 2. miR-yyy (142) │ 2. let-7b-5p (11)       │
│ 3. let-7a-5p(135)│ 3. miR-xxx (9)          │
│ ...              │ ...                      │
└──────────────────┴──────────────────────────┘
```
→ ¿let-7 sube en ranking cuando filtramos a G>T?

---

### 2. **Volcano Plots: Todos vs G>T** (Paso 2.4 vs 3.4)
```
┌─────────────────────────────────────────────┐
│ ALS vs Control                              │
├──────────────────┬──────────────────────────┤
│ Todos los SNVs   │ Solo G>T                 │
│                  │                          │
│ [Volcano plot]   │ [Volcano plot]           │
│ 127 significant  │ 45 significant           │
│ FDR < 0.05       │ FDR < 0.05               │
└──────────────────┴──────────────────────────┘
```
→ ¿Proporción de significativos mayor en G>T?

---

### 3. **Distribución Posicional: Todos vs G>T** (Paso 4.1 vs 4.2)
```
┌─────────────────────────────────────────────┐
│ Distribución por Posición                   │
├──────────────────┬──────────────────────────┤
│ Todos los SNVs   │ Solo G>T                 │
│                  │                          │
│ [Barplot 1-23]   │ [Barplot 1-23]           │
│                  │                          │
│ Seed: 35%        │ Seed: 48%  ← ENRIQUECIDO│
│ Central: 40%     │ Central: 30%             │
│ 3': 25%          │ 3': 22%                  │
└──────────────────┴──────────────────────────┘
```
→ ¿G>T enriquecido en seed?

---

## 🧪 **EJEMPLOS DE USO**

### Caso 1: Análisis Completo (Primera vez)
```r
# Cargar pipeline
source("src/pipeline.R")

# Ejecutar todos los módulos
results <- run_complete_pipeline(
  input_file = "data/miRNA_count.Q33.txt",
  config_file = "config/default_config.yaml",
  modules = c(1, 2, 3, 4, 5, 6),
  verbose = TRUE
)

# Ver estructura de outputs
list.files("outputs/", recursive = TRUE)
```

**Output**: 6 carpetas con 60 tablas + 80 figuras

---

### Caso 2: Solo Preparación + Panorama General
```r
# Solo entender el dataset
results <- run_complete_pipeline(
  input_file = "data/miRNA_count.Q33.txt",
  modules = c(1, 2),  # Solo prep + general
  verbose = TRUE
)
```

**Uso**: Entender contexto completo, estadísticas descriptivas

---

### Caso 3: Solo Oxidación (Skip panorama general)
```r
# Enfoque directo en G>T
results <- run_complete_pipeline(
  input_file = "data/miRNA_count.Q33.txt",
  modules = c(1, 3, 4, 5, 6),  # Skip Módulo 2
  verbose = TRUE
)
```

**Uso**: Análisis enfocado cuando ya conoces el dataset

---

### Caso 4: Solo let-7 (miRNA específico)
```r
# Análisis enfocado en let-7 family
custom_config <- list(
  filters = list(
    mirna_specific = list(
      enabled = TRUE,
      pattern = "hsa-let-7"
    )
  )
)

results <- run_complete_pipeline(
  input_file = "data/miRNA_count.Q33.txt",
  config = custom_config,
  modules = c(1, 3, 4, 5),
  verbose = TRUE
)
```

---

## 📊 **DECISIONES ALGORÍTMICAS POR MÓDULO**

| Módulo | Decisión | Default | Basado en Datos | User-Config |
|--------|----------|---------|-----------------|-------------|
| **1.4** | VAF threshold | 50% | ❌ | ✅ |
| **2.1** | Top N | 20 | ✅ (1% del total) | ✅ |
| **3.1** | G>T pattern | "GT$" | ❌ | ✅ |
| **4.2** | Hotspot threshold | Top 10% | ✅ (percentil 90) | ✅ |
| **4.3** | Seed definition | 2-8 | ❌ | ✅ |
| **5.1** | Min G>T in seed | 1 | ❌ | ✅ |
| **6.1** | # clusters | Auto | ✅ (sqrt(n)) | ✅ |
| **6.3** | FDR pathway | 0.05 | ❌ | ✅ |

---

## 🎯 **PRÓXIMO PASO INMEDIATO**

### Tarea: Implementar **Módulo 1 (Preparación)** completo

**Archivos a crear**:
```
src/
├── core/
│   ├── io.R                    # read_input_data(), validate_input_file()
│   └── preprocessing.R         # split_collapse(), calculate_vafs(), filter_high_vafs()
│
└── modules/
    └── module_01_prep.R        # run_module_01()
```

**Tiempo estimado**: 2-3 horas

**Output esperado**:
- Módulo 1 funcional
- Test con `example_input_mini.tsv`
- Genera 4 tablas + 3 figuras

---

## ❓ **¿EMPEZAMOS CON LA IMPLEMENTACIÓN?**

Opciones:

**A) Implementar Módulo 1 YA** ⚡
- Extraer funciones de tus scripts actuales
- Crear `src/core/preprocessing.R`
- Crear `src/modules/module_01_prep.R`
- Test end-to-end

**B) Revisar estructura primero** 📖
- ¿Falta algo en los 6 módulos?
- ¿Algún análisis adicional?
- Ajustar antes de implementar

**C) Crear configuración YAML primero** ⚙️
- Diseñar `config/default_config.yaml` completo
- Definir todos los parámetros
- Luego implementar contra spec

---

**¿Qué prefieres?** 🚀







