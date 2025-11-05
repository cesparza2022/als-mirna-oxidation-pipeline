#!/usr/bin/env Rscript

cat("\n")
cat("═════════════════════════════════════════════════════════════════════════\n")
cat("  PASO 2 - MASTER: VAF Quality Control (10 figures)\n")
cat("═════════════════════════════════════════════════════════════════════════\n\n")

library(fs)

base_dir <- "."
scripts_dir <- file.path(base_dir, "scripts")

run_script <- function(script_name) {
  path <- file.path(scripts_dir, script_name)
  if (!file_exists(path)) stop(sprintf("Missing script: %s", path))
  cat(sprintf("▶ Running %s...\n", script_name))
  t0 <- Sys.time()
  source(path, local = TRUE)
  cat(sprintf("   ✅ Done in %.1f sec\n\n", as.numeric(difftime(Sys.time(), t0, units = "secs"))))
}

start_time <- Sys.time()

run_script("01_apply_vaf_filter.R")
run_script("02_generate_diagnostic_figures.R")

cat("─────────────────────────────────────────────────────────────────────────\n")
cat(sprintf("  Total time: %.1f sec\n", as.numeric(difftime(Sys.time(), start_time, units = "secs"))))
cat("  Outputs: data/ALL_MUTATIONS_VAF_FILTERED.csv and QC figures\n")
cat("─────────────────────────────────────────────────────────────────────────\n\n")
