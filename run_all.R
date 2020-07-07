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

# Define regex query
suicide_query <- paste0(readLines("data/search_regexes_single_suicide.txt"), collapse = "|")
regex_query <- list(suicide_query)

#Define PubMed query
pudmed_query <- readLines("data/search_regexes_pubmed.txt")


###########################################################################
# External scripts --------------------------------------------------------
###########################################################################

# Library calls
source("R/library.R")

# Load searching script
source("R/perform_search.R")


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

# Update scopus dataset
reticulate::py_run_file("data/els_retrieve.py")

# Update WHO dataset
reticulate::py_run_file("data/who_rss.py")

# Update psy and soc dataset
reticulate::py_run_file("data/osf_share_rss.py")

###########################################################################
# Perform searches --------------------------------------------------------
###########################################################################
#############
#data from scopus
scop_data <- read.csv("data/scopus.csv", stringsAsFactors = FALSE, encoding = "UTF-8", header = TRUE)

scop_data$date <- character(length = nrow(scop_data))

for (row in 1:nrow(scop_data)) {
  scop_data$date[row] <- paste0(rev(unlist(stringr::str_split(scop_data$publication_date[row], "/"))),collapse = "")
}

scop_results <- perform_search(regex_query, scop_data, fields = c("title","abstract"))

# Clean results
scop_clean_results <- data.frame(stringsAsFactors = FALSE,
                                title       = scop_results$title,
                                abstract    = scop_results$abstract,
                                authors     = scop_results$authors,
                                link        = scop_results$link,
                                date        = scop_results$date,
                                subject     = scop_results$subject,
                                source      = scop_results$Source
)
#########################
##Data from Kaggle dataset, including microsoft Academic indexed Elsevier, PMC and Chan Zuckerberg Initiative records. Updated once a week, #TODO auto-update
misc_data <- read.csv("data/MA_elsevier_database.csv", stringsAsFactors = FALSE, encoding = "UTF-8", header = TRUE)

misc_data$date <- character(length = nrow(misc_data))

for (row in 1:nrow(misc_data)) {
  misc_data$date[row] <- paste0(rev(unlist(stringr::str_split(misc_data$publication_date[row], "/"))),collapse = "")
}

misc_results <- perform_search(regex_query, misc_data, fields = c("title","abstract"))

# Clean results
misc_clean_results <- data.frame(stringsAsFactors = FALSE, 
                                title       = misc_results$title,   
                                abstract    = misc_results$abstract,      
                                authors     = misc_results$authors,     
                                link        = misc_results$link,  
                                date        = misc_results$date,  
                                subject     = misc_results$subject,     
                                source      = misc_results$Source      
)

#############
#-#-#-#
# bioRxiv/medRxiv searches
#-#-#-#

rx_data <- read.csv("data/bioRxiv_rss.csv", stringsAsFactors = FALSE, 
                 encoding = "UTF-8", header = TRUE)

colnames(rx_data)[7] <- "date"

rx_results <- perform_search(regex_query, rx_data, fields = c("title","abstract"))

rx_results$source <- gsub("True","medRxiv", gsub("False","bioRxiv",rx_results$is_medRxiv))

# Clean results
rx_clean_results <- data.frame(stringsAsFactors = FALSE,
                               title       = rx_results$title,   
                                abstract    = rx_results$abstract,      
                                authors     = rx_results$authors,     
                                link        = rx_results$link,  
                                date        = rx_results$date,  
                                subject     = rx_results$subject,     
                                source      = rx_results$source)

#-#-#-#
# WHO searches
#-#-#-#

who_data <- read.csv("data/who_rss.csv", stringsAsFactors = FALSE, 
                 encoding = "UTF-8", header = TRUE)

colnames(who_data)[7] <- "date"

who_results <- perform_search(regex_query, who_data, fields = c("title","abstract"))

who_results$subject <- gsub("\\*","",who_results$subject)
who_results$source <- "WHO"

