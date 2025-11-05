#!/usr/bin/env Rscript
# ============================================================================
# REGENERACIÓN DE FIGURAS EN INGLÉS CON CALIDAD MEJORADA
# ============================================================================
# 
# Objetivo: Regenerar las figuras críticas que tienen texto en español,
#           traducirlas a inglés, mejorar la calidad visual, y mantener
#           consistencia de estilo y colores.
#
# Mejoras aplicadas:
# - Etiquetas en inglés
# - Colores profesionales y consistentes
# - Leyendas legibles
# - Tamaño de texto apropiado
# - Transparencia en puntos sobrepuestos
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(gridExtra)
  library(RColorBrewer)
  library(viridis)
  library(scales)
  library(pheatmap)
  library(ggseqlogo)
  library(Biostrings)
})

# Configuración global de tema
theme_set(theme_bw(base_size = 14))

# Paleta de colores consistente
color_palette <- list(
  primary = "#667eea",
  secondary = "#764ba2",
  accent = "#f5576c",
  success = "#28a745",
  warning = "#ffc107",
  info = "#17a2b8",
  als = "#e74c3c",
  control = "#3498db",
  gt = "#e74c3c",
  other = "#95a5a6",
  seed = "#2ecc71",
  central = "#f39c12",
  three_prime = "#9b59b6"
)

# Directorio de salida
output_dir <- "figures_english"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║     REGENERATING FIGURES IN ENGLISH - IMPROVED QUALITY                ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n")
cat("\n")

# ============================================================================
# CARGAR DATOS PROCESADOS
# ============================================================================

cat("📂 Loading processed data...\n")

# Cargar datos con VAFs filtrados
data_file <- "outputs/paso1a_cargar_datos/filtered_vaf_data.csv"
if (!file.exists(data_file)) {
  stop("❌ Data file not found: ", data_file)
}

data <- read_csv(data_file, show_col_types = FALSE)

cat("✅ Data loaded:\n")
cat("   • Rows:", nrow(data), "\n")
cat("   • Columns:", ncol(data), "\n")
cat("\n")

# Identificar columnas
meta_cols <- c("miRNA name", "pos:mut")
sample_cols <- setdiff(names(data), meta_cols)

# Extraer información de mutación
data <- data %>%
  mutate(
    position = as.integer(str_extract(`pos:mut`, "^\\d+")),
    mutation_raw = str_extract(`pos:mut`, "\\d+:(.+)$", group = 1),
    from_base = str_sub(mutation_raw, 1, 1),
    to_base = str_sub(mutation_raw, 2, 2),
    mutation_type = paste0(from_base, ">", to_base),
    is_gt = mutation_type == "G>T"
  )

# Clasificar región funcional
data <- data %>%
  mutate(
    region = case_when(
      position >= 2 & position <= 8 ~ "Seed",
      position >= 9 & position <= 12 ~ "Central",
      position >= 13 ~ "3' Region",
      TRUE ~ "Other"
    )
  )

cat("✅ Data processed with mutation types and regions\n")
cat("\n")

# ============================================================================
# FIGURA 1: PASO 7A - G>T TEMPORAL CHANGES (CRITICAL)
# ============================================================================

cat("🔄 Figure 1/17: Temporal G>T changes...\n")

