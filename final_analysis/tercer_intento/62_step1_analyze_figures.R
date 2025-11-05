# =============================================================================
# STEP 1: ANALYZE ALL EXISTING FIGURES AND IDENTIFY THEIR SOURCES
# =============================================================================

library(dplyr)
library(ggplot2)

# Set working directory
setwd("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/tercer_intento")

cat("=== STEP 1: ANALYZE ALL EXISTING FIGURES ===\n")

# Create analysis directory
step1_dir <- "step1_figure_analysis"
if (!dir.exists(step1_dir)) {
  dir.create(step1_dir, recursive = TRUE)
}

# 1. FIND ALL FIGURE DIRECTORIES
cat("1. Finding all figure directories...\n")

figure_dirs <- c(
  "enhanced_styled_figures",
  "figures_oxidative_load", 
  "figures_clinical_correlation",
  "figures_robust_pca",
  "figures_pathways"
)

# Also check current directory for figures
current_dir_figures <- list.files(".", pattern = "\\.(png|pdf|jpg|jpeg)$", full.names = TRUE)

# Create comprehensive figure inventory
figure_inventory <- data.frame(
  Figure_Name = character(0),
  Full_Path = character(0),
  Directory = character(0),
  File_Size_KB = numeric(0),
  File_Type = character(0),
  Analysis_Type = character(0),
  Description = character(0),
  Generated_By_Script = character(0),
  stringsAsFactors = FALSE
)

# Process each figure directory
for (dir in figure_dirs) {
  if (dir.exists(dir)) {
    cat(paste0("📁 Processing directory: ", dir, "\n"))
    figures <- list.files(dir, pattern = "\\.(png|pdf|jpg|jpeg)$", full.names = TRUE)
    
    for (fig in figures) {
      file_info <- file.info(fig)
      
      # Determine analysis type based on directory
      if (grepl("enhanced_styled", dir)) {
        analysis_type <- "Enhanced Styling"
      } else if (grepl("oxidative", dir)) {
        analysis_type <- "Oxidative Load Analysis"
      } else if (grepl("clinical", dir)) {
        analysis_type <- "Clinical Correlation"
      } else if (grepl("pca", dir)) {
        analysis_type <- "PCA Analysis"
      } else if (grepl("pathway", dir)) {
        analysis_type <- "Pathway Analysis"
      } else {
        analysis_type <- "General Analysis"
      }
      
      # Determine file type
      if (grepl("\\.png$", fig)) {
        file_type <- "PNG"
      } else if (grepl("\\.pdf$", fig)) {
        file_type <- "PDF"
      } else if (grepl("\\.jpg$|\\.jpeg$", fig)) {
        file_type <- "JPEG"
      } else {
        file_type <- "Unknown"
      }
      
      # Create description based on filename
      filename <- basename(fig)
      description <- ""
      if (grepl("preprocessing", filename, ignore.case = TRUE)) {
        description <- "Data preprocessing pipeline visualization"
      } else if (grepl("positional", filename, ignore.case = TRUE)) {
        description <- "Positional analysis of SNV patterns"
      } else if (grepl("oxidative", filename, ignore.case = TRUE)) {
        description <- "Oxidative load comparison between groups"
      } else if (grepl("pca", filename, ignore.case = TRUE)) {
        description <- "Principal Component Analysis visualization"
      } else if (grepl("heatmap", filename, ignore.case = TRUE)) {
        description <- "Heatmap visualization of data patterns"
      } else if (grepl("boxplot", filename, ignore.case = TRUE)) {
        description <- "Boxplot comparison between groups"
      } else if (grepl("scatter", filename, ignore.case = TRUE)) {
        description <- "Scatter plot showing relationships"
      } else if (grepl("histogram", filename, ignore.case = TRUE)) {
        description <- "Histogram showing data distribution"
      } else if (grepl("correlation", filename, ignore.case = TRUE)) {
        description <- "Correlation analysis visualization"
      } else if (grepl("network", filename, ignore.case = TRUE)) {
        description <- "Network analysis visualization"
      } else if (grepl("variance", filename, ignore.case = TRUE)) {
        description <- "Variance explained analysis"
      } else if (grepl("cluster", filename, ignore.case = TRUE)) {
        description <- "Clustering analysis visualization"
      } else if (grepl("roc", filename, ignore.case = TRUE)) {
        description <- "ROC curve analysis"
      } else if (grepl("bootstrap", filename, ignore.case = TRUE)) {
        description <- "Bootstrap confidence interval analysis"
      } else if (grepl("sensitivity", filename, ignore.case = TRUE)) {
        description <- "Sensitivity analysis"
      } else if (grepl("power", filename, ignore.case = TRUE)) {
        description <- "Statistical power analysis"
      } else if (grepl("mechanism", filename, ignore.case = TRUE)) {
        description <- "Biological mechanism analysis"
      } else if (grepl("family", filename, ignore.case = TRUE)) {
        description <- "miRNA family analysis"
      } else if (grepl("distribution", filename, ignore.case = TRUE)) {
        description <- "Data distribution analysis"
      } else {
        description <- "Analysis visualization"
      }
      
      # Add to inventory
      figure_inventory <- rbind(figure_inventory, data.frame(
        Figure_Name = filename,
        Full_Path = fig,
        Directory = dir,
        File_Size_KB = round(file_info$size / 1024, 2),
        File_Type = file_type,
        Analysis_Type = analysis_type,
        Description = description,
        Generated_By_Script = "Unknown", # Will be filled in step 2
        stringsAsFactors = FALSE
      ))
      
      cat(paste0("  ✅ Found: ", filename, " (", file_type, ", ", round(file_info$size / 1024, 2), " KB)\n"))
    }
  } else {
    cat(paste0("  ❌ Directory not found: ", dir, "\n"))
  }
}

