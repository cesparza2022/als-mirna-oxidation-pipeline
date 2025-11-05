# =============================================================================
# COMPREHENSIVE ORGANIZATION OF ALL ANALYSIS FILES AND FIGURES
# =============================================================================

library(dplyr)
library(ggplot2)
library(knitr)
library(gridExtra)
library(viridis)

# Set working directory
setwd("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/tercer_intento")

cat("=== COMPREHENSIVE ORGANIZATION OF ALL ANALYSIS ===\n")

# Create comprehensive organization directory
org_dir <- "comprehensive_organization"
if (!dir.exists(org_dir)) {
  dir.create(org_dir, recursive = TRUE)
}

# Create subdirectories for organization
subdirs <- c("analysis_scripts", "data_files", "figures_by_analysis", "results_summary", "code_figure_links")
for (subdir in subdirs) {
  if (!dir.exists(file.path(org_dir, subdir))) {
    dir.create(file.path(org_dir, subdir), recursive = TRUE)
  }
}

# 1. ORGANIZE ALL ANALYSIS SCRIPTS
cat("1. Organizing analysis scripts...\n")

# Find all R scripts
r_scripts <- list.files(".", pattern = "\\.R$", full.names = TRUE)
r_scripts <- r_scripts[!grepl("^[0-9]+_", basename(r_scripts))] # Exclude numbered scripts

# Create script organization
script_org <- data.frame(
  Script_Name = basename(r_scripts),
  Full_Path = r_scripts,
  Analysis_Type = "",
  Description = "",
  Key_Functions = "",
  Output_Files = "",
  Dependencies = "",
  stringsAsFactors = FALSE
)

# Analyze each script and categorize
for (i in 1:length(r_scripts)) {
  script_content <- readLines(r_scripts[i], warn = FALSE)
  
  # Determine analysis type based on content
  if (any(grepl("preprocessing|clean|filter", script_content, ignore.case = TRUE))) {
    script_org$Analysis_Type[i] <- "Data Preprocessing"
  } else if (any(grepl("positional|position", script_content, ignore.case = TRUE))) {
    script_org$Analysis_Type[i] <- "Positional Analysis"
  } else if (any(grepl("oxidative|oxidation", script_content, ignore.case = TRUE))) {
    script_org$Analysis_Type[i] <- "Oxidative Load Analysis"
  } else if (any(grepl("clinical|correlation", script_content, ignore.case = TRUE))) {
    script_org$Analysis_Type[i] <- "Clinical Correlation"
  } else if (any(grepl("pca|principal", script_content, ignore.case = TRUE))) {
    script_org$Analysis_Type[i] <- "PCA Analysis"
  } else if (any(grepl("pathway|pathways", script_content, ignore.case = TRUE))) {
    script_org$Analysis_Type[i] <- "Pathway Analysis"
  } else if (any(grepl("heatmap|cluster", script_content, ignore.case = TRUE))) {
    script_org$Analysis_Type[i] <- "Visualization"
  } else if (any(grepl("presentation|html", script_content, ignore.case = TRUE))) {
    script_org$Analysis_Type[i] <- "Presentation"
  } else {
    script_org$Analysis_Type[i] <- "General Analysis"
  }
  
  # Extract key functions
  func_lines <- script_content[grepl("function|ggplot|plot|analysis", script_content, ignore.case = TRUE)]
  script_org$Key_Functions[i] <- paste(head(func_lines, 3), collapse = "; ")
  
  # Extract output files
  output_lines <- script_content[grepl("write|save|output", script_content, ignore.case = TRUE)]
  script_org$Output_Files[i] <- paste(head(output_lines, 3), collapse = "; ")
  
  # Create description based on content
  first_lines <- paste(script_content[1:min(10, length(script_content))], collapse = " ")
  if (grepl("preprocessing", first_lines, ignore.case = TRUE)) {
    script_org$Description[i] <- "Data cleaning and preprocessing pipeline for miRNA SNV analysis"
  } else if (grepl("positional", first_lines, ignore.case = TRUE)) {
    script_org$Description[i] <- "Analysis of SNV patterns across miRNA positions (1-23)"
  } else if (grepl("oxidative", first_lines, ignore.case = TRUE)) {
    script_org$Description[i] <- "Oxidative load analysis comparing ALS vs Control groups"
  } else if (grepl("clinical", first_lines, ignore.case = TRUE)) {
    script_org$Description[i] <- "Clinical correlation analysis with demographic variables"
  } else if (grepl("pca", first_lines, ignore.case = TRUE)) {
    script_org$Description[i] <- "Principal Component Analysis for dimensionality reduction"
  } else if (grepl("pathway", first_lines, ignore.case = TRUE)) {
    script_org$Description[i] <- "Pathway analysis and miRNA network analysis"
  } else {
    script_org$Description[i] <- "Analysis script for miRNA SNV research"
  }
}

