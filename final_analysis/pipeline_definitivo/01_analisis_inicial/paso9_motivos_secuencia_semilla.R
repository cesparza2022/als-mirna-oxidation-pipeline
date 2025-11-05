#!/usr/bin/env Rscript
# ==============================================================================
# PASO 9: ANÁLISIS DE MOTIVOS DE SECUENCIA EN REGIÓN SEMILLA
# ==============================================================================
# 
# OBJETIVO:
#   Analizar contexto de secuencia alrededor de G>T en región semilla:
#   1. Extraer secuencias de miRNAs con G>T en cada posición
#   2. Buscar motivos conservados (contexto -2/+2 bases)
#   3. Identificar familias de miRNAs afectados
#   4. Analizar si ciertas secuencias son más susceptibles a G>T
#   5. Enfoque especial en posición 3 (significativa)
#
# INPUT:
#   - Datos del Paso 8 (397 G>T en semilla)
#   - Secuencias de miRNAs (de miRBase o dataset)
#
# OUTPUT:
#   - Motivos de secuencia por posición
#   - Logos de secuencia
#   - Familias de miRNAs afectados
#   - Análisis de susceptibilidad
#
# NOTA: Necesitamos las secuencias completas de miRNAs
#
# AUTOR: Análisis ALS miRNAs
# FECHA: 8 de octubre de 2025
# ==============================================================================

library(tidyverse)
library(jsonlite)

# Cargar Biostrings al final para evitar conflictos con dplyr::first
# (Solo si necesitamos secuencias)

cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║         PASO 9: MOTIVOS DE SECUENCIA EN REGIÓN SEMILLA                ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

# Cargar configuración
source("config_pipeline.R")
source("functions_pipeline.R")

# Directorios
output_paso9 <- file.path(config$output_paths$outputs, "paso9_motivos_secuencia")
output_figures <- file.path(config$output_paths$figures, "paso9_motivos_secuencia")
dir.create(output_paso9, recursive = TRUE, showWarnings = FALSE)
dir.create(output_figures, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# CARGAR DATOS
# ------------------------------------------------------------------------------

cat("📂 PASO 9.1: Cargando datos...\n")

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
    mutation_type = paste0(from_base, ">", to_base),
    region = case_when(
      position >= 1 & position <= 7 ~ "Seed",
      position >= 8 & position <= 12 ~ "Central",
      position >= 13 ~ "3prime",
      TRUE ~ "Unknown"
    )
  )

# Filtrar G>T en semilla
gt_seed <- datos %>%
  filter(mutation_type == "G>T", region == "Seed")

cat("  ✓ G>T en semilla:", nrow(gt_seed), "\n\n")

# ------------------------------------------------------------------------------
# PASO 9.2: INTENTAR CARGAR SECUENCIAS DE miRNAs
# ------------------------------------------------------------------------------

cat("🧬 PASO 9.2: Buscando archivo de secuencias...\n")

# Buscar archivo de secuencias (puede estar en varios lugares)
possible_seq_files <- c(
  "../../data/mirna_sequences.txt",
  "../../processed_data/mirna_sequences.fa",
  "../../results/Magen_ALS-bloodplasma/mirna_info.txt",
  "/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/mirna_sequences.txt"
)

seq_file <- NULL
for (file in possible_seq_files) {
  if (file.exists(file)) {
    seq_file <- file
    break
  }
}

if (is.null(seq_file)) {
  cat("  ⚠️ No se encontró archivo de secuencias\n")
  cat("  → Vamos a analizar familias y contexto sin secuencias completas\n\n")
  
  # Análisis sin secuencias (basado en nombres de miRNAs)
  use_sequences <- FALSE
  
} else {
  cat("  ✓ Archivo de secuencias encontrado:", seq_file, "\n\n")
  use_sequences <- TRUE
}

# ------------------------------------------------------------------------------
# PASO 9.3: ANÁLISIS DE FAMILIAS DE miRNAs
# ------------------------------------------------------------------------------

cat("👨‍👩‍👧‍👦 PASO 9.3: Analizando familias de miRNAs afectados...\n")

