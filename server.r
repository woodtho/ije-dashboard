#setwd('F:/IJE/code/shiny/')
library(shiny)
library(dplyr)
library(leaflet)
library(scales)
library(ggplot2)
#library(highcharter)
options(scipen = 999)

server<-function(input, output){
  
  # define filtered dataset
  #IJE_table1_filted<- reactive({
  #    IJE_table1 %>%
  #    filter(year%in% input$YearInput,
  #           source %in% input$SourceInput,
  #           gender %in% input$GenderInput,
  #           type %in% input$TypeInput)
  #})
  
  
  #####################PR Map
  mapfilter <- reactive({
    table_1_2 %>%
      filter(year%in% input$YearInput,
             source %in% input$SourceInput,
             gender %in% input$GenderInput,
             type %in% input$TypeInput,
             income_source %in% input$IncomeSource)
  })
    

  output$mainmap <- renderPlotly({
    
    mapdat <- simple_pr_shapefile %>%
      inner_join(mapfilter(), by='PRUID') %>%
      
      mutate(mapformat=sf::st_transform(
        simple_pr_shapefile$geometry,
        crs= "+proj=laea +lat_0=56.1304 +lon_0=-86.3468 +ellps=WGS84 +units=m +no_defs "))
    
    ## set color scheme for concept (employees in blue, income in red)
    if(input$SeriesInput == "Employees"){
      seriesvar <- mapdat$count
      lowgrad <- '#f1eef6'
      highgrad <- '#045a8d'
      # seriestitle <- 'Number of Inter-Jurisdictional Employees'
      # 
      # pal_count_PR <- createClasses(mapdat$count , "Blues", "transparent", 5)
      # 
      # geo_labels_PR <- sprintf(
      #   "<strong>%s (Employees):  %s </strong>",
      #   mapdat$province, format(mapdat$count, big.mark = ",")) %>%
      #   lapply(htmltools::HTML) # add labels 
      
    } else if(input$SeriesInput == "Income"){
      seriesvar <- mapdat$income
      lowgrad <- '#fef0d9'
      highgrad <- '#b30000'
      # seriestitle <- 'Income of Inter-Jurisdictional Employees'
      # 
      # pal_count_PR <- createClasses(mapdat$income, "Reds", "transparent", 5)
      # 
      # geo_labels_PR <- sprintf(
      #   "<strong>%s (Income): %s </strong>",
      #   mapdat$province, format(mapdat$income, big.mark = ",")) %>%
      #   lapply(htmltools::HTML) # add labels  
    }
    
    ggplotly(
      ggplot(mapdat %>% mutate(geometry=mapformat)) +
        geom_sf(aes(fill=log(seriesvar)/log(10),
                    text=sprintf("<b>%s</b><br>Employees: %s<br>Income: %s",
                                 province,
                                 format(count,big.mark=','),
                                 paste0('$',format(round(income/1000000,1),big.mark=','),' M'))),
                
                color="#444444",
                alpha=0.75) + theme_bw() +
        
        scale_fill_gradient(low=lowgrad,
                            high=highgrad,
                            na.value='grey.50') +
        
        theme(panel.grid.major=element_blank(),panel.grid.minor=element_blank(),
              axis.title.x=element_blank(),axis.text.x=element_blank(),axis.ticks.x=element_blank(),
              axis.title.y=element_blank(),axis.text.y=element_blank(),axis.ticks.y=element_blank(),
              
              legend.position='none'),
      
      tooltip='text') %>%
      style(hoveron='all')
    # 
    # ggplot() + geom_sf(data=mapdat$mapformat,
    #                    fill=pal_count_PR$pal(seriesvar),
    #                    group='count',
    #                    
    #                    color='#444444',
    #                    alpha=0.75) + theme_bw() + 
    #   
    #   theme(panel.grid.major=element_blank(),panel.grid.minor=element_blank(),
    #         axis.title.x=element_blank(),axis.text.x=element_blank(),axis.ticks.x=element_blank(),
    #         axis.title.y=element_blank(),axis.text.y=element_blank(),axis.ticks.y=element_blank())
    
    
  })
  
  #####
  # output$info <- renderText({
  #   paste0("x=", input$map_click$x, "\ny=", input$map_click$y)
  # })
  
  
  ## determine province of click
  # output$clickpoint <- reactive({st_as_sf(data.frame(x=input$mapclick$x,
  #                                                    y=input$mapclick$y),
  #                                         coords=c('x','y'),crs=4326)})
  
  # output$clickprov <- renderText(
  #   reactive({
  #     placevector <- apply(X=simple_pr_shapefile$geometry,
  #                          MARGIN=1,
  #                          FUN=function(x) st_contains(x,
  #                                                      st_as_sf(data.frame(x=input$mapclick$x,
  #                                                                          y=input$mapclick$y),
  #                                                               coords=c('x','y'),crs=4326),
  #                                                      sparse=F)[1,1])
  #     # 
  #     # simple_pr_shapefile %>%
  #     #   
  #     #   mutate(inprov=st_contains(geometry,
  #     #                             st_as_sf(data.frame(x=input$mapclick$x,
  #     #                                                 y=input$mapclick$y),
  #     #                                      coords=c('x','y'),crs=4326),
  #     #                             sparse=F)[1,1]) %>%
  #     #   
  #     #   mutate(inprov=apply(X=simple_pr_shapefile,
  #     #                       MARGIN=1,
  #     #                       FUN=function(x) st_contains(x[3]$geometry,
  #     #                                                   st_as_sf(data.frame(x=input$mapclick$x,
  #     #                                                                       y=input$mapclick$y),
  #     #                                                            coords=c('x','y'),crs=4326),
  #     #                                                   sparse=F)[1,1])) %>%
  #     #   filter(inprov) %>%
  #     #   pull(PRENAME)
  #   })
  # )
  # 
  
  # output$info <- renderText({
  #   paste0("x=", input$map_click$x, "\ny=", input$map_click$y)
  # })
  
  
  
  
  
  
  
  
  ##############################################################################################
  output$PRcount <- renderLeaflet({
    
    #####
    PRcount <- leaflet(table_1_2)#%>%
    # addProviderTiles(providers$OpenStreetMap.BlackAndWhite)
    
    #filter;
    IJE_table1_filted <-
      inner_join(simple_pr_shapefile, table_1_2 %>%filter(year%in% input$YearInput,
                                                          source %in% input$SourceInput,
                                                          gender %in% input$GenderInput,
                                                          type %in% input$TypeInput,
                                                          income_source %in% input$IncomeSource
      ),by = c("PRUID" = "PRUID")) 
    
    #color;
    if(input$SeriesInput == "Employees"){
      seriesvar <- IJE_table1_filted$count
      seriestitle <- 'Number of Inter-Jurisdictional Employees'
      
      pal_count_PR <- createClasses(IJE_table1_filted$count , "Blues", "transparent", 5)
      
      geo_labels_PR <- sprintf(
        "<strong>%s (Employees):  %s </strong>",
        IJE_table1_filted$province, format(IJE_table1_filted$count, big.mark = ",")) %>%
        lapply(htmltools::HTML) # add labels 
      
    } else if(input$SeriesInput == "Income"){
      
      seriesvar <- IJE_table1_filted$income
      seriestitle <- 'Income of Inter-Jurisdictional Employees'
      
      pal_count_PR <- createClasses(IJE_table1_filted$income, "Reds", "transparent", 5)
      
      geo_labels_PR <- sprintf(
        "<strong>%s (Income): %s </strong>",
        IJE_table1_filted$province, format(IJE_table1_filted$income, big.mark = ",")) %>%
        lapply(htmltools::HTML) # add labels  
    }
    
    # geo_labels_PR <- sprintf(
    #   "<strong>%s (Employees):  %s </strong>",
    #   IJE_table1_filted$province, format(IJE_table1_filted$count, big.mark = ",")) %>%
    #   lapply(htmltools::HTML) # add labels 
    # 
    # labels_inc <- sprintf(
    #   "<strong>%s (Income): %s </strong>",
    #   IJE_table1_filted$province, format(IJE_table1_filted$income, big.mark = ",")) %>%
    #   lapply(htmltools::HTML) # add labels  
    
    #####
    PRcount %>%
      addPolygons( data = IJE_table1_filted,stroke = TRUE, color = "#444444", weight = 1, smoothFactor = 0.5,
                   opacity = 1.0, fillOpacity = 0.5,fillColor = pal_count_PR$pal(seriesvar),group = "count",
                   highlightOptions = highlightOptions(color = "white", weight = 2,
                                                       bringToFront = FALSE),
                   label = geo_labels_PR,
                   labelOptions = labelOptions(
                     style = list(padding = "3px 8px"),
                     textsize = "13px",
                     direction = "auto"),              
                   popup =paste( '<B>', IJE_table1_filted$province, '</B>', "<br>",
                                 "Number of Employees: ", format(IJE_table1_filted$count, big.mark = ","), "<br>",
                                 "Income: ", format(IJE_table1_filted$income, big.mark = "," ), "<br>")
      )%>% 
      # addCircles(lng = IJE_table1_filted$lon, lat  = IJE_table1_filted$lat, weight = 2, radius = sqrt(IJE_table1_filted$income)*5,opacity = 1.0, fillOpacity = 0.5, fillColor = "transparent",
      #            color="red", label = labels_inc, highlightOptions = highlightOptions(color = "white", weight = 3,
      #                                                                                 bringToFront = TRUE), group="Income")%>%
      addLegend(position ="topright", pal = pal_count_PR$pal, values = seriesvar,
                opacity = 1, title = seriestitle, na.label = "No Data")%>%
      # addLayersControl( overlayGroups = c("Income"),
      #                   options = layersControlOptions(collapsed = TRUE, autoZIndex=TRUE)) %>%
      addScaleBar(position = "bottomleft", options = scaleBarOptions(imperial = FALSE)) 
    
  })
  
  ## reactive based on point clicked in map

  # output$clickpoint <- reactive({st_as_sf(data.frame(x=input$PRcount_shape_click[[4]],
  #                                                    y=input$PRcount_shape_click[[5]]),
  #                        coords=c('x','y'),crs=4326)})
  # 
  # output$clickprov <- reactive({
  #   simple_pr_shapefile %>%
  #     mutate(inprov=apply(X=simple_pr_shapefile,MARGIN=1,
  #                         FUN=function(x) st_contains(x[3]$geometry,output$clickpoint,sparse=F)[1,1])) %>%
  #     filter(inprov) %>%
  #     pull(PRENAME) %>%
  #     renderText()
  # })
  # 
  # output$point_lat <- renderText(input$PRcount_shape_click[[4]])
  # output$point_lon <- renderText(input$PRcount_shape_click[[5]])
  
  #PR barplot
  # output$PRbar <-renderPlot({
  #   IJE_table1_filted <-
  #     table_1_2 %>%
  #     filter(year%in% input$YearInput,
  #            source %in% input$SourceInput,
  #            gender %in% input$GenderInput,
  #            type %in% input$TypeInput,
  #            income_source %in% input$IncomeSource
  #     )
  #   
  #   ggplot(IJE_table1_filted,aes(x = prn )) +
  #     #scale_x_discrete(limits=c('NL','PE','NS','NB','QC','ON','MB','SK','AB','BC','YT','NT','NU'))+
  #     #geom_bar(aes(y = count, colour = "Employee"),stat = 'identity')
  #     geom_bar(mapping = aes(y = count, colour = "Employee"),stat = 'identity', fill="steelblue3")+
  #     #add second dimension
  #     geom_line(mapping = aes( y = income/35000,  colour = "Income"),group = 1, size = 2)+
  #     #add second y axis
  #     scale_y_continuous(name = "Number of Employee", labels = function(c){paste0(format(c, big.mark = ","))} ,
  #                        sec.axis = sec_axis(~.*35000, name="Aggregate T4 Earnings",
  #                                            labels = function(b){paste0(format(b, big.mark = ","))}))+
  #     #define colour
  #     scale_colour_manual(values = c("steelblue3", "firebrick3")) +
  #     labs(y = "Number of Employee", x = "Province", colour = "Label") +
  #     # title
  #     ggtitle ("Number of Inter-Jurisdictional Employees and Their T4 Earnings By Province")+
  #     #label location
  #     theme(legend.position = "none", 
  #           axis.title.y= element_text(color = "steelblue3", size = 14),
  #           axis.title.y.right = element_text(color = "firebrick3", size = 14), 
  #           plot.title = element_text(hjust=0.5, size=16, face="bold"))
  #   
  # })
  # 
  #National Level download 
  
  National_filted<- reactive({
    table_1_2 %>%
      filter(year%in% input$YearInput,
             source %in% input$SourceInput,
             gender %in% input$GenderInput,
             type %in% input$TypeInput,
             income_source %in% input$IncomeSource
      )})
  
  
  tableN_down <- reactive ({
    switch( input$tableN,
            "Filtered National Table" = National_filted(),
            "Full National Table" = table_1_2
    )
  })
  
  
  # Downloadable excel file of selected table
  output$downloadNtable <- downloadHandler(
    filename = function(){
      paste(input$tableN, ".csv", sep = "")
      #paste(input$table)
    },
    content = function(file){
      write.csv(tableN_down(), file, row.names = FALSE)
      
    },
    contentType = "csv"
  )
  
  
  
  
  
  
  ###################Comparison (THIS SECTION APPEARS TO BE DEPRECATED)-----
  #compare count
  # output$PRcomp <-renderPlot({
  #   comp_filted <-
  #     table_1_2 %>%
  #     filter(province %in% c(input$CompInput1, input$CompInput2),
  #            year>= input$YRComp[1],
  #            year<= input$YRComp[2],
  #            source %in% input$DSComp,
  #            type %in% input$TypeComp,
  #            gender %in% input$GDComp,
  #            income_source %in% input$InComp
  #     )
  #   xrange<- range(comp_filted$year)
  #   yrange<-range(comp_filted$count)
  #   plot(xrange,yrange, type="n", xlab="", ylab="Inter-jurisdictional Employment (Number)",
  #        main=paste("The Comparison Between", input$CompInput1, "and ", input$CompInput2, "(Employee)"))
  #   trend_filted_1 <-comp_filted %>%filter(province %in% input$CompInput1)
  #   lines(trend_filted_1$year,trend_filted_1$count,col="aquamarine4",type="o", lwd=3)
  #   trend_filted_2 <-comp_filted %>%filter(province %in% input$CompInput2)
  #   lines(trend_filted_2$year,trend_filted_2$count,col="yellow3",type="o", lwd=3)
  #   legend(input$YRComp[2]-5.5, min(comp_filted$count)+max(comp_filted$count)/5,c(input$CompInput1,input$CompInput2),
  #          col=c('aquamarine4','yellow3'), pch=15,ncol=1,bty="n",cex=1)
  #   
  # }) 
  # 
  # #compare Income
  # 
  # output$PRcomp_inc <-renderPlot({
  #   comp_filted <-
  #     table_1_2 %>%
  #     filter(province %in% c(input$CompInput1, input$CompInput2),
  #            year>= input$YRComp[1],
  #            year<= input$YRComp[2],
  #            source %in% input$DSComp,
  #            type %in% input$TypeComp,
  #            gender %in% input$GDComp,
  #            income_source %in% input$InComp
  #     )
  #   xrange<- range(comp_filted$year)
  #   yrange<-range(comp_filted$income)
  #   plot(xrange,yrange, type="n", xlab="", ylab="Income",
  #        main=paste("The Comparison Between", input$CompInput1, "and ", input$CompInput2 , "(Income)"))
  #   trend_filted_1 <-comp_filted %>%filter(province %in% input$CompInput1)
  #   lines(trend_filted_1$year,trend_filted_1$income,col="aquamarine4",type="o", lwd=3)
  #   trend_filted_2 <-comp_filted %>%filter(province %in% input$CompInput2)
  #   lines(trend_filted_2$year,trend_filted_2$income,col="yellow3",type="o", lwd=3)
  #   legend(input$YRComp[2]-5.5,min(comp_filted$income)+max(comp_filted$income)/5,c(input$CompInput1,input$CompInput2),
  #          col=c('aquamarine4','yellow3'), pch=15,ncol=1,bty="n",cex=1)
  #   
  # }) 
  # 
  # # filters:
  # IJE_count_filt1<- reactive({
  #   table_1_2[,c(-6,-10)] %>%
  #     filter(province %in% input$CompInput1,
  #            year>= input$YRComp[1],
  #            year<= input$YRComp[2],
  #            source %in% input$DSComp,
  #            type %in% input$TypeComp,
  #            gender %in% input$GDComp,
  #            income_source %in% input$InComp 
  #            
  #     )})
  # 
  # IJE_count_filt2<- reactive({
  #   table_1_2[,c(-6,-10)] %>%
  #     filter(province %in% input$CompInput2,
  #            year>= input$YRComp[1],
  #            year<= input$YRComp[2],
  #            source %in% input$DSComp,
  #            type %in% input$TypeComp,
  #            gender %in% input$GDComp,
  #            income_source %in% input$InComp
  #     )})
  # #table 1 in comparison.  
  # output$CompT1 <-DT::renderDataTable(
  #   datatable(IJE_count_filt1(),options= list(lengthMenu=c(input$YRComp[2]-input$YRComp[1]+1,2*(input$YRComp[2]-input$YRComp[1]+1),3*(input$YRComp[2]-input$YRComp[1]+1)), dom='ft',rownames=FALSE ))%>%
  #     formatStyle(c(1-6), color='black')
  #   
  # )
  # #table 2 in comparison.  
  # output$CompT2 <-DT::renderDataTable(
  #   datatable(IJE_count_filt2(),options= list(lengthMenu=c(input$YRComp[2]-input$YRComp[1]+1,2*(input$YRComp[2]-input$YRComp[1]+1),3*(input$YRComp[2]-input$YRComp[1]+1)), dom='ft',rownames=FALSE))%>%
  #     formatStyle(c(1-6), color='black')
  #   
  # )
  # 
  
  
  
  
   
  ################### Jurisdiction Trendplot-----
  
  trend_filted<- reactive({
    table_1_2 %>%
      filter(province %in% input$ProvinceInput,
             year>= input$YRInput[1],
             year<= input$YRInput[2],
             source %in% input$DSInput,
             gender %in% input$GDInput,
             type != "Resident",
             case_when(type == "Incoming" ~ income_source == "Inside the Jurisdiction", T ~ income_source == "Outside the Jurisdiction")
      )})
  
  #count trend
  output$PRtrend <-renderPlot({
    ggplot(trend_filted(), aes(x=year, y = count, group=type, color=type)) + 
      geom_line(size=1.2)+
      geom_point(size=3)+
      labs(y = "Number of IJEs", x = "Year")+
      scale_colour_manual(name='Role',values = c("aquamarine4", "yellow3"))+
      scale_x_continuous(breaks=seq(2002,2017,2))+
      scale_y_continuous(labels = function(c){paste0(format(c, big.mark = ","))})+
      ggtitle(paste("Incoming vs. Outgoing Inter-Jurisdictional Employment"))+
      theme(plot.title = element_text(hjust=0.5, size=16, face = "bold"),
            axis.title = element_text(size=12))
  }) 
  
  
  
  #Income trend
  output$PRInctrend <-renderPlot({
    ggplot(trend_filted(), aes(x=year, y = income, group=type, color=type)) + 
      geom_line(size=1.2)+
      geom_point(size=3)+
      labs(y = "Aggregate T4 Earnings ($)", x = "Year")+
      scale_colour_manual(name='Role',values = c("cyan3", "darkorange2"))+
      scale_x_continuous(breaks=seq(2002,2017,2))+
      scale_y_continuous(labels = function(c){paste0(format(c, big.mark = ","))})+
      ggtitle("Aggregate T4 Earnings for Inter-Jurisdictional Employees")+
      theme(plot.title = element_text(hjust=0.5, size=16, face = "bold"),
            axis.title = element_text(size=12))
  }) 
  
  
  
  
  #Income receiver and Income Sender trend
  output$Income_receiver <-renderPlot({
    IJE_table1_receive <-
      table_1_2 %>%
      filter(province %in% input$ProvinceInput,
             year>= input$YRInput[1],
             year<= input$YRInput[2],
             source %in% input$DSInput,
             gender %in% input$GDInput,
             type == "Incoming",
             income_source %in% "Inside the Jurisdiction"
      ) 
    
    ggplot(IJE_table1_receive,aes(x = year )) +
      geom_bar(mapping = aes(y = count, colour = "Employee"),stat = 'identity', fill= "aquamarine4")+
      #add second dimension
      geom_line(mapping = aes( y = income/35000),group = 1, size = 2,  colour = "cyan3")+
      scale_x_continuous(breaks=seq(2002,2017,2))+
      
      #add second y axis
      scale_y_continuous(name = "Incoming IJE", 
                         labels = function(c){paste0(format(c, big.mark = ","))} ,
                         sec.axis = sec_axis(~.*35000, name="Aggregate T4 Earnings",
                                             labels = function(b){paste0(format(b, big.mark = ","))}))+
      xlab('Year') +
      #define colour
      scale_colour_manual(values = c("aquamarine4", "cyan3")) +
      #label location
      theme(legend.position = "none", 
            axis.title.y= element_text(color = "aquamarine4", size=12),
            axis.title.y.right = element_text(color = "cyan3", size=12), 
            plot.title = element_text(hjust=0.5, size=16, face="bold"),
            axis.title = element_text(size=12))+
      ggtitle('Incoming Inter-Jurisdictional Employees and Aggregate T4 Earnings')
    
  }) 
  
  
  output$Income_sender <-renderPlot({
    IJE_table1_receive <-
      table_1_2 %>%
      filter(province %in% input$ProvinceInput,
             year>= input$YRInput[1],
             year<= input$YRInput[2],
             source %in% input$DSInput,
             gender %in% input$GDInput,
             type == "Outgoing",
             income_source %in% "Outside the Jurisdiction"
      ) 
    
    ggplot(IJE_table1_receive,aes(x = year )) +
      geom_bar(mapping = aes(y = count, colour = "Employee"),stat = 'identity', fill = "yellow3")+
      #add second dimension
      geom_line(mapping = aes( y = income/35000),group = 1, size = 2,  colour = "darkorange2")+
      scale_x_continuous(breaks=seq(2002,2017,2))+
      
      #add second y axis
      scale_y_continuous(name = "Outgoing IJE", 
                         labels = function(c){paste0(format(c, big.mark = ","))} ,
                         sec.axis = sec_axis(~.*35000, name="Aggregate T4 Earnings",                                                                                 
                                             labels = function(b){paste0(format(b, big.mark = ","))}))+
      xlab('Year') +
      scale_colour_manual(values = c("yellow3", "darkorange2")) +
      #label location
      theme( legend.position = "none", 
             axis.title.y= element_text(color = "yellow3", size=12),
             axis.title.y.right = element_text(color = "darkorange2"), 
             plot.title = element_text(hjust=0.5, size=16, face="bold"),
             axis.title = element_text(size=12))+
      ggtitle('Outgoing Inter-Jurisdictional Employees and Aggregate T4 Earnings')
    
  }) 
  
  
  #PR Trend download tables
  
  tableP_down <- reactive ({
    switch( input$tableIn,
            "Filtered Table" = trend_filted(),
            "Full Table" = table_1_2
    )
  })
  
  
  # Downloadable excel file of selected table
  output$downloadPtable <- downloadHandler(
    filename = function(){
      paste(input$tableIn, ".csv", sep = "")
      #paste(input$table)
    },
    content = function(file){
      write.csv(tableP_down(), file, row.names = FALSE)
      
    },
    contentType = "csv"
  )
  
  
  
  #PR Trend table
  
  # IJE_count_filt<- reactive({
  #   table_1_2[,c(-10)] %>%
  #     filter(province %in% input$ProvinceInput,
  #            year>= input$YRInput[1],
  #            year<= input$YRInput[2],
  #            source %in% input$DSInput,
  #            gender %in% input$GDInput,
  #            _source %in% input$InSource
  # )})
  # 
  # 
  # output$PRtable <-DT::renderDataTable(
  #   datatable(IJE_count_filt(),options= list(lengthMenu=c(input$YRInput[2]-input$YRInput[1]+1,2*(input$YRInput[2]-input$YRInput[1]+1),3*(input$YRInput[2]-input$YRInput[1]+1))))%>%
  #     formatStyle(c(1-8), color='black')
  #   
  # ) 
  
  
  
  
  ###################Industry
  
  ind_filtered <- reactive({
    table_3478 %>%
      filter(province %in% input$ProIndInput,
             industry %in% input$IndustryInput,
             type %in% input$IncOutIndustry,
             year>= input$YRInd[1],
             year<= input$YRInd[2]) %>%
    mutate(industry=factor(industry,levels=c("Agriculture, forestry, fishing and hunting","Oil and gas extraction and support activities",
                                             "Mining and quarrying (excluding oil and gas)","Utilities","Construction","Manufacturing",
                                             "Wholesale and Retail trade","Transportation and warehousing",
                                             "Information and cultural industries; Finance and insurance;\n Real estate and rental and leasing; Management of companies and enterprise",
                                             "Professional, scientific and technical services","Education services, health care and social assistance",
                                             "Accommodation and food services","Other services","Public administration","Unknown")))
    })
  
  #count trend
  
  output$IndCount <- renderPlot({
    ggplot(ind_filtered(), aes(x=year, y=count, group=industry, color=industry)) +
      geom_line(size=1.2) + geom_point(size=3) +
      
      ggtitle(paste("Inter-Jurisdictional Employment of", input$ProIndInput, "by Industry")) +
      labs(y = "Number of IJEs", x = "Year") +
      
      scale_x_continuous(breaks=seq(2002,2017,2)) + 
      scale_y_continuous(labels = function(c){paste0(format(c, big.mark = ","))}) +
      scale_colour_brewer(name='Industry',palette='Paired') +
      
      theme(plot.title = element_text(hjust=0.5, size=12, face = "bold"),
            axis.title = element_text(size=12))
  })
  
  output$IndIncome <- renderPlot({
    ggplot(ind_filtered(), aes(x=year, y=income, group=industry, color=industry)) +
      geom_line(size=1.2) + geom_point(size=3) +
      
      ggtitle(paste("Inter-Jurisdictional Employment Income of", input$ProIndInput, "by Industry")) +
      labs(y = "Aggregate T4 Earnings ($)", x = "Year") +
      
      scale_x_continuous(breaks=seq(2002,2017,2)) + 
      scale_y_continuous(labels = function(c){paste0(format(c, big.mark = ","))}) +
      scale_colour_brewer(name='Industry',palette='Paired') +
      
      theme(plot.title = element_text(hjust=0.5, size=12, face = "bold"),
            axis.title = element_text(size=12))
  })
  # 
  # output$Indtrend <-renderPlot({
  #   
  #   ggplot(Ind_filted(), aes(x=year, y = count, group=type, color=type)) + 
  #     geom_line(size=1.2)+
  #     geom_point(size=3)+
  #     labs(y = "Inter-Jurisdictional Employment (Number)", x = "Year")+
  #     scale_colour_manual(name='Role',values = c("aquamarine4", "yellow3"))+
  #     scale_x_continuous(breaks=seq(2002,2017,2))+
  #     
  #     scale_y_continuous(labels = function(c){paste0(format(c, big.mark = ","))})+
  #     ggtitle(paste("Inter-Jurisdictional Employment of", input$ProIndInput, "in Specificed Industry"))+
  #     theme(legend.position =c(0.9,0.9) , 
  #           plot.title = element_text(hjust=0.5, size=12, face = "bold"),
  #           axis.title = element_text(size=12))
  # })
  # 
  # # trend
  # output$IndInctrend <-renderPlot({
  #   ggplot(Ind_filted(), aes(x=year, y = income, group=type, color=type)) + 
  #     geom_line(size=1.2)+
  #     geom_point(size=3)+
  #     labs(y = "Aggregate T4 Earnings", x = "Year")+
  #     scale_colour_manual(name='Role',values = c("cyan3", "darkorange2"))+
  #     scale_x_continuous(breaks=seq(2002,2017,2))+
  #     
  #     scale_y_continuous(labels = function(c){paste0(format(c, big.mark = ","))})+
  #     ggtitle(paste("Aggregate T4 Earnings for Inter-Jurisdictional Employees in Specified Industry"))+
  #     theme(legend.position =c(0.9,0.9),
  #           plot.title = element_text(hjust=0.5, size=12, face = "bold"),
  #           axis.title = element_text(size=12))
  # }) 
  # 
  # 
  # # receiver and  Sender trend by industry
  # output$Ind_receiver <-renderPlot({
  #   table_3478_receive <-
  #     table_3478 %>%
  #     filter(province %in% input$ProIndInput,
  #            industry %in% input$IndustryInput,
  #            year>= input$YRInd[1],
  #            year<= input$YRInd[2],
  #            type == "Incoming"
  #     ) 
  #   
  #   ggplot(table_3478_receive,aes(x = year )) +
  #     geom_bar(mapping = aes(y = count, colour = "Employees"),stat = 'identity', fill="aquamarine4")+
  #     #add second dimension
  #     geom_line(mapping = aes( y = income/35000, colour = "Income"),group = 1, size = 2)+
  #     scale_x_continuous(breaks=seq(2002,2017,2))+
  #     
  #     #add second y axis
  #     scale_y_continuous(name = "Number of Employees", 
  #                        labels = function(c){paste0(format(c, big.mark = ","))} ,
  #                        sec.axis = sec_axis(~.*35000, name="Aggregate T4 Earnings",
  #                                            labels = function(b){paste0(format(b, big.mark = ","))}))+
  #     #define colour
  #     scale_colour_manual(values = c("aquamarine4", "cyan3")) +
  #     labs(y = "Number of Receiver", x = "Year", colour = "Label") +
  #     ggtitle( paste("Receiver and Income in Specified Industry"))+
  #     #label location
  #     theme( legend.position = "none",
  #            axis.title.y= element_text(color = "aquamarine4", size=12),
  #            axis.title.y.right = element_text(color = "cyan3", size=12), 
  #            plot.title = element_text(hjust=0.5, size=12, face="bold"),
  #            axis.title = element_text(size=12))
  #   
  # }) 
  # 
  # 
  # output$Ind_sender <-renderPlot({
  #   table_3478_send <-
  #     table_3478 %>%
  #     filter(province %in% input$ProIndInput,
  #            industry %in% input$IndustryInput,
  #            year>= input$YRInd[1],
  #            year<= input$YRInd[2],
  #            type == "Outgoing"
  #     ) 
  #   
  #   ggplot(table_3478_send,aes(x = year )) +
  #     geom_bar(mapping = aes(y = count, colour = "Employees"),stat = 'identity', fill="yellow3")+
  #     #add second dimension
  #     geom_line(mapping = aes( y = income/35000),group = 1, size = 2,  colour = "darkorange2")+
  #     scale_x_continuous(breaks=seq(2002,2017,2))+
  #     
  #     #add second y axis
  #     scale_y_continuous(name = "Number of Senders", 
  #                        labels = function(c){paste0(format(c, big.mark = ","))} ,
  #                        sec.axis = sec_axis(~.*35000, name="Aggregate T4 Earnings",
  #                                            labels = function(b){paste0(format(b, big.mark = ","))}))+
  #     #define colour
  #     scale_colour_manual(values = c("yellow3", "darkorange2")) +
  #     labs(y = "Number of Senders", x = "Year", colour = "Label") +
  #     ggtitle( paste("Senders and Income in Specified Industry"))+
  #     #label location
  #     theme( legend.position = "none", 
  #            axis.title.y= element_text(color = "yellow3", size=12),
  #            axis.title.y.right = element_text(color = "darkorange2", size=12), 
  #            plot.title = element_text(hjust=0.5, size=12, face="bold"),
  #            axis.title = element_text(size=12))
  #   
  # }) 
  # 
  
  
  #Industry Trend download tables
  
  tableI_down <- reactive ({
    switch( input$tableInd,
            "Filtered Industry Table" = Ind_filted(),
            "Full Table" = table_3478
    )
  })
  
  
  # Downloadable excel file of selected table
  output$downloadItable <- downloadHandler(
    filename = function(){
      paste(input$tableInd, ".csv", sep = "")
      #paste(input$table)
    },
    content = function(file){
      write.csv(tableI_down(), file, row.names = FALSE)
      
    },
    contentType = "csv"
  )
  
  #PR Industry table
  
  # Ind_filt<- reactive({
  #   table_3478[,c(-8)] %>%
  #     filter(province %in% input$ProIndInput,
  #            industry %in% input$IndustryInput,
  #            year>= input$YRInd[1],
  #            year<= input$YRInd[2]
  #     )})
  # 
  # output$Indtable <-DT::renderDataTable(
  #   datatable(Ind_filt(),options= list(lengthMenu=c(input$YRInd[2]-input$YRInd[1]+1,2*(input$YRInd[2]-input$YRInd[1]+1),3*(input$YRInd[2]-input$YRInd[1]+1))))%>%
  #     formatStyle(c(1-7), color='black')
  #   
  # ) 
  
  
  
  
  
  
  
  ###################Target Province
  
  
  
  #TP barplot
  
  # table56910_filted<- reactive({
  #   table_56910 %>%
  #     filter(province %in% input$ProOPInput,
  #            target_prov %in% input$ProTPInput,
  #            year>= input$YRTP[1],
  #            year<= input$YRTP[2]
  #     )})
  
  table56910_filtered <- reactive({
    table_56910 %>%
      filter(province %in% input$ProOPInput,
             target_prov %in% input$ProTPInput,
             type %in% input$IncOutTgtJuris,
             year>= input$YRTP[1],
             year<= input$YRTP[2]) %>%
      mutate(target_prov=factor(target_prov,levels=c("Newfoundland and Labrador","Prince Edward Island","Nova Scotia","New Brunswick",
                                                     "Quebec", "Ontario", "Manitoba","Saskatchewan","Alberta","British Columbia",
                                                     "Yukon", "Northwest Territories","Nunavut")))
  })
  
  output$TPcount <- renderPlot({
    ggplot(table56910_filtered(), aes(x=year, y= count, group=target_prov, color=target_prov)) + 
      geom_line(size=1.2) + geom_point(size=3)+
      
      ggtitle(paste("Inter-Jurisdictional Employment of", input$ProOPInput))+
      theme(plot.title = element_text(hjust = 0.5, size = 12, face = "bold")) +
      labs(x='Year', y='Number of IJEs') +
      
      scale_x_continuous(breaks=seq(2002,2017,2))+
      scale_y_continuous(labels = function(c){paste0(format(c, big.mark = ","))})+
      scale_color_brewer(name='Province',palette='Paired')
  })
  
  output$TPincome <- renderPlot({
    ggplot(table56910_filtered(), aes(x=year, y= income, group=target_prov, color=target_prov)) + 
      geom_line(size=1.2) + geom_point(size=3)+
      
      ggtitle(paste("Inter-Jurisdictional Employment Income of", input$ProOPInput))+
      theme(plot.title = element_text(hjust = 0.5, size = 12, face = "bold")) +
      labs(x='Year', y='Aggregate T4 Earnings ($)') +
      
      scale_x_continuous(breaks=seq(2002,2017,2))+
      scale_y_continuous(labels = function(c){paste0(format(c, big.mark = ","))})+
      scale_color_brewer(name='Province',palette='Paired')
  })
  # 
  # output$TPtrend <-renderPlot({
  #   
  #   ggplot(table56910_filted(), aes(x=year, y = count, group=type, color=type)) + 
  #     geom_line(size=1.2)+
  #     geom_point(size=3)+
  #     labs(y = "Inter-Jurisdictional Employment (Number)", x = "Year")+
  #     # add colour
  #     scale_colour_manual(name='Role',values = c("aquamarine4", "yellow3"))+
  #     scale_x_continuous(breaks=seq(2002,2017,2))+
  #     
  #     scale_y_continuous(labels = function(c){paste0(format(c, big.mark = ","))})+
  #     ggtitle(paste("Inter-Jurisdictional Employment of", input$ProOPInput))+
  #     theme(legend.position =c(0.9,0.9), plot.title = element_text(hjust = 0.5, size = 12, face = "bold"))
  # }) 
  # 
  # output$TPInctrend <-renderPlot({
  #   
  #   ggplot(table56910_filted(), aes(x=year, y = income, group=type, color=type)) + 
  #     geom_line(size=1.2)+
  #     geom_point(size=3)+
  #     labs(y = "Aggregate T4 Earnings", x = "Year")+
  #     # add colour
  #     scale_colour_manual(name='Role',values = c("cyan3", "darkorange2"))+
  #     scale_x_continuous(breaks=seq(2002,2017,2))+
  #     
  #     scale_y_continuous(labels = function(c){paste0(format(c, big.mark = ","))})+
  #     ggtitle("Aggregate T4 Earnings for Inter-Jurisdictional Employees")+
  #     theme(legend.position =c(0.9,0.9), plot.title = element_text(hjust = 0.5, size = 12, face = "bold"))
  # }) 
  # 
  # #TP comparison 
  # table56910_filted_1<- reactive({
  #   table_56910%>%
  #     filter(province %in% input$ProOPInput,
  #            target_prov %in% input$ProTPInput,
  #            year>= input$YRTP[1],
  #            year<= input$YRTP[2],
  #            type == "Incoming"
  #     )})
  # 
  # table56910_filted_2<- reactive({
  #   table_56910%>%
  #     filter(province %in% input$ProOPInput,
  #            target_prov %in% input$ProTPInput,
  #            year>= input$YRTP[1],
  #            year<= input$YRTP[2],
  #            type == "Outgoing"
  #     )}) 
  # 
  # output$TPComp <-renderPlot({
  #   ggplot(table56910_filted_1(),aes(x = year )) +
  #     geom_bar(mapping = aes(y = count, colour = "Employee"),stat = 'identity', fill="aquamarine4")+
  #     #add second dimension
  #     geom_line(mapping = aes( y = income/35000, colour = "Income"),group = 1, size = 2)+
  #     scale_x_continuous(breaks=seq(2002,2017,2))+
  #     
  #     #add second y axis
  #     scale_y_continuous(name = "Number of Receiver", 
  #                        labels = function(c){paste0(format(c, big.mark = ","))} ,
  #                        sec.axis = sec_axis(~.*35000, name="Aggregate T4 Earnings",
  #                                            labels = function(b){paste0(format(b, big.mark = ","))}))+
  #     #define colour
  #     scale_colour_manual(values = c("aquamarine4", "cyan3")) +
  #     labs(y = "Number of Receiver", x = "Year", colour = "Label") +
  #     ggtitle( paste("Inter-Jurisdictional Receiver and T4 Income in", input$ProOPInput))+
  #     #label location
  #     theme( legend.position = "none", 
  #            axis.title.y= element_text(color = "aquamarine4", size=12),
  #            axis.title.y.right = element_text(color = "cyan3", size=12), 
  #            plot.title = element_text(hjust=0.5, size=12, face="bold"),
  #            axis.title = element_text(size=12))
  # }) 
  # 
  # 
  # 
  # output$TPCompInc <-renderPlot({
  #   ggplot(table56910_filted_2(),aes(x = year )) +
  #     geom_bar(mapping = aes(y = count, colour = "Employee"),stat = 'identity', fill="yellow3")+
  #     #add second dimension
  #     geom_line(mapping = aes( y = income/35000, colour = "Income"),group = 1, size = 2)+
  #     scale_x_continuous(breaks=seq(2002,2017,2))+
  #     
  #     #add second y axis
  #     scale_y_continuous(name = "Number of Sender", 
  #                        labels = function(c){paste0(format(c, big.mark = ","))} ,
  #                        sec.axis = sec_axis(~.*35000, name="Aggregate T4 Earnings",
  #                                            labels = function(b){paste0(format(b, big.mark = ","))}))+
  #     #define colour
  #     scale_colour_manual(values = c("yellow3", "darkorange2")) +
  #     labs(y = "Number of Sender", x = "Year", colour = "Label") +
  #     ggtitle( paste("Inter-Jurisdictional Sender and T4 Income in", input$ProOPInput))+
  #     #label location
  #     theme( legend.position = "none", 
  #            axis.title.y= element_text(color = "yellow3", size=12),
  #            axis.title.y.right = element_text(color = "darkorange2", size=12), 
  #            plot.title = element_text(hjust=0.5, size=12, face="bold"),
  #            axis.title = element_text(size=12))
  #   
  # }) 
  # 
  
  
  
  ################### Age Group 
  
  agePalette <- paste0('#',c('F8766D','B79F00','00BA38','00BFC4','619CFF','F564E3'))
  names(agePalette) <- unique(table_11$age_group)
  
  table11_filted<- reactive({
    table_11 %>%
      filter(age_group %in% input$AgeInput,
             province %in% input$ProAgeInput,
             gender %in% input$GDAgeInput,
             type %in% input$TAgeInput,
             year>= input$YRAge[1],
             year<= input$YRAge[2]
      )})
  
  #Age Trend 
  output$Agetrend <-renderPlot({
    ggplot(table11_filted(), aes(x=year, y = count, group=age_group, color=age_group)) + 
      geom_line(size=1.2)+
      geom_point(size=3)+
      labs(y = "Number of IJEs", x = "Year")+
      scale_x_continuous(breaks=seq(2002,2017,2))+
      
      scale_y_continuous(labels = function(c){paste0(format(c, big.mark = ","))})+
      scale_color_manual(name='Age Group',values=agePalette) +
      ggtitle("Number of IJEs by Age Group")+
      theme(plot.title = element_text(hjust=0.5, size=16, face = "bold"))
  }) 
  
  
  #Age chanages
  output$Agechange <-renderPlot({
    table11_filted <-
      table_11 %>%
      filter(age_group %in% input$AgeInput,
             province %in% input$ProAgeInput,
             gender %in% input$GDAgeInput,
             type %in% input$TAgeInput,
             year %in% c(input$YRAge[1], input$YRAge[2])) %>% 
      group_by(age_group) %>%
      mutate(pct_change = (lead(count)/count-1)) %>%
      filter(year %in% input$YRAge[1])
    
    ggplot(table11_filted, aes(x=age_group, color=age_group, fill=age_group)) + 
      geom_histogram(mapping = aes(y = pct_change), position = "dodge",stat = 'identity')+
      labs(y = "Percentage Change of Employment", x = "Age Groups")+
      scale_y_continuous(labels = scales::percent_format(accuracy = 1))+
      scale_fill_manual(name='Age Group',values=agePalette) +
      scale_color_manual(name='Age Group',values=agePalette) +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))+
      ggtitle(paste("Percentage Changes of Employment by Age Group from", input$YRAge[1], "to", input$YRAge[2]))+
      theme(plot.title = element_text(hjust=0.5, size=16, face = "bold"))
  })  
  
  
  #Age Group Trend download tables
  
  tableA_down <- reactive ({
    switch( input$tableAge,
            "Filtered Age Table" = table11_filted(),
            "Full Age Table" = table_11
    )
  })
  
  
  # Downloadable excel file of selected table
  output$downloadAtable <- downloadHandler(
    filename = function(){
      paste(input$tableAge, ".csv", sep = "")
      #paste(input$table)
    },
    content = function(file){
      write.csv(tableA_down(), file, row.names = FALSE)
      
    },
    contentType = "csv"
  )
  
  ################### Table Download
  
  tableInput <- reactive ({
    switch( input$table,
            "Alberta" = table_AB,
            "British Columbia" = table_BC,
            "Manitoba" = table_MB,
            "New Brunswick" = table_NB,
            "Newfoundland and labrador" = table_NL,
            "Northwest Territories" = table_NT,
            "Nova Scotia" = table_NS,
            "Nunavut" = table_NU,
            "Ontario" = table_ON,
            "Prince Edward Island" = table_PE,
            "Quebec" = table_QC,
            "Saskatchewan" = table_SK,
            "Yukon" = table_YT
    )
  })
  
  
  # display the selected table
  output$tableD <- renderTable({
    tableInput()
  })
  
  # Downloadable excel file of selected table
  output$downloadData <- downloadHandler(
    filename = function(){
      paste(input$table, ".csv", sep = "")
    },
    content = function(file){
      write.csv(tableInput(), file, row.names = FALSE)
      
    }
  )
  
  output$downloadGuide <- downloadHandler(
    filename = 'Methodological Guide on IJEs-ENGLISH-Dec.2017.pdf',

    content = function(infile){
      file.copy('./data/downloadables/Methodological Guide on IJEs-ENGLISH-Dec.2017.pdf',infile)
      # save_object('david-wavrock/ije/Methodological Guide on IJEs-ENGLISH-Dec.2017.pdf',bucket=minio_filist,use_https=F,region='',file=infile)
    }
  )

  output$downloadVintage <- downloadHandler(
    filename = 'English_Version.zip',

    content = function(infile){
      # zip(zipfile=infile,files=list.files('./data/downloadables/English_Version'),flags='-j')
      file.copy('./data/downloadables/English_Version.zip',infile)
      # save_object('david-wavrock/ije/English_Version.zip',bucket=minio_filist,use_https=F,region='',file=infile)
    },
    contentType = 'application/zip'

  )
  
}