# Save script organization
write.csv(script_org, file.path(org_dir, "analysis_scripts/script_organization.csv"), row.names = FALSE)

# 2. ORGANIZE ALL DATA FILES
cat("2. Organizing data files...\n")

# Find all data files
data_files <- list.files(".", pattern = "\\.(csv|RData|txt)$", full.names = TRUE)
data_files <- data_files[!grepl("^[0-9]+_", basename(data_files))] # Exclude numbered files

# Create data file organization
data_org <- data.frame(
  File_Name = basename(data_files),
  Full_Path = data_files,
  File_Type = "",
  Size_KB = "",
  Description = "",
  Generated_By = "",
  Used_By = "",
  Key_Variables = "",
  stringsAsFactors = FALSE
)

# Analyze each data file
for (i in 1:length(data_files)) {
  file_info <- file.info(data_files[i])
  data_org$Size_KB[i] <- round(file_info$size / 1024, 2)
  
  # Determine file type
  if (grepl("\\.csv$", data_files[i])) {
    data_org$File_Type[i] <- "CSV Data"
  } else if (grepl("\\.RData$", data_files[i])) {
    data_org$File_Type[i] <- "R Data Object"
  } else if (grepl("\\.txt$", data_files[i])) {
    data_org$File_Type[i] <- "Text Data"
  }
  
  # Try to read and analyze content
  tryCatch({
    if (grepl("\\.csv$", data_files[i])) {
      sample_data <- read.csv(data_files[i], nrows = 5)
      data_org$Key_Variables[i] <- paste(colnames(sample_data), collapse = ", ")
      
      # Create description based on filename and content
      if (grepl("posicion", data_files[i])) {
        data_org$Description[i] <- "Positional analysis results with statistical significance"
        data_org$Generated_By[i] <- "Positional analysis scripts"
      } else if (grepl("oxidacion", data_files[i])) {
        data_org$Description[i] <- "Oxidative load analysis summary by group"
        data_org$Generated_By[i] <- "Oxidative load analysis scripts"
      } else if (grepl("muestra", data_files[i])) {
        data_org$Description[i] <- "Sample metrics and demographic data"
        data_org$Generated_By[i] <- "Sample analysis scripts"
      } else if (grepl("seed", data_files[i])) {
        data_org$Description[i] <- "Seed region analysis results"
        data_org$Generated_By[i] <- "Seed region analysis scripts"
      } else if (grepl("vaf", data_files[i])) {
        data_org$Description[i] <- "VAF analysis data for specific positions"
        data_org$Generated_By[i] <- "VAF analysis scripts"
      } else {
        data_org$Description[i] <- "Analysis results data file"
        data_org$Generated_By[i] <- "Various analysis scripts"
      }
    } else if (grepl("\\.RData$", data_files[i])) {
      data_org$Description[i] <- "R data object containing analysis results"
      data_org$Generated_By[i] <- "Analysis scripts with save() function"
    }
  }, error = function(e) {
    data_org$Description[i] <- "Data file (content analysis failed)"
    data_org$Generated_By[i] <- "Unknown"
  })
}

# Save data organization
write.csv(data_org, file.path(org_dir, "data_files/data_organization.csv"), row.names = FALSE)

# 3. ORGANIZE ALL FIGURES BY ANALYSIS TYPE
cat("3. Organizing figures by analysis type...\n")

# Find all figure directories
figure_dirs <- c(
  "enhanced_styled_figures",
  "figures_oxidative_load", 
  "figures_clinical_correlation",
  "figures_robust_pca",
  "figures_pathways"
)

# Create figure organization
figure_org <- data.frame(
  Figure_Name = character(0),
  Full_Path = character(0),
  Analysis_Type = character(0),
  Description = character(0),
  Generated_By = character(0),
  File_Size_KB = numeric(0),
  Figure_Type = character(0),
  Key_Insights = character(0),
  stringsAsFactors = FALSE
)

