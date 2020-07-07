#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(rio)
library(mongolite)
library(waiter)
library(DT)
library(markdown)
library(shinyjs)
library(stringr)

textAreaInput2 <- function (inputId, label, value = "", width = NULL, height = NULL, 
                            cols = NULL, rows = NULL, placeholder = NULL, resize = NULL) 
{
  value <- restoreInput(id = inputId, default = value)
  if (!is.null(resize)) {
    resize <- match.arg(resize, c("both", "none", "vertical", 
                                  "horizontal"))
  }
  style <- paste("max-width: 100%;", if (!is.null(width)) 
    paste0("width: ", validateCssUnit(width), ";"), if (!is.null(height)) 
      paste0("height: ", validateCssUnit(height), ";"), if (!is.null(resize)) 
        paste0("resize: ", resize, ";"))
  if (length(style) == 0) 
    style <- NULL
  div(class = "form-group", 
      tags$label(label, `for` = inputId), tags$textarea(id = inputId, 
                                                        class = "form-control", placeholder = placeholder, style = style, 
                                                        rows = rows, cols = cols, value))
}

# options(mongodb = list(
#     "host" = "-ndgul.mongodb.net/test?retryWrites=true&w=majority",
#     "username" = "mcguinlu:",
#     "password" = readLines("password.txt")
# ))
databaseName <- "COVID-suicide"
collectionName <- "responses"

mongo_url <- paste0("mongodb+srv://mcguinlu:",
             readLines("password.txt"),
             "@covid-suicide-ndgul.mongodb.net/test?retryWrites=true&w=majority")
db <- mongo(collection = collectionName,
            url = mongo_url)

# Define UI for application that draws a histogram
ui <- tagList(
    navbarPage(
        title = "COVID Suicide",
        id = "mytabsetpanel",
        theme = shinythemes::shinytheme("yeti"),
        
    tabPanel(title = "All records",
             fluidRow(column(width = 8, h3(textOutput("total_no")),p("Click on the button on the right to download a snapshot of the database. To make decisions at the title/abstract stage, click \"Inital decision\". Records marked for inclusion at the inital stage will appear in the \"Expert decision\" tab for second review and data extraction.")),
                      column(width= 4, align = "right",br(),  downloadButton("downloadallscreened", "Download snapshot of database") )),
             hr(),
             DT::dataTableOutput("all_records"),
             
             waiter::waiter_show_on_load()),
  
    tabPanel(title = "Initial assessment",
             h3(strong("Initial decisions")),
             p("Please use the \"Include\"/\"Exclude\" buttons to make an inital decision on each record.",
             "Records marked as \"Include\" will be passed to the \"Expert decision\" tab for further screening and data extraction.",
             "Once you make a decision, the program will automatically move to the next abstract - if you make a mistake, unclick the \"Show only IDs needing a decision\" checkbox and navigate to the record you wish to correct using the drop-down box.",
             "Clicking on the link in the \"Link\" column will open up the record in a new tab via it's DOI, or if no DOI was available, will perform a Google search of the record's title."),
             h4(strong(textOutput("number_initial_undecide"))),
             uiOutput("initalID"),
             checkboxInput("showall", "Show only IDs needing an initial assessment", value = TRUE),
             actionButton("initalinclude", "Send for further assessment"),
             actionButton("initalexclude", "Discard"),
             br(),
             tableOutput("test"),
 
             ),
    
    tabPanel(title = "Expert assessment",
             value = "expert_decision_pane",
             h3(strong("Expert assessment")),
             h4(strong(textOutput("number_expert_undecide"))),
             uiOutput("expertID"),
             checkboxInput("showallexpert", "Show only records that have not been marked as \"Complete\"", value = FALSE),
             fluidRow(column(width = 6,
             actionButton("expertinclude", "Include"),
             actionButton("expertexclude", "Exclude"),
             selectInput("exclusion_reason", label = "Exclusion reason (the Exclude button won't work until this is completed.)",
                          choices = c("","Single case report","Case series <5 cases","Suicide / self-harm not addressed","No original data presented","Duplicate","Other"))),
             column(width = 6, align = "right",downloadButton("report", "Generate report for this record")
)),
             tableOutput("expert_table"),
             hidden(div(id = "form",
             fluidRow(
               column(
                 width = 3,
                 uiOutput("basic_header"),
                 lapply(c(13,12,0:3), function(i)
                   uiOutput(paste0("q", i)))
               ),
               column(width = 8,
                      fluidRow(uiOutput("adv_header")),
                      fluidRow(
                        column(width = 6,
                               lapply(c(4,6,5), function(i)
                                 uiOutput(paste0(
                                   "q", i
                                 ))),
                               uiOutput("o1"),
                               uiOutput("q7")
                               ),
                        column(width = 6,
                               lapply(8:11, function(i)
                                 uiOutput(paste0(
                                   "q", i
                                 ))))
                      ), 
               
             ))
             ))
    ),
    
    tabPanel(title = "Expert decision table",
             br(),
             DT::dataTableOutput("expert_records")
             
    ),
    
    tabPanel(title = "About and Preferences",
             # Application title
             h2("About"),
             includeMarkdown("text/about.md"),
             hr(),
             h2("Preferences"),
             h4("Choose file extension"),
             selectInput(
               "downloadtype",
               "Download file extension for data",
               choices = c("xlsx","csv")
             ),
             selectInput(
               "downloadtype_report",
               "Download file extension for report",
               choices = c("pdf","docx")
             ),
             
             )
    
    ),
    tags$head(
      tags$style(
        HTML(".shiny-notification {
             position:fixed;
             top: calc(5%);
             width:25%;
             height: 7%;
             left: calc(75%);
             }
             "
        )
      )
    ),    
