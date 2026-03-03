# load packages
library(tidyverse)
library(here)

################################################################################
# AQUEOUS FRACTION
################################################################################

# load data
aq_metadata <- read_csv(here("data", "input", "Aqueous fraction", "Tables", "metadata.csv"))
aq_key <- read_csv(here("data", "input", "Aqueous fraction", "Tables", "Compounds_Aqueous_SIRIUS_InChIKeyFilled_ClassyFireFilled_condensed_verbose.csv"))
aq_key$ID <- as.character(aq_key$ID)

# Parse species and timepoint from sample_group
aq_metadata <- aq_metadata %>%
  mutate(
    sample = tolower(sample),
    sample = gsub("-", "_", sample),
    timepoint = str_extract(sample_group, "\\d+wks"),
    species = str_remove(sample_group, "_\\d+wks$") %>% str_trim()
  )

aq_metadata %>% count(sample_group)

# MS2 only: features that have confirmed MS2 fragmentation data with mzVault/mzCloud scores
ms2_features <- read_csv(here("data", "input", "Aqueous fraction", "Tables", "Normalization outputs", "intensity_log2_loess_medianCentered_FILTERED_groupMAJ_MS2only.csv"))

# pivot long and join metadata + key
aq_ms2_long <- ms2_features %>%
  pivot_longer(cols = -c("ID"), names_to = "sample", values_to = "intensity_log2_loess_medianCentered") %>%
  left_join(aq_metadata, by = "sample") %>%
  mutate(ID = as.character(ID)) %>%
  left_join(aq_key, by = "ID")

# Exclude controls
aq_ms2_filtered <- aq_ms2_long %>%
  filter(!(sample_group %in% c("control_6wks", "control_15wks")))

# --- Distribution of intensities ---
ggplot(aq_ms2_filtered, aes(x = intensity_log2_loess_medianCentered)) +
  geom_histogram(binwidth = 0.5, fill = "blue", color = "black") +
  theme_minimal() +
  labs(title = "Aqueous: Distribution of Log2-Transformed Intensities (Miscanthus)",
       x = "Log2-Transformed Intensity (Loess Median Centered)",
       y = "Frequency")

# --- Overall abundance + prevalence ---
aq_abundance_prevalence <- aq_ms2_filtered %>%
  group_by(Name) %>%
  summarise(
    mean_intensity = mean(intensity_log2_loess_medianCentered, na.rm = TRUE),
    prevalence = sum(!is.na(intensity_log2_loess_medianCentered)) / n()
  )

ggplot(aq_abundance_prevalence, aes(x = mean_intensity, y = prevalence)) +
  geom_point() +
  theme_minimal() +
  labs(title = "Aqueous: Mean Intensity vs Prevalence (All Miscanthus)",
       x = "Mean Log2-Transformed Intensity (Loess Median Centered)",
       y = "Prevalence (Fraction of Samples Detected)")

# --- LIMMA: enriched vs control ---
aq_lfc_long <- read_csv(here("data", "input", "Aqueous fraction", "Stats", "stats-LIMMA-MS2only", "LIMMA_wide_logFC_FILTERED_groupMAJ_MS2only.csv")) %>%
  pivot_longer(cols = -c("ID"), names_to = "contrast", values_to = "logFC")

aq_sig_long <- read_csv(here("data", "input", "Aqueous fraction", "Stats", "stats-LIMMA-MS2only", "LIMMA_wide_Sig_FILTERED_groupMAJ_MS2only.csv")) %>%
  pivot_longer(cols = -c("ID"), names_to = "contrast", values_to = "significant")

aq_limma_results <- aq_lfc_long %>%
  left_join(aq_sig_long, by = c("ID", "contrast")) %>%
  mutate(
    ID = as.character(ID),
    significant = case_when(
      significant == "*" ~ TRUE,
      significant == " " ~ FALSE,
      is.na(significant) ~ FALSE
    )
  ) %>%
  left_join(aq_key, by = "ID")

aq_diff_results <- aq_limma_results %>%
  filter(
    grepl("miscanthus.*6wks.*vs.*control_6wks", contrast) |
    grepl("miscanthus.*15wks.*vs.*control_15wks", contrast)
  ) %>%
  filter(significant == TRUE) %>%
  group_by(Name, `Top ClassyFire Superclass`) %>%
  summarise(mean_logFC = mean(logFC, na.rm = TRUE)) %>%
  arrange(desc(mean_logFC))

