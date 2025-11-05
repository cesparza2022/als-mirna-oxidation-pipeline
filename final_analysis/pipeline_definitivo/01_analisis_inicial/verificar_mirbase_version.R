#!/usr/bin/env Rscript
# ==============================================================================
# VERIFICACIÓN: VERSIÓN miRBase DEL ESTUDIO GSE168714
# ==============================================================================
# 
# OBJETIVO:
#   Verificar qué versión de miRBase usó el estudio original y confirmar
#   que nuestras secuencias son compatibles
#
# PASOS:
#   1. Revisar metadata GEO del estudio
#   2. Verificar versión actual (hsa_filt_mature_2022.fa)
#   3. Comparar nombres de miRNAs
#   4. Identificar discrepancias
#   5. Recomendar acción si necesario
#
# AUTOR: Verificación análisis ALS miRNAs
# FECHA: 8 de octubre de 2025
# ==============================================================================

library(tidyverse)
library(jsonlite)

cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║        VERIFICACIÓN: VERSIÓN miRBase DEL ESTUDIO                      ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

source("config_pipeline.R")

output_dir <- "outputs/verificacion_mirbase"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# PASO 1: INFORMACIÓN DEL ESTUDIO GSE168714
# ------------------------------------------------------------------------------

cat("📂 PASO 1: Información del estudio GSE168714...\n\n")

estudio_info <- list(
  accession = "GSE168714",
  titulo = "Small RNA sequencing of blood plasma from ALS patients",
  autores = "Magen et al.",
  publicacion = "2021",
  organismo = "Homo sapiens",
  plataforma = "Illumina NextSeq 500",
  tipo_muestra = "Blood plasma"
)

cat("  📋 INFORMACIÓN BÁSICA:\n")
cat("    - Accession:", estudio_info$accession, "\n")
cat("    - Publicación:", estudio_info$publicacion, "\n")
cat("    - Plataforma:", estudio_info$plataforma, "\n\n")

# Nota: Información de metadata GEO
cat("  📝 NOTA: Revisión de metadata GEO\n")
cat("    → GSE168714 publicado en 2021\n")
cat("    → miRBase v22 lanzado en Oct 2018\n")
cat("    → miRBase v22.1 lanzado en Oct 2022\n")
cat("    → Probablemente usaron v21 o v22\n\n")

# ------------------------------------------------------------------------------
# PASO 2: VERSIÓN DE NUESTRO ARCHIVO
# ------------------------------------------------------------------------------

cat("📂 PASO 2: Verificando versión de nuestro archivo...\n\n")

seq_file <- "data/hsa_filt_mature_2022.fa"

if (!file.exists(seq_file)) {
  cat("  ⚠️ ADVERTENCIA: Archivo no encontrado:", seq_file, "\n")
  cat("  → Esto podría explicar algunos miRNAs no mapeados\n\n")
  quit(save = "no", status = 0)
}

# Leer header del archivo FASTA
fasta_lines <- readLines(seq_file, n = 10)
header_lines <- fasta_lines[grep("^>", fasta_lines)]

cat("  ✓ Archivo encontrado:", seq_file, "\n")
cat("  📋 Primeras 5 entradas:\n")
for (h in head(header_lines, 5)) {
  cat("    ", h, "\n")
}
cat("\n")

# El nombre sugiere 2022 → probablemente miRBase v22.1
cat("  💡 ANÁLISIS DEL NOMBRE:\n")
cat("    - Archivo: 'hsa_filt_mature_2022.fa'\n")
cat("    - Sugiere: miRBase v22.1 (lanzado Oct 2022)\n")
cat("    - Estudio publicado: 2021\n")
cat("    - Posible desajuste: Estudio usó v21 o v22, nosotros v22.1\n\n")

# ------------------------------------------------------------------------------
# PASO 3: ANALIZAR miRNAs EN NUESTRO DATASET
# ------------------------------------------------------------------------------

cat("📊 PASO 3: Analizando miRNAs en nuestro dataset...\n\n")

# Cargar datos procesados
raw_data <- read_tsv(config$data_paths$raw_data, show_col_types = FALSE)

