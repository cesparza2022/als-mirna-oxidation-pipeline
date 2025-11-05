# Statistical Analysis Functions for ALS miRNA Oxidation Research
# This module contains functions for statistical analysis and comparisons

#' Calculate group means for SNV frequencies
#'
#' Computes mean frequency for each SNV across samples within each group.
#' Useful for comparing mutation patterns between experimental conditions.
#'
#' @param df_freq_long Long-format data frame with frequency data
#' @param group_col Name of the group column (default: "group")
#' @param freq_col Name of the frequency column (default: "freq_pct")
#' @return Wide-format data frame with group means
#' @examples
#' \dontrun{
#' df_means <- calculate_snv_group_means(df_freq_long)
#' }
#' @export
calculate_snv_group_means <- function(df_freq_long, 
                                     group_col = "group", 
                                     freq_col = "freq_pct") {
  stopifnot(is.data.frame(df_freq_long))
  stopifnot(group_col %in% names(df_freq_long))
  stopifnot(freq_col %in% names(df_freq_long))
  stopifnot("miRNA" %in% names(df_freq_long))
  stopifnot("mut" %in% names(df_freq_long))
  
  df_freq_long %>%
    group_by(miRNA, mut, .data[[group_col]]) %>%
    summarise(mean_freq = mean(.data[[freq_col]], na.rm = TRUE),
              .groups = "drop") %>%
    pivot_wider(names_from = group_col,
                values_from = mean_freq,
                names_prefix = "mean_")
}

#' Get top SNVs by group
#'
#' Identifies the top N SNVs with highest mean frequency in each group.
#' Useful for identifying the most prevalent mutations in each condition.
#'
#' @param df_means Data frame with group means (from calculate_snv_group_means)
#' @param n_top Number of top SNVs to return per group (default: 5)
#' @param group_names Vector of group names to analyze
#' @return List with top SNVs for each group
#' @examples
#' \dontrun{
#' top_snvs <- get_top_snvs_by_group(df_means, n_top = 5, 
#'                                   group_names = c("ALS.Enrolment", "ALS.Longitudinal", "Control"))
#' }
#' @export
get_top_snvs_by_group <- function(df_means, n_top = 5, group_names) {
  stopifnot(is.data.frame(df_means))
  stopifnot(is.numeric(n_top))
  stopifnot(n_top > 0)
  stopifnot(is.character(group_names))
  stopifnot(all(paste0("mean_", group_names) %in% names(df_means)))
  
  result <- list()
  
  for (group in group_names) {
    col_name <- paste0("mean_", group)
    if (col_name %in% names(df_means)) {
      result[[group]] <- df_means %>%
        arrange(desc(.data[[col_name]])) %>%
        slice(1:n_top) %>%
        select(miRNA, mut, all_of(col_name))
    }
  }
  
  result
}

#' Perform statistical comparison between groups
#'
#' Performs statistical tests (t-test, ANOVA) to compare frequencies between groups.
#' Provides p-values and effect sizes for group comparisons.
#'
#' @param df_freq_long Long-format data frame with frequency data
#' @param group_col Name of the group column (default: "group")
#' @param freq_col Name of the frequency column (default: "freq_pct")
#' @param test_type Type of test to perform ("t.test", "anova", "kruskal")
#' @return Data frame with statistical test results
#' @examples
#' \dontrun{
#' stats_results <- perform_group_comparison(df_freq_long, test_type = "anova")
#' }
#' @export
perform_group_comparison <- function(df_freq_long,
                                   group_col = "group",
                                   freq_col = "freq_pct",
                                   test_type = "anova") {
  stopifnot(is.data.frame(df_freq_long))
  stopifnot(group_col %in% names(df_freq_long))
  stopifnot(freq_col %in% names(df_freq_long))
  stopifnot(test_type %in% c("t.test", "anova", "kruskal"))
  
  if (test_type == "anova") {
    # One-way ANOVA
    model <- aov(as.formula(paste(freq_col, "~", group_col)), data = df_freq_long)
    summary(model)
  } else if (test_type == "kruskal") {
    # Kruskal-Wallis test
    kruskal.test(as.formula(paste(freq_col, "~", group_col)), data = df_freq_long)
  } else if (test_type == "t.test") {
    # Pairwise t-tests
    groups <- unique(df_freq_long[[group_col]])
    if (length(groups) == 2) {
      group1_data <- df_freq_long[df_freq_long[[group_col]] == groups[1], freq_col]
      group2_data <- df_freq_long[df_freq_long[[group_col]] == groups[2], freq_col]
      t.test(group1_data, group2_data)
    } else {
      stop("t.test requires exactly 2 groups")
    }
  }
}

