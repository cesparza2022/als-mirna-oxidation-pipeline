# =============================================================================
# FIX DETAILED PRESENTATION - REMOVE DUPLICATE CHUNK LABELS
# =============================================================================

library(dplyr)
library(ggplot2)
library(knitr)
library(rmarkdown)

# Set working directory
setwd("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/tercer_intento")

cat("=== FIXING DETAILED PRESENTATION ===\n")

# Read the existing R Markdown file
detailed_dir <- "comprehensive_detailed_presentation"
rmd_file <- file.path(detailed_dir, "comprehensive_detailed_analysis.Rmd")

if (file.exists(rmd_file)) {
  rmd_content <- readLines(rmd_file)
  
  # Find and fix duplicate chunk labels
  chunk_labels <- c()
  fixed_content <- c()
  
  for (i in seq_along(rmd_content)) {
    line <- rmd_content[i]
    
    # Check if this is a chunk line
    if (grepl("^```\\{r", line)) {
      # Extract chunk label
      label_match <- regexec("```\\{r\\s+([^,}]+)", line)
      if (label_match[[1]][1] != -1) {
        label <- regmatches(line, label_match)[[1]][2]
        
        # Check if label already exists
        if (label %in% chunk_labels) {
          # Create unique label
          counter <- 1
          new_label <- paste0(label, "_", counter)
          while (new_label %in% chunk_labels) {
            counter <- counter + 1
            new_label <- paste0(label, "_", counter)
          }
          
          # Replace the line with unique label
          new_line <- gsub(paste0("```\\{r\\s+", label), paste0("```{r ", new_label), line)
          fixed_content <- c(fixed_content, new_line)
          chunk_labels <- c(chunk_labels, new_label)
          cat(paste0("  🔧 Fixed duplicate label: ", label, " → ", new_label, "\n"))
        } else {
          fixed_content <- c(fixed_content, line)
          chunk_labels <- c(chunk_labels, label)
        }
      } else {
        fixed_content <- c(fixed_content, line)
      }
    } else {
      fixed_content <- c(fixed_content, line)
    }
  }
  
  # Write the fixed content
  writeLines(fixed_content, rmd_file)
  cat("✅ Fixed duplicate chunk labels in R Markdown file\n")
  
  # Now render the presentation
  cat("\nRendering the fixed presentation...\n")
  
  tryCatch({
    rmarkdown::render(
      input = rmd_file,
      output_file = "comprehensive_detailed_analysis.html",
      output_dir = detailed_dir,
      intermediates_dir = detailed_dir,
      quiet = FALSE
    )
    cat("✅ Successfully rendered fixed presentation\n")
  }, error = function(e) {
    cat(paste0("❌ Error rendering fixed presentation: ", e$message, "\n"))
  })
  
} else {
  cat("❌ R Markdown file not found\n")
}

cat("\n=== PRESENTATION FIX COMPLETED ===\n")









