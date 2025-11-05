# 🧬 PLAN: Análisis de Motivos de Secuencia y Logos

**Objetivo:** Descubrir relaciones entre miRNAs mutados basado en similitud de secuencia

---

## 🎯 TU PREGUNTA EXACTA

> "Si miRNA-X tiene G>T en posición 3, y miRNA-Y también tiene G>T en posición 3, tal vez si vemos los logos de los dos miRNAs encontremos alguna similitud"

**Respuesta: ¡EXACTO!** Esto es análisis de **motivos conservados** (sequence motifs).

---

## 🔬 QUÉ NECESITAMOS ANALIZAR

### **NIVEL 1: Agrupación por POSICIÓN afectada**

```
GRUPO 1: miRNAs con G>T en posición 2
  → miR-A, miR-B, miR-C, ...
  → ¿Tienen secuencias similares alrededor de pos 2?

GRUPO 2: miRNAs con G>T en posición 3
  → miR-D, miR-E, miR-F, ...
  → ¿Tienen secuencias similares alrededor de pos 3?

etc.
```

### **NIVEL 2: Extracción de contexto (ventana ±2)**

```
miR-X tiene G>T en posición 3:

Secuencia seed completa: A G G A G C U
Posiciones:              1 2 3 4 5 6 7
                             ↑
                         G>T aquí (pos 3)

Contexto ±2 (ventana de 5 nt):
  Posiciones 1-5: A G G A G
                    ↑
                  G afectado

Trinucleótido (ventana ±1):
  Posiciones 2-4: G G A
                  ↑
                XGY context
```

### **NIVEL 3: Sequence LOGO**

**¿Qué es un Sequence Logo?**

```
Alinear TODAS las secuencias (ventana ±2 alrededor del G afectado):

miR-A: A G G A G
miR-B: U G G U G
miR-C: C G G A G
miR-D: A G G C G
...

LOGO:
  Posición -2: A (40%), U (30%), C (20%), G (10%)
  Posición -1: G (95%) ← MUY CONSERVADO
  Posición 0:  G (100%) ← El G que muta
  Posición +1: A (45%), U (35%), C (20%)
  Posición +2: G (60%), C (30%), U (10%)

INTERPRETACIÓN:
  → Posición -1 es casi siempre G (95%)
  → Esto es un motivo GG (GpG dinucleótido)
  → GpG es MÁS susceptible a oxidación ✅
```

### **NIVEL 4: Clustering por similitud**

```
Agrupar miRNAs por:
  1. Similitud de secuencia (edit distance)
  2. Contexto trinucleótido (XGY)
  3. Familias (let-7, miR-9, etc.)

RESULTADO:
  CLUSTER 1: GG context (GpG) - Altamente oxidable
  CLUSTER 2: CG context (CpG) - Moderadamente oxidable
  CLUSTER 3: AG/UG context - Menos oxidable
```

---

## 🧬 DATOS QUE NECESITAMOS

### **1. Secuencias de miRBase** (externas)

```
Para cada miRNA candidato, necesitamos:
  • Secuencia madura completa
  • Secuencia seed (posiciones 2-8)
  
Fuente: miRBase (base de datos pública)
  URL: https://www.mirbase.org/
  
Formato:
  >hsa-miR-196a-5p
  UAGGUAGUUUCAUGUUGUUGGG
  └─────┘
   Seed (2-8): AGGUAGU
```

**Opción A: Descargar de miRBase**
- Archivo: mature.fa (todas las secuencias maduras)
- Parsear y extraer solo nuestros candidatos

**Opción B: Usar paquete de R**
- `miRBaseConverter` o `microRNA`
- Acceso programático

### **2. Alineación de secuencias**

```
Para miRNAs con G>T en la MISMA posición:
  1. Extraer ventana ±3 alrededor del G
  2. Alinear secuencias
  3. Crear logo plot
  4. Identificar posiciones conservadas
```

---

## 📊 ANÁLISIS PROPUESTO

