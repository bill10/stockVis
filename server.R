# server.R
library(shiny)
library(dygraphs)
#library(quantmod)
#source("helpers.R")

read.cols=rep("NULL",23)
read.cols[c(2,3,7,9)]=NA
read.cols[3]="character"
options(digits.secs = 3)

shinyServer(function(input, output) {
    dataInput = reactive({
        symbol=toupper(input$symb)
        t=1
        f = sprintf("Data/%s/201004%02d",symbol,t)
        if (!file.exists(f)) {
            if (!dir.exists(sprintf("Data/%s",symbol))) {
                dir.create(sprintf("Data/%s",symbol))
            }
            system(sprintf("scp -q -r osg:/home/bill10/stash/public/Stock/201004%02d.KP/e%s Data/%s/201004%02d",t,symbol,symbol,t))
        }
        if (file.exists(f)) {
            data=read.zoo(f, sep=',', header=FALSE, colClasses=read.cols, index.column = 1:2, format = "%Y%m%d %H%M%OS", tz="")
            #strptime(paste0(data[,1],data[,2]), format="%Y%m%d%H%M%OS")
            names(data)=c('Price','Size')
        }
        else {
            data=NULL
        }
        return(data)
    })
    
    output$plot <- renderDygraph({
        data=dataInput()
        if (!is.null(data)) {
            dygraph(dataInput()$Price) %>% dyRangeSelector() %>% dyOptions(logscale=input$log)
        }
    })
})