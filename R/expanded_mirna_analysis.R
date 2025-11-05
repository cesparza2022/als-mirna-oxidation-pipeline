#' Análisis Expandido de miRNAs - Top 10% por Cuentas vs VAF
#' 
#' Este script implementa un análisis más amplio para identificar miRNAs
#' más significativos usando dos métodos: cuentas totales vs VAF promedio

library(dplyr)
library(ggplot2)
library(stringr)
library(tidyr)
library(purrr)
library(readr)
library(tibble)
library(pheatmap)
library(RColorBrewer)
library(viridis)
library(gridExtra)

# Cargar datos directamente
cat("📊 Cargando datos miRNA...\n")
df <- read.delim("results/miRNA_count.Q38.txt", sep = "\t", stringsAsFactors = FALSE)
cat("✅ Datos cargados. Dimensiones:", nrow(df), "x", ncol(df), "\n")

# Identificar columnas
meta_cols <- c("miRNA.name", "pos.mut")
snv_cols <- names(df)[str_detect(names(df), "second_trim_rCMC_cont_IP|second_trim_rCMC_PE_IP") & 
                      !str_detect(names(df), "PM\\.1MM\\.2MM")]
total_cols <- names(df)[str_detect(names(df), "PM\\.1MM\\.2MM")]

cat("📊 Columnas identificadas:\n")
cat("   - Meta:", paste(meta_cols, collapse = ", "), "\n")
cat("   - SNV:", paste(snv_cols, collapse = ", "), "\n")
cat("   - Total:", paste(total_cols, collapse = ", "), "\n")

# Filtrar mutaciones G>T
df_gt_mutations <- df %>%
  dplyr::filter(pos.mut != "PM") %>%
  dplyr::filter(str_detect(pos.mut, "GT"))

cat("✅ Total de mutaciones G>T:", nrow(df_gt_mutations), "\n")

# Función para calcular VAF
calculate_vaf <- function(df_mutations, snv_cols, total_cols, df_original) {
  cat("🔍 Calculando VAFs...\n")
  
  # Crear un dataframe con los totales de miRNA por muestra
  df_totals <- df_original %>%
    dplyr::select(miRNA.name, all_of(total_cols)) %>%
    group_by(miRNA.name) %>%
    summarise(across(everything(), sum, na.rm = TRUE), .groups = "drop")
  
  # Preparar df para el cálculo de VAF
  df_vaf_calc <- df_mutations %>%
    mutate(
      miRNA_pos_mut = paste(miRNA.name, pos.mut, sep = "_")
    )
  
  # Calcular VAF para cada SNV en cada muestra
  vaf_matrix_list <- list()
  for (i in seq_along(snv_cols)) {
    snv_col <- snv_cols[i]
    total_col <- total_cols[i]
    
    # Obtener las cuentas de SNV
    snv_counts <- df_vaf_calc[[snv_col]]
    
    # Obtener los totales de miRNA correspondientes
    total_miRNA_counts <- df_totals[[total_col]][match(df_vaf_calc$miRNA.name, df_totals$miRNA.name)]
    
    # Calcular VAF
    vaf_matrix_list[[snv_col]] <- ifelse(total_miRNA_counts > 0, snv_counts / total_miRNA_counts, 0)
  }
  
  vaf_matrix <- as.data.frame(vaf_matrix_list)
  names(vaf_matrix) <- paste0(snv_cols, "_VAF")
  
  df_vaf_calc <- bind_cols(df_vaf_calc, vaf_matrix)
  
  # Calcular VAF promedio por fila (SNV)
  vaf_avg_cols <- names(df_vaf_calc)[str_detect(names(df_vaf_calc), "_VAF")]
  df_vaf_calc <- df_vaf_calc %>%
    mutate(
      vaf_avg = rowMeans(select(., all_of(vaf_avg_cols)), na.rm = TRUE)
    )
  
  return(df_vaf_calc)
}

# Calcular VAFs
df_with_vaf <- calculate_vaf(df_gt_mutations, snv_cols, total_cols, df)

# Filtrar SNVs con VAF > 50%
cat("🔍 Filtrando SNVs con VAF > 50%...\n")
df_filtered <- df_with_vaf %>%
  filter(vaf_avg <= 0.5)

vaf_filtered_count <- nrow(df_with_vaf) - nrow(df_filtered)
cat("✅ SNVs filtrados:", vaf_filtered_count, "removidos\n")
cat("✅ SNVs restantes:", nrow(df_filtered), "\n")

