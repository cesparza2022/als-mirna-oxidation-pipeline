#!/usr/bin/env Rscript
# ==============================================================================
# PASO 10D: ANÁLISIS DE MOTIVOS EXTENDIDOS (PENTANUCLEÓTIDOS Y HEPTANUCLEÓTIDOS)
# ==============================================================================
# 
# OBJETIVO:
#   Analizar contexto amplio de G>T (±2 y ±3 bases):
#   1. Pentanucleótidos (±2 bases)
#   2. Heptanucleótidos (±3 bases)
#   3. Específico de let-7 (T-G-A-G-G contexto)
#   4. Comparar Seed vs Central vs 3prime
#   5. Enriquecimiento estadístico formal
#
# INPUT:
#   - 397 G>T en semilla + otros en Central y 3prime
#   - Secuencias completas de miRNAs
#
# OUTPUT:
#   - Pentanucleótidos identificados
#   - Heptanucleótidos identificados
#   - Enriquecimiento estadístico
#   - Motivos por región
#
# AUTOR: Análisis ALS miRNAs
# FECHA: 8 de octubre de 2025
# ==============================================================================

library(tidyverse)
library(ggseqlogo)
library(jsonlite)

cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║     PASO 10D: MOTIVOS EXTENDIDOS (PENTANUC Y HEPTANUC)                ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

# Cargar configuración
source("config_pipeline.R")
source("functions_pipeline.R")

