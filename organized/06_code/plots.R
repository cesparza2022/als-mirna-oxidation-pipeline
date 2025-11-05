# Visualization Functions for ALS miRNA Oxidation Research
# This module contains functions for creating plots and visualizations

#' Create sample distribution pie chart
#'
#' Creates a pie chart showing the distribution of samples across groups.
#' Useful for understanding the experimental design and sample balance.
#'
#' @param sample_counts Named vector with sample counts per group
#' @param title Chart title (default: "Sample Distribution by Group")
#' @param colors Vector of colors for each group (optional)
#' @return ggplot object
#' @examples
#' \dontrun{
#' counts <- c("ALS-Longitudinal" = 128, "ALS-Enrolment" = 626, "Control" = 204)
#' p <- plot_sample_distribution(counts)
#' }
#' @export
plot_sample_distribution <- function(sample_counts, 
                                   title = "Sample Distribution by Group",
                                   colors = NULL) {
  stopifnot(is.numeric(sample_counts))
  stopifnot(length(sample_counts) > 0)
  stopifnot(all(names(sample_counts) != ""))
  
  # Create data frame for plotting
  df_pie <- data.frame(
    group = names(sample_counts),
    count = as.numeric(sample_counts),
    stringsAsFactors = FALSE
  ) %>%
    mutate(
      percentage = round(count / sum(count) * 100, 1),
      label = paste0(group, " (", count, ")")
    )
  
  # Create pie chart
  p <- ggplot(df_pie, aes(x = "", y = count, fill = group)) +
    geom_bar(stat = "identity", width = 1) +
    coord_polar("y", start = 0) +
    labs(title = title) +
    theme_void() +
    theme(legend.position = "right")
  
  # Add colors if provided
  if (!is.null(colors)) {
    p <- p + scale_fill_manual(values = colors)
  }
  
  return(p)
}

#' Create total counts distribution plot
#'
#' Creates a violin plot with boxplot overlay showing the distribution of total counts by group.
#' Useful for understanding sequencing depth differences between groups.
#'
#' @param df_long Long-format data frame with sample and count information
#' @param group_col Name of the group column (default: "group")
#' @param count_col Name of the count column (default: "total_counts")
#' @param title Plot title (default: "Distribution of Total Counts by Sample Group")
#' @return ggplot object
#' @examples
#' \dontrun{
#' p <- plot_total_counts_distribution(df_long)
#' }
#' @export
plot_total_counts_distribution <- function(df_long,
                                         group_col = "group",
                                         count_col = "total_counts",
                                         title = "Distribution of Total Counts by Sample Group") {
  stopifnot(is.data.frame(df_long))
  stopifnot(group_col %in% names(df_long))
  stopifnot(count_col %in% names(df_long))
  
  ggplot(df_long, aes(x = .data[[group_col]], y = .data[[count_col]], fill = .data[[group_col]])) +
    geom_violin(alpha = 0.4, color = NA) +
    geom_boxplot(width = 0.3, outlier.size = 0.8, alpha = 0.6) +
    stat_summary(
      fun = mean,
      geom = "point",
      shape = 23,
      size = 3,
      color = "black",
      fill = "yellow"
    ) +
    scale_y_continuous(
      labels = scales::comma,
      breaks = scales::pretty_breaks(n = 6)
    ) +
    labs(
      title = title,
      x = "Sample Group",
      y = "Total Counts"
    ) +
    theme_minimal() +
    theme(legend.position = "none")
}

#' Create SNV prevalence histogram
#'
#' Creates a histogram showing the distribution of SNV prevalence across samples.
#' Can be faceted by group or shown as a combined plot.
#'
#' @param df_counts_long Long-format data frame with SNV counts
#' @param group_col Name of the group column (default: "group")
#' @param count_col Name of the count column (default: "n_samples")
#' @param facet_by_group Whether to create separate plots for each group (default: TRUE)
#' @param title Plot title
#' @return ggplot object
#' @examples
#' \dontrun{
#' p <- plot_snv_prevalence_histogram(df_counts_long, facet_by_group = TRUE)
#' }
#' @export
plot_snv_prevalence_histogram <- function(df_counts_long,
                                        group_col = "group",
                                        count_col = "n_samples",
                                        facet_by_group = TRUE,
                                        title = "SNV Prevalence Distribution by Group") {
  stopifnot(is.data.frame(df_counts_long))
  stopifnot(group_col %in% names(df_counts_long))
  stopifnot(count_col %in% names(df_counts_long))
  
  if (facet_by_group) {
    p <- ggplot(df_counts_long, aes(x = .data[[count_col]], fill = .data[[group_col]])) +
      geom_histogram(binwidth = 5, color = "white", alpha = 0.7) +
      facet_wrap(as.formula(paste("~", group_col)), scales = "free_y") +
      scale_x_continuous(breaks = scales::pretty_breaks(10)) +
      scale_y_continuous(labels = scales::comma) +
      labs(
        title = title,
        x = "Number of Samples in Group Containing SNV",
        y = "Number of SNVs"
      ) +
      theme_minimal() +
      theme(legend.position = "none")
  } else {
    p <- ggplot(df_counts_long, aes(x = .data[[count_col]], fill = .data[[group_col]])) +
      geom_histogram(
        position = "identity",
        alpha = 0.4,
        binwidth = 1
      ) +
      geom_vline(xintercept = 1, linetype = "dashed") +
      annotate(
        "text", x = 1.5, y = Inf, label = "Only in 1 sample",
        vjust = 2, hjust = 0, size = 3
      ) +
      scale_x_continuous(
        breaks = seq(0, max(df_counts_long[[count_col]]), by = 1)
      ) +
      scale_y_continuous(labels = scales::comma) +
      scale_fill_brewer(type = "qual", palette = "Set1") +
      labs(
        title = title,
        subtitle = "How many samples (x) contain each SNV, colored by group",
        x = "Number of Samples in Group Containing SNV",
        y = "Number of SNVs",
        fill = "Group"
      ) +
      theme_minimal() +
      theme(
        legend.position = "top",
        panel.grid.minor = element_blank()
      )
  }
  
  return(p)
}

