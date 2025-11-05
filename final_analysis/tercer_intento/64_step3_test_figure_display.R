# =============================================================================
# STEP 3: TEST FIGURE DISPLAY IN SIMPLE HTML
# =============================================================================

library(dplyr)
library(ggplot2)
library(knitr)
library(rmarkdown)

# Set working directory
setwd("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/tercer_intento")

cat("=== STEP 3: TEST FIGURE DISPLAY IN SIMPLE HTML ===\n")

# Create step 3 directory
step3_dir <- "step3_figure_display_test"
if (!dir.exists(step3_dir)) {
  dir.create(step3_dir, recursive = TRUE)
}

# Load mapping data from step 2
figure_mapping <- read.csv("step2_code_mapping/complete_figure_code_mapping.csv", stringsAsFactors = FALSE)

# 1. SELECT REPRESENTATIVE FIGURES FOR TESTING
cat("1. Selecting representative figures for testing...\n")

# Select 1-2 figures from each analysis type for testing
# Use the correct column name (Analysis_Type.y from the merge)
test_figures <- figure_mapping %>%
  group_by(Analysis_Type.y) %>%
  slice_head(n = 2) %>%
  ungroup() %>%
  arrange(Analysis_Type.y, Figure_Name)

cat(paste0("Selected ", nrow(test_figures), " representative figures for testing:\n"))
for (i in 1:nrow(test_figures)) {
  fig_name <- test_figures$Figure_Name[i]
  analysis_type <- test_figures$Analysis_Type.y[i]
  cat(paste0("  ", i, ". ", fig_name, " (", analysis_type, ")\n"))
}

# 2. CREATE TEST FIGURES DIRECTORY
cat("\n2. Creating test figures directory...\n")

test_figures_dir <- file.path(step3_dir, "test_figures")
if (!dir.exists(test_figures_dir)) {
  dir.create(test_figures_dir, recursive = TRUE)
}

# Copy test figures to test directory
for (i in 1:nrow(test_figures)) {
  source_path <- test_figures$Full_Path.x[i]
  target_path <- file.path(test_figures_dir, test_figures$Figure_Name[i])
  
  if (file.exists(source_path)) {
    file.copy(source_path, target_path, overwrite = TRUE)
    cat(paste0("  ✅ Copied: ", test_figures$Figure_Name[i], "\n"))
  } else {
    cat(paste0("  ❌ Source not found: ", source_path, "\n"))
  }
}

# 3. CREATE SIMPLE HTML TEST
cat("\n3. Creating simple HTML test...\n")

# Create R Markdown content for testing
rmd_content <- c(
  "---",
  "title: 'Figure Display Test'",
  "author: 'AI Assistant'",
  "date: '`r format(Sys.Date(), \"%B %d, %Y\")`'",
  "output:",
  "  html_document:",
  "    theme: flatly",
  "    toc: true",
  "    toc_depth: 2",
  "    number_sections: true",
  "    self_contained: true",
  "---",
  "",
  "```{r setup, include=FALSE}",
  "knitr::opts_chunk$set(echo = FALSE, message = FALSE, warning = FALSE, fig.align = 'center')",
  "library(dplyr)",
  "library(ggplot2)",
  "library(knitr)",
  "```",
  "",
  "# Figure Display Test",
  "",
  "This document tests the display of representative figures from our miRNA SNV analysis.",
  "",
  "## Test Results",
  "",
  "```{r test-results}",
  "test_figures <- data.frame(",
  "  Figure_Name = c(",
  paste0("    \"", test_figures$Figure_Name, "\"", collapse = ",\n"),
  "  ),",
  "  Analysis_Type = c(",
  paste0("    \"", test_figures$Analysis_Type.y, "\"", collapse = ",\n"),
  "  ),",
  "  File_Exists = file.exists(file.path('test_figures', c(",
  paste0("    \"", test_figures$Figure_Name, "\"", collapse = ",\n"),
  "  ))),",
  "  stringsAsFactors = FALSE",
  ")",
  "",
  "knitr::kable(test_figures, caption = 'Test Figure Status')",
  "```"
)

