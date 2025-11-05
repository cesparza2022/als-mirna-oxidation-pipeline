# =============================================================================
# STEP 2: MAP EACH FIGURE TO ITS GENERATING CODE
# =============================================================================

library(dplyr)
library(stringr)

# Set working directory
setwd("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/tercer_intento")

cat("=== STEP 2: MAP FIGURES TO GENERATING CODE ===\n")

# Create step 2 directory
step2_dir <- "step2_code_mapping"
if (!dir.exists(step2_dir)) {
  dir.create(step2_dir, recursive = TRUE)
}

# Load figure inventory from step 1
figure_inventory <- read.csv("step1_figure_analysis/figure_inventory.csv", stringsAsFactors = FALSE)

# 1. FIND ALL R SCRIPTS
cat("1. Finding all R scripts...\n")

# Look for R scripts in current directory and subdirectories
r_scripts <- list.files(".", pattern = "\\.R$", full.names = TRUE, recursive = TRUE)
r_scripts <- r_scripts[!grepl("step[0-9]", r_scripts)] # Exclude step scripts

cat(paste0("Found ", length(r_scripts), " R scripts:\n"))
for (script in r_scripts) {
  cat(paste0("  📄 ", script, "\n"))
}

# 2. ANALYZE EACH SCRIPT TO FIND FIGURE GENERATION
cat("\n2. Analyzing scripts for figure generation...\n")

# Create mapping data frame
figure_code_mapping <- data.frame(
  Figure_Name = character(0),
  Full_Path = character(0),
  Generating_Script = character(0),
  Code_Line_Start = numeric(0),
  Code_Line_End = numeric(0),
  Code_Snippet = character(0),
  Analysis_Type = character(0),
  stringsAsFactors = FALSE
)

# Function to extract code snippet around a line
extract_code_snippet <- function(lines, target_line, context = 5) {
  start_line <- max(1, target_line - context)
  end_line <- min(length(lines), target_line + context)
  snippet <- paste(lines[start_line:end_line], collapse = "\n")
  return(snippet)
}

# Analyze each script
for (script_path in r_scripts) {
  cat(paste0("📄 Analyzing: ", basename(script_path), "\n"))
  
  tryCatch({
    script_content <- readLines(script_path, warn = FALSE)
    
    # Look for figure generation patterns
    figure_patterns <- c(
      "ggsave\\(",
      "png\\(",
      "pdf\\(",
      "jpeg\\(",
      "dev\\.off\\(\\)",
      "ggsave2\\(",
      "save_plot\\(",
      "cairo_pdf\\(",
      "tiff\\("
    )
    
    for (pattern in figure_patterns) {
      matching_lines <- grep(pattern, script_content, ignore.case = TRUE)
      
      for (line_num in matching_lines) {
        line_content <- script_content[line_num]
        
        # Extract filename from the line
        filename_match <- str_extract(line_content, '"[^"]*\\.(png|pdf|jpg|jpeg|tiff)"')
        if (is.na(filename_match)) {
          filename_match <- str_extract(line_content, "'[^']*\\.(png|pdf|jpg|jpeg|tiff)'")
        }
        
        if (!is.na(filename_match)) {
          # Clean filename
          filename <- gsub('["\']', '', filename_match)
          filename <- basename(filename)
          
          # Check if this figure exists in our inventory
          matching_figures <- figure_inventory[grepl(filename, figure_inventory$Figure_Name, ignore.case = TRUE), ]
          
          if (nrow(matching_figures) > 0) {
            for (i in 1:nrow(matching_figures)) {
              figure_name <- matching_figures$Figure_Name[i]
              
              # Extract code snippet
              code_snippet <- extract_code_snippet(script_content, line_num, 3)
              
              # Determine analysis type from script name
              analysis_type <- ""
              if (grepl("preprocessing", script_path, ignore.case = TRUE)) {
                analysis_type <- "Data Preprocessing"
              } else if (grepl("positional", script_path, ignore.case = TRUE)) {
                analysis_type <- "Positional Analysis"
              } else if (grepl("oxidative", script_path, ignore.case = TRUE)) {
                analysis_type <- "Oxidative Load Analysis"
              } else if (grepl("clinical", script_path, ignore.case = TRUE)) {
                analysis_type <- "Clinical Correlation"
              } else if (grepl("pca", script_path, ignore.case = TRUE)) {
                analysis_type <- "PCA Analysis"
              } else if (grepl("pathway", script_path, ignore.case = TRUE)) {
                analysis_type <- "Pathway Analysis"
              } else if (grepl("enhanced", script_path, ignore.case = TRUE)) {
                analysis_type <- "Enhanced Styling"
              } else {
                analysis_type <- "General Analysis"
              }
              
              # Add to mapping
              figure_code_mapping <- rbind(figure_code_mapping, data.frame(
                Figure_Name = figure_name,
                Full_Path = matching_figures$Full_Path[i],
                Generating_Script = script_path,
                Code_Line_Start = max(1, line_num - 3),
                Code_Line_End = min(length(script_content), line_num + 3),
                Code_Snippet = code_snippet,
                Analysis_Type = analysis_type,
                stringsAsFactors = FALSE
              ))
              
              cat(paste0("  ✅ Mapped: ", filename, " -> ", basename(script_path), " (line ", line_num, ")\n"))
            }
          }
        }
      }
    }
    
  }, error = function(e) {
    cat(paste0("  ❌ Error reading script: ", e$message, "\n"))
  })
}

