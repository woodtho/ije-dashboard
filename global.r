# setwd('/home/jovyan/ije-shiny-2020/data/')
beginy = quote(2002)
endy = quote(2017)
#install.packages( pkgs = c("classInt"),type="binary", repos = "file:////fld6filer/packagerepo-depotprogiciel/miniCRAN" )
library(shiny)
library(tidyverse)
library(sf)
# library(rmapshaper)
library(leaflet)
# library(dplyr)
library(spData)
library(classInt)
library(sp)
# library(geojsonio)
library(rgeos)
# library(rgdal)
library(htmlwidgets)
# library(aws.s3)
library(RColorBrewer)
library(plotly)

options(scipen = 999)


# Added new modules -------------------------------------------------------

mainmapUI <- function(id) {
  ns <- NS(id)
  tagList(
    plotlyOutput(ns("mainmap"),height=600
                 # ,click='map_click'
    )
  )
}

mainmapServer <- function(id, data, SeriesInput) {
  moduleServer(
    id,
    function(input, output, session) {
      output$mainmap <- renderPlotly({
        
        mapdat <- simple_pr_shapefile %>%
          inner_join(data(), by='PRUID') %>%
          
          mutate(mapformat=sf::st_transform(
            simple_pr_shapefile$geometry,
            crs= "+proj=laea +lat_0=56.1304 +lon_0=-86.3468 +ellps=WGS84 +units=m +no_defs "))
        
        ## set color scheme for concept (employees in blue, income in red)
        if(SeriesInput() == "Employees"){
          seriesvar <- mapdat$count
          lowgrad <- '#f1eef6'
          highgrad <- '#045a8d'
          seriestitle <- 'Number of Inter-Jurisdictional Employees by Province'
          # seriestitle <- 'Number of Inter-Jurisdictional Employees'
          # 
          pal_count_PR <- createClasses(mapdat$count , "Blues", "transparent", 5)
          # 
          # geo_labels_PR <- sprintf(
          #   "<strong>%s (Employees):  %s </strong>",
          #   mapdat$province, format(mapdat$count, big.mark = ",")) %>%
          #   lapply(htmltools::HTML) # add labels 
          
        } else if(SeriesInput() == "Income"){
          seriesvar <- mapdat$income
          lowgrad <- '#fef0d9'
          highgrad <- '#b30000'
          seriestitle <- 'Total Income of Inter-Jurisdictional Employees by Province'
          # seriestitle <- 'Income of Inter-Jurisdictional Employees'
          # 
          pal_count_PR <- createClasses(mapdat$income, "Reds", "transparent", 5)
          # 
          # geo_labels_PR <- sprintf(
          #   "<strong>%s (Income): %s </strong>",
          #   mapdat$province, format(mapdat$income, big.mark = ",")) %>%
          #   lapply(htmltools::HTML) # add labels  
        }
        
        mapdat <- mapdat %>%
          mutate(pcol=pal_count_PR$pal(seriesvar))
        
        ggplotly(
          ggplot(mapdat %>% mutate(geometry=mapformat)) +
            geom_sf(aes(fill=log(seriesvar)/log(10),
                        text=sprintf("<b>%s</b><br>Employees: %s<br>Income: %s",
                                     province,
                                     format(count,big.mark=','),
                                     paste0('$',format(round(income/1000000,1),big.mark=','),' M'))),
                    
                    color="#444444",
                    alpha=0.75) + theme_bw() +
            
            labs(title=seriestitle) +
            # scale_fill_manual(values=pcol) +
            
            scale_fill_gradient(low=lowgrad,
                                high=highgrad,
                                na.value='grey.50') +
            
            theme(plot.title = element_text(vjust=1, hjust=0.5, size=14, face = "bold"),
                  panel.grid.major=element_blank(),panel.grid.minor=element_blank(),
                  axis.title.x=element_blank(),axis.text.x=element_blank(),axis.ticks.x=element_blank(),
                  axis.title.y=element_blank(),axis.text.y=element_blank(),axis.ticks.y=element_blank(),
                  
                  legend.position='none'),
          
          tooltip='text') %>%
          style(hoveron='all')
        
        
        
      })
      
      TRUE
      
      
    }
  )
}

simple_pr_shapefile <- readRDS('./data/simple_pr_shapefile.RDS')
table_1_2 <- readRDS('./data/table_1_2.RDS')
table_3478 <- readRDS('./data/table_3478.RDS') %>%
  mutate(industry=ifelse(industry=="Information and cultural industries; Finance and insurance;\n Real estate and rental and leasing; Management of companies and enterprise",'IFRM',industry))
table_56910 <- readRDS('./data/table_56910.RDS')
table_11 <- readRDS('./data/table_11.RDS')

## define lists for where they're necessary
provList <- c("Newfoundland and Labrador","Prince Edward Island","Nova Scotia","New Brunswick",
              "Quebec", "Ontario", "Manitoba","Saskatchewan","Alberta","British Columbia",
              "Yukon", "Northwest Territories","Nunavut")

indList <- c("Agriculture, forestry, fishing and hunting","Oil and gas extraction and support activities",
             "Mining and quarrying (excluding oil and gas)","Utilities","Construction","Manufacturing",
             "Wholesale and Retail trade","Transportation and warehousing",
             # "Information and cultural industries; Finance and insurance;\n Real estate and rental and leasing; Management of companies and enterprise",
             "IFRM",
             "Professional, scientific and technical services","Education services, health care and social assistance",
             "Accommodation and food services","Other services","Public administration","Unknown")

ageList <- c("18 to 24 years", "25 to 34 years", "35 to 44 years", "45 to 54 years",
             "55 to 64 years", "65 years and older")


createClasses <- function(data, palette, na_color, n) {
  classes <- classIntervals(na.exclude(data), n = n, style = "jenks")
  bins <- classes[["brks"]]
  pal <- colorBin(palette, domain = data, bins = bins, na.color = na_color)
  return <- list("pal" = pal, "bins" = bins)
}

pal <- colorNumeric("viridis", NULL)

# CREATE VARIABLE THAT STORES ALL DATA VALUES FOR DETERMINING BINNING AND PALETTE FOR CHOROPLETH MAP

#pal_count_PR <- createClasses(IJE_table1$count , "Blues", "transparent", 5)

## establish minio connection and list of s3_objects
# source('/home/jovyan/ije-shiny-2020/code/shiny/daaas_storage.R')
# daaas_storage.minimal()

# minio_filist <- get_bucket(bucket='shared',use_https=F,region='',prefix='david-wavrock/ije/')

## to save objects
# save_object('name-of-object',
#             bucket=minio_filist,use_https=F,region='')
