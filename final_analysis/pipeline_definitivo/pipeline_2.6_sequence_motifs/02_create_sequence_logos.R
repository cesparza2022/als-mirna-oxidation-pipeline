#!/usr/bin/env Rscript
# ============================================================================
# PASO 2.6.2: SEQUENCE LOGOS POR POSICIÓN
# Crea logos mostrando conservación alrededor de G oxidado
# ============================================================================

library(dplyr)
library(readr)
library(stringr)
library(ggplot2)
library(ggseqlogo)
library(purrr)

COLOR_ALS <- "#D62728"

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║          🎨 CREANDO SEQUENCE LOGOS POR POSICIÓN                      ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

# ============================================================================
# CARGAR DATOS
# ============================================================================

cat("📊 Cargando datos...\n")

candidates <- read_csv("data/candidates_with_sequences.csv", show_col_types = FALSE)
snv_details <- read_csv("data/snv_with_sequence_context.csv", show_col_types = FALSE)

cat(sprintf("✅ %d miRNAs con secuencias\n", nrow(candidates)))
cat(sprintf("✅ %d SNVs con contexto\n\n", nrow(snv_details)))

# ============================================================================
# FUNCIÓN: Extraer ventana alrededor de posición
# ============================================================================

extract_window <- function(seed_seq, position, window_size = 3) {
  # Extraer ventana ±window_size alrededor de la posición
  # position es 1-based en la seed (1-7)
  
  seed_index <- position - 1  # Convertir a índice en seed (0-based conceptual)
  
  start_pos <- max(1, seed_index - window_size + 1)
  end_pos <- min(nchar(seed_seq), seed_index + window_size + 1)
  
  window <- substr(seed_seq, start_pos, end_pos)
  
  return(window)
}

# ============================================================================
# CREAR LOGOS PARA POSICIONES ENRIQUECIDAS (2, 3, 5)
# ============================================================================

enriched_positions <- c(2, 3, 5)

for (pos in enriched_positions) {
  
  cat(paste(rep("═", 70), collapse = ""), "\n")
  cat(sprintf("📊 LOGO PARA POSICIÓN %d\n", pos))
  cat(paste(rep("═", 70), collapse = ""), "\n\n")
  
  # Filtrar SNVs en esta posición
  snvs_this_pos <- snv_details %>%
    filter(Position == pos, !is.na(Seed_Sequence))
  
  if (nrow(snvs_this_pos) == 0) {
    cat("   ⚠️ No hay SNVs en esta posición\n\n")
    next
  }
  
  cat(sprintf("   miRNAs con G>T en pos %d: %d\n", pos, nrow(snvs_this_pos)))
  
  # Extraer ventanas ±3 alrededor del G
  windows <- map_chr(1:nrow(snvs_this_pos), function(i) {
    extract_window(snvs_this_pos$Seed_Sequence[i], pos, window_size = 3)
  })
  
  # Limpiar - asegurar misma longitud
  window_lengths <- nchar(windows)
  mode_length <- as.integer(names(sort(table(window_lengths), decreasing = TRUE)[1]))
  
  windows_clean <- windows[nchar(windows) == mode_length]
  mirnas_clean <- snvs_this_pos$miRNA[nchar(windows) == mode_length]
  
  cat(sprintf("   Ventanas extraídas: %d de longitud %d\n", 
              length(windows_clean), mode_length))
  
  # Mostrar ejemplos
  cat("\n   Ejemplos:\n")
  for (i in 1:min(5, length(windows_clean))) {
    cat(sprintf("     %s: %s\n", mirnas_clean[i], windows_clean[i]))
  }
  cat("\n")
  
  # ============================================================================
  # CREAR LOGO
  # ============================================================================
  
  if (length(windows_clean) >= 3) {
    
    cat("   📊 Generando logo...\n")
    
    # Crear logo plot
    logo_plot <- ggseqlogo(windows_clean, method = "prob", seq_type = "rna") +
      ggtitle(sprintf("Sequence Logo: miRNAs with G>T at Position %d (n=%d)", 
                      pos, length(windows_clean))) +
      theme_classic(base_size = 14) +
      theme(
        plot.title = element_text(face = "bold", hjust = 0.5, size = 16),
        axis.text.x = element_text(size = 12),
        axis.title = element_text(size = 14, face = "bold")
      )
    
    filename <- sprintf("figures/LOGO_Position_%d.png", pos)
    ggsave(filename, logo_plot, width = 12, height = 6, dpi = 300)
    
    cat(sprintf("   ✅ Logo guardado: %s\n\n", filename))
    
  } else {
    cat("   ⚠️ Muy pocas secuencias para crear logo\n\n")
  }
}