# Función para crear matriz de cuentas por miRNA
create_count_matrix <- function(df_filtered, snv_cols) {
  cat("📊 Creando matriz de cuentas G>T por miRNA...\n")
  
  # Sumar cuentas de SNVs G>T por miRNA y muestra
  count_matrix <- df_filtered %>%
    dplyr::select(miRNA.name, all_of(snv_cols)) %>%
    group_by(miRNA.name) %>%
    summarise(across(everything(), sum, na.rm = TRUE), .groups = "drop") %>%
    column_to_rownames("miRNA.name")
  
  # Renombrar columnas para claridad
  colnames(count_matrix) <- c("Control", "PE_IP")
  
  return(count_matrix)
}

# Función para crear matriz de VAF promedio por miRNA
create_vaf_matrix <- function(df_filtered, snv_cols) {
  cat("📊 Creando matriz de VAF promedio por miRNA...\n")
  
  # Calcular VAF promedio por miRNA y muestra
  vaf_matrix <- df_filtered %>%
    dplyr::select(miRNA.name, contains("_VAF")) %>%
    group_by(miRNA.name) %>%
    summarise(across(everything(), mean, na.rm = TRUE), .groups = "drop") %>%
    column_to_rownames("miRNA.name")
  
  # Renombrar columnas para claridad
  colnames(vaf_matrix) <- c("Control_VAF", "PE_IP_VAF")
  
  return(vaf_matrix)
}

# Crear matrices
count_matrix <- create_count_matrix(df_filtered, snv_cols)
vaf_matrix <- create_vaf_matrix(df_filtered, snv_cols)

cat("✅ Matriz de cuentas:", nrow(count_matrix), "miRNAs x", ncol(count_matrix), "muestras\n")
cat("✅ Matriz de VAF:", nrow(vaf_matrix), "miRNAs x", ncol(vaf_matrix), "muestras\n")

# Función para identificar top 10% de miRNAs
get_top_10_percent <- function(matrix, method_name) {
  cat("🔍 Identificando top 10% de miRNAs por", method_name, "...\n")
  
  # Calcular suma total por miRNA (suma de ambas muestras)
  total_scores <- rowSums(matrix, na.rm = TRUE)
  
  # Ordenar por score total
  sorted_scores <- sort(total_scores, decreasing = TRUE)
  
  # Calcular top 10%
  n_top <- max(1, round(length(sorted_scores) * 0.1))
  top_10_percent <- names(sorted_scores)[1:n_top]
  
  cat("✅ Top 10% miRNAs por", method_name, ":", length(top_10_percent), "miRNAs\n")
  
  return(list(
    top_mirnas = top_10_percent,
    scores = sorted_scores,
    n_top = n_top
  ))
}

# Identificar top 10% por ambos métodos
top_by_counts <- get_top_10_percent(count_matrix, "cuentas totales")
top_by_vaf <- get_top_10_percent(vaf_matrix, "VAF promedio")

# Análisis de solapamiento
cat("📊 Analizando solapamiento entre métodos...\n")
cat("🔍 Top miRNAs por cuentas:", paste(head(top_by_counts$top_mirnas, 5), collapse = ", "), "\n")
cat("🔍 Top miRNAs por VAF:", paste(head(top_by_vaf$top_mirnas, 5), collapse = ", "), "\n")

shared_mirnas <- intersect(top_by_counts$top_mirnas, top_by_vaf$top_mirnas)
counts_only <- setdiff(top_by_counts$top_mirnas, top_by_vaf$top_mirnas)
vaf_only <- setdiff(top_by_vaf$top_mirnas, top_by_counts$top_mirnas)

cat("✅ miRNAs compartidos:", length(shared_mirnas), "\n")
cat("✅ Solo en cuentas:", length(counts_only), "\n")
cat("✅ Solo en VAF:", length(vaf_only), "\n")

# Debug: mostrar algunos ejemplos
if(length(shared_mirnas) > 0) {
  cat("🔍 Ejemplos de miRNAs compartidos:", paste(head(shared_mirnas, 3), collapse = ", "), "\n")
} else {
  cat("⚠️  No hay miRNAs compartidos - investigando...\n")
  cat("🔍 Primeros 3 por cuentas:", paste(head(top_by_counts$top_mirnas, 3), collapse = ", "), "\n")
  cat("🔍 Primeros 3 por VAF:", paste(head(top_by_vaf$top_mirnas, 3), collapse = ", "), "\n")
}

