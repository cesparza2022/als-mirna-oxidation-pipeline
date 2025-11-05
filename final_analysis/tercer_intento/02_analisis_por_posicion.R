library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)

# =============================================================================
# ANÁLISIS POR POSICIÓN - CONTROL vs ALS
# =============================================================================

cat("=== ANÁLISIS POR POSICIÓN - CONTROL vs ALS ===\n\n")

# 1. CARGAR DATOS PROCESADOS
# =============================================================================
cat("1. CARGANDO DATOS PROCESADOS\n")
cat("============================\n")

# Cargar datos finales procesados
final_data <- read.csv("../processed_data/final_processed_data.csv", stringsAsFactors = FALSE)

cat("Datos cargados:\n")
cat("  - SNVs:", nrow(final_data), "\n")
cat("  - miRNAs:", length(unique(final_data$miRNA_name)), "\n")
cat("  - Muestras:", ncol(final_data) - 2, "\n\n")

# 2. IDENTIFICAR GRUPOS Y COLUMNAS
# =============================================================================
cat("2. IDENTIFICANDO GRUPOS Y COLUMNAS\n")
cat("==================================\n")

# Obtener columnas de muestras
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

# 3. CALCULAR LIBRARY SIZE POR MUESTRA
# =============================================================================
cat("3. CALCULANDO LIBRARY SIZE POR MUESTRA\n")
cat("======================================\n")

# Para calcular RPM, necesitamos el library size total por muestra
# Esto se calcula sumando todas las columnas de total (PM+1MM+2MM)
# Pero en nuestros datos procesados, solo tenemos las columnas de VAF

# Necesitamos volver a los datos originales para obtener los totales
cat("Nota: Para calcular RPM correctamente, necesitamos los datos originales con columnas de total\n")
cat("Por ahora, usaremos una aproximación con los datos disponibles...\n\n")

# 4. FUNCIÓN PARA CALCULAR RPM (APROXIMACIÓN)
# =============================================================================
cat("4. CALCULANDO RPM (APROXIMACIÓN)\n")
cat("================================\n")

# Función para calcular RPM aproximado
# Como no tenemos los totales originales, usaremos una aproximación
calculate_rpm_approximation <- function(data, sample_cols, group_name) {
  # Crear dataframe con posiciones extraídas
  df_pos <- data %>%
    mutate(
      pos = as.integer(str_extract(pos.mut, "^[0-9]+")),
      clean_mut = str_replace(pos.mut, ":", "_"),
      featureID = paste(miRNA_name, clean_mut, sep = "_")
    ) %>%
    filter(!is.na(pos))  # Filtrar filas PM
  
  # Para cada muestra, calcular RPM aproximado
  rpm_data <- df_pos[, c("miRNA_name", "pos.mut", "pos", "featureID")]
  
  for (col in sample_cols) {
    # VAF = count / total, entonces count = VAF * total
    # RPM = count / library_size * 1e6
    # Aproximación: RPM ≈ VAF * factor_escala
    vaf_values <- data[[col]]
    
    # Filtrar NAs (VAFs > 0.5 que se convirtieron a NaN)
    valid_vaf <- !is.na(vaf_values) & vaf_values > 0
    
    # Usar VAF como proxy para RPM (esto es una aproximación)
    # En un análisis real, necesitaríamos los totales originales
    rpm_values <- ifelse(valid_vaf, vaf_values * 1e6, NA)
    
    rpm_data[[paste0(col, "_RPM")]] <- rpm_values
  }
  
  return(rpm_data)
}

# Calcular RPM para cada grupo
control_rpm <- calculate_rpm_approximation(final_data, control_cols, "Control")
als_rpm <- calculate_rpm_approximation(final_data, als_cols, "ALS")

cat("RPM calculado para:\n")
cat("  - Control:", nrow(control_rpm), "SNVs\n")
cat("  - ALS:", nrow(als_rpm), "SNVs\n\n")

# 5. ANÁLISIS POR POSICIÓN - CONTROL
# =============================================================================
cat("5. ANÁLISIS POR POSICIÓN - CONTROL\n")
cat("==================================\n")