### **ANÁLISIS 1: Logo Plots por Posición**

**Para cada posición (2, 3, 5 - las enriquecidas):**

```R
# Ejemplo: Posición 3

# PASO 1: Identificar miRNAs con G>T en pos 3
mirnas_pos3 <- candidates %>%
  filter(str_detect(Positions, "3"))

# Resultado: ~10 miRNAs con G>T en pos 3

# PASO 2: Obtener secuencias seed de miRBase
seeds_pos3 <- get_mirbase_seeds(mirnas_pos3$miRNA)

# Ejemplo:
#   miR-21: UAGCUUA
#   miR-185: UGGAGAGA  (tiene múltiples posiciones)
#   miR-24: UGGCUCAGU

# PASO 3: Extraer ventana ±3 alrededor de pos 3
windows_pos3 <- extract_window(seeds_pos3, position = 3, window = 3)

# Ejemplo (pos 3 es índice 2 en 0-based):
#   miR-21: AGC (pos 1-3) o AGCUUA (pos 1-6)
#   miR-185: GGAGA (ventana 5)
#   miR-24: GGCUCA (ventana 6)

# PASO 4: Crear alignment
alignment <- align_sequences(windows_pos3)

# PASO 5: Generar LOGO
library(ggseqlogo)
logo_plot <- ggseqlogo(alignment, method = "prob")

# RESULTADO:
#   Logo mostrando qué nucleótidos están conservados
#   Si posición -1 es siempre G → motivo GG (GpG)
```

**Output:**
- **LOGO_Position_2.png** - Motivos alrededor de pos 2
- **LOGO_Position_3.png** - Motivos alrededor de pos 3
- **LOGO_Position_5.png** - Motivos alrededor de pos 5

---

### **ANÁLISIS 2: Contexto Trinucleótido (XGY)**

**Clasificar cada G>T por su contexto:**

```R
# Para cada SNV, extraer XGY (nucleótido antes, G, nucleótido después)

snv_context <- map_df(candidates_snvs, function(snv) {
  
  mirna <- snv$miRNA
  position <- snv$Position  # ej: 3
  
  # Obtener seed sequence
  seed <- get_seed_sequence(mirna)  # ej: "UAGCUUA"
  
  # Extraer contexto
  if (position > 1 && position < 7) {
    x <- substr(seed, position - 1, position - 1)  # Nucleótido antes
    g <- "G"  # El G que muta
    y <- substr(seed, position + 1, position + 1)  # Nucleótido después
    
    trinuc <- paste0(x, "G", y)
    
    return(data.frame(
      miRNA = mirna,
      Position = position,
      Trinucleotide = trinuc,
      Context_Type = classify_context(trinuc)
    ))
  }
})

# Clasificar contextos
classify_context <- function(trinuc) {
  x <- substr(trinuc, 1, 1)
  y <- substr(trinuc, 3, 3)
  
  if (x == "G") return("GpG (High Oxidation)")
  if (x == "C") return("CpG (Moderate)")
  if (x == "A") return("ApG")
  if (x == "U") return("UpG")
}

# RESULTADO:
# Tabla de contextos:
#   miR-21, pos 3: GGA → GpG (High Oxidation) ✅
#   miR-185, pos 2: UGC → UpG
#   miR-1, pos 3: GGU → GpG (High Oxidation) ✅
```

**Test de enriquecimiento:**
```R
# ¿Hay más GpG de lo esperado por azar?

observed_GpG <- mean(snv_context$Context_Type == "GpG (High Oxidation)")
expected_GpG <- 0.25  # Si fuera aleatorio (1 de 4 nucleótidos)

enrichment <- observed_GpG / expected_GpG

if (enrichment > 1.5) {
  cat("🔥 HALLAZGO: GpG context enriquecido\n")
  cat("   Confirma susceptibilidad a oxidación\n")
}
```

---

### **ANÁLISIS 3: Clustering por Similitud de Seed**

**Agrupar miRNAs por similitud de secuencia seed completa:**

