## 1. Data sources in this repository

- `data/input/msa_msi_minicores_2025.xlsx`
    - Panel and sample inventory for Miscanthus genotypes (identifiers, species/consensus IDs, accessions, project tags). Serves as the master list of plants/samples to be tracked across timepoints.
- `data/input/Aponte_Bolivar_msa_msi_pilot_samples.xlsx`
    - Pilot greenhouse sample tracking for early method shakedown; limited scope and used to validate the protocol and data structure prior to main collections.
- `protocols/mxg_exudate_collection_protocol.qmd`
    - Versioned exudate collection protocol (methodological context, volumes, timing, controls, greenhouse adaptations) used to standardize measurement definitions.
- `notebooks/`
    - `notebooks/mxg_genotype_exudates.md`: Experiment overview, timeline, materials checklist, and field/greenhouse implementation notes (dates, irrigation, fertilization, and procedural deviations).
    - `notebooks/pilot_mxg_greenhouse.md`: Pilot attempt log (setup, soak/bleach steps, environmental conditions).

## 2. Entities and identifiers

- Core sample key: barcode (unique per plant/pot), with supporting IDs: entry, species_consensus, accession_number, alt_accession_number, usda_q_number, uiuc_id.
- Project context: project, project_id, investigator and site (from notebooks), date_transplant (POSIXct).

## 3. Measurements collected at two planned timepoints (6 and 15 weeks) 
All measurement groups exist in paired forms for 6wks and 15wks. Numeric quantities are stored as numeric; event times as POSIXct.

### A. Root exudate incubation and flushes

- root_exudate_collect_[6wks|15wks] (flag)
- incubation_start_[6wks|15wks] (POSIXct)
- incubation_end_[6wks|15wks] (POSIXct)
- Flush volumes (mL):
    - flush_1_initial_volume_[6wks|15wks]
    - flush_1_replenish_[6wks|15wks]
    - flush_1_final_volume_[6wks|15wks]
    - flush_2_initial_volume_[6wks|15wks]
    - flush_2_final_volume_[6wks|15wks] Notes:
- Volumes align with the protocol’s T0, T24, F1 and F2 steps.
- These support derived metrics such as recovered volume and potential recovery fraction by flush.

### B. Soil drying and mass (mg)

- soil_[6wks|15wks] (flag)
- soil_dry_time_start_[6wks|15wks] (POSIXct)
- soil_dry_time_end_[6wks|15wks] (POSIXct)
- soil_start_mg_[6wks|15wks]
- soil_24hrs_mg_[6wks|15wks]
- soil_end_mg_[6wks|15wks] Notes:
- Supports drying duration and moisture loss calculations if needed.

### C. Root drying and mass (mg)

- root_[6wks|15wks] (flag)
- root_dry_time_start_[6wks|15wks] (POSIXct)
- root_dry_time_end_[6wks|15wks] (POSIXct)
- root_start_mg_[6wks|15wks]
- root_end_mg_[6wks|15wks] Notes:
- Supports dry-down duration and mass changes for normalization (e.g., exudate per root mass).

### D. Status and notes

- transplanted (numeric flag), date_transplant (POSIXct), survival_6wks, labeled, replaced_july2025 (flag), notes (free text).

### 4. Experimental context captured in notebooks

- Planting date, medium, pot size, irrigation schedules, watering changes, fertilization amounts and dates, and observed issues (e.g., rot in *M. sacchariflorus*).
- Timeline planning for 6- and 15-week collections.
- Greenhouse adaptations to the protocol (e.g., 20 mL syringes, filter behavior, handling tips). These entries document deviations, risks, and justifications—useful for interpreting data quality and reproducibility.

### 5. Processing and shaping of the data

- Ingest: Excel workbooks are read to R data frames (e.g., “mxg_panel”), with explicit types (numeric vs POSIXct for timestamps).
- Normalization:
    - Date/time fields are retained as POSIXct for event timing and duration calculations.
    - Measurement columns are numeric.
- Tidy restructuring:
    - Wide-format measurement columns (e.g., flush_1_final_volume_6wks, soil_end_mg_15wks) are pivoted to a long “variable/value” layout for analysis, while POSIXct timestamp columns are excluded from pivoting and kept as columns joined by barcode/sample row.
    - A “week” field (6wks vs 15wks) is carried with measurements to prevent mixing timepoints.