#' Create UpSet plot for SNV overlap
#'
#' Creates an UpSet plot showing the overlap of SNVs between groups.
#' Useful for understanding which mutations are shared or unique between conditions.
#'
#' @param snv_lists Named list of SNV ID vectors for each group
#' @param title Plot title (default: "SNV Overlap Between Groups")
#' @return UpSet plot object
#' @examples
#' \dontrun{
#' snv_lists <- list("ALS-Longitudinal" = snv_ids_long, "Control" = snv_ids_ctrl)
#' p <- plot_snv_upset(snv_lists)
#' }
#' @export
plot_snv_upset <- function(snv_lists, title = "SNV Overlap Between Groups") {
  stopifnot(is.list(snv_lists))
  stopifnot(length(snv_lists) >= 2)
  stopifnot(all(sapply(snv_lists, is.character)))
  
  # Create a simple overlap plot instead of UpSetR
  # Calculate overlaps
  all_snvs <- unique(unlist(snv_lists))
  overlap_df <- data.frame(
    snv_id = all_snvs,
    stringsAsFactors = FALSE
  )
  
  for (group_name in names(snv_lists)) {
    overlap_df[[group_name]] <- all_snvs %in% snv_lists[[group_name]]
  }
  
  # Count overlaps
  overlap_counts <- overlap_df %>%
    select(-snv_id) %>%
    rowSums()
  
  overlap_table <- table(overlap_counts)
  overlap_summary <- data.frame(
    n_groups = as.numeric(names(overlap_table)),
    count = as.numeric(overlap_table)
  ) %>%
    mutate(percentage = count / sum(count) * 100)
  
  ggplot(overlap_summary, aes(x = n_groups, y = count)) +
    geom_bar(stat = "identity", fill = "steelblue", alpha = 0.7) +
    geom_text(aes(label = paste0(round(percentage, 1), "%")), 
              vjust = -0.5, size = 3) +
    labs(
      title = title,
      x = "Number of Groups",
      y = "Number of SNVs",
      subtitle = "Distribution of SNV overlap between groups"
    ) +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5))
}

#' Create G>T mutation analysis plot
#'
#' Creates a plot showing G>T mutation counts and patterns.
#' This is the core visualization for oxidative damage analysis.
#'
#' @param gt_analysis List from identify_gt_mutations function
#' @param group_col Name of the group column in gt_summary
#' @param title Plot title (default: "G>T Mutation Analysis")
#' @return ggplot object
#' @examples
#' \dontrun{
#' p <- plot_gt_mutations(gt_analysis)
#' }
#' @export
plot_gt_mutations <- function(gt_analysis, 
                            group_col = "group",
                            title = "G>T Mutation Analysis") {
  stopifnot(is.list(gt_analysis))
  stopifnot("gt_summary" %in% names(gt_analysis))
  stopifnot(is.data.frame(gt_analysis$gt_summary))
  
  df_gt <- gt_analysis$gt_summary
  
  ggplot(df_gt, aes(x = .data[[group_col]], y = .data[["gt_count"]], fill = .data[[group_col]])) +
    geom_violin(alpha = 0.4, color = NA) +
    geom_boxplot(width = 0.3, outlier.size = 0.8, alpha = 0.6) +
    stat_summary(
      fun = mean,
      geom = "point",
      shape = 23,
      size = 3,
      color = "black",
      fill = "yellow"
    ) +
    scale_y_continuous(
      labels = scales::comma,
      breaks = scales::pretty_breaks(n = 6)
    ) +
    labs(
      title = title,
      x = "Sample Group",
      y = "G>T Mutation Count"
    ) +
    theme_minimal() +
    theme(legend.position = "none")
}