```R
# PASO 1: Obtener seeds de todos los candidatos
candidate_seeds <- get_mirbase_seeds(candidates$miRNA)

# PASO 2: Calcular matriz de distancia (edit distance)
library(stringdist)

dist_matrix <- stringdistmatrix(candidate_seeds, method = "lv")  # Levenshtein

# PASO 3: Clustering jerárquico
hc <- hclust(as.dist(dist_matrix), method = "ward.D2")

# PASO 4: Identificar clusters
clusters <- cutree(hc, k = 3)  # 3 grupos

# PASO 5: Ver si clusters tienen:
#   • Mismas posiciones afectadas
#   • Mismo contexto (GpG, CpG)
#   • Mismas familias

# RESULTADO:
#   CLUSTER 1: let-7 family, GpG context, pos 2-3
#   CLUSTER 2: miR-9 family, CpG context, pos 5
#   CLUSTER 3: Mixed, various contexts
```

---

### **ANÁLISIS 4: Network de Similitud de Secuencia**

**Crear red donde:**
- **Nodos** = miRNAs candidatos
- **Edges** = Similitud de secuencia > umbral
- **Color** = Familia
- **Shape** = Posición afectada

```R
# Si dos miRNAs tienen:
#   • Edit distance < 3
#   • O mismo contexto trinucleótido
#   → Conectarlos

# RESULTADO:
#   Sub-networks de miRNAs relacionados por secuencia
#   ¿Hay módulos conservados?
```

---

## 🎨 FIGURAS A GENERAR

### **Figura A: Sequence Logos por Posición**

```
Panel A: Logo de miRNAs con G>T en pos 2 (n=X)
Panel B: Logo de miRNAs con G>T en pos 3 (n=Y)
Panel C: Logo de miRNAs con G>T en pos 5 (n=Z)

Cada panel muestra:
  • Conservación en cada posición
  • Motivos enriquecidos (GG, CG, etc.)
```

### **Figura B: Trinucleótido Context**

```
Barplot:
  X-axis: Contexto (GpG, CpG, ApG, UpG)
  Y-axis: Frecuencia (% de SNVs)
  
Con test de enriquecimiento:
  • Línea punteada = Expected (25% cada uno)
  • Barras = Observed
  • Asteriscos si significativo
```

### **Figura C: Heatmap de Similitud**

```
Heatmap:
  Rows/Cols = Candidatos
  Color = Edit distance de seed
  Clusters = Dendrograma

Anotaciones:
  • Familia miRNA
  • Posiciones afectadas
  • Contexto trinuc
```

### **Figura D: Network de Secuencia**

```
Network graph:
  • Nodos = miRNAs
  • Edges = Similitud alta
  • Color = Familia
  • Shape = Contexto (GpG, CpG, etc.)
  • Size = FC (fold change)
```

---

## 🚀 IMPLEMENTACIÓN

### **SCRIPT 1: Obtener Secuencias de miRBase**

```R
#!/usr/bin/env Rscript
# GET_MIRBASE_SEQUENCES.R

library(Biostrings)
library(dplyr)

# Descargar mature.fa de miRBase
# URL: https://www.mirbase.org/ftp/CURRENT/mature.fa.gz

# O usar paquete
library(microRNA)  # Si existe

# Extraer secuencias de nuestros candidatos
candidates <- read_csv("ALS_CANDIDATES_ENHANCED.csv")

get_seed_sequence <- function(mirna_name) {
  # Buscar en miRBase
  # Extraer posiciones 2-8 de la secuencia madura
  # Return: "AGGUAGU" (ejemplo)
}

seed_sequences <- map_chr(candidates$miRNA, get_seed_sequence)

# Guardar
seed_data <- data.frame(
  miRNA = candidates$miRNA,
  Seed_Sequence = seed_sequences,
  Positions = candidates$Positions
)

write_csv(seed_data, "SEED_SEQUENCES.csv")
```

### **SCRIPT 2: Análisis de Motivos**

