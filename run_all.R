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



###########################################################################
# Update underlying data sets ---------------------------------------------
###########################################################################


###########################################################################
# Perform searches --------------------------------------------------------
###########################################################################
# medRxiv search
mx_data <-
  read.csv(
    paste0(
      "https://raw.githubusercontent.com/mcguinlu/",
      "autosynthesis/master/data/",
      "medRxiv_abstract_list.csv"
    ), sep = ",",
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-8",
    header = TRUE)

mx_results <- perform_search(query, mx_data)

# bioRxiv search
bx_data <-
  read.csv(
    paste0(
      "https://raw.githubusercontent.com/mcguinlu/",
      "autosynthesis/master/data/",
      "medRxiv_abstract_list.csv"
    ), sep = ",",
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-8",
    header = TRUE)

bx_results <- perform_search(query, bx_data)

###########################################################################
# Export results --------------------------------------------------------
###########################################################################