# Crear visualizaciones
create_comparison_plots <- function(count_matrix, vaf_matrix, top_by_counts, top_by_vaf, shared_mirnas) {
  cat("🎨 Creando visualizaciones...\n")
  
  # 1. Heatmap de cuentas para top miRNAs
  top_count_mirnas <- top_by_counts$top_mirnas
  count_heatmap_data <- count_matrix[top_count_mirnas, , drop = FALSE]
  
  p1 <- pheatmap(
    count_heatmap_data,
    scale = "row",
    clustering_distance_rows = "euclidean",
    clustering_distance_cols = "euclidean",
    color = viridis(100),
    main = "Top 10% miRNAs por Cuentas G>T",
    fontsize = 8,
    fontsize_row = 6,
    fontsize_col = 10
  )
  
  # 2. Heatmap de VAF para top miRNAs
  top_vaf_mirnas <- top_by_vaf$top_mirnas
  vaf_heatmap_data <- vaf_matrix[top_vaf_mirnas, , drop = FALSE]
  
  p2 <- pheatmap(
    vaf_heatmap_data,
    scale = "row",
    clustering_distance_rows = "euclidean",
    clustering_distance_cols = "euclidean",
    color = viridis(100),
    main = "Top 10% miRNAs por VAF G>T",
    fontsize = 8,
    fontsize_row = 6,
    fontsize_col = 10
  )
  
  # 3. Diagrama de Venn (solo si hay solapamiento)
  library(VennDiagram)
  
  venn_data <- list(
    "Por Cuentas" = top_by_counts$top_mirnas,
    "Por VAF" = top_by_vaf$top_mirnas
  )
  
  if(length(shared_mirnas) > 0) {
    p3 <- venn.diagram(
      venn_data,
      filename = NULL,
      fill = c("lightblue", "lightcoral"),
      alpha = 0.7,
      cex = 1.5,
      cat.cex = 1.2,
      main = "Solapamiento: Top 10% miRNAs"
    )
  } else {
    # Crear un gráfico simple cuando no hay solapamiento
    p3 <- ggplot(data.frame(x = 1, y = 1), aes(x, y)) +
      geom_text(aes(label = "No hay solapamiento\nentre métodos"), size = 6) +
      theme_void() +
      labs(title = "Solapamiento: Top 10% miRNAs")
  }
  
  # 4. Gráfico de barras comparativo
  comparison_data <- data.frame(
    Metodo = c("Cuentas", "VAF", "Compartidos"),
    Cantidad = c(
      length(top_by_counts$top_mirnas),
      length(top_by_vaf$top_mirnas),
      length(shared_mirnas)
    )
  )
  
  p4 <- ggplot(comparison_data, aes(x = Metodo, y = Cantidad, fill = Metodo)) +
    geom_bar(stat = "identity", alpha = 0.8) +
    geom_text(aes(label = Cantidad), vjust = -0.5, size = 4) +
    scale_fill_brewer(type = "qual", palette = "Set2") +
    labs(
      title = "Comparación de Métodos: Top 10% miRNAs",
      x = "Método",
      y = "Número de miRNAs"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, size = 14),
      axis.text = element_text(size = 12),
      axis.title = element_text(size = 12)
    )
  
  return(list(
    count_heatmap = p1,
    vaf_heatmap = p2,
    venn_diagram = p3,
    comparison_bars = p4
  ))
}

# Crear visualizaciones
plots <- create_comparison_plots(count_matrix, vaf_matrix, top_by_counts, top_by_vaf, shared_mirnas)

# Guardar visualizaciones
cat("💾 Guardando visualizaciones...\n")
dir.create("outputs/figures/expanded_analysis", recursive = TRUE, showWarnings = FALSE)

# Guardar heatmaps
png("outputs/figures/expanded_analysis/heatmap_top_counts.png", width = 1200, height = 800, res = 150)
print(plots$count_heatmap)
dev.off()

png("outputs/figures/expanded_analysis/heatmap_top_vaf.png", width = 1200, height = 800, res = 150)
print(plots$vaf_heatmap)
dev.off()

png("outputs/figures/expanded_analysis/venn_diagram.png", width = 800, height = 600, res = 150)
if(length(shared_mirnas) > 0) {
  grid.draw(plots$venn_diagram)
} else {
  print(plots$venn_diagram)
}
dev.off()

png("outputs/figures/expanded_analysis/comparison_bars.png", width = 800, height = 600, res = 150)
print(plots$comparison_bars)
dev.off()