# 3. HANDLE UNMAPPED FIGURES
cat("\n3. Handling unmapped figures...\n")

mapped_figures <- unique(figure_code_mapping$Figure_Name)
unmapped_figures <- figure_inventory[!figure_inventory$Figure_Name %in% mapped_figures, ]

if (nrow(unmapped_figures) > 0) {
  cat(paste0("Found ", nrow(unmapped_figures), " unmapped figures:\n"))
  
  for (i in 1:nrow(unmapped_figures)) {
    fig_name <- unmapped_figures$Figure_Name[i]
    fig_dir <- unmapped_figures$Directory[i]
    
    # Try to infer the generating script based on directory and filename
    inferred_script <- ""
    
    if (fig_dir == "enhanced_styled_figures") {
      inferred_script <- "enhanced_styled_figures.R (inferred)"
    } else if (fig_dir == "figures_oxidative_load") {
      inferred_script <- "oxidative_load_analysis.R (inferred)"
    } else if (fig_dir == "figures_clinical_correlation") {
      inferred_script <- "clinical_correlation_analysis.R (inferred)"
    } else if (fig_dir == "figures_robust_pca") {
      inferred_script <- "robust_pca_analysis.R (inferred)"
    } else if (fig_dir == "figures_pathways") {
      inferred_script <- "pathway_analysis.R (inferred)"
    } else if (fig_dir == "current_directory") {
      # Try to match based on filename patterns
      if (grepl("distribucion.*posicion", fig_name, ignore.case = TRUE)) {
        inferred_script <- "positional_analysis.R (inferred)"
      } else if (grepl("boxplot.*vaf", fig_name, ignore.case = TRUE)) {
        inferred_script <- "oxidative_load_analysis.R (inferred)"
      } else if (grepl("heatmap", fig_name, ignore.case = TRUE)) {
        inferred_script <- "heatmap_analysis.R (inferred)"
      } else {
        inferred_script <- "unknown_script.R (inferred)"
      }
    } else {
      inferred_script <- "unknown_script.R (inferred)"
    }
    
    # Add unmapped figure with inferred script
    figure_code_mapping <- rbind(figure_code_mapping, data.frame(
      Figure_Name = fig_name,
      Full_Path = unmapped_figures$Full_Path[i],
      Generating_Script = inferred_script,
      Code_Line_Start = NA,
      Code_Line_End = NA,
      Code_Snippet = "Code snippet not found - figure may be generated by different method",
      Analysis_Type = unmapped_figures$Analysis_Type[i],
      stringsAsFactors = FALSE
    ))
    
    cat(paste0("  ⚠️  Unmapped: ", fig_name, " -> ", inferred_script, "\n"))
  }
} else {
  cat("✅ All figures successfully mapped!\n")
}

# 4. CREATE COMPREHENSIVE MAPPING REPORT
cat("\n4. Creating comprehensive mapping report...\n")

# Merge with original figure inventory
complete_mapping <- merge(figure_inventory, figure_code_mapping, by = "Figure_Name", all.x = TRUE)