# ============================================================================
# CREAR LOGO COMBINADO (Todas las posiciones juntas)
# ============================================================================

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("📊 LOGO COMBINADO: Todas las posiciones enriquecidas\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

# Todas las ventanas (alineadas por el G central)
all_windows <- map_df(enriched_positions, function(pos) {
  snvs_pos <- snv_details %>%
    filter(Position == pos, !is.na(Seed_Sequence))
  
  if (nrow(snvs_pos) > 0) {
    windows <- map_chr(1:nrow(snvs_pos), function(i) {
      extract_window(snvs_pos$Seed_Sequence[i], pos, window_size = 2)
    })
    
    data.frame(
      miRNA = snvs_pos$miRNA,
      Position = pos,
      Window = windows
    )
  }
})

# Filtrar por longitud común
mode_len <- as.integer(names(sort(table(nchar(all_windows$Window)), decreasing = TRUE)[1]))
all_windows_clean <- all_windows %>%
  filter(nchar(Window) == mode_len)

cat(sprintf("   Total ventanas: %d (longitud %d)\n\n", 
            nrow(all_windows_clean), mode_len))

if (nrow(all_windows_clean) >= 5) {
  
  logo_combined <- ggseqlogo(all_windows_clean$Window, method = "prob", seq_type = "rna") +
    ggtitle(sprintf("Combined Sequence Logo: All Enriched Positions (2,3,5) - n=%d", 
                    nrow(all_windows_clean))) +
    labs(subtitle = "Aligned by central G (oxidized position)") +
    theme_classic(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", hjust = 0.5, size = 16),
      plot.subtitle = element_text(hjust = 0.5, size = 12, color = "grey40"),
      axis.text.x = element_text(size = 12)
    )
  
  ggsave("figures/LOGO_ALL_POSITIONS_COMBINED.png", logo_combined, width = 12, height = 6, dpi = 300)
  
  cat("   ✅ Logo combinado guardado\n\n")
}

# ============================================================================
# ANÁLISIS DE CONSERVACIÓN
# ============================================================================

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("📊 ANÁLISIS DE CONSERVACIÓN\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

# Para cada posición relativa al G, calcular frecuencia de nucleótidos
conservation_analysis <- map_df(enriched_positions, function(pos) {
  
  snvs_pos <- snv_details %>%
    filter(Position == pos, !is.na(Seed_Sequence))
  
  if (nrow(snvs_pos) == 0) return(NULL)
  
  # Posición -1 (antes del G)
  before_nucs <- map_chr(1:nrow(snvs_pos), function(i) {
    seed <- snvs_pos$Seed_Sequence[i]
    if (pos > 2) {
      return(substr(seed, pos - 2, pos - 2))
    } else {
      return(NA_character_)
    }
  })
  
  before_counts <- table(before_nucs[!is.na(before_nucs)])
  
  if (length(before_counts) > 0) {
    most_common <- names(which.max(before_counts))
    pct <- round(100 * max(before_counts) / length(before_nucs[!is.na(before_nucs)]), 1)
    
    data.frame(
      Position = pos,
      N_miRNAs = nrow(snvs_pos),
      Most_Common_Before = most_common,
      Pct_Before = pct,
      Is_GpG_Enriched = (most_common == "G" & pct > 40)
    )
  }
})

if (!is.null(conservation_analysis) && nrow(conservation_analysis) > 0) {
  cat("Conservación en posición -1 (antes del G):\n\n")
  print(conservation_analysis)
  cat("\n")
  
  # Resumen
  n_gpg_enriched <- sum(conservation_analysis$Is_GpG_Enriched, na.rm = TRUE)
  
  if (n_gpg_enriched > 0) {
    cat("🔥 HALLAZGO: GpG motif CONSERVADO\n")
    cat(sprintf("   %d/%d posiciones tienen G antes del G oxidado\n", 
                n_gpg_enriched, nrow(conservation_analysis)))
    cat("   → Confirma susceptibilidad específica de GG dinucleótidos\n\n")
  }
}

# ============================================================================
# GUARDAR DATOS
# ============================================================================

write_csv(all_windows_clean, "data/sequence_windows_all.csv")

if (!is.null(conservation_analysis)) {
  write_csv(conservation_analysis, "data/conservation_analysis.csv")
}

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("✅ SEQUENCE LOGOS COMPLETADOS\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

cat("📁 Archivos generados:\n")
cat("   • figures/LOGO_Position_*.png (por posición)\n")
cat("   • figures/LOGO_ALL_POSITIONS_COMBINED.png\n")
cat("   • data/sequence_windows_all.csv\n")
cat("   • data/conservation_analysis.csv\n\n")

cat("🚀 SIGUIENTE:\n")
cat("   Rscript 03_clustering_by_similarity.R\n\n")

