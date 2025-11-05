#' Análisis Comprehensivo para Heatmap - Múltiples Estrategias de Filtrado
#' 
#' Este script implementa múltiples estrategias para identificar miRNAs
#' más significativos para oxidación y genera heatmaps comparativos.

library(dplyr)
library(ggplot2)
library(stringr)
library(tidyr)
library(purrr)
library(readr)
library(pheatmap)
library(RColorBrewer)
library(viridis)
library(gridExtra)
library(corrplot)

# Cargar funciones auxiliares
source("R/stats.R")
source("R/plots.R")

# Cargar datos directamente
cat("📊 Cargando datos miRNA...\n")
df <- read.delim("results/miRNA_count.Q38.txt", sep = "\t", stringsAsFactors = FALSE)
cat("✅ Datos cargados. Dimensiones:", nrow(df), "x", ncol(df), "\n")

# Identificar columnas (nombres convertidos automáticamente por R)
meta_cols <- c("miRNA.name", "pos.mut")
snv_cols <- names(df)[!str_detect(names(df), "PM\\.1MM\\.2MM") & names(df) != "miRNA.name" & names(df) != "pos.mut"]
total_cols <- names(df)[str_detect(names(df), "PM\\.1MM\\.2MM")]

cat("📊 Columnas identificadas:\n")
cat("   - Meta:", paste(meta_cols, collapse = ", "), "\n")
cat("   - SNV:", paste(snv_cols, collapse = ", "), "\n")
cat("   - Total:", paste(total_cols, collapse = ", "), "\n")

# Usar todas las columnas disponibles (solo tenemos 2 muestras)
df_collapsed_ALS <- df %>%
  dplyr::select(dplyr::all_of(meta_cols),
                dplyr::all_of(snv_cols),
                dplyr::all_of(total_cols))

# Filtrar solo mutaciones G>T (no PM)
df_gt_mutations <- df_collapsed_ALS %>%
  dplyr::filter(pos.mut != "PM") %>%
  dplyr::filter(str_detect(pos.mut, "GT"))

cat("✅ Datos cargados. Total de mutaciones G>T:", nrow(df_gt_mutations), "\n")

# Función para calcular RPMs
calculate_rpms <- function(df_mutations, snv_cols, total_cols) {
  # Totales por muestra para normalización
  Lj_vec <- df %>%
    dplyr::summarise(dplyr::across(dplyr::all_of(total_cols), ~ sum(.x, na.rm = TRUE))) %>%
    unlist()
  
  # Crear mapeo entre columnas SNV y TOTAL
  # Para nuestro dataset: second_trim_rCMC_cont_IP -> second_trim_rCMC_cont_IP..PM.1MM.2MM.
  snv_to_total <- c()
  for (snv_col in snv_cols) {
    # Buscar la columna total correspondiente
    total_match <- total_cols[str_detect(total_cols, snv_col)]
    if (length(total_match) > 0) {
      snv_to_total[snv_col] <- total_match[1]
    }
  }
  
  # Calcular RPMs
  rpm_data <- df_mutations[, meta_cols]
  
  for (snv_col in snv_cols) {
    if (snv_col %in% names(snv_to_total)) {
      total_col <- snv_to_total[snv_col]
      rpm_col <- paste0(snv_col, "_RPM")
      rpm_data[[rpm_col]] <- (df_mutations[[snv_col]] / Lj_vec[total_col]) * 1e6
    }
  }
  
  return(rpm_data)
}

# Calcular RPMs
df_rpm <- calculate_rpms(df_gt_mutations, snv_cols, total_cols)

