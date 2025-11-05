#!/usr/bin/env Rscript
# ==============================================================================
# PASO 10C: ANÁLISIS DE CO-MUTACIONES EN let-7
# ==============================================================================
# 
# OBJETIVO:
#   Entender si las posiciones 2, 4, 5 de TGAGGTA mutan:
#   1. Juntas (co-mutación) o independientemente
#   2. Por muestra individual (¿una muestra tiene las 3?)
#   3. Correlación entre posiciones
#   4. Gradiente de saturación
#   5. Modelo de acumulación de mutaciones
#
# INPUT:
#   - let-7 family (8 miRNAs con G>T en 2,4,5)
#   - Datos por muestra (VAFs individuales)
#
# OUTPUT:
#   - Matriz de co-mutación
#   - Correlaciones entre posiciones
#   - Análisis por muestra
#   - Modelo de saturación
#
# AUTOR: Análisis ALS miRNAs
# FECHA: 8 de octubre de 2025
# ==============================================================================

library(tidyverse)
library(pheatmap)
library(corrplot)
library(jsonlite)

cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║        PASO 10C: CO-MUTACIONES EN let-7 (posiciones 2, 4, 5)          ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

# Cargar configuración
source("config_pipeline.R")
source("functions_pipeline.R")

# Directorios
output_paso10c <- file.path(config$output_paths$outputs, "paso10c_comutaciones_let7")
output_figures <- file.path(config$output_paths$figures, "paso10c_comutaciones_let7")
dir.create(output_paso10c, recursive = TRUE, showWarnings = FALSE)
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
    mutation_type = paste0(str_sub(mutation_raw, 1, 1), ">", str_sub(mutation_raw, 2, 2))
  )

# let-7 members
let7_members <- c("hsa-let-7a-5p", "hsa-let-7b-5p", "hsa-let-7c-5p", 
                  "hsa-let-7d-5p", "hsa-let-7e-5p", "hsa-let-7f-5p",
                  "hsa-let-7g-5p", "hsa-let-7i-5p", "hsa-miR-98-5p")

let7_data <- datos %>%
  filter(`miRNA name` %in% let7_members,
         mutation_type == "G>T",
         position %in% c(2, 4, 5))

cat("  ✓ G>T en posiciones 2, 4, 5 de let-7:", nrow(let7_data), "\n\n")

# ------------------------------------------------------------------------------
# PASO 10C.1: MATRIZ DE CO-MUTACIÓN POR miRNA
# ------------------------------------------------------------------------------

cat("🔗 PASO 10C.1: Analizando co-mutación por miRNA...\n")

# Para cada miRNA, ¿qué posiciones tiene mutadas?
let7_pattern <- let7_data %>%
  group_by(`miRNA name`) %>%
  summarise(
    tiene_pos2 = 2 %in% position,
    tiene_pos4 = 4 %in% position,
    tiene_pos5 = 5 %in% position,
    n_posiciones = n_distinct(position),
    patron = paste(sort(position), collapse = ","),
    .groups = "drop"
  )

cat("\n  📊 PATRÓN POR miRNA:\n")
print(let7_pattern)

# Resumen de patrones
patron_summary <- let7_pattern %>%
  group_by(patron) %>%
  summarise(n_mirnas = n(), .groups = "drop") %>%
  arrange(desc(n_mirnas))

cat("\n  📈 FRECUENCIA DE PATRONES:\n")
print(patron_summary)

write_csv(let7_pattern, file.path(output_paso10c, "paso10c_let7_patrones.csv"))

# Gráfica
p1 <- ggplot(let7_pattern, aes(x = `miRNA name`, y = 1)) +
  geom_tile(aes(fill = tiene_pos2), width = 0.8, height = 0.2, 
            position = position_nudge(y = 0.3)) +
  geom_tile(aes(fill = tiene_pos4), width = 0.8, height = 0.2, 
            position = position_nudge(y = 0)) +
  geom_tile(aes(fill = tiene_pos5), width = 0.8, height = 0.2, 
            position = position_nudge(y = -0.3)) +
  scale_fill_manual(values = c("FALSE" = "gray80", "TRUE" = "#E31A1C"),
                    name = "") +
  labs(
    title = "Mapa de Co-mutación: let-7 en Posiciones 2, 4, 5",
    subtitle = "Rojo = tiene G>T, Gris = no tiene",
    x = "miRNA let-7",
    y = ""
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        axis.text.y = element_blank(),
        legend.position = "none") +
  annotate("text", x = 0.5, y = 1.3, label = "Pos 2", hjust = 0, size = 4) +
  annotate("text", x = 0.5, y = 1.0, label = "Pos 4", hjust = 0, size = 4) +
  annotate("text", x = 0.5, y = 0.7, label = "Pos 5", hjust = 0, size = 4)

