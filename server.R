# server.R
library(shiny)
library(dygraphs)
library(parallel)
library(zoo)
#library(quantmod)
#source("helpers.R")

read.cols=rep("NULL",23)
read.cols[c(2,3,7,9)]=NA
read.cols[3]="character"
options(digits.secs = 3)

shinyServer(function(input, output) {
    dataInput = reactive({
        output$plotHelp = renderText("")
        progress <- shiny::Progress$new()
        on.exit(progress$close())
        symbol=toupper(input$symb)
        if (symbol=="") {
            return(NULL)
        }
        progress$set(message = "Downloading Data", value = 0.3)
        files=sapply(1:25, function(s,t){sprintf("Data/%s/201004%02d",s,t)}, s=symbol)
        allData=do.call(rbind, mclapply(files, function(f) {
            symbol=strsplit(f,'/')[[1]][2]
            t=strsplit(f,'/')[[1]][3]
            if (!file.exists(f)) {
                if (!dir.exists(sprintf("Data/%s",symbol))) {
                    dir.create(sprintf("Data/%s",symbol))
                }
                system(sprintf("scp -q -r osg:/home/bill10/stash/public/Stock/%s.KP/e%s Data/%s/%s",t,symbol,symbol,t))
            }
            if (file.exists(f)) {
                #data=read.zoo(f, sep=',', header=FALSE, colClasses=read.cols, index.column = 1:2, format = "%Y%m%d %H%M%OS", tz="")
                #strptime(paste0(data[,1],data[,2]), format="%Y%m%d%H%M%OS")
                data=read.csv(f, header=FALSE, colClasses=read.cols)
                names(data)=c('Date','Time','Price','Size')
            }
            else {
                data=NULL
            }
            return(data)},
            mc.cores=10)
        )
        progress$set(message = "Loading Data", value = 0.6)
        if (is.null(allData)) {
            return(NULL)
        }
        read.zoo(allData,index.column = 1:2, format = "%Y%m%d %H%M%OS", tz="")
    })
    
    output$plot <- renderDygraph({
        input$action
        data=isolate(dataInput())
        progress <- shiny::Progress$new()
        on.exit(progress$close())
        progress$set(message = "Ploting", value = 0.9)
        if (!is.null(data)) {
            graph=dygraph(data$Price, ylab = "Price") %>% dyRangeSelector() #%>% dyOptions(logscale=input$log)
            output$plotHelp = renderText("Drag to zoom in and double click to reset.")
        }
        else {
            graph=NULL
        }
        progress$set(message = "Rendering in Browser", value = 1)
        return(graph)
    })
})