# Directorios
output_paso10d <- file.path(config$output_paths$outputs, "paso10d_motivos_extendidos")
output_figures <- file.path(config$output_paths$figures, "paso10d_motivos_extendidos")
dir.create(output_paso10d, recursive = TRUE, showWarnings = FALSE)
dir.create(output_figures, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# CARGAR DATOS
# ------------------------------------------------------------------------------

cat("📂 Cargando datos...\n")

raw_data <- read_tsv(config$data_paths$raw_data, show_col_types = FALSE)
datos_split <- apply_split_collapse(raw_data)
datos <- calculate_vafs(datos_split)
datos <- filter_high_vafs(datos, threshold = 0.5)

datos <- datos %>%
  mutate(
    position = as.integer(str_extract(`pos:mut`, "^\\d+")),
    mutation_raw = str_extract(`pos:mut`, "(?<=:)[ACGT]{2}"),
    mutation_type = paste0(str_sub(mutation_raw, 1, 1), ">", str_sub(mutation_raw, 2, 2)),
    region = case_when(
      position >= 1 & position <= 7 ~ "Seed",
      position >= 8 & position <= 12 ~ "Central",
      position >= 13 ~ "3prime",
      TRUE ~ "Unknown"
    )
  )

# Secuencias
seq_file <- "data/hsa_filt_mature_2022.fa"
fasta_lines <- readLines(seq_file)
headers <- grep("^>", fasta_lines)

sequences <- tibble(
  header = fasta_lines[headers],
  sequence = fasta_lines[headers + 1]
) %>%
  mutate(mirna_name = str_extract(header, "hsa-[^ ]+"))

# G>T con secuencias
gt_data <- datos %>%
  filter(mutation_type == "G>T", !is.na(position)) %>%
  left_join(sequences, by = c("miRNA name" = "mirna_name")) %>%
  filter(!is.na(sequence))

cat("  ✓ G>T con secuencias:", nrow(gt_data), "\n\n")

# ------------------------------------------------------------------------------
# PASO 10D.1: EXTRAER PENTANUCLEÓTIDOS (±2)
# ------------------------------------------------------------------------------

cat("🧬 PASO 10D.1: Extrayendo pentanucleótidos (±2)...\n")

# Función para extraer contexto
extract_context_extended <- function(sequence, position, window = 2) {
  seq_length <- nchar(sequence)
  if (position < 1 || position > seq_length) return(NA)
  
  start_pos <- max(1, position - window)
  end_pos <- min(seq_length, position + window)
  context <- substr(sequence, start_pos, end_pos)
  
  return(context)
}

# Extraer pentanucleótidos
gt_pentanuc <- gt_data %>%
  rowwise() %>%
  mutate(
    pentanuc = extract_context_extended(sequence, position, window = 2)
  ) %>%
  ungroup() %>%
  filter(!is.na(pentanuc), nchar(pentanuc) == 5)

cat("  ✓ Pentanucleótidos extraídos:", nrow(gt_pentanuc), "\n")

# Frecuencias
pentanuc_freq <- gt_pentanuc %>%
  group_by(pentanuc, region) %>%
  summarise(n = n(), .groups = "drop") %>%
  arrange(region, desc(n))

cat("\n  📊 TOP 10 PENTANUCLEÓTIDOS (por región):\n\n")

for (reg in c("Seed", "Central", "3prime")) {
  cat("  ", reg, ":\n")
  top_reg <- pentanuc_freq %>% filter(region == reg) %>% head(10)
  if (nrow(top_reg) > 0) {
    print(top_reg)
  }
  cat("\n")
}

write_csv(pentanuc_freq, file.path(output_paso10d, "paso10d_pentanucleotidos.csv"))

# Gráfica de top pentanuc en semilla
top_pentanuc_seed <- pentanuc_freq %>%
  filter(region == "Seed") %>%
  head(20)

p1 <- ggplot(top_pentanuc_seed, aes(x = reorder(pentanuc, n), y = n)) +
  geom_col(fill = "#E31A1C", alpha = 0.8) +
  geom_text(aes(label = n), hjust = -0.2, size = 3) +
  coord_flip() +
  labs(
    title = "Top 20 Pentanucleótidos en G>T de Región Semilla",
    subtitle = "Contexto ±2 bases alrededor de G mutada",
    x = "Pentanucleótido",
    y = "Frecuencia"
  ) +
  theme_minimal()

ggsave(file.path(output_figures, "paso10d_pentanuc_seed.png"),
       p1, width = 10, height = 8)
cat("  ✓ Figura 'paso10d_pentanuc_seed.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 10D.2: EXTRAER HEPTANUCLEÓTIDOS (±3)
# ------------------------------------------------------------------------------

cat("🧬 PASO 10D.2: Extrayendo heptanucleótidos (±3)...\n")

gt_heptanuc <- gt_data %>%
  rowwise() %>%
  mutate(
    heptanuc = extract_context_extended(sequence, position, window = 3)
  ) %>%
  ungroup() %>%
  filter(!is.na(heptanuc), nchar(heptanuc) == 7)

cat("  ✓ Heptanucleótidos extraídos:", nrow(gt_heptanuc), "\n")

# Frecuencias
heptanuc_freq <- gt_heptanuc %>%
  group_by(heptanuc, region) %>%
  summarise(n = n(), .groups = "drop") %>%
  arrange(region, desc(n))

cat("\n  📊 TOP 5 HEPTANUCLEÓTIDOS (por región):\n\n")

for (reg in c("Seed", "Central", "3prime")) {
  cat("  ", reg, ":\n")
  top_reg <- heptanuc_freq %>% filter(region == reg) %>% head(5)
  if (nrow(top_reg) > 0) {
    print(top_reg)
  }
  cat("\n")
}

write_csv(heptanuc_freq, file.path(output_paso10d, "paso10d_heptanucleotidos.csv"))

# ------------------------------------------------------------------------------
# PASO 10D.3: ANÁLISIS ESPECÍFICO DE let-7 (TGAGGTA)
# ------------------------------------------------------------------------------

cat("🎯 PASO 10D.3: Análisis específico de motivos let-7...\n")

# Pentanuc de let-7 en posiciones 2, 4, 5
let7_pentanuc <- gt_pentanuc %>%
  filter(str_detect(`miRNA name`, "let-7|miR-98"),
         position %in% c(2, 4, 5))

let7_pentanuc_freq <- let7_pentanuc %>%
  group_by(position, pentanuc) %>%
  summarise(n = n(), .groups = "drop") %>%
  arrange(position, desc(n))

cat("\n  📊 PENTANUCLEÓTIDOS EN let-7 (posiciones 2, 4, 5):\n\n")
for (pos in c(2, 4, 5)) {
  cat("  Posición", pos, ":\n")
  top_pos <- let7_pentanuc_freq %>% filter(position == pos) %>% head(5)
  print(top_pos)
  cat("\n")
}

# ------------------------------------------------------------------------------
# PASO 10D.4: COMPARAR MOTIVOS POR REGIÓN
# ------------------------------------------------------------------------------

cat("📍 PASO 10D.4: Comparando motivos por región...\n")

# Diversidad de motivos por región
diversidad <- pentanuc_freq %>%
  group_by(region) %>%
  summarise(
    n_total = sum(n),
    n_motivos_unicos = n(),
    motivo_mas_comun = pentanuc[which.max(n)],
    freq_mas_comun = max(n),
    perc_mas_comun = round(max(n) / sum(n) * 100, 1),
    .groups = "drop"
  )

cat("\n  📊 DIVERSIDAD DE MOTIVOS POR REGIÓN:\n")
print(diversidad)

write_csv(diversidad, file.path(output_paso10d, "paso10d_diversidad_por_region.csv"))

# Gráfica
p2 <- ggplot(diversidad, aes(x = region, y = n_motivos_unicos)) +
  geom_col(fill = "steelblue", alpha = 0.8) +
  geom_text(aes(label = paste0(n_motivos_unicos, "\nmotivos")),
            vjust = -0.5, size = 4) +
  labs(
    title = "Diversidad de Motivos (Pentanucleótidos) por Región",
    subtitle = "Número de motivos únicos identificados",
    x = "Región",
    y = "Motivos Únicos"
  ) +
  theme_minimal()

ggsave(file.path(output_figures, "paso10d_diversidad_por_region.png"),
       p2, width = 10, height = 6)
cat("  ✓ Figura 'paso10d_diversidad_por_region.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 10D.5: SEQUENCE LOGOS EXTENDIDOS
# ------------------------------------------------------------------------------

cat("🎨 PASO 10D.5: Generando sequence logos extendidos...\n")

# Logos por región (pentanuc completos)
for (reg in c("Seed", "Central", "3prime")) {
  
  seqs_reg <- gt_pentanuc %>%
    filter(region == reg) %>%
    pull(pentanuc)
  
  if (length(seqs_reg) >= 10 && length(unique(nchar(seqs_reg))) == 1) {
    
    cat("  → Logo para región", reg, "(n =", length(seqs_reg), ")\n")
    
    p_logo <- ggseqlogo(seqs_reg, method = 'prob') +
      labs(title = paste0("Pentanucleótido Logo: Región ", reg, " (G>T)"),
           subtitle = paste0("N = ", length(seqs_reg), " contextos")) +
      theme_minimal()
    
    ggsave(file.path(output_figures, paste0("paso10d_logo_pentanuc_", tolower(reg), ".png")),
           p_logo, width = 10, height = 4)
    
    cat("    ✓ Logo generado\n")
  }
}

cat("\n")

# ------------------------------------------------------------------------------
# PASO 10D.6: ENRIQUECIMIENTO ESTADÍSTICO
# ------------------------------------------------------------------------------

cat("📊 PASO 10D.6: Calculando enriquecimiento de motivos G-rich...\n")

# Identificar motivos G-rich
gt_pentanuc <- gt_pentanuc %>%
  mutate(
    n_g = str_count(pentanuc, "G"),
    is_g_rich = n_g >= 3
  )

# Resumen
enriquecimiento <- gt_pentanuc %>%
  group_by(region, is_g_rich) %>%
  summarise(n = n(), .groups = "drop") %>%
  pivot_wider(names_from = is_g_rich, values_from = n, values_fill = 0) %>%
  rename(g_rich = `TRUE`, no_g_rich = `FALSE`) %>%
  mutate(
    total = g_rich + no_g_rich,
    perc_g_rich = round(g_rich / total * 100, 1)
  )

cat("\n  📈 ENRIQUECIMIENTO EN MOTIVOS G-RICH (≥3 G's en pentanuc):\n")
print(enriquecimiento)

# Test estadístico (esperado aleatorio = 0.1% para ≥3 G's en pentanuc de 5)
# Probabilidad = (0.25)^3 * C(5,3) = 0.015625 ≈ 1.56%

for (i in 1:nrow(enriquecimiento)) {
  reg <- enriquecimiento$region[i]
  obs <- enriquecimiento$perc_g_rich[i]
  esperado <- 1.56
  fold <- round(obs / esperado, 1)
  
  cat("\n  ", reg, ":\n")
  cat("    Observado:", obs, "%\n")
  cat("    Esperado aleatorio: ~1.6%\n")
  cat("    Enriquecimiento:", fold, "x\n")
}

write_csv(enriquecimiento, file.path(output_paso10d, "paso10d_enriquecimiento_g_rich.csv"))

# Gráfica
p3 <- ggplot(enriquecimiento, aes(x = region, y = perc_g_rich)) +
  geom_col(fill = "#E31A1C", alpha = 0.8) +
  geom_hline(yintercept = 1.56, linetype = "dashed", color = "blue") +
  geom_text(aes(label = paste0(perc_g_rich, "%")), vjust = -0.5, size = 4) +
  annotate("text", x = 2.5, y = 1.8, label = "Esperado aleatorio (1.6%)", 
           color = "blue", size = 3) +
  labs(
    title = "Enriquecimiento de Motivos G-rich (≥3 G's) por Región",
    subtitle = "En contexto pentanucleótido (±2 bases)",
    x = "Región",
    y = "% Motivos G-rich"
  ) +
  theme_minimal()

ggsave(file.path(output_figures, "paso10d_enriquecimiento_g_rich.png"),
       p3, width = 10, height = 6)
cat("\n  ✓ Figura 'paso10d_enriquecimiento_g_rich.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 10D.7: COMPARAR let-7 (TGAGGTA) vs RESTO
# ------------------------------------------------------------------------------

cat("🎯 PASO 10D.7: Comparando motivos let-7 vs resto...\n")

# Clasificar
gt_pentanuc <- gt_pentanuc %>%
  mutate(
    es_let7 = str_detect(`miRNA name`, "let-7|miR-98") & position %in% c(2, 4, 5)
  )

# Comparación
comparacion_let7 <- gt_pentanuc %>%
  group_by(es_let7) %>%
  summarise(
    n = n(),
    n_g_promedio = mean(n_g, na.rm = TRUE),
    perc_g_rich = round(sum(is_g_rich) / n() * 100, 1),
    .groups = "drop"
  )

cat("\n  📊 COMPARACIÓN let-7 vs RESTO:\n")
print(comparacion_let7)

# Test
if (sum(gt_pentanuc$es_let7) > 0) {
  test_g <- wilcox.test(n_g ~ es_let7, data = gt_pentanuc)
  cat("\n  🔬 Test Wilcoxon (contenido G):\n")
  cat("    p-value =", format.pval(test_g$p.value), "\n\n")
}

# ------------------------------------------------------------------------------
# PASO 10D.8: RESUMEN EJECUTIVO
# ------------------------------------------------------------------------------

cat("📋 Generando resumen ejecutivo...\n")

resumen <- list(
  n_pentanuc = nrow(gt_pentanuc),
  n_heptanuc = nrow(gt_heptanuc),
  pentanuc_mas_comun_seed = pentanuc_freq %>% 
    filter(region == "Seed") %>% 
    slice_max(n, n = 1) %>% 
    pull(pentanuc),
  enriq_seed = enriquecimiento %>% filter(region == "Seed") %>% pull(perc_g_rich),
  enriq_central = enriquecimiento %>% filter(region == "Central") %>% pull(perc_g_rich),
  enriq_3prime = enriquecimiento %>% filter(region == "3prime") %>% pull(perc_g_rich)
)

write_json(resumen, file.path(output_paso10d, "paso10d_resumen.json"), pretty = TRUE)

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║                  RESUMEN EJECUTIVO - PASO 10D                         ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

cat("🧬 MOTIVOS ANALIZADOS:\n")
cat("  • Pentanucleótidos:", resumen$n_pentanuc, "\n")
cat("  • Heptanucleótidos:", resumen$n_heptanuc, "\n\n")

cat("📊 ENRIQUECIMIENTO G-RICH:\n")
cat("  • Semilla:", resumen$enriq_seed, "% (vs 1.6% esperado)\n")
cat("  • Central:", resumen$enriq_central, "% (vs 1.6% esperado)\n")
cat("  • 3prime:", resumen$enriq_3prime, "% (vs 1.6% esperado)\n\n")

cat("✅ ANÁLISIS COMPLETADO\n")
cat("  • Figuras generadas: 4-5\n")
cat("  • Tablas guardadas: 3\n")
cat("  • Ubicación:", output_paso10d, "\n\n")

cat("🎯 SIGUIENTE: Paso 10E - Temporal × motivos\n\n")

cat("════════════════════════════════════════════════════════════════════════\n")








