# miRNA Data Loader for ALS Oxidation Research
# This script loads and processes the miRNA_count.Q33.txt dataset

# Load required libraries
library(data.table)
library(dplyr)
library(stringr)

# Function to load miRNA count data
load_mirna_data <- function(file_path, config) {
  cat("Loading miRNA count data from:", file_path, "\n")
  
  # Check if file exists
  if (!file.exists(file_path)) {
    stop("miRNA count file not found: ", file_path)
  }
  
  # Read the data
  cat("Reading data...\n")
  mirna_data <- fread(file_path, sep = "\t")
  
  cat("Dataset loaded successfully!\n")
  cat("Dimensions:", nrow(mirna_data), "x", ncol(mirna_data), "\n")
  
  # Extract sample information
  sample_cols <- names(mirna_data)[3:ncol(mirna_data)]  # Skip miRNA name and pos:mut
  
  # Create sample metadata
  sample_metadata <- data.table(
    sample_id = sample_cols,
    group = ifelse(str_detect(sample_cols, "control"), "Control", 
                   ifelse(str_detect(sample_cols, "ALS"), "ALS", "Unknown")),
    timepoint = ifelse(str_detect(sample_cols, "longitudinal"), 
                       str_extract(sample_cols, "longitudinal_[0-9]+"), "enrolment"),
    tissue = "bloodplasma",
    srr_id = str_extract(sample_cols, "SRR[0-9]+")
  )
  
  # Add batch information
  sample_metadata[, batch := str_extract(sample_cols, "batch_[0-9]+")]
  sample_metadata[is.na(batch), batch := "unknown"]
  
  # Separate miRNA information and count data
  mirna_info <- mirna_data[, .(mirna_name = `miRNA name`, mutation = `pos:mut`)]
  count_data <- mirna_data[, 3:ncol(mirna_data), with = FALSE]
  
  # Convert count data to numeric matrix
  count_matrix <- as.matrix(count_data)
  rownames(count_matrix) <- paste0(mirna_info$mirna_name, "_", mirna_info$mutation)
  colnames(count_matrix) <- sample_metadata$sample_id
  
  # Calculate summary statistics
  total_mutations <- nrow(mirna_info)
  total_samples <- ncol(count_matrix)
  als_samples <- sum(sample_metadata$group == "ALS")
  control_samples <- sum(sample_metadata$group == "Control")
  
  cat("\nDataset Summary:\n")
  cat("- Total mutations:", total_mutations, "\n")
  cat("- Total samples:", total_samples, "\n")
  cat("- ALS samples:", als_samples, "\n")
  cat("- Control samples:", control_samples, "\n")
  cat("- Unique miRNAs:", length(unique(mirna_info$mirna_name)), "\n")
  cat("- Unique mutation types:", length(unique(mirna_info$mutation)), "\n")
  
  # Calculate data quality metrics
  zero_count <- sum(count_matrix == 0)
  total_values <- length(count_matrix)
  zero_pct <- round(100 * zero_count / total_values, 2)
  
  cat("- Zero values:", zero_pct, "%\n")
  cat("- Data range:", min(count_matrix), "to", max(count_matrix), "\n")
  
  return(list(
    count_matrix = count_matrix,
    mirna_info = mirna_info,
    sample_metadata = sample_metadata,
    summary = list(
      total_mutations = total_mutations,
      total_samples = total_samples,
      als_samples = als_samples,
      control_samples = control_samples,
      zero_pct = zero_pct
    )
  ))
}

