#!/usr/bin/env Rscript
# ============================================================================
# RUNNER: STEP 1 - Exploratory Analysis
# ============================================================================
# Orchestrates execution of all Step 1 figure generation scripts
# Similar structure to run_step2.R

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  STEP 1: Exploratory Analysis - Running all panels\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# Get absolute path to pipeline root
# If running from step1/, go up one level to pipeline_definitivo
current_dir <- normalizePath(getwd())
if (basename(current_dir) == "step1") {
  root <- dirname(current_dir)
  step1_dir <- current_dir
} else {
  # If running from elsewhere, assume standard structure
  root <- dirname(current_dir)
  step1_dir <- file.path(root, "step1")
}
scripts_dir <- file.path(step1_dir, "scripts")
outputs_dir <- file.path(step1_dir, "outputs")

cat("📁 Directories:\n")
cat("   Root:", root, "\n")
cat("   Step1:", step1_dir, "\n")
cat("   Scripts:", scripts_dir, "\n")
cat("   Outputs:", outputs_dir, "\n\n")

# Ensure output directories exist
dir.create(file.path(outputs_dir, "figures"), showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(outputs_dir, "tables"), showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(outputs_dir, "logs"), showWarnings = FALSE, recursive = TRUE)

# Scripts to run (in order)
scripts <- c(
  "02_gt_count_by_position.R",
  "03_gx_spectrum.R",
  "04_positional_fraction.R",
  "05_gcontent.R",
  "06_seed_vs_nonseed.R",
  "07_gt_specificity.R"
)

cat("📊 Running Step 1 scripts...\n\n")

success_count <- 0
failed_scripts <- c()

for (script in scripts) {
  script_path <- file.path(scripts_dir, script)
  
  if (!file.exists(script_path)) {
    cat("⚠️  Missing:", script, "\n")
    failed_scripts <- c(failed_scripts, script)
    next
  }
  
  cat("▶️  Running", script, "...\n")
  
  # Change to scripts directory for execution (so relative paths work)
  old_wd <- getwd()
  setwd(scripts_dir)
  
  # Capture output to log
  log_file <- file.path(outputs_dir, "logs", paste0(tools::file_path_sans_ext(script), ".log"))
  sink(log_file, split = TRUE)
  
  start_time <- Sys.time()
  
  tryCatch({
    # Use just script name since we're already in scripts_dir
    source(script, local = TRUE)
    elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    cat("   ✅ Completed in", round(elapsed, 1), "seconds\n\n")
    success_count <- success_count + 1
  }, error = function(e) {
    cat("   ❌ ERROR:", e$message, "\n\n")
    failed_scripts <- c(failed_scripts, script)
  })
  
  sink()
  setwd(old_wd)
}

cat("───────────────────────────────────────────────────────────────────────\n")
cat("📊 SUMMARY:\n")
cat("   ✅ Successful:", success_count, "/", length(scripts), "\n")
if (length(failed_scripts) > 0) {
  cat("   ❌ Failed:", paste(failed_scripts, collapse = ", "), "\n")
}
cat("───────────────────────────────────────────────────────────────────────\n\n")

cat("✅ STEP 1 COMPLETE!\n")
cat("   Figures: outputs/figures/\n")
cat("   Tables: outputs/tables/\n")
cat("   Logs: outputs/logs/\n\n")

if (success_count == length(scripts)) {
  cat("🎉 All panels generated successfully!\n")
} else {
  cat("⚠️  Some scripts failed. Check logs for details.\n")
}


# RUNNER: STEP 1 - Exploratory Analysis
# ============================================================================
# Orchestrates execution of all Step 1 figure generation scripts
# Similar structure to run_step2.R

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  STEP 1: Exploratory Analysis - Running all panels\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# Get absolute path to pipeline root
# If running from step1/, go up one level to pipeline_definitivo
current_dir <- normalizePath(getwd())
if (basename(current_dir) == "step1") {
  root <- dirname(current_dir)
  step1_dir <- current_dir
} else {
  # If running from elsewhere, assume standard structure
  root <- dirname(current_dir)
  step1_dir <- file.path(root, "step1")
}
scripts_dir <- file.path(step1_dir, "scripts")
outputs_dir <- file.path(step1_dir, "outputs")

cat("📁 Directories:\n")
cat("   Root:", root, "\n")
cat("   Step1:", step1_dir, "\n")
cat("   Scripts:", scripts_dir, "\n")
cat("   Outputs:", outputs_dir, "\n\n")

# Ensure output directories exist
dir.create(file.path(outputs_dir, "figures"), showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(outputs_dir, "tables"), showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(outputs_dir, "logs"), showWarnings = FALSE, recursive = TRUE)

# Scripts to run (in order)
scripts <- c(
  "02_gt_count_by_position.R",
  "03_gx_spectrum.R",
  "04_positional_fraction.R",
  "05_gcontent.R",
  "06_seed_vs_nonseed.R",
  "07_gt_specificity.R"
)

cat("📊 Running Step 1 scripts...\n\n")

success_count <- 0
failed_scripts <- c()