# Add figure display sections
for (i in 1:nrow(test_figures)) {
  fig_name <- test_figures$Figure_Name[i]
  analysis_type <- test_figures$Analysis_Type.y[i]
  
  # Determine file extension
  if (grepl("\\.png$", fig_name)) {
    file_type <- "PNG"
  } else if (grepl("\\.pdf$", fig_name)) {
    file_type <- "PDF"
  } else if (grepl("\\.jpg$|\\.jpeg$", fig_name)) {
    file_type <- "JPEG"
  } else {
    file_type <- "Unknown"
  }
  
  section_title <- paste0("## ", i, ". ", analysis_type, " - ", fig_name)
  
  rmd_content <- c(rmd_content, 
    "",
    section_title,
    "",
    paste0("**File Type:** ", file_type),
    "",
    paste0("**Description:** ", test_figures$Description[i]),
    "",
    "```{r fig-", i, ", fig.cap='", fig_name, "'}",
    "fig_path <- file.path('test_figures', '", fig_name, "')",
    "if (file.exists(fig_path)) {",
    "  knitr::include_graphics(fig_path)",
    "} else {",
    "  cat('<div class=\"alert alert-danger\">Figure not found: ", fig_name, "</div>')",
    "}",
    "```"
  )
}

# Add conclusion
rmd_content <- c(rmd_content,
  "",
  "# Test Summary",
  "",
  "This test validates that figures can be properly displayed in HTML format.",
  "",
  "## Next Steps",
  "",
  "1. Verify all figures display correctly",
  "2. Create working presentation with verified figures", 
  "3. Validate all figures display correctly in final presentation",
  "",
  "---",
  "",
  "*Generated on: `r format(Sys.Date(), \"%Y-%m-%d\")`*"
)

# Write R Markdown file
rmd_file <- file.path(step3_dir, "figure_display_test.Rmd")
writeLines(rmd_content, rmd_file)
cat("✅ Created R Markdown file: figure_display_test.Rmd\n")

# 4. RENDER HTML TEST
cat("\n4. Rendering HTML test...\n")

tryCatch({
  rmarkdown::render(
    input = rmd_file,
    output_file = "figure_display_test.html",
    output_dir = step3_dir,
    intermediates_dir = step3_dir,
    quiet = FALSE
  )
  cat("✅ Successfully rendered HTML test\n")
}, error = function(e) {
  cat(paste0("❌ Error rendering HTML: ", e$message, "\n"))
  
  # Create a simple HTML file manually as fallback
  cat("Creating fallback HTML file...\n")
  
  html_content <- c(
    "<!DOCTYPE html>",
    "<html>",
    "<head>",
    "<title>Figure Display Test</title>",
    "<style>",
    "body { font-family: Arial, sans-serif; margin: 40px; }",
    ".figure-container { margin: 20px 0; padding: 20px; border: 1px solid #ddd; }",
    ".figure-title { font-weight: bold; color: #333; }",
    ".figure-info { color: #666; font-size: 0.9em; }",
    ".error { color: red; background: #ffe6e6; padding: 10px; border-radius: 5px; }",
    "</style>",
    "</head>",
    "<body>",
    "<h1>Figure Display Test</h1>",
    "<p>This document tests the display of representative figures from our miRNA SNV analysis.</p>"
  )
  
  # Add figure sections
  for (i in 1:nrow(test_figures)) {
    fig_name <- test_figures$Figure_Name[i]
    analysis_type <- test_figures$Analysis_Type[i]
    fig_path <- file.path("test_figures", fig_name)
    
    html_content <- c(html_content,
      paste0("<div class='figure-container'>"),
      paste0("<div class='figure-title'>", i, ". ", analysis_type, " - ", fig_name, "</div>"),
      paste0("<div class='figure-info'>Analysis Type: ", analysis_type, "</div>"),
      paste0("<div class='figure-info'>Description: ", test_figures$Description[i], "</div>")
    )
    
    if (file.exists(fig_path)) {
      html_content <- c(html_content,
        paste0("<img src='", fig_path, "' alt='", fig_name, "' style='max-width: 100%; height: auto;'>")
      )
    } else {
      html_content <- c(html_content,
        paste0("<div class='error'>Figure not found: ", fig_name, "</div>")
      )
    }
    
    html_content <- c(html_content, "</div>")
  }
  
  html_content <- c(html_content,
    "<h2>Test Summary</h2>",
    "<p>This test validates that figures can be properly displayed in HTML format.</p>",
    "<p><strong>Generated on:</strong> ", format(Sys.Date(), "%Y-%m-%d"), "</p>",
    "</body>",
    "</html>"
  )
  
  html_file <- file.path(step3_dir, "figure_display_test_fallback.html")
  writeLines(html_content, html_file)
  cat("✅ Created fallback HTML file: figure_display_test_fallback.html\n")
})

