library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)

# =============================================================================
# ANÁLISIS POR POSICIÓN CON FILTRADO ESTRICTO DE NAs
# =============================================================================

cat("=== ANÁLISIS POR POSICIÓN CON FILTRADO ESTRICTO ===\n\n")

# 1. CARGAR DATOS PROCESADOS
# =============================================================================
cat("1. CARGANDO DATOS PROCESADOS\n")
cat("============================\n")

final_data <- read.csv("../processed_data/final_processed_data.csv", stringsAsFactors = FALSE)

cat("Datos cargados:\n")
cat("  - SNVs:", nrow(final_data), "\n")
cat("  - Muestras:", ncol(final_data) - 2, "\n\n")

# 2. IDENTIFICAR GRUPOS Y COLUMNAS
# =============================================================================
cat("2. IDENTIFICANDO GRUPOS Y COLUMNAS\n")
cat("==================================\n")

sample_cols <- colnames(final_data)[!colnames(final_data) %in% c("miRNA_name", "pos.mut")]

# Identificar grupos
identify_cohort <- function(col_name) {
  if (grepl("control", col_name, ignore.case = TRUE)) {
    return("Control")
  } else if (grepl("ALS", col_name, ignore.case = TRUE)) {
    return("ALS")
  } else {
    return("Unknown")
  }
}

cohorts <- sapply(sample_cols, identify_cohort)

# Separar columnas por grupo
control_cols <- sample_cols[cohorts == "Control"]
als_cols <- sample_cols[cohorts == "ALS"]

cat("Grupos identificados:\n")
cat("  - Control:", length(control_cols), "muestras\n")
cat("  - ALS:", length(als_cols), "muestras\n\n")

# 3. FUNCIÓN DE FILTRADO ESTRICTO
# =============================================================================
cat("3. APLICANDO FILTRADO ESTRICTO\n")
cat("==============================\n")

# Función para filtrar SNVs con suficientes VAFs válidos
filter_valid_snvs <- function(data, sample_cols, min_valid_pct = 0.1) {
  data %>%
    mutate(
      pos = as.integer(str_extract(pos.mut, "^[0-9]+")),
      total_nas = rowSums(is.na(across(all_of(sample_cols)))),
      total_samples = length(sample_cols),
      valid_pct = (total_samples - total_nas) / total_samples,
      n_valid = total_samples - total_nas
    ) %>%
    filter(
      !is.na(pos) &  # No es PM
      valid_pct >= min_valid_pct &  # Al menos min_valid_pct% de muestras válidas
      n_valid >= 2  # Al menos 2 muestras válidas
    )
}

# Aplicar filtrado estricto (10% mínimo de muestras válidas)
filtered_data <- filter_valid_snvs(final_data, sample_cols, min_valid_pct = 0.1)

cat("Filtrado aplicado:\n")
cat("  - SNVs originales:", nrow(final_data), "\n")
cat("  - SNVs después del filtrado:", nrow(filtered_data), "\n")
cat("  - SNVs eliminados:", nrow(final_data) - nrow(filtered_data), "\n")
cat("  - Porcentaje eliminado:", round((nrow(final_data) - nrow(filtered_data)) / nrow(final_data) * 100, 2), "%\n\n")

# 4. ANÁLISIS POR POSICIÓN - CONTROL
# =============================================================================
cat("4. ANÁLISIS POR POSICIÓN - CONTROL\n")
cat("==================================\n")

# Filtrar solo muestras de control
control_data <- filtered_data %>%
  select(miRNA_name, pos.mut, pos, all_of(control_cols))

# Calcular métricas por SNV
control_analysis <- control_data %>%
  mutate(
    n_valid = rowSums(!is.na(across(all_of(control_cols)))),
    mean_vaf = rowMeans(across(all_of(control_cols)), na.rm = TRUE),
    valid_pct = n_valid / length(control_cols)
  ) %>%
  filter(mean_vaf > 0) %>%
  select(miRNA_name, pos.mut, pos, mean_vaf, n_valid, valid_pct)

# Contar por posición
pos_control <- control_analysis %>%
  count(pos, name = "n_control")

cat("SNVs por posición en Control (después del filtrado):\n")
print(head(pos_control, 10))

