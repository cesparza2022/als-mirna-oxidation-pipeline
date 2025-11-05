# 🔍 PATRÓN DE FORMATO DEL INPUT - Análisis Abstracto

**Fecha**: Octubre 15, 2025  
**Propósito**: Definir el **patrón generalizable** del input, independiente de números específicos

---

## 🎯 **PATRÓN GENERAL ABSTRACTO**

### Estructura del Archivo:

```
┌─────────────┬──────────┬────────────────────┬────────────────────┐
│  Metadata   │ Metadata │   SNV Counts       │   Totals           │
│  Column 1   │ Column 2 │   (N columns)      │   (N columns)      │
├─────────────┼──────────┼────────────────────┼────────────────────┤
│ miRNA name  │ pos:mut  │ Sample_1           │ Sample_1 (PM+...)  │
│             │          │ Sample_2           │ Sample_2 (PM+...)  │
│             │          │ ...                │ ...                │
│             │          │ Sample_N           │ Sample_N (PM+...)  │
└─────────────┴──────────┴────────────────────┴────────────────────┘

Total columnas: 2 + N + N = 2 + 2N
```

**Donde**:
- **N** = Número de muestras (puede ser 10, 100, 415, 1000, cualquier número)
- **M** = Número de SNVs (puede ser 100, 10000, 68968, cualquier número)

---

## 📊 **COLUMNAS: 3 TIPOS**

### **Tipo 1: Metadata (2 columnas fijas)**

| Posición | Nombre | Tipo | Contenido |
|----------|--------|------|-----------|
| **Col 1** | `miRNA name` | String | Nombre del miRNA (nomenclatura miRBase) |
| **Col 2** | `pos:mut` | String | Mutación o "PM" (perfect match) |

**Características**:
- Siempre las **2 primeras columnas**
- Nombres fijos (no variables)
- Identificación: por nombre exacto o por posición

---

### **Tipo 2: SNV Counts (N columnas)**

| Posición | Nombre | Tipo | Contenido |
|----------|--------|------|-----------|
| **Col 3** | `{Sample_1_name}` | Numeric | Count de SNV en muestra 1 |
| **Col 4** | `{Sample_2_name}` | Numeric | Count de SNV en muestra 2 |
| **...** | ... | ... | ... |
| **Col (2+N)** | `{Sample_N_name}` | Numeric | Count de SNV en muestra N |

**Características**:
- Rango: columnas **3** hasta **(2+N)**
- Nombres: **SIN sufijo** (nombres limpios de muestra)
- Valores: Numéricos (float), 0.0 para no detectado
- Significado: **Número de reads que soportan ese SNV específico**

**Identificación**:
```r
# Método 1: Excluir metadata y totales
count_cols <- colnames(data)[
  !colnames(data) %in% c("miRNA name", "pos:mut") &
  !grepl("\\(PM\\+1MM\\+2MM\\)$", colnames(data))
]

# Método 2: Detectar por patrón (primeras columnas sin sufijo)
count_cols <- colnames(data)[3:(which(grepl("\\(PM\\+1MM\\+2MM\\)", colnames(data)))[1] - 1)]
```

---

### **Tipo 3: Totales (N columnas)**

| Posición | Nombre | Tipo | Contenido |
|----------|--------|------|-----------|
| **Col (3+N)** | `{Sample_1_name} (PM+1MM+2MM)` | Numeric | Total reads del miRNA en muestra 1 |
| **Col (4+N)** | `{Sample_2_name} (PM+1MM+2MM)` | Numeric | Total reads del miRNA en muestra 2 |
| **...** | ... | ... | ... |
| **Col (2+2N)** | `{Sample_N_name} (PM+1MM+2MM)` | Numeric | Total reads del miRNA en muestra N |

**Características**:
- Rango: columnas **(3+N)** hasta **(2+2N)**
- Nombres: **CON sufijo** `" (PM+1MM+2MM)"`
- Valores: Numéricos (float), 0.0 para no expresado
- Significado: **Total reads del miRNA en esa muestra (PM + 1 mismatch + 2 mismatches)**