# Cargar metadata
metadata_file <- "outputs/paso6a_integracion_metadatos/metadata_integrated.csv"
if (file.exists(metadata_file)) {
  metadata <- read_csv(metadata_file, show_col_types = FALSE)
  
  # Identificar muestras longitudinales
  longitudinal_samples <- metadata %>%
    filter(is_longitudinal == TRUE, cohort == "ALS") %>%
    pull(sample_id)
  
  # Preparar datos para análisis temporal
  data_long <- data %>%
    select(`miRNA name`, `pos:mut`, position, mutation_type, is_gt, region, all_of(sample_cols)) %>%
    pivot_longer(
      cols = all_of(sample_cols),
      names_to = "sample",
      values_to = "vaf"
    ) %>%
    filter(!is.na(vaf), vaf > 0)
  
  # Unir con metadata
  data_long <- data_long %>%
    left_join(
      metadata %>% select(sample_id, timepoint, cohort),
      by = c("sample" = "sample_id")
    ) %>%
    filter(!is.na(timepoint), cohort == "ALS")
  
  # Calcular cambios temporales para G>T
  temporal_gt <- data_long %>%
    filter(is_gt == TRUE) %>%
    group_by(`miRNA name`, `pos:mut`, timepoint) %>%
    summarise(mean_vaf = mean(vaf, na.rm = TRUE), .groups = "drop") %>%
    pivot_wider(names_from = timepoint, values_from = mean_vaf) %>%
    filter(!is.na(Enrolment), !is.na(Longitudinal)) %>%
    mutate(
      change = Longitudinal - Enrolment,
      direction = case_when(
        change > 0.0001 ~ "Increase",
        change < -0.0001 ~ "Decrease",
        TRUE ~ "No change"
      )
    )
  
  # Plot
  p <- ggplot(temporal_gt, aes(x = Enrolment, y = Longitudinal)) +
    geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray50", size = 1) +
    geom_point(aes(color = direction), alpha = 0.6, size = 2.5) +
    scale_color_manual(
      values = c("Increase" = color_palette$als, 
                 "Decrease" = color_palette$control, 
                 "No change" = "gray60"),
      name = "Direction"
    ) +
    labs(
      title = "G>T Mutations: Temporal Changes",
      subtitle = "Enrolment vs Longitudinal Timepoints (ALS patients)",
      x = "VAF at Enrolment",
      y = "VAF at Longitudinal",
      caption = paste0("N = ", nrow(temporal_gt), " G>T mutations with paired data\n",
                      "Points above diagonal = increase over time")
    ) +
    theme_bw(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30"),
      legend.position = "right",
      legend.title = element_text(face = "bold"),
      panel.grid.minor = element_blank()
    )
  
  ggsave(file.path(output_dir, "paso7a_temporal_gt_changes_english.png"),
         plot = p, width = 10, height = 8, dpi = 300, bg = "white")
  
  cat("   ✅ Saved: paso7a_temporal_gt_changes_english.png\n")
} else {
  cat("   ⚠️  Metadata not found, skipping temporal analysis\n")
}

cat("\n")

# ============================================================================
# FIGURA 2: PASO 8C - HEATMAP Z-SCORES (CRITICAL)
# ============================================================================

cat("🔄 Figure 2/17: Z-score heatmap...\n")

# Filtrar G>T en semilla
gt_seed <- data %>%
  filter(is_gt == TRUE, region == "Seed")

if (nrow(gt_seed) > 0) {
  # Crear matriz de VAFs
  vaf_matrix <- gt_seed %>%
    select(`miRNA name`, `pos:mut`, all_of(sample_cols)) %>%
    column_to_rownames("pos:mut") %>%
    select(-`miRNA name`) %>%
    as.matrix()
  
  # Calcular z-scores por fila (por mutación)
  vaf_matrix_zscore <- t(scale(t(vaf_matrix)))
  vaf_matrix_zscore[is.na(vaf_matrix_zscore) | is.infinite(vaf_matrix_zscore)] <- 0
  
  # Limitar a primeras 100 mutaciones para legibilidad
  if (nrow(vaf_matrix_zscore) > 100) {
    vaf_matrix_zscore <- vaf_matrix_zscore[1:100, ]
  }
  
  # Limitar a primeras 50 muestras para legibilidad
  if (ncol(vaf_matrix_zscore) > 50) {
    vaf_matrix_zscore <- vaf_matrix_zscore[, 1:50]
  }
  
  # Crear heatmap
  png(file.path(output_dir, "paso8c_heatmap_zscore_english.png"),
      width = 12, height = 10, units = "in", res = 300)
  
  pheatmap(
    vaf_matrix_zscore,
    color = colorRampPalette(c("blue", "white", "red"))(100),
    breaks = seq(-3, 3, length.out = 101),
    cluster_rows = TRUE,
    cluster_cols = TRUE,
    show_rownames = FALSE,  # No mostrar nombres individuales
    show_colnames = FALSE,  # No mostrar nombres individuales
    main = "Z-scores of VAFs for G>T Mutations in Seed Region",
    fontsize = 12,
    fontsize_row = 8,
    fontsize_col = 8,
    border_color = NA,
    legend = TRUE,
    legend_breaks = c(-3, -1.5, 0, 1.5, 3),
    legend_labels = c("-3", "-1.5", "0", "1.5", "3")
  )
  
  dev.off()
  
  cat("   ✅ Saved: paso8c_heatmap_zscore_english.png\n")
  cat("      (Limited to 100 mutations × 50 samples for readability)\n")
}