# 5. ANÁLISIS POR POSICIÓN - ALS
# =============================================================================
cat("\n5. ANÁLISIS POR POSICIÓN - ALS\n")
cat("==============================\n")

# Filtrar solo muestras de ALS
als_data <- filtered_data %>%
  select(miRNA_name, pos.mut, pos, all_of(als_cols))

# Calcular métricas por SNV
als_analysis <- als_data %>%
  mutate(
    n_valid = rowSums(!is.na(across(all_of(als_cols)))),
    mean_vaf = rowMeans(across(all_of(als_cols)), na.rm = TRUE),
    valid_pct = n_valid / length(als_cols)
  ) %>%
  filter(mean_vaf > 0) %>%
  select(miRNA_name, pos.mut, pos, mean_vaf, n_valid, valid_pct)

# Contar por posición
pos_als <- als_analysis %>%
  count(pos, name = "n_als")

cat("SNVs por posición en ALS (después del filtrado):\n")
print(head(pos_als, 10))

# 6. COMPARACIÓN ESTADÍSTICA POR POSICIÓN
# =============================================================================
cat("\n6. COMPARACIÓN ESTADÍSTICA POR POSICIÓN\n")
cat("=======================================\n")

# Unir datos de ambos grupos
pos_comparison <- full_join(pos_control, pos_als, by = "pos") %>%
  replace_na(list(n_control = 0, n_als = 0)) %>%
  mutate(
    total_control = sum(n_control),
    total_als = sum(n_als),
    frac_control = n_control / total_control,
    frac_als = n_als / total_als
  )

# Test de Fisher para cada posición
pos_comparison <- pos_comparison %>%
  rowwise() %>%
  mutate(
    p_value = tryCatch({
      fisher.test(
        matrix(
          c(n_als, total_als - n_als, n_control, total_control - n_control),
          nrow = 2
        )
      )$p.value
    }, error = function(e) NA)
  ) %>%
  ungroup() %>%
  mutate(
    p_adj = p.adjust(p_value, method = "BH"),
    significant = p_adj < 0.05
  )

cat("Comparación por posición (después del filtrado):\n")
print(pos_comparison)

# 7. CREAR GRÁFICO POR POSICIÓN
# =============================================================================
cat("\n7. CREANDO GRÁFICO POR POSICIÓN\n")
cat("===============================\n")

# Preparar datos para el gráfico
plot_data <- pos_comparison %>%
  select(pos, frac_control, frac_als, p_adj) %>%
  pivot_longer(
    cols = c(frac_control, frac_als),
    names_to = "group",
    values_to = "fraction"
  ) %>%
  mutate(
    group = recode(group,
                   frac_control = "Control",
                   frac_als = "ALS")
  )

# Nivel máximo para la sombra
ymax <- max(plot_data$fraction, na.rm = TRUE) * 1.1

# Crear gráfico
p <- ggplot(plot_data, aes(x = pos, y = fraction, fill = group)) +
  # Sombra de la región seed (pos 2-8)
  annotate(
    "rect",
    xmin = 2 - 0.5, xmax = 8 + 0.5,
    ymin = 0, ymax = ymax,
    fill = "grey80", alpha = 0.3
  ) +
  # Barras lado a lado
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  # Asteriscos para posiciones significativas
  geom_text(
    data = filter(plot_data, group == "ALS" & p_adj < 0.05),
    aes(label = "*"),
    position = position_nudge(x = 0.2),
    vjust = -0.5, size = 5, color = "black"
  ) +
  scale_x_continuous(
    breaks = 1:25,
    minor_breaks = NULL
  ) +
  scale_fill_manual(values = c("Control" = "grey60", "ALS" = "#D62728")) +
  labs(
    x = "Posición en miRNA",
    y = "Fracción posicional",
    fill = "Grupo",
    title = "Distribución de mutaciones G>T por posición: Control vs ALS (Filtrado Estricto)",
    subtitle = "Región seed sombreada (pos 2-8), *p_adj<0.05, min 10% muestras válidas"
  ) +
  coord_cartesian(ylim = c(0, ymax)) +
  theme_classic(base_size = 14) +
  theme(
    axis.text.x = element_text(size = 10),
    legend.position = c(0.8, 0.9)
  )