**Identificación**:
```r
# Por sufijo
total_cols <- colnames(data)[grepl("\\(PM\\+1MM\\+2MM\\)$", colnames(data))]
```

---

## 🔗 **EMPAREJAMIENTO COUNT-TOTAL**

### Regla de Emparejamiento:

```
Para cada muestra i:
├─ Count column:  colnames[2 + i]         = "Sample_name"
├─ Total column:  colnames[2 + N + i]     = "Sample_name (PM+1MM+2MM)"
└─ Relación:      total_name = count_name + " (PM+1MM+2MM)"
```

### Algoritmo de Emparejamiento:

```r
# Extraer nombre base de columna total
get_base_name <- function(total_col_name) {
  # Remover sufijo " (PM+1MM+2MM)"
  base_name <- str_remove(total_col_name, " \\(PM\\+1MM\\+2MM\\)$")
  return(base_name)
}

# Emparejar todas las columnas
pair_columns <- function(data) {
  
  # Identificar columnas
  total_cols <- colnames(data)[grepl("\\(PM\\+1MM\\+2MM\\)$", colnames(data))]
  
  pairs <- data.frame(
    count_col = character(),
    total_col = character(),
    stringsAsFactors = FALSE
  )
  
  for (total_col in total_cols) {
    base_name <- get_base_name(total_col)
    
    # Buscar columna count correspondiente
    if (base_name %in% colnames(data)) {
      pairs <- rbind(pairs, data.frame(
        count_col = base_name,
        total_col = total_col
      ))
    } else {
      warning("No se encontró columna count para: ", total_col)
    }
  }
  
  return(pairs)
}
```

**Resultado**:
```
  count_col                                          total_col
1 Magen-ALS-enrolment-bloodplasma-SRR13934430      Magen-ALS-enrolment-bloodplasma-SRR13934430 (PM+1MM+2MM)
2 Magen-ALS-enrolment-bloodplasma-SRR13934402      Magen-ALS-enrolment-bloodplasma-SRR13934402 (PM+1MM+2MM)
3 Magen-control-control-bloodplasma-SRR14631747    Magen-control-control-bloodplasma-SRR14631747 (PM+1MM+2MM)
...
N Magen-ALS-longitudinal_4-bloodplasma-SRR13934474 Magen-ALS-longitudinal_4-bloodplasma-SRR13934474 (PM+1MM+2MM)
```

---

## 📋 **EJEMPLO CON DATOS REALES**

### Caso: let-7a-5p en Sample 1 y Sample 2

#### Fila 1: PM (Perfect Match, sin mutación)
```
miRNA name        pos:mut   Count_S1   Count_S2   Total_S1   Total_S2
hsa-let-7a-5p     PM        599187.0   24967.0    611158.0   25598.0
```

**Interpretación**:
- Sample 1: 599,187 reads **sin mutación** de 611,158 totales → VAF_PM = 98.0%
- Sample 2: 24,967 reads **sin mutación** de 25,598 totales → VAF_PM = 97.5%

#### Fila 2: 2:GT (G→T en posición 2 del seed)
```
miRNA name        pos:mut   Count_S1   Count_S2   Total_S1   Total_S2
hsa-let-7a-5p     2:GT      9.0        0.0        611158.0   25598.0
```

**Interpretación**:
- Sample 1: 9 reads **con G→T** de 611,158 totales → VAF_GT = 0.0015% (oxidación baja)
- Sample 2: 0 reads **con G→T** de 25,598 totales → VAF_GT = 0% (no detectado)

**IMPORTANTE**: 
- El **Total es el MISMO** (611,158 y 25,598) para PM y 2:GT
- Representa la **expresión global del miRNA** (hsa-let-7a-5p) en esa muestra
- Las VAFs de todas las mutaciones del mismo miRNA suman ≈ 100%

---

## 🔢 **VALIDACIÓN MATEMÁTICA**

### Propiedad Fundamental:

