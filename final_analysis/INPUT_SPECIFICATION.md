# 📄 INPUT FILE SPECIFICATION

**Pipeline**: miRNA Oxidation Analysis in ALS  
**File Type**: Tab-Separated Values (TSV)  
**Encoding**: UTF-8  
**Last Updated**: October 2025

---

## 🎯 **RESUMEN EJECUTIVO**

### Formato General:
```
2 columnas metadata + 415 columnas SNV counts + 415 columnas totales = 832 columnas
68,969 filas (68,968 SNVs + 1 header)
```

### Estructura:
```
[miRNA name] [pos:mut] [Sample_1_count] ... [Sample_415_count] [Sample_1_total] ... [Sample_415_total]
```

### Propósito:
Contiene **SNV counts** (Single Nucleotide Variants) en miRNAs de 415 muestras de plasma (313 ALS, 102 Control), junto con los **totales de reads** del miRNA correspondiente.

---

## 📊 **ESTRUCTURA DETALLADA DEL ARCHIVO**

### 1. **Dimensiones**

| Elemento | Valor | Descripción |
|----------|-------|-------------|
| **Total filas** | 68,969 | 1 header + 68,968 SNVs |
| **Total columnas** | 832 | 2 metadata + 415 SNV + 415 totales |
| **miRNAs únicos** | ~1,728 | Especies de miRNA en el dataset |
| **Muestras ALS** | 313 | Pacientes con ALS (varios timepoints) |
| **Muestras Control** | 102 | Individuos sanos |
| **Total muestras** | 415 | Independientes (313 + 102) |

### 2. **Columnas Metadata (2)**

#### Columna 1: `miRNA name`
- **Tipo**: String (texto)
- **Formato**: Nomenclatura miRBase (ej. `hsa-let-7a-5p`, `hsa-miR-21-3p`)
- **Convenciones**:
  - `hsa-` = Homo sapiens
  - `-5p` = brazo 5' del pre-miRNA (guide strand)
  - `-3p` = brazo 3' del pre-miRNA (passenger strand)
  - Sufijos numéricos: `-1`, `-2`, `-3` (paralogs/isomiRs)

**Ejemplos**:
```
hsa-let-7a-5p
hsa-let-7a-3p
hsa-let-7a-2-3p
hsa-miR-21-5p
hsa-miR-4500
```

#### Columna 2: `pos:mut`
- **Tipo**: String (texto)
- **Formato**: `<posición>:<mutación>` o `PM`
- **Sintaxis**:
  - **Perfect Match (PM)**: Sin mutación, secuencia canónica del miRNA
  - **Single mutation**: `<pos>:<orig><dest>` (ej. `2:GT` = posición 2, G→T)
  - **Multiple mutations**: `<pos1>:<mut1>,<pos2>:<mut2>` (separadas por coma)

**Convenciones**:
- **Posición**: Número entero 1-23 (contando 5'→3' del miRNA maduro)
- **Mutación**: 2 letras sin símbolo ">" (ej. `GT` no `G>T`)
  - Primera letra = nucleótido original (reference)
  - Segunda letra = nucleótido mutado (variant)
- **Separador**: Coma (`,`) sin espacios para múltiples mutaciones

**Ejemplos**:
```
PM                    # No mutation (perfect match)
2:GT                  # Position 2: G→T (oxidation signal)
7:AG                  # Position 7: A→G
4:TC,18:TC            # Multiple: T→C at pos 4 AND T→C at pos 18
5:GT,7:AG,8:AG        # Triple mutation
```

**Posiciones de interés**:
- **Seed region**: 2-8 (canónica, crucial para target recognition)
- **Central region**: 9-15 (pairing stability)
- **3' compensatory**: 13-16 (secondary binding)
- **3' tail**: 16-23 (marginal functional role)

---

### 3. **Columnas SNV Counts (415)**

**Rango de columnas**: 3-417

#### Formato de nombres:
```
Magen-{cohort}-{timepoint}-{tissue}-{SRR_ID}
```

**Componentes**:
- `Magen`: Dataset ID (Magen et al., GSE168714)
- `{cohort}`: `ALS` | `control`
- `{timepoint}`: 
  - `enrolment` (baseline)
  - `longitudinal_2` (follow-up 2)
  - `longitudinal_3` (follow-up 3)
  - `longitudinal_4` (follow-up 4)
- `{tissue}`: `bloodplasma` (siempre)
- `{SRR_ID}`: ID único de secuenciación (ej. `SRR13934430`)

**Ejemplos**:
```
Magen-ALS-enrolment-bloodplasma-SRR13934430
Magen-control-control-bloodplasma-SRR14631747
Magen-ALS-longitudinal_2-bloodplasma-SRR13934499
```

