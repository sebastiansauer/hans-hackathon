
glotzdauer_playpause <- function(d){

x2 <- 
d |> 
  # for each id_visit, we are interested in the actions where some videoplayer clicks happened.
  group_by(id_visit, action_count) |> 
  # we are only interested in visits, where some videoplayer clicks happened:
  filter(any(str_detect(value, "videoplayer_click"))) |> 
  # now we look only at rows where videoplayer clicks happend and their times are reported:
  filter((type == "subtitle" & str_detect(value, "videoplayer_click")) | 
           (type == "timestamp")) |> 
  
  # # by the way, we remove all quotation marks from the value column:
  # mutate(value =  gsub('"', '', value)) |>
  # mutate(value =  gsub("'", "", value)) |> 
  
  # remove all text from the value column, except for the words "play", "pause" and "set_position",
  # but do not remove timestamps:
  mutate(value =  if_else(type != "timestamp",
                          str_extract(value, "\\b(play|pause|set_position)\\b"), value)) |> 
  
  distinct(.keep_all = TRUE) |> 
  
  # one column with "timestamp", one with "subtitle", (start, pause, set position):
  pivot_wider(
    id_cols = c(id_visit, action_count),  # Columns to keep as identifiers
    names_from = type,                    # Column whose values become column names
    values_from = value                   # Column whose values fill the new columns
  ) |> 
  
  # repair the timestamp column:
  mutate(timestamp = ymd_hms(timestamp)) |> 
  ungroup() |> 
  
  # compute the time diff between start and pause of the video:
  mutate(
    # Create a grouping variable that increments every time we encounter a "pause"
    group = cumsum(subtitle == "pause")
  )  %>%
  group_by(group) %>%
  filter(any(subtitle == "play") & any(subtitle == "pause"))


  # summarise the time intervals:
x3 <-
  x2 |> 
  summarise(
    id_visit = first(id_visit),
    start_time = timestamp[subtitle == "play"][1],
    end_time = timestamp[subtitle == "pause"][1],
    time_interval = as.numeric(difftime(end_time, start_time, units = "secs"))
  ) %>%
  ungroup()

return(x3)
}



