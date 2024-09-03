library(tidyverse)


source("funs/rm_sensitive_data.R")

datafiles_list <- list.files(path = "data-raw/matomo_export_2024-05-27_to_2024-06-03",
                             pattern = "csv$")


data_files_list |> 
  walk(~ rm_sensitive_data(filename = .x))