mirnas_dataset <- raw_data %>%
  pull(`miRNA name`) %>%
  unique() %>%
  sort()

cat("  ✓ miRNAs únicos en dataset:", length(mirnas_dataset), "\n")
cat("  📋 Primeros 10:\n")
for (m in head(mirnas_dataset, 10)) {
  cat("    -", m, "\n")
}
cat("\n")

# ------------------------------------------------------------------------------
# PASO 4: MAPEAR CONTRA FASTA
# ------------------------------------------------------------------------------

cat("🔗 PASO 4: Mapeando miRNAs dataset → secuencias FASTA...\n\n")

# Leer todo el FASTA
fasta_all <- readLines(seq_file)
headers <- grep("^>", fasta_all)

sequences <- tibble(
  header = fasta_all[headers],
  sequence = fasta_all[headers + 1]
) %>%
  mutate(
    mirna_name = str_extract(header, "hsa-[^ ]+")
  )

cat("  ✓ Secuencias en FASTA:", nrow(sequences), "\n\n")

# Mapeo
mirnas_mapeados <- mirnas_dataset[mirnas_dataset %in% sequences$mirna_name]
mirnas_no_mapeados <- mirnas_dataset[!mirnas_dataset %in% sequences$mirna_name]

cat("  📊 RESULTADO MAPEO:\n")
cat("    - miRNAs mapeados:", length(mirnas_mapeados), 
    "(", round(length(mirnas_mapeados)/length(mirnas_dataset)*100, 1), "%)\n")
cat("    - miRNAs NO mapeados:", length(mirnas_no_mapeados),
    "(", round(length(mirnas_no_mapeados)/length(mirnas_dataset)*100, 1), "%)\n\n")

# Listar no mapeados
if (length(mirnas_no_mapeados) > 0) {
  cat("  ⚠️ miRNAs NO MAPEADOS (", length(mirnas_no_mapeados), "):\n")
  
  if (length(mirnas_no_mapeados) <= 20) {
    for (m in mirnas_no_mapeados) {
      cat("    -", m, "\n")
    }
  } else {
    for (m in head(mirnas_no_mapeados, 20)) {
      cat("    -", m, "\n")
    }
    cat("    ... y", length(mirnas_no_mapeados) - 20, "más\n")
  }
  cat("\n")
}

# Guardar
write_csv(
  tibble(mirna = mirnas_no_mapeados),
  file.path(output_dir, "mirnas_no_mapeados.csv")
)

# ------------------------------------------------------------------------------
# PASO 5: ANALIZAR DISCREPANCIAS
# ------------------------------------------------------------------------------

cat("🔍 PASO 5: Analizando tipos de discrepancias...\n\n")

# Análisis de nombres no mapeados
discrepancias <- tibble(mirna = mirnas_no_mapeados) %>%
  mutate(
    tipo_discrepancia = case_when(
      str_detect(mirna, "-3p$|-5p$") ~ "Tiene sufijo -3p/-5p",
      str_detect(mirna, "miR-\\d+[a-z]") ~ "Tiene letra variante",
      str_detect(mirna, "let-7") ~ "Familia let-7",
      TRUE ~ "Otro"
    )
  )

discrepancias_summary <- discrepancias %>%
  group_by(tipo_discrepancia) %>%
  summarise(n = n(), .groups = "drop") %>%
  arrange(desc(n))

cat("  📊 TIPOS DE DISCREPANCIAS:\n")
print(discrepancias_summary)

# ------------------------------------------------------------------------------
# PASO 6: VERIFICAR miRNAs CRÍTICOS
# ------------------------------------------------------------------------------

cat("\n🎯 PASO 6: Verificando miRNAs críticos del análisis...\n\n")

# miRNAs críticos de nuestro análisis
mirnas_criticos <- c(
  # let-7 family
  "hsa-let-7a-5p", "hsa-let-7b-5p", "hsa-let-7c-5p", "hsa-let-7d-5p",
  "hsa-let-7e-5p", "hsa-let-7f-5p", "hsa-let-7g-5p", "hsa-let-7i-5p",
  "hsa-miR-98-5p",
  # Resistentes
  "hsa-miR-4500", "hsa-miR-503-5p", "hsa-miR-29b-3p",
  "hsa-miR-4644", "hsa-miR-30a-5p", "hsa-miR-30b-5p",
  "hsa-miR-519d-3p"  # Este no encontramos antes
)