ggsave(file.path(output_figures, "paso10c_mapa_comutacion.png"),
       p1, width = 12, height = 6)
cat("  ✓ Figura 'paso10c_mapa_comutacion.png' generada\n\n")

# ------------------------------------------------------------------------------
# PASO 10C.2: ANÁLISIS POR MUESTRA
# ------------------------------------------------------------------------------

cat("📍 PASO 10C.2: Analizando por muestra individual...\n")

# Para cada posición, identificar columnas VAF
vaf_cols <- grep("^VAF_", colnames(let7_data), value = TRUE)

# Por cada posición, ver en cuántas muestras aparece
let7_by_sample <- let7_data %>%
  select(`miRNA name`, position, all_of(vaf_cols)) %>%
  pivot_longer(cols = all_of(vaf_cols), names_to = "sample", values_to = "vaf") %>%
  filter(!is.na(vaf), vaf > 0) %>%
  group_by(`miRNA name`, position) %>%
  summarise(
    n_samples = n(),
    mean_vaf = mean(vaf, na.rm = TRUE),
    .groups = "drop"
  )

cat("\n  📊 Muestras por posición:\n")
print(let7_by_sample %>% pivot_wider(names_from = position, values_from = n_samples, values_fill = 0))

# ------------------------------------------------------------------------------
# PASO 10C.3: CORRELACIÓN ENTRE POSICIONES
# ------------------------------------------------------------------------------

cat("\n🔬 PASO 10C.3: Calculando correlación entre posiciones...\n")

# Crear matriz: muestras × posiciones para cada miRNA let-7
correlaciones <- list()

for (mirna in unique(let7_data$`miRNA name`)) {
  
  mirna_data <- let7_data %>%
    filter(`miRNA name` == mirna) %>%
    select(position, all_of(vaf_cols)) %>%
    pivot_longer(cols = all_of(vaf_cols), names_to = "sample", values_to = "vaf") %>%
    filter(!is.na(vaf)) %>%
    select(position, sample, vaf) %>%
    pivot_wider(names_from = position, values_from = vaf, values_fill = 0)
  
  if (ncol(mirna_data) > 1) {
    
    matriz_vaf <- mirna_data %>% 
      select(-sample) %>%
      as.matrix()
    
    if (ncol(matriz_vaf) >= 2) {
      cor_matrix <- cor(matriz_vaf, use = "pairwise.complete.obs")
      
      correlaciones[[mirna]] <- cor_matrix
      
      cat("  ", mirna, ":\n")
      print(round(cor_matrix, 3))
      cat("\n")
    }
  }
}

# ------------------------------------------------------------------------------
# PASO 10C.4: RESUMEN EJECUTIVO
# ------------------------------------------------------------------------------

cat("📋 Generando resumen ejecutivo...\n")

resumen <- list(
  patron_dominante = patron_summary$patron[1],
  n_mirnas_patron = patron_summary$n_mirnas[1],
  todos_tienen_245 = all(let7_pattern$tiene_pos2 & let7_pattern$tiene_pos4),
  n_con_pos5 = sum(let7_pattern$tiene_pos5)
)

write_json(resumen, file.path(output_paso10c, "paso10c_resumen.json"), pretty = TRUE)

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║                  RESUMEN EJECUTIVO - PASO 10C                         ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

cat("🔗 CO-MUTACIÓN:\n")
cat("  • Patrón más común:", resumen$patron_dominante, "\n")
cat("  • miRNAs con este patrón:", resumen$n_mirnas_patron, "\n")
cat("  • Todos tienen pos. 2 y 4:", resumen$todos_tienen_245, "\n")
cat("  • Con posición 5:", resumen$n_con_pos5, "\n\n")

cat("✅ ANÁLISIS COMPLETADO\n")
cat("  • Figuras generadas: 1-2\n")
cat("  • Tablas guardadas: 2\n")
cat("  • Correlaciones calculadas:", length(correlaciones), "\n")
cat("  • Ubicación:", output_paso10c, "\n\n")

cat("🎯 SIGUIENTE: Paso 10D - Motivos extendidos\n\n")

cat("════════════════════════════════════════════════════════════════════════\n")