# Process each figure directory
for (dir in figure_dirs) {
  if (dir.exists(dir)) {
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
      
      # Create description based on filename
      filename <- basename(fig)
      if (grepl("preprocessing", filename)) {
        description <- "Data preprocessing pipeline visualization"
        insights <- "Shows data cleaning steps and quality metrics"
      } else if (grepl("positional", filename)) {
        description <- "Positional analysis of SNV patterns"
        insights <- "Shows significant differences across miRNA positions"
      } else if (grepl("oxidative", filename)) {
        description <- "Oxidative load comparison between groups"
        insights <- "Shows paradoxical pattern with higher VAF in controls"
      } else if (grepl("pca", filename)) {
        description <- "Principal Component Analysis visualization"
        insights <- "Shows dimensionality reduction and clustering"
      } else if (grepl("heatmap", filename)) {
        description <- "Heatmap visualization of data patterns"
        insights <- "Shows correlation patterns and clustering"
      } else if (grepl("boxplot", filename)) {
        description <- "Boxplot comparison between groups"
        insights <- "Shows distribution differences and statistical significance"
      } else if (grepl("scatter", filename)) {
        description <- "Scatter plot showing relationships"
        insights <- "Shows correlations between variables"
      } else if (grepl("histogram", filename)) {
        description <- "Histogram showing data distribution"
        insights <- "Shows frequency distribution of values"
      } else if (grepl("correlation", filename)) {
        description <- "Correlation analysis visualization"
        insights <- "Shows relationships between variables"
      } else if (grepl("network", filename)) {
        description <- "Network analysis visualization"
        insights <- "Shows miRNA interaction networks"
      } else {
        description <- "Analysis visualization"
        insights <- "Shows analysis results"
      }
      
      # Determine figure type
      if (grepl("\\.png$", fig)) {
        fig_type <- "PNG Image"
      } else if (grepl("\\.pdf$", fig)) {
        fig_type <- "PDF Vector"
      } else if (grepl("\\.jpg$|\\.jpeg$", fig)) {
        fig_type <- "JPEG Image"
      } else {
        fig_type <- "Image File"
      }
      
      # Add to organization
      figure_org <- rbind(figure_org, data.frame(
        Figure_Name = filename,
        Full_Path = fig,
        Analysis_Type = analysis_type,
        Description = description,
        Generated_By = "R analysis scripts",
        File_Size_KB = round(file_info$size / 1024, 2),
        Figure_Type = fig_type,
        Key_Insights = insights,
        stringsAsFactors = FALSE
      ))
    }
  }
}

# Also include figures from current directory
current_figures <- list.files(".", pattern = "\\.(png|pdf|jpg|jpeg)$", full.names = TRUE)
for (fig in current_figures) {
  file_info <- file.info(fig)
  filename <- basename(fig)
  
  # Create description based on filename
  if (grepl("distribucion.*posicion", filename)) {
    description <- "Position distribution analysis"
    insights <- "Shows SNV distribution across miRNA positions"
    analysis_type <- "Positional Analysis"
  } else if (grepl("boxplot.*vaf", filename)) {
    description <- "VAF boxplot comparison"
    insights <- "Shows VAF distribution differences between groups"
    analysis_type <- "Oxidative Load Analysis"
  } else if (grepl("heatmap.*vaf", filename)) {
    description <- "VAF heatmap visualization"
    insights <- "Shows VAF patterns across samples and positions"
    analysis_type <- "Visualization"
  } else if (grepl("heatmap.*zscore", filename)) {
    description <- "Z-score heatmap visualization"
    insights <- "Shows standardized differences between groups"
    analysis_type <- "Statistical Analysis"
  } else if (grepl("scatter.*snv", filename)) {
    description <- "SNV count scatter plot"
    insights <- "Shows relationship between SNV counts and other variables"
    analysis_type <- "Correlation Analysis"
  } else {
    description <- "Analysis visualization"
    insights <- "Shows analysis results"
    analysis_type <- "General Analysis"
  }
  
  # Determine figure type
  if (grepl("\\.png$", fig)) {
    fig_type <- "PNG Image"
  } else if (grepl("\\.pdf$", fig)) {
    fig_type <- "PDF Vector"
  } else if (grepl("\\.jpg$|\\.jpeg$", fig)) {
    fig_type <- "JPEG Image"
  } else {
    fig_type <- "Image File"
  }
  
  # Add to organization
  figure_org <- rbind(figure_org, data.frame(
    Figure_Name = filename,
    Full_Path = fig,
    Analysis_Type = analysis_type,
    Description = description,
    Generated_By = "R analysis scripts",
    File_Size_KB = round(file_info$size / 1024, 2),
    Figure_Type = fig_type,
    Key_Insights = insights,
    stringsAsFactors = FALSE
  ))
}