use_waiter(),
useShinyjs()
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
    
    waiter::waiter_hide()

# Initial initial_decision --------------------------------------------------------

  # Render text to show at top
  # Details the number found by search and the number needing inital screening
  output$number_initial_undecide <- renderText({
    initaldecision()
    paste0(
      "There were ",
      db$count('{}'),
      " records found by the search, of which ",
      db$count('{"initial_decision": "Undecided"}'),
      " record(s) need an initial decision"
    )
  })
    
  # Render ID dropdown box
  output$initalID <- renderUI({
    # Take dependency on inital decision
    initaldecision()
    
    # If showall, find all records, and don't autoprogress when screening
    if (input$showall == FALSE) {
      find <- '{}'
      selected <- isolate(input$ID)
    } else {
      find <- '{"initial_decision": "Undecided"}'
      selected <- ""
    }
    
    tagList(selectInput(
      "ID",
      "ID",
      choices = db$find(find, fields = '{"_id": false,"ID": true}'), 
      selected = selected
    ))
    
  })
  
  
  # Render table showing selected record
  output$test <- renderTable({
    initaldecision()
    req(input$ID)
    
    # If showall is TRUE, define search to only find records without an inital
    # decision
    # If FALSE, find all
    if (input$showall == FALSE) {
      find <- '{}'
    } else {
      find <- '{"initial_decision": "Undecided"}'
    }
    
    # If no of records found using search is 0, show nothing
    if (nrow(db$find(find, fields = '{"_id": false,"ID": true}')) != 0) {
      data <-
        db$find(query = sprintf('{"ID" : %s}', as.numeric(input$ID)),
                fields = '{"_id": false,"ID":true,"title": true, "abstract": true, "link": true, "initial_decision": true, "expert_decision": true}')
      # Format hyperlink correctly
      data$link <-
        ifelse(data$link != "",
               paste0("<a href='", data$link, "' target='_blank'>Link</a>"),
               "")
      data$ID <- as.character(data$ID)
      
      # Fix error created by empty abstracts
      if (is.null(data$abstract)) {
      data$abstract <- "NO ABSTRACT"
      data[, c(5, 1,6,2:4)]
      } else {
      data[, c(6, 1:5)]
      }  
    }
    
  }, sanitize.text.function = function(x)
    x)
    
  # Create reactive value that captures a decision  
  initaldecision <- reactive({
    input$initalinclude
    input$initalexclude
  })

  # Make inital "Include" decision and show notification
  observeEvent(input$initalinclude, {
    db$update(query = sprintf('{"ID" : %s}', as.numeric(input$ID)),
              update = '{"$set":{"initial_decision":"Include"}}')
    showNotification(h4(paste0(
      "Set ID ",
      as.numeric(input$ID),
      " to Initial: ",
      db$find(sprintf('{"ID" : %s}', as.numeric(input$ID)), fields = '{"_id": false,"initial_decision": true}')
    )), type = "message", duration = 60)
  })
  
  # Make inital "Exclude" decision and show notification
  observeEvent(input$initalexclude, {
    db$update(query = sprintf('{"ID" : %s}', as.numeric(input$ID)),
              update = '{"$set":{"initial_decision":"Exclude"}}')
    showNotification(h4(paste0(
      "Set ID ",
      as.numeric(input$ID),
      " to Initial: ",
      db$find(sprintf('{"ID" : %s}', as.numeric(input$ID)), fields = '{"_id": false,"initial_decision": true}')
    )), type = "message", duration = 60)
  })


