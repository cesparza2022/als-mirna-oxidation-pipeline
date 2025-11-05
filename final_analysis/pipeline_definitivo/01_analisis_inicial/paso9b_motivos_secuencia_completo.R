#!/usr/bin/env Rscript
# ==============================================================================
# PASO 9B: ANÁLISIS COMPLETO DE MOTIVOS DE SECUENCIA
# ==============================================================================
# 
# OBJETIVO:
#   Con las secuencias de miRNAs, analizar motivos conservados:
#   1. Extraer contexto ±2 bases alrededor de cada G>T
#   2. Generar sequence logos por posición
#   3. Identificar motivos conservados (ej. GGG, GGA)
#   4. Analizar contexto dinucleótido
#   5. Comparar posición 3 vs otras
#
# INPUT:
#   - Secuencias de miRNAs (hsa_filt_mature_2022.fa)
#   - G>T en semilla del Paso 8
#
# OUTPUT:
#   - Sequence logos por posición
#   - Motivos conservados identificados
#   - Análisis de contexto
#
# AUTOR: Análisis ALS miRNAs
# FECHA: 8 de octubre de 2025
# ==============================================================================

library(tidyverse)
library(jsonlite)
library(ggseqlogo)

cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║      PASO 9B: ANÁLISIS COMPLETO DE MOTIVOS DE SECUENCIA               ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

# Cargar configuración
source("config_pipeline.R")
source("functions_pipeline.R")