# Save figure organization
write.csv(figure_org, file.path(org_dir, "figures_by_analysis/figure_organization.csv"), row.names = FALSE)

# 4. CREATE CODE-FIGURE LINKS
cat("4. Creating code-figure links...\n")

# Create detailed code-figure mapping
code_figure_links <- data.frame(
  Script_Name = character(0),
  Figure_Name = character(0),
  Analysis_Step = character(0),
  Code_Section = character(0),
  Figure_Purpose = character(0),
  Key_Code_Lines = character(0),
  stringsAsFactors = FALSE
)

# Analyze each script for figure generation
for (script in r_scripts) {
  script_content <- readLines(script, warn = FALSE)
  
  # Find figure generation lines
  fig_lines <- which(grepl("ggsave|png|pdf|jpeg|jpg|plot|ggplot", script_content))
  
  for (line_idx in fig_lines) {
    line_content <- script_content[line_idx]
    
    # Extract figure name if possible
    if (grepl("ggsave.*file.*=", line_content)) {
      fig_name <- gsub(".*file.*=.*[\"']([^\"']+)[\"'].*", "\\1", line_content)
      fig_name <- basename(fig_name)
    } else if (grepl("png.*file.*=", line_content)) {
      fig_name <- gsub(".*file.*=.*[\"']([^\"']+)[\"'].*", "\\1", line_content)
      fig_name <- basename(fig_name)
    } else if (grepl("pdf.*file.*=", line_content)) {
      fig_name <- gsub(".*file.*=.*[\"']([^\"']+)[\"'].*", "\\1", line_content)
      fig_name <- basename(fig_name)
    } else {
      fig_name <- "Generated Figure"
    }
    
    # Determine analysis step
    if (grepl("preprocessing|clean|filter", script_content[max(1, line_idx-10):min(length(script_content), line_idx+10)], ignore.case = TRUE)) {
      analysis_step <- "Data Preprocessing"
    } else if (grepl("positional|position", script_content[max(1, line_idx-10):min(length(script_content), line_idx+10)], ignore.case = TRUE)) {
      analysis_step <- "Positional Analysis"
    } else if (grepl("oxidative|oxidation", script_content[max(1, line_idx-10):min(length(script_content), line_idx+10)], ignore.case = TRUE)) {
      analysis_step <- "Oxidative Load Analysis"
    } else if (grepl("clinical|correlation", script_content[max(1, line_idx-10):min(length(script_content), line_idx+10)], ignore.case = TRUE)) {
      analysis_step <- "Clinical Correlation"
    } else if (grepl("pca|principal", script_content[max(1, line_idx-10):min(length(script_content), line_idx+10)], ignore.case = TRUE)) {
      analysis_step <- "PCA Analysis"
    } else if (grepl("pathway|pathways", script_content[max(1, line_idx-10):min(length(script_content), line_idx+10)], ignore.case = TRUE)) {
      analysis_step <- "Pathway Analysis"
    } else {
      analysis_step <- "General Analysis"
    }
    
    # Determine figure purpose
    if (grepl("boxplot", line_content)) {
      fig_purpose <- "Group comparison visualization"
    } else if (grepl("scatter", line_content)) {
      fig_purpose <- "Correlation analysis"
    } else if (grepl("heatmap", line_content)) {
      fig_purpose <- "Pattern visualization"
    } else if (grepl("histogram", line_content)) {
      fig_purpose <- "Distribution analysis"
    } else if (grepl("bar", line_content)) {
      fig_purpose <- "Categorical comparison"
    } else {
      fig_purpose <- "Data visualization"
    }
    
    # Add to links
    code_figure_links <- rbind(code_figure_links, data.frame(
      Script_Name = basename(script),
      Figure_Name = fig_name,
      Analysis_Step = analysis_step,
      Code_Section = paste("Line", line_idx),
      Figure_Purpose = fig_purpose,
      Key_Code_Lines = line_content,
      stringsAsFactors = FALSE
    ))
  }
}