# Clean results
who_clean_results <- data.frame(stringsAsFactors = FALSE,
                                title       = who_results$title,   
                                abstract    = who_results$abstract,      
                                authors     = who_results$authors,     
                                link        = who_results$link,  
                                date        = who_results$date,  
                                subject     = who_results$subject,     
                                source      = who_results$source)
#-#-#-#
# psyArxiv searches: perform search anywa because the osf search api returns some aditional results that can not be relevant
#-#-#-#

psyArxiv_data <- read.csv("data/psyArXiv.csv", stringsAsFactors = FALSE, 
                 encoding = "UTF-8", header = TRUE)

colnames(psyArxiv_data)[7] <- "date"

psyArxiv_results <- perform_search(regex_query, psyArxiv_data, fields = c("title","abstract"))

psyArxiv_results$source <- "PsyArXiv"

# Clean results
psyArxiv_clean_results <- data.frame(stringsAsFactors = FALSE,
                                title       = psyArxiv_results$title,   
                                abstract    = psyArxiv_results$abstract,      
                                authors     = psyArxiv_results$authors,     
                                link        = psyArxiv_results$link,  
                                date        = psyArxiv_results$date,  
                                subject     = psyArxiv_results$subject,     
                                source      = psyArxiv_results$source)


#-#-#-#
# socArxiv searches
#-#-#-#

socArxiv_data <- read.csv("data/socArXiv.csv", stringsAsFactors = FALSE, 
                 encoding = "UTF-8", header = TRUE)

colnames(socArxiv_data)[7] <- "date"

socArxiv_results <- perform_search(regex_query, socArxiv_data, fields = c("title","abstract"))

socArxiv_results$source <- "SocArXiv"

# Clean results
socArxiv_clean_results <- data.frame(stringsAsFactors = FALSE,
                                title       = socArxiv_results$title,   
                                abstract    = socArxiv_results$abstract,      
                                authors     = socArxiv_results$authors,     
                                link        = socArxiv_results$link,  
                                date        = socArxiv_results$date,  
                                subject     = socArxiv_results$subject,     
                                source      = socArxiv_results$source)

#-#-#-#
# PubMed
#-#-#-#


t <- get_pubmed_ids(pudmed_query)
abstracts_xml <- fetch_pubmed_data(pubmed_id_list = t,
                                   retmax = t$Count)

test <- articles_to_list(abstracts_xml)

pubmed_results <- article_to_df(test[1], getAuthors = FALSE, getKeywords = TRUE, max_chars = -1)
pubmed_results$authors <- paste0(custom_grep(test[1],"LastName","char"),collapse = ", ")

for (article in 2:length(test)) {
  tmp <- article_to_df(test[article], getAuthors = FALSE, getKeywords = TRUE, max_chars = -1)
  tmp$authors <- paste0(custom_grep(test[article],"LastName","char"),collapse = ", ")
  pubmed_results<- rbind(pubmed_results,tmp)
}

pubmed_results$date <- paste0(pubmed_results$year,
                              pubmed_results$month,pubmed_results$day)

pubmed_clean_results <- data.frame(stringsAsFactors = FALSE,
                                   title    = pubmed_results$title,   
                                   abstract    = pubmed_results$abstract,      
                                   authors     = pubmed_results$authors,     
                                   link        = pubmed_results$doi,  
                                   date        = pubmed_results$date,  
                                   subject     = pubmed_results$keywords,     
                                   source      = rep("PubMed",length(pubmed_results$title)))      

# Combine all clean search results into final
all_results <- rbind(rx_clean_results,
                     who_clean_results,
                     pubmed_clean_results,
                     scop_clean_results,
                     psyArxiv_clean_results,
                     socArxiv_clean_results,
                     misc_clean_results)

write.csv(all_results,"data/total_found.csv", row.names = FALSE)

all_results$initial_decision <- ""

for (row in 1:nrow(all_results)) {
  if (stringr::str_sub(all_results$link[row],1,2)=="10") {
    all_results$link[row] <- paste0("https://doi.org/",all_results$link[row])
  }
  
  if (all_results$link[row] == "") {
    # Convert title to google search query if no link exists
    all_results$link[row] <- paste0("https://www.google.com/search?q=",paste0(unlist(stringr::str_split(all_results$title[row]," ")), collapse = "+"))
  }
}