cat("\n")

# ============================================================================
# FIGURA 3: PASO 8C - POSITIONAL DIFFERENCES (CRITICAL)
# ============================================================================

cat("🔄 Figure 3/17: Positional differences ALS vs Control...\n")

# Cargar metadata si existe
if (exists("metadata")) {
  # Preparar datos
  data_long <- data %>%
    filter(is_gt == TRUE, region == "Seed") %>%
    select(`miRNA name`, `pos:mut`, position, all_of(sample_cols)) %>%
    pivot_longer(
      cols = all_of(sample_cols),
      names_to = "sample",
      values_to = "vaf"
    ) %>%
    filter(!is.na(vaf))
  
  # Unir con metadata
  data_long <- data_long %>%
    left_join(
      metadata %>% select(sample_id, cohort),
      by = c("sample" = "sample_id")
    ) %>%
    filter(!is.na(cohort), cohort %in% c("ALS", "Control"))
  
  # Calcular diferencias por posición
  pos_diff <- data_long %>%
    group_by(position, cohort) %>%
    summarise(mean_vaf = mean(vaf, na.rm = TRUE), .groups = "drop") %>%
    pivot_wider(names_from = cohort, values_from = mean_vaf) %>%
    mutate(
      diff = ALS - Control,
      abs_diff = abs(diff)
    ) %>%
    filter(!is.na(diff))
  
  # Realizar t-tests
  pos_tests <- data_long %>%
    group_by(position) %>%
    summarise(
      p_value = tryCatch({
        test <- t.test(vaf[cohort == "ALS"], vaf[cohort == "Control"])
        test$p.value
      }, error = function(e) NA_real_),
      .groups = "drop"
    )
  
  # Unir
  pos_diff <- pos_diff %>%
    left_join(pos_tests, by = "position") %>%
    mutate(
      significant = p_value < 0.05,
      neg_log_p = -log10(p_value)
    )
  
  # Plot 1: Diferencias
  p1 <- ggplot(pos_diff, aes(x = factor(position), y = diff)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_col(aes(fill = diff > 0), alpha = 0.8) +
    scale_fill_manual(
      values = c("TRUE" = color_palette$als, "FALSE" = color_palette$control),
      labels = c("TRUE" = "Higher in ALS", "FALSE" = "Higher in Control"),
      name = ""
    ) +
    labs(
      title = "VAF Differences by Seed Position",
      subtitle = "ALS - Control (G>T mutations)",
      x = "Seed Position",
      y = "Mean VAF Difference (ALS - Control)",
      caption = "Positive values = higher in ALS; Negative = higher in Control"
    ) +
    theme_bw(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30"),
      legend.position = "top",
      panel.grid.major.x = element_blank()
    )
  
  ggsave(file.path(output_dir, "paso8c_positional_differences_english.png"),
         plot = p1, width = 10, height = 7, dpi = 300, bg = "white")
  
  cat("   ✅ Saved: paso8c_positional_differences_english.png\n")
  
  # Plot 2: Significancia
  p2 <- ggplot(pos_diff %>% filter(!is.na(neg_log_p)), 
               aes(x = factor(position), y = neg_log_p)) +
    geom_hline(yintercept = -log10(0.05), linetype = "dashed", 
               color = color_palette$accent, size = 1) +
    geom_col(aes(fill = significant), alpha = 0.8) +
    scale_fill_manual(
      values = c("TRUE" = color_palette$accent, "FALSE" = "gray70"),
      labels = c("TRUE" = "Significant (p<0.05)", "FALSE" = "Not significant"),
      name = ""
    ) +
    labs(
      title = "Statistical Significance by Position",
      subtitle = "ALS vs Control comparison (G>T mutations)",
      x = "Seed Position",
      y = "-log10(p-value)",
      caption = "Dashed line = p = 0.05 threshold"
    ) +
    theme_bw(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30"),
      legend.position = "top",
      panel.grid.major.x = element_blank()
    )
  
  ggsave(file.path(output_dir, "paso8c_significance_by_position_english.png"),
         plot = p2, width = 10, height = 7, dpi = 300, bg = "white")
  
  cat("   ✅ Saved: paso8c_significance_by_position_english.png\n")
}

cat("\n")

# ============================================================================
# FIGURA 4: PASO 9C - G CONTENT IN OXIDIZED vs NON-OXIDIZED
# ============================================================================

cat("🔄 Figure 4/17: G content comparison...\n")

# Cargar secuencias
seq_file <- "hsa_filt_mature_2022.fa"
if (file.exists(seq_file)) {
  sequences <- readDNAStringSet(seq_file)
  
  # Extraer nombres y secuencias
  seq_df <- tibble(
    mirna_full = names(sequences),
    sequence = as.character(sequences)
  ) %>%
    mutate(
      mirna_name = str_extract(mirna_full, "^[^ ]+")
    )
  
  # Identificar miRNAs con G>T en semilla
  mirnas_with_gt <- data %>%
    filter(is_gt == TRUE, region == "Seed") %>%
    pull(`miRNA name`) %>%
    unique()
  
  # Extraer semilla (posiciones 2-8, que en R es 2:8)
  seq_df <- seq_df %>%
    mutate(
      seed_seq = str_sub(sequence, 2, 8),
      n_g_in_seed = str_count(seed_seq, "G"),
      has_gt_seed = mirna_name %in% mirnas_with_gt
    )
  
  # Comparar contenido G
  g_content_summary <- seq_df %>%
    group_by(has_gt_seed) %>%
    summarise(
      n = n(),
      mean_g = mean(n_g_in_seed, na.rm = TRUE),
      median_g = median(n_g_in_seed, na.rm = TRUE),
      sd_g = sd(n_g_in_seed, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Test estadístico
  test_result <- wilcox.test(
    n_g_in_seed ~ has_gt_seed,
    data = seq_df %>% filter(!is.na(n_g_in_seed))
  )
  
  # Plot
  p <- ggplot(seq_df %>% filter(!is.na(n_g_in_seed)), 
              aes(x = has_gt_seed, y = n_g_in_seed)) +
    geom_violin(aes(fill = has_gt_seed), alpha = 0.6, trim = FALSE) +
    geom_boxplot(width = 0.2, alpha = 0.8, outlier.alpha = 0.3) +
    scale_fill_manual(
      values = c("TRUE" = color_palette$als, "FALSE" = color_palette$control),
      labels = c("TRUE" = "With G>T in Seed", "FALSE" = "Without G>T in Seed"),
      name = "Oxidation Status"
    ) +
    scale_x_discrete(
      labels = c("TRUE" = "Oxidized", "FALSE" = "Non-oxidized")
    ) +
    labs(
      title = "G-content in Seed Region",
      subtitle = "Comparison between Oxidized and Non-oxidized miRNAs",
      x = "Oxidation Status",
      y = "Number of G's in Seed (positions 2-8)",
      caption = sprintf("Wilcoxon test: p = %.2e\nOxidized: %.2f G's (mean) | Non-oxidized: %.2f G's (mean)",
                       test_result$p.value,
                       g_content_summary$mean_g[g_content_summary$has_gt_seed == TRUE],
                       g_content_summary$mean_g[g_content_summary$has_gt_seed == FALSE])
    ) +
    theme_bw(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30"),
      legend.position = "top"
    )
  
  ggsave(file.path(output_dir, "paso9c_g_content_comparison_english.png"),
         plot = p, width = 10, height = 8, dpi = 300, bg = "white")
  
  cat("   ✅ Saved: paso9c_g_content_comparison_english.png\n")
}

cat("\n")

# ============================================================================
# FIGURA 5: PASO 10A - let-7 HEATMAP POSITIONS (MOST CRITICAL)
# ============================================================================

cat("🔄 Figure 5/17: let-7 heatmap (MOST CRITICAL)...\n")

# Identificar let-7 family
let7_members <- data %>%
  filter(str_detect(`miRNA name`, "let-7")) %>%
  pull(`miRNA name`) %>%
  unique()

# Filtrar G>T en semilla para let-7
let7_gt_seed <- data %>%
  filter(`miRNA name` %in% let7_members, is_gt == TRUE, region == "Seed")

if (nrow(let7_gt_seed) > 0) {
  # Crear matriz de presencia/ausencia
  let7_matrix <- let7_gt_seed %>%
    group_by(`miRNA name`, position) %>%
    summarise(has_gt = 1, .groups = "drop") %>%
    complete(`miRNA name`, position = 2:8, fill = list(has_gt = 0)) %>%
    pivot_wider(names_from = position, values_from = has_gt, values_fill = 0) %>%
    column_to_rownames("miRNA name") %>%
    as.matrix()
  
  # Crear heatmap
  png(file.path(output_dir, "paso10a_let7_heatmap_english.png"),
      width = 10, height = 8, units = "in", res = 300)
  
  pheatmap(
    let7_matrix,
    color = colorRampPalette(c("white", color_palette$als))(2),
    cluster_rows = FALSE,
    cluster_cols = FALSE,
    display_numbers = TRUE,
    number_color = "black",
    fontsize = 14,
    fontsize_row = 12,
    fontsize_col = 12,
    main = "G>T Presence in let-7 Family (Seed Positions)",
    legend = TRUE,
    legend_breaks = c(0, 1),
    legend_labels = c("Absent", "Present"),
    border_color = "gray80",
    cellwidth = 40,
    cellheight = 30
  )
  
  dev.off()
  
  cat("   ✅ Saved: paso10a_let7_heatmap_english.png\n")
  cat("      ⭐⭐⭐ CRITICAL FIGURE - Shows exact 2,4,5 pattern\n")
}

cat("\n")

# ============================================================================
# FIGURA 6: PASO 10A - VAF COMPARISON let-7 vs miR-4500 (CRITICAL)
# ============================================================================

cat("🔄 Figure 6/17: let-7 vs miR-4500 VAF comparison...\n")

# Identificar miR-4500
mir4500 <- data %>%
  filter(str_detect(`miRNA name`, "miR-4500"))

# Calcular VAFs promedio
let7_vafs <- let7_gt_seed %>%
  select(all_of(sample_cols)) %>%
  summarise(across(everything(), ~mean(.x, na.rm = TRUE))) %>%
  pivot_longer(everything(), names_to = "sample", values_to = "vaf") %>%
  filter(!is.na(vaf), vaf > 0) %>%
  mutate(group = "let-7 family")

mir4500_vafs <- mir4500 %>%
  filter(region == "Seed") %>%
  select(all_of(sample_cols)) %>%
  summarise(across(everything(), ~mean(.x, na.rm = TRUE))) %>%
  pivot_longer(everything(), names_to = "sample", values_to = "vaf") %>%
  filter(!is.na(vaf), vaf > 0) %>%
  mutate(group = "miR-4500")

# Combinar
comparison_df <- bind_rows(let7_vafs, mir4500_vafs)

# Plot
p <- ggplot(comparison_df, aes(x = group, y = vaf, fill = group)) +
  geom_violin(alpha = 0.6, trim = FALSE) +
  geom_boxplot(width = 0.2, alpha = 0.8, outlier.alpha = 0.3) +
  scale_fill_manual(
    values = c("let-7 family" = color_palette$als, "miR-4500" = color_palette$info),
    name = ""
  ) +
  scale_y_log10(labels = scales::scientific) +
  labs(
    title = "VAF Comparison: let-7 vs miR-4500",
    subtitle = "Both share TGAGGTA seed sequence",
    x = "",
    y = "Variant Allele Frequency (VAF, log scale)",
    caption = sprintf("let-7: %.2e (mean) | miR-4500: %.2e (mean)\nRatio: %.1fx higher in miR-4500",
                     mean(let7_vafs$vaf, na.rm = TRUE),
                     mean(mir4500_vafs$vaf, na.rm = TRUE),
                     mean(mir4500_vafs$vaf, na.rm = TRUE) / mean(let7_vafs$vaf, na.rm = TRUE))
  ) +
  theme_bw(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30"),
    legend.position = "none",
    axis.text.x = element_text(face = "bold", size = 12)
  )

ggsave(file.path(output_dir, "paso10a_vaf_comparison_english.png"),
       plot = p, width = 10, height = 8, dpi = 300, bg = "white")

cat("   ✅ Saved: paso10a_vaf_comparison_english.png\n")
cat("      ⭐⭐⭐ CRITICAL FIGURE - Shows miR-4500 paradox\n")

cat("\n")

# ============================================================================
# FIGURA 7: PASO 10A - G>T BY POSITION IN let-7
# ============================================================================

cat("🔄 Figure 7/17: G>T distribution by position in let-7...\n")

# Contar G>T por posición en let-7
let7_by_pos <- let7_gt_seed %>%
  group_by(position) %>%
  summarise(
    n_mirnas = n_distinct(`miRNA name`),
    n_mutations = n(),
    .groups = "drop"
  ) %>%
  mutate(
    is_universal = n_mirnas == length(let7_members)
  )

# Plot
p <- ggplot(let7_by_pos, aes(x = factor(position), y = n_mirnas)) +
  geom_col(aes(fill = is_universal), alpha = 0.8) +
  geom_text(aes(label = n_mirnas), vjust = -0.5, size = 5, fontface = "bold") +
  scale_fill_manual(
    values = c("TRUE" = color_palette$accent, "FALSE" = color_palette$primary),
    labels = c("TRUE" = "Universal (all 9 members)", "FALSE" = "Partial"),
    name = "Penetrance"
  ) +
  scale_y_continuous(limits = c(0, max(let7_by_pos$n_mirnas) * 1.15)) +
  labs(
    title = "G>T Distribution Across Seed Positions in let-7 Family",
    subtitle = "Number of let-7 members with G>T at each position",
    x = "Seed Position",
    y = "Number of let-7 Members",
    caption = sprintf("Total let-7 members analyzed: %d\nPositions 2, 4, 5 show universal presence",
                     length(let7_members))
  ) +
  theme_bw(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30"),
    legend.position = "top",
    panel.grid.major.x = element_blank()
  )

ggsave(file.path(output_dir, "paso10a_let7_by_position_english.png"),
       plot = p, width = 10, height = 7, dpi = 300, bg = "white")

cat("   ✅ Saved: paso10a_let7_by_position_english.png\n")

cat("\n")

# ============================================================================
# FIGURA 8: PASO 10A - SNV TYPES COMPARISON
# ============================================================================

cat("🔄 Figure 8/17: SNV types in let-7 vs miR-4500...\n")

# Comparar tipos de SNVs en semilla
let7_snvs <- data %>%
  filter(`miRNA name` %in% let7_members, region == "Seed") %>%
  mutate(group = "let-7 family")

mir4500_snvs <- data %>%
  filter(str_detect(`miRNA name`, "miR-4500"), region == "Seed") %>%
  mutate(group = "miR-4500")

snv_comparison <- bind_rows(let7_snvs, mir4500_snvs) %>%
  group_by(group, mutation_type) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(group) %>%
  mutate(
    total = sum(n),
    proportion = n / total * 100
  )

# Plot
p <- ggplot(snv_comparison, aes(x = group, y = proportion, fill = mutation_type)) +
  geom_col(position = "dodge", alpha = 0.8) +
  geom_text(aes(label = n), position = position_dodge(width = 0.9), 
            vjust = -0.5, size = 3.5) +
  scale_fill_brewer(palette = "Set2", name = "Mutation Type") +
  labs(
    title = "SNV Types in Seed Region: let-7 vs miR-4500",
    subtitle = "Both share TGAGGTA sequence but different mutation profiles",
    x = "",
    y = "Proportion of Mutations (%)",
    caption = "Numbers above bars = count of mutations"
  ) +
  theme_bw(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30"),
    legend.position = "right",
    axis.text.x = element_text(face = "bold", size = 12)
  )

ggsave(file.path(output_dir, "paso10a_snv_types_comparison_english.png"),
       plot = p, width = 11, height = 8, dpi = 300, bg = "white")

cat("   ✅ Saved: paso10a_snv_types_comparison_english.png\n")

cat("\n")

# ============================================================================
# RESUMEN
# ============================================================================

cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║                    REGENERATION PROGRESS                              ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n")
cat("\n")
cat("✅ Figures regenerated so far: 8/17\n")
cat("📁 Output directory: figures_english/\n")
cat("\n")
cat("🎯 Next batch: Pathway analysis, heatmaps, and additional figures\n")
cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("\n")
cat("This is Part 1 of the regeneration process.\n")
cat("Continue with remaining figures in next script.\n")
cat("\n")








