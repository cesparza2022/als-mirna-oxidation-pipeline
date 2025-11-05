# =============================================================================
# PASO 1B: ANÁLISIS DETALLADO DE miRNAs
# =============================================================================
# Autor: César Esparza
# Fecha: 2024
# Descripción: Análisis detallado de miRNAs después de transformaciones
# =============================================================================

# Cargar librerías
library(tidyverse)
library(ggplot2)

cat("=== PASO 1B: ANÁLISIS DETALLADO DE miRNAs ===\n")
cat("Fecha:", Sys.time(), "\n\n")

# =============================================================================
# CARGAR DATOS PROCESADOS
# =============================================================================

cat("Cargando datos procesados...\n")
processed_data <- read_csv("tables/datos_procesados_split_collapse.csv")

cat("Datos cargados:\n")
cat("  - Filas:", nrow(processed_data), "\n")
cat("  - miRNAs únicos:", length(unique(processed_data$`miRNA name`)), "\n")

# =============================================================================
# ANÁLISIS POR miRNA
# =============================================================================

cat("\nAnalizando miRNAs...\n")

# Análisis básico por miRNA
mirna_analysis <- processed_data %>%
  group_by(`miRNA name`) %>%
  summarise(
    total_snvs = n(),
    posiciones_unicas = n_distinct(str_extract(`pos:mut`, "^\\d+")),
    mutaciones_unicas = n_distinct(`pos:mut`),
    gt_mutations = sum(grepl(":GT", `pos:mut`)),
    gt_percentage = round(sum(grepl(":GT", `pos:mut`)) / n() * 100, 2),
    .groups = "drop"
  ) %>%
  arrange(desc(total_snvs))

cat("Análisis por miRNA completado:\n")
cat("  - miRNAs analizados:", nrow(mirna_analysis), "\n")
cat("  - miRNA con más SNVs:", mirna_analysis$`miRNA name`[1], "(", mirna_analysis$total_snvs[1], "SNVs)\n")

# =============================================================================
# ANÁLISIS DE REGIONES FUNCIONALES
# =============================================================================

cat("\nAnalizando regiones funcionales...\n")

# Definir regiones funcionales
region_analysis <- processed_data %>%
  mutate(
    position = as.numeric(str_extract(`pos:mut`, "^\\d+")),
    region = case_when(
      position >= 2 & position <= 8 ~ "Semilla",
      position >= 9 & position <= 15 ~ "Central",
      position >= 16 & position <= 22 ~ "3'",
      TRUE ~ "Otro"
    )
  ) %>%
  group_by(region) %>%
  summarise(
    total_snvs = n(),
    mirnas_afectados = n_distinct(`miRNA name`),
    posiciones_unicas = n_distinct(position),
    gt_mutations = sum(grepl(":GT", `pos:mut`)),
    gt_percentage = round(sum(grepl(":GT", `pos:mut`)) / n() * 100, 2),
    .groups = "drop"
  ) %>%
  mutate(porcentaje_total = round(total_snvs / sum(total_snvs) * 100, 2))

cat("Análisis por región completado:\n")
print(region_analysis)

# =============================================================================
# GUARDAR RESULTADOS
# =============================================================================

cat("\nGuardando resultados...\n")
write_csv(mirna_analysis, "tables/analisis_mirnas_detallado.csv")
write_csv(region_analysis, "tables/analisis_regiones_funcionales.csv")

# =============================================================================
# GENERAR VISUALIZACIONES BÁSICAS
# =============================================================================

cat("\nGenerando visualizaciones...\n")

# 1. Top 10 miRNAs con más SNVs
top_mirnas <- head(mirna_analysis, 10)
p1 <- ggplot(top_mirnas, aes(x = reorder(`miRNA name`, total_snvs), y = total_snvs, fill = total_snvs)) +
  geom_col(alpha = 0.8) +
  coord_flip() +
  labs(title = "Top 10 miRNAs con más SNVs",
       x = "miRNA", y = "Número de SNVs") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 8)) +
  scale_fill_gradient(low = "lightblue", high = "darkblue")

ggsave("figures/top_10_mirnas_snvs.png", p1, width = 10, height = 6, dpi = 300)

# 2. Distribución por regiones funcionales
p2 <- ggplot(region_analysis, aes(x = region, y = total_snvs, fill = region)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = paste0(total_snvs, "\n(", porcentaje_total, "%)")), 
            vjust = -0.5, size = 4) +
  labs(title = "Distribución de SNVs por Región Funcional",
       x = "Región", y = "Número de SNVs") +
  theme_minimal() +
  theme(legend.position = "none") +
  scale_fill_brewer(palette = "Set1")

ggsave("figures/snvs_por_region_funcional.png", p2, width = 10, height = 6, dpi = 300)

# =============================================================================
# RESUMEN
# =============================================================================

cat("\n=== PASO 1B COMPLETADO ===\n")
cat("Archivos generados:\n")
cat("  - 2 archivos CSV con análisis\n")
cat("  - 2 archivos PNG con visualizaciones\n")
cat("\nResumen de miRNAs:\n")
cat("  - Total miRNAs:", nrow(mirna_analysis), "\n")
cat("  - miRNA con más SNVs:", mirna_analysis$`miRNA name`[1], "(", mirna_analysis$total_snvs[1], "SNVs)\n")
cat("  - miRNA con más G>T:", mirna_analysis$`miRNA name`[which.max(mirna_analysis$gt_mutations)], 
    "(", max(mirna_analysis$gt_mutations), "mutaciones G>T)\n")
cat("\nPaso 1B completado exitosamente!\n")








