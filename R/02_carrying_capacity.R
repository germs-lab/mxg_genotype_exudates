###############################################################################
# GREENHOUSE CARRYING CAPACITY ANALYSIS
# Evaluates how many Miscanthus genotypes and individuals can be maintained
# Bolívar Aponte Rolón
# 2025-11-20
###############################################################################

# ============================================================================
# SETUP & DATA PREPARATION
# ============================================================================

source("R/utils/000_setup.R")

# Propagation dates for reference
# 2025-09-23, 2025-11-14, 2025-11-18

# Extract and clean core genotype data, excluding controls
mxg_counts <- mxg_panel_list$mxg_panel_raw %>%
  janitor::clean_names() %>%
  select(
    barcode,
    species_consensus,
    groups_consensus,
    quantity,
    transplanted,
    date_transplant
  ) %>%
  filter(!str_detect(barcode, "^control")) %>%
  rename(quantity_initial = quantity)

write_excel_csv(mxg_counts, "data/output/mxg_counts.csv")


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Standardize species names across groupings
standardize_species <- function(species_consensus) {
  case_when(
    str_detect(species_consensus, "sinensis") ~ "Miscanthus sinensis",
    str_detect(
      species_consensus,
      "sacchariflorus"
    ) ~ "Miscanthus sacchariflorus",
    str_detect(species_consensus, "floridulus") ~ "Miscanthus floridulus",
    str_detect(
      species_consensus,
      "xgiganteus|x giganteus"
    ) ~ "Miscanthus × giganteus",
    TRUE ~ species_consensus
  )
}

# Create standardized gt table styling
theme_mxg_table <- function(
  data,
  title,
  subtitle = NULL,
  groupname_col = NULL
) {
  # Capture row count from ungrouped data before gt conversion
  n_rows <- nrow(data)

  # Build gt object - groupname_col is passed directly to gt()
  gt_obj <- data %>%
    gt(groupname_col = groupname_col)

  # Apply styling
  gt_obj %>%
    tab_header(
      title = title,
      subtitle = subtitle
    ) %>%
    tab_style(
      style = cell_fill(color = "#f0f0f0"),
      locations = cells_body(rows = seq(1, n_rows, 2))
    ) %>%
    tab_style(
      style = cell_text(weight = "bold"),
      locations = cells_column_labels()
    ) %>%
    tab_options(
      table.font.size = "small",
      heading.title.font.size = px(18),
      heading.subtitle.font.size = px(12)
    )
}

# ============================================================================
# SUMMARY STATISTICS: SPECIES-LEVEL OVERVIEW
# ============================================================================