```
Para un miRNA M en una muestra S:

Σ (VAF de todos los pos:mut) ≈ 1.0

Es decir:
VAF_PM + VAF_2:GT + VAF_3:AG + ... + VAF_22:CT ≈ 100%
```

**Verificación**:
```r
# Para hsa-let-7a-5p en Sample 1
total <- 611158.0

counts <- c(
  PM    = 599187.0,
  "2:GT" = 9.0,
  "1:TC" = 716.0,
  # ... (otras mutaciones)
)

sum(counts) / total  # Debe ser ≈ 1.0 (puede ser < 1.0 si hay mutaciones raras no listadas)
```

---

## 🎨 **PATRÓN DE NOMBRES DE MUESTRAS**

### Estructura General:

```
{Dataset}-{Cohort}-{Timepoint}-{Tissue}-{SeqID}
```

**Componentes**:
| Campo | Valores Posibles | Ejemplo |
|-------|------------------|---------|
| `Dataset` | "Magen" (fijo para este dataset) | Magen |
| `Cohort` | "ALS", "control" | ALS |
| `Timepoint` | "enrolment", "longitudinal_2", "longitudinal_3", "longitudinal_4", "control" | enrolment |
| `Tissue` | "bloodplasma" (fijo) | bloodplasma |
| `SeqID` | "SRR..." (SRA accession) | SRR13934430 |

**Ejemplos**:
```
Magen-ALS-enrolment-bloodplasma-SRR13934430
Magen-control-control-bloodplasma-SRR14631747
Magen-ALS-longitudinal_2-bloodplasma-SRR13934499
```

**Parsing**:
```r
parse_sample_name <- function(sample_name) {
  # Remover sufijo si existe
  clean_name <- str_remove(sample_name, " \\(PM\\+1MM\\+2MM\\)$")
  
  # Split por guiones
  parts <- str_split(clean_name, "-")[[1]]
  
  if (length(parts) >= 5) {
    return(list(
      dataset = parts[1],           # "Magen"
      cohort = parts[2],             # "ALS" | "control"
      timepoint = parts[3],          # "enrolment" | "longitudinal_X" | "control"
      tissue = parts[4],             # "bloodplasma"
      seq_id = parts[5]              # "SRR..."
    ))
  } else {
    warning("Formato de nombre no reconocido: ", sample_name)
    return(NULL)
  }
}
```

**Flexibilidad**:
- El patrón puede variar según el dataset
- El pipeline debe ser **agnóstico** al patrón específico
- Metadata parsing es **opcional** (solo si se necesita cohort/timepoint)

---

## 🔧 **FUNCIÓN CORE: AUTO-DETECTAR ESTRUCTURA**

### Función para Identificar Tipos de Columnas:

