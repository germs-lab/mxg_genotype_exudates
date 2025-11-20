invisible(lapply(
  c("tidyverse", "readxl", "openxlsx", "janitor"),
  library,
  character.only = TRUE
))


list.files(
  here::here("data/output"),
  full.names = TRUE,
  recursive = FALSE,
  pattern = "\\.rda$"
) %>%
  lapply(., load, .GlobalEnv)
