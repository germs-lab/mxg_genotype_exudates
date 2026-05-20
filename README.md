# *Miscanthus spp.* Genotype Root Exudates

![GitHub](https://img.shields.io/github/license/jibarozzo/mxg_genotype_exudates)

## Overview

This repository contains protocols, notebooks, and resources for collecting and analyzing root exudates from *Miscanthus spp.* genotypes.  Modified from a protocol from Rich Phillips.

## Repository Structure

- **data/**: Contains raw (`input/`) and processed (`output/`) data files. Not all data is included due to size constraints. See GERMS lab Google Drive or request access.
- **docs/**: Documentation and supplementary materials. Poster presentations and other material in main GERMS lab Google Drive.
- **protocols/**: ***What did Bolívar do things?*** Contains detailed protocols for exudate collection. 
  - `mxg_exudate_collection_protocol.qmd`: Comprehensive protocol for soluble root exudate collection (Version 6)
- **notebooks/**: ***How did Bolívar do things?*** Analysis notebooks and experimental documentation
  - `pilot_mxg_greenhouse.md`: Documentation for pilot greenhouse experiments
- **R/**: R scripts for import and cleaning data for metabolomic analysis and greenhouse carrying capacity for the lab. 
- **renv/**: R environment configuration for reproducible analysis
- **R/**: R scripts for data analysis
- **data/**: Raw and processed data files

***Read [DATA_DICTIONARY](DATA_DICTIONARY.md) and [DMP_REPORT](DMP_REPORT.md) for more details on how the data was collected and managed.***

## Getting Started

### Prerequisites

- R and RStudio for data analysis
- Quarto for rendering `.qmd` documents
- Laboratory equipment as detailed in the protocols

### Setup

This project uses `renv` for managing R package dependencies. To set up the environment:

1. Clone this repository
2. Open the project in RStudio
3. Run `renv::restore()` to install the required packages

## Protocols

### Mxg Exudate Collection Protocol

The main protocol `protocols/LDRD_Root_Exudates_Protocol-v6.docx` or `protocols/mxg_exudate_collection_protocol.html` provides detailed instructions for collecting soluble root exudates from *Miscanthus x giganteus*. The protocol includes:

- Materials and equipment lists
- Step-by-step collection procedures
- Sample preservation methods
- Quality control considerations

View the full protocol in the `protocols/` directory.

## Pilot Experiments

Documentation for pilot experiments in greenhouse settings can be found in the `notebooks/` directory. These include:

- Materials needed for Mxg rhizome preparation
- Growth conditions
- Experimental setup
- Data collection procedures

## Contributors

- John Field, Ph.D (Oak Ridge National Laboratory) 
- Bolívar Aponte Rolón, Ph.D (Iowa State University)
- Phillip de Lorimier (Iowa State University)  

