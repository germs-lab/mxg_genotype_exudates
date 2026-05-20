## 1. Data sources in this repository
Last modified 2026-05-20

-   `data/input/msa_msi_minicores_2025.xlsx`
    -   Panel and sample inventory for Miscanthus genotypes (identifiers, species/consensus IDs, accessions, project tags). Serves as the master list of plants/samples to be tracked across timepoints.

    -   Contains tabs:

        -   `Msa_Msi_Mini-Cores-Ainsworth_RA`: Lockec spreadsheet with accession information provided by Erik Sacks.

        -   `isu_msa_msi_collection`: Working copy of `Msa_Msi_Mini-Cores-Ainsworth_RA`. Cleaned and organized for input in R or downstream analyses. This is the source for downstreams metadata files.

        -   `mxg_genotype_exudate_panel`: Spreadsheet with the accessions used for the pilot study. Contains RAW data collected in pilot study.

        -   `msa_msi_pilots_samples`: Old version of `mxg_genotype_exudate_panel`. Contains partial raw data.

        -   `replacement_plants`: Accessions requested to Erik Sacks after plant death at 6 weeks.

        -   `metadata`: Explanation of variables measured in the pilot study. Passwords for `Msa_Msi_Mini-Cores-Ainsworth_RA` tab.
-   `data/input/Aponte_Bolivar_mxg_genotype_exudate_panel.xlsx`
    -   The result of `R/001_import_clean.R` which takes `isu_msa_msi_collection` and `mxg_genotype_exudate_panel` cleans them and provides them in long for for metabolomic analyses downstream.
-   `data/input/CBI_SRO_Howe/LC-Metabolomics/`
    -   Main directory for results from Oak Ridge Metabolomics analyses from Paul Abraham.
    -   Contains raw LC-MS data for aqueous and organic fractions of root exudates. These were extracted ass their own subdirecories: `Aqueous_fraction/` and `Organic_fraction/`.
-   `protocols/mxg_exudate_collection_protocol.qmd`
    -   Versioned exudate collection protocol (methodological context, volumes, timing, controls, greenhouse adaptations) used to standardize measurement definitions.
-   `notebooks/`
    -   `notebooks/mxg_genotype_exudates.md`: Experiment overview, timeline, materials checklist, and field/greenhouse implementation notes (dates, irrigation, fertilization, and procedural deviations).
    -   `notebooks/pilot_mxg_greenhouse.md`: Pilot attempt log (setup, soak/bleach steps, environmental conditions).

## 2. Entities and identifiers

-   Core sample key: barcode (unique per plant/pot), with supporting IDs: `entry`, `species_consensus`, `accession_number`, `alt_accession_number`, `usda_q_number`, `uiuc_id`.
-   Project context: `project`, `project_id`, `investigator` and `site` (from notebooks), `date_transplant` (POSIXct).

**See `metadata` in `data/input/msa_msi_minicores_2025.xlsx` and [DATA_DICTIONARY](DATA_DICTIONARY.md) for details.**

## 3. Measurements collected at two planned timepoints (6 and 15 weeks)

All measurement groups exist in paired forms for `6wks` and `15wks`. Numeric quantities are stored as numeric; event times as POSIXct.

### A. Root exudate incubation and flushes

-   root_exudate_collect\_\[`6wks`\|`15wks`\] (flag)
-   incubation_start\_\[`6wks`\|`15wks`\] (POSIXct)
-   incubation_end\_\[`6wks`\|`15wks`\] (POSIXct)
-   Flush volumes (mL):
    -   `flush_1_initial_volume\_`\[`6wks`\|`15wks`\]
    -   `flush_1_replenish\_`\[`6wks`\|`15wks`\]
    -   `flush_1_final_volume\_`\[`6wks`\|`15wks`\]
    -   `flush_2_initial_volume\_`\[`6wks`\|`15wks`\]
    -   `flush_2_final_volume\_`\[`6wks`\|`15wks`\] Notes:
-   Volumes align with the protocol’s T0, T24, F1 and F2 steps.
-   These support derived metrics such as recovered volume and potential recovery fraction by flush.

### B. Soil drying and mass (mg)

-   `soil\_`\[`6wks`\|`15wks`\] (flag)
-   `soil_dry_time_start\_`\[`6wks`\|`15wks`\] (POSIXct)
-   `soil_dry_time_end\_`\[`6wks`\|`15wks`\] (POSIXct)
-   `soil_start_mg\_`\[`6wks`\|`15wks`\]
-   `soil_24hrs_mg\_`\[`6wks`\|`15wks`\]
-   `soil_end_mg\_`\[`6wks`\|`15wks`\] Notes:
-   Supports drying duration and moisture loss calculations if needed.

### C. Root drying and mass (mg)

-   `root\_`\[`6wks`\|`15wks`\] (flag)
-   `root_dry_time_start\_`\[`6wks`\|`15wks`\] (POSIXct)
-   `root_dry_time_end\_`\[`6wks`\|`15wks`\] (POSIXct)
-   `root_start_mg\_`\[`6wks`\|`15wks`\]
-   `root_end_mg\_`\[`6wks`\|`15wks`\] Notes:
-   Supports dry-down duration and mass changes for normalization (e.g., exudate per root mass).