```r
#' Identify Column Types in Input File
#'
#' Auto-detects metadata, count, and total columns based on patterns
#'
#' @param data data.frame read from input TSV
#' 
#' @return list with metadata_cols, count_cols, total_cols, and pairs
#' 
#' @export
identify_column_types <- function(data) {
  
  all_cols <- colnames(data)
  
  # 1. METADATA COLUMNS
  # Asumimos que las primeras 2 columnas son metadata
  # O las que tengan nombres específicos
  metadata_cols <- all_cols[1:2]
  
  # Validar nombres esperados
  if (metadata_cols[1] != "miRNA name" || metadata_cols[2] != "pos:mut") {
    warning("Expected 'miRNA name' and 'pos:mut' as first two columns. Found: ", 
            paste(metadata_cols, collapse = ", "))
  }
  
  # 2. TOTAL COLUMNS
  # Identificar por sufijo " (PM+1MM+2MM)"
  total_cols <- all_cols[grepl("\\(PM\\+1MM\\+2MM\\)$", all_cols)]
  
  if (length(total_cols) == 0) {
    stop("No se encontraron columnas de totales con sufijo (PM+1MM+2MM)")
  }
  
  # 3. COUNT COLUMNS
  # Todo lo que no es metadata ni total
  count_cols <- setdiff(all_cols, c(metadata_cols, total_cols))
  
  if (length(count_cols) == 0) {
    stop("No se encontraron columnas de counts")
  }
  
  # 4. VALIDAR QUE TENEMOS MISMO NÚMERO DE COUNTS Y TOTALS
  if (length(count_cols) != length(total_cols)) {
    warning("Mismatch: ", length(count_cols), " count columns vs ", 
            length(total_cols), " total columns")
  }
  
  # 5. EMPAREJAR COUNT-TOTAL
  pairs <- pair_count_total_columns(count_cols, total_cols)
  
  # 6. RESUMEN
  cat("=== COLUMN STRUCTURE DETECTED ===\n")
  cat("Metadata columns:  ", length(metadata_cols), "\n")
  cat("Count columns:     ", length(count_cols), "\n")
  cat("Total columns:     ", length(total_cols), "\n")
  cat("Paired samples:    ", nrow(pairs), "\n")
  cat("Total columns:     ", ncol(data), "\n")
  cat("Expected formula:  2 + 2N = ", 2 + 2*length(count_cols), "\n")
  cat("Actual:            ", ncol(data), "\n")
  
  if (ncol(data) != 2 + 2*length(count_cols)) {
    warning("Column count doesn't match expected pattern")
  }
  
  return(list(
    metadata_cols = metadata_cols,
    count_cols = count_cols,
    total_cols = total_cols,
    pairs = pairs,
    n_samples = length(count_cols)
  ))
}
```

---

### Función para Emparejar Counts con Totales:

```r
#' Pair Count and Total Columns
#'
#' Matches each count column with its corresponding total column
#'
#' @param count_cols character vector of count column names
#' @param total_cols character vector of total column names
#' 
#' @return data.frame with count_col and total_col pairs
#' 
#' @export
pair_count_total_columns <- function(count_cols, total_cols) {
  
  pairs <- data.frame(
    count_col = character(),
    total_col = character(),
    stringsAsFactors = FALSE
  )
  
  for (count_col in count_cols) {
    # Construir nombre esperado de total
    expected_total <- paste0(count_col, " (PM+1MM+2MM)")
    
    # Buscar en total_cols
    if (expected_total %in% total_cols) {
      pairs <- rbind(pairs, data.frame(
        count_col = count_col,
        total_col = expected_total,
        stringsAsFactors = FALSE
      ))
    } else {
      warning("No se encontró total para count column: ", count_col)
    }
  }
  
  # Verificar que todos los totales fueron emparejados
  unpaired_totals <- setdiff(total_cols, pairs$total_col)
  if (length(unpaired_totals) > 0) {
    warning("Totales sin emparejar: ", length(unpaired_totals))
  }
  
  return(pairs)
}
```

---

## 📊 **VALORES Y SIGNIFICADO**

### 1. **Columna `miRNA name`**

**Tipo**: String  
**Formato**: Nomenclatura miRBase  
**Patrón**: `hsa-{familia}-{número}-{brazo}`

**Ejemplos válidos**:
```
hsa-let-7a-5p       # let-7 family, miembro a, brazo 5'
hsa-let-7a-3p       # let-7 family, miembro a, brazo 3'
hsa-let-7a-2-3p     # let-7 family, paralog 2, brazo 3'
hsa-miR-21-5p       # miR-21, brazo 5'
hsa-miR-4500        # miR-4500 (sin brazo especificado)
```

**Pipeline**: Debe aceptar **cualquier nombre de miRNA** sin validación estricta

---

### 2. **Columna `pos:mut`**

**Tipo**: String  
**Formato**: `<posición>:<mutación>` o `PM`

**Componentes**:
- **Posición**: Entero 1-23 (típicamente, puede variar según longitud del miRNA)
- **Mutación**: 2 letras mayúsculas (nucleótidos)
  - Letra 1: Nucleótido original (A, C, G, T)
  - Letra 2: Nucleótido mutado (A, C, G, T)