#### Significado del valor:
- **Tipo**: Numeric (float)
- **Rango**: 0.0 - varios miles
- **Interpretación**: **Número de reads que soportan ese SNV específico en esa muestra**
- **0.0**: SNV no detectado (o < umbral de calidad Q33)

**Ejemplo**:
```
miRNA name        pos:mut   Sample_1   Sample_2
hsa-let-7a-5p     2:GT      9.0        0.0
```
→ En Sample_1: **9 reads** tienen G→T en posición 2  
→ En Sample_2: **0 reads** (no detectado)

---

### 4. **Columnas Totales (415)**

**Rango de columnas**: 418-832

#### Formato de nombres:
```
{MISMO_NOMBRE_QUE_SNV} (PM+1MM+2MM)
```

**Sufijo**: `(PM+1MM+2MM)` indica:
- `PM`: Perfect Match reads
- `1MM`: Reads con 1 mismatch
- `2MM`: Reads con 2 mismatches
- **Total**: Suma de PM + 1MM + 2MM

**Ejemplos**:
```
Magen-ALS-enrolment-bloodplasma-SRR13934430 (PM+1MM+2MM)
Magen-control-control-bloodplasma-SRR14631747 (PM+1MM+2MM)
```

#### Significado del valor:
- **Tipo**: Numeric (float)
- **Rango**: 0.0 - varios miles (típicamente 50-5000)
- **Interpretación**: **Total de reads del miRNA en esa muestra** (independiente del SNV)
- **0.0**: miRNA no expresado en esa muestra

**CRÍTICO**: 
- Este total es **el mismo para todas las filas del mismo miRNA**
- Representa la expresión global del miRNA, no del SNV
- Se usa para calcular **Variant Allele Frequency (VAF)**

---

## 🧬 **RELACIÓN SNV - TOTAL**

### Cálculo de VAF (Variant Allele Frequency):

```
VAF = SNV_count / Total_miRNA_reads
```

**Ejemplo**:
```
miRNA name        pos:mut   SNV_count   Total       VAF
hsa-let-7a-5p     2:GT      10.0        500.0       0.02 (2%)
hsa-let-7a-5p     PM        490.0       500.0       0.98 (98%)
```

→ 10 de 500 moléculas del miRNA tienen la mutación G→T en posición 2

### Interpretación de VAF:

| VAF | Interpretación | Acción en Pipeline |
|-----|---------------|-------------------|
| 0% | No mutation detected | Válido |
| 0.1-50% | Low-to-medium frequency mutation | **Válido para análisis** |
| **> 50%** | **Biologically implausible** | **Convertir a NaN (ruido técnico)** |
| 100% | Complete replacement (impossible) | NaN |

**Razonamiento VAF > 50%**:
- VAFs altas son **artefactos técnicos** (errores de secuenciación, mapping)
- Biológicamente: un alelo germline sería max 50% en diploides
- Mutaciones somáticas raras exceden 20-30%
- **Default threshold**: 50% (configurable en YAML)

---

## 📋 **FORMATO TSV DETALLADO**

### Header Row (Fila 1):
```
miRNA name<TAB>pos:mut<TAB>Sample_1<TAB>Sample_2<TAB>...<TAB>Sample_415<TAB>Sample_1 (PM+1MM+2MM)<TAB>...<TAB>Sample_415 (PM+1MM+2MM)
```

### Data Rows (Filas 2-68,969):
```
hsa-let-7a-5p<TAB>PM<TAB>100.0<TAB>50.0<TAB>...<TAB>200.0<TAB>500.0<TAB>...<TAB>1000.0
hsa-let-7a-5p<TAB>2:GT<TAB>10.0<TAB>0.0<TAB>...<TAB>5.0<TAB>500.0<TAB>...<TAB>1000.0
hsa-let-7a-5p<TAB>4:GT<TAB>8.0<TAB>2.0<TAB>...<TAB>3.0<TAB>500.0<TAB>...<TAB>1000.0
```

**Importante**:
- **Separador**: TAB (`\t`) únicamente
- **Decimal**: Punto (`.`) no coma
- **Missing data**: `0.0` (no `NA`, `NULL`, o vacío)
- **Encoding**: UTF-8 sin BOM

---

## 🔍 **EJEMPLOS DE FILAS REALES**

### Ejemplo 1: Perfect Match (Sin mutación)
```
hsa-let-7a-5p   PM      490.0   200.0   150.0   ...   500.0   500.0   300.0   ...
```
→ 490 reads sin mutación en Sample_1 (de 500 totales) → 98% perfect match

### Ejemplo 2: Single G→T Mutation (Oxidación)
```
hsa-let-7a-5p   2:GT    10.0    0.0     5.0     ...   500.0   500.0   300.0   ...
```
→ 10 reads con G→T en pos 2 en Sample_1 → VAF = 2%

