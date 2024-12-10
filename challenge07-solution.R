#Sys.setenv(TAR_PROJECT = "challenge07")


library(targets)
library(tarchetypes)  # Extention to "targets", eg watching source data files
library(quarto)  # Quarto reports



# packages available for all targets:
tar_option_set(
  packages = c("tidyverse")
)


# set options:
options(lubridate.week.start = 1)

# source funs:
funs_files <- list.files(
  path = "funs", pattern = "\\.R", full.names = TRUE)
lapply(X = funs_files, FUN = source)



# targets, ie., steps to be computed:
list(
  
  

# data import and cleansing -----------------------------------------------

  
  # read data:
  tar_target(data_files_list, 
             list.files(path = paste0(here::here(),"/data-processed/data-raw-no-sensitive"),  # MY path to the data
                        full.names = TRUE,
                        pattern = "*.csv$",
                        recursive = TRUE), 
             format = "file"),  # watch data source files
  
  # bind all csv files into one long dataframe:
  tar_target(one_df,
             data_files_list |> 
               map(~ fread(.x, fill = TRUE, colClasses = "character")) |> 
               rbindlist(fill = TRUE, idcol = "file", use.names = TRUE),
             packages = "data.table"),
  
  # remove empty cols and rows:
  tar_target(rm_empty,
             one_df |> 
               remove_empty(which = c("rows", "cols")), packages = "janitor"),
  
  # remove constant cols:
  tar_target(rm_constants,
             rm_empty |> 
               remove_constant(), packages = "janitor"),

  # Clean column names:
  tar_target(clean_col_names,
             rm_empty |> clean_names(),
             packages = "janitor"),
  
  # # select only subtitles and timestamps columns:
  # tar_target(df_subtitles_timestamps,
  #            clean_col_names |> 
  #              select(id_visit, contains("subtitle"), contains("timestamp"))),
  
  # repair date-time cols:
  tar_target(repair_dttm,
             clean_col_names |> 
               mutate(across(contains("timestamp"), ~ as_datetime(as.numeric(.x)))),
             packages = c("lubridate", "dplyr")),
  
  
  # exclude developers, lecturers and admins:
  tar_target(data_users_only,
             repair_dttm |> 
               filter(!str_detect(action_details_0_subtitle, "developer|lecturer|admin")),
             packages = "stringr"),




# longify data ------------------------------------------------------------



  # pivot longer:
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
  
  
  # mutate to numeric:
  tar_target(numeric_id,
             add_id_col |> 
               mutate(action_count = as.integer(action_count))),
  
  
  # get types of actions:
  tar_target(action_types,
             numeric_id |>
               separate(name, sep = "_", into = c("constant1", "constant2", "nr", "type")) |> 
               select(-constant1, -constant2, -nr),
             packages = "tidyr"),
  
  
  # count stuff per visit -------------------------------------------------
  
  # count actions per visit:
  tar_target(actions_per_visit,
             numeric_id |>
               group_by(id_visit) |>
               # "nr" is the id of the action of this visit:
             summarise(nr_max = max(action_count))),

  # count action categories per visit:
  tar_target(count_action_type,
           count_user_action_type(action_types), packages = c("stringr", "dplyr")),


# count times per visit etc. ----------------------------------------------

  # start and end time of user's visit:
  tar_target(time_minmax,
             action_types |> time_min_max(),
             packages = c("lubridate", "dplyr")),

  # time spent on the site:
  tar_target(time_spent,
             action_types |> diff_time(),
             packages = c("lubridate", "dplyr")),
  
  tar_target(time_duration,
           data_users_only %>% 
             select(id_visit, visit_duration) %>% 
             mutate(visit_duration_sec = as.numeric(visit_duration)) %>% 
             select(-visit_duration)),

  # count time of visit per weekday:
  tar_target(time_visit_wday,
           action_types |> when_visited(), 
           packages = c("collapse", "lubridate", "dplyr")),

  # count time since last visit on site:
  tar_target(time_since_last_visit,
           data_users_only |> 
             select(id_visit, days_since_last_visit))

  
  # render report in Quarto:
  # tar_quarto(challenge07_report, "challenges_solutions/challenge07.qmd")
  
)
