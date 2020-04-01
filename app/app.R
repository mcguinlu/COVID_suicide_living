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
             fluidRow(column(width = 6, h3(textOutput("total_no")),p("Click on the button on the right to download a snapshot of the database. To make decisions at the title/abstract stage, click \"Inital decision\".")),
                      column(width= 6, align = "right",br(),br(),  downloadButton("downloadallscreened", "Download snapshot of database") )),
             hr(),
             DT::dataTableOutput("all_records"),
             
             waiter::waiter_show_on_load()),
  
    tabPanel(title = "Initial decision",
             h3("Initial decisions"),
             p("Please use the \"Include\"/\"Exclude\" buttons to make an inital decision on each record.",
             "Records marked as \"Include\" will be passed to the \"Expert decision\" tab for further screening and data extraction.",
             "Once you make a decision, the program will automatically move to the next abstract - if you make a mistake, unclick the \"Show only IDs needing a decision\" checkbox and navigate to the record using the drop-down box.",
             "Clicking on the link in the \"Link\" column will open up the record in a new tab via it's DOI, or if no DOI was available, will perform a Google search of the records title."),
             textOutput("number_initial_undecide"),
             uiOutput("initalID"),
             checkboxInput("showall", "Show only IDs needing a decision", value = TRUE),
             actionButton("initalinclude", "Include"),
             actionButton("initalexclude", "Exclude"),
             tableOutput("test")
             ),
    
    tabPanel(title = "Expert decision",
             textOutput("number_initial_include"),
             uiOutput("expertID"),
             tableOutput("expert_table"),
             fluidRow(
               column(width = 3,
                      h4("Basic details"),
                      uiOutput("expert_decision"),
                      lapply(1:4, function(i) uiOutput(paste0("q",i)))),
               column(width = 3,
                      offset = 1,
                      h4("Advanced details"),
                      lapply(5:8, function(i) uiOutput(paste0("q",i)))),
               column(width = 3,
                      offset = 1,
                      h4(""),
                      lapply(9:11, function(i) uiOutput(paste0("q",i)))),
               
             )),
    
    
    tabPanel(title = "Test",
             # Application title
             
             h3("Choose file extension"),
             selectInput(
               "downloadtype",
               "Download file extension",
               choices = c("csv", "xlsx")
             ),
             hr(),
             h3("Download all results"),
             downloadButton("downloadallresults", "Download all results"),
             
             actionButton("savechanges", "Save"),
             
             
             h2("Daily results"),
             )
    
    ),
use_waiter())

