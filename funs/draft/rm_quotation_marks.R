
rm_quotation_marks <- function(d, column){
  
  # by the way, we remove all quotation marks from the value column:
  d |> 
  mutate(value =  gsub('"', '', value)) |>
  mutate(value =  gsub("'", "", value)) 
}
