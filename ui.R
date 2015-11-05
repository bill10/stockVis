library(shiny)
library(dygraphs)

shinyUI(fluidPage(
    titlePanel("Stock Vis"),
    
    sidebarLayout(
        sidebarPanel(
            helpText("Type a stock to examine. 
                     It will take some time as information will be downloaded from server."),
            
            div(style="display:inline-block",textInput("symb", "Symbol", "")),
            div(style="display:inline-block",actionButton("action", label = "GO")),
            br(),
            width=2
            #radioButtons("radio", label="",
                         #choices = list("Price" = "Price", "Size" = "Size"), 
                         #selected = "Price")
            #checkboxInput("log", "Plot y axis on log scale", value = FALSE),
            #checkboxInput("adjust", "Adjust prices for inflation", value = FALSE)
            ),
        
        mainPanel(dygraphOutput("plot"),
                  helpText(textOutput("plotHelp"), align='center'))
    )
))