# Expert decision ---------------------------------------------------------

  
  output$number_expert_undecide <- renderText({
    initaldecision()
    expertdecision()
    paste0(
      "There were ",
      db$count('{"initial_decision": "Include"}'),
      " record(s) marked for further assessment, of which ",
      db$count('{"initial_decision": "Include", "q12": "FALSE"}')+
        db$count('{"initial_decision": "Include", "q12": "False"}'),
      " record(s) need expert assessment and data extraction."
    )
  })
    
  output$expertID <- renderUI({
    input$expertexclude
    initaldecision()

    if (input$showallexpert == TRUE) {
      find <- '{"initial_decision": "Include", "q12": "FALSE"}'
      selected <- ""
    } else {
      find <- '{"initial_decision": "Include"}'
      selected <- isolate(input$expert_ID)
    }
    
    test <- db$find(find, fields = '{"_id": false, "ID": true, "authors": true}')
    test$name <- paste0(test$ID," - ", gsub(",","",stringr::word(test$authors, 1)))
    
    choices <- setNames(test$ID,test$name                        )
    
    test <- input$expert_ID
    if (nrow(db$find(find, fields = '{"_id": false,"ID": true}')) != 0) {
      tagList(
        selectInput(
          inputId = "expert_ID",
          label = "ID",
          selected = selected,
          choices = choices
        )
      )
    }
  })
  
  
  observe({
    initaldecision()
    expertdecision()
    req(input$expert_ID)
    
    if (input$showallexpert == TRUE) {
      find <- '{"initial_decision": "Include", "q12": "FALSE"}'
    } else {
      find <- '{"initial_decision": "Include"}'
    }
    
    if (nrow(data.frame(db$find(find, fields = '{"_id": false,"ID": true}'))) > 0) {
      show("form")
    } else {
      hide("form")
    }
    
    updateSelectInput(session, "exclusion_reason",selected = "")
  })
      


    expertdecision <- reactive({
      input$expertinclude
      input$expertexclude
    })
    
    # Make inital decisions
    observeEvent(input$expertinclude,{
      db$update(query = sprintf('{"ID" : %s}',as.numeric(input$expert_ID)), update = '{"$set":{"expert_decision":"Include"}}')
    })
    
    observeEvent(input$expertexclude,{
      req(input$exclusion_reason)
      db$update(query = sprintf('{"ID" : %s}',as.numeric(input$expert_ID)), update = '{"$set":{"expert_decision":"Exclude", "initial_decision":"Exclude" }}')
      db$update(
        query = sprintf('{"ID" : %s}', as.numeric(input$expert_ID)),
        update = sprintf('{"$set":{"exclusion_reason":"%s"}}', as.character(input$exclusion_reason))
      )
     })
    
    
    output$expert_table <- renderTable({
      expertdecision()
      req(input$expert_ID)
      
      if (input$showallexpert == TRUE) {
        find <- '{"initial_decision": "Include", "q12": "FALSE"}'
      } else {
        find <- '{}'
      }

      if(nrow(db$find(find, fields = '{"_id": false,"ID": true}')) != 0){
        data <- db$find(query = sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                        fields ='{"_id": false,"ID": true,"title": true, "abstract": true, "authors": true, "link": true, "initial_decision": true, "expert_decision": true,"q12": true}')
        data$link <- ifelse(data$link!="",paste0("<a href='", data$link, "' target='_blank'>Link</a>"),"")
        data$ID <- as.character(data$ID)
      if (is.null(data$abstract)) {
        data$abstract <- "NO ABSTRACT"
      } 
      if (is.null(data$authors)) {
        data$authors <- "NO AUTHORS LISTED"
      } 
        
        data <- data[, c("ID",
                 "title",
                 "authors",
                 "abstract",
                 "link",
                 "initial_decision",
                 "expert_decision",
                 "q12")]
        colnames(data)[8] <- "Complete"
        data
      }
      
      
      
    }, sanitize.text.function = function(x) x
    )
    
    
    output$basic_header <- renderUI({
      expertdecision()
      req(input$expert_ID)
      
          tagList(
          h4("Basic details")
          )
    })
    
    output$adv_header <- renderUI({
      expertdecision()
      req(input$expert_ID)
      
          tagList(
            h4("Advanced details")
          )
    })
    
    
    output$q0 <- renderUI({
      expertdecision()
      req(input$expert_ID)
      
      tagList(
        selectInput("q0",
                    "Assessor initals",
                    # Initials only
                    choices = sort(c("","AJ","DG","ECE","COO","HE", "SZ","PM","NK","RW","KH")),
                    selected = db$find(sprintf(
                      '{"ID" : %s}', input$expert_ID
                    ),
                    fields = '{"_id": false,"q0": true}')
                    )
      )
    })
    
    
    output$q1 <- renderUI({
      expertdecision()
      req(input$expert_ID)
      
      
      tagList(
        selectInput("q1",
                    "Study design",
                    choices = c(sort(c("","Case series","Cross sectional survey","Case control","Cohort","Non-randomised intervention study","RCT","Qualitative","Nested case control")),"Other"),
                    selected = db$find(sprintf(
                    '{"ID" : %s}', input$expert_ID
                    ),
                    fields = '{"_id": false,"q1": true}'))
      )
    })
    
    output$q2 <- renderUI({
      expertdecision()
      req(input$expert_ID)
      
      tagList(
        textInput("q2", "If other, please specify:", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                          fields = '{"_id": false,"q2": true}'))
      )
    })

    
    output$q3 <- renderUI({
      expertdecision()  
      req(input$expert_ID)
      

      tagList(
        textInput("q3", "Setting (country/region)", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                          fields = '{"_id": false,"q3": true}'))
      )
    })
    
    output$q4 <- renderUI({
      expertdecision() 
      req(input$expert_ID)
      

      tagList(
        textAreaInput2("q4", "Population studied", width = "100%", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                                    fields = '{"_id": false,"q4": true}'))
      )
    })
    
    # Outcome investigated
    output$q5 <- renderUI({
      expertdecision()  
      req(input$expert_ID)
      

      tagList(
        selectInput("q5", "Outcome(s) investigated",width = "100%", choices =  c("Suicide death", "Suicide attempts/selfharm", "Suicidal thoughts", "Other (please specify below)"), multiple = TRUE,
                       selected = unlist(stringr::str_split(db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                               fields = '{"_id": false,"q5": true}'),", "))
                       )
      )
    })
    
    # Update outcome, collapsing for proper saving
    # This is why it isn't in the lapply call later on
    observeEvent(input$q5,{
      db$update(
        query = sprintf('{"ID" : %s}', as.numeric(input$expert_ID)),
        update = sprintf('{"$set":{"q5":"%s"}}', paste0(input$q5,collapse = ", "))
      )
    })
    
    # Other outcomes
    output$o1 <- renderUI({
      expertdecision()  
      req(input$expert_ID)
      
      tagList(
        textInput("o1", "Other outcome(s) investigated (seperate with comma)", width = "100%",
                    value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                           fields = '{"_id": false,"o1": true}')
        )
      )
    })
    
    observeEvent(input$o1,{
      db$update(
        query = sprintf('{"ID" : %s}', as.numeric(input$expert_ID)),
        update = sprintf('{"$set":{"o1":"%s"}}', input$o1)
      )
    })
    
    output$q6 <- renderUI({
      expertdecision()     
      req(input$expert_ID)
      

      tagList(
        textAreaInput2("q6", "Sample size (describe)",width = "100%", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                                fields = '{"_id": false,"q6": true}'))
      )
    })
    
    output$q7 <- renderUI({
      expertdecision()    
      req(input$expert_ID)
      

      tagList(
        textAreaInput2("q7", "Key findings",width = "100%", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                                  fields = '{"_id": false,"q7": true}'))
      )
    })
    
    output$q8 <- renderUI({
      expertdecision() 
      req(input$expert_ID)

      tagList(
        textAreaInput2("q8", "Strengths",width = "100%", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                                  fields = '{"_id": false,"q8": true}'))
      )
    })
    
    output$q9 <- renderUI({
      expertdecision() 
      req(input$expert_ID)
      

      tagList(
        textAreaInput2("q9", "Limitations",width = "100%", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                                  fields = '{"_id": false,"q9": true}')),
      )
    })
    
    output$q10 <- renderUI({
      expertdecision() 
      req(input$expert_ID)
      

      tagList(
        textAreaInput2("q10", "Implications for practice/policy",width = "100%", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                                  fields = '{"_id": false,"q10": true}'))
      )
    })
    
    output$q11 <- renderUI({
      expertdecision() 
      req(input$expert_ID)
      

        tagList(
          textAreaInput2("q11", "Implications for research",width = '100%', value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                                               fields = '{"_id": false,"q11": true}'))
        )
      
    })
    
    
    output$q12 <- renderUI({
      expertdecision() 
      req(input$expert_ID)
      tagList(
        checkboxInput("q12", "Check this box to mark the record as \"Complete\" once you have finished filling out the fields.",
                      value = as.logical(db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                                                          fields = '{"_id": false,"q12": true}'))
                      )
      )
      
    })
    
    output$q13 <- renderUI({
      expertdecision() 
      req(input$expert_ID)
      tagList(
        checkboxInput("q13", "Check this box to mark the record as a \"Background\" record, which does not need data extraction",
                      value = as.logical(db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                 fields = '{"_id": false,"q13": true}')
                                         )
        )
      )
      
    })
    

    # Capture inputs
    lapply(c(0:4,6:13), function(i){
      observeEvent(input[[paste0("q",i)]],{
        db$update(
          query = sprintf('{"ID" : %s}', as.numeric(input$expert_ID)),
          update = sprintf('{"$set":{"q%s":"%s"}}', i, gsub("\\n","\\\\n",gsub('"','\\\\"',as.character(input[[paste0("q",i)]]))))
        )
      })
    })
        
    
    # observeEvent(input$exclusion_reason,{
    #   db$update(
    #     query = sprintf('{"ID" : %s}', as.numeric(input$expert_ID)),
    #     update = sprintf('{"$set":{"exclusion_reason":"%s"}}', as.character(input$exclusion_reason))
    #   )
    # })

