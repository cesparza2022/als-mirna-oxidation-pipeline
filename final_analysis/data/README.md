# 📁 DATA DIRECTORY

Esta carpeta contiene los **archivos de input** para el pipeline de análisis de oxidación de miRNAs.

---

## 📄 **ARCHIVOS**

### 1. `example_input_mini.tsv` (Ejemplo pequeño)
- **Tamaño**: 50 filas × 22 columnas
- **Contenido**: 
  - 1 miRNA: `hsa-let-7a-5p`
  - 49 SNVs de ese miRNA
  - 10 muestras SNV + 10 muestras totales
- **Propósito**: Testing rápido, debugging, ejemplos de código
- **Tiempo de procesamiento**: < 1 segundo

### 2. `miRNA_count.Q33.txt` (Dataset completo - NO INCLUIDO)
- **Tamaño**: 68,969 filas × 832 columnas (~200 MB)
- **Contenido**:
  - 1,728 miRNAs únicos
  - 68,968 SNVs
  - 415 muestras (313 ALS, 102 Control)
- **Ubicación**: `/Users/cesaresparza/New_Desktop/UCSD/8OG/organized/02_data/Magen_ALS-bloodplasma/miRNA_count.Q33.txt`
- **Propósito**: Análisis completo, generación de figuras/tablas para publicación
- **Tiempo de procesamiento**: ~15-20 minutos

---

## 🎯 **USO**

### Cargar Ejemplo Pequeño:
```r
# Rápido para testing
data <- read.delim("data/example_input_mini.tsv", stringsAsFactors = FALSE)
```

### Cargar Dataset Completo:
```r
# Análisis completo
data <- read.delim("/Users/cesaresparza/New_Desktop/UCSD/8OG/organized/02_data/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", 
                   stringsAsFactors = FALSE)
```

### Configuración en YAML:
```yaml
# config/default_config.yaml
io:
  input_file: "data/example_input_mini.tsv"  # Para testing
  # input_file: "/path/to/miRNA_count.Q33.txt"  # Para análisis completo
```

---

## 📋 **FORMATO DE INPUT**

Ver especificación completa en: `../INPUT_SPECIFICATION.md`

### Resumen:
- **Formato**: TSV (tab-separated)
- **Columnas**: `miRNA name` + `pos:mut` + SNV counts + Totales
- **Valores**: Numéricos (float), 0.0 para missing
- **Encoding**: UTF-8

### Estructura:
```
miRNA name      pos:mut   Sample_1   ...   Sample_N   Sample_1 (PM+1MM+2MM)   ...   Sample_N (PM+1MM+2MM)
hsa-let-7a-5p   PM        599187.0   ...   118908.0   611158.0                ...   120716.0
hsa-let-7a-5p   2:GT      9.0        ...   0.0        611158.0                ...   120716.0
```

---

## ⚠️ **NOTA IMPORTANTE**

El archivo `miRNA_count.Q33.txt` **NO se incluye en el repositorio GitHub** por su tamaño (200 MB).

### Obtener el dataset completo:

1. **Desde GEO**:
   - Accession: GSE168714
   - URL: https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE168714
   - Paper: Magen et al., Nature Communications 2023

2. **Contacto directo**:
   - Email: cesaresparza@[email]
   - El autor puede proveer el archivo procesado

---

## 🧪 **CREAR TU PROPIO EJEMPLO**

Si tienes el dataset completo, puedes crear ejemplos personalizados:

```bash
# Extraer let-7 family (primeras 50 mutaciones, 20 muestras)
head -1 miRNA_count.Q33.txt > my_example.tsv
grep "hsa-let-7" miRNA_count.Q33.txt | head -50 | \
  cut -f1-22,418-437 >> my_example.tsv
```

O en R:
```r
# Cargar dataset completo
full_data <- read.delim("miRNA_count.Q33.txt")

# Filtrar let-7 family
let7_data <- full_data %>%
  filter(str_detect(`miRNA name`, "hsa-let-7")) %>%
  head(100)

# Seleccionar subset de muestras
example <- let7_data %>%
  select(1:2, 3:22, 418:437)  # 2 metadata + 20 SNV + 20 totales

# Guardar
write.table(example, "my_let7_example.tsv", 
            sep = "\t", quote = FALSE, row.names = FALSE)
```

---

## 📊 **ESTADÍSTICAS DEL DATASET COMPLETO**

| Métrica | Valor |
|---------|-------|
| Filas totales | 68,969 |
| miRNAs únicos | 1,728 |
| SNVs únicos | 68,968 |
| Muestras ALS | 313 |
| Muestras Control | 102 |
| Total muestras | 415 |
| Mutaciones G>T | ~2,193 (7.5% de SNVs) |
| G>T en seed (pos 2-8) | ~397 (18.1% de G>T) |
| miRNAs con G>T en seed | ~270 |

---

## 🔍 **VALIDACIÓN RÁPIDA**

```r
# Verificar formato del input
source("../src/core/io.R")
validate_input_file("data/example_input_mini.tsv")

# Debe imprimir:
# ✓ Input validation passed
```

---

**Última actualización**: Octubre 15, 2025







