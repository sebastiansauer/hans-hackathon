# choose targets pipeline, for example, challenge06:
Sys.setenv(TAR_PROJECT = "challenge05")

# run the pipeline:
library(targets)
tar_make()



# run manually:

#tar_make(script = "challenges-solutions/challenge07-solution.R", store = "challenge06")
# tar_make(script = "challenges-solutions/challenge06-solution.R", store = "challenge06")
tar_visnetwork(script = "challenge05-solution.R", store = "challenge06")
#tar_make(script = "challenges-solutions/challenge09-solution.R", store = "challenge09")
tar_make(script = "challenges-solutions/MASTER-solution-pipeline.R", store = "mastersolution")

tar_make(script = "challenge06-solution.R", store = "challenge06")

# load targets manually from a manually selected store:
tar_load("rm_constants", store = "challenge05")