### D. Status and notes

-   `transplanted` (numeric flag), `date_transplant` (POSIXct), `survival_6wks`, `labeled`, `replaced_july2025` (flag), `notes` (free text).

### 4. Experimental context captured in notebooks

-   Planting date, medium, pot size, irrigation schedules, watering changes, fertilization amounts and dates, and observed issues (e.g., rot in *M. sacchariflorus*).
-   Timeline planning for 6- and 15-week collections.
-   Greenhouse adaptations to the protocol (e.g., 20 mL syringes, filter behavior, handling tips). These entries document deviations, risks, and justifications—useful for interpreting data quality and reproducibility.

### 5. Processing and shaping of the data

-   Ingest: Excel workbooks are read to R data frames (e.g., “mxg_panel”), with explicit types (numeric vs POSIXct for timestamps).
-   Normalization:
    -   Date/time fields are retained as POSIXct for event timing and duration calculations.
    -   Measurement columns are numeric.
-   Tidy restructuring in `R/001_import_clean.R`:
    -   Wide-format measurement columns (e.g., flush_1_final_volume_6wks, soil_end_mg_15wks) are pivoted to a long “variable/value” layout for analysis, while POSIXct timestamp columns are excluded from pivoting and kept as columns joined by barcode/sample row.
    -   A “week” field (6wks vs 15wks) is carried with measurements to prevent mixing timepoints.
-   Known pitfall addressed:
    -   To avoid replicating 15-week dates across 6-week rows (and vice versa), POSIXct columns are excluded from pivoting and preserved alongside long-form measurement rows. This prevents temporal mismatches during analysis.

# 6. Data quality, controls, and gaps

-   Protocol includes collection of controls (blank and soil-contaminated) to evaluate contamination and background; these should be flagged in notes/variables if present.
-   Some samples were replaced (`replaced_july2025`), and not all lines participated in the initial 6-week sampling. **Expect NAs in 6-week variables for those cases**.
-   Notes fields capture procedural deviations (e.g., filter clogging, pressure issues, irrigation adjustments).
-   Units:
    -   Volumes in mL; masses in mg; times as POSIXct (UTC recommended for storage).
-   No human-subjects or PII; plant-level identifiers only.

# 7. Example derived fields recommended (if/when computed)

-   `incubation_duration\_`\[`6wks`\|`15wks`\] = `incubation_end − incubation_start` (hours)
-   `soil_dry_duration\_`\[`6wks`\|`15wks`\] and `root_dry_duration\_`\[`6wks`\|`15wks\]
-   `recovered_volume_by_flush` = `final_volume − initial_volume` (+ replenish, as protocol dictates)
-   normalization metrics:
    -   `volume_per_root_mass` = `total_recovered_volume / root_end_mg\_`\[`timepoint`\]
    -   `mass_loss` and `percent_moisture` (`soil_start` vs `soil_end`)

# 8. Storage, versioning, and provenance

-   Raw inputs: Excel files in `data/input/`.
-   Protocol and procedural context: `protocols/` and `notebooks/` folders.

# 9. Suggested data package for sharing/archiving

-   Raw: Original Excel files as collected.
-   Processed/tidy:
    -   A long-format CSV with columns such as:
        -   `barcode`, `species_consensus`, `accession_number`, `project_id`
        -   `week` (6wks/15wks), `variable`, `value`
        -   retained timestamp columns (POSIXct) relevant to the row’s timepoint
        -   `notes`, `flags` (`survival_6wks`, `replaced_july2025`, etc.)
-   Data dictionary:
    -   Include variable names, definitions, units, and types (as summarized above).
-   Readme:
    -   Link to protocol file and notebooks; describe known caveats (e.g., replaced plants, missing timepoint values).


# Description of R/001_import_clean.R

-   Sets up environment (sources R/utils/000_setup.R).
-   Imports two Excel sheets into data frames:
    -   `isu_msa_msi_collection` → mxg_coll
    -   `mxg_genotype_exudate_panel` → mxg_panel
-   QC cross-checks: finds barcodes present in one table but missing in the other via anti_join.
-   Generates a label dataset by replicating each panel row 6× and selecting key ID fields; writes labels to CSV and XLSX (note: XLSX write references mxg_labels_clean, which isn’t defined in this script).
-   Cleans panel column names to snake_case and prints them.
-   Reshapes measurements:
    -   pivot_longer over numeric columns (excluding specified flags), then parses fields:
        -   week (6wks/15wks), flush (flush_1/flush_2), sample_type (exudate/root/soil), measurement_type (initial/final/replenish; soil/root masses).
    -   Filters non-relevant rows, pivots wider to measurement columns, fills soil/root mass values within barcode × week, and renames flush columns (flush_initial_volume, flush_final_volume, flush_replenish).
-   Outputs reshaped data to Excel: `data/input/Aponte_Bolivar_msa_msi_pilot_samples.xlsx` (sheet msa_msi_pilot_samples).

Result: an analysis-ready table with one or more rows per barcode × week containing flush volumes and soil/root mass metrics, plus parsed context columns.