# Extraer familia de miRNA (hsa-miR-XXX -> miR-XXX family)
gt_seed <- gt_seed %>%
  mutate(
    mirna_family = str_extract(`miRNA name`, "miR-\\d+[a-z]*"),
    mirna_base = str_extract(mirna_family, "miR-\\d+")  # Sin letra (familia base)
  )

# Contar por familia y posición
familias_por_posicion <- gt_seed %>%
  group_by(position, mirna_base) %>%
  summarise(
    n_mutations = n(),
    mirnas = paste(unique(`miRNA name`), collapse = ", "),
    .groups = "drop"
  ) %>%
  arrange(position, desc(n_mutations))

cat("\n  📊 Familias más afectadas por posición:\n")

# Por cada posición en semilla
for (pos in 1:7) {
  cat("\n  Posición", pos, ":\n")
  
  familias_pos <- familias_por_posicion %>%
    filter(position == pos) %>%
    head(5)
  
  if (nrow(familias_pos) > 0) {
    print(familias_pos %>% select(mirna_base, n_mutations))
  } else {
    cat("    Sin datos\n")
  }
}

# Guardar
write_csv(familias_por_posicion, 
          file.path(output_paso9, "paso9_familias_por_posicion.csv"))

# Gráfica de familias más afectadas
top_familias <- gt_seed %>%
  group_by(mirna_base, position) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(mirna_base) %>%
  summarise(
    total = sum(n),
    posiciones = paste(position, collapse = ","),
    .groups = "drop"
  ) %>%
  arrange(desc(total)) %>%
  head(20)

p1 <- ggplot(top_familias, aes(x = reorder(mirna_base, total), y = total)) +
  geom_col(fill = "steelblue", alpha = 0.8) +
  geom_text(aes(label = total), hjust = -0.2, size = 3) +
  coord_flip() +
  labs(
    title = "Top 20 Familias de miRNAs con G>T en Región Semilla",
    subtitle = "Suma de todas las posiciones (1-7)",
    x = "Familia de miRNA",
    y = "Número de G>T en Semilla"
  ) +
  theme_minimal()

ggsave(file.path(output_figures, "paso9_top_familias.png"),
       p1, width = 10, height = 8)