```R
#!/usr/bin/env Rscript
# ANALYZE_SEQUENCE_MOTIFS.R

library(ggseqlogo)
library(dplyr)

seeds <- read_csv("SEED_SEQUENCES.csv")

# Por cada posición enriquecida (2, 3, 5)
for (pos in c(2, 3, 5)) {
  
  # Filtrar miRNAs con G>T en esta posición
  mirnas_this_pos <- seeds %>%
    filter(str_detect(Positions, as.character(pos)))
  
  # Extraer ventana ±3
  windows <- extract_window_around_position(
    sequences = mirnas_this_pos$Seed_Sequence,
    position = pos,
    window_size = 3
  )
  
  # Crear LOGO
  logo <- ggseqlogo(windows, method = "prob") +
    ggtitle(sprintf("Sequence Logo: miRNAs with G>T at Position %d (n=%d)", 
                    pos, nrow(mirnas_this_pos)))
  
  ggsave(sprintf("LOGO_Position_%d.png", pos), logo, width = 10, height = 6)
  
  # Identificar motivos
  consensus <- get_consensus_sequence(windows)
  cat(sprintf("Posición %d: Consenso = %s\n", pos, consensus))
}
```

### **SCRIPT 3: Contexto Trinucleótido**

```R
#!/usr/bin/env Rscript
# ANALYZE_TRINUCLEOTIDE_CONTEXT.R

# Extraer XGY para cada SNV
trinuc_data <- map_df(1:nrow(snv_details), function(i) {
  
  mirna <- snv_details$miRNA[i]
  position <- snv_details$Position[i]
  
  seed <- get_seed_sequence(mirna)
  
  if (position > 1 && position < nchar(seed)) {
    x <- substr(seed, position - 1, position - 1)
    g <- "G"
    y <- substr(seed, position + 1, position + 1)
    
    trinuc <- paste0(x, "G", y)
    
    return(data.frame(
      miRNA = mirna,
      Position = position,
      Trinucleotide = trinuc,
      Is_GpG = (x == "G"),
      Is_CpG = (x == "C")
    ))
  }
})

# Test de enriquecimiento
observed_GpG <- mean(trinuc_data$Is_GpG)
expected_GpG <- 0.25

pvalue <- binom.test(
  x = sum(trinuc_data$Is_GpG),
  n = nrow(trinuc_data),
  p = expected_GpG
)$p.value

# Plot
fig <- ggplot(trinuc_context_summary, aes(x = Context, y = Frequency)) +
  geom_col(aes(fill = Context)) +
  geom_hline(yintercept = 25, linetype = "dashed", label = "Expected (25%)") +
  labs(title = "Trinucleotide Context Enrichment")

ggsave("TRINUCLEOTIDE_ENRICHMENT.png", fig)
```

### **SCRIPT 4: Clustering por Similitud**

```R
#!/usr/bin/env Rscript
# CLUSTER_BY_SEQUENCE_SIMILARITY.R

library(stringdist)
library(pheatmap)

# Matriz de distancia
dist_matrix <- stringdistmatrix(seeds$Seed_Sequence, method = "lv")
rownames(dist_matrix) <- seeds$miRNA
colnames(dist_matrix) <- seeds$miRNA

# Heatmap con anotaciones
annotation <- data.frame(
  Family = seeds$Family,
  Position = seeds$Positions,
  Context = seeds$Trinuc_Context,
  row.names = seeds$miRNA
)

pheatmap(
  dist_matrix,
  annotation_row = annotation,
  annotation_col = annotation,
  main = "Seed Sequence Similarity Among ALS Candidates"
)
```

---

## 🔥 EJEMPLO CONCRETO

### **Caso: miRNAs con G>T en Posición 3**

**Hipótesis:** Si varios miRNAs tienen G>T en pos 3, tal vez compartan motivo.

