# ------------------------------------------------------------------
# Portability note: install.packages() calls were removed from this
# script. Install the packages listed in the README before running,
# then run the script from this folder (paths are relative).
# ------------------------------------------------------------------

######################### Lab 11 - Interactive Maps  ##########################

#### Set your working environment ----

# Install packages


# Load packages
library(sf)
library(tidyverse)
library(leaflet)
library(leaflet.extras)
library(htmlwidgets)
library(classInt)
library(RColorBrewer)

# Set working directory 
# NOTE: the original setwd() call was removed for portability.
# Run this script from this project folder; all file paths below are relative.

# Read data 
deaths <- st_read("NYC_covid19_zip.shp")
clusters <-  st_read("clusters_death.shp")
sites <- st_read("NYC_COVID19_vacc_sites.shp")

# Re project your maps to WGS84
deaths <- st_transform(deaths, crs = 4326)
clusters <- st_transform(clusters, crs = 4326)
sites <- st_transform(sites, crs = 4326)

# Data management 
names(deaths)

# Rename variables 
deaths |> 
  rename("per.65yrs" = X..over.65y,
         "per.HS" = X..HS.degre,
         "per.poverty" = X..Poverty,
         "per.PP" = X..Public.T,
         "infection" =  Infection.) |> 
  mutate(per.65yrs = round(per.65yrs, 1),
         per.HS = round(per.HS, 1),
         per.poverty = round(per.poverty, 1),
         per.PP = round(per.PP, 1),
         Death.Rate = round(Death.Rate, 1)) -> deaths

names(deaths)

#### Add a tile layer -----

# Get list of map providers 
names(providers)

# Base tiles
leaflet() |> 
  addProviderTiles("CartoDB", group = "CartoDB")

# You can add multiple base maps
leaflet() |> 
  addProviderTiles("CartoDB", group = "CartoDB") |> 
  addProviderTiles("CartoDB.DarkMatterNoLabels", group = "CartoDB - Black") 
    
  
# Control layer
leaflet() |>  
  addProviderTiles("CartoDB", group = "CartoDB") |> 
  addProviderTiles("CartoDB.DarkMatterNoLabels", group = "CartoDB - Black") |> 
  addLayersControl(baseGroups = c("CartoDB", "CartoDB - Black")) # adds control layer


# Specify location of interest
leaflet() |>  
  addProviderTiles("CartoDB", group = "CartoDB") |> 
  addProviderTiles("CartoDB.DarkMatterNoLabels", group = "CartoDB - Black") |> 
  setView(lng = -73.968, lat = 40.780, zoom = 10) |>  # Coordinates of NYC
  addLayersControl(baseGroups = c("CartoDB", "CartoDB - Black")) 

# Assign it to an object
leaflet() |>  
  addProviderTiles("CartoDB", group = "CartoDB") |> 
  addProviderTiles("CartoDB.DarkMatterNoLabels", group = "CartoDB - Black") |> 
  setView(lng = -73.968, lat = 40.780, zoom = 10) |>  # Coordinates of NYC
  addLayersControl(baseGroups = c("CartoDB", "CartoDB - Black")) -> base


#### Add choropleth layer ----

# Select color palette 
display.brewer.all(type = "seq")

# Continuous Color palette  function
pal_death <- colorNumeric("Reds", 
                     domain = deaths$Death.Rate,
                     reverse = FALSE)

# Add the layer 
base |> 
  addPolygons(data = deaths,
              color = "black",
              weight = 0.5,   # line width 
              fillColor = ~pal_death(Death.Rate),  # adds color palette function
              fillOpacity = 0.7,
              label = ~NYCZipCode) |> 
  addLegend(pal = pal_death,
            values = deaths$Death.Rate,
            title = "Rate",
            position = "bottomright") 

# A binned color palette
classIntervals(deaths$Death.Rate, n = 5, style = "jenks")$brks

pal_death2 <- colorBin(palette = "Reds",             
                      domain = deaths$Death.Rate,   
                      bins = c(0, 243, 423, 589, 818, 1229),                     
                      reverse = FALSE)

base |> 
  addPolygons(data = deaths,
              color = "black",
              weight = 0.5,
              fillColor = ~pal_death2(Death.Rate),
              fillOpacity = 0.7,
              label = ~NYCZipCode) |> 
  addLegend(pal = pal_death2,
            values = deaths$Death.Rate,
            title = "Rate",
            position = "bottomright") 


# Add pop-up
base |> 
  addPolygons(data = deaths,
              color = "black",
              weight = 0.5,
              fillColor = ~pal_death2(Death.Rate),
              fillOpacity = 0.7,
              label = ~NYCZipCode,
              group = "COVID-19 Death Rate",   # adding a layer name 
              popup = ~paste(
                             NYCZipCode, 
                             Death.Rate,
                             per.65yrs,
                             per.HS, 
                             per.poverty, 
                             per.PP )) |> 
  addLegend(pal = pal_death2,
            values = deaths$Death.Rate,
            title = "Rate",
            position = "bottomright") 