cat("\n  ✓ Figura 'paso9_top_familias.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 9.4: ANÁLISIS DE CONTEXTO DE MUTACIÓN (base mutada)
# ------------------------------------------------------------------------------

cat("🔬 PASO 9.4: Analizando contexto de la mutación...\n")

# Contexto: qué base está ANTES y DESPUÉS de la G mutada
# Esto requiere secuencia completa, pero podemos inferir parcialmente

# Por ahora, analicemos la base que muta (from_base siempre es G)
# y la base resultante (to_base siempre es T)

# Análisis de familias por posición específica
posicion3_analisis <- gt_seed %>%
  filter(position == 3) %>%
  mutate(
    familia_tipo = case_when(
      str_detect(mirna_family, "let-7") ~ "let-7",
      str_detect(mirna_family, "miR-1") ~ "miR-1xx",
      str_detect(mirna_family, "miR-2") ~ "miR-2xx",
      str_detect(mirna_family, "miR-3") ~ "miR-3xx",
      TRUE ~ "Otras"
    )
  ) %>%
  group_by(familia_tipo) %>%
  summarise(
    n = n(),
    mirnas_unicos = n_distinct(`miRNA name`),
    .groups = "drop"
  ) %>%
  arrange(desc(n))

cat("\n  📊 POSICIÓN 3 (significativa) - Distribución por familia:\n")
print(posicion3_analisis)

# Gráfica posición 3
p2 <- ggplot(posicion3_analisis, aes(x = reorder(familia_tipo, n), y = n)) +
  geom_col(fill = "#E31A1C", alpha = 0.8) +
  geom_text(aes(label = paste0(n, "\n(", mirnas_unicos, " miRNAs)")), 
            hjust = -0.2, size = 3.5) +
  coord_flip() +
  labs(
    title = "Distribución de Familias en Posición 3",
    subtitle = "Posición significativa (p = 0.027)",
    x = "Tipo de Familia",
    y = "Número de G>T"
  ) +
  theme_minimal()

ggsave(file.path(output_figures, "paso9_posicion3_familias.png"),
       p2, width = 10, height = 6)
cat("  ✓ Figura 'paso9_posicion3_familias.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 9.5: ANÁLISIS DE CO-MUTACIONES (mismas familias, múltiples posiciones)
# ------------------------------------------------------------------------------

cat("🔗 PASO 9.5: Analizando co-mutaciones en familias...\n")

# miRNAs con múltiples G>T en semilla
multi_gt <- gt_seed %>%
  group_by(`miRNA name`) %>%
  summarise(
    n_gt_seed = n(),
    posiciones = paste(sort(position), collapse = ","),
    familia = first(mirna_base),
    .groups = "drop"
  ) %>%
  filter(n_gt_seed > 1) %>%
  arrange(desc(n_gt_seed))

cat("  📊 miRNAs con múltiples G>T en semilla:", nrow(multi_gt), "\n")
cat("  📊 Top miRNA:", multi_gt$`miRNA name`[1], 
    "(", multi_gt$n_gt_seed[1], "mutaciones)\n\n")

# Patrones de posiciones
position_patterns <- multi_gt %>%
  group_by(posiciones) %>%
  summarise(
    n_mirnas = n(),
    ejemplos = paste(head(`miRNA name`, 3), collapse = ", "),
    .groups = "drop"
  ) %>%
  arrange(desc(n_mirnas))

cat("  📍 Patrones de posiciones más comunes:\n")
print(head(position_patterns, 10))

write_csv(multi_gt, file.path(output_paso9, "paso9_mirnas_multi_gt.csv"))
write_csv(position_patterns, file.path(output_paso9, "paso9_patrones_posiciones.csv"))

# Gráfica de patrones
top_patterns <- position_patterns %>% head(10)

p3 <- ggplot(top_patterns, aes(x = reorder(posiciones, n_mirnas), y = n_mirnas)) +
  geom_col(fill = "#FF7F00", alpha = 0.8) +
  geom_text(aes(label = n_mirnas), hjust = -0.2, size = 3.5) +
  coord_flip() +
  labs(
    title = "Patrones de Co-mutaciones en Región Semilla",
    subtitle = "Combinaciones de posiciones afectadas en mismo miRNA",
    x = "Patrón de Posiciones",
    y = "Número de miRNAs"
  ) +
  theme_minimal()

ggsave(file.path(output_figures, "paso9_patrones_comutacion.png"),
       p3, width = 10, height = 8)
cat("  ✓ Figura 'paso9_patrones_comutacion.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 9.6: ANÁLISIS ESPECÍFICO POSICIÓN 3
# ------------------------------------------------------------------------------

cat("🎯 PASO 9.6: Análisis detallado de posición 3...\n")

pos3_data <- gt_seed %>%
  filter(position == 3) %>%
  mutate(
    familia_detallada = case_when(
      str_detect(mirna_family, "let-7") ~ mirna_family,
      TRUE ~ mirna_base
    )
  )

# Resumen por familia detallada
pos3_familias <- pos3_data %>%
  group_by(familia_detallada) %>%
  summarise(
    n = n(),
    mirnas = paste(unique(`miRNA name`), collapse = ", "),
    .groups = "drop"
  ) %>%
  arrange(desc(n))

cat("\n  📊 POSICIÓN 3 - Familias afectadas:\n")
print(pos3_familias)

write_csv(pos3_familias, file.path(output_paso9, "paso9_posicion3_familias_detallado.csv"))

# Lista de miRNAs en posición 3
pos3_mirnas <- pos3_data %>%
  select(`miRNA name`, mirna_family, mirna_base) %>%
  arrange(`miRNA name`)

write_csv(pos3_mirnas, file.path(output_paso9, "paso9_posicion3_mirnas_lista.csv"))

cat("  ✓ Lista de", nrow(pos3_mirnas), "miRNAs en posición 3 guardada\n\n")

# ------------------------------------------------------------------------------
# PASO 9.7: ANÁLISIS DE DISTRIBUCIÓN DE BASES EN CADA POSICIÓN
# ------------------------------------------------------------------------------

cat("🧬 PASO 9.7: Analizando distribución de bases mutadas...\n")

# Ya sabemos que from_base = G y to_base = T
# Pero podemos ver si hay enriquecimiento de familias específicas

# Distribución de familias base por posición
familias_dist <- gt_seed %>%
  group_by(position, mirna_base) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(position) %>%
  mutate(
    total_pos = sum(n),
    perc = round(n / total_pos * 100, 1)
  ) %>%
  ungroup()

# Top 5 familias por posición
top_by_position <- familias_dist %>%
  group_by(position) %>%
  slice_max(n, n = 5) %>%
  ungroup()

cat("\n  📊 Top familias por posición:\n")
for (pos in 1:7) {
  cat("\n  Posición", pos, ":\n")
  top_pos <- top_by_position %>% filter(position == pos)
  print(top_pos %>% select(mirna_base, n, perc))
}

# Heatmap de familias × posición
familia_pos_matrix <- familias_dist %>%
  filter(!is.na(mirna_base)) %>%  # Eliminar NAs
  select(position, mirna_base, n) %>%
  pivot_wider(names_from = position, values_from = n, values_fill = 0) %>%
  column_to_rownames("mirna_base") %>%
  as.matrix()

# Filtrar familias con al menos 3 mutaciones totales
familia_pos_matrix <- familia_pos_matrix[rowSums(familia_pos_matrix) >= 3, ]

if (nrow(familia_pos_matrix) > 0) {
  
  cat("\n  → Generando heatmap familias × posición...\n")
  
  library(pheatmap)
  
  png(file.path(output_figures, "paso9_heatmap_familias_posicion.png"),
      width = 10, height = 12, units = "in", res = 150)
  
  pheatmap(
    familia_pos_matrix,
    color = colorRampPalette(c("white", "yellow", "orange", "red"))(100),
    cluster_rows = TRUE,
    cluster_cols = FALSE,
    display_numbers = TRUE,
    main = "Heatmap: Familias de miRNAs × Posición en Semilla",
    fontsize = 10,
    fontsize_number = 7
  )
  
  dev.off()
  cat("  ✓ Figura 'paso9_heatmap_familias_posicion.png' generada\n\n")
}

# ------------------------------------------------------------------------------
# PASO 9.8: IDENTIFICAR FAMILIAS CON ALTA SUSCEPTIBILIDAD
# ------------------------------------------------------------------------------

cat("🎯 PASO 9.8: Identificando familias de alta susceptibilidad...\n")

# Familias con más de 5 G>T en semilla
high_susceptibility <- gt_seed %>%
  group_by(mirna_base) %>%
  summarise(
    n_gt_total = n(),
    n_mirnas = n_distinct(`miRNA name`),
    posiciones_afectadas = paste(sort(unique(position)), collapse = ","),
    n_posiciones = n_distinct(position),
    tiene_pos3 = 3 %in% position,
    tiene_pos6 = 6 %in% position,
    .groups = "drop"
  ) %>%
  filter(n_gt_total >= 5) %>%
  arrange(desc(n_gt_total))

cat("\n  🏆 Familias de alta susceptibilidad (≥5 G>T en semilla):\n")
print(high_susceptibility)

write_csv(high_susceptibility, 
          file.path(output_paso9, "paso9_familias_alta_susceptibilidad.csv"))

# Gráfica
if (nrow(high_susceptibility) > 0) {
  
  p4 <- ggplot(high_susceptibility, aes(x = reorder(mirna_base, n_gt_total), y = n_gt_total)) +
    geom_col(aes(fill = tiene_pos3), alpha = 0.8) +
    scale_fill_manual(
      values = c("FALSE" = "steelblue", "TRUE" = "#E31A1C"),
      labels = c("Sin pos. 3", "Con pos. 3"),
      name = "Posición 3"
    ) +
    geom_text(aes(label = n_gt_total), hjust = -0.2, size = 3) +
    coord_flip() +
    labs(
      title = "Familias de miRNAs de Alta Susceptibilidad",
      subtitle = "Familias con ≥5 G>T en región semilla (coloreadas por pos. 3)",
      x = "Familia de miRNA",
      y = "Total G>T en Semilla"
    ) +
    theme_minimal()
  
  ggsave(file.path(output_figures, "paso9_familias_susceptibilidad.png"),
         p4, width = 10, height = 8)
  cat("  ✓ Figura 'paso9_familias_susceptibilidad.png' generada\n\n")
}

# ------------------------------------------------------------------------------
# PASO 9.9: RESUMEN EJECUTIVO
# ------------------------------------------------------------------------------

cat("📋 PASO 9.9: Generando resumen ejecutivo...\n")

resumen <- list(
  total_gt_semilla = nrow(gt_seed),
  n_mirnas = n_distinct(gt_seed$`miRNA name`),
  n_familias = n_distinct(gt_seed$mirna_base),
  n_familias_alta_susc = nrow(high_susceptibility),
  top_familia = high_susceptibility$mirna_base[1],
  top_familia_n = high_susceptibility$n_gt_total[1],
  n_multi_gt = nrow(multi_gt),
  patron_mas_comun = position_patterns$posiciones[1],
  patron_mas_comun_n = position_patterns$n_mirnas[1],
  pos3_n_mirnas = nrow(pos3_mirnas),
  pos3_n_familias = n_distinct(pos3_data$mirna_base)
)

write_json(resumen, file.path(output_paso9, "paso9_resumen.json"), pretty = TRUE)

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║                    RESUMEN EJECUTIVO - PASO 9                         ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

cat("👨‍👩‍👧‍👦 FAMILIAS DE miRNAs:\n")
cat("  • Total G>T en semilla:", resumen$total_gt_semilla, "\n")
cat("  • miRNAs únicos:", resumen$n_mirnas, "\n")
cat("  • Familias afectadas:", resumen$n_familias, "\n")
cat("  • Familias alta susceptibilidad:", resumen$n_familias_alta_susc, "\n\n")

cat("🏆 TOP FAMILIA:\n")
cat("  •", resumen$top_familia, "con", resumen$top_familia_n, "mutaciones\n\n")

cat("🔗 CO-MUTACIONES:\n")
cat("  • miRNAs con múltiples G>T:", resumen$n_multi_gt, "\n")
cat("  • Patrón más común:", resumen$patron_mas_comun, 
    "(", resumen$patron_mas_comun_n, "miRNAs)\n\n")

cat("🎯 POSICIÓN 3 (significativa):\n")
cat("  • miRNAs afectados:", resumen$pos3_n_mirnas, "\n")
cat("  • Familias afectadas:", resumen$pos3_n_familias, "\n\n")

cat("✅ ANÁLISIS COMPLETADO\n")
cat("  • Figuras generadas: 4-5\n")
cat("  • Tablas guardadas: 6\n")
cat("  • Ubicación:", output_paso9, "\n\n")

cat("════════════════════════════════════════════════════════════════════════\n")

# ------------------------------------------------------------------------------
# NOTA FINAL
# ------------------------------------------------------------------------------

cat("\n⚠️ NOTA IMPORTANTE:\n")
cat("  Para análisis de MOTIVOS DE SECUENCIA completo (contexto -2/+2),\n")
cat("  necesitamos archivo de secuencias de miRNAs.\n\n")
cat("  Opciones:\n")
cat("  1. Descargar de miRBase (hsa.mature.fa)\n")
cat("  2. Usar API de miRBase\n")
cat("  3. Extraer del dataset original si está disponible\n\n")
cat("  Con secuencias podríamos:\n")
cat("  - Generar sequence logos por posición\n")
cat("  - Identificar motivos conservados (ej. GGG, GGA)\n")
cat("  - Analizar contexto dinucleótido\n")
cat("  - Predecir susceptibilidad a oxidación\n\n")