# Create summary by script
script_summary <- figure_code_mapping %>%
  group_by(Generating_Script) %>%
  summarise(
    Figures_Generated = n(),
    Analysis_Types = paste(unique(Analysis_Type), collapse = ", "),
    .groups = 'drop'
  ) %>%
  arrange(desc(Figures_Generated))

# Create summary by analysis type
analysis_summary <- figure_code_mapping %>%
  group_by(Analysis_Type) %>%
  summarise(
    Figures_Count = n(),
    Scripts_Used = length(unique(Generating_Script)),
    .groups = 'drop'
  ) %>%
  arrange(desc(Figures_Count))

# 5. SAVE RESULTS
cat("\n5. Saving mapping results...\n")

# Save complete mapping
write.csv(complete_mapping, file.path(step2_dir, "complete_figure_code_mapping.csv"), row.names = FALSE)
cat("✅ Saved complete mapping: complete_figure_code_mapping.csv\n")

# Save script summary
write.csv(script_summary, file.path(step2_dir, "script_summary.csv"), row.names = FALSE)
cat("✅ Saved script summary: script_summary.csv\n")

# Save analysis summary
write.csv(analysis_summary, file.path(step2_dir, "analysis_summary.csv"), row.names = FALSE)
cat("✅ Saved analysis summary: analysis_summary.csv\n")

# Create detailed mapping report
mapping_report <- paste0("# STEP 2: FIGURE-CODE MAPPING REPORT

## Overview
This report maps each figure to its generating R script and code location.

## Summary Statistics
- **Total Figures**: ", nrow(figure_inventory), "
- **Successfully Mapped**: ", length(unique(figure_code_mapping$Figure_Name[!grepl("inferred", figure_code_mapping$Generating_Script)])), "
- **Inferred Mappings**: ", length(unique(figure_code_mapping$Figure_Name[grepl("inferred", figure_code_mapping$Generating_Script)])), "
- **Total Scripts Analyzed**: ", length(r_scripts), "

## Scripts by Figure Count
")

for (i in 1:nrow(script_summary)) {
  script_name <- basename(script_summary$Generating_Script[i])
  count <- script_summary$Figures_Generated[i]
  analysis_types <- script_summary$Analysis_Types[i]
  mapping_report <- paste0(mapping_report, "- **", script_name, "**: ", count, " figures (", analysis_types, ")\n")
}

mapping_report <- paste0(mapping_report, "

## Analysis Types by Figure Count
")

for (i in 1:nrow(analysis_summary)) {
  analysis_type <- analysis_summary$Analysis_Type[i]
  count <- analysis_summary$Figures_Count[i]
  scripts <- analysis_summary$Scripts_Used[i]
  mapping_report <- paste0(mapping_report, "- **", analysis_type, "**: ", count, " figures (", scripts, " scripts)\n")
}

mapping_report <- paste0(mapping_report, "

## Next Steps
1. Test figure display in simple HTML
2. Create working presentation with verified figures
3. Validate all figures display correctly

## Generated on: ", format(Sys.Date(), "%Y-%m-%d"), "
")

writeLines(mapping_report, file.path(step2_dir, "mapping_report.md"))

# 6. DISPLAY RESULTS
cat("\n=== STEP 2 COMPLETED ===\n")
cat("📊 Total figures mapped:", nrow(figure_code_mapping), "\n")
cat("📄 Scripts analyzed:", length(r_scripts), "\n")
cat("📁 Analysis saved to:", step2_dir, "\n")
cat("📋 Files created:\n")
cat("  - complete_figure_code_mapping.csv (full mapping)\n")
cat("  - script_summary.csv (scripts by figure count)\n")
cat("  - analysis_summary.csv (analysis types by count)\n")
cat("  - mapping_report.md (detailed report)\n")

cat("\n📈 Top Scripts by Figure Count:\n")
for (i in 1:min(5, nrow(script_summary))) {
  script_name <- basename(script_summary$Generating_Script[i])
  count <- script_summary$Figures_Generated[i]
  cat(paste0("  ", i, ". ", script_name, ": ", count, " figures\n"))
}

cat("\n📊 Analysis Types:\n")
for (i in 1:nrow(analysis_summary)) {
  analysis_type <- analysis_summary$Analysis_Type[i]
  count <- analysis_summary$Figures_Count[i]
  cat(paste0("  - ", analysis_type, ": ", count, " figures\n"))
}

cat("\n🎯 Ready for STEP 3: Test figure display in simple HTML\n")