**Valores especiales**:
- `PM`: Perfect Match (sin mutación, secuencia canónica)

**Ejemplos**:
```
PM               # Sin mutación
2:GT             # Posición 2, G→T (oxidación)
7:AG             # Posición 7, A→G
4:TC,18:TC       # Múltiple: T→C en pos 4 Y T→C en pos 18
5:GT,7:AG,8:AG   # Triple mutación
```

**Parsing**:
```r
parse_posmut <- function(posmut_string) {
  
  if (posmut_string == "PM") {
    return(list(
      is_pm = TRUE,
      position = NA,
      original = NA,
      mutated = NA,
      mutation_type = "PM"
    ))
  }
  
  # Extraer posición
  position <- as.integer(str_extract(posmut_string, "^\\d+"))
  
  # Extraer mutación (2 letras después de ":")
  mutation <- str_extract(posmut_string, "(?<=:)[A-Z]{2}")
  
  if (nchar(mutation) == 2) {
    original <- substr(mutation, 1, 1)
    mutated <- substr(mutation, 2, 2)
    mutation_type <- paste0(original, ">", mutated)  # "G>T"
  } else {
    original <- NA
    mutated <- NA
    mutation_type <- NA
  }
  
  return(list(
    is_pm = FALSE,
    position = position,
    original = original,
    mutated = mutated,
    mutation_type = mutation_type
  ))
}
```

---

### 3. **Valores Numéricos (Counts y Totales)**

**Tipo**: Numeric (float)  
**Rango**: 0.0 - ∞

**Counts (SNV)**:
- Mínimo: 0.0 (SNV no detectado o < threshold calidad)
- Típico: 0.0 - 100.0
- Alto: 100.0 - 1000.0
- Muy alto: > 1000.0

**Totales (miRNA)**:
- Mínimo: 0.0 (miRNA no expresado)
- Típico: 50.0 - 5000.0
- Alto: 5000.0 - 100000.0
- Muy alto: > 100000.0

**Relación**:
```
Count_SNV <= Total_miRNA   (siempre)
VAF = Count_SNV / Total_miRNA   (cuando Total > 0)
```

---

## 🎯 **INVARIANTES DEL FORMATO**

### Invariantes que el Pipeline Puede Asumir:

✅ **Siempre TRUE**:
1. Columnas 1-2 son metadata: `"miRNA name"`, `"pos:mut"`
2. Existe al menos 1 par (count, total)
3. Cada total tiene sufijo `" (PM+1MM+2MM)"`
4. Nombre base de total = nombre de count
5. Valores son numéricos (o convertibles a numérico)
6. Separador de archivo: TAB (`\t`)
7. Para mismo miRNA, todas las filas comparten el mismo Total

❌ **NO asumir** (pueden variar):
1. Número específico de muestras (puede ser 10, 100, 415, 1000)
2. Número específico de SNVs (puede ser 100, 10K, 68K, 1M)
3. Nombres específicos de muestras (patrón puede variar)
4. Rango de posiciones (pueden ser 1-23, o 1-21 para miRNAs cortos)
5. Tipos de mutaciones presentes (puede haber solo G>T, o todas)

---

## 🔍 **PATRÓN GENÉRICO PARA PIPELINE**

### Template Abstracto:

