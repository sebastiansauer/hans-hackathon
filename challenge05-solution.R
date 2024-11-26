library(targets)
library(tarchetypes)  # Extention to "targets", eg watching source data files
library(janitor)


# packages available for all targets:
tar_option_set(
  packages = c("dplyr", "readr", "purrr", "tidyr", "stringr", "janitor", "writexl")
)

# set options:
options(lubridate.week.start = 1)

source("funs/add_id_cols.R")



# targets pipeline, ie., steps to be computed:
list(
  # read data:
  tar_target(data_files_list, 
             list.files(path = "data-processed/data-raw-no-sensitive",  # MY path to the data
                        full.names = TRUE,
                        pattern = "*.csv$",
                        recursive = FALSE), 
             format = "file"),  # watch data source files
  
  # bind all csv files into one long dataframe:
  tar_target(one_df,
              data_files_list |> 
                map_dfr(read.csv, .id = "file_id")),
  
  # remove empty cols and rows:
  tar_target(rm_empty,
             one_df |> 
               remove_empty(which = c("rows", "cols")), 
             packages = "janitor"),
  
  # remove constant cols:
  tar_target(rm_constants,
             rm_empty |> 
               remove_constant(), 
             packages = "janitor"),
  
  # # select only subtitles and timestamps:
  # tar_target(df_subtitles_timestamps,
  #            rm_constants |> 
  #              select(idVisit, contains("subtitle"), contains("timestamp"))),
  
  # repair date-time cols:
  
  tar_target(repair_dttm,
             rm_constants |> 
                mutate(across(contains("timestamp"), ~ as_datetime(as.numeric(.x)))),
              packages = c("lubridate", "tidyverse")),
  
  # exclude developers, lecturers and admins:
  tar_target(rm_lecturers_admins,
              repair_dttm |> 
                filter(!str_detect(actionDetails_0_subtitle, "developer|lecturer|admin")),
             packages = "stringr"),
  
  # pivot longer:
  tar_target(d_long,
             rm_lecturers_admins |> 
               select(idVisit, contains("actionDetails")) |> 
               mutate(across(everything(), as.character)) |> 
               pivot_longer(-idVisit) ),
  
  # add id col:
  tar_target(add_id_col,
             add_id_column(d_long),
             packages = c("stringr")),
  
  # write to XLSX:
  tar_target(write_xlsx,
             rm_lecturers_admins |> 
               write_xlsx("data-processed/data-raw-no-sensitive/challenge05.xlsx"),
             packages = "writexl")
  
  
)  # close targets pipeline