# All screened ------------------------------------------------------------

output$total_no <- renderText({
  paste0("Browse decision for all ",db$count()," records")
})    
    
output$all_records <- DT::renderDataTable({
  initaldecision()
  data <- db$find(query = '{}', fields = '{"_id": false,"ID": true,"title": true, "abstract": true,"initial_decision": true, "expert_decision": true, "link": true, "authors":true}')
  data$link <- sprintf("<a href='%s' target='_blank'>Link</a>", data$link)
  data$ID <- as.character(data$ID)
  DT::datatable(
        data[,c(7,1:6)],
        rownames = FALSE,
        escape = FALSE
  )
})
    
output$downloadallscreened <- downloadHandler(
  filename = function() {
    paste0("all_screened.", input$downloadtype, sep = "")
  },
  content = function(file) {
    data <- db$find(query = '{}')
    data <- data[,c(21,1:20,22:ncol(data))]
    rio::export(data, file, format = input$downloadtype)
  }
)   


# Expert decisions --------------------------------------------------------

output$expert_records <- DT::renderDataTable({
  expertdecision()
  data <- db$find(query = '{}', fields = '{"_id": false,"ID": true,"title": true, "abstract": true,"initial_decision": true, "expert_decision": true, "link": true, "authors":true, "exclusion_reason": true, "q12": true,"q13":true,"q0":true }')
  data <- data %>% dplyr::filter(expert_decision != "")
  colnames(data)[which(colnames(data)=="q13")] <- "Background?"
  colnames(data)[which(colnames(data)=="q12")] <- "Complete?"
  colnames(data)[which(colnames(data)=="q0")] <- "Expert"
  data$link <- sprintf("<a href='%s' target='_blank'>Link</a>", data$link)
  data$ID <- as.character(data$ID)
  DT::datatable(
    data[, c(
      "ID",
      "title",
      "authors",
      "abstract",
      "link",
      "Expert",
      "expert_decision",
      "Complete?",
      "Background?"
    )], 
    rownames = FALSE,
    escape = FALSE
  )
})


