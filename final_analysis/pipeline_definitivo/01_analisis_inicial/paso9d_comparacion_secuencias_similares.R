#!/usr/bin/env Rscript
# ==============================================================================
# PASO 9D: COMPARACIÓN DE miRNAs CON SECUENCIAS SIMILARES
# ==============================================================================
# 
# OBJETIVO:
#   Para las secuencias ultra-susceptibles (ej. TGAGGTA con 89% oxidados):
#   1. Identificar miRNAs con esa MISMA secuencia que NO están oxidados
#   2. Comparar características entre oxidados vs no oxidados (misma secuencia)
#   3. Analizar diferencias en VAFs, expresión, etc.
#   4. Buscar secuencias SIMILARES (1 base diferente) y comparar
#   5. Identificar qué diferencia a los oxidados de los no oxidados
#
# INPUT:
#   - Secuencias de miRNAs
#   - Datos de G>T en semilla
#   - VAFs
#
# OUTPUT:
#   - Comparaciones detalladas por secuencia
#   - Análisis de miRNAs "resistentes"
#   - Factores protectores identificados
#
# AUTOR: Análisis ALS miRNAs
# FECHA: 8 de octubre de 2025
# ==============================================================================

library(tidyverse)
library(jsonlite)

cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║   PASO 9D: COMPARACIÓN miRNAs OXIDADOS vs NO OXIDADOS (misma seq)     ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

# Cargar configuración
source("config_pipeline.R")
source("functions_pipeline.R")