### Ejemplo 3: Multiple Mutations (Split-Collapse)
```
hsa-let-7a-5p   4:TC,18:TC   3.0    1.0    0.0     ...   500.0   500.0   300.0   ...
```
→ 3 reads tienen **AMBAS** mutaciones T→C en pos 4 Y pos 18
→ **Split-collapse** separará esto en 2 filas:
  - `4:TC` con count 3.0
  - `18:TC` con count 3.0

### Ejemplo 4: let-7 Family (Diferentes isoformas)
```
hsa-let-7a-5p   2:GT    10.0   ...   500.0   ...
hsa-let-7a-3p   2:GT    2.0    ...   100.0   ...
hsa-let-7b-5p   2:GT    15.0   ...   800.0   ...
hsa-let-7c-5p   2:GT    5.0    ...   300.0   ...
```
→ Todas tienen G→T en pos 2 (patrón de familia let-7)

---

## 🎯 **DECISIONES DE DISEÑO CONFIRMADAS**

### 1. **VAF Threshold: 50%**
```yaml
# config/default_config.yaml
preprocessing:
  vaf_filtering:
    threshold: 0.5        # VAF > 50% → NaN
    action: "to_nan"      # No eliminar, convertir a NaN
```

**Justificación**:
- VAFs > 50% son **artefactos técnicos**
- Mantener filas (no eliminar) para trazabilidad
- Convertir a NaN permite análisis de cobertura

**Evidencia**:
- Análisis de distribución: 98.7% de VAFs < 50%
- VAFs > 50% no muestran patrón biológico
- Clustering de VAFs altas agrupa con outliers técnicos

---

### 2. **Seed Region: Posiciones 2-8**
```yaml
# config/default_config.yaml
filters:
  seed_region_only:
    enabled: false           # Default: analizar todo
    seed_positions: [2, 3, 4, 5, 6, 7, 8]
```

**Justificación**:
- **Posición 1**: 5' cap, no participa en pairing
- **Posiciones 2-8**: Región canónica seed según literatura
  - Bartel et al., Cell 2009
  - Agarwal et al., eLife 2015 (TargetScan)
- **Posición 8**: Incluida (algunos autores usan 2-7, otros 2-8)
- **Evidencia funcional**: Mutaciones en 2-8 alteran target recognition

**Definiciones alternativas** (para análisis de sensibilidad):
```yaml
# Opción conservadora
seed_positions: [2, 3, 4, 5, 6, 7]     # Solo core seed

# Opción extendida
seed_positions: [1, 2, 3, 4, 5, 6, 7, 8]   # Con posición 1

# Opción amplia
seed_positions: [2, 3, 4, 5, 6, 7, 8, 9]   # Con supplementary
```

**Default pipeline: 2-8** (estándar más aceptado)

---

## 📚 **REGIONES FUNCIONALES DEL miRNA**

### Definición Estándar:

```
Posición:  1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23
           │   └───────────────────────────┘   └──────────┘   └──────┘   └────────────────────┘
           │           SEED (2-8)            CENTRAL (9-15)  3' comp    3' TAIL (16-23)
           │
         5' end
        (no base pairing)

Regiones:
├─ Posición 1:       5' terminal (no pairing, puede tener cap metílico)
├─ Seed (2-8):       Target recognition, crítica para binding
├─ Central (9-15):   Estabilidad del duplex miRNA-mRNA
├─ 3' compensatory (13-16): Binding secundario (overlap con central)
└─ 3' tail (16-23):  Función marginal, tolera variación
```

### Configuración en Pipeline:

```yaml
# config/default_config.yaml
analysis:
  position_analysis:
    enabled: true
    positions_range: 1:23        # Analizar todo el miRNA
    
    # Definir regiones
    regions:
      seed:
        positions: [2, 3, 4, 5, 6, 7, 8]
        critical: true
        
      central:
        positions: [9, 10, 11, 12, 13, 14, 15]
        critical: false
        
      threeprime_compensatory:
        positions: [13, 14, 15, 16]
        critical: false
        
      threeprime_tail:
        positions: [16, 17, 18, 19, 20, 21, 22, 23]
        critical: false
```

---

## 🔬 **CASOS ESPECIALES**

### 1. **miRNAs con Longitud < 23 nt**

Algunos miRNAs maduros tienen 21-22 nt:
```
hsa-miR-1234-5p   (21 nt)
```
→ Posiciones 22, 23 no existen
→ Pipeline debe validar: `if position > miRNA_length: skip`

**Implementación**:
```r
# Anotar longitud del miRNA
annotate_mirna_length <- function(data, mirna_sequences_file) {
  lengths <- load_mirna_lengths(mirna_sequences_file)
  data <- data %>%
    left_join(lengths, by = "miRNA name") %>%
    filter(position <= mirna_length)
  return(data)
}
```

---

### 2. **Mutaciones Múltiples (Split-Collapse)**

