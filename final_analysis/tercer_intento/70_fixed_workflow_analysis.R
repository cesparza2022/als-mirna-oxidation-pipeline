# =============================================================================
# FIXED WORKFLOW ANALYSIS - HANDLING ACTUAL DATA STRUCTURE
# =============================================================================

library(dplyr)
library(ggplot2)
library(knitr)
library(rmarkdown)
library(gridExtra)
library(viridis)
library(RColorBrewer)
library(reshape2)
library(stringr)

# Set working directory
setwd("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/tercer_intento")

cat("=== FIXED WORKFLOW ANALYSIS ===\n")

# Create output directory
output_dir <- "correct_workflow_analysis"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Create figures directory
figures_dir <- file.path(output_dir, "figures")
if (!dir.exists(figures_dir)) {
  dir.create(figures_dir, recursive = TRUE)
}

# =============================================================================
# STEP 1: LOAD ORIGINAL DATASET AND EXPLORE
# =============================================================================

cat("STEP 1: LOADING ORIGINAL DATASET\n")
cat("================================\n")

# Load the original dataset
original_file <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/results/Magen_ALS-bloodplasma/miRNA_count.Q33.txt"

if (file.exists(original_file)) {
  cat("Loading original dataset...\n")
  
  # Load with proper column handling
  original_data <- read.table(original_file, 
                             sep = "\t", 
                             header = TRUE, 
                             stringsAsFactors = FALSE,
                             check.names = FALSE)
  
  cat("Original dataset loaded successfully!\n")
  cat("Dimensions:", nrow(original_data), "x", ncol(original_data), "\n")
  
  # Examine the actual structure
  cat("\nFirst few rows and columns:\n")
  print(head(original_data[, 1:10]))
  
  # Check column names
  cat("\nColumn names (first 20):\n")
  print(colnames(original_data)[1:20])
  
  # Identify miRNA and position columns
  if ("miRNA.name" %in% colnames(original_data)) {
    cat("Found miRNA.name column\n")
  } else {
    cat("miRNA.name column not found. Available columns:\n")
    print(colnames(original_data)[1:10])
  }
  
  if ("pos.mut" %in% colnames(original_data)) {
    cat("Found pos.mut column\n")
  } else {
    cat("pos.mut column not found. Available columns:\n")
    print(colnames(original_data)[1:10])
  }
  
  # Let's examine the actual structure more carefully
  cat("\nExamining data structure...\n")
  
  # Check if we have the right columns
  if ("miRNA.name" %in% colnames(original_data) && "pos.mut" %in% colnames(original_data)) {
    # This is the expected structure
    sample_cols <- colnames(original_data)[!colnames(original_data) %in% c("miRNA.name", "pos.mut")]
    count_cols <- sample_cols[!grepl("\\.\\.PM\\.1MM\\.2MM\\.$", sample_cols)]
    total_cols <- sample_cols[grepl("\\.\\.PM\\.1MM\\.2MM\\.$", sample_cols)]
    
    cat("Dataset Structure (Expected):\n")
    cat("- Rows (SNVs):", nrow(original_data), "\n")
    cat("- Columns:", ncol(original_data), "\n")
    cat("- miRNA names:", length(unique(original_data$miRNA.name)), "\n")
    cat("- Sample count columns:", length(count_cols), "\n")
    cat("- Sample total columns:", length(total_cols), "\n")
    
    # Create dataset overview figure
    p1 <- ggplot() +
      annotate("text", x = 0.5, y = 0.7, 
               label = paste0("ORIGINAL DATASET OVERVIEW\n\n",
                             "• Total SNVs: ", nrow(original_data), "\n",
                             "• Unique miRNAs: ", length(unique(original_data$miRNA.name)), "\n",
                             "• Sample count columns: ", length(count_cols), "\n",
                             "• Sample total columns: ", length(total_cols), "\n",
                             "• File: miRNA_count.Q33.txt"), 
               size = 5, hjust = 0.5, vjust = 0.5, fontface = "bold") +
      theme_void() +
      theme(plot.background = element_rect(fill = "#f8f9fa", color = "black", linewidth = 1)) +
      labs(title = "Step 1: Original Dataset Structure")
    
    ggsave(file.path(figures_dir, "step1_original_dataset_overview.png"), p1, 
           width = 12, height = 8, dpi = 300)
    
    # Analyze sample metadata
    cat("\nAnalyzing sample metadata...\n")
    
    # Extract sample information from column names
    sample_info <- data.frame(
      sample_name = count_cols,
      stringsAsFactors = FALSE
    )
    
    # Identify groups based on sample names
    sample_info$group <- ifelse(grepl("control", sample_info$sample_name, ignore.case = TRUE), 
                               "Control", 
                               ifelse(grepl("ALS", sample_info$sample_name, ignore.case = TRUE), 
                                     "ALS", "Unknown"))
    
    # Count samples by group
    group_counts <- table(sample_info$group)
    cat("Sample distribution:\n")
    print(group_counts)
    
    # Create sample distribution figure
    p2 <- ggplot(sample_info, aes(x = group, fill = group)) +
      geom_bar(alpha = 0.8) +
      scale_fill_manual(values = c("ALS" = "#e74c3c", "Control" = "#3498db", "Unknown" = "#95a5a6")) +
      labs(title = "Sample Distribution by Group",
           x = "Group", 
           y = "Number of Samples") +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
            legend.position = "none") +
      geom_text(aes(label = after_stat(count)), stat = "count", vjust = -0.5, size = 5, fontface = "bold")
    
    ggsave(file.path(figures_dir, "step1_sample_distribution.png"), p2, 
           width = 10, height = 6, dpi = 300)
    
    # Analyze mutation types in original data
    cat("\nAnalyzing mutation types in original data...\n")
    
    # Extract mutation types from pos.mut column
    mutation_types <- str_extract_all(original_data$pos.mut, "[A-Z]>[A-Z]", simplify = TRUE)
    mutation_types_flat <- as.vector(mutation_types)
    mutation_types_flat <- mutation_types_flat[mutation_types_flat != ""]
    
    if (length(mutation_types_flat) > 0) {
      mutation_counts <- table(mutation_types_flat)
      cat("Mutation types in original data:\n")
      print(mutation_counts)
      
      # Create mutation type distribution figure
      mutation_df <- data.frame(
        mutation_type = names(mutation_counts),
        count = as.numeric(mutation_counts)
      )
      
      p3 <- ggplot(mutation_df, aes(x = reorder(mutation_type, count), y = count, fill = mutation_type)) +
        geom_bar(stat = "identity", alpha = 0.8) +
        scale_fill_viridis_d() +
        labs(title = "Distribution of Mutation Types in Original Data",
             x = "Mutation Type", 
             y = "Count") +
        theme_minimal() +
        theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
              axis.text.x = element_text(angle = 45, hjust = 1),
              legend.position = "none") +
        coord_flip()
      
      ggsave(file.path(figures_dir, "step1_mutation_types_distribution.png"), p3, 
             width = 10, height = 6, dpi = 300)
    } else {
      cat("No mutation types found in pos.mut column\n")
      
      # Create a simple figure showing no mutations found
      p3 <- ggplot() +
        annotate("text", x = 0.5, y = 0.5, 
                 label = "No mutation types found in pos.mut column\n\nThis might indicate a different data format\nor the need to examine the data structure more carefully", 
                 size = 4, hjust = 0.5, vjust = 0.5) +
        theme_void() +
        theme(plot.background = element_rect(fill = "#f8d7da", color = "black", linewidth = 1)) +
        labs(title = "Mutation Type Analysis - No Data Found")
      
      ggsave(file.path(figures_dir, "step1_mutation_types_distribution.png"), p3, 
             width = 10, height = 6, dpi = 300)
    }
    
  } else {
    cat("Unexpected data structure. Let's examine it more carefully...\n")
    
    # Create a diagnostic figure
    p1 <- ggplot() +
      annotate("text", x = 0.5, y = 0.5, 
               label = paste0("UNEXPECTED DATA STRUCTURE\n\n",
                             "• Rows: ", nrow(original_data), "\n",
                             "• Columns: ", ncol(original_data), "\n",
                             "• First column: ", colnames(original_data)[1], "\n",
                             "• Second column: ", colnames(original_data)[2], "\n",
                             "• Need to examine structure more carefully"), 
               size = 4, hjust = 0.5, vjust = 0.5) +
      theme_void() +
      theme(plot.background = element_rect(fill = "#f8d7da", color = "black", linewidth = 1)) +
      labs(title = "Step 1: Unexpected Data Structure")
    
    ggsave(file.path(figures_dir, "step1_original_dataset_overview.png"), p1, 
           width = 12, height = 8, dpi = 300)
  }
  
} else {
  cat("❌ Original dataset not found at:", original_file, "\n")
  stop("Cannot proceed without original dataset")
}

cat("\n=== FIXED WORKFLOW ANALYSIS COMPLETED ===\n")
cat("📁 Output directory: ", output_dir, "\n")
cat("📋 Figures created: ", length(list.files(figures_dir)), "\n")
cat("🎯 Ready to examine the actual data structure!\n")