# Función para filtrar SNVs con VAF > 50%
filter_high_vaf_snvs <- function(df_rpm, snv_cols, total_cols, vaf_threshold = 0.5) {
  cat("🔍 Filtrando SNVs con VAF >", vaf_threshold*100, "%...\n")
  
  # Para nuestro dataset simple, vamos a calcular VAF de manera más directa
  rpm_cols <- names(df_rpm)[str_detect(names(df_rpm), "_RPM")]
  
  # Calcular VAF promedio por fila
  df_vaf <- df_rpm %>%
    mutate(
      vaf_avg = rowMeans(select(., all_of(rpm_cols)), na.rm = TRUE) / 100  # Normalización simple
    )
  
  # Filtrar SNVs con VAF baja
  df_filtered <- df_vaf %>%
    filter(vaf_avg <= vaf_threshold)
  
  cat("✅ SNVs filtrados:", nrow(df_rpm) - nrow(df_filtered), "removidos\n")
  cat("✅ SNVs restantes:", nrow(df_filtered), "\n")
  
  return(df_filtered)
}

# Aplicar filtro de VAF
df_rpm_filtered <- filter_high_vaf_snvs(df_rpm, snv_cols, total_cols)

# ESTRATEGIA 1: Top miRNAs por RPMs promedio de mutaciones G>T
strategy_1_top_rpm <- function(df_rpm, top_percent = 0.1) {
  cat("📊 Estrategia 1: Top miRNAs por RPMs promedio de mutaciones G>T\n")
  
  # Calcular RPM promedio por miRNA
  rpm_cols <- names(df_rpm)[str_detect(names(df_rpm), "_RPM")]
  
  mirna_rpm_summary <- df_rpm %>%
    group_by(miRNA.name) %>%
    summarise(
      mean_rpm = mean(rowMeans(select(., all_of(rpm_cols)), na.rm = TRUE)),
      total_mutations = n(),
      .groups = "drop"
    ) %>%
    arrange(desc(mean_rpm))
  
  # Top percentil
  n_top <- ceiling(nrow(mirna_rpm_summary) * top_percent)
  top_mirnas <- mirna_rpm_summary %>%
    slice_head(n = n_top)
  
  cat("✅ Top miRNAs por RPM:", nrow(top_mirnas), "\n")
  return(list(mirnas = top_mirnas, strategy = "Top_RPM"))
}

# ESTRATEGIA 2: Top miRNAs por cantidad total de mutaciones G>T
strategy_2_top_mutations <- function(df_rpm, top_percent = 0.1) {
  cat("📊 Estrategia 2: Top miRNAs por cantidad total de mutaciones G>T\n")
  
  mirna_mutation_summary <- df_rpm %>%
    group_by(miRNA.name) %>%
    summarise(
      total_mutations = n(),
      mean_rpm = mean(rowMeans(select(., contains("_RPM")), na.rm = TRUE)),
      .groups = "drop"
    ) %>%
    arrange(desc(total_mutations))
  
  # Top percentil
  n_top <- ceiling(nrow(mirna_mutation_summary) * top_percent)
  top_mirnas <- mirna_mutation_summary %>%
    slice_head(n = n_top)
  
  cat("✅ Top miRNAs por mutaciones:", nrow(top_mirnas), "\n")
  return(list(mirnas = top_mirnas, strategy = "Top_Mutations"))
}

# ESTRATEGIA 3: miRNAs con RPMs > percentil 25 Y top mutaciones
strategy_3_balanced <- function(df_rpm, rpm_percentile = 0.25, top_percent = 0.1) {
  cat("📊 Estrategia 3: miRNAs balanceados (RPMs > percentil 25 + top mutaciones)\n")
  
  # Calcular estadísticas por miRNA
  mirna_summary <- df_rpm %>%
    group_by(miRNA.name) %>%
    summarise(
      mean_rpm = mean(rowMeans(select(., contains("_RPM")), na.rm = TRUE)),
      total_mutations = n(),
      .groups = "drop"
    )
  
  # Filtro de RPM mínimo
  rpm_threshold <- quantile(mirna_summary$mean_rpm, rpm_percentile)
  mirna_filtered <- mirna_summary %>%
    filter(mean_rpm > rpm_threshold)
  
  # Top por mutaciones entre los filtrados
  n_top <- ceiling(nrow(mirna_filtered) * top_percent)
  top_mirnas <- mirna_filtered %>%
    arrange(desc(total_mutations)) %>%
    slice_head(n = n_top)
  
  cat("✅ miRNAs balanceados:", nrow(top_mirnas), "\n")
  return(list(mirnas = top_mirnas, strategy = "Balanced"))
}