aq_abundance_prevalence_limma <- aq_abundance_prevalence %>%
  left_join(aq_diff_results, by = "Name") %>%
  mutate(miscanthus_effect = case_when(
    mean_logFC > 0 ~ "enriched_in_miscanthus",
    mean_logFC < 0 ~ "depleted_in_miscanthus",
    is.na(mean_logFC) ~ "no_significant_change"
  ))

# Scatter: abundance vs prevalence colored by enrichment
ggplot(aq_abundance_prevalence_limma, aes(x = mean_intensity, y = prevalence, color = miscanthus_effect)) +
  geom_point() +
  theme_minimal() +
  labs(title = "Aqueous: Abundance vs Prevalence by Miscanthus Enrichment",
       x = "Mean Log2 Intensity", y = "Prevalence")

# Bar chart: top 30 enriched in miscanthus overall
aq_diff_results %>%
  ungroup() %>%
  slice_max(mean_logFC, n = 30) %>%
  mutate(Name = str_trunc(Name, 40)) %>%
  ggplot(aes(x = reorder(Name, mean_logFC), y = mean_logFC, fill = `Top ClassyFire Superclass`)) +
  geom_col() +
  coord_flip() +
  theme_minimal() +
  labs(title = "Aqueous: Top 30 Metabolites Enriched in Miscanthus vs Control",
       x = NULL, y = "Mean Log2 Fold Change")

# Print top results
aq_abundance_prevalence_limma %>% arrange(desc(mean_logFC)) %>% print(n = 25)
aq_abundance_prevalence_limma %>% arrange(desc(mean_intensity)) %>% print(n = 25)

# --- Species-specific analysis ---
aq_species_summary <- aq_ms2_filtered %>%
  group_by(Name, species) %>%
  summarise(
    mean_intensity = mean(intensity_log2_loess_medianCentered, na.rm = TRUE),
    prevalence = sum(!is.na(intensity_log2_loess_medianCentered)) / n(),
    .groups = "drop"
  )

ggplot(aq_species_summary, aes(x = mean_intensity, y = prevalence, color = species)) +
  geom_point(alpha = 0.5) +
  theme_minimal() +
  labs(title = "Aqueous: Abundance vs Prevalence by Species",
       x = "Mean Log2 Intensity", y = "Prevalence")

# Top 20 enriched per species (from LIMMA)
aq_limma_results %>%
  filter(significant == TRUE) %>%
  filter(grepl("miscanthus.*vs.*control", contrast)) %>%
  mutate(species = str_extract(contrast, "miscanthus[^_]*(?:_[^_]+)*(?=_\\d+wks)")) %>%
  group_by(species, Name) %>%
  summarise(mean_logFC = mean(logFC, na.rm = TRUE), .groups = "drop") %>%
  group_by(species) %>%
  slice_max(mean_logFC, n = 20) %>%
  mutate(Name = str_trunc(Name, 40)) %>%
  ggplot(aes(x = reorder(Name, mean_logFC), y = mean_logFC, fill = species)) +
  geom_col(show.legend = FALSE) +
  coord_flip() +
  facet_wrap(~species, scales = "free_y") +
  theme_minimal() +
  labs(title = "Aqueous: Top 20 Enriched Metabolites by Species",
       x = NULL, y = "Mean Log2 Fold Change")

# --- Timepoint-specific analysis ---
aq_timepoint_summary <- aq_ms2_filtered %>%
  group_by(Name, timepoint) %>%
  summarise(
    mean_intensity = mean(intensity_log2_loess_medianCentered, na.rm = TRUE),
    prevalence = sum(!is.na(intensity_log2_loess_medianCentered)) / n(),
    .groups = "drop"
  )

ggplot(aq_timepoint_summary, aes(x = mean_intensity, y = prevalence, color = timepoint)) +
  geom_point(alpha = 0.5) +
  theme_minimal() +
  labs(title = "Aqueous: Abundance vs Prevalence by Timepoint",
       x = "Mean Log2 Intensity", y = "Prevalence")