- Known pitfall addressed:
    - To avoid replicating 15-week dates across 6-week rows (and vice versa), POSIXct columns are excluded from pivoting and preserved alongside long-form measurement rows. This prevents temporal mismatches during analysis.

# 6. Data quality, controls, and gaps

- Protocol includes collection of controls (blank and soil-contaminated) to evaluate contamination and background; these should be flagged in notes/variables if present.
- Some samples were replaced (replaced_july2025), and not all lines participated in the initial 6-week sampling—expect NAs in 6-week variables for those cases.
- Notes fields capture procedural deviations (e.g., filter clogging, pressure issues, irrigation adjustments).
- Units:
    - Volumes in mL; masses in mg; times as POSIXct (UTC recommended for storage).
- No human-subjects or PII; plant-level identifiers only.

# 7. Example derived fields recommended (if/when computed)

- incubation_duration_[6wks|15wks] = incubation_end − incubation_start (hours)
- soil_dry_duration_[6wks|15wks] and root_dry_duration_[6wks|15wks]
- recovered_volume_by_flush = final_volume − initial_volume (+ replenish, as protocol dictates)
- normalization metrics:
    - volume_per_root_mass = total_recovered_volume / root_end_mg_[timepoint]
    - mass loss and percent moisture (soil_start vs soil_end)

# 8. Storage, versioning, and provenance

- Raw inputs: Excel files in data/input/.
- Protocol and procedural context: protocols/ and notebooks/ folders.
- Version control: GitHub repo germs-lab/mxg_genotype_exudates; the state referenced here is commit 595df626259529c6fb8c71d61b54b912b550856c.
- Access: Repository-hosted, enabling transparent provenance; notebook logs provide experiment dates and changes over time.

# 9. Suggested data package for sharing/archiving

- Raw: Original Excel files as collected.
- Processed/tidy:
    - A long-format CSV/Parquet with columns such as:
        - barcode, species_consensus, accession_number, project_id
        - week (6wks/15wks), variable, value
        - retained timestamp columns (POSIXct) relevant to the row’s timepoint
        - notes, flags (survival_6wks, replaced_july2025, etc.)
- Data dictionary:
    - Include variable names, definitions, units, and types (as summarized above).
- Readme:
    - Link to protocol file and notebooks; describe known caveats (e.g., replaced plants, missing timepoint values).


# Data Structure Summary

## Sources: 
- `data/input/msa_msi_minicores_2025.xlsx` (master panel),
- `data/input/Aponte_Bolivar_msa_msi_pilot_samples.xlsx` (pilot), 
- `notebooks` (experiment context), protocols used only to define variable meanings (not decisions).

## 1) Entities and keys
- Primary key: barcode (string; unique plant/pot identifier).
- Supporting IDs (string): entry, species_consensus, accession_number, alt_accession_number, usda_q_number, uiuc_id, project, project_id, minicores_ainsworth_2025.
- Notes (string): notes (free text).

## 2) Global attributes
- quantity (numeric)
- transplanted, labeled, survival_6wks, replaced_july2025 (numeric flags; 0/1 or NA)
- date_transplant (POSIXct)

## 3) Timepoint pattern (suffix-names)
- Two planned timepoints encoded in column suffixes: _6wks and _15wks
- Variable families (by prefix), each duplicated for both timepoints:
  - Root exudate collection (flags): root_exudate_collect_[6wks|15wks]
  - Incubation timestamps (POSIXct): incubation_start_[6wks|15wks], incubation_end_[6wks|15wks]
  - Flush volumes (numeric, mL):
    - flush_1_initial_volume_[6wks|15wks]
    - flush_1_replenish_[6wks|15wks]
    - flush_1_final_volume_[6wks|15wks]
    - flush_2_initial_volume_[6wks|15wks]
    - flush_2_final_volume_[6wks|15wks]
  - Soil drying (timestamps POSIXct; masses numeric, mg):
    - soil_[6wks|15wks] (flag)
    - soil_dry_time_start_[6wks|15wks], soil_dry_time_end_[6wks|15wks]
    - soil_start_mg_[6wks|15wks], soil_24hrs_mg_[6wks|15wks], soil_end_mg_[6wks|15wks]
  - Root drying (timestamps POSIXct; masses numeric, mg):
    - root_[6wks|15wks] (flag)
    - root_dry_time_start_[6wks|15wks], root_dry_time_end_[6wks|15wks]
    - root_start_mg_[6wks|15wks], root_end_mg_[6wks|15wks]