#' Create heatmap of top SNVs
#'
#' Creates a heatmap showing the top SNVs across samples or groups.
#' Useful for visualizing mutation patterns and identifying outliers.
#'
#' @param df_wide Wide-format data frame with SNV frequencies
#' @param snv_cols Vector of sample column names
#' @param n_top Number of top SNVs to show (default: 20)
#' @param title Plot title (default: "Top SNVs Heatmap")
#' @param cluster_rows Whether to cluster rows (default: TRUE)
#' @param cluster_cols Whether to cluster columns (default: TRUE)
#' @return pheatmap object
#' @examples
#' \dontrun{
#' p <- plot_snv_heatmap(df_wide, snv_cols, n_top = 20)
#' }
#' @export
plot_snv_heatmap <- function(df_wide, snv_cols, n_top = 20,
                           title = "Top SNVs Heatmap",
                           cluster_rows = TRUE,
                           cluster_cols = TRUE) {
  stopifnot(is.data.frame(df_wide))
  stopifnot(all(snv_cols %in% names(df_wide)))
  stopifnot(is.numeric(n_top))
  stopifnot(n_top > 0)
  
  library(pheatmap)
  
  # Select top SNVs by mean frequency
  df_top <- df_wide %>%
    mutate(mean_freq = rowMeans(select(., all_of(snv_cols)), na.rm = TRUE)) %>%
    arrange(desc(mean_freq)) %>%
    slice(1:n_top)
  
  # Prepare matrix for heatmap
  heatmap_data <- df_top %>%
    select(all_of(snv_cols)) %>%
    as.matrix()
  
  rownames(heatmap_data) <- paste(df_top$miRNA, df_top$mut, sep = "_")
  
  # Create heatmap
  pheatmap(
    heatmap_data,
    main = title,
    cluster_rows = cluster_rows,
    cluster_cols = cluster_cols,
    show_rownames = TRUE,
    show_colnames = TRUE,
    scale = "row",
    color = viridis::viridis(100)
  )
}

#' Create mutation burden plot
#'
#' Creates a plot showing mutation burden (total mutations) per miRNA.
#' Useful for identifying miRNAs with high mutation rates.
#'
#' @param burden_df Data frame from calculate_mutation_burden
#' @param n_top Number of top miRNAs to show (default: 20)
#' @param title Plot title (default: "Mutation Burden by miRNA")
#' @return ggplot object
#' @examples
#' \dontrun{
#' p <- plot_mutation_burden(burden_df, n_top = 20)
#' }
#' @export
plot_mutation_burden <- function(burden_df, n_top = 20,
                               title = "Mutation Burden by miRNA") {
  stopifnot(is.data.frame(burden_df))
  stopifnot("total_burden" %in% names(burden_df))
  stopifnot("miRNA" %in% names(burden_df))
  stopifnot(is.numeric(n_top))
  stopifnot(n_top > 0)
  
  df_top <- burden_df %>%
    slice(1:n_top) %>%
    mutate(miRNA = factor(miRNA, levels = rev(miRNA)))
  
  ggplot(df_top, aes(x = miRNA, y = total_burden)) +
    geom_col(fill = "steelblue", alpha = 0.7) +
    coord_flip() +
    labs(
      title = title,
      x = "miRNA",
      y = "Total Mutation Burden"
    ) +
    theme_minimal() +
    theme(
      axis.text.y = element_text(size = 8),
      panel.grid.major.y = element_blank()
    )
}

#' Create correlation heatmap
#'
#' Creates a correlation heatmap between groups or samples.
#' Useful for understanding relationships in the data.
#'
#' @param cor_matrix Correlation matrix
#' @param title Plot title (default: "Correlation Heatmap")
#' @param method Correlation method used (for subtitle)
#' @return ggplot object
#' @examples
#' \dontrun{
#' p <- plot_correlation_heatmap(cor_matrix, method = "pearson")
#' }
#' @export
plot_correlation_heatmap <- function(cor_matrix, 
                                   title = "Correlation Heatmap",
                                   method = "pearson") {
  stopifnot(is.matrix(cor_matrix))
  stopifnot(isSymmetric(cor_matrix))
  
  # Convert to long format
  df_cor <- cor_matrix %>%
    as.data.frame() %>%
    rownames_to_column("var1") %>%
    pivot_longer(-var1, names_to = "var2", values_to = "correlation")
  
  ggplot(df_cor, aes(x = var1, y = var2, fill = correlation)) +
    geom_tile() +
    scale_fill_gradient2(
      low = "blue", 
      mid = "white", 
      high = "red",
      midpoint = 0,
      limits = c(-1, 1)
    ) +
    labs(
      title = title,
      subtitle = paste("Method:", method),
      x = "",
      y = "",
      fill = "Correlation"
    ) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      panel.grid = element_blank()
    )
}