#' Calculate mutation burden per miRNA
#'
#' Calculates total mutation burden (sum of all mutation frequencies) for each miRNA.
#' Useful for identifying miRNAs with high overall mutation rates.
#'
#' @param df_freq Data frame with frequency percentages
#' @param snv_cols Vector of SNV column names
#' @param miRNA_col Name of the miRNA column (default: "miRNA")
#' @return Data frame with mutation burden per miRNA
#' @examples
#' \dontrun{
#' burden_df <- calculate_mutation_burden(df_freq, snv_cols)
#' }
#' @export
calculate_mutation_burden <- function(df_freq, snv_cols, miRNA_col = "miRNA") {
  stopifnot(is.data.frame(df_freq))
  stopifnot(miRNA_col %in% names(df_freq))
  stopifnot(all(snv_cols %in% names(df_freq)))
  
  df_freq %>%
    group_by(.data[[miRNA_col]]) %>%
    summarise(
      total_burden = sum(across(all_of(snv_cols)), na.rm = TRUE),
      n_mutations = n(),
      mean_frequency = mean(across(all_of(snv_cols)), na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(desc(total_burden))
}

#' Identify G>T mutations
#'
#' Identifies and analyzes G>T mutations, which are characteristic of oxidative damage.
#' This is the primary focus of the ALS miRNA oxidation research.
#'
#' @param df_presence Data frame with SNV presence data
#' @param mut_col Name of the mutation column (default: "mut")
#' @return List with G>T mutation analysis results
#' @examples
#' \dontrun{
#' gt_analysis <- identify_gt_mutations(df_presence)
#' }
#' @export
identify_gt_mutations <- function(df_presence, mut_col = "mut") {
  stopifnot(is.data.frame(df_presence))
  stopifnot(mut_col %in% names(df_presence))
  
  # Identify G>T mutations (single and multiple)
  gt_patterns <- c("GT", "G>T", "G:T", ":GT")
  
  gt_mutations <- df_presence %>%
    filter(str_detect(.data[[mut_col]], paste(gt_patterns, collapse = "|"))) %>%
    mutate(
      is_gt = TRUE,
      gt_type = case_when(
        str_detect(.data[[mut_col]], "GT$") ~ "single_GT",
        str_detect(.data[[mut_col]], "GT,") ~ "multiple_GT",
        TRUE ~ "other_GT"
      )
    )
  
  # Calculate G>T counts per sample
  sample_cols <- setdiff(names(df_presence), c("miRNA", mut_col))
  gt_counts <- gt_mutations %>%
    select(all_of(sample_cols)) %>%
    colSums(na.rm = TRUE)
  
  list(
    gt_mutations = gt_mutations,
    gt_summary = data.frame(
      sample_id = gsub("\\.", "-", names(gt_counts)),  # Convert dots back to hyphens
      gt_count = as.numeric(gt_counts),
      stringsAsFactors = FALSE
    )
  )
}

#' Perform differential expression analysis
#'
#' Performs differential expression analysis using edgeR or DESeq2.
#' Compares expression levels between groups for each miRNA.
#'
#' @param count_matrix Count matrix (from convert_to_edgeR)
#' @param sample_metadata Data frame with sample metadata
#' @param group_col Name of the group column in metadata
#' @param method Analysis method ("edgeR" or "DESeq2")
#' @return Data frame with differential expression results
#' @examples
#' \dontrun{
#' de_results <- perform_differential_expression(count_matrix, sample_metadata, 
#'                                              group_col = "group", method = "edgeR")
#' }
#' @export
perform_differential_expression <- function(count_matrix, sample_metadata, 
                                          group_col = "group", method = "edgeR") {
  stopifnot(is.matrix(count_matrix))
  stopifnot(is.data.frame(sample_metadata))
  stopifnot(group_col %in% names(sample_metadata))
  stopifnot(method %in% c("edgeR", "DESeq2"))
  
  if (method == "edgeR") {
    # edgeR analysis
    library(edgeR)
    
    # Create DGEList object
    dge <- DGEList(counts = count_matrix, group = sample_metadata[[group_col]])
    
    # Filter lowly expressed genes
    keep <- filterByExpr(dge)
    dge <- dge[keep, , keep.lib.sizes = FALSE]
    
    # Normalize
    dge <- calcNormFactors(dge)
    
    # Design matrix
    design <- model.matrix(~ sample_metadata[[group_col]])
    
    # Estimate dispersions
    dge <- estimateDisp(dge, design)
    
    # Fit model and test
    fit <- glmFit(dge, design)
    lrt <- glmLRT(fit)
    
    # Extract results
    topTags(lrt, n = nrow(count_matrix))
    
  } else if (method == "DESeq2") {
    # DESeq2 analysis
    library(DESeq2)
    
    # Create DESeqDataSet
    dds <- DESeqDataSetFromMatrix(
      countData = count_matrix,
      colData = sample_metadata,
      design = as.formula(paste("~", group_col))
    )
    
    # Filter low count genes
    dds <- dds[rowSums(counts(dds)) >= 10, ]
    
    # Run DESeq2
    dds <- DESeq(dds)
    
    # Get results
    results(dds)
  }
}

#' Calculate correlation between groups
#'
#' Calculates correlation coefficients between groups for mutation frequencies.
#' Useful for understanding relationships between experimental conditions.
#'
#' @param df_means Data frame with group means
#' @param group_names Vector of group names to correlate
#' @param method Correlation method ("pearson", "spearman", "kendall")
#' @return Correlation matrix
#' @examples
#' \dontrun{
#' cor_matrix <- calculate_group_correlation(df_means, 
#'                                          group_names = c("ALS.Enrolment", "Control"),
#'                                          method = "pearson")
#' }
#' @export
calculate_group_correlation <- function(df_means, group_names, method = "pearson") {
  stopifnot(is.data.frame(df_means))
  stopifnot(is.character(group_names))
  stopifnot(method %in% c("pearson", "spearman", "kendall"))
  stopifnot(all(paste0("mean_", group_names) %in% names(df_means)))
  
  # Select relevant columns
  cor_cols <- paste0("mean_", group_names)
  cor_data <- df_means[cor_cols]
  
  # Remove rows with any NA values
  cor_data <- cor_data[complete.cases(cor_data), ]
  
  # Calculate correlation matrix
  cor(cor_data, method = method)
}