# Save code-figure links
write.csv(code_figure_links, file.path(org_dir, "code_figure_links/code_figure_mapping.csv"), row.names = FALSE)

# 5. CREATE COMPREHENSIVE SUMMARY
cat("5. Creating comprehensive summary...\n")

# Create summary statistics
summary_stats <- data.frame(
  Metric = c(
    "Total Analysis Scripts",
    "Total Data Files", 
    "Total Figures",
    "Analysis Types",
    "Data File Types",
    "Figure Types",
    "Total File Size (MB)"
  ),
  Count = c(
    nrow(script_org),
    nrow(data_org),
    nrow(figure_org),
    length(unique(script_org$Analysis_Type)),
    length(unique(data_org$File_Type)),
    length(unique(figure_org$Figure_Type)),
    round(sum(as.numeric(data_org$Size_KB), na.rm = TRUE) / 1024, 2)
  ),
  Description = c(
    "R scripts for data analysis",
    "CSV, RData, and text files",
    "PNG, PDF, and JPEG images",
    "Different types of analysis performed",
    "Different data file formats",
    "Different image formats",
    "Total size of all data files"
  )
)

# Save summary
write.csv(summary_stats, file.path(org_dir, "results_summary/summary_statistics.csv"), row.names = FALSE)

# 6. CREATE DETAILED README
cat("6. Creating detailed README...\n")

