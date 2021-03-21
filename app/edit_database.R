#library(mongolite)

######Helper and general methods or explanation how to add or edit fields in database. 1. get current screening snapshot

#databaseName <- "COVID-suicide"
#collectionName <- "responses"
#current_date <- format(Sys.time(), "%Y-%m-%d")

#mongo_url <- paste0("mongodb+srv://allUsers:",
#                    readLines("password.txt"),
#                    "@covid-suicide-ndgul.mongodb.net/test?retryWrites=true&w=majority")



#db <- mongo(collection = collectionName,
            #            url = mongo_url)

#db_snapshot <- db$find()

#db_snapshot_name <- paste0("app/",current_date,"_snapshot.csv")

#write.csv(db_snapshot,
#          file = db_snapshot_name,
#          fileEncoding = "UTF-8",
#                    row.names = FALSE)

#names(db_snapshot)
######Either add csv columns manually or do it in R.
##Warning: Error in [.data.frame: undefined columns selected::: Check if windows appended something like "X.U.FEFF.title" and use r replacement function below if needed

######Reading from a csv, make sure that its utf-8 and that the dates are not messed up (my american laptop does that to the db, so please check that extraction dates are in uniform format becasue that date is key to some of the visualisations and heatmaps). I added columns in the csv before manually as I'm not an R wizard :)

#dat = read.csv(db_snapshot_name, stringsAsFactors = FALSE, encoding = "UTF-8", header = TRUE)
#dat[is.na(dat)] = ""#incase the new column values became NA
#names(dat)[1] <- "title"
#names(dat)
#print(dat)

#####Dont want to risk messing up the db, soadding a new collection to test if the app still runs after adding the new fields.. needs to be changed in app.R if new colelction ebcomes standard
#collectionName <- "responses_NEW_FIELDS"

#db <- mongo(collection = collectionName,
#            url = mongo_url)
#db$drop()
#db$insert(dat)
#db$find(limit=1)
