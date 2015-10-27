library(shiny)
library(dygraphs)

shinyUI(fluidPage(
    titlePanel("Stock Vis"),
    
    sidebarLayout(
        sidebarPanel(
            helpText("Type a stock to examine. 
                     Information will be downloaded from server."),
            
            textInput("symb", "Symbol", ""),
            helpText("After plot is loaded, drag to zoom in and double click to reset."),
            br()
            
            #checkboxInput("log", "Plot y axis on log scale", value = FALSE),
            
            #checkboxInput("adjust", "Adjust prices for inflation", value = FALSE)
            ),
        
        mainPanel(dygraphOutput("plot"), textOutput("statusIndicator"))
        
    )
))