for (script in scripts) {
  script_path <- file.path(scripts_dir, script)
  
  if (!file.exists(script_path)) {
    cat("⚠️  Missing:", script, "\n")
    failed_scripts <- c(failed_scripts, script)
    next
  }
  
  cat("▶️  Running", script, "...\n")
  
  # Change to scripts directory for execution (so relative paths work)
  old_wd <- getwd()
  setwd(scripts_dir)
  
  # Capture output to log
  log_file <- file.path(outputs_dir, "logs", paste0(tools::file_path_sans_ext(script), ".log"))
  sink(log_file, split = TRUE)
  
  start_time <- Sys.time()
  
  tryCatch({
    # Use just script name since we're already in scripts_dir
    source(script, local = TRUE)
    elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    cat("   ✅ Completed in", round(elapsed, 1), "seconds\n\n")
    success_count <- success_count + 1
  }, error = function(e) {
    cat("   ❌ ERROR:", e$message, "\n\n")
    failed_scripts <- c(failed_scripts, script)
  })
  
  sink()
  setwd(old_wd)
}

cat("───────────────────────────────────────────────────────────────────────\n")
cat("📊 SUMMARY:\n")
cat("   ✅ Successful:", success_count, "/", length(scripts), "\n")
if (length(failed_scripts) > 0) {
  cat("   ❌ Failed:", paste(failed_scripts, collapse = ", "), "\n")
}
cat("───────────────────────────────────────────────────────────────────────\n\n")

cat("✅ STEP 1 COMPLETE!\n")
cat("   Figures: outputs/figures/\n")
cat("   Tables: outputs/tables/\n")
cat("   Logs: outputs/logs/\n\n")

if (success_count == length(scripts)) {
  cat("🎉 All panels generated successfully!\n")
} else {
  cat("⚠️  Some scripts failed. Check logs for details.\n")
}


# RUNNER: STEP 1 - Exploratory Analysis
# ============================================================================
# Orchestrates execution of all Step 1 figure generation scripts
# Similar structure to run_step2.R

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  STEP 1: Exploratory Analysis - Running all panels\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# Get absolute path to pipeline root
# If running from step1/, go up one level to pipeline_definitivo
current_dir <- normalizePath(getwd())
if (basename(current_dir) == "step1") {
  root <- dirname(current_dir)
  step1_dir <- current_dir
} else {
  # If running from elsewhere, assume standard structure
  root <- dirname(current_dir)
  step1_dir <- file.path(root, "step1")
}
scripts_dir <- file.path(step1_dir, "scripts")
outputs_dir <- file.path(step1_dir, "outputs")

cat("📁 Directories:\n")
cat("   Root:", root, "\n")
cat("   Step1:", step1_dir, "\n")
cat("   Scripts:", scripts_dir, "\n")
cat("   Outputs:", outputs_dir, "\n\n")

# Ensure output directories exist
dir.create(file.path(outputs_dir, "figures"), showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(outputs_dir, "tables"), showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(outputs_dir, "logs"), showWarnings = FALSE, recursive = TRUE)

# Scripts to run (in order)
scripts <- c(
  "02_gt_count_by_position.R",
  "03_gx_spectrum.R",
  "04_positional_fraction.R",
  "05_gcontent.R",
  "06_seed_vs_nonseed.R",
  "07_gt_specificity.R"
)

cat("📊 Running Step 1 scripts...\n\n")

success_count <- 0
failed_scripts <- c()

for (script in scripts) {
  script_path <- file.path(scripts_dir, script)
  
  if (!file.exists(script_path)) {
    cat("⚠️  Missing:", script, "\n")
    failed_scripts <- c(failed_scripts, script)
    next
  }
  
  cat("▶️  Running", script, "...\n")
  
  # Change to scripts directory for execution (so relative paths work)
  old_wd <- getwd()
  setwd(scripts_dir)
  
  # Capture output to log
  log_file <- file.path(outputs_dir, "logs", paste0(tools::file_path_sans_ext(script), ".log"))
  sink(log_file, split = TRUE)
  
  start_time <- Sys.time()
  
  tryCatch({
    # Use just script name since we're already in scripts_dir
    source(script, local = TRUE)
    elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    cat("   ✅ Completed in", round(elapsed, 1), "seconds\n\n")
    success_count <- success_count + 1
  }, error = function(e) {
    cat("   ❌ ERROR:", e$message, "\n\n")
    failed_scripts <- c(failed_scripts, script)
  })
  
  sink()
  setwd(old_wd)
}

cat("───────────────────────────────────────────────────────────────────────\n")
cat("📊 SUMMARY:\n")
cat("   ✅ Successful:", success_count, "/", length(scripts), "\n")
if (length(failed_scripts) > 0) {
  cat("   ❌ Failed:", paste(failed_scripts, collapse = ", "), "\n")
}
cat("───────────────────────────────────────────────────────────────────────\n\n")

cat("✅ STEP 1 COMPLETE!\n")
cat("   Figures: outputs/figures/\n")
cat("   Tables: outputs/tables/\n")
cat("   Logs: outputs/logs/\n\n")

if (success_count == length(scripts)) {
  cat("🎉 All panels generated successfully!\n")
} else {
  cat("⚠️  Some scripts failed. Check logs for details.\n")
}

