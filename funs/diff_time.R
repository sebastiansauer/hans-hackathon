diff_time <- function(data, group = id_visit, time = time) {
  data |> 
    filter(type ==  "timestamp") |> 
    group_by(id_visit) |> 
    #mutate(type = as.character(type)) |> 
    mutate(time = parse_date_time(value, "ymd HMS"),
            time_diff = max(time) - min(time)) 
}