```
File: {cualquier_nombre}.{tsv|txt|csv}
Delimiter: TAB
Encoding: UTF-8

Structure:
┌──────────────┬──────────┬──────────────┬──────────────┬─────┬──────────────┬──────────────┬──────────────┬─────┬──────────────┐
│ miRNA name   │ pos:mut  │ Sample_1     │ Sample_2     │ ... │ Sample_N     │ Sample_1 (*) │ Sample_2 (*) │ ... │ Sample_N (*) │
├──────────────┼──────────┼──────────────┼──────────────┼─────┼──────────────┼──────────────┼──────────────┼─────┼──────────────┤
│ hsa-miR-xxx  │ PM       │ 1000.0       │ 500.0        │ ... │ 200.0        │ 1200.0       │ 520.0        │ ... │ 215.0        │
│ hsa-miR-xxx  │ 2:GT     │ 10.0         │ 5.0          │ ... │ 2.0          │ 1200.0       │ 520.0        │ ... │ 215.0        │
│ hsa-miR-xxx  │ 3:AG     │ 15.0         │ 8.0          │ ... │ 3.0          │ 1200.0       │ 520.0        │ ... │ 215.0        │
│ ...          │ ...      │ ...          │ ...          │ ... │ ...          │ ...          │ ...          │ ... │ ...          │
└──────────────┴──────────┴──────────────┴──────────────┴─────┴──────────────┴──────────────┴──────────────┴─────┴──────────────┘

(*) = " (PM+1MM+2MM)"

Dimensiones:
├─ Filas: M (cualquier número de SNVs)
├─ Columnas: 2 + 2N (donde N = número de muestras)
└─ Validación: ncol(data) debe ser par + 2
```

---

## 🧪 **FUNCIÓN DE AUTO-DETECCIÓN COMPLETA**

```r
#' Auto-Detect Input File Structure
#'
#' Automatically identifies metadata, count, and total columns
#' Works with ANY number of samples, ANY number of SNVs
#'
#' @param file_path character, path to input TSV file
#' @param verbose logical, print detection summary
#' 
#' @return list with structure information
#' 
#' @export
auto_detect_input_structure <- function(file_path, verbose = TRUE) {
  
  if (verbose) cat("=== AUTO-DETECTING INPUT STRUCTURE ===\n\n")
  
  # 1. LEER HEADER
  header <- readLines(file_path, n = 1)
  cols <- str_split(header, "\t")[[1]]
  
  if (verbose) cat("Total columns detected:", length(cols), "\n")
  
  # 2. VALIDAR COLUMNAS METADATA
  if (cols[1] != "miRNA name") {
    stop("Column 1 must be 'miRNA name', found: ", cols[1])
  }
  if (cols[2] != "pos:mut") {
    stop("Column 2 must be 'pos:mut', found: ", cols[2])
  }
  
  metadata_cols <- cols[1:2]
  
  # 3. IDENTIFICAR TOTALES (por sufijo)
  total_pattern <- "\\(PM\\+1MM\\+2MM\\)$"
  total_cols <- cols[grepl(total_pattern, cols)]
  
  if (length(total_cols) == 0) {
    stop("No total columns found with pattern '(PM+1MM+2MM)'")
  }
  
  if (verbose) cat("Total columns found:", length(total_cols), "\n")
  
  # 4. IDENTIFICAR COUNTS (resto)
  count_cols <- setdiff(cols, c(metadata_cols, total_cols))
  
  if (length(count_cols) == 0) {
    stop("No count columns found")
  }
  
  if (verbose) cat("Count columns found:", length(count_cols), "\n")
  
  # 5. VALIDAR NÚMERO DE COLUMNAS
  expected_total <- 2 + length(count_cols) + length(total_cols)
  if (length(cols) != expected_total) {
    warning("Column count mismatch: expected ", expected_total, ", found ", length(cols))
  }
  
  # 6. VALIDAR PARIDAD
  if (length(count_cols) != length(total_cols)) {
    warning("Mismatch: ", length(count_cols), " counts vs ", length(total_cols), " totals")
  }
  
  # 7. EMPAREJAR COUNT-TOTAL
  pairs <- pair_count_total_columns(count_cols, total_cols)
  
  if (verbose) {
    cat("Successfully paired:  ", nrow(pairs), "/", length(count_cols), "\n")
    
    if (nrow(pairs) < length(count_cols)) {
      unpaired_counts <- setdiff(count_cols, pairs$count_col)
      cat("Unpaired counts:      ", length(unpaired_counts), "\n")
    }
  }
  
  # 8. LEER DATASET COMPLETO
  if (verbose) cat("\nReading full dataset...\n")
  data <- read.delim(file_path, stringsAsFactors = FALSE, check.names = FALSE)
  
  if (verbose) {
    cat("Data dimensions:      ", nrow(data), "×", ncol(data), "\n")
    cat("Unique miRNAs:        ", length(unique(data$`miRNA name`)), "\n")
    cat("Unique SNVs:          ", nrow(data), "\n")
  }
  
  # 9. RETORNAR ESTRUCTURA
  return(list(
    data = data,
    metadata_cols = metadata_cols,
    count_cols = count_cols,
    total_cols = total_cols,
    pairs = pairs,
    n_samples = nrow(pairs),
    n_snvs = nrow(data),
    n_mirnas = length(unique(data$`miRNA name`))
  ))
}
```

