#Sys.setenv(TAR_PROJECT = "challenge09")


library(targets)
library(tarchetypes)  # Extention to "targets", eg watching source data files
library(quarto)  # Quarto reports



# packages available for all targets:
tar_option_set(
  packages = c("dplyr", "readr", "purrr", "tidyr", "stringr")
)


# set options:
options(lubridate.week.start = 1)

# source helper funs:
# funs_files <- list.files(
#   path = "funs", pattern = "\\.R", full.names = TRUE, recursive = TRUE)
# lapply(X = funs_files, FUN = source)

source("funs/count_user_action_type.R")



# here are the targets, ie., steps (of the pipeline) to be computed:
list(
  
  # data import and cleansing -----------------------------------------------
  
  
  # read data:
  tar_target(data_files_list, 
             list.files(
               # MY path to the data:
               path = paste0(here::here(),"/data-processed/data-raw-no-sensitive"),  
               full.names = TRUE,
               pattern = "*.csv$",
               recursive = TRUE), 
             format = "file"),  # watch data source files for changes
  
  # bind all csv files into one long dataframe:
  tar_target(one_df,
             data_files_list |> 
               map(~ fread(.x, fill = TRUE, 
                           colClasses = "character")) |>  
               # convert list to dataframe using bind_rows:
               rbindlist(fill = TRUE, idcol = "file", use.names = TRUE),
             packages = "data.table"),
  
  # remove empty cols and rows:
  tar_target(rm_empty,
             one_df |> 
               remove_empty(which = c("rows", "cols")), 
             packages = "janitor"),
  
  # remove constant cols:
  tar_target(rm_constants,
             rm_empty |> 
               remove_constant(), packages = "janitor"),
  
  # Clean column names:
  tar_target(clean_col_names,
             rm_empty |> clean_names(),
             packages = "janitor"),
  
  # repair date-time columns, ie., convert character to date-time format:
  tar_target(repair_dttm,
             clean_col_names |> 
               mutate(across(contains("timestamp"), ~ as_datetime(as.numeric(.x)))),
             packages = c("lubridate", "dplyr")),
  
  
  # exclude data (rows) of developers, lecturers and admins:
  tar_target(data_users_only,
             repair_dttm |> 
               filter(!str_detect(action_details_0_subtitle, "developer|lecturer|admin")),
             packages = "stringr"),
  
  
  
  
  # longify data ------------------------------------------------------------
  
  
  
  # PIVOT longer, that's easier to work with:
  tar_target(d_long,
             data_users_only |> 
               select(id_visit, contains("details_")) |> 
               mutate(across(everything(), as.character)) |> 
               pivot_longer(-id_visit)),
  
  # drop rows with missing data:
  tar_target(d_long_nona,
             d_long |> drop_na() |> filter(value != "")),  
  
  # add action-count column:
  tar_target(add_id_col,
             d_long_nona |> 
               # rename(action_count = name) |>  # new = old
               mutate(action_count = str_extract(name, "\\d+")), 
             packages = "stringr"),
  
  
  # mutate id column to numeric:
  tar_target(numeric_id,
             add_id_col |> 
               mutate(action_count = as.integer(action_count))),
  
  
  # get types of actions:
  tar_target(action_types,
             numeric_id |>
               separate(name, sep = "_", into = c("constant1", "constant2", "nr", "type")) |> 
               select(-constant1, -constant2, -nr),
             packages = "tidyr"),
  
  
# Challenge 06: Count stuff per visit ------------------------------------------
  
  # count actions per visit:
  tar_target(actions_per_visit,
             numeric_id |>
               group_by(id_visit) |>
               # "nr" is the id of the action of this visit:
               summarise(nr_max = max(action_count))),
  
  # count action categories per visit:
  tar_target(count_action_type,
             count_user_action_type(action_types), packages = c("stringr", "dplyr")),
  
  

# render report in Quarto -------------------------------------------------


# tar_target(
#   quarto_report,
#   {
#     quarto::quarto_render(
#       input = "challenge06-solution-report.qmd",      # Quarto-Datei
#       output_file = "challenge06-solution-report.html"  # Name der Ausgabedatei
#       # execute_params = list(
#       #   data_target = "remove_admins"  # Optional: Übergabeparameter
#       # )
#     )
#     "challenge06-solution-report.html"  # Gibt den Namen des generierten Berichts zurück
#   },
#   format = "file"  # Gibt an, dass das Ziel eine Datei ist
# )

  # render report in Quarto:
  # tar_quarto(challenge06_report, "challenge06-solution-report.qmd")
  
)
