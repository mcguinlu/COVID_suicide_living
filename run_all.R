###########################################################################
# About -------------------------------------------------------------------
###########################################################################
#
# Title: 
# Author: 
# Description: 

###########################################################################
# Define queries ----------------------------------------------------------
###########################################################################

# Define query 
topic1 <- c("suicide","depress", "mental health")

query <- list(topic1)

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

# Update bioRxiv/medRxiv dataset
reticulate::py_run_file("data/retrieve_rss.py")

###########################################################################
# Perform searches --------------------------------------------------------
###########################################################################

# bioRxiv/medRxiv searches  
rx_data <- read.csv("data/bioRxiv_rss.csv", stringsAsFactors = FALSE, 
                 encoding = "UTF-8", header = TRUE)

colnames(rx_data)[7] <- "date"

rx_results <- perform_search(query, rx_data, fields = c("title","abstract"))

rx_results$source <- gsub("True","medRxiv", gsub("False","bioRxiv",rx_results$is_medRxiv))

rx_clean_results <- data.frame(title       = rx_results$title,   
                                abstract    = rx_results$abstract,      
                                authors     = rx_results$authors,     
                                link        = rx_results$link,  
                                date        = rx_results$date,  
                                subject     = rx_results$subject,     
                                source      = rx_results$source)

# WHO searches

who_data <- read.csv("data/WHO_database.csv",
                             encoding = "UTF-8",
                             stringsAsFactors = FALSE,
                             header = TRUE)

colnames(who_data) <- tolower(colnames(who_data))
colnames(who_data)[4] <- "date"
colnames(who_data)[11] <- "link"
colnames(who_data)[16] <- "subject"

who_results <- perform_search(query, who_data, fields = c("title","abstract", "subject"))

who_results$subject <- gsub("\\*","",who_results$subject)

who_clean_results <- data.frame(title       = who_results$title,   
                                abstract    = who_results$abstract,      
                                authors     = who_results$authors,     
                                link        = who_results$link,  
                                date        = who_results$date,  
                                subject     = who_results$subject,     
                                source      = rep("WHO",length(who_results$title))       
)

# PubMed

pudmed_query <- "(suicide OR mental health) AND coronavirus"

abstracts_xml <- fetch_pubmed_data(pubmed_id_list = get_pubmed_ids(pudmed_query))

test <- articles_to_list(abstracts_xml)

# Create basic dataframe
pubmed_results <- article_to_df(test[1], getAuthors = FALSE, getKeywords = TRUE)
pubmed_results$authors <- paste0(custom_grep(test[1],"LastName","char"),collapse = ", ")

# Iterate through results
for (article in 2:length(test)) {
  tmp <- article_to_df(test[article], getAuthors = FALSE, getKeywords = TRUE)
  tmp$authors <- paste0(custom_grep(test[article],"LastName","char"),collapse = ", ")
  pubmed_results<- rbind(pubmed_results,tmp)
}

# Generate date variable
pubmed_results$date <- paste0(pubmed_results$year,pubmed_results$month,pubmed_results$day)

pubmed_clean_results <- data.frame(title    = pubmed_results$title,   
                                abstract    = pubmed_results$abstract,      
                                authors     = pubmed_results$authors,     
                                link        = pubmed_results$doi,  
                                date        = pubmed_results$date,  
                                subject     = pubmed_results$keywords,     
                                source      = rep("PubMed",length(pubmed_results$title))       
)


# Combine all clean search results into final
all_results <- rbind(rx_clean_results,
                     who_clean_results,
                     pubmed_clean_results)

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
    path = file_name_all)

add(repo = getwd(),
    path = file_name_daily)

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
