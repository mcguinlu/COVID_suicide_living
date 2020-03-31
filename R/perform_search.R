#' Search database
#' @description Search medRxiv using a string
#' @param query Character string, vector or list
#' @param data Pass in database to search
#' @param fields Fields of the database to search - default is Title, Abstract,
#'   First author, Subject, and Link (which includes the DOI)
#' @param from.date Defines earlist date of interest. Written as a number in
#'   format YYYYMMDD. Note, records published on the date specified will also be
#'   returned.
#' @param to.date Defines latest date of interest. Written as a number in
#'   format YYYYMMDD. Note, records published on the date specified will also be
#'   returned.
#' @param NOT Vector of regular expressions to exclude from the search. Default
#'   is NULL.
#' @param deduplicate Logical. Only return the most recent version of a record.
#'   Default is TRUE.
#' @examples \dontrun{
#' mx_results <- mx_search("dementia")
#' }
#' @export
#' @importFrom utils download.file
#' @importFrom utils read.csv
#' @importFrom dplyr %>%


perform_search <- function(query,
                      data,      
                      fields = c("title","abstract","authors","subject","link"),
                      from.date = NULL,
                      to.date = NULL,
                      NOT = "",
                      deduplicate = FALSE 
){
  
  . <- NULL
  link <- NULL
  link_group <- NULL
  or_1 <- NULL
  or_2 <- NULL
  or_3 <- NULL
  or_4 <- NULL
  or_5 <- NULL
  link <- NULL
  
  
  
  # Error handling ----------------------------------------------------------

  # Load data
  mx_data <- data
  mx_data$internal_id <- seq(1,length(mx_data$title))
  
  # Implement data limits ---------------------------------------------------
  
  
  mx_data$date <- as.numeric(gsub("-","",mx_data$date))
  
  if (!is.null(to.date)) {
    mx_data <- mx_data %>% dplyr::filter(date <= to.date)
  }
  
  if (!is.null(from.date)) {
    mx_data <- mx_data %>% dplyr::filter(date >= from.date)
  }
  
  
  # Run search --------------------------------------------------------------
  
  
  if (is.list(query)) {
    
    # General code to find matches
    
    query_length <- as.numeric(length(query))
    
    and_list <- list()
    
    for (list in seq_len(query_length)) {
      tmp <- mx_data %>%
        dplyr::filter_at(dplyr::vars(fields),
                         dplyr::any_vars(grepl(paste(query[[list]],
                                                     collapse = '|'), .))) %>%
        dplyr::select(internal_id)
      tmp <- tmp$internal_id
      and_list[[list]] <- tmp
    }
    
    and <- Reduce(intersect, and_list)
    
  }
  
  if (!is.list(query) & is.vector(query)) {
    
    # General code to find matches
    tmp <- mx_data %>%
      dplyr::filter_at(dplyr::vars(fields),
                       dplyr::any_vars(grepl(paste(query,
                                                   collapse = '|'), .))) %>%
      dplyr::select(internal_id)
    
    and <- tmp$internal_id
    
  }
  
  #Exclude those in the NOT category
  
  if (NOT!="") {
    tmp <- mx_data %>%
      dplyr::filter_at(dplyr::vars(fields),
                       dplyr::any_vars(grepl(paste(NOT,
                                                   collapse = '|'), .))) %>%
      dplyr::select(internal_id)
    
    `%notin%` <- Negate(`%in%`)
    
    and <- and[and %notin% tmp$internal_id]
    
    results <- and
    
  } else {
    results <- and
  }
  
  
  if(length(query) > 1){
    mx_results <- mx_data[which(mx_data$internal_id %in% results),]
  } else {
    if(query == "*") {
      mx_results <- mx_data
    } else {
      mx_results <- mx_data[which(mx_data$internal_id %in% results),]
    }
  }
  
  
  if (deduplicate==TRUE) {
    mx_results$link <- gsub("\\?versioned=TRUE","", mx_results$link)
    
    mx_results$version <- substr(mx_results$link,
                                 nchar(mx_results$link),
                                 nchar(mx_results$link))
    
    mx_results$link_group <- substr(mx_results$link,1,nchar(mx_results$link)-2)
    
    mx_results <- mx_results %>%
      dplyr::group_by(link_group) %>%
      dplyr::slice(which.max(version))
    
    mx_results <- mx_results[1:12]
    
    # Post message and return dataframe
    message(paste0("Found ",
                   length(mx_results$link),
                   " record(s) matching your search."))
    
    mx_results
    
  } else {
    
    # Post message and return dataframe
    message(paste0("Found ",
                   length(mx_results$link),
                   " record(s) matching your search.\n",
                   "Note, there may be >1 version of the same record."))
    
    mx_results <- mx_results[,1:ncol(mx_results)-1]
    
    mx_results
    
  }
  
}


