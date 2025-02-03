
# Challenge 09


library(targets)
library(tarchetypes)  # Extention to "targets", eg watching source data files
library(quarto)  # Quarto reports



# packages available for all targets:
tar_option_set(
  packages = c("dplyr", "readr", "purrr", "tidyr", "stringr", "janitor", 
               "data.table", "writexl", "lubridate", "collapse")
)


# set options:
options(lubridate.week.start = 1)

# source helper funs:
funs_files <- list.files(
  path = "funs", pattern = "\\.R", full.names = TRUE, recursive = TRUE)
invisible(lapply(funs_files, source))



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
               map(~ fread(.x, fill = TRUE, colClasses = "character")) |>  
               # convert list to dataframe using bind_rows:
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
  
  
  # Challenge 07: count times per visit etc. --------------------------------------
  
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
               select(id_visit, days_since_last_visit)),
  
  
  
  
  # Challenge 08: Interaction with LLM--------------------------------------------
  
  
  # count AI transcript clicks per month:
  tar_target(ai_transcript_clicks_per_month,
             action_types |> 
               mutate(clicks_transcript = str_detect(value, "click_transcript_word"))  |> 
               group_by(id_visit) |> 
               mutate(clicks_transcript_any = any(clicks_transcript == TRUE)) |> 
               filter(type == "timestamp") |> 
               add_dates() |> 
               group_by(id_visit) |> 
               filter(date_time == min(date_time)) |> 
               slice_head(n=1) |> 
               ungroup() |> 
               select(-c(clicks_transcript))
             ,
             packages = c("lubridate", "collapse", "stringr", "dplyr")),
  
  tar_target(llm_per_visit,
             action_types |> 
               #  mutate(llm = str_detect(value, "llm")) |> 
               mutate(is_timestamp = str_detect(type, "timestamp")) |> 
               mutate(date_time = parse_date_time(value, "ymd HMS")) |> 
               group_by(id_visit) |>
               reframe(visit_uses_llm = any(str_detect(value, "llm")),
                       min_time = min(date_time, na.rm = TRUE))),
  
  # count interactions with LLM per month:
  tar_target(ai_llm_per_months,
             action_types |> 
               filter(type == "eventcategory" | type == "timestamp") |> 
               add_dates() |> 
               group_by(year_month) |> 
               count(llm_interaction = str_detect(value, "llm")),
             packages = c("lubridate", "collapse", "stringr", "dplyr")),
  
  
  # count how many visitors interact with the LLM:
  tar_target(idvisit_has_llm, 
             action_types |> 
               mutate(has_llm = str_detect(value, "llm"))  |> 
               group_by(id_visit) |> 
               mutate(uses_llm = any(has_llm == TRUE)) |> 
               filter(type == "timestamp") |> 
               add_dates()  |> 
               filter(date_time == min(date_time)) |> 
               ungroup() |> 
               select(-c(has_llm)),
             packages = c("lubridate", "collapse", "stringr", "dplyr")),
  
  
  
  
  
  # Export data -------------------------------------------------------------
  
  tar_target(export_data_users_only_xlsx,
             data_users_only |> write_xlsx("data-processed/MASTER-data_users_only.xlsx"),
             packages = "writexl"),
  tar_target(export_action_types_csv,
             data_users_only |> write_csv("data-processed/MASTER-data_users_only.csv")),
  
  # Render report -----------------------------------------------------------
  
  


# Glotzdauer, Challenge 09 --------------------------------------------------------------


tar_target(glotzdauer,
           action_types |> 
             glotzdauer_playpause())


# Render report -----------------------------------------------------------



  
  # render report in Quarto:
  # tar_quarto(challenge08_report, "challenges_solutions/challenge08.qmd")
  
)