# Top 20 enriched per timepoint (from LIMMA)
aq_limma_results %>%
  filter(significant == TRUE) %>%
  filter(
    grepl("miscanthus.*6wks.*vs.*control_6wks", contrast) |
    grepl("miscanthus.*15wks.*vs.*control_15wks", contrast)
  ) %>%
  mutate(timepoint = str_extract(contrast, "\\d+wks")) %>%
  group_by(timepoint, Name) %>%
  summarise(mean_logFC = mean(logFC, na.rm = TRUE), .groups = "drop") %>%
  group_by(timepoint) %>%
  slice_max(mean_logFC, n = 20) %>%
  mutate(Name = str_trunc(Name, 40)) %>%
  ggplot(aes(x = reorder(Name, mean_logFC), y = mean_logFC, fill = timepoint)) +
  geom_col(show.legend = FALSE) +
  coord_flip() +
  facet_wrap(~timepoint, scales = "free_y") +
  theme_minimal() +
  labs(title = "Aqueous: Top 20 Enriched Metabolites by Timepoint",
       x = NULL, y = "Mean Log2 Fold Change")

################################################################################
# ORGANIC FRACTION
################################################################################

or_metadata <- read_csv(here("data", "input", "Organic fraction", "Tables", "metadata.csv"))
or_key <- read_csv(here("data", "input", "Organic fraction", "Tables", "Compounds_Organic_SIRIUS_InChIKeyFilled_ClassyFireFilled_condensed_verbose.csv"))
or_key$ID <- as.character(or_key$ID)

# Parse species and timepoint from sample_group
or_metadata <- or_metadata %>%
  mutate(
    sample = tolower(sample),
    sample = gsub("-", "_", sample),
    timepoint = str_extract(sample_group, "\\d+wks"),
    species = str_remove(sample_group, "_\\d+wks$") %>% str_trim()
  )

ms2_features <- read_csv(here("data", "input", "Organic fraction", "Tables", "Normalization outputs", "intensity_log2_loess_medianCentered_FILTERED_groupMAJ_MS2only.csv"))

or_ms2_long <- ms2_features %>%
  pivot_longer(cols = -c("ID"), names_to = "sample", values_to = "intensity_log2_loess_medianCentered") %>%
  left_join(or_metadata, by = "sample") %>%
  mutate(ID = as.character(ID)) %>%
  left_join(or_key, by = "ID")

or_ms2_filtered <- or_ms2_long %>%
  filter(!(sample_group %in% c("control_6wks", "control_15wks")))

# --- Distribution of intensities ---
ggplot(or_ms2_filtered, aes(x = intensity_log2_loess_medianCentered)) +
  geom_histogram(binwidth = 0.5, fill = "blue", color = "black") +
  theme_minimal() +
  labs(title = "Organic: Distribution of Log2-Transformed Intensities (Miscanthus)",
       x = "Log2-Transformed Intensity (Loess Median Centered)",
       y = "Frequency")

# --- Overall abundance + prevalence ---
or_abundance_prevalence <- or_ms2_filtered %>%
  group_by(Name) %>%
  summarise(
    mean_intensity = mean(intensity_log2_loess_medianCentered, na.rm = TRUE),
    prevalence = sum(!is.na(intensity_log2_loess_medianCentered)) / n()
  )

ggplot(or_abundance_prevalence, aes(x = mean_intensity, y = prevalence)) +
  geom_point() +
  theme_minimal() +
  labs(title = "Organic: Mean Intensity vs Prevalence (All Miscanthus)",
       x = "Mean Log2-Transformed Intensity (Loess Median Centered)",
       y = "Prevalence (Fraction of Samples Detected)")

# --- LIMMA: enriched vs control ---
or_lfc_long <- read_csv(here("data", "input", "Organic fraction", "Stats", "stats-LIMMA-MS2only", "LIMMA_wide_logFC_FILTERED_groupMAJ_MS2only.csv")) %>%
  pivot_longer(cols = -c("ID"), names_to = "contrast", values_to = "logFC")

or_sig_long <- read_csv(here("data", "input", "Organic fraction", "Stats", "stats-LIMMA-MS2only", "LIMMA_wide_Sig_FILTERED_groupMAJ_MS2only.csv")) %>%
  pivot_longer(cols = -c("ID"), names_to = "contrast", values_to = "significant")

or_limma_results <- or_lfc_long %>%
  left_join(or_sig_long, by = c("ID", "contrast")) %>%
  mutate(
    ID = as.character(ID),
    significant = case_when(
      significant == "*" ~ TRUE,
      significant == " " ~ FALSE,
      is.na(significant) ~ FALSE
    )
  ) %>%
  left_join(or_key, by = "ID")

or_diff_results <- or_limma_results %>%
  filter(
    grepl("miscanthus.*6wks.*vs.*control_6wks", contrast) |
    grepl("miscanthus.*15wks.*vs.*control_15wks", contrast)
  ) %>%
  filter(significant == TRUE) %>%
  group_by(Name) %>%
  summarise(mean_logFC = mean(logFC, na.rm = TRUE)) %>%
  arrange(desc(mean_logFC))

