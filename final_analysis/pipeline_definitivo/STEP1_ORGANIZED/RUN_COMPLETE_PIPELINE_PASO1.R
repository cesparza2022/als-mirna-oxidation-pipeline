#!/usr/bin/env Rscript
# ============================================================================
# RUNNER: STEP 1 - Exploratory Analysis (Panels B, C, D, E, F, G)
# ============================================================================
# Note: Panel A (dataset evolution) and Panel H (sequence context) will be added next

scripts <- c(
  "scripts/02_gt_count_by_position.R",
  "scripts/03_gx_spectrum.R",
  "scripts/04_positional_fraction.R",
  "scripts/05_gcontent_FINAL_VERSION.R",
  "scripts/06_seed_vs_nonseed.R",
  "scripts/07_gt_specificity.R"
)

cat("\n===============================================================\n")
cat(" RUNNING STEP 1 - Exploratory Analysis (selected panels)\n")
cat("===============================================================\n\n")

for (s in scripts) {
  cat(sprintf("➡️  Running %s...\n", s))
  source(s, local = TRUE)
  cat("\n")
}

cat("✅ STEP 1 RUN COMPLETE\n")

#!/usr/bin/env Rscript

cat("\n")
cat("═════════════════════════════════════════════════════════════════════════\n")
cat("  PASO 1 - MASTER: Exploratory Analysis (8 figures)\n")
cat("═════════════════════════════════════════════════════════════════════════\n\n")

library(fs)

base_dir <- "."
fig_dir <- file.path(base_dir, "figures")
scripts_dir <- file.path(base_dir, "scripts")

dir_create(fig_dir)

run_if_exists <- function(script_name) {
  path <- file.path(scripts_dir, script_name)
  if (file_exists(path)) {
    cat(sprintf("▶ Running %s...\n", script_name))
    t0 <- Sys.time()
    source(path, local = TRUE)
    cat(sprintf("   ✅ Done in %.1f sec\n\n", as.numeric(difftime(Sys.time(), t0, units = "secs"))))
    TRUE
  } else {
    cat(sprintf("   ⚠️  Missing script: %s (skipping)\n\n", script_name))
    FALSE
  }
}

start_time <- Sys.time()
count_done <- 0

# Panel A: Dataset Overview
count_done <- count_done + as.integer(run_if_exists("01_dataset_overview.R"))

# Panel B: G>T Count by Position
count_done <- count_done + as.integer(run_if_exists("02_gt_count_by_position.R"))

# Panel C: G>X Mutation Spectrum
count_done <- count_done + as.integer(run_if_exists("03_gx_spectrum.R"))

# Panel D: Positional Fraction
count_done <- count_done + as.integer(run_if_exists("04_positional_fraction.R"))

# Panel E: G-Content Landscape (available)
count_done <- count_done + as.integer(run_if_exists("05_gcontent_FINAL_VERSION.R"))

# Panel F: Seed vs Non-seed
count_done <- count_done + as.integer(run_if_exists("06_seed_vs_nonseed.R"))

# Panel G: G>T Specificity
count_done <- count_done + as.integer(run_if_exists("07_gt_specificity.R"))

# Panel H: Sequence Context (adjacent nucleotides)
count_done <- count_done + as.integer(run_if_exists("08_sequence_context_adjacent.R"))

cat("─────────────────────────────────────────────────────────────────────────\n")
cat(sprintf("  Completed panels (scripts run): %d / 8\n", count_done))
cat(sprintf("  Total time: %.1f sec\n", as.numeric(difftime(Sys.time(), start_time, units = "secs"))))
cat("  Outputs saved to: figures/\n")
cat("─────────────────────────────────────────────────────────────────────────\n\n")
