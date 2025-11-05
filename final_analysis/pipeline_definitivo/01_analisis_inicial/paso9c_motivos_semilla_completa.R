#!/usr/bin/env Rscript
# ==============================================================================
# PASO 9C: ANÁLISIS DE MOTIVOS DE SECUENCIA SEMILLA COMPLETA
# ==============================================================================
# 
# OBJETIVO:
#   Analizar secuencias COMPLETAS de región semilla (7 bases) y agruparlas:
#   1. Extraer región semilla completa (pos 1-7) de cada miRNA
#   2. Agrupar por similitud de secuencia
#   3. Calcular nivel de oxidación por grupo (% con G>T)
#   4. Identificar secuencias más susceptibles
#   5. Generar sequence logos por grupo
#
# INPUT:
#   - Secuencias de miRNAs (hsa_filt_mature_2022.fa)
#   - Todos los miRNAs (no solo con G>T)
#
# OUTPUT:
#   - Grupos de secuencias similares
#   - Nivel de oxidación por grupo
#   - Sequence logos por grupo
#   - Heatmap de oxidación
#
# AUTOR: Análisis ALS miRNAs
# FECHA: 8 de octubre de 2025
# ==============================================================================

library(tidyverse)
library(ggseqlogo)
library(pheatmap)
library(jsonlite)

cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║    PASO 9C: MOTIVOS DE SEMILLA COMPLETA Y SUSCEPTIBILIDAD A OXIDACIÓN ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

# Cargar configuración
source("config_pipeline.R")
source("functions_pipeline.R")

# Directorios
output_paso9c <- file.path(config$output_paths$outputs, "paso9c_semilla_completa")
output_figures <- file.path(config$output_paths$figures, "paso9c_semilla_completa")
dir.create(output_paso9c, recursive = TRUE, showWarnings = FALSE)
dir.create(output_figures, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# PASO 9C.1: CARGAR DATOS Y SECUENCIAS
# ------------------------------------------------------------------------------

cat("📂 PASO 9C.1: Cargando datos...\n")

# Datos completos
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
    mirna_name = str_extract(header, "hsa-[^ ]+")
  )

cat("  ✓ Secuencias cargadas:", nrow(sequences), "\n\n")

# ------------------------------------------------------------------------------
# PASO 9C.2: EXTRAER REGIÓN SEMILLA DE TODOS LOS miRNAs
# ------------------------------------------------------------------------------

cat("🌱 PASO 9C.2: Extrayendo región semilla (1-7) de todos los miRNAs...\n")

# Extraer región semilla
sequences_seed <- sequences %>%
  mutate(
    seed_region = substr(sequence, 1, 7),
    seed_length = nchar(seed_region)
  ) %>%
  filter(seed_length == 7)  # Solo miRNAs con semilla completa

cat("  ✓ miRNAs con semilla completa:", nrow(sequences_seed), "\n")

# Contar G's en semilla
sequences_seed <- sequences_seed %>%
  mutate(
    n_g_in_seed = str_count(seed_region, "G"),
    perc_g = round(n_g_in_seed / 7 * 100, 1)
  )

cat("  ✓ G's promedio en semilla:", round(mean(sequences_seed$n_g_in_seed), 2), "\n\n")

# ------------------------------------------------------------------------------
# PASO 9C.3: IDENTIFICAR QUÉ miRNAs TIENEN G>T EN SEMILLA
# ------------------------------------------------------------------------------

cat("🔍 PASO 9C.3: Identificando miRNAs oxidados...\n")

# miRNAs con G>T en semilla
mirnas_gt_seed <- datos %>%
  filter(mutation_type == "G>T", position >= 1, position <= 7) %>%
  distinct(`miRNA name`) %>%
  pull(`miRNA name`)

cat("  ✓ miRNAs con G>T en semilla:", length(mirnas_gt_seed), "\n")

# Marcar en tabla de secuencias
sequences_seed <- sequences_seed %>%
  mutate(
    tiene_gt = mirna_name %in% mirnas_gt_seed
  )

# Contar G>T por miRNA
gt_counts <- datos %>%
  filter(mutation_type == "G>T", position >= 1, position <= 7) %>%
  group_by(`miRNA name`) %>%
  summarise(n_gt_seed = n(), .groups = "drop")

sequences_seed <- sequences_seed %>%
  left_join(gt_counts, by = c("mirna_name" = "miRNA name")) %>%
  mutate(n_gt_seed = replace_na(n_gt_seed, 0))