for (col in 0:13) {
  all_results[[paste0("q",col)]] <- character(length = nrow(all_results))
}

all_results$q12 <- "FALSE"
all_results$q13 <- "FALSE"

all_results$exclusion_reason <- ""

all_results$extraction_date = rep(format(Sys.time(), "%Y-%m-%d"),length(all_results$title))

###########################################################################
# Daily updates --------------------------------------------------------
###########################################################################
previous_results <- read.csv("data/results/all_results.csv",
                             encoding = "UTF-8",
                             stringsAsFactors = FALSE,
                             header = TRUE)

previous_results_tmp <- previous_results %>%
  select(-expert_decision,-initial_decision,-ID)

previous_results_tmp$title <- gsub("\\.","",previous_results_tmp$title)
all_results$title <- gsub("\\.","",all_results$title)

write.csv(previous_results_tmp, "data/results/all_results_tmp.csv",
          row.names = FALSE,
          fileEncoding = "UTF-8")


write.csv(all_results, "data/results/new_results.csv",
          row.names = FALSE,
          fileEncoding = "UTF-8")

#############DEDUPLICATION
##usage: maybe add all new results to the previous results spreadsheet, and then
#run dedupe on the lot? A report, logging which articles were removed will
#appear in the same directory as the target csv 

#this line in the
#dedupeppy file at the bottom specifies which csv to dedupe:
#path=os.path.join("results", "all_results.csv")
reticulate::py_run_file("data/dedupe.py")
#

# Read in deduplicated
new_results <- read.csv("data/results/new_and_deduped.csv",
                        stringsAsFactors = FALSE) %>%
  select(-X) %>%
  mutate_all(replace_na, replace = "") %>%
  distinct(link, .keep_all = TRUE)

# Deduplicate based on DOI also
# Captures thing like different languages and other inexplicable results
# E.g. [https://doi.org/10.2196/19297]
new_results <- new_results[which(new_results$link %notin% previous_results$link),]

# Clean and prep for addition
if (nrow(new_results)!=0) {
    new_results$initial_decision <- "Undecided"
    new_results$expert_decision <- ""


    if (max(previous_results$ID)==-Inf) {
      new_results$ID <- seq(1:nrow(new_results))
    } else {
      new_results$ID <- seq((max(previous_results$ID)+1),(max(previous_results$ID)+ nrow(new_results)))
    }
}

new_results$o1 <- character(length = nrow(new_results))

all_results <- rbind(previous_results,
                     new_results)

all_results <- all_results %>% 
  mutate_all(~ replace_na(.x, "")) %>%
  as.data.frame()

all_results$ID <- as.numeric(all_results$ID)

###########################################################################
# Export results --------------------------------------------------------
###########################################################################

#Set-up
  current_time <- format(Sys.time(), "%Y-%m-%d %H:%M")
  current_date <- format(Sys.time(), "%Y-%m-%d")
  
  writeLines(current_time, "data/results/timestamp.txt")
  
  file_name_all <- "data/results/all_results.csv"
  file_name_daily <- paste0("data/results/",current_date,"_results.csv")
  db_snapshot_name <- paste0("data/screening_snapshot/",current_date,"_snapshot.csv")


# Take and save snapshot of the database, and add new results
  databaseName <- "COVID-suicide"
  collectionName <- "responses"
  mongo_url <- paste0("mongodb+srv://mcguinlu:",
                      readLines("app/password.txt"),
                      "@covid-suicide-ndgul.mongodb.net/test?retryWrites=true&w=majority")
  
  db <- mongo(collection = collectionName, url = mongo_url)
  
  db_snapshot <- db$find()
  
  write.csv(db_snapshot,
            file = db_snapshot_name,
            fileEncoding = "UTF-8",
            row.names = FALSE)
  
  db$insert(new_results)


# Save other CSV files
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
      path = db_snapshot_name)
  
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
