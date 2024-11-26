
add_id_column <- function(d_long){

d_long |> 
  rename(id = name) |>  # new = old, "id" is the action number
  # "actiondetails_XXX_subtitl" --> "XXX":
  mutate(id = str_extract(id, "\\d+"))

}