# Crear reporte detallado
create_detailed_report <- function(count_matrix, vaf_matrix, top_by_counts, top_by_vaf, 
                                 shared_mirnas, counts_only, vaf_only, vaf_filtered_count) {
  cat("📝 Generando reporte detallado...\n")
  
  report <- paste0(
    "# REPORTE DE ANÁLISIS EXPANDIDO: TOP 10% miRNAs\n\n",
    "## Fecha: ", Sys.Date(), "\n\n",
    "## RESUMEN EJECUTIVO\n",
    "Se implementó un análisis expandido para identificar miRNAs más significativos ",
    "usando dos métodos diferentes: cuentas totales de SNVs G>T vs VAF promedio.\n\n",
    "### Filtros Aplicados:\n",
    "- **VAF > 50%**: ", vaf_filtered_count, " SNVs removidos\n",
    "- **SNVs restantes**: ", nrow(count_matrix), " miRNAs analizados\n\n",
    "## RESULTADOS POR MÉTODO\n\n",
    "### Método 1: Cuentas Totales G>T\n",
    "- **Total miRNAs**: ", nrow(count_matrix), "\n",
    "- **Top 10%**: ", length(top_by_counts$top_mirnas), " miRNAs\n",
    "- **Top 5 miRNAs**: ", paste(head(top_by_counts$top_mirnas, 5), collapse = ", "), "\n\n",
    "### Método 2: VAF Promedio G>T\n",
    "- **Total miRNAs**: ", nrow(vaf_matrix), "\n",
    "- **Top 10%**: ", length(top_by_vaf$top_mirnas), " miRNAs\n",
    "- **Top 5 miRNAs**: ", paste(head(top_by_vaf$top_mirnas, 5), collapse = ", "), "\n\n",
    "## ANÁLISIS DE SOLAPAMIENTO\n",
    "- **miRNAs compartidos**: ", length(shared_mirnas), "\n",
    "- **Solo en cuentas**: ", length(counts_only), "\n",
    "- **Solo en VAF**: ", length(vaf_only), "\n",
    "- **Porcentaje de solapamiento**: ", round(length(shared_mirnas) / max(length(top_by_counts$top_mirnas), length(top_by_vaf$top_mirnas)) * 100, 1), "%\n\n",
    "## miRNAs COMPARTIDOS (Top 10%)\n",
    paste(shared_mirnas, collapse = ", "), "\n\n",
    "## miRNAs SOLO EN CUENTAS\n",
    paste(counts_only, collapse = ", "), "\n\n",
    "## miRNAs SOLO EN VAF\n",
    paste(vaf_only, collapse = ", "), "\n\n",
    "## INTERPRETACIÓN\n",
    "### miRNAs Compartidos:\n",
    "Los miRNAs que aparecen en ambos métodos son los más robustos y confiables ",
    "para análisis posteriores.\n\n",
    "### Diferencias entre Métodos:\n",
    "- **Método de cuentas**: Identifica miRNAs con mayor cantidad absoluta de mutaciones\n",
    "- **Método de VAF**: Identifica miRNAs con mayor frecuencia relativa de mutaciones\n\n",
    "## RECOMENDACIONES\n",
    "1. **Priorizar miRNAs compartidos** para análisis funcional\n",
    "2. **Investigar diferencias** entre métodos para entender patrones\n",
    "3. **Validar experimentalmente** los miRNAs más consistentes\n\n",
    "---\n",
    "*Reporte generado el: ", Sys.time(), "*\n"
  )
  
  return(report)
}

# Generar reporte
detailed_report <- create_detailed_report(
  count_matrix, vaf_matrix, top_by_counts, top_by_vaf,
  shared_mirnas, counts_only, vaf_only, vaf_filtered_count
)

# Guardar reporte
writeLines(detailed_report, "outputs/expanded_analysis_report.md")

# Guardar datos
saveRDS(list(
  count_matrix = count_matrix,
  vaf_matrix = vaf_matrix,
  top_by_counts = top_by_counts,
  top_by_vaf = top_by_vaf,
  shared_mirnas = shared_mirnas,
  counts_only = counts_only,
  vaf_only = vaf_only,
  vaf_filtered_count = vaf_filtered_count
), "outputs/expanded_analysis_results.rds")

cat("🎉 Análisis expandido completado!\n")
cat("📁 Resultados guardados en:\n")
cat("   - outputs/figures/expanded_analysis/\n")
cat("   - outputs/expanded_analysis_report.md\n")
cat("   - outputs/expanded_analysis_results.rds\n")