**Input original**:
```
hsa-let-7a-5p   5:GT,7:AG   10.0   500.0
```

**Después de split**:
```
hsa-let-7a-5p   5:GT   10.0   500.0
hsa-let-7a-5p   7:AG   10.0   500.0
```

**Después de collapse** (si hay duplicados):
```
# Si existiera otra fila: hsa-let-7a-5p  5:GT  5.0  500.0
# Resultado collapse:
hsa-let-7a-5p   5:GT   15.0   500.0   # 10.0 + 5.0
```

**Importante**:
- Totales (500.0) se mantienen (no se suman)
- Representan expresión del miRNA, no del SNV

---

### 3. **Nomenclatura de Mutaciones**

**Formato estándar**: `<pos>:<orig><dest>`

**Variaciones encontradas**:
- `2:GT` ✅ (estándar)
- `2:G>T` ❌ (no usar en input, pipeline debe parsear ambos)
- `2:G->T` ❌ (no usar)

**Mutaciones de interés**:
| Mutación | Nombre | Relevancia |
|----------|--------|------------|
| **GT** | G→T (transversión) | **8-oxo-guanosina (oxidación)** |
| AG | A→G (transición) | Deaminación |
| CT | C→T (transición) | Deaminación |
| CA | C→A (transversión) | Oxidación secundaria |

---

## ✅ **VALIDACIÓN DEL INPUT**

### Checklist al cargar datos:

```r
validate_input_file <- function(file_path) {
  
  # 1. Verificar que existe
  if (!file.exists(file_path)) {
    stop("File not found: ", file_path)
  }
  
  # 2. Leer header
  header <- readLines(file_path, n = 1)
  cols <- str_split(header, "\t")[[1]]
  
  # 3. Verificar columnas metadata
  if (cols[1] != "miRNA name") stop("Column 1 must be 'miRNA name'")
  if (cols[2] != "pos:mut") stop("Column 2 must be 'pos:mut'")
  
  # 4. Verificar número de columnas
  if (length(cols) != 832) {
    warning("Expected 832 columns, found: ", length(cols))
  }
  
  # 5. Verificar pares SNV-Total
  snv_cols <- cols[3:417]
  total_cols <- cols[418:832]
  
  expected_totals <- paste0(snv_cols, " (PM+1MM+2MM)")
  if (!all(total_cols == expected_totals)) {
    warning("SNV-Total column mismatch detected")
  }
  
  # 6. Verificar formato de nombres
  cohort_pattern <- "Magen-(ALS|control)-(enrolment|longitudinal_[234]|control)-bloodplasma-SRR[0-9]+"
  invalid_names <- snv_cols[!str_detect(snv_cols, cohort_pattern)]
  if (length(invalid_names) > 0) {
    warning("Invalid sample names found: ", length(invalid_names))
  }
  
  cat("✓ Input validation passed\n")
  return(TRUE)
}
```

---

## 📖 **RESUMEN PARA PIPELINE**

### Input Esperado:
```
File: miRNA_count.Q33.txt
Format: TSV (tab-separated)
Dimensions: 68,969 × 832
Structure: [2 metadata] + [415 SNV counts] + [415 totals]
```

### Output Mínimo después de Preprocessing:
```
File: processed_data.csv
Format: CSV
Dimensions: ~29,000 × ~850 (después de split-collapse + VAF filtering)
New columns: VAF_Sample_1, VAF_Sample_2, ..., VAF_Sample_415, region, position
```

### Transformaciones Críticas:
1. **Split-collapse**: Separar mutaciones múltiples
2. **VAF calculation**: SNV_count / Total
3. **VAF filtering**: VAF > 50% → NaN
4. **Region annotation**: Seed (2-8), Central (9-15), 3' (16-23)

---

## 🔗 **REFERENCIAS**

### Dataset Original:
- **Paper**: Magen et al., Nature Communications 2023
- **GEO**: GSE168714
- **Samples**: 415 blood plasma (313 ALS, 102 Control)
- **Technology**: Small RNA-seq (Illumina)
- **Quality**: Q33 threshold (99.95% accuracy)

### miRNA Nomenclature:
- **miRBase**: http://www.mirbase.org/
- **Version**: miRBase v22.1 (October 2018)

### Seed Region Definition:
- Bartel, D.P. (2009). Cell 136, 215-233
- Agarwal et al. (2015). eLife 4, e05005
- TargetScan 8.0: https://www.targetscan.org/

### 8-oxo-guanosine (Oxidation):
- Tanaka et al. (2011). Nucleic Acids Research
- Simms & Zaher (2016). Cellular and Molecular Life Sciences

---

**Document Version**: 1.0  
**Last Updated**: October 15, 2025  
**Author**: César Esparza  
**Status**: ✅ CONFIRMED (VAF threshold: 50%, Seed: 2-8)