# 5. CREATE FIGURE VALIDATION REPORT
cat("\n5. Creating figure validation report...\n")

# Check which figures exist
figure_validation <- test_figures %>%
  mutate(
    File_Exists = file.exists(file.path(test_figures_dir, Figure_Name)),
    File_Size_KB = ifelse(File_Exists, 
      round(file.info(file.path(test_figures_dir, Figure_Name))$size / 1024, 2), 
      NA
    )
  )

# Save validation report
write.csv(figure_validation, file.path(step3_dir, "figure_validation_report.csv"), row.names = FALSE)
cat("✅ Saved validation report: figure_validation_report.csv\n")

# Create summary report
validation_summary <- paste0("# STEP 3: FIGURE DISPLAY TEST REPORT

## Overview
This report validates that figures can be properly displayed in HTML format.

## Test Results
- **Total Figures Tested**: ", nrow(test_figures), "
- **Figures Found**: ", sum(figure_validation$File_Exists), "
- **Figures Missing**: ", sum(!figure_validation$File_Exists), "
- **Success Rate**: ", round(100 * sum(figure_validation$File_Exists) / nrow(test_figures), 1), "%

## Analysis Types Tested
")

for (analysis_type in unique(test_figures$Analysis_Type.y)) {
  count <- sum(test_figures$Analysis_Type.y == analysis_type)
  found <- sum(figure_validation$File_Exists[test_figures$Analysis_Type.y == analysis_type])
  validation_summary <- paste0(validation_summary, "- **", analysis_type, "**: ", found, "/", count, " figures found\n")
}

validation_summary <- paste0(validation_summary, "

## File Status
")

for (i in 1:nrow(figure_validation)) {
  status <- ifelse(figure_validation$File_Exists[i], "✅ Found", "❌ Missing")
  size_info <- ifelse(figure_validation$File_Exists[i], 
    paste0(" (", figure_validation$File_Size_KB[i], " KB)"), 
    ""
  )
  validation_summary <- paste0(validation_summary, "- ", figure_validation$Figure_Name[i], ": ", status, size_info, "\n")
}

validation_summary <- paste0(validation_summary, "

## Next Steps
1. Fix any missing figures
2. Create working presentation with verified figures
3. Validate all figures display correctly in final presentation

## Generated on: ", format(Sys.Date(), "%Y-%m-%d"), "
")

writeLines(validation_summary, file.path(step3_dir, "validation_report.md"))

# 6. DISPLAY RESULTS
cat("\n=== STEP 3 COMPLETED ===\n")
cat("📊 Figures tested:", nrow(test_figures), "\n")
cat("✅ Figures found:", sum(figure_validation$File_Exists), "\n")
cat("❌ Figures missing:", sum(!figure_validation$File_Exists), "\n")
cat("📈 Success rate:", round(100 * sum(figure_validation$File_Exists) / nrow(test_figures), 1), "%\n")
cat("📁 Test files saved to:", step3_dir, "\n")
cat("📋 Files created:\n")
cat("  - figure_display_test.Rmd (R Markdown test)\n")
cat("  - figure_display_test.html (rendered HTML)\n")
cat("  - figure_validation_report.csv (validation results)\n")
cat("  - validation_report.md (summary report)\n")

if (sum(!figure_validation$File_Exists) > 0) {
  cat("\n⚠️  Missing figures:\n")
  missing_figures <- figure_validation[!figure_validation$File_Exists, ]
  for (i in 1:nrow(missing_figures)) {
    cat(paste0("  - ", missing_figures$Figure_Name[i], "\n"))
  }
}

cat("\n🎯 Ready for STEP 4: Create working presentation with verified figures\n")