# Process current directory figures
if (length(current_dir_figures) > 0) {
  cat("📁 Processing current directory figures...\n")
  for (fig in current_dir_figures) {
    file_info <- file.info(fig)
    filename <- basename(fig)
    
    # Determine file type
    if (grepl("\\.png$", fig)) {
      file_type <- "PNG"
    } else if (grepl("\\.pdf$", fig)) {
      file_type <- "PDF"
    } else if (grepl("\\.jpg$|\\.jpeg$", fig)) {
      file_type <- "JPEG"
    } else {
      file_type <- "Unknown"
    }
    
    # Create description based on filename
    description <- ""
    if (grepl("distribucion.*posicion", filename, ignore.case = TRUE)) {
      description <- "Position distribution analysis"
      analysis_type <- "Positional Analysis"
    } else if (grepl("boxplot.*vaf", filename, ignore.case = TRUE)) {
      description <- "VAF boxplot comparison"
      analysis_type <- "Oxidative Load Analysis"
    } else if (grepl("heatmap.*vaf", filename, ignore.case = TRUE)) {
      description <- "VAF heatmap visualization"
      analysis_type <- "Visualization"
    } else if (grepl("heatmap.*zscore", filename, ignore.case = TRUE)) {
      description <- "Z-score heatmap visualization"
      analysis_type <- "Statistical Analysis"
    } else if (grepl("scatter.*snv", filename, ignore.case = TRUE)) {
      description <- "SNV count scatter plot"
      analysis_type <- "Correlation Analysis"
    } else if (grepl("comparacion.*subtipos", filename, ignore.case = TRUE)) {
      description <- "ALS subtype comparison"
      analysis_type <- "Subtype Analysis"
    } else if (grepl("correlaciones.*top", filename, ignore.case = TRUE)) {
      description <- "Top SNV correlations"
      analysis_type <- "Correlation Analysis"
    } else if (grepl("distribucion.*snvs.*muestra", filename, ignore.case = TRUE)) {
      description <- "SNV distribution per sample"
      analysis_type <- "Sample Analysis"
    } else if (grepl("distribucion.*vaf.*promedio", filename, ignore.case = TRUE)) {
      description <- "Average VAF distribution per sample"
      analysis_type <- "Sample Analysis"
    } else if (grepl("histograma.*vaf", filename, ignore.case = TRUE)) {
      description <- "VAF histogram analysis"
      analysis_type <- "Distribution Analysis"
    } else if (grepl("clusters.*verificado", filename, ignore.case = TRUE)) {
      description <- "Verified cluster analysis"
      analysis_type <- "Clustering Analysis"
    } else if (grepl("subtipos.*top.*snvs", filename, ignore.case = TRUE)) {
      description <- "Top SNVs by subtype"
      analysis_type <- "Subtype Analysis"
    } else if (grepl("posiciones.*significativas", filename, ignore.case = TRUE)) {
      description <- "Significant positions analysis"
      analysis_type <- "Positional Analysis"
    } else {
      description <- "Analysis visualization"
      analysis_type <- "General Analysis"
    }
    
    # Add to inventory
    figure_inventory <- rbind(figure_inventory, data.frame(
      Figure_Name = filename,
      Full_Path = fig,
      Directory = "current_directory",
      File_Size_KB = round(file_info$size / 1024, 2),
      File_Type = file_type,
      Analysis_Type = analysis_type,
      Description = description,
      Generated_By_Script = "Unknown", # Will be filled in step 2
      stringsAsFactors = FALSE
    ))
    
    cat(paste0("  ✅ Found: ", filename, " (", file_type, ", ", round(file_info$size / 1024, 2), " KB)\n"))
  }
}

