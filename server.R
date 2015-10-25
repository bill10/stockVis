# server.R
library(dygraphs)
library(quantmod)
source("helpers.R")

shinyServer(function(input, output) {
    dataInput = reactive({
        symbol=toupper(input$symb)
        f = sprintf("e%s/201004%02d",symbol,1)
        if (!file.exists(f)) {
            if (!dir.exists(sprintf("e%s",symbol))) {
                dir.create(sprintf("e%s",symbol))
            }
            # download f
        } else {
            
        }
    })
    
    output$plot <- renderDygraph({
        dygraph(dataInput()[,4]) %>% dyRangeSelector() %>% dyOptions(logscale=input$log)
    })
})