# =============================================================================
# STEP 1: TEST FIGURE INCLUSION
# Let's create a simple test to make sure figures are working
# =============================================================================

library(rmarkdown)
library(ggplot2)

# Set working directory
setwd("/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/tercer_intento")

cat("=== STEP 1: TESTING FIGURE INCLUSION ===\n")

# Create test directory
test_dir <- "step1_test_figures"
if (!dir.exists(test_dir)) {
  dir.create(test_dir, recursive = TRUE)
}

# Check what figures we have
pdf_figures <- list.files(".", pattern = "\\.pdf$", full.names = TRUE)
cat("Found", length(pdf_figures), "PDF figures:\n")
for (i in 1:min(5, length(pdf_figures))) {
  cat("  ", basename(pdf_figures[i]), "\n")
}

# Create a simple test R Markdown
test_rmd <- paste0("
---
title: 'Step 1: Test Figure Inclusion'
output: html_document
---

# Test Figure Inclusion

## Test 1: Simple Plot
```{r test-plot, fig.cap='Test plot to verify figure inclusion works'}
library(ggplot2)
data <- data.frame(x = 1:10, y = rnorm(10))
p <- ggplot(data, aes(x = x, y = y)) +
  geom_point() +
  labs(title = 'Test Plot', x = 'X', y = 'Y') +
  theme_minimal()
print(p)
```

## Test 2: Include Existing PDF Figure
```{r test-pdf, fig.cap='Test including an existing PDF figure'}
# Let's try to include one of our existing figures
if (file.exists('", basename(pdf_figures[1]), "')) {
  knitr::include_graphics('", basename(pdf_figures[1]), "')
} else {
  cat('Figure not found')
}
```

## Test 3: List Available Figures
```{r list-figures}
pdf_files <- list.files('.', pattern = '\\\\.pdf$')
cat('Available PDF figures:\\n')
for (f in head(pdf_files, 10)) {
  cat('  ', f, '\\n')
}
```
")

# Write test R Markdown
writeLines(test_rmd, file.path(test_dir, "test_figures.Rmd"))

# Render the test
cat("Rendering test HTML...\n")
tryCatch({
  render(file.path(test_dir, "test_figures.Rmd"), 
         output_file = "test_figures.html",
         output_dir = test_dir,
         quiet = FALSE)
  cat("✅ Test HTML rendered successfully!\n")
}, error = function(e) {
  cat("❌ Error rendering test HTML:", e$message, "\n")
})

cat("\n=== STEP 1 COMPLETED ===\n")
cat("📁 Test directory:", test_dir, "\n")
cat("🌐 Test HTML:", file.path(test_dir, "test_figures.html"), "\n")
cat("🔍 Check if figures are displaying properly\n")