# 2. CREATE SUMMARY STATISTICS
cat("\n2. Creating summary statistics...\n")

summary_stats <- data.frame(
  Metric = c(
    "Total Figures Found",
    "PNG Figures",
    "PDF Figures", 
    "JPEG Figures",
    "Enhanced Styling Figures",
    "Oxidative Load Figures",
    "Clinical Correlation Figures",
    "PCA Analysis Figures",
    "Pathway Analysis Figures",
    "Current Directory Figures",
    "Total File Size (MB)"
  ),
  Count = c(
    nrow(figure_inventory),
    sum(figure_inventory$File_Type == "PNG"),
    sum(figure_inventory$File_Type == "PDF"),
    sum(figure_inventory$File_Type == "JPEG"),
    sum(figure_inventory$Analysis_Type == "Enhanced Styling"),
    sum(figure_inventory$Analysis_Type == "Oxidative Load Analysis"),
    sum(figure_inventory$Analysis_Type == "Clinical Correlation"),
    sum(figure_inventory$Analysis_Type == "PCA Analysis"),
    sum(figure_inventory$Analysis_Type == "Pathway Analysis"),
    sum(figure_inventory$Directory == "current_directory"),
    round(sum(figure_inventory$File_Size_KB) / 1024, 2)
  )
)

# 3. SAVE RESULTS
cat("\n3. Saving analysis results...\n")

# Save figure inventory
write.csv(figure_inventory, file.path(step1_dir, "figure_inventory.csv"), row.names = FALSE)
cat("✅ Saved figure inventory: figure_inventory.csv\n")

# Save summary statistics
write.csv(summary_stats, file.path(step1_dir, "summary_statistics.csv"), row.names = FALSE)
cat("✅ Saved summary statistics: summary_statistics.csv\n")

# Create detailed report
report_content <- paste0("# STEP 1: FIGURE ANALYSIS REPORT

## Overview
This report provides a comprehensive analysis of all figures found in the miRNA SNV analysis project.

## Summary Statistics
- **Total Figures Found**: ", nrow(figure_inventory), "
- **PNG Figures**: ", sum(figure_inventory$File_Type == "PNG"), "
- **PDF Figures**: ", sum(figure_inventory$File_Type == "PDF"), "
- **JPEG Figures**: ", sum(figure_inventory$File_Type == "JPEG"), "
- **Total File Size**: ", round(sum(figure_inventory$File_Size_KB) / 1024, 2), " MB

## Analysis Types
")

for (analysis_type in unique(figure_inventory$Analysis_Type)) {
  count <- sum(figure_inventory$Analysis_Type == analysis_type)
  report_content <- paste0(report_content, "- **", analysis_type, "**: ", count, " figures\n")
}

report_content <- paste0(report_content, "

## File Types
")

for (file_type in unique(figure_inventory$File_Type)) {
  count <- sum(figure_inventory$File_Type == file_type)
  report_content <- paste0(report_content, "- **", file_type, "**: ", count, " figures\n")
}

report_content <- paste0(report_content, "

## Directories
")

for (directory in unique(figure_inventory$Directory)) {
  count <- sum(figure_inventory$Directory == directory)
  report_content <- paste0(report_content, "- **", directory, "**: ", count, " figures\n")
}

report_content <- paste0(report_content, "

## Next Steps
1. Map each figure to its generating script
2. Test figure display in HTML
3. Create working presentation
4. Validate all figures display correctly

## Generated on: ", format(Sys.Date(), "%Y-%m-%d"), "
")

writeLines(report_content, file.path(step1_dir, "analysis_report.md"))

# 4. DISPLAY RESULTS
cat("\n=== STEP 1 COMPLETED ===\n")
cat("📊 Total figures found:", nrow(figure_inventory), "\n")
cat("📁 Analysis saved to:", step1_dir, "\n")
cat("📋 Files created:\n")
cat("  - figure_inventory.csv (complete list)\n")
cat("  - summary_statistics.csv (counts by type)\n")
cat("  - analysis_report.md (detailed report)\n")

cat("\n📈 Summary by Analysis Type:\n")
for (analysis_type in unique(figure_inventory$Analysis_Type)) {
  count <- sum(figure_inventory$Analysis_Type == analysis_type)
  cat(paste0("  - ", analysis_type, ": ", count, " figures\n"))
}

cat("\n📁 Summary by Directory:\n")
for (directory in unique(figure_inventory$Directory)) {
  count <- sum(figure_inventory$Directory == directory)
  cat(paste0("  - ", directory, ": ", count, " figures\n"))
}

cat("\n🎯 Ready for STEP 2: Map figures to generating code\n")