readme_content <- paste0("# Comprehensive Analysis Organization

## Overview
This directory contains a complete organization of all analysis files, data, and figures from the miRNA SNV analysis in ALS project.

## Directory Structure
```
comprehensive_organization/
├── analysis_scripts/
│   └── script_organization.csv          # All R analysis scripts with descriptions
├── data_files/
│   └── data_organization.csv            # All data files with metadata
├── figures_by_analysis/
│   └── figure_organization.csv          # All figures organized by analysis type
├── results_summary/
│   └── summary_statistics.csv           # Overall project statistics
└── code_figure_links/
    └── code_figure_mapping.csv          # Links between code and generated figures
```

## Analysis Types
1. **Data Preprocessing**: Data cleaning and filtering pipeline
2. **Positional Analysis**: SNV patterns across miRNA positions (1-23)
3. **Oxidative Load Analysis**: G>T mutation analysis comparing ALS vs Control
4. **Clinical Correlation**: Analysis with demographic and clinical variables
5. **PCA Analysis**: Principal Component Analysis for dimensionality reduction
6. **Pathway Analysis**: miRNA pathway and network analysis
7. **Visualization**: Enhanced figures and plots

## Key Findings
- **", sum(script_org$Analysis_Type == "Positional Analysis"), "** positional analysis scripts
- **", sum(script_org$Analysis_Type == "Oxidative Load Analysis"), "** oxidative load analysis scripts  
- **", sum(script_org$Analysis_Type == "Clinical Correlation"), "** clinical correlation scripts
- **", sum(script_org$Analysis_Type == "PCA Analysis"), "** PCA analysis scripts
- **", sum(script_org$Analysis_Type == "Pathway Analysis"), "** pathway analysis scripts
- **", nrow(figure_org), "** total figures generated
- **", nrow(data_org), "** data files created

## File Descriptions

### Analysis Scripts
Each script is categorized by analysis type and includes:
- Key functions used
- Output files generated
- Dependencies
- Detailed descriptions

### Data Files
Each data file includes:
- File type and size
- Key variables
- Description of content
- Which script generated it
- Which scripts use it

### Figures
Each figure includes:
- Analysis type
- Description and purpose
- Key insights
- File size and type
- Which script generated it

### Code-Figure Links
Direct mapping between:
- R scripts and figures they generate
- Analysis steps and visualizations
- Code sections and figure purposes

## Usage
1. **Find Analysis Scripts**: Check `analysis_scripts/script_organization.csv`
2. **Locate Data Files**: Check `data_files/data_organization.csv`
3. **Browse Figures**: Check `figures_by_analysis/figure_organization.csv`
4. **Link Code to Figures**: Check `code_figure_links/code_figure_mapping.csv`
5. **View Summary**: Check `results_summary/summary_statistics.csv`

## Generated on: ", format(Sys.Date(), "%Y-%m-%d"), "
## Total Files Organized: ", nrow(script_org) + nrow(data_org) + nrow(figure_org), "
")

writeLines(readme_content, file.path(org_dir, "README.md"))

# 7. CREATE ANALYSIS WORKFLOW DIAGRAM
cat("7. Creating analysis workflow diagram...\n")

# Create workflow data
workflow_data <- data.frame(
  Step = c(
    "Data Loading",
    "Preprocessing", 
    "Positional Analysis",
    "Oxidative Load Analysis",
    "Clinical Correlation",
    "PCA Analysis",
    "Pathway Analysis",
    "Visualization",
    "Presentation"
  ),
  Scripts = c(
    sum(grepl("load|read", script_org$Key_Functions, ignore.case = TRUE)),
    sum(script_org$Analysis_Type == "Data Preprocessing"),
    sum(script_org$Analysis_Type == "Positional Analysis"),
    sum(script_org$Analysis_Type == "Oxidative Load Analysis"),
    sum(script_org$Analysis_Type == "Clinical Correlation"),
    sum(script_org$Analysis_Type == "PCA Analysis"),
    sum(script_org$Analysis_Type == "Pathway Analysis"),
    sum(script_org$Analysis_Type == "Visualization"),
    sum(script_org$Analysis_Type == "Presentation")
  ),
  Data_Files = c(
    sum(grepl("original|raw", data_org$Description, ignore.case = TRUE)),
    sum(grepl("preprocessing|clean", data_org$Description, ignore.case = TRUE)),
    sum(grepl("positional|position", data_org$Description, ignore.case = TRUE)),
    sum(grepl("oxidative|oxidation", data_org$Description, ignore.case = TRUE)),
    sum(grepl("clinical|correlation", data_org$Description, ignore.case = TRUE)),
    sum(grepl("pca|principal", data_org$Description, ignore.case = TRUE)),
    sum(grepl("pathway|pathways", data_org$Description, ignore.case = TRUE)),
    sum(grepl("figure|plot", data_org$Description, ignore.case = TRUE)),
    sum(grepl("presentation|html", data_org$Description, ignore.case = TRUE))
  ),
  Figures = c(
    sum(grepl("data.*quality|preprocessing", figure_org$Description, ignore.case = TRUE)),
    sum(grepl("preprocessing|pipeline", figure_org$Description, ignore.case = TRUE)),
    sum(grepl("positional|position", figure_org$Description, ignore.case = TRUE)),
    sum(grepl("oxidative|oxidation", figure_org$Description, ignore.case = TRUE)),
    sum(grepl("clinical|correlation", figure_org$Description, ignore.case = TRUE)),
    sum(grepl("pca|principal", figure_org$Description, ignore.case = TRUE)),
    sum(grepl("pathway|network", figure_org$Description, ignore.case = TRUE)),
    sum(grepl("enhanced|styling", figure_org$Description, ignore.case = TRUE)),
    sum(grepl("presentation|comprehensive", figure_org$Description, ignore.case = TRUE))
  )
)

# Save workflow
write.csv(workflow_data, file.path(org_dir, "results_summary/analysis_workflow.csv"), row.names = FALSE)

# Create workflow visualization
p <- ggplot(workflow_data, aes(x = Step, y = Scripts, fill = Step)) +
  geom_col(alpha = 0.8, width = 0.6) +
  geom_text(aes(label = Scripts), vjust = -0.5, size = 3, fontface = 'bold') +
  scale_fill_viridis_d() +
  labs(title = 'Analysis Workflow: Scripts by Step',
       x = 'Analysis Step', y = 'Number of Scripts') +
  theme_minimal() +
  theme(legend.position = 'none',
        axis.text.x = element_text(angle = 45, hjust = 1),
        axis.text = element_text(size = 10),
        axis.title = element_text(size = 12, face = 'bold'),
        plot.title = element_text(size = 14, face = 'bold', hjust = 0.5))

ggsave(file.path(org_dir, "analysis_workflow.png"), p, width = 12, height = 8, dpi = 300)

cat("\n=== COMPREHENSIVE ORGANIZATION COMPLETED ===\n")
cat("📁 Organization directory:", org_dir, "\n")
cat("📊 Scripts organized:", nrow(script_org), "\n")
cat("📁 Data files organized:", nrow(data_org), "\n")
cat("🖼️ Figures organized:", nrow(figure_org), "\n")
cat("🔗 Code-figure links:", nrow(code_figure_links), "\n")
cat("📈 Analysis workflow diagram created\n")
cat("📋 Detailed README created\n")
cat("🔍 Check comprehensive_organization/ directory for complete organization\n")
