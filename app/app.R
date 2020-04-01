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
  
    tabPanel(title = "Initial decision",
             h3("Initial decisions"),
             p("Please use the \"Include\"/\"Exclude\" buttons to make an inital decision on each record.",
             "Records marked as \"Include\" will be passed to the \"Expert decision\" tab for further screening and data extraction.",
             "Once you make a decision, the program will automatically move to the next abstract - if you make a mistake, unclick the \"Show only IDs needing a decision\" checkbox and navigate to the record you wish to correct using the drop-down box.",
             "Clicking on the link in the \"Link\" column will open up the record in a new tab via it's DOI, or if no DOI was available, will perform a Google search of the record's title."),
             textOutput("number_initial_undecide"),
             uiOutput("initalID"),
             checkboxInput("showall", "Show only IDs needing an initial decision", value = TRUE),
             actionButton("initalinclude", "Include"),
             actionButton("initalexclude", "Exclude"),
             tableOutput("test")
             ),
    
    tabPanel(title = "Expert decision",
             h3("Expert decisions"),
             textOutput("number_initial_include"),
             div(style="display: inline-block;vertical-align:top; width: 150px;",uiOutput("expertID")),
             div(style="display: inline-block;vertical-align:top; width: 100px;",HTML("<br>")),
             div(style="display: inline-block;vertical-align:top; width: 150px;",uiOutput("expert_decision")),
             tableOutput("expert_table"),
             fluidRow(
               column(width = 3,
                      uiOutput("basic_header"),
                      lapply(1:3, function(i) uiOutput(paste0("q",i)))),
               column(width = 8,
                      fluidRow(uiOutput("adv_header")),
              fluidRow(column(width = 6,
                      lapply(4:7, function(i) uiOutput(paste0("q",i)))),
               column(width = 6,
                      lapply(8:11, function(i) uiOutput(paste0("q",i)))))),
               
             )),
    
    
    tabPanel(title = "About and Preferences",
             # Application title
             h2("About"),
             includeMarkdown("text/about.md"),
             hr(),
             h2("Preferences"),
             h4("Choose file extension"),
             selectInput(
               "downloadtype",
               "Download file extension",
               choices = c("xlsx","csv")
             ),

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
    
    output$expertID <- renderUI({
      initaldecision()
      if (nrow(db$find('{"initial_decision": "Include"}', fields = '{"_id": false,"ID": true}')) != 0){
      tagList(
        selectInput(inputId = "expert_ID",label = "ID",selected = "",choices = data.frame(db$find('{"initial_decision":"Include"}', fields = '{"_id": false, "ID": true}'))[,1])
      )
      }  
    })
    
    output$expert_decision <- renderUI({
      initaldecision()
      
      if (nrow(data.frame(db$find('{"initial_decision": "Include"}', fields = '{"_id": false, "ID": true}'))) > 0){
      tagList(
        selectInput(inputId = "expert_decision",label = "Expert Decision", selected = db$find(query = sprintf('{"ID" : %s}',as.numeric(input$expert_ID)), fields ='{"_id": false,"expert_decision": true}'), choices = c("", "Include", "Exclude"))
      )
      }  
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
    
    
    output$basic_header <- renderUI({
      input$expert_decision
      if (nrow(data.frame(db$find('{"initial_decision": "Include"}', fields = '{"_id": false,"ID": true}'))) > 0) {
        
        if (db$find(query = sprintf('{"ID" : %s}',as.numeric(input$expert_ID)), fields ='{"_id": false,"expert_decision": true}') == "Include") {
          tagList(
          h4("Basic details")
          )
        }}
    })
    
    output$adv_header <- renderUI({
      input$expert_decision
      if (nrow(data.frame(db$find('{"initial_decision": "Include"}', fields = '{"_id": false,"ID": true}'))) > 0) {
        
        if (db$find(query = sprintf('{"ID" : %s}',as.numeric(input$expert_ID)), fields ='{"_id": false,"expert_decision": true}') == "Include") {
          tagList(
            h4("Advanced details")
          )
        }}
    })
      
    
    output$q1 <- renderUI({
      input$expert_decision
      if (nrow(data.frame(db$find('{"initial_decision": "Include"}', fields = '{"_id": false,"ID": true}'))) > 0) {
        
      if (db$find(query = sprintf('{"ID" : %s}',as.numeric(input$expert_ID)), fields ='{"_id": false,"expert_decision": true}') == "Include") {
      tagList(
        selectInput("q1",
                    "Study design",
                    choices = c("","case series","cross sectional survey","case control","cohort","non randomised intervention study","RCT","other"),
                    selected = db$find(sprintf(
                    '{"ID" : %s}', input$expert_ID
                    ),
                    fields = '{"_id": false,"q1": true}'))
      )
    }}
    })
    
    output$q2 <- renderUI({
      input$expert_decision
      if (nrow(data.frame(db$find('{"initial_decision": "Include"}', fields = '{"_id": false,"ID": true}'))) > 0) {
        
        if (db$find(query = sprintf('{"ID" : %s}',as.numeric(input$expert_ID)), fields ='{"_id": false,"expert_decision": true}') == "Include") {
          
      tagList(
        textInput("q2", "If other, please specify:", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                          fields = '{"_id": false,"q2": true}'))
      )}}
    })

    
    output$q3 <- renderUI({
      input$expert_decision
      
      if (nrow(data.frame(db$find('{"initial_decision": "Include"}', fields = '{"_id": false,"ID": true}'))) > 0) {
        
        if (db$find(query = sprintf('{"ID" : %s}',as.numeric(input$expert_ID)), fields ='{"_id": false,"expert_decision": true}') == "Include") {
          
      tagList(
        textInput("q3", "Setting (country/region)", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                          fields = '{"_id": false,"q3": true}'))
      )}}
    })
    
    output$q4 <- renderUI({
      input$expert_decision
      
      if (nrow(data.frame(db$find('{"initial_decision": "Include"}', fields = '{"_id": false,"ID": true}'))) > 0) {
        
        if (db$find(query = sprintf('{"ID" : %s}',as.numeric(input$expert_ID)), fields ='{"_id": false,"expert_decision": true}') == "Include") {
          
      tagList(
        textAreaInput2("q4", "Population studied", width = "100%", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                                    fields = '{"_id": false,"q4": true}'))
      )}}
    })
    
    output$q5 <- renderUI({
      input$expert_decision
      
      if (nrow(data.frame(db$find('{"initial_decision": "Include"}', fields = '{"_id": false,"ID": true}'))) > 0) {
        
        if (db$find(query = sprintf('{"ID" : %s}',as.numeric(input$expert_ID)), fields ='{"_id": false,"expert_decision": true}') == "Include") {
          
      tagList(
        textAreaInput2("q5", "Outcome(s) investigated",width = "100%", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                              fields = '{"_id": false,"q5": true}'))
      )}}
    })
    
    output$q6 <- renderUI({
      input$expert_decision
      
      if (nrow(data.frame(db$find('{"initial_decision": "Include"}', fields = '{"_id": false,"ID": true}'))) > 0) {
        
        if (db$find(query = sprintf('{"ID" : %s}',as.numeric(input$expert_ID)), fields ='{"_id": false,"expert_decision": true}') == "Include") {
          
      tagList(
        textAreaInput2("q6", "Sample size (describe)",width = "100%", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                                fields = '{"_id": false,"q6": true}'))
      )}}
    })
    
    output$q7 <- renderUI({
      input$expert_decision
      
      if (nrow(data.frame(db$find('{"initial_decision": "Include"}', fields = '{"_id": false,"ID": true}'))) > 0) {
        
        if (db$find(query = sprintf('{"ID" : %s}',as.numeric(input$expert_ID)), fields ='{"_id": false,"expert_decision": true}') == "Include") {
          
      tagList(
        textAreaInput2("q7", "Key findings",width = "100%", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                                  fields = '{"_id": false,"q7": true}'))
      )}}
    })
    
    output$q8 <- renderUI({
      input$expert_decision
      
      if (nrow(data.frame(db$find('{"initial_decision": "Include"}', fields = '{"_id": false,"ID": true}'))) > 0) {
        
        if (db$find(query = sprintf('{"ID" : %s}',as.numeric(input$expert_ID)), fields ='{"_id": false,"expert_decision": true}') == "Include") {
          
      tagList(
        textAreaInput2("q8", "Strengths",width = "100%", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                                  fields = '{"_id": false,"q8": true}'))
      )}}
    })
    
    output$q9 <- renderUI({
      input$expert_decision
      
      if (nrow(data.frame(db$find('{"initial_decision": "Include"}', fields = '{"_id": false,"ID": true}'))) > 0) {
        
        if (db$find(query = sprintf('{"ID" : %s}',as.numeric(input$expert_ID)), fields ='{"_id": false,"expert_decision": true}') == "Include") {
          
      tagList(
        textAreaInput2("q9", "Limitations",width = "100%", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                                  fields = '{"_id": false,"q9": true}')),
      )}}
    })
    
    output$q10 <- renderUI({
      input$expert_decision
      
      if (nrow(data.frame(db$find('{"initial_decision": "Include"}', fields = '{"_id": false,"ID": true}'))) > 0) {
        
        if (db$find(query = sprintf('{"ID" : %s}',as.numeric(input$expert_ID)), fields ='{"_id": false,"expert_decision": true}') == "Include") {
          
      tagList(
        textAreaInput2("q10", "Implications for practice/policy",width = "100%", value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                                  fields = '{"_id": false,"q10": true}'))
      )}}
    })
    
    output$q11 <- renderUI({
      input$expert_decision
      
      if (nrow(data.frame(db$find('{"initial_decision": "Include"}', fields = '{"_id": false,"ID": true}'))) > 0) {
        
        if (db$find(query = sprintf('{"ID" : %s}',as.numeric(input$expert_ID)), fields ='{"_id": false,"expert_decision": true}') == "Include") {
          
      tagList(
        textAreaInput2("q11", "Implications for research",width = '100%', value = db$find(sprintf('{"ID" : %s}',as.numeric(input$expert_ID)),
                                                                             fields = '{"_id": false,"q11": true}'))
      )
      }}
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