# Directorios
output_paso9d <- file.path(config$output_paths$outputs, "paso9d_secuencias_similares")
output_figures <- file.path(config$output_paths$figures, "paso9d_secuencias_similares")
dir.create(output_paso9d, recursive = TRUE, showWarnings = FALSE)
dir.create(output_figures, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# PASO 9D.1: CARGAR DATOS
# ------------------------------------------------------------------------------

cat("📂 PASO 9D.1: Cargando datos...\n")

# Datos
raw_data <- read_tsv(config$data_paths$raw_data, show_col_types = FALSE)
datos_split <- apply_split_collapse(raw_data)
datos <- calculate_vafs(datos_split)
datos <- filter_high_vafs(datos, threshold = 0.5)

datos <- datos %>%
  mutate(
    position = as.integer(str_extract(`pos:mut`, "^\\d+")),
    mutation_raw = str_extract(`pos:mut`, "(?<=:)[ACGT]{2}"),
    from_base = str_sub(mutation_raw, 1, 1),
    to_base = str_sub(mutation_raw, 2, 2),
    mutation_type = paste0(from_base, ">", to_base)
  )

# Secuencias
seq_file <- "data/hsa_filt_mature_2022.fa"
fasta_lines <- readLines(seq_file)
headers <- grep("^>", fasta_lines)

sequences <- tibble(
  header = fasta_lines[headers],
  sequence = fasta_lines[headers + 1]
) %>%
  mutate(
    mirna_name = str_extract(header, "hsa-[^ ]+"),
    seed_region = substr(sequence, 1, 7)
  ) %>%
  filter(nchar(seed_region) == 7)

# miRNAs con G>T en semilla
mirnas_gt <- datos %>%
  filter(mutation_type == "G>T", position >= 1, position <= 7) %>%
  distinct(`miRNA name`) %>%
  pull(`miRNA name`)

sequences <- sequences %>%
  mutate(tiene_gt = mirna_name %in% mirnas_gt)

cat("  ✓ Secuencias cargadas:", nrow(sequences), "\n")
cat("  ✓ Con G>T:", sum(sequences$tiene_gt), "\n")
cat("  ✓ Sin G>T:", sum(!sequences$tiene_gt), "\n\n")

# ------------------------------------------------------------------------------
# PASO 9D.2: ANALIZAR SECUENCIAS ULTRA-SUSCEPTIBLES
# ------------------------------------------------------------------------------

cat("🔥 PASO 9D.2: Analizando secuencias ultra-susceptibles...\n")

# Top 5 secuencias más oxidadas (del Paso 9C)
top_sequences <- c("TGAGGTA", "TCAGTGC", "TAGCAGC", "TGGAGAG", "TAGCACC")

cat("\n  📊 ANÁLISIS POR SECUENCIA:\n\n")

resultados_comparacion <- list()

for (seq in top_sequences) {
  
  cat("  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
  cat("  Secuencia:", seq, "\n")
  cat("  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")
  
  # Filtrar miRNAs con esta secuencia
  mirnas_seq <- sequences %>%
    filter(seed_region == seq)
  
  n_total <- nrow(mirnas_seq)
  n_oxidados <- sum(mirnas_seq$tiene_gt)
  n_no_oxidados <- n_total - n_oxidados
  perc_oxidados <- round(n_oxidados / n_total * 100, 1)
  
  cat("  Total miRNAs con esta secuencia:", n_total, "\n")
  cat("  Oxidados (con G>T):", n_oxidados, sprintf("(%.1f%%)", perc_oxidados), "\n")
  cat("  NO oxidados:", n_no_oxidados, "\n\n")
  
  if (n_oxidados > 0 && n_no_oxidados > 0) {
    
    cat("  ✅ OXIDADOS:\n")
    oxidados_list <- mirnas_seq %>% filter(tiene_gt) %>% pull(mirna_name)
    cat("    ", paste(oxidados_list, collapse = ", "), "\n\n")
    
    cat("  ⭕ NO OXIDADOS:\n")
    no_oxidados_list <- mirnas_seq %>% filter(!tiene_gt) %>% pull(mirna_name)
    cat("    ", paste(no_oxidados_list, collapse = ", "), "\n\n")
    
    # Guardar para análisis posterior
    resultados_comparacion[[seq]] <- list(
      secuencia = seq,
      n_total = n_total,
      n_oxidados = n_oxidados,
      n_no_oxidados = n_no_oxidados,
      perc_oxidados = perc_oxidados,
      oxidados = oxidados_list,
      no_oxidados = no_oxidados_list
    )
    
  } else if (n_no_oxidados == 0) {
    cat("  ⚠️ TODOS oxidados (100%)\n\n")
    
    cat("  ✅ LISTA COMPLETA:\n")
    all_list <- mirnas_seq %>% pull(mirna_name)
    cat("    ", paste(all_list, collapse = ", "), "\n\n")
    
    resultados_comparacion[[seq]] <- list(
      secuencia = seq,
      n_total = n_total,
      n_oxidados = n_oxidados,
      n_no_oxidados = 0,
      perc_oxidados = 100,
      oxidados = all_list,
      no_oxidados = character(0)
    )
    
  } else {
    cat("  ⚠️ Ninguno oxidado\n\n")
  }
}

# Guardar resumen
resumen_secuencias <- map_df(resultados_comparacion, ~tibble(
  secuencia = .x$secuencia,
  n_total = .x$n_total,
  n_oxidados = .x$n_oxidados,
  n_no_oxidados = .x$n_no_oxidados,
  perc_oxidados = .x$perc_oxidados
))

write_csv(resumen_secuencias, file.path(output_paso9d, "paso9d_resumen_secuencias.csv"))

# ------------------------------------------------------------------------------
# PASO 9D.3: ANÁLISIS DETALLADO DE TGAGGTA (let-7)
# ------------------------------------------------------------------------------

cat("🎯 PASO 9D.3: Análisis profundo de TGAGGTA (let-7 family)...\n\n")

# Todos los miRNAs con TGAGGTA
tgaggta_mirnas <- sequences %>%
  filter(seed_region == "TGAGGTA")

cat("  Total miRNAs con TGAGGTA:", nrow(tgaggta_mirnas), "\n")

# Detalles
tgaggta_details <- tgaggta_mirnas %>%
  mutate(
    familia = str_extract(mirna_name, "let-7[a-z]")
  )

# Contar oxidación
tgaggta_oxidation <- tgaggta_details %>%
  group_by(tiene_gt) %>%
  summarise(
    n = n(),
    ejemplos = paste(mirna_name, collapse = ", "),
    .groups = "drop"
  )

cat("\n  📊 DISTRIBUCIÓN:\n")
print(tgaggta_oxidation)

# El único NO oxidado (si existe)
if (sum(!tgaggta_details$tiene_gt) > 0) {
  no_oxidado <- tgaggta_details %>% 
    filter(!tiene_gt) %>%
    pull(mirna_name)
  
  cat("\n  ⭐ miRNA NO OXIDADO con TGAGGTA:\n")
  cat("    →", no_oxidado, "\n")
  cat("    → Este miRNA es 'resistente' a oxidación\n")
  cat("    → ¿Qué lo hace diferente?\n\n")
}

# Guardar
write_csv(tgaggta_details, file.path(output_paso9d, "paso9d_tgaggta_detallado.csv"))

# ------------------------------------------------------------------------------
# PASO 9D.4: BUSCAR SECUENCIAS SIMILARES (1 base diferente)
# ------------------------------------------------------------------------------

cat("🔍 PASO 9D.4: Buscando secuencias similares (1 mismatch)...\n")

# Función para calcular distancia Hamming
hamming_distance <- function(s1, s2) {
  if (nchar(s1) != nchar(s2)) return(NA)
  sum(strsplit(s1, "")[[1]] != strsplit(s2, "")[[1]])
}

# Para TGAGGTA, buscar secuencias con distancia 1
target_seq <- "TGAGGTA"

sequences_with_distance <- sequences %>%
  filter(nchar(seed_region) == 7) %>%
  rowwise() %>%
  mutate(
    dist = hamming_distance(seed_region, target_seq)
  ) %>%
  ungroup() %>%
  filter(dist <= 1) %>%
  arrange(dist, desc(tiene_gt))

cat("  ✓ Secuencias encontradas:\n")
cat("    - Idéntica (dist=0):", sum(sequences_with_distance$dist == 0), "\n")
cat("    - 1 mismatch (dist=1):", sum(sequences_with_distance$dist == 1), "\n\n")

# Resumen de similares
similares_summary <- sequences_with_distance %>%
  filter(dist == 1) %>%
  group_by(seed_region, tiene_gt) %>%
  summarise(n = n(), .groups = "drop") %>%
  pivot_wider(names_from = tiene_gt, values_from = n, values_fill = 0) %>%
  rename(n_oxidados = `TRUE`, n_no_oxidados = `FALSE`) %>%
  mutate(
    total = n_oxidados + n_no_oxidados,
    perc_oxidados = round(n_oxidados / total * 100, 1)
  ) %>%
  arrange(desc(perc_oxidados))

cat("  📊 SECUENCIAS SIMILARES A TGAGGTA (1 mismatch):\n")
print(similares_summary)

write_csv(similares_summary, file.path(output_paso9d, "paso9d_similares_tgaggta.csv"))

# Gráfica
if (nrow(similares_summary) > 0) {
  
  p1 <- ggplot(similares_summary %>% head(15), 
               aes(x = reorder(seed_region, perc_oxidados), y = perc_oxidados)) +
    geom_col(aes(fill = seed_region == "TGAGGTA"), alpha = 0.8) +
    scale_fill_manual(
      values = c("FALSE" = "steelblue", "TRUE" = "#E31A1C"),
      guide = "none"
    ) +
    geom_text(aes(label = paste0(perc_oxidados, "%\n(", n_oxidados, "/", total, ")")),
              hjust = -0.1, size = 3) +
    coord_flip() +
    labs(
      title = "Oxidación en TGAGGTA vs Secuencias Similares (1 mismatch)",
      subtitle = "TGAGGTA destacada en rojo",
      x = "Secuencia Semilla",
      y = "% Oxidados"
    ) +
    theme_minimal()
  
  ggsave(file.path(output_figures, "paso9d_tgaggta_vs_similares.png"),
         p1, width = 12, height = 8)
  cat("  ✓ Figura 'paso9d_tgaggta_vs_similares.png' generada\n\n")
}

# ------------------------------------------------------------------------------
# PASO 9D.5: ANÁLISIS DE miRNAs "RESISTENTES"
# ------------------------------------------------------------------------------

cat("🛡️ PASO 9D.5: Analizando miRNAs 'resistentes' a oxidación...\n")

# Para secuencias con ≥3 miRNAs y ≥50% oxidados, identificar los no oxidados
secuencias_alta_susc <- c("TGAGGTA", "TAGCAGC", "TGGAGAG", "CAAAGTG", "TGTAAAC")

resistentes_list <- list()

for (seq in secuencias_alta_susc) {
  
  mirnas_seq <- sequences %>%
    filter(seed_region == seq)
  
  resistentes <- mirnas_seq %>%
    filter(!tiene_gt) %>%
    pull(mirna_name)
  
  if (length(resistentes) > 0) {
    cat("\n  Secuencia:", seq, "\n")
    cat("    Resistentes:", paste(resistentes, collapse = ", "), "\n")
    
    resistentes_list[[seq]] <- resistentes
  }
}

# Guardar lista de resistentes
if (length(resistentes_list) > 0) {
  resistentes_df <- map_df(names(resistentes_list), ~tibble(
    secuencia = .x,
    mirna_resistente = resistentes_list[[.x]]
  ))
  
  write_csv(resistentes_df, file.path(output_paso9d, "paso9d_mirnas_resistentes.csv"))
  cat("\n  ✓ Lista de resistentes guardada:", nrow(resistentes_df), "miRNAs\n\n")
}

# ------------------------------------------------------------------------------
# PASO 9D.6: COMPARAR VAFs ENTRE OXIDADOS Y NO OXIDADOS (misma secuencia)
# ------------------------------------------------------------------------------

cat("📊 PASO 9D.6: Comparando VAFs (misma secuencia, diferente oxidación)...\n")

# Calcular VAF promedio por miRNA (solo miRNAs en dataset)
vaf_cols <- grep("^VAF_", colnames(datos), value = TRUE)

vaf_per_mirna <- datos %>%
  group_by(`miRNA name`) %>%
  summarise(
    across(all_of(vaf_cols), ~mean(.x, na.rm = TRUE)),
    .groups = "drop"
  ) %>%
  rowwise() %>%
  mutate(
    mean_vaf_all = mean(c_across(all_of(vaf_cols)), na.rm = TRUE)
  ) %>%
  ungroup() %>%
  select(`miRNA name`, mean_vaf_all)

# Join con secuencias
sequences_vaf <- sequences %>%
  left_join(vaf_per_mirna, by = c("mirna_name" = "miRNA name"))

# Para TGAGGTA específicamente
tgaggta_vaf <- sequences_vaf %>%
  filter(seed_region == "TGAGGTA", !is.na(mean_vaf_all))

if (nrow(tgaggta_vaf) > 0) {
  
  cat("\n  📊 TGAGGTA - VAFs:\n")
  
  vaf_comparison <- tgaggta_vaf %>%
    group_by(tiene_gt) %>%
    summarise(
      n = n(),
      mean_vaf = mean(mean_vaf_all, na.rm = TRUE),
      sd_vaf = sd(mean_vaf_all, na.rm = TRUE),
      .groups = "drop"
    )
  
  print(vaf_comparison)
  
  # Test
  if (sum(tgaggta_vaf$tiene_gt) > 0 && sum(!tgaggta_vaf$tiene_gt) > 0) {
    test_vaf <- wilcox.test(
      mean_vaf_all ~ tiene_gt,
      data = tgaggta_vaf
    )
    cat("\n  🔬 Test Wilcoxon (VAF oxidados vs no):\n")
    cat("    p-value =", format.pval(test_vaf$p.value), "\n\n")
  }
}

# ------------------------------------------------------------------------------
# PASO 9D.7: BUSCAR FACTORES PROTECTORES
# ------------------------------------------------------------------------------

cat("🛡️ PASO 9D.7: Buscando factores protectores...\n")

# Comparar características entre resistentes y oxidados (misma secuencia)
# Necesitamos más datos (expresión, etc.) que no tenemos ahora

cat("  ⚠️ Análisis limitado sin datos de expresión o metadatos adicionales\n")
cat("  → Factores que podríamos analizar con más datos:\n")
cat("    - Nivel de expresión\n")
cat("    - Localización celular\n")
cat("    - Procesamiento (pri-miRNA)\n")
cat("    - Modificaciones post-transcripcionales\n\n")

# Pero podemos ver si hay diferencias en número de SNVs totales
if (nrow(resistentes_df) > 0) {
  
  # Contar SNVs totales por miRNA
  snvs_per_mirna <- datos %>%
    group_by(`miRNA name`) %>%
    summarise(n_snvs = n(), .groups = "drop")
  
  resistentes_df <- resistentes_df %>%
    left_join(snvs_per_mirna, by = c("mirna_resistente" = "miRNA name"))
  
  cat("  📊 SNVs en miRNAs resistentes:\n")
  print(resistentes_df %>% select(secuencia, mirna_resistente, n_snvs))
  
  write_csv(resistentes_df, 
            file.path(output_paso9d, "paso9d_resistentes_con_snvs.csv"))
}

cat("\n")

# ------------------------------------------------------------------------------
# PASO 9D.8: CLUSTERING DE SECUENCIAS
# ------------------------------------------------------------------------------

cat("🌳 PASO 9D.8: Clustering de secuencias por similitud...\n")

# Tomar top 50 secuencias más comunes
top_50_seqs <- sequences %>%
  group_by(seed_region) %>%
  summarise(
    n = n(),
    n_oxidados = sum(tiene_gt),
    perc_ox = round(n_oxidados / n * 100, 1),
    .groups = "drop"
  ) %>%
  filter(n >= 3) %>%
  arrange(desc(n)) %>%
  head(50)

cat("  ✓ Top 50 secuencias seleccionadas\n")

# Crear matriz de distancias
seq_list <- top_50_seqs$seed_region
n_seqs <- length(seq_list)

dist_matrix <- matrix(0, nrow = n_seqs, ncol = n_seqs)
rownames(dist_matrix) <- seq_list
colnames(dist_matrix) <- seq_list

for (i in 1:n_seqs) {
  for (j in 1:n_seqs) {
    if (i != j) {
      dist_matrix[i, j] <- hamming_distance(seq_list[i], seq_list[j])
    }
  }
}

cat("  ✓ Matriz de distancias calculada\n")

# Heatmap de distancias
library(pheatmap)

# Anotaciones
annotation_row <- top_50_seqs %>%
  mutate(
    Oxidacion = cut(perc_ox, 
                    breaks = c(0, 10, 30, 50, 100),
                    labels = c("Baja", "Media", "Alta", "Muy Alta"))
  ) %>%
  column_to_rownames("seed_region") %>%
  select(Oxidacion)

ann_colors <- list(
  Oxidacion = c("Baja" = "#1F78B4", "Media" = "#33A02C", 
                "Alta" = "#FF7F00", "Muy Alta" = "#E31A1C")
)

png(file.path(output_figures, "paso9d_clustering_secuencias.png"),
    width = 14, height = 14, units = "in", res = 150)

pheatmap(
  dist_matrix,
  color = colorRampPalette(c("white", "yellow", "orange", "red"))(100),
  cluster_rows = TRUE,
  cluster_cols = TRUE,
  annotation_row = annotation_row,
  annotation_col = annotation_row,
  annotation_colors = ann_colors,
  show_rownames = TRUE,
  show_colnames = FALSE,
  main = "Clustering de Secuencias Semilla por Similitud",
  fontsize = 7,
  fontsize_row = 6
)

dev.off()
cat("  ✓ Figura 'paso9d_clustering_secuencias.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 9D.9: RESUMEN EJECUTIVO
# ------------------------------------------------------------------------------

cat("📋 PASO 9D.9: Generando resumen ejecutivo...\n")

resumen <- list(
  n_secuencias_analizadas = length(top_sequences),
  secuencia_mas_oxidada = "TGAGGTA",
  perc_mas_oxidada = 88.9,
  n_resistentes = nrow(resistentes_df),
  n_top50 = nrow(top_50_seqs)
)

write_json(resumen, file.path(output_paso9d, "paso9d_resumen.json"), pretty = TRUE)

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║                  RESUMEN EJECUTIVO - PASO 9D                          ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

cat("🔥 SECUENCIAS ANALIZADAS:\n")
cat("  • Top 5 ultra-susceptibles comparadas\n")
cat("  • TGAGGTA (let-7): 8/9 oxidados (89%)\n")
cat("  • miRNAs resistentes identificados\n\n")

cat("🛡️ RESISTENTES:\n")
cat("  • Total miRNAs resistentes:", nrow(resistentes_df), "\n")
cat("  • En secuencias ultra-susceptibles\n\n")

cat("🌳 CLUSTERING:\n")
cat("  • Top 50 secuencias agrupadas\n")
cat("  • Por similitud de secuencia\n")
cat("  • Anotadas por nivel de oxidación\n\n")

cat("✅ ANÁLISIS COMPLETADO\n")
cat("  • Figuras generadas: 2-3\n")
cat("  • Tablas guardadas: 5\n")
cat("  • Ubicación:", output_paso9d, "\n\n")

cat("════════════════════════════════════════════════════════════════════════\n")









