library(targets)
library(tarchetypes)  # Extention to "targets", eg watching source data files



# packages available for all targets:
tar_option_set(
  packages = c("dplyr", "purrr", "readr", "tidyr")
)




# targets, ie., steps to be computed:
list(
  # read data:
  tar_target(data_files_list, 
             list.files(path = <your paht>,  # your path to the data
                        full.names = TRUE,
                        pattern = "*.csv$",
                        recursive = FALSE), 
             format = "file"),  # watch data source files for changes
  
  
  
  
  # bind all csv files into one long dataframe:
  tar_target(import_stuff,
             read_csv(lkjdsf) |> 
               kjdsalflj() |> 
               kf(),
  
  
  
  # remove empty cols and rows:
  tar_target(<name of this step>,
              <previous step> |> 
               <enter your code here>),
  
  # remove constant cols:
  tar_target(<...>,
              <...> |> 
               <...>),
  
  # subsequent targets...
 
  
  
)  # end of pipeline