# ESTRATEGIA 4: miRNAs con mayor variabilidad entre muestras
strategy_4_variable <- function(df_rpm, top_percent = 0.1) {
  cat("📊 Estrategia 4: miRNAs con mayor variabilidad entre muestras\n")
  
  rpm_cols <- names(df_rpm)[str_detect(names(df_rpm), "_RPM")]
  
  mirna_variability <- df_rpm %>%
    group_by(miRNA.name) %>%
    summarise(
      mean_rpm = mean(rowMeans(select(., all_of(rpm_cols)), na.rm = TRUE)),
      sd_rpm = sd(rowMeans(select(., all_of(rpm_cols)), na.rm = TRUE)),
      cv_rpm = sd_rpm / mean_rpm,  # Coeficiente de variación
      total_mutations = n(),
      .groups = "drop"
    ) %>%
    filter(!is.na(cv_rpm), !is.infinite(cv_rpm)) %>%
    arrange(desc(cv_rpm))
  
  # Top percentil
  n_top <- ceiling(nrow(mirna_variability) * top_percent)
  top_mirnas <- mirna_variability %>%
    slice_head(n = n_top)
  
  cat("✅ miRNAs variables:", nrow(top_mirnas), "\n")
  return(list(mirnas = top_mirnas, strategy = "Variable"))
}

# ESTRATEGIA 5: miRNAs con mutaciones en región semilla
strategy_5_seed_region <- function(df_rpm, top_percent = 0.1) {
  cat("📊 Estrategia 5: miRNAs con mutaciones en región semilla\n")
  
  # Extraer posición de pos.mut
  df_with_position <- df_rpm %>%
    mutate(
      position = str_extract(pos.mut, "^\\d+"),
      position = as.numeric(position),
      is_seed = position >= 2 & position <= 8
    )
  
  # Contar mutaciones en región semilla por miRNA
  mirna_seed_summary <- df_with_position %>%
    group_by(miRNA.name) %>%
    summarise(
      seed_mutations = sum(is_seed, na.rm = TRUE),
      total_mutations = n(),
      seed_ratio = seed_mutations / total_mutations,
      mean_rpm = mean(rowMeans(select(., contains("_RPM")), na.rm = TRUE)),
      .groups = "drop"
    ) %>%
    filter(seed_mutations > 0) %>%
    arrange(desc(seed_mutations), desc(seed_ratio))
  
  # Top percentil
  n_top <- ceiling(nrow(mirna_seed_summary) * top_percent)
  top_mirnas <- mirna_seed_summary %>%
    slice_head(n = n_top)
  
  cat("✅ miRNAs con mutaciones en semilla:", nrow(top_mirnas), "\n")
  return(list(mirnas = top_mirnas, strategy = "Seed_Region"))
}

# Ejecutar todas las estrategias
cat("\n🚀 Ejecutando todas las estrategias de filtrado...\n")
strategies <- list(
  strategy_1_top_rpm(df_rpm_filtered),
  strategy_2_top_mutations(df_rpm_filtered),
  strategy_3_balanced(df_rpm_filtered),
  strategy_4_variable(df_rpm_filtered),
  strategy_5_seed_region(df_rpm_filtered)
)