## 4) Data types and units
- character: identifiers and labels (barcode, entry, species_consensus, …, project_id, notes)
- numeric: counts/flags/volumes/masses (quantity, 0/1 flags, flush_*_volume_*, *_mg_*)
- POSIXct: all *_start/_end time fields and date_transplant
- Units:
  - Volumes: mL
  - Masses: mg
  - Timestamps: POSIXct (recommend storing with timezone metadata)


## 5) Validation and constraints (data-level)
- Key integrity: barcode must be present; uniqueness recommended within a file.
- Type checks:
  - POSIXct fields parseable as datetime
  - Numeric fields finite (allow NA)
- Logical constraints:
  - *_start <= *_end for timestamp pairs (when both present)
  - Non-negative volumes and masses
- Missingness:
  - NA indicates “not collected/applicable” (e.g., timepoint not performed or sample absent)

## 6) File organization and outputs
- Raw inputs: Excel workbooks in data/input/
- Processed outputs (recommended):
  - Long-form CSV/Parquet:
    - Required columns: barcode, week, variable, value
    - Plus retained wide timestamp fields and static IDs/notes
  - Data dictionary:
    - Column name, description, type, unit, allowed values (for flags: 0/1/NA)

## 7) Column naming conventions
- snake_case with timepoint suffixes: <base>_[6wks|15wks]
- Timestamp fields use _start/_end suffix
- Flags are numeric 0/1

## 8) Minimal schema snapshot (wide, illustrative)
- Keys/labels: barcode (chr), entry (chr), species_consensus (chr), accession_number (chr), project_id (chr), notes (chr)
- Globals: quantity (num), transplanted (num), labeled (num), survival_6wks (num), replaced_july2025 (num), date_transplant (POSIXct)
- Timepointed (examples, each duplicated for 6wks & 15wks):
  - root_exudate_collect_* (num)
  - incubation_start_*, incubation_end_* (POSIXct)
  - _flush_1_initial_volume_*, flush_1_replenish_*, _flush_1_final_volume_*, flush_2_initial_volume_*, _flush_2_final_volume_* (num)
  - _soil_* flags; _soil_dry_time_start_*, soil_dry_time_end_* (POSIXct); _soil_start_mg_*, soil_24hrs_mg_*, _soil_end_mg_* (num)
  - _root_* flags; _root_dry_time_start_*, root_dry_time_end_* (POSIXct); _root_start_mg_*, root_end_mg_* (num)

## Description of R/001_import_clean.R

- Sets up environment (sources R/utils/000_setup.R).
- Imports two Excel sheets into data frames:
    - `isu_msa_msi_collection` → mxg_coll
    - `mxg_genotype_exudate_panel` → mxg_panel
- QC cross-checks: finds barcodes present in one table but missing in the other via anti_join.
- Generates a label dataset by replicating each panel row 6× and selecting key ID fields; writes labels to CSV and XLSX (note: XLSX write references mxg_labels_clean, which isn’t defined in this script).
- Cleans panel column names to snake_case and prints them.
- Reshapes measurements:
    - pivot_longer over numeric columns (excluding specified flags), then parses fields:
        - week (6wks/15wks), flush (flush_1/flush_2), sample_type (exudate/root/soil), measurement_type (initial/final/replenish; soil/root masses).
    - Filters non-relevant rows, pivots wider to measurement columns, fills soil/root mass values within barcode × week, and renames flush columns (flush_initial_volume, flush_final_volume, flush_replenish).
- Outputs reshaped data to Excel: `data/input/Aponte_Bolivar_msa_msi_pilot_samples.xlsx` (sheet msa_msi_pilot_samples).

Result: an analysis-ready table with one or more rows per barcode × week containing flush volumes and soil/root mass metrics, plus parsed context columns.