# Function to filter data based on coverage and quality
filter_mirna_data <- function(mirna_data, config) {
  cat("\nFiltering miRNA data...\n")
  
  count_matrix <- mirna_data$count_matrix
  sample_metadata <- mirna_data$sample_metadata
  
  # Filter by minimum coverage
  min_coverage <- config$data$min_coverage
  cat("Applying minimum coverage filter:", min_coverage, "\n")
  
  # Calculate coverage per mutation (sum across samples)
  mutation_coverage <- rowSums(count_matrix)
  high_coverage_mutations <- mutation_coverage >= min_coverage
  
  cat("Mutations before filtering:", nrow(count_matrix), "\n")
  cat("Mutations after coverage filtering:", sum(high_coverage_mutations), "\n")
  
  # Filter by minimum samples per group
  min_samples_per_group <- config$data$min_samples_per_group
  
  # Check if we have enough samples in each group
  als_count <- sum(sample_metadata$group == "ALS")
  control_count <- sum(sample_metadata$group == "Control")
  
  if (als_count < min_samples_per_group) {
    warning("ALS group has only ", als_count, " samples, less than minimum ", min_samples_per_group)
  }
  if (control_count < min_samples_per_group) {
    warning("Control group has only ", control_count, " samples, less than minimum ", min_samples_per_group)
  }
  
  # Apply filters
  filtered_count_matrix <- count_matrix[high_coverage_mutations, ]
  filtered_mirna_info <- mirna_data$mirna_info[high_coverage_mutations]
  
  cat("Final filtered dataset:\n")
  cat("- Mutations:", nrow(filtered_count_matrix), "\n")
  cat("- Samples:", ncol(filtered_count_matrix), "\n")
  
  return(list(
    count_matrix = filtered_count_matrix,
    mirna_info = filtered_mirna_info,
    sample_metadata = sample_metadata,
    summary = mirna_data$summary
  ))
}

# Function to create G>T specific analysis
prepare_gt_analysis <- function(mirna_data) {
  cat("\nPreparing G>T analysis...\n")
  
  # Identify G>T mutations (these are the oxidation events)
  gt_mutations <- mirna_data$mirna_info[str_detect(mutation, "GT|TG"), ]
  
  if (nrow(gt_mutations) == 0) {
    cat("No G>T mutations found in the dataset.\n")
    cat("Available mutation types:", unique(mirna_data$mirna_info$mutation), "\n")
    return(NULL)
  }
  
  cat("Found", nrow(gt_mutations), "G>T mutations\n")
  
  # Extract G>T count matrix
  gt_indices <- which(str_detect(mirna_data$mirna_info$mutation, "GT|TG"))
  gt_count_matrix <- mirna_data$count_matrix[gt_indices, ]
  
  # Calculate G>T levels per sample
  gt_levels <- colSums(gt_count_matrix)
  
  # Create summary table
  gt_summary <- data.table(
    sample_id = names(gt_levels),
    gt_count = gt_levels,
    group = mirna_data$sample_metadata$group[match(names(gt_levels), mirna_data$sample_metadata$sample_id)]
  )
  
  return(list(
    gt_count_matrix = gt_count_matrix,
    gt_mutations = gt_mutations,
    gt_summary = gt_summary
  ))
}

# Main data loading function
load_and_prepare_data <- function(config_file = "config.yaml") {
  # Load configuration
  config <- yaml::read_yaml(config_file)
  
  # Load miRNA data
  mirna_data <- load_mirna_data(config$data$input_matrix, config)
  
  # Filter data
  filtered_data <- filter_mirna_data(mirna_data, config)
  
  # Prepare G>T analysis
  gt_analysis <- prepare_gt_analysis(filtered_data)
  
  return(list(
    raw_data = mirna_data,
    filtered_data = filtered_data,
    gt_analysis = gt_analysis,
    config = config
  ))
}

# Test the data loading
if (interactive()) {
  cat("=== Testing miRNA Data Loading ===\n")
  
  # Load and prepare data
  data_results <- load_and_prepare_data()
  
  # Save sample metadata
  fwrite(data_results$filtered_data$sample_metadata, "sample_metadata.tsv", sep = "\t")
  cat("\nSample metadata saved to: sample_metadata.tsv\n")
  
  # Print final summary
  cat("\n=== FINAL DATA SUMMARY ===\n")
  cat("Raw data mutations:", data_results$raw_data$summary$total_mutations, "\n")
  cat("Filtered data mutations:", nrow(data_results$filtered_data$count_matrix), "\n")
  cat("Total samples:", data_results$filtered_data$summary$total_samples, "\n")
  cat("ALS samples:", data_results$filtered_data$summary$als_samples, "\n")
  cat("Control samples:", data_results$filtered_data$summary$control_samples, "\n")
  
  if (!is.null(data_results$gt_analysis)) {
    cat("G>T mutations found:", nrow(data_results$gt_analysis$gt_mutations), "\n")
  } else {
    cat("No G>T mutations found in the dataset\n")
  }
}