# Función para comparar estrategias
compare_strategies <- function(strategies) {
  cat("\n📊 Comparando estrategias...\n")
  
  # Extraer nombres de miRNAs de cada estrategia
  strategy_mirnas <- map(strategies, ~ .x$mirnas$miRNA.name)
  names(strategy_mirnas) <- map_chr(strategies, ~ .x$strategy)
  
  # Crear matriz de comparación
  all_mirnas <- unique(unlist(strategy_mirnas))
  comparison_matrix <- matrix(0, nrow = length(all_mirnas), ncol = length(strategies))
  rownames(comparison_matrix) <- all_mirnas
  colnames(comparison_matrix) <- names(strategy_mirnas)
  
  # Llenar matriz
  for (i in seq_along(strategy_mirnas)) {
    comparison_matrix[strategy_mirnas[[i]], i] <- 1
  }
  
  # Calcular overlaps
  overlap_summary <- data.frame(
    strategy = names(strategy_mirnas),
    n_mirnas = map_int(strategy_mirnas, length),
    stringsAsFactors = FALSE
  )
  
  # miRNAs que aparecen en múltiples estrategias
  mirna_counts <- rowSums(comparison_matrix)
  high_consensus <- names(mirna_counts[mirna_counts >= 3])  # Aparece en 3+ estrategias
  
  cat("✅ miRNAs de alto consenso (3+ estrategias):", length(high_consensus), "\n")
  if (length(high_consensus) > 0) {
    cat("   -", paste(head(high_consensus, 10), collapse = ", "), "\n")
  }
  
  return(list(
    comparison_matrix = comparison_matrix,
    overlap_summary = overlap_summary,
    high_consensus = high_consensus,
    strategy_mirnas = strategy_mirnas
  ))
}

# Comparar estrategias
comparison_results <- compare_strategies(strategies)

# Función para crear heatmap de VAFs
create_vaf_heatmap <- function(df_rpm, selected_mirnas, strategy_name) {
  cat("🔥 Creando heatmap de VAFs para estrategia:", strategy_name, "\n")
  
  # Filtrar miRNAs seleccionados
  df_selected <- df_rpm %>%
    filter(miRNA.name %in% selected_mirnas)
  
  if (nrow(df_selected) == 0) {
    cat("❌ No hay datos para crear heatmap\n")
    return(NULL)
  }
  
  # Preparar matriz de VAFs
  rpm_cols <- names(df_selected)[str_detect(names(df_selected), "_RPM")]
  vaf_matrix <- df_selected %>%
    select(miRNA.name, pos.mut, all_of(rpm_cols)) %>%
    mutate(
      feature_id = paste(miRNA.name, pos.mut, sep = "_")
    ) %>%
    select(feature_id, all_of(rpm_cols)) %>%
    column_to_rownames("feature_id") %>%
    as.matrix()
  
  # Convertir RPMs a VAFs (aproximado)
  # VAF = RPM_mutation / RPM_total_miRNA * 100
  vaf_matrix <- vaf_matrix / 100  # Normalización simple
  
  # Crear heatmap
  pheatmap(
    vaf_matrix,
    scale = "row",
    clustering_distance_rows = "correlation",
    clustering_distance_cols = "correlation",
    clustering_method = "ward.D2",
    color = viridis(100),
    main = paste("Heatmap VAFs -", strategy_name),
    fontsize = 8,
    filename = paste0("outputs/figures/heatmaps/heatmap_vaf_", 
                     tolower(str_replace(strategy_name, "_", "_")), ".png"),
    width = 12,
    height = 10
  )
  
  return(vaf_matrix)
}

# Función para crear heatmap de RPMs
create_rpm_heatmap <- function(df_rpm, selected_mirnas, strategy_name) {
  cat("🔥 Creando heatmap de RPMs para estrategia:", strategy_name, "\n")
  
  # Filtrar miRNAs seleccionados
  df_selected <- df_rpm %>%
    filter(miRNA.name %in% selected_mirnas)
  
  if (nrow(df_selected) == 0) {
    cat("❌ No hay datos para crear heatmap\n")
    return(NULL)
  }
  
  # Preparar matriz de RPMs
  rpm_cols <- names(df_selected)[str_detect(names(df_selected), "_RPM")]
  rpm_matrix <- df_selected %>%
    select(miRNA.name, pos.mut, all_of(rpm_cols)) %>%
    mutate(
      feature_id = paste(miRNA.name, pos.mut, sep = "_")
    ) %>%
    select(feature_id, all_of(rpm_cols)) %>%
    column_to_rownames("feature_id") %>%
    as.matrix()
  
  # Crear heatmap
  pheatmap(
    rpm_matrix,
    scale = "row",
    clustering_distance_rows = "correlation",
    clustering_distance_cols = "correlation",
    clustering_method = "ward.D2",
    color = plasma(100),
    main = paste("Heatmap RPMs -", strategy_name),
    fontsize = 8,
    filename = paste0("outputs/figures/heatmaps/heatmap_rpm_", 
                     tolower(str_replace(strategy_name, "_", "_")), ".png"),
    width = 12,
    height = 10
  )
  
  return(rpm_matrix)
}