# Aggregate by species to understand genetic and geographic diversity
mxg_species_summary <- mxg_counts %>%
  mutate(species_group = standardize_species(species_consensus)) %>%
  group_by(species_group) %>%
  summarise(
    unique_subspecies = n_distinct(species_consensus),
    unique_genotypes = n_distinct(barcode),
    unique_regions = n_distinct(groups_consensus),
    count = n(),
    total_quantity = sum(quantity_initial, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  mutate(quantity_post_propagation = NA) %>%
  arrange(desc(total_quantity))

# Display summary
mxg_species_summary


# ============================================================================
# PROPAGATION SCENARIOS
# ============================================================================

# Simulate four propagation strategies to evaluate greenhouse capacity:
# - Scenario 1 & 2: Scale all genotypes (4x and 2x propagation)
# - Scenario 3 & 4: Selective breeding (2 and 1 genotype per species per region)

simulate_propagation_by_group <- function(mxg_counts) {
  # Prepare data: standardize species and filter for regional diversity assessment
  mxg_data <- mxg_counts %>%
    select(barcode, species_consensus, groups_consensus, quantity_initial) %>%
    filter(!str_detect(barcode, "^control")) %>%
    filter(!is.na(groups_consensus)) %>%
    mutate(species_group = standardize_species(species_consensus))

  # Calculate baseline diversity metrics for all-genotype scenarios
  mxg_species_summary <- mxg_counts %>%
    mutate(species_group = standardize_species(species_consensus)) %>%
    group_by(species_group) %>%
    summarise(
      unique_genotypes = n_distinct(barcode),
      unique_regions = n_distinct(groups_consensus),
      count = n(),
      total_quantity = sum(quantity_initial, na.rm = TRUE),
      .groups = 'drop'
    )

  # SCENARIO 1: Propagate all genotypes 4 times each
  scenario_1 <- mxg_species_summary %>%
    mutate(
      propagation_rounds = 4,
      plants_per_genotype = 4,
      total_plants = unique_genotypes * plants_per_genotype
    ) %>%
    select(
      species_group,
      unique_genotypes,
      unique_regions,
      propagation_rounds,
      plants_per_genotype,
      total_plants
    )

  # SCENARIO 2: Propagate all genotypes 2 times each
  scenario_2 <- mxg_species_summary %>%
    mutate(
      propagation_rounds = 2,
      plants_per_genotype = 2,
      total_plants = unique_genotypes * plants_per_genotype
    ) %>%
    select(
      species_group,
      unique_genotypes,
      unique_regions,
      propagation_rounds,
      plants_per_genotype,
      total_plants
    )

  # SCENARIO 3: Keep top 2 genotypes per species per geographic region
  # Maximizes regional genetic representation while reducing labor
  scenario_3 <- mxg_data %>%
    group_by(species_group, groups_consensus) %>%
    slice(1:2) %>%
    ungroup() %>%
    group_by(species_group, groups_consensus) %>%
    summarise(
      n_genotypes_selected = n(),
      n_species_selected = n_distinct(species_group),
      total_quantity = sum(quantity_initial, na.rm = TRUE),
      .groups = 'drop'
    ) %>%
    mutate(
      plants_per_genotype = 2,
      total_plants = plants_per_genotype *
        n_genotypes_selected *
        n_species_selected
    )

  # SCENARIO 4: Keep best genotype per species per geographic region
  # Minimal maintenance, core lineage representation
  scenario_4 <- mxg_data %>%
    group_by(species_group, groups_consensus) %>%
    slice(1) %>%
    ungroup() %>%
    group_by(species_group, groups_consensus) %>%
    summarise(
      n_genotypes_selected = n(),
      n_species_selected = n_distinct(species_group),
      total_quantity = sum(quantity_initial, na.rm = TRUE),
      .groups = 'drop'
    ) %>%
    mutate(
      plants_per_genotype = 1,
      total_plants = plants_per_genotype *
        n_genotypes_selected *
        n_species_selected
    )

  # Combine all scenarios and merge region/group information
  combined <- bind_rows(
    scenario_1 %>% mutate(scenario = "4x Propagation"),
    scenario_2 %>% mutate(scenario = "2x Propagation"),
    scenario_3 %>% mutate(scenario = "2 genotypes X species X region"),
    scenario_4 %>% mutate(scenario = "1 genotype X species X region"),
  ) %>%
    relocate(scenario, .before = species_group) %>%
    mutate(
      n_genotypes_selected = case_when(
        scenario %in% c("4x Propagation", "2x Propagation") ~ unique_genotypes,
        scenario %in% c("2 genotypes X species X region") ~ 2,
        scenario %in% c("1 genotype X species X region") ~ 1,
        TRUE ~ NA_integer_
      ),
      region_group = case_when(
        # All genotype scenarios: show distinct region count
        scenario %in% c("4x Propagation", "2x Propagation") ~
          paste0(unique_regions, " regions"),
        # Selective scenarios: show specific geographic group
        !is.na(groups_consensus) ~ groups_consensus,
        TRUE ~ NA_character_
      ),
      n_regions = case_when(
        scenario %in% c("4x Propagation", "2x Propagation") ~ unique_regions,
        !is.na(groups_consensus) ~ 1,
        TRUE ~ NA_integer_
      )
    )

  # Summary statistics: capacity needs by scenario
  summary_stats <- combined %>%
    group_by(scenario) %>%
    summarise(
      total_genotypes_selected = sum(n_genotypes_selected, na.rm = TRUE),
      n_species = 4, #n_distinct(species_group),
      n_regions = sum(n_regions, na.rm = TRUE),
      total_plants_needed = sum(total_plants, na.rm = TRUE),
      .groups = 'drop'
    )

  return(list(
    detailed_table = combined,
    summary_table = summary_stats,
    original_data_summary = mxg_data %>%
      group_by(species_group, groups_consensus) %>%
      summarise(
        total_genotypes_available = n(),
        total_quantity_available = sum(quantity_initial, na.rm = TRUE),
        .groups = 'drop'
      )
  ))
}

# Execute propagation analysis
group_propagation_results <- simulate_propagation_by_group(mxg_counts)

# Display summary
group_propagation_results$summary_table


# ============================================================================
# TABLE GENERATION & VISUALIZATION
# ============================================================================

library(gt)

# Species Summary Table ----

mxg_species_table <- theme_mxg_table(
  mxg_species_summary,
  title = "Miscanthus Species Summary",
  subtitle = "Genotype panel diversity and initial quantities"
) %>%
  cols_label(
    species_group = "Species",
    unique_subspecies = "Subspecies",
    unique_genotypes = "Genotypes",
    unique_regions = "Regions",
    count = "N Individuals",
    total_quantity = "Total Quantity",
    quantity_post_propagation = "Post-Propagation"
  ) %>%
  fmt_number(columns = total_quantity, decimals = 0) %>%
  cols_align(
    align = "center",
    columns = c(unique_subspecies, unique_genotypes, count, total_quantity)
  ) %>%
  grand_summary_rows(
    columns = c(
      unique_subspecies,
      unique_genotypes,
      unique_regions,
      count,
      total_quantity
    ),
    fns = list(Total = ~ sum(., na.rm = TRUE)),
    side = "bottom"
  )

mxg_species_table


# Propagation Scenarios: Detailed Table ----
detailed_table <- theme_mxg_table(
  data = group_propagation_results$detailed_table,
  title = "Miscanthus Propagation by Group Scenarios",
  subtitle = "Comparison of selective breeding strategies",
  groupname_col = "scenario"
) %>%
  cols_label(
    species_group = "Species",
    groups_consensus = "Group",
    n_genotypes_selected = "Genotypes Selected",
    total_quantity = "Initial Quantity",
    plants_per_genotype = "Plants/Genotype",
    total_plants = "Total Plants"
  ) %>%
  fmt_number(columns = c(n_genotypes_selected, total_plants), decimals = 0)

detailed_table


# Propagation Scenarios: Summary Table ----
summary_table <- theme_mxg_table(
  data = group_propagation_results$summary_table,
  title = "Miscanthus Propagation Scenarios",
  subtitle = "Greenhouse capacity requirements"
) %>%
  cols_label(
    scenario = "Scenario",
    total_genotypes_selected = "Genotypes Selected",
    n_species = "# Species",
    total_plants_needed = "Total Plants",
    n_regions = "Number of Regions"
  ) %>%

  fmt_number(
    columns = c(total_genotypes_selected, total_plants_needed),
    decimals = 0
  )

summary_table


# Available Genotypes by Group ----
available_genotypes <- theme_mxg_table(
  data = group_propagation_results$original_data_summary,
  title = "Available Genotypes by Group"
) %>%
  cols_label(
    species_group = "Species",
    groups_consensus = "Region",
    total_genotypes_available = "Available Genotypes",
    total_quantity_available = "Available Quantity"
  ) %>%
  fmt_number(
    columns = c(total_genotypes_available, total_quantity_available),
    decimals = 0
  )

available_genotypes


# ============================================================================
# EXPORT RESULTS
# ============================================================================

# Save all tables as HTML for reporting
gtsave(detailed_table, filename = "data/output/tables/mxg_detailed_table.html")
gtsave(
  summary_table,
  filename = "data/output/tables/mxg_scenario_summary_table.html"
)
gtsave(
  available_genotypes,
  filename = "data/output/tables/mxg_available_genotypes_table.html"
)
gtsave(
  mxg_species_table,
  filename = "data/output/tables/mxg_panel_summary.html"
)