# Guardar gráfico
ggsave("distribucion_por_posicion_filtrado.pdf", p, width = 12, height = 8)

cat("Gráfico guardado: distribucion_por_posicion_filtrado.pdf\n\n")

# 8. ANÁLISIS DE REGIÓN SEED
# =============================================================================
cat("8. ANÁLISIS DE REGIÓN SEED\n")
cat("==========================\n")

# Definir región seed (posiciones 2-8)
seed_positions <- 2:8

# Calcular métricas para región seed
seed_analysis <- pos_comparison %>%
  mutate(
    is_seed = pos %in% seed_positions,
    region = ifelse(is_seed, "Seed", "Non-seed")
  ) %>%
  group_by(region) %>%
  summarise(
    total_control = sum(n_control),
    total_als = sum(n_als),
    frac_control = sum(frac_control),
    frac_als = sum(frac_als),
    .groups = 'drop'
  )

cat("Análisis de región seed (después del filtrado):\n")
print(seed_analysis)

# Test de Fisher para región seed vs non-seed
if (nrow(seed_analysis) == 2) {
  seed_fisher <- fisher.test(
    matrix(
      c(
        seed_analysis$total_als[seed_analysis$region == "Seed"],
        seed_analysis$total_als[seed_analysis$region == "Non-seed"],
        seed_analysis$total_control[seed_analysis$region == "Seed"],
        seed_analysis$total_control[seed_analysis$region == "Non-seed"]
      ),
      nrow = 2
    )
  )
  
  cat("\nTest de Fisher para región seed vs non-seed:\n")
  cat("  - p-value:", round(seed_fisher$p.value, 6), "\n")
  cat("  - OR:", round(seed_fisher$estimate, 4), "\n\n")
}

# 9. COMPARAR CON ANÁLISIS SIN FILTRADO
# =============================================================================
cat("9. COMPARACIÓN CON ANÁLISIS SIN FILTRADO\n")
cat("========================================\n")

# Análisis sin filtrado estricto
unfiltered_control <- final_data %>%
  mutate(pos = as.integer(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(!is.na(pos)) %>%
  count(pos, name = "n_control_unfiltered")

unfiltered_als <- final_data %>%
  mutate(pos = as.integer(str_extract(pos.mut, "^[0-9]+"))) %>%
  filter(!is.na(pos)) %>%
  count(pos, name = "n_als_unfiltered")

comparison <- full_join(
  pos_comparison %>% select(pos, n_control, n_als),
  full_join(unfiltered_control, unfiltered_als, by = "pos"),
  by = "pos"
) %>%
  replace_na(list(n_control = 0, n_als = 0, n_control_unfiltered = 0, n_als_unfiltered = 0)) %>%
  mutate(
    control_reduction = n_control_unfiltered - n_control,
    als_reduction = n_als_unfiltered - n_als,
    control_pct_reduction = (control_reduction / n_control_unfiltered) * 100,
    als_pct_reduction = (als_reduction / n_als_unfiltered) * 100
  )

cat("Comparación de SNVs por posición (filtrado vs sin filtrar):\n")
print(head(comparison, 10))

# 10. GUARDAR RESULTADOS
# =============================================================================
cat("\n10. GUARDANDO RESULTADOS\n")
cat("========================\n")

# Guardar análisis por posición
write.csv(pos_comparison, "analisis_por_posicion_filtrado.csv", row.names = FALSE)

# Guardar análisis de región seed
write.csv(seed_analysis, "analisis_region_seed_filtrado.csv", row.names = FALSE)

# Guardar comparación
write.csv(comparison, "comparacion_filtrado_vs_sin_filtrar.csv", row.names = FALSE)

cat("Archivos guardados:\n")
cat("  - analisis_por_posicion_filtrado.csv\n")
cat("  - analisis_region_seed_filtrado.csv\n")
cat("  - comparacion_filtrado_vs_sin_filtrar.csv\n")
cat("  - distribucion_por_posicion_filtrado.pdf\n\n")

cat("=== ANÁLISIS CON FILTRADO ESTRICTO COMPLETADO ===\n")