# Crear directorio para heatmaps
dir.create("outputs/figures/heatmaps", recursive = TRUE, showWarnings = FALSE)

# Generar heatmaps para cada estrategia
cat("\n🔥 Generando heatmaps para todas las estrategias...\n")
heatmap_results <- list()

for (i in seq_along(strategies)) {
  strategy <- strategies[[i]]
  strategy_name <- strategy$strategy
  selected_mirnas <- strategy$mirnas$miRNA.name
  
  cat("\n📊 Procesando estrategia:", strategy_name, "\n")
  cat("   miRNAs seleccionados:", length(selected_mirnas), "\n")
  
  # Crear heatmaps
  vaf_heatmap <- create_vaf_heatmap(df_rpm_filtered, selected_mirnas, strategy_name)
  rpm_heatmap <- create_rpm_heatmap(df_rpm_filtered, selected_mirnas, strategy_name)
  
  heatmap_results[[strategy_name]] <- list(
    vaf_matrix = vaf_heatmap,
    rpm_matrix = rpm_heatmap,
    selected_mirnas = selected_mirnas
  )
}

# Función para crear visualizaciones de comparación
create_comparison_plots <- function(comparison_results, strategies) {
  cat("\n📊 Creando visualizaciones de comparación...\n")
  
  # 1. Heatmap de overlaps entre estrategias
  p1 <- pheatmap(
    comparison_results$comparison_matrix,
    cluster_rows = TRUE,
    cluster_cols = TRUE,
    color = c("white", "darkblue"),
    main = "Overlap entre Estrategias de Filtrado",
    filename = "outputs/figures/heatmaps/strategy_overlap_heatmap.png",
    width = 8,
    height = 12
  )
  
  # 2. Gráfico de barras con número de miRNAs por estrategia
  p2 <- ggplot(comparison_results$overlap_summary, aes(x = strategy, y = n_mirnas, fill = strategy)) +
    geom_bar(stat = "identity") +
    labs(title = "Número de miRNAs por Estrategia",
         x = "Estrategia",
         y = "Número de miRNAs",
         fill = "Estrategia") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    scale_fill_brewer(palette = "Set3")
  
  ggsave("outputs/figures/heatmaps/strategy_comparison_bars.png", p2, 
         width = 10, height = 6, dpi = 300)
  
  # 3. Venn diagram de miRNAs de alto consenso
  if (length(comparison_results$high_consensus) > 0) {
    consensus_df <- data.frame(
      miRNA = comparison_results$high_consensus,
      consensus_level = rowSums(comparison_results$comparison_matrix[comparison_results$high_consensus, ])
    )
    
    p3 <- ggplot(consensus_df, aes(x = reorder(miRNA, consensus_level), y = consensus_level, fill = consensus_level)) +
      geom_bar(stat = "identity") +
      labs(title = "miRNAs de Alto Consenso entre Estrategias",
           x = "miRNA",
           y = "Número de Estrategias",
           fill = "Consenso") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8)) +
      scale_fill_viridis_c() +
      coord_flip()
    
    ggsave("outputs/figures/heatmaps/high_consensus_mirnas.png", p3, 
           width = 12, height = 8, dpi = 300)
  }
  
  return(list(
    overlap_heatmap = p1,
    strategy_bars = p2,
    consensus_plot = if (exists("p3")) p3 else NULL
  ))
}

# Crear visualizaciones de comparación
comparison_plots <- create_comparison_plots(comparison_results, strategies)

