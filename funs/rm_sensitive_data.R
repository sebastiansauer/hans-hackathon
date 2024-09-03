
rm_sensitive_data <- function(input_path = "data-raw/matomo_export_2024-05-27_to_2024-06-03",
                              filename, 
                              output_path = "data-processed/data-raw-no-sensitive") {
  
  d <- read.csv(paste0(input_path, "/", filename))
  d["visitIp"] <- NULL
  d["visitorId"] <- NULL
  d["fingerprint"] <- NULL
  
  write.csv(d, paste0(output_path, "/", filename))
  
  cat("File has been written.")
  
}