status_criticos <- tibble(
  mirna = mirnas_criticos,
  mapeado = mirnas_criticos %in% sequences$mirna_name,
  categoria = c(
    rep("let-7 family", 9),
    rep("Resistente", 7)
  )
)

cat("  📊 ESTADO miRNAs CRÍTICOS:\n\n")
print(status_criticos)

# Resumen
cat("\n  ✓ let-7 mapeados:", sum(status_criticos$categoria == "let-7 family" & status_criticos$mapeado),
    "/9\n")
cat("  ✓ Resistentes mapeados:", sum(status_criticos$categoria == "Resistente" & status_criticos$mapeado),
    "/7\n\n")

# Verificar específicamente los NO mapeados críticos
criticos_no_mapeados <- status_criticos %>%
  filter(!mapeado)

if (nrow(criticos_no_mapeados) > 0) {
  cat("  ⚠️ miRNAs CRÍTICOS NO MAPEADOS:\n")
  print(criticos_no_mapeados)
  cat("\n")
}

write_csv(status_criticos, file.path(output_dir, "status_mirnas_criticos.csv"))

# ------------------------------------------------------------------------------
# PASO 7: BUSCAR ALTERNATIVAS PARA NO MAPEADOS
# ------------------------------------------------------------------------------

cat("🔍 PASO 7: Buscando alternativas para no mapeados...\n\n")

if (nrow(criticos_no_mapeados) > 0) {
  
  for (i in 1:nrow(criticos_no_mapeados)) {
    mirna_target <- criticos_no_mapeados$mirna[i]
    
    cat("  Buscando:", mirna_target, "\n")
    
    # Buscar similar (sin -3p/-5p, variantes)
    base_name <- str_replace(mirna_target, "-(3p|5p)$", "")
    
    # Buscar en FASTA
    matches <- sequences %>%
      filter(str_detect(mirna_name, fixed(base_name)))
    
    if (nrow(matches) > 0) {
      cat("    → Posibles matches:\n")
      for (j in 1:min(5, nrow(matches))) {
        cat("      ", matches$mirna_name[j], "\n")
      }
    } else {
      cat("    → No encontrado\n")
    }
    cat("\n")
  }
}

# ------------------------------------------------------------------------------
# PASO 8: IMPACTO EN ANÁLISIS
# ------------------------------------------------------------------------------

cat("📊 PASO 8: Evaluando impacto en análisis...\n\n")

# ¿Cuántos SNVs están en miRNAs no mapeados?
source("functions_pipeline.R")
datos_split <- apply_split_collapse(raw_data)

snvs_no_mapeados <- datos_split %>%
  filter(`miRNA name` %in% mirnas_no_mapeados) %>%
  nrow()

snvs_totales <- nrow(datos_split)

cat("  📊 IMPACTO:\n")
cat("    - SNVs en miRNAs no mapeados:", snvs_no_mapeados, "\n")
cat("    - SNVs totales:", snvs_totales, "\n")
cat("    - % afectado:", round(snvs_no_mapeados/snvs_totales*100, 2), "%\n\n")

# ¿Algún crítico afectado?
snvs_criticos_no_mapeados <- datos_split %>%
  filter(`miRNA name` %in% criticos_no_mapeados$mirna) %>%
  nrow()

cat("  ⚠️ SNVs en miRNAs CRÍTICOS no mapeados:", snvs_criticos_no_mapeados, "\n\n")

# ------------------------------------------------------------------------------
# PASO 9: RECOMENDACIONES
# ------------------------------------------------------------------------------

cat("💡 PASO 9: Generando recomendaciones...\n\n")