cat("  ✓ G>T contados por miRNA\n\n")

# ------------------------------------------------------------------------------
# PASO 9C.4: AGRUPAR POR SIMILITUD DE SECUENCIA SEMILLA
# ------------------------------------------------------------------------------

cat("🧬 PASO 9C.4: Agrupando por similitud de secuencia...\n")

# Contar frecuencia de cada secuencia semilla
seed_freq <- sequences_seed %>%
  group_by(seed_region) %>%
  summarise(
    n_mirnas = n(),
    n_con_gt = sum(tiene_gt),
    total_gt = sum(n_gt_seed),
    perc_oxidados = round(n_con_gt / n_mirnas * 100, 1),
    ejemplos = paste(head(mirna_name, 3), collapse = ", "),
    .groups = "drop"
  ) %>%
  arrange(desc(n_mirnas))

cat("  ✓ Secuencias semilla únicas:", nrow(seed_freq), "\n")
cat("  ✓ Semilla más común:", seed_freq$seed_region[1], 
    "(", seed_freq$n_mirnas[1], "miRNAs)\n\n")

# Filtrar secuencias con al menos 3 miRNAs
seed_freq_filtered <- seed_freq %>%
  filter(n_mirnas >= 3)

cat("  ✓ Secuencias con ≥3 miRNAs:", nrow(seed_freq_filtered), "\n\n")

# ------------------------------------------------------------------------------
# PASO 9C.5: IDENTIFICAR SECUENCIAS MÁS OXIDADAS
# ------------------------------------------------------------------------------

cat("🔥 PASO 9C.5: Identificando secuencias más susceptibles...\n")

# Top por % de oxidación (mínimo 3 miRNAs)
top_oxidadas <- seed_freq_filtered %>%
  filter(n_con_gt > 0) %>%
  arrange(desc(perc_oxidados), desc(total_gt)) %>%
  head(20)

cat("\n  🏆 TOP 20 SECUENCIAS MÁS OXIDADAS:\n")
print(top_oxidadas %>% select(seed_region, n_mirnas, n_con_gt, perc_oxidados, total_gt))

write_csv(top_oxidadas, file.path(output_paso9c, "paso9c_top_secuencias_oxidadas.csv"))

# Gráfica
p1 <- ggplot(top_oxidadas, aes(x = reorder(seed_region, perc_oxidados), y = perc_oxidados)) +
  geom_col(fill = "#E31A1C", alpha = 0.8) +
  geom_text(aes(label = paste0(perc_oxidados, "%\n(", n_con_gt, "/", n_mirnas, ")")),
            hjust = -0.1, size = 3) +
  coord_flip() +
  labs(
    title = "Top 20 Secuencias de Semilla Más Oxidadas",
    subtitle = "% de miRNAs con esa secuencia que tienen G>T en semilla",
    x = "Secuencia Semilla (7 bases)",
    y = "% miRNAs con G>T"
  ) +
  theme_minimal()

ggsave(file.path(output_figures, "paso9c_top_secuencias_oxidadas.png"),
       p1, width = 12, height = 8)
