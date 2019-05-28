library(shiny)
library(dplyr)
library(dbplyr)
library(DBI)
library(shinydashboard)
library(dslabs)
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
                h1('PheWAS Regression Results'),
                br(),
                fluidRow(
                  column(3, selectInput('target', label = 'Target:',
                                        choices = gapminder$country, selected = NULL)), # The choices from this widget will need to be pulled from list of already processed targets, database_name$targets will be the choices
                  column(3, numericInput('num', label = 'Minimum -log10(p):', value = 3, min = 3, max = 20, step = 1)),
                  column(3, selectInput('regression', label = 'Regression:', choices = list('Linear', 'Logistic'))),
                  column(2, actionButton('query', label = 'Query Results')),
                  fluidRow(),
                  fluidRow(
                    column(2, h5('If target not found, click ')),
                    column(2, actionButton('click', label = 'Here'))),
                  hr(),
                  DT::dataTableOutput('targetTable_1')
                )
              )
      ),
      
      tabItem(tabName = 'Request',
              # Tab 2 Content
              wellPanel(
                h1('UKB Target Request'),
                textInput('name', label = 'Name'),
                textInput('email', label = 'Email'),
                dateInput('date', label = 'Date', value = Sys.Date()),
                checkboxGroupInput('run', label = 'Run on:', choices = c('SNP Chip', 'Exomes'), selected = 1),
                # In the server funtion, use observeEvent(input$run, shinyjs::disable(choices))
                hr(),
                h3('Target Selection'),
                br(),
                h5('Manually enter multiple targets in the textbox or select targets using the dropdown'),
                fluidRow(
                  textInput('man_targs', label = 'Enter Targets', placeholder = 'csv format')
                  # Will need some sort of check button to see if the targets are available, the '+' button in Kartiks app
                ),
                selectInput('sel_target', label = 'Select Target', choices = gapminder$country, selected = NULL),
                # use updateSelectInput in the server function to remove choices that have already been selected
                DT::dataTableOutput('targetTable_2'),
                actionButton('submit', label = 'Submit')
              )
      )
    )
  )
)

# Need to isolate the input functions and delay reactivity until the 'Query Results' button is selected
# check back with the shiny tutorial to determine syntax for isolate() function

# add Takeda image to the form - img(), but where to add?

# I assume we will not be loading the db through the shinyapp, rather connecting to athena
# or wherever the data is being stored

# For the querying service, use dplyr for filtering and selecting
# take an input choice and fill the query with that input

#-------------------------------------------------------------------------------#

server <- function(input, output) {
  
  # Tab switch if target not found
  observeEvent(input$click, {
    newTab <- switch(input$tabs,
                     'Request' = 'Results')
    updateTabItems('tabs', newTab)
  })
  
  # Regression Results DataTable
  observeEvent(input$query, {
    output$targetTable_1 <- DT::renderDataTable({
      gapminder %>% filter(country == input$target 
                           & population > input$num 
                           & fertility != input$regression)
    })
  })
  
  # Target Selection DataTable
  observeEvent(input$submit, {
    output$targetTable_2 <- DT::renderDataTable({
      gapminder %>% filter(country == input$sel_target)
    })
  })
}

#-------------------------------------------------------------------------------#

shinyApp(ui = ui, server = server)