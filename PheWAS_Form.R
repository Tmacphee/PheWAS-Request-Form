library(shiny)
library(dplyr)
library(dbplyr)
library(DBI)
library(shinydashboard)
library(dslabs)
library(jsonlite)
library(plumber)
library(shinyjs)

#------------------------------------------------------------------------------#

ui <- dashboardPage(
  dashboardHeader(title = 'UK Biobank'),
  dashboardSidebar(
    sidebarMenu(
      id = 'tabs',
      menuItem('PheWAS Regression Results', tabName = 'Results', icon = icon('table')),
      menuItem('Target Request', tabName = 'Request', icon = icon('file-alt'))
    )
  ),
  dashboardBody(
    tabItems(
    # First Tab Content
      tabItem(tabName = 'Results',
        wellPanel(
          fluidRow(column(6, h1('PheWAS Regression Results'))),
          br(),
          fluidRow(
            column(3, selectInput('target', label = 'Target:',
                                  choices = gapminder$country, selected = NULL)), # The choices from this widget will need to be pulled from list of already processed targets, database_name$targets will be the choices
            column(3, numericInput('num', label = 'Minimum -log10(p):', value = 3, min = 3, max = 20, step = 1)),
            column(3, selectInput('regression', label = 'Regression:', choices = list('Linear', 'Logistic'))),
            tags$head(
              tags$style(HTML('#query{background-color:skyblue}'))
            ),
            column(2, actionButton('query', label = 'Query Results'))),
          tags$h5('If target not found, click:'),
          actionButton('click', label = 'Here'),
          h3(textOutput('username')),
          hr(),
          DT::dataTableOutput('targetTable_1')
        )
      ),
      
      tabItem(tabName = 'Request',
      # Tab 2 Content
        wellPanel(
          useShinyjs(),
          h1('UKB Target Request'),
          fluidRow(
            column(7, textInput('name', label = 'Name'))
            ),
          fluidRow(
            column(7, textInput('email', label = 'Email'))
            ),
          fluidRow(
            column(7, dateInput('date', label = 'Date', value = Sys.Date()))
            ),
          checkboxGroupInput('run', label = 'Run on:', choices = c('SNP Chip', 'Exomes'), selected = 'SNP Chip'),
          # In the server funtion, use observeEvent(input$run, shinyjs::disable(choices))
          hr(),
          h3('Target Selection'),
          br(),
          h5('Manually enter multiple targets in the textbox or select targets using the dropdown'),
          fluidRow(
            column(7, textInput('man_targs', label = 'Enter Targets', placeholder = 'csv format'))
            # Will need some sort of check button to see if the targets are available, the '+' button in Kartiks app
          ),
          fluidRow(
            column(7, selectInput('sel_target', label = 'Select Target', choices = gapminder$country, selected = NULL))
            ),
          # use updateSelectInput in the server function to remove choices that have already been selected
          DT::dataTableOutput('targetTable_2'),
          tags$head(
            tags$style(HTML('#submit{background-color:skyblue}'))
          ),
          actionButton('submit', label = 'Submit', icon('paper-plane'))
        )
      )
    )
  )
)

#-------------------------------------------------------------------------------#

server <- function(input, output, session) {
  
  output$username <- reactive({
    session$user
  })
  
# Tab switch if target not found
  observeEvent(input$click, {
    updateTabItems(session, 'tabs', 'Request')
  })
  
# Selecting Linear/Logistic Regression Dataset
  # dataset <- input$regression
      # input$regression will need to point to one of two datasets. This selected value will be used
      # in the querying and rendering of targetTable_1
  
  
# Regression Results DataTable
  df <- eventReactive(input$query, {
    gapminder %>% filter(country == input$target 
                         & fertility > input$num 
                         & population != input$regression) %>% head(150)
  })
  output$targetTable_1 <- DT::renderDataTable({
    df()
  })
  
# Locking date and 'run on' inputs
  shinyjs::disable('date')
  shinyjs::disable('run')

# Build selection list based upon selected targets, query, display records
  observeEvent(input$sel_target, {
    output$targetTable_2 <- DT::renderDataTable({
      gapminder %>% filter(country == input$target) %>% head(150)
    })
  })
}

# Connecting to Athena
  # accessKeyId <- "your access key id..."
  # secretKey <- "your secret key..."
  # 
  # jdbcConnection <- dbConnect(
  #   drv, 
  #   'jdbc:awsathena://athena.us-east-1.amazonaws.com:443',
  #   s3_staging_dir="s3://mybucket",
  #   user=accessKeyId,
  #   password=secretKey
  # )

#-------------------------------------------------------------------------------#

shinyApp(ui = ui, server = server)