```
PASO 1: Identificar
  → 6 miRNAs tienen G>T en pos 3

PASO 2: Obtener secuencias seed
  miR-21:  U A G C U U A
  miR-185: A G G A G A G  (también tiene en pos 2,5,7)
  miR-24:  U G G C U C A  (también tiene en pos 2,8)
  miR-1:   U G G A A U A  (también tiene en pos 2,7)
  ...

PASO 3: Extraer ventana ±2 alrededor de pos 3
  Posiciones 1-5:
  miR-21:  U A G C U
  miR-185: A G G A G
  miR-24:  U G G C U
  miR-1:   U G G A A
           ↑ ↑ ↑
           1 2 3

PASO 4: Alinear y crear LOGO
  
  Posición 1 (pos -2 del G):
    U: 50% ███████
    A: 25% ███
    
  Posición 2 (pos -1 del G):
    G: 75% ███████████ ← MUY CONSERVADO!
    A: 25% ███
    
  Posición 3 (el G que muta):
    G: 100% █████████████ ← Siempre G
    
  Posición 4 (pos +1 del G):
    C: 40% █████
    A: 40% █████
    U: 20% ██
    
  Posición 5 (pos +2 del G):
    U: 40% █████
    A: 30% ████
    G: 20% ██
    C: 10% █

INTERPRETACIÓN:
  → 75% tienen G en posición -1 (GG motif)
  → Esto es GpG dinucleótido
  → GpG es ALTAMENTE susceptible a 8-oxoG
  → CONFIRMA mecanismo oxidativo ✅
```

---

## 📋 OUTPUTS ESPERADOS

### **1. Sequence Logos (3 figuras)**
- Logo para pos 2 (44 miRNAs)
- Logo para pos 3 (33 miRNAs)
- Logo para pos 5 (61 miRNAs)

### **2. Trinucleótido Analysis (1 figura)**
- Barplot de contextos (GpG, CpG, ApG, UpG)
- Test de enriquecimiento
- Comparación vs esperado

### **3. Similarity Heatmap (1 figura)**
- Distancia entre seeds
- Clustering jerárquico
- Anotaciones (familia, posición, contexto)

### **4. Network de Similitud (1 figura)**
- Grafo de miRNAs relacionados
- Color por familia
- Shape por contexto

### **5. Tabla de Motivos (CSV)**
- miRNA, Posición, Contexto, Motivo
- ¿Cuáles comparten motivos?

---

## 🎯 PREGUNTAS PARA TI

### **1. ¿Quieres que implemente esto?**

Necesitaría:
- [ ] A. Descargar secuencias de miRBase (~10 min)
- [ ] B. Crear los 4 scripts de análisis (~1 hr)
- [ ] C. Generar las figuras (~30 min)
- [ ] **Total: ~2 horas**

### **2. ¿Para cuántos candidatos?**

- [ ] A. Solo TIER 3 (6 con pos 2,3,5)
- [ ] B. TIER 2 + TIER 3 (9 candidatos)
- [ ] C. TIER 4 (15 candidatos completo)

### **3. ¿Qué análisis priorizar?**

- [ ] A. Sequence logos (MÁS visual, MÁS informativo) ⭐
- [ ] B. Trinucleótido context (Más simple, más directo)
- [ ] C. Ambos (completo)

### **4. ¿Dónde está el paper que mencionaste?**

Para ver exactamente qué metodología usar, ¿me puedes:
- [ ] A. Pasar el archivo PDF
- [ ] B. Decir el título/autores para buscarlo
- [ ] C. Describir qué figura/análisis específico te gustó

---

## 🚀 SIGUIENTE PASO

**Opción A: Implementar análisis completo de motivos** (~2 hr)
- Descargar miRBase
- Crear logos
- Analizar trinucleótidos
- Clustering por similitud

**Opción B: Análisis rápido de trinucleótidos** (~30 min)
- Solo XGY context
- Test de enriquecimiento GpG
- Sin logos (por ahora)

**Opción C: Ver el paper primero** (~10 min)
- Leer metodología
- Replicar exactamente lo que hacen
- Implementar después

**¿Qué prefieres? Y ¿dónde está el paper?** 📄