# Obtener columnas RPM para control
control_rpm_cols <- grep("_RPM$", colnames(control_rpm), value = TRUE)

# Calcular promedio de RPM por SNV
control_analysis <- control_rpm %>%
  mutate(
    avr_raw = rowMeans(across(all_of(control_rpm_cols)), na.rm = TRUE),
    n_valid_samples = rowSums(!is.na(across(all_of(control_rpm_cols))))
  ) %>%
  filter(avr_raw > 0 & n_valid_samples > 0) %>%  # Solo SNVs con al menos una muestra válida
  mutate(avr = log2(avr_raw + 1)) %>%
  select(featureID, miRNA_name, pos, avr, n_valid_samples)

# Contar por posición
pos_control <- control_analysis %>%
  count(pos, name = "n_control")

cat("SNVs por posición en Control:\n")
print(head(pos_control, 10))

# 6. ANÁLISIS POR POSICIÓN - ALS
# =============================================================================
cat("\n6. ANÁLISIS POR POSICIÓN - ALS\n")
cat("==============================\n")

# Obtener columnas RPM para ALS
als_rpm_cols <- grep("_RPM$", colnames(als_rpm), value = TRUE)

# Calcular promedio de RPM por SNV
als_analysis <- als_rpm %>%
  mutate(
    avr_raw = rowMeans(across(all_of(als_rpm_cols)), na.rm = TRUE),
    n_valid_samples = rowSums(!is.na(across(all_of(als_rpm_cols))))
  ) %>%
  filter(avr_raw > 0 & n_valid_samples > 0) %>%  # Solo SNVs con al menos una muestra válida
  mutate(avr = log2(avr_raw + 1)) %>%
  select(featureID, miRNA_name, pos, avr, n_valid_samples)

# Contar por posición
pos_als <- als_analysis %>%
  count(pos, name = "n_als")

cat("SNVs por posición en ALS:\n")
print(head(pos_als, 10))

# 7. COMPARACIÓN ESTADÍSTICA POR POSICIÓN
# =============================================================================
cat("\n7. COMPARACIÓN ESTADÍSTICA POR POSICIÓN\n")
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

cat("Comparación por posición:\n")
print(pos_comparison)

# 8. CREAR GRÁFICO POR POSICIÓN
# =============================================================================
cat("\n8. CREANDO GRÁFICO POR POSICIÓN\n")
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
    fill = "grey80", alpha = 0.3, inherit.aes = FALSE
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
    title = "Distribución de mutaciones G>T por posición: Control vs ALS",
    subtitle = "Región seed sombreada (pos 2-8), *p_adj<0.05"
  ) +
  coord_cartesian(ylim = c(0, ymax)) +
  theme_classic(base_size = 14) +
  theme(
    axis.text.x = element_text(size = 10),
    legend.position = c(0.8, 0.9)
  )

# Guardar gráfico
ggsave("distribucion_por_posicion.pdf", p, width = 12, height = 8)

cat("Gráfico guardado: distribucion_por_posicion.pdf\n\n")

# 9. ANÁLISIS DE REGIÓN SEED
# =============================================================================
cat("9. ANÁLISIS DE REGIÓN SEED\n")
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

cat("Análisis de región seed:\n")
print(seed_analysis)

# Test de Fisher para región seed vs non-seed
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

# 10. GUARDAR RESULTADOS
# =============================================================================
cat("10. GUARDANDO RESULTADOS\n")
cat("========================\n")

# Guardar análisis por posición
write.csv(pos_comparison, "analisis_por_posicion.csv", row.names = FALSE)

# Guardar análisis de región seed
write.csv(seed_analysis, "analisis_region_seed.csv", row.names = FALSE)

cat("Archivos guardados:\n")
cat("  - analisis_por_posicion.csv\n")
cat("  - analisis_region_seed.csv\n")
cat("  - distribucion_por_posicion.pdf\n\n")

cat("=== ANÁLISIS POR POSICIÓN COMPLETADO ===\n")
