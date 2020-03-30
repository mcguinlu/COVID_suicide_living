###########################################################################
# About -------------------------------------------------------------------
###########################################################################
#
# Title: 
# Author: 
# Description: 


###########################################################################
# External scripts --------------------------------------------------------
###########################################################################

# Library calls
source("R/library.R")

# Load updating scripts
source("R/perform_search.R")

# Load searching script
source("R/perform_search.R")

# Set working directory
WORKING_DIR=readLines("WORKING_DIR.txt")
setwd(WORKING_DIR)

# Read in credentials
GITHUB_USER <- readLines("GITHUB_USER.txt")
GITHUB_PASS <- readLines("GITHUB_PASS.txt")

# Define custom function
`%notin%` <- Negate(`%in%`)


###########################################################################
# Update underlying data sets ---------------------------------------------
###########################################################################

reticulate::py_run_file("data/retrieve_rss.py")

###########################################################################
# Perform searches --------------------------------------------------------
###########################################################################

# Define query 
topic1 <- c("suicide","depress", "mental health")

query <- list(topic1)


# bioRxiv/medRxiv searches  
data <- read.csv("data/bioRxiv_rss.csv", stringsAsFactors = FALSE, 
                 encoding = "UTF-8", header = TRUE)

colnames(data)[7] <- "date"

rx_results <- perform_search(query, data, from.date = 20200101, fields = c("title","abstract"), deduplicate = FALSE)




###########################################################################
# Daily updates --------------------------------------------------------
###########################################################################
previous_results <- read.csv("data/results/all_results.csv",
                             encoding = "UTF-8",
                             stringsAsFactors = FALSE,
                             header = TRUE)

new_results <- all_results[which(all_results$title %notin% previous_results$title), ]


###########################################################################
# Export results --------------------------------------------------------
###########################################################################

current_time <- format(Sys.time(), "%Y-%m-%d %H:%M")
current_date <- format(Sys.time(), "%Y-%m-%d")

writeLines(current_time, "data/results/timestamp.txt")

file_name_all <- "data/results/all_results.csv"
file_name_daily <- paste0("data/results/",current_date,"_results.csv")

write.csv(all_results,
          file = file_name_all,
          fileEncoding = "UTF-8",
          row.names = FALSE)

write.csv(new_results,
          file = file_name_daily,
          fileEncoding = "UTF-8",
          row.names = FALSE)

# Add new file name to list
file_name_list <- read.csv("data/results/results_list.csv", 
                           stringsAsFactors = FALSE)

file_name_df <- data.frame(file_name = paste0(current_date,"results.csv"),
                           stringsAsFactors = FALSE )
file_name_list <- rbind(file_name_list, file_name_df)
file_name_list <- unique(file_name_list)

write.csv(file_name_list,
          file = "data/results/results_list.csv",
          fileEncoding = "UTF-8",
          row.names = FALSE)

# Add and commit files
add(repo = getwd(),
    path = file_name)

add(repo = getwd(),
    path = "data/results/results_list.csv")

add(repo = getwd(),
    path = "data/timestamp.txt")

commit(repo = getwd(),
       message = paste0("Updated search results: ", current_time)
)

# Push the repo again
push(object = getwd(),
     credentials = cred_user_pass(username = GITHUB_USER,
                                  password = GITHUB_PASS))