# Add labels and line breaks with html
##  "<b>Label:</b>" to bold the label 
## "<br>" for line breaks
base |> 
  addPolygons(data = deaths,
              color = "black",
              weight = 0.5,
              fillColor = ~pal_death2(Death.Rate),
              fillOpacity = 0.7,
              label = ~NYCZipCode,
              group = "COVID-19 Death Rate",   
              popup = ~paste(
                      "<b>Zip Code:</b>", NYCZipCode,"<br>",
                      "<b>Death Rate:</b>", Death.Rate,"per 100k<br>",
                      "<b>Percent older than 65yrs:</b>", per.65yrs,"%<br>",
                      "<b>Percent High School Graduates:</b>", per.HS,"%<br>",
                      "<b>Percent Poverty:</b>", per.poverty,"%<br>",
                      "<b>Percent Public Assistance:</b>", per.PP,"%" )) |> 
  addLegend(pal = pal_death2,
            values = deaths$Death.Rate,
            title = "Rate",
            position = "bottomright") 


# Add the layer 
base |> 
  addPolygons(data = deaths,
              color = "black",
              weight = 0.5,
              fillColor = ~pal_death2(Death.Rate),
              fillOpacity = 0.7,
              label = ~NYCZipCode,
              group = "COVID-19 Death Rate",   
              popup = ~paste(
                "<div style='font-family: Roboto, sans-serif; font-size: 14px; line-height: 1.4;'>",
                "<div style='font-size: 16px; font-weight: bold; color: #d9534f;'> 
                <b>Zip Code:</b> ", NYCZipCode, "</div>",
                "<b>Death Rate:</b> <span style='color: #03a5fc;'>", Death.Rate, " per 100k</span><br>",
                "<b>Percent older than 65yrs:</b> <span style='color: #03a5fc;'>", per.65yrs, "%</span><br>",
                "<b>Percent High School Graduates:</b> <span style='color: #03a5fc;'>", per.HS, "%</span><br>",
                "<b>Percent Poverty:</b> <span style='color: #03a5fc;'>", per.poverty, "%</span><br>",
                "<b>Percent Public Assistance:</b> <span style='color: #03a5fc;'>", per.PP, "%</span><br>",
                "</div>"
                )) |> 
  addLegend(pal = pal_death2,
            values = deaths$Death.Rate,
            title = "Rate",
            position = "bottomright") -> basemap_rate

#### Add the clusters ----
pal_cluster <- colorFactor(palette = c("darkred","darkblue"),
                           domain = clusters$cluster)

basemap_rate |> 
  addPolygons(data = clusters,
             color = ~pal_cluster(cluster),
             weight = 2,
             fillColor = NA,
             popup = ~paste(cluster, "<br>"),
             group = "Clusters") |> 
  addLayersControl(baseGroups = c("CartoDB", "CartoDB - Black"),
                   overlayGroups = c("COVID-19 Death Rate", "Clusters"), 
                   options = layersControlOptions(collapsed = FALSE)) -> basemap_rate_clusters


#### Add Vaccination Sites ----
basemap_rate_clusters |> 
  addCircleMarkers(data = sites,
                   color = "steelblue",
                   fillOpacity = .9,
                   radius = 4,
                   group = "Vaccinations Sites",
                   popup = ~paste(name, "<br>")) |> 
  addLayersControl(baseGroups = c("CartoDB", "CartoDB - Black"),
                   overlayGroups = c("COVID-19 Death Rate", "Clusters", "Vaccinations Sites"), 
                   options = layersControlOptions(collapsed = FALSE)) -> basemap_rate_clusters_points

  

#### Add more functionality ----
basemap_rate_clusters_points |> 
  hideGroup(c("Clusters", "Vaccinations Sites")) |>  # Hide or deactivate layers
  showGroup("COVID-19 Death Rate") |>  # Activate layer
  addSearchFeatures(targetGroups = "COVID-19 Death Rate",  # Add a search box for zip codes
                    options = searchFeaturesOptions(
                      zoom = 12,       
                      openPopup = TRUE,  
                      firstTip = "Zip Code",  
                      autoCollapse = TRUE,
                      hideMarkerOnCollapse = TRUE))



#### Prepare map for export ----
basemap_rate_clusters_points |> 
  hideGroup(c("Clusters", "Vaccinations Sites")) |>  # Hide or deactivate layers
  showGroup("COVID-19 Death Rate") |>  # Activate layer
  addSearchFeatures(targetGroups = "COVID-19 Death Rate",  # Add a search box for zip codes
                    options = searchFeaturesOptions(
                      zoom = 12,       
                      openPopup = TRUE,  
                      firstTip = "Zip Code",  
                      autoCollapse = TRUE,
                      hideMarkerOnCollapse = TRUE)) -> web_map

# Save interactive maps 
saveWidget(web_map,
           file = "COVID19_map.html")




