---

## ✅ **ENTENDIMIENTO DEL FORMATO - CONFIRMACIÓN**

Déjame confirmar lo que entendí del patrón:

### **PATRÓN CORE**:

```
1. ARCHIVO TSV (tab-delimited)
   
2. COLUMNAS FIJAS (metadata):
   - Col 1: "miRNA name"
   - Col 2: "pos:mut"
   
3. COLUMNAS DINÁMICAS (dependen de # muestras N):
   - Cols 3 a (2+N):     Count columns (SIN sufijo)
   - Cols (3+N) a (2+2N): Total columns (CON sufijo " (PM+1MM+2MM)")
   
4. EMPAREJAMIENTO:
   - Cada count "X" tiene un total "X (PM+1MM+2MM)"
   - Mismo orden: Count_i en posición (2+i), Total_i en posición (2+N+i)
   
5. VALORES:
   - Counts: # de reads con ese SNV específico
   - Totales: # de reads totales del miRNA (MISMO para todas las filas del mismo miRNA)
   
6. VAF (calculado):
   - VAF = Count / Total
   - Rango válido: 0% - 100%
   - Filtro: VAF > 50% → NaN (isoformas, no oxidación)
```

---

### **LO QUE VARÍA** (Pipeline debe ser flexible):
- ❌ Número de muestras (N)
- ❌ Número de SNVs (M)
- ❌ Patrón específico de nombres de muestras
- ❌ Número de miRNAs
- ❌ Rango de posiciones

### **LO QUE ES FIJO** (Pipeline puede asumir):
- ✅ Primeras 2 columnas: metadata
- ✅ Sufijo totales: " (PM+1MM+2MM)"
- ✅ Emparejamiento: count + sufijo = total
- ✅ Separador: TAB
- ✅ Valores numéricos (float)

---

## 🎯 **¿ES CORRECTO MI ENTENDIMIENTO?**

Déjame resumir lo que entendí:

### **PATRÓN DEL INPUT**:

1. **2 columnas metadata** (siempre primeras):
   - "miRNA name"
   - "pos:mut"

2. **N columnas counts** (nombres limpios):
   - Sample_1_name
   - Sample_2_name
   - ...
   - Sample_N_name

3. **N columnas totales** (mismo nombre + sufijo):
   - Sample_1_name **(PM+1MM+2MM)**
   - Sample_2_name **(PM+1MM+2MM)**
   - ...
   - Sample_N_name **(PM+1MM+2MM)**

4. **M filas de datos** (SNVs):
   - Cada fila = un SNV en un miRNA
   - Mismo miRNA puede tener múltiples filas (PM, 2:GT, 3:AG, etc.)
   - Total es el MISMO para todas las filas del mismo miRNA

5. **Relación matemática**:
   - Para cada par (count_i, total_i): VAF_i = count_i / total_i
   - Para mismo miRNA: Σ VAF ≈ 1.0

---

## ❓ **¿ESTO ES CORRECTO?**

Si sí, puedo ajustar todas las funciones del pipeline para:
- ✅ Auto-detectar N (número de muestras)
- ✅ Auto-emparejar counts con totales
- ✅ Funcionar con CUALQUIER dataset que siga este patrón
- ✅ No hardcodear números específicos (415 muestras, 832 cols, etc.)

**¿Confirmas que este es el patrón correcto?** 🔍






