# choose targets pipeline, for example, challenge06:
Sys.setenv(TAR_PROJECT = "challenge05")

# run the pipeline:
library(targets)
tar_make()



# run manually:


tar_visnetwork(script = "challenges-solutions/challenge08-solution.R", store = "mastersolution")

tar_make(script = "challenge08-solution.R", 
         store = "mastersolution")




