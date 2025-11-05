#!/usr/bin/env Rscript
# ============================================================================
# RUNNER: STEP 1.5 - VAF Quality Control
# ============================================================================
# Orchestrates execution of Step 1.5 VAF filtering scripts

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  STEP 1.5: VAF Quality Control - Running all scripts\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# Get absolute path to pipeline root
current_dir <- normalizePath(getwd())
if (basename(current_dir) == "step1_5") {
  root <- dirname(current_dir)
  step1_5_dir <- current_dir
} else {
  root <- dirname(current_dir)
  step1_5_dir <- file.path(root, "step1_5")
}
scripts_dir <- file.path(step1_5_dir, "scripts")
outputs_dir <- file.path(step1_5_dir, "outputs")

cat("📁 Directories:\n")
cat("   Root:", root, "\n")
cat("   Step1.5:", step1_5_dir, "\n")
cat("   Scripts:", scripts_dir, "\n")
cat("   Outputs:", outputs_dir, "\n\n")

# Ensure output directories exist
dir.create(file.path(outputs_dir, "figures"), showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(outputs_dir, "tables"), showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(outputs_dir, "logs"), showWarnings = FALSE, recursive = TRUE)

# Scripts to run (in order)
scripts <- c(
  "01_apply_vaf_filter.R",
  "02_generate_diagnostic_figures.R"
)

cat("📊 Running Step 1.5 scripts...\n\n")

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
  
  old_wd <- getwd()
  setwd(scripts_dir)
  
  log_file <- file.path(outputs_dir, "logs", paste0(tools::file_path_sans_ext(script), ".log"))
  sink(log_file, split = TRUE)
  
  start_time <- Sys.time()
  
  tryCatch({
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

cat("✅ STEP 1.5 COMPLETE!\n")
cat("   Figures: outputs/figures/\n")
cat("   Tables: outputs/tables/\n")
cat("   Logs: outputs/logs/\n\n")

if (success_count == length(scripts)) {
  cat("🎉 All scripts executed successfully!\n")
} else {
  cat("⚠️  Some scripts failed. Check logs for details.\n")
}

# ============================================================================
# RUNNER: STEP 1.5 - VAF Quality Control
# ============================================================================
# Orchestrates execution of Step 1.5 VAF filtering scripts

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  STEP 1.5: VAF Quality Control - Running all scripts\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# Get absolute path to pipeline root
current_dir <- normalizePath(getwd())
if (basename(current_dir) == "step1_5") {
  root <- dirname(current_dir)
  step1_5_dir <- current_dir
} else {
  root <- dirname(current_dir)
  step1_5_dir <- file.path(root, "step1_5")
}
scripts_dir <- file.path(step1_5_dir, "scripts")
outputs_dir <- file.path(step1_5_dir, "outputs")

cat("📁 Directories:\n")
cat("   Root:", root, "\n")
cat("   Step1.5:", step1_5_dir, "\n")
cat("   Scripts:", scripts_dir, "\n")
cat("   Outputs:", outputs_dir, "\n\n")

# Ensure output directories exist
dir.create(file.path(outputs_dir, "figures"), showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(outputs_dir, "tables"), showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(outputs_dir, "logs"), showWarnings = FALSE, recursive = TRUE)

# Scripts to run (in order)
scripts <- c(
  "01_apply_vaf_filter.R",
  "02_generate_diagnostic_figures.R"
)

cat("📊 Running Step 1.5 scripts...\n\n")

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
  
  old_wd <- getwd()
  setwd(scripts_dir)
  
  log_file <- file.path(outputs_dir, "logs", paste0(tools::file_path_sans_ext(script), ".log"))
  sink(log_file, split = TRUE)
  
  start_time <- Sys.time()
  
  tryCatch({
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

cat("✅ STEP 1.5 COMPLETE!\n")
cat("   Figures: outputs/figures/\n")
cat("   Tables: outputs/tables/\n")
cat("   Logs: outputs/logs/\n\n")

if (success_count == length(scripts)) {
  cat("🎉 All scripts executed successfully!\n")
} else {
  cat("⚠️  Some scripts failed. Check logs for details.\n")
}

# ============================================================================
# RUNNER: STEP 1.5 - VAF Quality Control
# ============================================================================
# Orchestrates execution of Step 1.5 VAF filtering scripts

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("  STEP 1.5: VAF Quality Control - Running all scripts\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("\n")

# Get absolute path to pipeline root
current_dir <- normalizePath(getwd())
if (basename(current_dir) == "step1_5") {
  root <- dirname(current_dir)
  step1_5_dir <- current_dir
} else {
  root <- dirname(current_dir)
  step1_5_dir <- file.path(root, "step1_5")
}
scripts_dir <- file.path(step1_5_dir, "scripts")
outputs_dir <- file.path(step1_5_dir, "outputs")

cat("📁 Directories:\n")
cat("   Root:", root, "\n")
cat("   Step1.5:", step1_5_dir, "\n")
cat("   Scripts:", scripts_dir, "\n")
cat("   Outputs:", outputs_dir, "\n\n")

# Ensure output directories exist
dir.create(file.path(outputs_dir, "figures"), showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(outputs_dir, "tables"), showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(outputs_dir, "logs"), showWarnings = FALSE, recursive = TRUE)

# Scripts to run (in order)
scripts <- c(
  "01_apply_vaf_filter.R",
  "02_generate_diagnostic_figures.R"
)

cat("📊 Running Step 1.5 scripts...\n\n")

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
  
  old_wd <- getwd()
  setwd(scripts_dir)
  
  log_file <- file.path(outputs_dir, "logs", paste0(tools::file_path_sans_ext(script), ".log"))
  sink(log_file, split = TRUE)
  
  start_time <- Sys.time()
  
  tryCatch({
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

cat("✅ STEP 1.5 COMPLETE!\n")
cat("   Figures: outputs/figures/\n")
cat("   Tables: outputs/tables/\n")
cat("   Logs: outputs/logs/\n\n")

if (success_count == length(scripts)) {
  cat("🎉 All scripts executed successfully!\n")
} else {
  cat("⚠️  Some scripts failed. Check logs for details.\n")
}

