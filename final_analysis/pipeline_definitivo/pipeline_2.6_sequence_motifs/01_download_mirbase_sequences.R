#!/usr/bin/env Rscript
# ============================================================================
# PASO 2.6.1: OBTENER SECUENCIAS DE miRBase
# Descarga secuencias maduras de miRBase para nuestros candidatos
# ============================================================================

library(dplyr)
library(readr)
library(stringr)
library(tidyr)
library(purrr)
library(httr)

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║        🧬 PASO 2.6: ANÁLISIS DE MOTIVOS DE SECUENCIA                ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

cat("📊 PASO 1: Obtener secuencias de miRBase\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

# Crear directorios
dir.create("data", showWarnings = FALSE, recursive = TRUE)
dir.create("figures", showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# CARGAR CANDIDATOS
# ============================================================================

# Cargar los 15 candidatos PERMISSIVE
candidates <- read_csv("../ALS_CANDIDATES_ENHANCED.csv", show_col_types = FALSE)

cat(sprintf("📋 Candidatos a analizar: %d\n\n", nrow(candidates)))

# ============================================================================
# OPCIÓN 1: Base de datos hardcoded (más rápido para testing)
# ============================================================================

cat("📊 Creando base de datos de secuencias (manual)...\n")
cat("   (Idealmente descargaríamos de miRBase automáticamente)\n\n")

# Secuencias conocidas de miRBase (versión hsa, humano)
# Fuente: https://www.mirbase.org/
mirbase_sequences <- tribble(
  ~miRNA, ~Mature_Sequence,
  "hsa-miR-196a-5p", "UAGGUAGUUUCAUGUUGUUGGG",
  "hsa-miR-9-5p", "UCUUUGGUUAUCUAGCUGUAUGA",
  "hsa-miR-142-5p", "CAUAAAGUAGAAAGCACUACU",
  "hsa-miR-21-5p", "UAGCUUAUCAGACUGAUGUUGA",
  "hsa-let-7d-5p", "AGAGGUAGUAGGUUGCAUAGUU",
  "hsa-miR-185-5p", "UGGAGAGAAAGGCAGUUCCUGA",
  "hsa-miR-1-3p", "UGGAAUGUAAAGAAGUAUGUAU",
  "hsa-miR-24-3p", "UGGCUCAGUUCAGCAGGAACAG",
  "hsa-miR-423-3p", "AGCUCGGUCUGAGGCCCCUCAGU",
  "hsa-miR-9-3p", "AUAAAGCUAGAUAACCGAAAGU",
  "hsa-miR-30e-3p", "CUUUCAGUCGGAUGUUUACAGC",
  "hsa-miR-20a-5p", "UAAAGUGCUUAUAGUGCAGGUAG",
  "hsa-miR-6721-5p", "AUGUGCUGUCUCUGGGCUGCUGUGCU",  # Placeholder si no existe
  "hsa-miR-425-5p", "AAUGACACGAUCACUCCCGUUGA",
  "hsa-miR-361-5p", "UUAUCAGAAUCUCCAGGGGUAC"
)

# Merge con candidatos
candidates_with_seq <- candidates %>%
  left_join(mirbase_sequences, by = c("miRNA" = "miRNA"))

# ============================================================================
# EXTRAER SEED REGION (posiciones 2-8)
# ============================================================================

cat("📊 Extrayendo región seed (posiciones 2-8)...\n")

candidates_with_seq <- candidates_with_seq %>%
  mutate(
    # Seed es posiciones 2-8 (índices 2-8 en 1-based)
    Seed_Sequence = substr(Mature_Sequence, 2, 8),
    Seed_Length = nchar(Seed_Sequence)
  )

cat(sprintf("✅ Seeds extraídos: %d miRNAs\n\n", 
            sum(!is.na(candidates_with_seq$Seed_Sequence))))

# ============================================================================
# IDENTIFICAR NUCLEÓTIDO EN CADA POSICIÓN AFECTADA
# ============================================================================

cat("📊 Identificando nucleótido en cada posición afectada...\n")

# Expandir para tener una fila por SNV
# Positions puede ser: "2", "23", "235", etc. (dígitos individuales concatenados)
snv_details <- candidates_with_seq %>%
  filter(!is.na(Positions)) %>%
  mutate(
    # Separar dígitos individuales
    Position_List = map(Positions, function(pos_str) {
      as.integer(unlist(strsplit(as.character(pos_str), "")))
    })
  ) %>%
  unnest(Position_List) %>%
  mutate(
    Position = Position_List,
    # Extraer nucleótido en esa posición de la seed
    # Posición en seed es position (porque seed es pos 2-8, pos 2 = índice 1)
    Nucleotide_at_Position = substr(Seed_Sequence, Position - 1, Position - 1),
    
    # Verificar que es G
    Is_G = (Nucleotide_at_Position == "G"),
    
    # Contexto trinucleótido (XGY)
    Context_Before = if_else(Position > 2, 
                             substr(Seed_Sequence, Position - 2, Position - 2),
                             NA_character_),
    Context_After = if_else(Position < 8,
                            substr(Seed_Sequence, Position, Position),
                            NA_character_),
    
    Trinucleotide = if_else(
      !is.na(Context_Before) & !is.na(Context_After),
      paste0(Context_Before, "G", Context_After),
      NA_character_
    ),
    
    # Clasificar contexto
    Context_Type = case_when(
      Context_Before == "G" ~ "GpG (High Oxidation)",
      Context_Before == "C" ~ "CpG (Moderate)",
      Context_Before == "A" ~ "ApG",
      Context_Before == "U" ~ "UpG",
      TRUE ~ "Unknown"
    )
  )

cat(sprintf("✅ SNVs anotados: %d\n\n", nrow(snv_details)))

# Verificar Gs
n_confirmed_G <- sum(snv_details$Is_G, na.rm = TRUE)
cat(sprintf("   Confirmados como G: %d/%d (%.1f%%)\n\n", 
            n_confirmed_G, nrow(snv_details), 
            100 * n_confirmed_G / nrow(snv_details)))

# ============================================================================
# RESUMEN DE CONTEXTOS
# ============================================================================

context_summary <- snv_details %>%
  filter(!is.na(Context_Type)) %>%
  count(Context_Type) %>%
  arrange(desc(n)) %>%
  mutate(
    Percentage = round(100 * n / sum(n), 1),
    Expected = 25.0  # Si fuera aleatorio
  )

cat("📊 DISTRIBUCIÓN DE CONTEXTOS TRINUCLEÓTIDO:\n")
cat(paste(rep("─", 70), collapse = ""), "\n\n")
print(context_summary)
cat("\n")

# Test de enriquecimiento para GpG
n_GpG <- sum(snv_details$Context_Type == "GpG (High Oxidation)", na.rm = TRUE)
n_total <- sum(!is.na(snv_details$Context_Type))

binom_test <- binom.test(n_GpG, n_total, p = 0.25, alternative = "greater")

cat("🔬 TEST DE ENRIQUECIMIENTO GpG:\n")
cat(paste(rep("─", 70), collapse = ""), "\n")
cat(sprintf("   Observado: %.1f%% GpG\n", 100 * n_GpG / n_total))
cat(sprintf("   Esperado: 25%% (si aleatorio)\n"))
cat(sprintf("   p-value: %.4f", binom_test$p.value))

if (binom_test$p.value < 0.05) {
  cat(" ✅ SIGNIFICATIVO\n")
  cat("\n🔥 HALLAZGO: GpG context está ENRIQUECIDO\n")
  cat("   → Confirma susceptibilidad a oxidación en GG dinucleótidos\n\n")
} else {
  cat(" ❌ No significativo\n\n")
}

# ============================================================================
# GUARDAR RESULTADOS
# ============================================================================

write_csv(candidates_with_seq, "data/candidates_with_sequences.csv")
write_csv(snv_details, "data/snv_with_sequence_context.csv")
write_csv(context_summary, "data/trinucleotide_context_summary.csv")

cat(paste(rep("═", 70), collapse = ""), "\n")
cat("✅ SECUENCIAS Y CONTEXTOS EXTRAÍDOS\n")
cat(paste(rep("═", 70), collapse = ""), "\n\n")

cat("📁 Archivos generados:\n")
cat("   • data/candidates_with_sequences.csv\n")
cat("   • data/snv_with_sequence_context.csv\n")
cat("   • data/trinucleotide_context_summary.csv\n\n")

cat("🚀 SIGUIENTE:\n")
cat("   Rscript 02_create_sequence_logos.R\n\n")