cat("  ✓ Figura 'paso9c_top_secuencias_oxidadas.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 9C.6: ANÁLISIS POR CONTENIDO DE G
# ------------------------------------------------------------------------------

cat("📊 PASO 9C.6: Analizando susceptibilidad por contenido de G...\n")

# Agrupar por número de G's
oxidacion_por_g <- sequences_seed %>%
  group_by(n_g_in_seed) %>%
  summarise(
    n_mirnas = n(),
    n_con_gt = sum(tiene_gt),
    total_gt = sum(n_gt_seed),
    perc_oxidados = round(n_con_gt / n_mirnas * 100, 1),
    gt_per_mirna = round(total_gt / n_mirnas, 2),
    .groups = "drop"
  )

cat("\n  📈 OXIDACIÓN POR CONTENIDO DE G:\n")
print(oxidacion_por_g)

write_csv(oxidacion_por_g, file.path(output_paso9c, "paso9c_oxidacion_por_contenido_g.csv"))

# Gráfica
p2 <- ggplot(oxidacion_por_g, aes(x = factor(n_g_in_seed), y = perc_oxidados)) +
  geom_col(fill = "steelblue", alpha = 0.8) +
  geom_text(aes(label = paste0(perc_oxidados, "%\n(n=", n_mirnas, ")")),
            vjust = -0.5, size = 3.5) +
  labs(
    title = "Susceptibilidad a Oxidación por Contenido de G en Semilla",
    subtitle = "% de miRNAs con G>T según número de G's en región semilla",
    x = "Número de G's en Región Semilla",
    y = "% miRNAs con G>T"
  ) +
  theme_minimal()

ggsave(file.path(output_figures, "paso9c_oxidacion_vs_contenido_g.png"),
       p2, width = 10, height = 6)
cat("  ✓ Figura 'paso9c_oxidacion_vs_contenido_g.png' generada\n\n")

# Test de correlación
if (nrow(oxidacion_por_g) > 2) {
  cor_test <- cor.test(oxidacion_por_g$n_g_in_seed, oxidacion_por_g$perc_oxidados)
  cat("  🔬 Correlación G's vs % oxidación:\n")
  cat("    r =", round(cor_test$estimate, 3), "\n")
  cat("    p =", format.pval(cor_test$p.value), "\n\n")
}

# ------------------------------------------------------------------------------
# PASO 9C.7: SEQUENCE LOGOS POR NIVEL DE OXIDACIÓN
# ------------------------------------------------------------------------------

cat("🎨 PASO 9C.7: Generando logos por nivel de oxidación...\n")

# Separar en grupos por oxidación
sequences_seed <- sequences_seed %>%
  mutate(
    oxidation_level = case_when(
      n_gt_seed >= 2 ~ "Alto (≥2 G>T)",
      n_gt_seed == 1 ~ "Medio (1 G>T)",
      TRUE ~ "Sin G>T"
    )
  )

# Resumen por nivel
oxidation_summary <- sequences_seed %>%
  group_by(oxidation_level) %>%
  summarise(
    n = n(),
    avg_g = round(mean(n_g_in_seed), 2),
    .groups = "drop"
  )

cat("\n  📊 NIVELES DE OXIDACIÓN:\n")
print(oxidation_summary)

# Generar logos por grupo
for (nivel in c("Alto (≥2 G>T)", "Medio (1 G>T)", "Sin G>T")) {
  
  seqs_nivel <- sequences_seed %>%
    filter(oxidation_level == nivel) %>%
    pull(seed_region)
  
  if (length(seqs_nivel) >= 10) {
    
    cat("\n  → Logo para:", nivel, "(n =", length(seqs_nivel), ")\n")
    
    p_logo <- ggseqlogo(seqs_nivel, method = 'prob') +
      labs(title = paste0("Sequence Logo: ", nivel),
           subtitle = paste0("N = ", length(seqs_nivel), " miRNAs")) +
      theme_minimal()
    
    filename <- str_replace_all(tolower(nivel), "[^a-z0-9]", "_")
    ggsave(file.path(output_figures, paste0("paso9c_logo_", filename, ".png")),
           p_logo, width = 10, height = 4)
    
    cat("    ✓ Logo generado\n")
  }
}

cat("\n")

# ------------------------------------------------------------------------------
# PASO 9C.8: ANÁLISIS DE SECUENCIAS CON MÚLTIPLES G>T
# ------------------------------------------------------------------------------

cat("🔥 PASO 9C.8: Analizando secuencias con múltiples G>T...\n")

# Secuencias con 2+ G>T
high_oxidation <- sequences_seed %>%
  filter(n_gt_seed >= 2) %>%
  arrange(desc(n_gt_seed))

cat("  ✓ miRNAs con ≥2 G>T en semilla:", nrow(high_oxidation), "\n")

if (nrow(high_oxidation) > 0) {
  cat("\n  🏆 TOP miRNAs más oxidados:\n")
  print(high_oxidation %>% 
          select(mirna_name, seed_region, n_g_in_seed, n_gt_seed) %>%
          head(10))
  
  write_csv(high_oxidation, file.path(output_paso9c, "paso9c_mirnas_alta_oxidacion.csv"))
}

# Analizar contenido G en estos
cat("\n  📊 Contenido G en miRNAs altamente oxidados:\n")
cat("    - G's promedio:", round(mean(high_oxidation$n_g_in_seed), 2), "\n")
cat("    - vs general:", round(mean(sequences_seed$n_g_in_seed), 2), "\n\n")

# ------------------------------------------------------------------------------
# PASO 9C.9: HEATMAP DE OXIDACIÓN POR POSICIÓN Y SECUENCIA
# ------------------------------------------------------------------------------

cat("📊 PASO 9C.9: Generando heatmap de oxidación...\n")

# Para cada secuencia común (≥3 miRNAs), contar G>T por posición
seed_position_oxidation <- datos %>%
  filter(mutation_type == "G>T", position >= 1, position <= 7) %>%
  left_join(sequences, by = c("miRNA name" = "mirna_name")) %>%
  filter(!is.na(sequence)) %>%
  mutate(seed_region = substr(sequence, 1, 7)) %>%
  group_by(seed_region, position) %>%
  summarise(n_gt = n(), .groups = "drop")

# Join con frecuencias
seed_position_oxidation <- seed_position_oxidation %>%
  left_join(seed_freq %>% select(seed_region, n_mirnas), by = "seed_region") %>%
  filter(n_mirnas >= 3) %>%
  mutate(perc = round(n_gt / n_mirnas * 100, 1))

# Crear matriz para heatmap
if (nrow(seed_position_oxidation) > 0) {
  
  oxidation_matrix <- seed_position_oxidation %>%
    select(seed_region, position, n_gt) %>%
    pivot_wider(names_from = position, values_from = n_gt, values_fill = 0) %>%
    column_to_rownames("seed_region") %>%
    as.matrix()
  
  # Solo top 30 secuencias por total de G>T
  if (nrow(oxidation_matrix) > 30) {
    row_sums <- rowSums(oxidation_matrix)
    top_30 <- names(sort(row_sums, decreasing = TRUE)[1:30])
    oxidation_matrix <- oxidation_matrix[top_30, ]
  }
  
  png(file.path(output_figures, "paso9c_heatmap_oxidacion.png"),
      width = 10, height = 12, units = "in", res = 150)
  
  pheatmap(
    oxidation_matrix,
    color = colorRampPalette(c("white", "yellow", "orange", "red"))(100),
    cluster_rows = TRUE,
    cluster_cols = FALSE,
    display_numbers = TRUE,
    main = "Heatmap: G>T por Posición y Secuencia Semilla",
    fontsize = 9,
    fontsize_number = 7,
    labels_col = paste0("Pos ", 1:7)
  )
  
  dev.off()
  cat("  ✓ Figura 'paso9c_heatmap_oxidacion.png' generada\n\n")
}

# ------------------------------------------------------------------------------
# PASO 9C.10: COMPARAR SECUENCIAS OXIDADAS VS NO OXIDADAS
# ------------------------------------------------------------------------------

cat("🔬 PASO 9C.10: Comparando secuencias oxidadas vs no oxidadas...\n")

# Estadísticas
comp_stats <- sequences_seed %>%
  group_by(tiene_gt) %>%
  summarise(
    n = n(),
    avg_g = round(mean(n_g_in_seed), 2),
    sd_g = round(sd(n_g_in_seed), 2),
    min_g = min(n_g_in_seed),
    max_g = max(n_g_in_seed),
    .groups = "drop"
  )

cat("\n  📊 COMPARACIÓN:\n")
print(comp_stats)

# Test estadístico
test_g <- wilcox.test(
  n_g_in_seed ~ tiene_gt,
  data = sequences_seed
)

cat("\n  🔬 Test Wilcoxon (contenido G):\n")
cat("    p-value =", format.pval(test_g$p.value), "\n\n")

# Boxplot
p3 <- ggplot(sequences_seed, aes(x = tiene_gt, y = n_g_in_seed, fill = tiene_gt)) +
  geom_boxplot(alpha = 0.7, outlier.size = 1) +
  scale_fill_manual(
    values = c("FALSE" = "#1F78B4", "TRUE" = "#E31A1C"),
    labels = c("Sin G>T", "Con G>T"),
    name = ""
  ) +
  scale_x_discrete(labels = c("Sin G>T\nen semilla", "Con G>T\nen semilla")) +
  labs(
    title = "Contenido de G en Semilla: miRNAs Oxidados vs No Oxidados",
    subtitle = sprintf("p-value = %s (Wilcoxon)", format.pval(test_g$p.value)),
    x = "",
    y = "Número de G's en Región Semilla"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

ggsave(file.path(output_figures, "paso9c_contenido_g_oxidados.png"),
       p3, width = 8, height = 6)
cat("  ✓ Figura 'paso9c_contenido_g_oxidados.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 9C.11: SECUENCIAS ESPECÍFICAS CON ALTO % OXIDACIÓN
# ------------------------------------------------------------------------------

cat("🎯 PASO 9C.11: Secuencias con alta susceptibilidad...\n")

# Filtrar: ≥50% oxidados Y ≥3 miRNAs
high_susceptibility <- seed_freq_filtered %>%
  filter(perc_oxidados >= 50) %>%
  arrange(desc(perc_oxidados), desc(n_mirnas))

cat("\n  🔥 SECUENCIAS DE ALTA SUSCEPTIBILIDAD (≥50% oxidados):\n")
if (nrow(high_susceptibility) > 0) {
  print(high_susceptibility)
  write_csv(high_susceptibility, 
            file.path(output_paso9c, "paso9c_secuencias_alta_susceptibilidad.csv"))
} else {
  cat("    Ninguna secuencia alcanza ≥50% con ≥3 miRNAs\n")
}

# Análisis de contenido G en estas secuencias
if (nrow(high_susceptibility) > 0) {
  high_susc_with_g <- high_susceptibility %>%
    mutate(n_g = str_count(seed_region, "G"))
  
  cat("\n  📊 Contenido G en secuencias susceptibles:\n")
  cat("    - G's promedio:", round(mean(high_susc_with_g$n_g), 2), "\n")
  cat("    - vs general:", round(mean(sequences_seed$n_g_in_seed), 2), "\n\n")
}

# ------------------------------------------------------------------------------
# PASO 9C.12: RESUMEN EJECUTIVO
# ------------------------------------------------------------------------------

cat("📋 PASO 9C.12: Generando resumen ejecutivo...\n")

resumen <- list(
  total_mirnas_analizados = nrow(sequences_seed),
  mirnas_con_gt = sum(sequences_seed$tiene_gt),
  perc_con_gt = round(sum(sequences_seed$tiene_gt) / nrow(sequences_seed) * 100, 1),
  secuencias_unicas = nrow(seed_freq),
  secuencias_comunes = nrow(seed_freq_filtered),
  secuencia_mas_comun = seed_freq$seed_region[1],
  secuencia_mas_comun_n = seed_freq$n_mirnas[1],
  secuencia_mas_oxidada = top_oxidadas$seed_region[1],
  secuencia_mas_oxidada_perc = top_oxidadas$perc_oxidados[1],
  avg_g_oxidados = comp_stats$avg_g[comp_stats$tiene_gt == TRUE],
  avg_g_no_oxidados = comp_stats$avg_g[comp_stats$tiene_gt == FALSE],
  test_p = test_g$p.value,
  n_alta_susceptibilidad = nrow(high_susceptibility)
)

write_json(resumen, file.path(output_paso9c, "paso9c_resumen.json"), pretty = TRUE)

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║                  RESUMEN EJECUTIVO - PASO 9C                          ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

cat("🌱 REGIÓN SEMILLA - ANÁLISIS COMPLETO:\n")
cat("  • miRNAs analizados:", resumen$total_mirnas_analizados, "\n")
cat("  • Con G>T en semilla:", resumen$mirnas_con_gt, 
    sprintf("(%.1f%%)", resumen$perc_con_gt), "\n")
cat("  • Secuencias únicas:", resumen$secuencias_unicas, "\n\n")

cat("🧬 SECUENCIAS:\n")
cat("  • Más común:", resumen$secuencia_mas_comun, 
    "(", resumen$secuencia_mas_comun_n, "miRNAs)\n")
cat("  • Más oxidada:", resumen$secuencia_mas_oxidada, 
    sprintf("(%.1f%% oxidados)", resumen$secuencia_mas_oxidada_perc), "\n\n")

cat("📊 CONTENIDO DE G:\n")
cat("  • Oxidados:", resumen$avg_g_oxidados, "G's promedio\n")
cat("  • No oxidados:", resumen$avg_g_no_oxidados, "G's promedio\n")
cat("  • p-value:", format.pval(resumen$test_p), "\n\n")

cat("🔥 ALTA SUSCEPTIBILIDAD:\n")
cat("  • Secuencias con ≥50% oxidados:", resumen$n_alta_susceptibilidad, "\n\n")

cat("✅ ANÁLISIS COMPLETADO\n")
cat("  • Figuras generadas: 5-8\n")
cat("  • Tablas guardadas: 5\n")
cat("  • Sequence logos: 3 (por nivel)\n")
cat("  • Ubicación:", output_paso9c, "\n\n")

cat("════════════════════════════════════════════════════════════════════════\n")









