library(dplyr)
library(tidyr)
library(stringr)
library(pheatmap)

data <- read.csv("../../../final_analysis/processed_data/final_processed_data.csv")
metadata <- read.csv("metadata.csv")
sample_cols <- metadata$Sample_ID

all_mutations <- data %>%
  mutate(
    position = as.numeric(str_extract(pos.mut, "^[0-9]+")),
    mutation_type = str_extract(pos.mut, ":[A-Z]+$") %>% str_remove(":")
  ) %>%
  filter(!is.na(position), position <= 22)

mutation_data <- all_mutations %>%
  select(all_of(c("mutation_type", "position", sample_cols))) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "Sample_ID", values_to = "VAF") %>%
  left_join(metadata, by = "Sample_ID") %>%
  group_by(mutation_type, position, Group) %>%
  summarise(Mean_VAF = mean(VAF, na.rm = TRUE), .groups = "drop")

# Crear matrices
create_mat <- function(grp) {
  mat_data <- mutation_data %>%
    filter(Group == grp) %>%
    select(mutation_type, position, Mean_VAF) %>%
    pivot_wider(names_from = position, values_from = Mean_VAF, values_fill = 0)
  
  mat <- as.matrix(mat_data[, -1])
  rownames(mat) <- mat_data$mutation_type
  return(mat)
}

png("figures_paso2/FIGURA_2.11_HEATMAP_MUTATION_TYPES.png", width = 16, height = 8, units = "in", res = 300)
par(mfrow = c(1, 2))

mat_als <- create_mat("ALS")
pheatmap(mat_als, main = "ALS: All Mutation Types", 
         color = colorRampPalette(c("white", "red"))(100),
         cluster_rows = FALSE, cluster_cols = FALSE, fontsize = 8, silent = TRUE)

mat_ctrl <- create_mat("Control")
pheatmap(mat_ctrl, main = "Control: All Mutation Types", 
         color = colorRampPalette(c("white", "blue"))(100),
         cluster_rows = FALSE, cluster_cols = FALSE, fontsize = 8, silent = TRUE)

dev.off()
cat("✅ Figura 2.11 generada exitosamente\n")

