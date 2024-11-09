# choose targets pipeline:
Sys.setenv(TAR_PROJECT = "challange06")

# run the pipeline:
library(targets)
tar_make()



# run manually:
#tar_make(script = "challenges-solutions/challenge06-solution.R", store = "challenge06")
tar_make(script = "challenges-solutions/challenge06-solution_variant_a.R", store = "challenge06")
#tar_make(script = "challenges-solutions/challenge05-solution.R", store = "challenge05")

# load targets manually from a manually selected store:
tar_load("data_files_list", store = "challenge06")