# File output -------------------------------------------------------------

# Generate report for that study

output$report <- downloadHandler(
  # For PDF output, change this to "report.pdf"
  filename = paste0("report.",isolate(input$downloadtype_report)),
  content = function(file) {
    # Copy the report file to a temporary directory before processing it, in
    # case we don't have write permissions to the current working dir (which
    # can happen when deployed).
    
    tempReport <- file.path(tempdir(), "report.Rmd")
    
    if (isolate(input$downloadtype_report) == "pdf") {
    file.copy("report_pdf.Rmd", tempReport, overwrite = TRUE)
    } else {
    file.copy("report_word.Rmd", tempReport, overwrite = TRUE)
    }
    
    
    # Set up parameters to pass to Rmd document
    params <- list(ID = input$expert_ID, 
                   Title =       db$find(query = sprintf('{"ID" : %s}', as.numeric(input$expert_ID)), fields = '{"_id": false, "title": true}'),
                   Authors =     db$find(query = sprintf('{"ID" : %s}', as.numeric(input$expert_ID)), fields = '{"_id": false, "authors": true}'),
                   Abstract =    db$find(query = sprintf('{"ID" : %s}', as.numeric(input$expert_ID)), fields = '{"_id": false, "abstract": true}'),
                   Link =        db$find(query = sprintf('{"ID" : %s}', as.numeric(input$expert_ID)), fields = '{"_id": false, "link": true}'),
                   Design =      input$q1,
                   Designother = input$q2,
                   Setting =     input$q3,
                   Population =  input$q4,
                   Outcome =     input$q5,
                   Outcomeother =input$o1,
                   Size =        input$q6,
                   Findings =    input$q7,
                   Strength =    input$q8,
                   Limit =       input$q9,
                   Policyimp =   input$q10,
                   Researchimp = input$q11
    )
    # Knit the document, passing in the `params` list, and eval it in a
    # child of the global environment (this isolates the code in the document
    # from the code in this app).
    rmarkdown::render(tempReport,
                      output_file = file,
                      params = params,
                      envir = new.env(parent = globalenv())
    )
  }
)


}







# Run the application 
shinyApp(ui = ui, server = server)
