#!/usr/bin/env Rscript

# =============================================================================
# PASO 4A: GRÁFICO VAF COMPARATIVO
# =============================================================================

library(dplyr)
library(readr)
library(stringr)
library(tidyr)
library(ggplot2)

cat("=== PASO 4A: GRÁFICO VAF COMPARATIVO ===\n\n")

# --- Cargar datos procesados ---
cat("Cargando datos procesados...\n")

# Cargar datos originales
df_main <- read_tsv("results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt", show_col_types = FALSE)
df_main <- df_main[-1, ]  # Remover metadatos

sample_cols <- names(df_main)[!names(df_main) %in% c("miRNA name", "pos:mut")]
als_samples <- sample_cols[str_detect(sample_cols, "Magen-ALS")]
control_samples <- sample_cols[str_detect(sample_cols, "Magen-control")]

# Aplicar split y collapse
split_mutations <- function(row_data) {
  pos_mut <- row_data$`pos:mut`
  mutations <- str_split(pos_mut, ",")[[1]]
  mutations <- str_trim(mutations)
  
  if (length(mutations) == 1) {
    return(row_data)
  } else {
    result_rows <- list()
    for (mut in mutations) {
      new_row <- row_data
      new_row$`pos:mut` <- mut
      result_rows[[length(result_rows) + 1]] <- new_row
    }
    return(bind_rows(result_rows))
  }
}

df_split_list <- list()
for (i in 1:nrow(df_main)) {
  split_result <- split_mutations(df_main[i, ])
  df_split_list[[length(df_split_list) + 1]] <- split_result
}
df_split <- bind_rows(df_split_list)

df_collapsed <- df_split %>%
  group_by(`miRNA name`, `pos:mut`) %>%
  summarise(
    across(all_of(sample_cols), ~ sum(as.numeric(.x), na.rm = TRUE)),
    .groups = "drop"
  )

# Aplicar filtro de representación
df_long <- df_collapsed %>%
  pivot_longer(
    cols = all_of(sample_cols),
    names_to = "sample",
    values_to = "count"
  ) %>%
  mutate(count = as.numeric(count))

high_rep_snvs <- df_long %>%
  group_by(`miRNA name`, `pos:mut`) %>%
  summarise(
    samples_with_count = sum(count > 0, na.rm = TRUE),
    frac_present = samples_with_count / length(sample_cols),
    .groups = "drop"
  ) %>%
  filter(frac_present > 0.5) %>%
  mutate(snv_id = paste(`miRNA name`, `pos:mut`, sep = "_"))

df_long$snv_id <- paste(df_long$`miRNA name`, df_long$`pos:mut`, sep = "_")
df_filtered_long <- df_long %>%
  mutate(
    count_filtered = ifelse(snv_id %in% high_rep_snvs$snv_id, NA_real_, count)
  )

# Filtrar solo G>T y calcular VAFs
df_gt_filtered <- df_filtered_long %>%
  filter(str_detect(`pos:mut`, "GT")) %>%
  mutate(
    group = ifelse(str_detect(sample, "Magen-ALS"), "ALS", "Control")
  )

vaf_summary <- df_gt_filtered %>%
  group_by(`miRNA name`, `pos:mut`, group) %>%
  summarise(
    mean_vaf = mean(count_filtered, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = group,
    values_from = mean_vaf,
    names_prefix = "mean_vaf_"
  ) %>%
  mutate(
    mean_vaf_ALS = replace_na(mean_vaf_ALS, 0),
    mean_vaf_Control = replace_na(mean_vaf_Control, 0),
    vaf_difference = mean_vaf_ALS - mean_vaf_Control
  )

cat(paste0("  - SNVs G>T procesados: ", nrow(vaf_summary), "\n"))

# --- Crear gráfico VAF comparativo ---
cat("\nCreando gráfico VAF comparativo...\n")

# Preparar datos para el gráfico (top 20 por diferencia)
plot_data <- vaf_summary %>%
  arrange(desc(vaf_difference)) %>%
  head(20) %>%
  mutate(
    snv_label = paste(`miRNA name`, `pos:mut`, sep = " "),
    snv_label = str_wrap(snv_label, width = 25)
  )

# Gráfico de barras comparativo
p1 <- ggplot(plot_data, aes(x = reorder(snv_label, vaf_difference))) +
  geom_col(aes(y = mean_vaf_ALS), fill = "#E31A1C", alpha = 0.7, width = 0.4, position = position_nudge(x = -0.2)) +
  geom_col(aes(y = mean_vaf_Control), fill = "#1F78B4", alpha = 0.7, width = 0.4, position = position_nudge(x = 0.2)) +
  coord_flip() +
  labs(
    title = "Top 20 SNVs G>T: VAF Promedio ALS vs Control",
    subtitle = "Después del filtro de representación (VAF > 50% → NaN)",
    x = "SNV (miRNA + Posición:Mutación)",
    y = "VAF Promedio",
    caption = "Rojo: ALS, Azul: Control"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 10),
    axis.text.y = element_text(size = 8),
    plot.caption = element_text(size = 9, hjust = 0)
  )

# Guardar gráfico
ggsave("outputs/final_paper_graphs/vaf_comparison_after_filter.pdf", p1, 
       width = 12, height = 8, dpi = 300)

cat("  ✅ Gráfico VAF comparativo guardado: vaf_comparison_after_filter.pdf\n")

# --- Mostrar top 5 SNVs ---
cat("\nTop 5 SNVs G>T por diferencia de VAF:\n")
print(plot_data %>% 
      select(`miRNA name`, `pos:mut`, mean_vaf_ALS, mean_vaf_Control, vaf_difference) %>%
      head(5))

cat("\n=== PASO 4A COMPLETADO ===\n")










