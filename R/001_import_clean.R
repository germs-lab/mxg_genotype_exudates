###############################################################################
#
# Brief cleaning and quality control of the MxG collection and panel data.
# Objective: Create labels .csv and .xlsx for metabolite analyses at Oak Ridge
#
#
# Bolívar Aponte Rolón
# 2025-07-29
###############################################################################
source("R/utils/000_setup.R")


#---------------------------------
# Import
#---------------------------------
mxg_coll <- readxl::read_xlsx(
  "data/input/msa_msi_minicores_2025.xlsx",
  sheet = "isu_msa_msi_collection"
)

mxg_panel_raw <- readxl::read_xlsx(
  "data/input/msa_msi_minicores_2025.xlsx",
  sheet = "mxg_genotype_exudate_panel"
)

#-----------------------------------
# Print Labels
#-----------------------------------

# Find barcodes in panel but missing from collection
missing_from_collection <- mxg_panel_raw %>%
  anti_join(mxg_coll, by = c("Barcode" = "Barcode...1"))

# Find barcodes in collection but missing from panel
missing_from_panel <- mxg_coll %>%
  anti_join(mxg_panel_raw, by = c("Barcode...1" = "Barcode"))

# Creating new DF for making labels
mxg_labels <- mxg_panel_raw %>%
  slice(rep(row_number(), each = 6)) %>%
  select(
    Barcode,
    Entry,
    Species_consensus,
    `Groups Consensus`,
    `Accession_#`,
    `USDA_Q_#`,
    `Alt_accession_#`,
    UIUC_ID,
    project,
    project_id
  )

# Save
write_excel_csv(mxg_labels, "data/output/mxg_labels.csv")
# write.xlsx(mxg_labels_clean, "data/output/mxg_labels.xlsx", row.names = TRUE)

#------------------------------------
# Data Clean up
#------------------------------------

# mxg_panel <- janitor::clean_names(mxg_panel_raw)
# posix_cols <- mxg_panel %>%
#   select(barcode, where(~ lubridate::is.POSIXct(.x)))

identifier_cols <- c(
  "barcode",
  "entry",
  "species_consensus",
  "groups_consensus",
  "accession_number",
  "usda_q_number",
  "alt_accession_number",
  "uiuc_id"
)

# Reshaped data
excluded_cols <- c(
  "quantity",
  "transplanted",
  "labeled",
  "survival_6wks",
  "root_6wks",
  "root_15wks",
  "soil_6wks",
  "soil_15wks",
  "root_exudate_collect_6wks",
  "root_exudate_collect_15wks"
)

mxg_panel <- mxg_panel_raw %>%
  janitor::clean_names(.) %>%
  #select(!where(~ lubridate::is.POSIXct(.x))) %>%
  tidyr::pivot_longer(
    cols = where(is.numeric) &
      !matches(excluded_cols),
    names_to = "variable",
    values_to = "value"
  ) %>%
  mutate(
    week = str_extract(variable, "(6|15)wks"),
    flush = str_extract(variable, "flush_[12]"),
    sample_type = case_when(
      str_detect(variable, "flush_[12]") ~ "exudate",
      str_detect(variable, "root*") ~ "root",
      str_detect(variable, "soil*") ~ "soil",
      TRUE ~ variable
    ),
    #flush = case_when(str_detect(variable, "flush_[12]") ~ "F", TRUE ~ variable),
    measurement_type = case_when(
      str_detect(variable, "flush_[12]_initial_volume") ~ "initial_volume",
      str_detect(variable, "flush_[12]_final_volume") ~ "final_volume",
      str_detect(variable, "flush_[12]_replenish") ~ "replenish",
      str_detect(variable, "soil_start") ~ "soil_initial_mg",
      str_detect(variable, "soil_24hrs") ~ "soil_24hrs_mg",
      str_detect(variable, "soil_end*") ~ "soil_final_mg",
      str_detect(variable, "root_start*") ~ "root_initial_mg",
      str_detect(variable, "root_end*") ~ "root_final_mg",
      TRUE ~ variable
    )
  ) %>%
  filter(!is.na(sample_type) & !sample_type == "replaced_july2025") %>% # Keep only flush-related rows
  select(-variable) %>%
  tidyr::pivot_wider(
    names_from = measurement_type,
    values_from = value,
    values_fill = NA,
    values_fn = first
  ) %>%
  group_by(barcode, week) %>%
  fill(
    soil_initial_mg,
    soil_24hrs_mg,
    soil_final_mg,
    root_initial_mg,
    root_final_mg,
    .direction = "downup"
  ) %>%
  ungroup() %>%
  rename(
    flush_initial_volume = initial_volume,
    flush_final_volume = final_volume,
    flush_replenish = replenish
  )

#--------------------------------------
# Save
#--------------------------------------
# File for Metabolite analysis at Oak Ridge
write.xlsx(
  mxg_panel,
  "data/input/Aponte_Bolivar_mxg_genotype_exudate_panel.xlsx",
  sheetName = 'mxg_genotype_exudate_panel',
  rowNames = TRUE
)


mxg_panel_list <- list(
  mxg_panel_raw = mxg_panel_raw,
  mxg_panel = mxg_panel
)
save(
  mxg_panel_list,
  file = "data/output/mxg_genotype_exudate_panel.rda"
)
