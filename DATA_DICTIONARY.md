# Data Dictionary: Mxg Genotype Exudates
Last modified 2026-05-20

### Conventions
- Types: chr = character/string; num = numeric; flag = 0/1 or NA; datetime = POSIXct.
- Timepoints: Columns with suffixes `_6wks` and `_15wks` represent the same measurement at different times.
- Units: volumes (mL), masses (mg), timestamps (datetime with timezone recommended).

### Identifiers and project context
- `barcode` (chr): Unique identifier for the plant/pot/sample.
- `entry` (chr): Panel entry code or number.
- `species_consensus` (chr): Taxonomic assignment (e.g., M. sinensis, M. sacchariflorus, M. × giganteus).
- `accession_number` (chr): Primary accession ID.
- `alt_accession_number` (chr): Alternate accession ID.
- `usda_q_number` (chr): USDA quarantine or collection number.
- `uiuc_id` (chr): University of Illinois identifier (if applicable).
- `minicores_ainsworth_2025` (chr): Minicore membership tag/reference.
- `project` (chr): Project name or label.
- `project_id` (chr): Project identifier code.
- `notes` (chr): Free-text annotations about the sample.

### Global/administrative
- `quantity` (num): Count of individuals/plants represented by the barcode (if >1).
- `transplanted` (flag): Whether the plant was transplanted (1) or not (0/NA).
- `date_transplant` (datetime): Transplant date/time.
- `labeled` (flag): Whether physical labeling was completed.
- `survival_6wks` (flag): Survival status at 6 weeks.
- `replaced_july2025` (flag): Indicates if plant/sample was replaced during July 2025.

### Root exudate collection (by timepoint)
- `root_exudate_collect_`[`6wks`|`15wks`] (flag): Exudate collection attempted/completed.
- `incubation_start_`[`6wks`|`15wks`] (datetime): Start of incubation.
- `incubation_end_`[`6wks`|`15wks`] (datetime): End of incubation.

### Flush volumes (by timepoint; mL)
- `flush_1_initial_volume_`[`6wks`|`15wks`] (num): Volume present before flush 1 recovery.
- `flush_1_replenish_`[`6wks`|`15wks`] (num): Make-up volume added during flush 1.
- `flush_1_final_volume_`[`6wks`|`15wks`] (num): Volume recovered after flush 1.
- `flush_2_initial_volume_`[`6wks`|`15wks`] (num): Volume present before flush 2 recovery.
- `flush_2_final_volume_`[`6wks`|`15wks`] (num): Volume recovered after flush 2.

### Soil collection and drying (by timepoint)
- `soil_`[`6wks`|`15wks`] (flag): Soil sample collected.
- `soil_dry_time_start_`[`6wks`|`15wks`] (datetime): Start of soil drying.
- `soil_dry_time_end_`[`6wks`|`15wks`] (datetime): End of soil drying.
- `soil_start_mg_`[`6wks`|`15wks`] (num, mg): Initial soil mass before drying.
- `soil_24hrs_mg_`[`6wks`|`15wks`] (num, mg): Soil mass after ~24 hours drying.
- `soil_end_mg_`[`6wks`|`15wks`] (num, mg): Final soil mass at end of drying.

### Root collection and drying (by timepoint)
- `root_`[`6wks`|`15wks`] (flag): Root sample collected.
- `root_dry_time_start_`[`6wks`|`15wks`] (datetime): Start of root drying.
- `root_dry_time_end_`[`6wks`|`15wks`] (datetime): End of root drying.
- `root_start_mg_`[`6wks`|`15wks`] (num, mg): Initial root mass before drying.
- `root_end_mg_`[`6wks`|`15wks`] (num, mg): Final root mass at end of drying.