# Define server logic required to draw a histogram
server <- function(input, output) {
    
    waiter::waiter_hide()

# Initial initial_decision --------------------------------------------------------

    output$number_initial_undecide <- renderText({
        initaldecision()
        paste0("There were ", db$count('{}'), " records found by the search, of which ", db$count('{"initial_decision": "Undecided"}')," record(s) need an initial decision")
    })
    
    output$test <- renderTable({
        initaldecision()
        if (input$showall == FALSE) {
          find <- '{}'
        } else {
          find <- '{"initial_decision": "Undecided"}'
        }
      
        if(nrow(db$find(find, fields = '{"_id": false,"ID": true}')) != 0){
        data <- db$find(query = sprintf('{"ID" : %s}',as.numeric(input$ID)), fields ='{"_id": false,"title": true, "abstract": true, "link": true, "initial_decision": true}' )
        data$link <- ifelse(data$link!="",paste0("<a href='", data$link, "' target='_blank'>Link</a>"),"")
        data
        }
      
            }, sanitize.text.function = function(x) x
        )
    
    output$initalID <- renderUI({
        initaldecision()
        if (input$showall == FALSE) {
            find <- '{}'
        } else {
            find <- '{"initial_decision": "Undecided"}'
        }
        tagList(
            selectInput("ID","ID", choices = db$find(find, fields = '{"_id": false,"ID": true}'))
        )
    })
    
    initaldecision <- reactive({
        input$initalinclude
        input$initalexclude
    })

    # Make inital decisions
    observeEvent(input$initalinclude,{
        db$update(query = sprintf('{"ID" : %s}',as.numeric(input$ID)), update = '{"$set":{"initial_decision":"Include"}}')
    })
    
    observeEvent(input$initalexclude,{
        db$update(query = sprintf('{"ID" : %s}',as.numeric(input$ID)), update = '{"$set":{"initial_decision":"Exclude"}}')
    })


# Expert decision ---------------------------------------------------------

    output$number_initial_include <- renderText({
      initaldecision()
      paste0(db$count('{"initial_decision": "Include"}')," record(s) included at title and abstract")
    })
    
    output$expert_decision <- renderUI({
      tagList(
        selectInput(inputId = "expert_decision",label = "Expert Decision",selected = db$find(query = sprintf('{"ID" : %s}',as.numeric(input$expert_ID)), fields ='{"_id": false,"expert_decision": true}'), choices = c("", "Include", "Exclude"))
      )
    })
    
    observeEvent(input$expert_decision,{
      db$update(
        query = sprintf('{"ID" : %s}', as.numeric(input$expert_ID)),
        update = sprintf('{"$set":{"expert_decision":"%s"}}', input$expert_decision)
      )
    })
    
    output$expert_table <- renderTable({
      initaldecision()
      if (input$showall == FALSE) {
        find <- '{}'
      } else {
        find <- '{"initial_decision": "Undecided"}'
      }
      
      if(nrow(db$find('{"initial_decision": "Include"}', fields = '{"_id": false,"ID": true}')) != 0){
        data <- db$find(query = sprintf('{"ID" : %s}',as.numeric(input$expert_ID)), fields ='{"_id": false,"ID": true,"title": true, "abstract": true, "link": true, "initial_decision": true}' )
        data$link <- ifelse(data$link!="",paste0("<a href='", data$link, "' target='_blank'>Link</a>"),"")
        data[,c(5,1:4)]
      }
      
    }, sanitize.text.function = function(x) x
    )
    
    output$expertID <- renderUI({
      initaldecision()
      tagList(
        selectInput(inputId = "expert_ID",label = "ID",selected = "",choices = db$find('{"initial_decision":"Include"}', fields = '{"_id": false, "ID": true}'))
      )
    })
    
    output$q1 <- renderUI({
      tagList(
        selectInput("q1",
                    "Study design",
                    choices = c("","case series","cross sectional survey","case control","cohort","non randomised intervention study","RCT","other"),
                    selected = db$find(sprintf(
                    '{"ID" : %s}', input$expert_ID
                    ),
                    fields = '{"_id": false,"q1": true}'))
      )
    })
    
    output$q2 <- renderUI({
      tagList(
        textInput("q2", "If other, please specify:", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                          fields = '{"_id": false,"q2": true}'))
      )
    })

    
    output$q3 <- renderUI({
      tagList(
        textInput("q3", "Setting (country/region)", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                          fields = '{"_id": false,"q3": true}'))
      )
    })
    
    output$q4 <- renderUI({
      tagList(
        textInput("q4", "Population studied", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                                    fields = '{"_id": false,"q4": true}'))
      )
    })
    
    output$q5 <- renderUI({
      tagList(
        textAreaInput("q5", "Outcome(s) investigated", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                              fields = '{"_id": false,"q5": true}'))
      )
    })
    
    output$q6 <- renderUI({
      tagList(
        textAreaInput("q6", "Sample size (describe)", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                                fields = '{"_id": false,"q6": true}'))
      )
    })
    
    output$q7 <- renderUI({
      tagList(
        textAreaInput("q7", "Key findings", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                                  fields = '{"_id": false,"q7": true}'))
      )
    })
    
    output$q8 <- renderUI({
      tagList(
        textAreaInput("q8", "Strengths", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                                  fields = '{"_id": false,"q8": true}'))
      )
    })
    
    output$q9 <- renderUI({
      tagList(
        textAreaInput("q9", "Limitations", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                                  fields = '{"_id": false,"q9": true}')),
        helpText("(Consider the following: random population sample vs. self-selected group / non-response bias / control selection bias / loss of follow-up / confounding)")
      )
    })
    
    output$q10 <- renderUI({
      tagList(
        textAreaInput("q10", "Implications for practice/policy", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                                  fields = '{"_id": false,"q10": true}'))
      )
    })
    
    output$q11 <- renderUI({
      tagList(
        textAreaInput("q11", "Implications for research", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                                             fields = '{"_id": false,"q11": true}'))
      )
    })
    
 
    # Capture inputs
    lapply(1:11, function(i){
      observeEvent(input[[paste0("q",i)]],{
        db$update(
          query = sprintf('{"ID" : %s}', as.numeric(input$expert_ID)),
          update = sprintf('{"$set":{"q%s":"%s"}}', i, input[[paste0("q",i)]])
        )
      })
    })
        

# All screened ------------------------------------------------------------

output$total_no <- renderText({
  paste0("Browse decision for all ",db$count()," records")
})    
    
output$all_records <- DT::renderDataTable({
  initaldecision()
  data <- db$find(query = '{}', fields = '{"_id": false,"title": true, "abstract": true,"initial_decision": true, "expert_decision": true, "link": true}')
  data$link <- sprintf("<a href='%s'>%s</a>", data$link, data$link)
  DT::datatable(
        data,
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

}

# Run the application 
shinyApp(ui = ui, server = server)