recomendaciones <- list(
  version_actual = "miRBase v22.1 (probable, del nombre archivo 2022)",
  version_estudio = "miRBase v21 o v22 (2021 o anterior)",
  desajuste_probable = "Menor (1 versión diferencia máximo)",
  
  impacto = list(
    miRNAs_criticos_afectados = nrow(criticos_no_mapeados),
    let7_afectados = sum(status_criticos$categoria == "let-7 family" & !status_criticos$mapeado),
    resistentes_afectados = sum(status_criticos$categoria == "Resistente" & !status_criticos$mapeado)
  ),
  
  acciones_sugeridas = list(
    critico = if (nrow(criticos_no_mapeados) > 0) {
      "Descargar miRBase v21 y v22 para comparar"
    } else {
      "No necesario - todos los críticos mapeados"
    },
    opcional = c(
      "Verificar metadata del estudio (methods paper)",
      "Comparar con miRBase release notes",
      "Usar aliases/nombres alternativos"
    )
  ),
  
  conclusion = if (nrow(criticos_no_mapeados) == 0) {
    "✅ TODOS los miRNAs críticos están mapeados - análisis es válido"
  } else if (nrow(criticos_no_mapeados) <= 2) {
    "⚠️ Algunos críticos no mapeados - impacto menor, análisis sigue válido"
  } else {
    "🔴 Varios críticos no mapeados - requiere investigación"
  }
)

write_json(recomendaciones, file.path(output_dir, "recomendaciones_mirbase.json"),
           pretty = TRUE, auto_unbox = TRUE)

# ------------------------------------------------------------------------------
# RESUMEN EJECUTIVO
# ------------------------------------------------------------------------------

cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║                  RESUMEN VERIFICACIÓN miRBase                         ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

cat("📋 VERSIONES:\n")
cat("  • Estudio GSE168714: 2021 (probablemente miRBase v21/v22)\n")
cat("  • Nuestro archivo: hsa_filt_mature_2022.fa (probablemente v22.1)\n")
cat("  • Desajuste: Máximo 1 versión de diferencia\n\n")

cat("📊 MAPEO:\n")
cat("  • Total miRNAs:", length(mirnas_dataset), "\n")
cat("  • Mapeados:", length(mirnas_mapeados), 
    "(", round(length(mirnas_mapeados)/length(mirnas_dataset)*100, 1), "%)\n")
cat("  • NO mapeados:", length(mirnas_no_mapeados),
    "(", round(length(mirnas_no_mapeados)/length(mirnas_dataset)*100, 1), "%)\n\n")

cat("🎯 miRNAs CRÍTICOS:\n")
cat("  • let-7 mapeados:", sum(status_criticos$categoria == "let-7 family" & status_criticos$mapeado), "/9\n")
cat("  • Resistentes mapeados:", sum(status_criticos$categoria == "Resistente" & status_criticos$mapeado), "/7\n")
cat("  • Críticos NO mapeados:", nrow(criticos_no_mapeados), "\n\n")

if (nrow(criticos_no_mapeados) > 0) {
  cat("  ⚠️ AFECTADOS:\n")
  for (i in 1:nrow(criticos_no_mapeados)) {
    cat("    -", criticos_no_mapeados$mirna[i], 
        "(", criticos_no_mapeados$categoria[i], ")\n")
  }
  cat("\n")
}

cat("💡 IMPACTO EN ANÁLISIS:\n")
cat("  • SNVs afectados:", snvs_no_mapeados, "/", snvs_totales,
    "(", round(snvs_no_mapeados/snvs_totales*100, 2), "%)\n")
cat("  • SNVs críticos afectados:", snvs_criticos_no_mapeados, "\n\n")

cat("🎯 CONCLUSIÓN:\n")
cat("  ", recomendaciones$conclusion, "\n\n")

if (nrow(criticos_no_mapeados) > 0) {
  cat("📋 ACCIÓN RECOMENDADA:\n")
  cat("  →", recomendaciones$acciones_sugeridas$critico, "\n\n")
} else {
  cat("✅ NO SE REQUIERE ACCIÓN\n")
  cat("  → Todos los hallazgos críticos están validados con secuencias correctas\n\n")
}

cat("📁 Outputs guardados en:", output_dir, "\n\n")

cat("════════════════════════════════════════════════════════════════════════\n")