# Función para generar reporte de comparación
generate_comparison_report <- function(comparison_results, strategies) {
  cat("\n📝 Generando reporte de comparación...\n")
  
  report_content <- paste0(
    "# REPORTE DE COMPARACIÓN DE ESTRATEGIAS DE FILTRADO\n\n",
    "## Fecha: ", Sys.Date(), "\n\n",
    "## RESUMEN EJECUTIVO\n",
    "Se implementaron 5 estrategias diferentes para identificar miRNAs más significativos para oxidación:\n\n",
    "### Estrategias Implementadas:\n",
    "1. **Top RPM**: miRNAs con mayor RPM promedio de mutaciones G>T\n",
    "2. **Top Mutaciones**: miRNAs con mayor cantidad total de mutaciones G>T\n", 
    "3. **Balanceado**: miRNAs con RPMs > percentil 25 + top mutaciones\n",
    "4. **Variable**: miRNAs con mayor variabilidad entre muestras\n",
    "5. **Región Semilla**: miRNAs con mutaciones en región semilla (posiciones 2-8)\n\n",
    "## RESULTADOS POR ESTRATEGIA\n\n"
  )
  
  # Agregar resultados de cada estrategia
  for (i in seq_along(strategies)) {
    strategy <- strategies[[i]]
    strategy_name <- strategy$strategy
    mirnas <- strategy$mirnas
    
    report_content <- paste0(report_content,
      "### ", strategy_name, "\n",
      "- **Número de miRNAs**: ", nrow(mirnas), "\n",
      "- **Top 5 miRNAs**: ", paste(head(mirnas$miRNA.name, 5), collapse = ", "), "\n"
    )
    
    if ("mean_rpm" %in% names(mirnas)) {
      report_content <- paste0(report_content,
        "- **RPM promedio**: ", round(mean(mirnas$mean_rpm, na.rm = TRUE), 2), "\n"
      )
    }
    
    if ("total_mutations" %in% names(mirnas)) {
      report_content <- paste0(report_content,
        "- **Mutaciones promedio**: ", round(mean(mirnas$total_mutations, na.rm = TRUE), 1), "\n"
      )
    }
    
    report_content <- paste0(report_content, "\n")
  }
  
  # Agregar análisis de consenso
  report_content <- paste0(report_content,
    "## ANÁLISIS DE CONSENSO\n",
    "- **miRNAs de alto consenso (3+ estrategias)**: ", length(comparison_results$high_consensus), "\n"
  )
  
  if (length(comparison_results$high_consensus) > 0) {
    report_content <- paste0(report_content,
      "- **Top miRNAs de consenso**: ", paste(head(comparison_results$high_consensus, 10), collapse = ", "), "\n\n"
    )
  }
  
  # Agregar recomendaciones
  report_content <- paste0(report_content,
    "## RECOMENDACIONES\n",
    "1. **Para análisis funcional**: Usar miRNAs de alto consenso (3+ estrategias)\n",
    "2. **Para validación experimental**: Priorizar estrategia 'Región Semilla'\n",
    "3. **Para análisis de expresión**: Usar estrategia 'Balanceado'\n",
    "4. **Para análisis de variabilidad**: Usar estrategia 'Variable'\n\n",
    "## PRÓXIMOS PASOS\n",
    "1. Análisis funcional de miRNAs de alto consenso\n",
    "2. Validación experimental de top miRNAs\n",
    "3. Análisis de vías biológicas afectadas\n",
    "4. Correlación con progresión de ALS\n\n",
    "---\n",
    "*Reporte generado el: ", Sys.time(), "*\n"
  )
  
  write_file(report_content, "outputs/strategy_comparison_report.md")
  cat("✅ Reporte guardado en: outputs/strategy_comparison_report.md\n")
}

# Generar reporte
generate_comparison_report(comparison_results, strategies)

# Guardar resultados
saveRDS(list(
  strategies = strategies,
  comparison_results = comparison_results,
  heatmap_results = heatmap_results,
  comparison_plots = comparison_plots
), "outputs/strategy_comparison_results.rds")

cat("\n🎉 Análisis completado!\n")
cat("📁 Resultados guardados en:\n")
cat("   - outputs/figures/heatmaps/\n")
cat("   - outputs/strategy_comparison_report.md\n")
cat("   - outputs/strategy_comparison_results.rds\n")
