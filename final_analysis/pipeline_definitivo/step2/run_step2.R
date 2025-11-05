#!/usr/bin/env Rscript
cat("\n==== STEP 2: Running generators and syncing density figures ====\n")
root <- "/Users/cesaresparza/New_Desktop/UCSD/8OG/final_analysis/pipeline_definitivo"
pipe2 <- file.path(root, "pipeline_2")
step2 <- file.path(root, "step2")
outputs_clean <- file.path(step2, "outputs", "figures_clean")

# 1) Run the density generator in its native context (non-destructive)
script_density <- file.path(pipe2, "generate_FIG_2.13-15_DENSITY.R")
if (file.exists(script_density)) {
  cat("Running:", script_density, "\n")
  system2("Rscript", c(script_density), stdout = TRUE, stderr = TRUE)
} else {
  cat("WARNING: density script not found:", script_density, "\n")
}

# 2) Copy the exact images used by the reference viewer (golden copies)
cat("\n🔄 Syncing golden copies of density heatmaps...\n")
ref_dir <- file.path(pipe2, "HTML_VIEWERS_FINALES", "figures_paso2_CLEAN")
sel <- c(
  file.path(ref_dir, "FIG_2.13_DENSITY_HEATMAP_ALS.png"),
  file.path(ref_dir, "FIG_2.14_DENSITY_HEATMAP_CONTROL.png"),
  file.path(ref_dir, "FIG_2.15_DENSITY_COMBINED.png")
)
for (src in sel) {
  if (file.exists(src)) {
    file.copy(src, file.path(outputs_clean, basename(src)), overwrite = TRUE)
    cat("   Synced:", basename(src), "\n")
  } else {
    cat("   MISSING:", src, "\n")
  }
}

# 3) Build STEP2_EMBED.html and STEP2.html using dedicated script
cat("\n📄 Building HTML viewers...\n")
build_script <- file.path(step2, "scripts", "build_step2_viewers.R")
if (file.exists(build_script)) {
  source(build_script)
} else {
  cat("WARNING: build_step2_viewers.R not found, skipping viewer generation.\n")
}

cat("\n✅ STEP 2 COMPLETE!\n")
cat("   Viewers available at:\n")
cat("   - ", file.path(step2, "viewers", "STEP2_EMBED.html"), " (embedded images)\n", sep="")
cat("   - ", file.path(step2, "viewers", "STEP2.html"), " (relative paths)\n", sep="")