# Directorios
output_paso9b <- file.path(config$output_paths$outputs, "paso9b_motivos_completo")
output_figures <- file.path(config$output_paths$figures, "paso9b_motivos_completo")
dir.create(output_paso9b, recursive = TRUE, showWarnings = FALSE)
dir.create(output_figures, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# CARGAR DATOS
# ------------------------------------------------------------------------------

cat("📂 PASO 9B.1: Cargando datos...\n")

# Datos de G>T
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

gt_seed <- datos %>%
  filter(mutation_type == "G>T", position >= 1, position <= 7)

cat("  ✓ G>T en semilla:", nrow(gt_seed), "\n")

# Cargar secuencias de miRNAs
seq_file <- "data/hsa_filt_mature_2022.fa"

if (!file.exists(seq_file)) {
  stop("❌ Archivo de secuencias no encontrado: ", seq_file)
}

cat("  ✓ Leyendo secuencias de:", seq_file, "\n")

# Leer FASTA
fasta_lines <- readLines(seq_file)
headers <- grep("^>", fasta_lines)

sequences <- tibble(
  header = fasta_lines[headers],
  sequence = fasta_lines[headers + 1]
) %>%
  mutate(
    mirna_name = str_extract(header, "hsa-[^ ]+")
  )

cat("  ✓ Secuencias cargadas:", nrow(sequences), "\n\n")

# ------------------------------------------------------------------------------
# PASO 9B.2: MAPEAR G>T A SECUENCIAS
# ------------------------------------------------------------------------------

cat("🧬 PASO 9B.2: Mapeando G>T a secuencias...\n")

# Join con secuencias
gt_seed_seq <- gt_seed %>%
  left_join(sequences, by = c("miRNA name" = "mirna_name"))

# Filtrar solo los que tienen secuencia
gt_seed_seq <- gt_seed_seq %>%
  filter(!is.na(sequence))

cat("  ✓ G>T con secuencia mapeada:", nrow(gt_seed_seq), "de", nrow(gt_seed), "\n")
cat("  ⚠️ Sin secuencia:", nrow(gt_seed) - nrow(gt_seed_seq), "\n\n")

# ------------------------------------------------------------------------------
# PASO 9B.3: EXTRAER CONTEXTO ±2 BASES
# ------------------------------------------------------------------------------

cat("📍 PASO 9B.3: Extrayendo contexto ±2 bases...\n")

# Función para extraer contexto
extract_context <- function(sequence, position, window = 2) {
  seq_length <- nchar(sequence)
  
  # Validar posición
  if (position < 1 || position > seq_length) {
    return(NA)
  }
  
  # Calcular ventana
  start_pos <- max(1, position - window)
  end_pos <- min(seq_length, position + window)
  
  # Extraer
  context <- substr(sequence, start_pos, end_pos)
  
  # Identificar posición de G dentro del contexto
  g_position_in_context <- position - start_pos + 1
  
  return(list(
    context = context,
    g_pos = g_position_in_context,
    upstream = substr(sequence, start_pos, position - 1),
    g_base = substr(sequence, position, position),
    downstream = substr(sequence, position + 1, end_pos)
  ))
}

# Aplicar extracción
gt_seed_context <- gt_seed_seq %>%
  rowwise() %>%
  mutate(
    context_data = list(extract_context(sequence, position, window = 2))
  ) %>%
  ungroup() %>%
  mutate(
    context_5mer = map_chr(context_data, ~.x$context %||% NA_character_),
    upstream_2 = map_chr(context_data, ~.x$upstream %||% NA_character_),
    g_base = map_chr(context_data, ~.x$g_base %||% NA_character_),
    downstream_2 = map_chr(context_data, ~.x$downstream %||% NA_character_)
  ) %>%
  select(-context_data)

cat("  ✓ Contexto extraído\n")

# Verificar que la base es G
verificacion <- gt_seed_context %>%
  filter(!is.na(g_base)) %>%
  summarise(
    total = n(),
    correctas = sum(g_base == "G"),
    incorrectas = sum(g_base != "G")
  )

cat("  → Verificación: ", verificacion$correctas, "correctas,", 
    verificacion$incorrectas, "incorrectas\n\n")

# Guardar
write_csv(gt_seed_context %>% select(`miRNA name`, position, `pos:mut`, 
                                     sequence, context_5mer, upstream_2, 
                                     g_base, downstream_2),
          file.path(output_paso9b, "paso9b_contextos_secuencia.csv"))

# ------------------------------------------------------------------------------
# PASO 9B.4: ANÁLISIS DE MOTIVOS POR POSICIÓN
# ------------------------------------------------------------------------------

cat("🔍 PASO 9B.4: Analizando motivos por posición...\n")

# Análisis de contexto por posición
motivos_por_posicion <- gt_seed_context %>%
  filter(!is.na(context_5mer)) %>%
  group_by(position) %>%
  summarise(
    n = n(),
    contextos_unicos = n_distinct(context_5mer),
    motivo_mas_comun = names(sort(table(context_5mer), decreasing = TRUE))[1],
    frecuencia_top = max(table(context_5mer)),
    .groups = "drop"
  )

cat("\n  📊 MOTIVOS POR POSICIÓN:\n")
print(motivos_por_posicion)

write_csv(motivos_por_posicion, file.path(output_paso9b, "paso9b_motivos_por_posicion.csv"))

# ------------------------------------------------------------------------------
# PASO 9B.5: ANÁLISIS DE DINUCLEÓTIDOS (±1 base)
# ------------------------------------------------------------------------------

cat("\n🧬 PASO 9B.5: Analizando dinucleótidos...\n")

# Extraer base -1 y +1
dinucleotidos <- gt_seed_context %>%
  filter(!is.na(upstream_2), !is.na(downstream_2)) %>%
  mutate(
    base_minus1 = str_sub(upstream_2, -1, -1),
    base_plus1 = str_sub(downstream_2, 1, 1),
    trinucleotido = paste0(base_minus1, "G", base_plus1)
  )

# Frecuencias de trinucleótidos
trinuc_freq <- dinucleotidos %>%
  group_by(trinucleotido) %>%
  summarise(n = n(), .groups = "drop") %>%
  arrange(desc(n)) %>%
  mutate(perc = round(n / sum(n) * 100, 1))

cat("\n  📊 TOP 10 TRINUCLEÓTIDOS (XGY donde G muta a T):\n")
print(head(trinuc_freq, 10))

write_csv(trinuc_freq, file.path(output_paso9b, "paso9b_trinucleotidos.csv"))

# Gráfica
p1 <- ggplot(head(trinuc_freq, 15), aes(x = reorder(trinucleotido, n), y = n)) +
  geom_col(fill = "steelblue", alpha = 0.8) +
  geom_text(aes(label = paste0(n, " (", perc, "%)")), hjust = -0.1, size = 3) +
  coord_flip() +
  labs(
    title = "Top 15 Trinucleótidos en G>T de Región Semilla",
    subtitle = "Contexto XGY donde G muta a T",
    x = "Trinucleótido",
    y = "Frecuencia"
  ) +
  theme_minimal()

ggsave(file.path(output_figures, "paso9b_trinucleotidos.png"),
       p1, width = 10, height = 8)
cat("  ✓ Figura 'paso9b_trinucleotidos.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 9B.6: SEQUENCE LOGOS POR POSICIÓN
# ------------------------------------------------------------------------------

cat("🎨 PASO 9B.6: Generando sequence logos...\n")

# Sequence logo para cada posición (solo si hay suficientes)
for (pos in c(3, 6, 7)) {  # Posiciones clave
  
  cat("\n  → Posición", pos, ":\n")
  
  # Filtrar contextos de esta posición
  contextos_pos <- gt_seed_context %>%
    filter(position == pos, !is.na(context_5mer)) %>%
    pull(context_5mer)
  
  if (length(contextos_pos) >= 5) {
    
    cat("    - Contextos:", length(contextos_pos), "\n")
    
    # Asegurar que todos tienen mismo largo
    lens <- nchar(contextos_pos)
    if (length(unique(lens)) == 1) {
      
      # Crear logo
      p_logo <- ggseqlogo(contextos_pos, method = 'prob') +
        labs(title = paste0("Sequence Logo Posición ", pos, " (G>T en Semilla)"),
             subtitle = paste0("N = ", length(contextos_pos), " secuencias")) +
        theme_minimal()
      
      ggsave(file.path(output_figures, paste0("paso9b_logo_posicion", pos, ".png")),
             p_logo, width = 8, height = 4)
      
      cat("    ✓ Logo generado\n")
      
    } else {
      cat("    ⚠️ Contextos de diferente largo, ajustando...\n")
      
      # Ajustar al largo más común
      most_common_len <- names(sort(table(lens), decreasing = TRUE))[1]
      contextos_pos_fixed <- contextos_pos[lens == as.integer(most_common_len)]
      
      if (length(contextos_pos_fixed) >= 5) {
        p_logo <- ggseqlogo(contextos_pos_fixed, method = 'prob') +
          labs(title = paste0("Sequence Logo Posición ", pos, " (G>T en Semilla)"),
               subtitle = paste0("N = ", length(contextos_pos_fixed), " secuencias")) +
          theme_minimal()
        
        ggsave(file.path(output_figures, paste0("paso9b_logo_posicion", pos, ".png")),
               p_logo, width = 8, height = 4)
        
        cat("    ✓ Logo generado (ajustado)\n")
      }
    }
  } else {
    cat("    ⚠️ Muy pocas secuencias (", length(contextos_pos), ")\n")
  }
}

cat("\n")

# ------------------------------------------------------------------------------
# PASO 9B.7: ANÁLISIS DE CONSERVACIÓN
# ------------------------------------------------------------------------------

cat("📊 PASO 9B.7: Analizando conservación de bases...\n")

# Por cada posición, analizar frecuencia de bases en ±1
conservacion <- dinucleotidos %>%
  group_by(position) %>%
  summarise(
    n = n(),
    # Base -1
    freq_A_minus1 = sum(base_minus1 == "A") / n(),
    freq_C_minus1 = sum(base_minus1 == "C") / n(),
    freq_G_minus1 = sum(base_minus1 == "G") / n(),
    freq_T_minus1 = sum(base_minus1 == "T") / n(),
    # Base +1
    freq_A_plus1 = sum(base_plus1 == "A") / n(),
    freq_C_plus1 = sum(base_plus1 == "C") / n(),
    freq_G_plus1 = sum(base_plus1 == "G") / n(),
    freq_T_plus1 = sum(base_plus1 == "T") / n(),
    .groups = "drop"
  )

cat("\n  📈 CONSERVACIÓN DE BASES:\n")
print(conservacion)

write_csv(conservacion, file.path(output_paso9b, "paso9b_conservacion_bases.csv"))

# Gráfica de conservación (posición -1)
conservacion_long <- conservacion %>%
  select(position, n, starts_with("freq_")) %>%
  pivot_longer(cols = starts_with("freq_"), 
               names_to = "base_position", 
               values_to = "freq") %>%
  mutate(
    base = str_extract(base_position, "[ACGT]"),
    pos_rel = ifelse(str_detect(base_position, "minus"), "-1", "+1")
  )

p2 <- ggplot(conservacion_long, aes(x = factor(position), y = freq, fill = base)) +
  geom_col(position = "dodge", alpha = 0.8) +
  facet_wrap(~pos_rel, ncol = 2) +
  scale_fill_manual(
    values = c("A" = "#1F78B4", "C" = "#33A02C", "G" = "#E31A1C", "T" = "#FF7F00"),
    name = "Base"
  ) +
  labs(
    title = "Conservación de Bases Adyacentes a G>T",
    subtitle = "Frecuencia de bases en posición -1 y +1",
    x = "Posición de G en miRNA",
    y = "Frecuencia"
  ) +
  theme_minimal()

ggsave(file.path(output_figures, "paso9b_conservacion_adyacente.png"),
       p2, width = 12, height = 6)
cat("  ✓ Figura 'paso9b_conservacion_adyacente.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 9B.8: ANÁLISIS ESPECÍFICO POSICIÓN 3
# ------------------------------------------------------------------------------

cat("🎯 PASO 9B.8: Análisis detallado posición 3...\n")

pos3_context <- dinucleotidos %>%
  filter(position == 3)

cat("  ✓ Contextos en posición 3:", nrow(pos3_context), "\n")

# Trinucleótidos en posición 3
trinuc_pos3 <- pos3_context %>%
  group_by(trinucleotido) %>%
  summarise(n = n(), .groups = "drop") %>%
  arrange(desc(n)) %>%
  mutate(perc = round(n / sum(n) * 100, 1))

cat("\n  📊 TRINUCLEÓTIDOS EN POSICIÓN 3:\n")
print(trinuc_pos3)

write_csv(pos3_context %>% select(`miRNA name`, position, trinucleotido, 
                                   context_5mer, sequence),
          file.path(output_paso9b, "paso9b_posicion3_contextos.csv"))

# ------------------------------------------------------------------------------
# PASO 9B.9: COMPARAR POSICIÓN 3 vs OTRAS
# ------------------------------------------------------------------------------

cat("\n🔬 PASO 9B.9: Comparando posición 3 vs otras...\n")

# Agrupar posiciones
dinucleotidos_grouped <- dinucleotidos %>%
  mutate(
    pos_group = ifelse(position == 3, "Posición 3\n(significativa)", "Otras\nposiciones")
  )

# Frecuencias por grupo
trinuc_comparison <- dinucleotidos_grouped %>%
  group_by(pos_group, trinucleotido) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(pos_group) %>%
  mutate(perc = round(n / sum(n) * 100, 1)) %>%
  ungroup() %>%
  arrange(pos_group, desc(n))

# Top 10 por grupo
trinuc_pos3_top <- trinuc_comparison %>%
  filter(pos_group == "Posición 3\n(significativa)") %>%
  head(10)

trinuc_otras_top <- trinuc_comparison %>%
  filter(pos_group == "Otras\nposiciones") %>%
  head(10)

# Gráfica comparativa
p3 <- ggplot(trinuc_comparison %>% group_by(pos_group) %>% slice_max(n, n = 10),
             aes(x = reorder(trinucleotido, n), y = n)) +
  geom_col(aes(fill = pos_group), alpha = 0.8, show.legend = FALSE) +
  geom_text(aes(label = paste0(n, "\n", perc, "%")), hjust = -0.1, size = 2.5) +
  facet_wrap(~pos_group, scales = "free_y", ncol = 2) +
  coord_flip() +
  scale_fill_manual(values = c("#E31A1C", "#1F78B4")) +
  labs(
    title = "Comparación de Trinucleótidos: Posición 3 vs Otras",
    subtitle = "Top 10 motivos más frecuentes en cada grupo",
    x = "Trinucleótido",
    y = "Frecuencia"
  ) +
  theme_minimal()

ggsave(file.path(output_figures, "paso9b_comparacion_pos3_otras.png"),
       p3, width = 12, height = 8)
cat("  ✓ Figura 'paso9b_comparacion_pos3_otras.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 9B.10: RESUMEN EJECUTIVO
# ------------------------------------------------------------------------------

cat("📋 PASO 9B.10: Generando resumen ejecutivo...\n")

resumen <- list(
  total_gt_mapeados = nrow(gt_seed_seq),
  total_gt_semilla = nrow(gt_seed),
  perc_mapeado = round(nrow(gt_seed_seq) / nrow(gt_seed) * 100, 1),
  n_trinucleotidos_unicos = nrow(trinuc_freq),
  trinuc_mas_comun = trinuc_freq$trinucleotido[1],
  trinuc_mas_comun_n = trinuc_freq$n[1],
  trinuc_mas_comun_perc = trinuc_freq$perc[1],
  pos3_contextos = nrow(pos3_context),
  pos3_trinuc_top = trinuc_pos3$trinucleotido[1],
  pos3_trinuc_top_n = trinuc_pos3$n[1]
)

write_json(resumen, file.path(output_paso9b, "paso9b_resumen.json"), pretty = TRUE)

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║                  RESUMEN EJECUTIVO - PASO 9B                          ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

cat("🧬 MAPEO DE SECUENCIAS:\n")
cat("  • G>T mapeados:", resumen$total_gt_mapeados, "de", resumen$total_gt_semilla, 
    sprintf("(%.1f%%)", resumen$perc_mapeado), "\n\n")

cat("🔍 TRINUCLEÓTIDOS:\n")
cat("  • Motivos únicos:", resumen$n_trinucleotidos_unicos, "\n")
cat("  • Más común:", resumen$trinuc_mas_comun, "-", resumen$trinuc_mas_comun_n, 
    sprintf("(%.1f%%)", resumen$trinuc_mas_comun_perc), "\n\n")

cat("🎯 POSICIÓN 3:\n")
cat("  • Contextos analizados:", resumen$pos3_contextos, "\n")
cat("  • Trinucleótido top:", resumen$pos3_trinuc_top, "-", resumen$pos3_trinuc_top_n, "\n\n")

cat("✅ ANÁLISIS COMPLETADO\n")
cat("  • Figuras generadas: 6-9\n")
cat("  • Tablas guardadas: 5\n")
cat("  • Sequence logos: 3 posiciones\n")
cat("  • Ubicación:", output_paso9b, "\n\n")

cat("════════════════════════════════════════════════════════════════════════\n")