or_abundance_prevalence_limma <- or_abundance_prevalence %>%
  left_join(or_diff_results, by = "Name") %>%
  mutate(miscanthus_effect = case_when(
    mean_logFC > 0 ~ "enriched_in_miscanthus",
    mean_logFC < 0 ~ "depleted_in_miscanthus",
    is.na(mean_logFC) ~ "no_significant_change"
  ))

# Scatter: abundance vs prevalence colored by enrichment
ggplot(or_abundance_prevalence_limma, aes(x = mean_intensity, y = prevalence, color = miscanthus_effect)) +
  geom_point() +
  theme_minimal() +
  labs(title = "Organic: Abundance vs Prevalence by Miscanthus Enrichment",
       x = "Mean Log2 Intensity", y = "Prevalence")

# Bar chart: top 30 enriched in miscanthus overall
or_diff_results %>%
  slice_max(mean_logFC, n = 30) %>%
  mutate(Name = str_trunc(Name, 40)) %>%
  ggplot(aes(x = reorder(Name, mean_logFC), y = mean_logFC)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  theme_minimal() +
  labs(title = "Organic: Top 30 Metabolites Enriched in Miscanthus vs Control",
       x = NULL, y = "Mean Log2 Fold Change")

# Print top results
or_abundance_prevalence_limma %>% arrange(desc(mean_logFC)) %>% print(n = 25)
or_abundance_prevalence_limma %>% arrange(desc(mean_intensity)) %>% print(n = 25)

# --- Species-specific analysis ---
or_species_summary <- or_ms2_filtered %>%
  group_by(Name, species) %>%
  summarise(
    mean_intensity = mean(intensity_log2_loess_medianCentered, na.rm = TRUE),
    prevalence = sum(!is.na(intensity_log2_loess_medianCentered)) / n(),
    .groups = "drop"
  )

ggplot(or_species_summary, aes(x = mean_intensity, y = prevalence, color = species)) +
  geom_point(alpha = 0.5) +
  theme_minimal() +
  labs(title = "Organic: Abundance vs Prevalence by Species",
       x = "Mean Log2 Intensity", y = "Prevalence")

or_limma_results %>%
  filter(significant == TRUE) %>%
  filter(grepl("miscanthus.*vs.*control", contrast)) %>%
  mutate(species = str_extract(contrast, "miscanthus[^_]*(?:_[^_]+)*(?=_\\d+wks)")) %>%
  group_by(species, Name) %>%
  summarise(mean_logFC = mean(logFC, na.rm = TRUE), .groups = "drop") %>%
  group_by(species) %>%
  slice_max(mean_logFC, n = 20) %>%
  mutate(Name = str_trunc(Name, 40)) %>%
  ggplot(aes(x = reorder(Name, mean_logFC), y = mean_logFC, fill = species)) +
  geom_col(show.legend = FALSE) +
  coord_flip() +
  facet_wrap(~species, scales = "free_y") +
  theme_minimal() +
  labs(title = "Organic: Top 20 Enriched Metabolites by Species",
       x = NULL, y = "Mean Log2 Fold Change")

# --- Timepoint-specific analysis ---
or_timepoint_summary <- or_ms2_filtered %>%
  group_by(Name, timepoint) %>%
  summarise(
    mean_intensity = mean(intensity_log2_loess_medianCentered, na.rm = TRUE),
    prevalence = sum(!is.na(intensity_log2_loess_medianCentered)) / n(),
    .groups = "drop"
  )

ggplot(or_timepoint_summary, aes(x = mean_intensity, y = prevalence, color = timepoint)) +
  geom_point(alpha = 0.5) +
  theme_minimal() +
  labs(title = "Organic: Abundance vs Prevalence by Timepoint",
       x = "Mean Log2 Intensity", y = "Prevalence")

or_limma_results %>%
  filter(significant == TRUE) %>%
  filter(
    grepl("miscanthus.*6wks.*vs.*control_6wks", contrast) |
    grepl("miscanthus.*15wks.*vs.*control_15wks", contrast)
  ) %>%
  mutate(timepoint = str_extract(contrast, "\\d+wks")) %>%
  group_by(timepoint, Name) %>%
  summarise(mean_logFC = mean(logFC, na.rm = TRUE), .groups = "drop") %>%
  group_by(timepoint) %>%
  slice_max(mean_logFC, n = 20) %>%
  mutate(Name = str_trunc(Name, 40)) %>%
  ggplot(aes(x = reorder(Name, mean_logFC), y = mean_logFC, fill = timepoint)) +
  geom_col(show.legend = FALSE) +
  coord_flip() +
  facet_wrap(~timepoint, scales = "free_y") +
  theme_minimal() +
  labs(title = "Organic: Top 20 Enriched Metabolites by Timepoint",
       x = NULL, y = "Mean Log2 Fold Change")



### Sugar Analysis

sugars <- c("gluco", "fructo", "galacto", "mannos", "xylos", "arabinos", "ribos", "sucros", "pyranos", "furanos")

sugar_ids <- aq_ms2_long %>%
  filter(str_detect(tolower(Name), paste(sugars, collapse = "|"))) %>%
  distinct(ID)

aq_limma_results %>%
  filter(ID %in% sugar_ids$ID) %>%
  filter(
    grepl("miscanthus.*6wks.*vs.*control_6wks", contrast) |
    grepl("miscanthus.*15wks.*vs.*control_15wks", contrast)
  ) %>%
  filter(significant == TRUE) %>%
  mutate(
    species = str_extract(contrast, "miscanthus\\S+(?=_\\d+wks)"),
    timepoint = str_extract(contrast, "\\d+wks(?=_vs)")
  ) %>%
  select(Name, species, timepoint, logFC) %>%
  arrange(desc(logFC)) %>%
  print(n = 50)

## Switchgrass Metabolite Investigation

search_metabolites <- function(query, long_data = aq_ms2_long, limma_data = aq_limma_results) {
  
  hits <- long_data %>%
    filter(str_detect(tolower(Name), tolower(query))) %>%
    distinct(ID, Name, `Top ClassyFire Class`, `Top ClassyFire Subclass`)

  cat("Found", nrow(hits), "matching features", "to", query, ":\n")
  print(hits)
  
  limma_data %>%
    filter(ID %in% hits$ID) %>%
    filter(
      grepl("miscanthus.*6wks.*vs.*control_6wks", contrast) |
      grepl("miscanthus.*15wks.*vs.*control_15wks", contrast)
    ) %>%
    mutate(
      species = str_extract(contrast, "miscanthus\\S+(?=_\\d+wks)"),
      timepoint = str_extract(contrast, "\\d+wks(?=_vs)"),
      display_name = query
    ) %>%
    select(display_name, Name, species, timepoint, logFC, significant) %>%
    arrange(desc(logFC)) %>%
    return()
}

# usage
search_term_drought <- c("benzoic acid", "pyridoxic acid", "mevalon", "chlorogenic acid", "caffeic acid", "pentose", "cinnamic acid", "gluconic acid")

switch_metabs_drought <- bind_rows(
  lapply(search_term_drought, function(term) {
    bind_rows(
      search_metabolites(term, aq_ms2_long, aq_limma_results) %>% mutate(fraction = "aqueous"),
      search_metabolites(term, or_ms2_long, or_limma_results) %>% mutate(fraction = "organic")
    )
  })
)

search_term_np <- c("hydroxyproline", "valine", "threonine", "lysine", "aminocyclopropanecarboxylic acid",
"ectoine", "ornithine", "arginine", "tryptophan", "acetylcholine", "allantoin", "aminoisobutyric acid",
"isoleucine", "asparagine", "serotonin", "histidine")

switch_metabs_np <- bind_rows(
  lapply(search_term_np, function(term) {
    bind_rows(
      search_metabolites(term, aq_ms2_long, aq_limma_results) %>% mutate(fraction = "aqueous"),
      search_metabolites(term, or_ms2_long, or_limma_results) %>% mutate(fraction = "organic")
    )
  })
)

switch_metabs_drought %>%
  mutate(condition = "drought") %>%
  bind_rows(switch_metabs_np %>% mutate(condition = "NP")) %>%
  ggplot(aes(x = display_name, y = logFC, fill = fraction)) +
  geom_boxplot() +
  geom_hline(yintercept = 0, linetype = "dashed") +
  facet_wrap(~condition, scales = "free_x",
             nrow = 2) +
  theme_minimal() +
  labs(title = "Switchgrass: Log2 Fold Change for Drought-Related and Nitrogen-Related Metabolites",
       x = "Metabolite Name", y = "Log2 Fold Change (Miscanthus vs Control)") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
