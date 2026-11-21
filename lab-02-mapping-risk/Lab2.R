# ------------------------------------------------------------------
# Portability note: install.packages() calls were removed from this
# script. Install the packages listed in the README before running,
# then run the script from this folder (paths are relative).
# ------------------------------------------------------------------

########################### Lab 2: Mapping Risk ###############################

#### Setting Up your R Environment ----

# Step 1: Load our packages:
library(tidycensus)
library(tidyverse)
library(sf)
library(RColorBrewer)
library(classInt)
library(ggspatial)
library(patchwork)


# Step 2: Set working directory 


# Step 3: Read-in data 

# Zip code .shp
zip_nyc <- st_read("MODZCTA_2010.shp")

class(zip_nyc)
head(zip_nyc)

ggplot() +
  geom_sf(data = zip_nyc)

# Covid19 death data
covid <- read_csv("data-by-modzcta.csv")

str(covid)
summary(covid)

# Join covid data to zip shp 
covid_zip <- merge(zip_nyc, covid, 
                   by.x = "MODZCTA",
                   by.y = "modified_ZCTA")


#### Calculate Rates and Relative Risks ----

# Calculate total pop and deaths
covid |> 
  summarise(city_pop_total = sum(population),
            city_deaths_total = sum(death_count))

# Add new columns 
covid_zip |> 
  mutate(rate = round(100000*(death_count/population),0),
         expected = population*(35253/8336817),
         RR = round(death_count/expected,2)) -> covid_zip


#### Create our two maps ----

# Map death rate 
# base map:
ggplot() +
  geom_sf(data = covid_zip,
          aes(fill = rate),
          color = "black",
          linewidth = .2) 

# Select color palette and our breaks: 
display.brewer.all(type = "seq")

# Examine distribution
covid_zip |> 
  ggplot(aes(x = rate)) +
      geom_histogram() +
       theme_minimal()

# Get quantile breaks
rate_quant_breaks <- classIntervals(covid_zip$rate, n = 5, style = "quantile")$brks

## add color and breaks
ggplot() +
  geom_sf(data = covid_zip,
          aes(fill = rate),
          color = "black",
          linewidth = .2) +
  scale_fill_fermenter(direction = 1,
                       palette = "YlOrBr",
                       breaks = rate_quant_breaks) +
  theme_void()

## add final elements to map
ggplot() +
  geom_sf(data = covid_zip,
          aes(fill = rate),
          color = "black",
          linewidth = .2) +
  scale_fill_fermenter(direction = 1,
                       palette = "YlOrBr",
                       breaks = rate_quant_breaks) +
  labs(title = "COVID19 Death Rate \nper 100k Residents",
       fill = "Rate") +
  theme_void() + 
  theme(plot.title = element_text(size = 13,
                                  family  = "Avenir",
                                  vjust = -10,
                                  hjust = 0.10),
        plot.title.position = "plot",
        legend.title = element_text(size = 12),
        legend.position = c(0.22, 0.63),
        legend.key.size = unit(.4, 'cm')) +
  annotation_scale(pad_x = unit(1.4, "in"),
                   pad_y = unit(.3, "in"),
                   unit_category = "imperial") +
  annotation_north_arrow(location = "bl", which_north = "true", 
                         height = unit(.8, "cm"),
                         width = unit(1, "cm"),
                         pad_x = unit(1, "in"), 
                         pad_y = unit(0.2, "in"),
                         style = north_arrow_fancy_orienteering) -> map_rate


# Relative Risk  
# base map
ggplot() +
  geom_sf(data = covid_zip,
          aes(fill = RR),
          color = "black",
          linewidth = .2) 

# Select a `divergent` color palette and our breaks: 
display.brewer.all(type = "div")

# Add breaks manually 
rr_manual_breaks <- c(0,0.50, 0.90, 1.10, 1.50, 2.91)

# Add breaks
ggplot() +
  geom_sf(data = covid_zip,
          aes(fill = RR),
          color = "black",
          linewidth = .2) +
  scale_fill_fermenter(direction = -1,
                       palette = "RdBu",
                       breaks = rr_manual_breaks) 


## add final elements: 
ggplot() +
  geom_sf(data = covid_zip,
          aes(fill = RR),
          color = "black",
          linewidth = .2) +
  scale_fill_fermenter(direction = -1,
                       palette = "RdBu",
                       breaks = rr_manual_breaks) +
  labs(title = " Relative Risk of Dying \nfrom COVID19",
       fill = "Ratio",
       caption = "Author: Tobechi Dimkpa \n Sources: NYC Health \n Date: January 29 2025") +
  theme_void() + 
  theme(plot.title = element_text(size = 13,
                                  family  = "Avenir",
                                  vjust = -10,
                                  hjust = 0.10),
        plot.title.position = "plot",
        legend.title = element_text(size = 12),
        legend.position = c(0.22, 0.63),
        legend.key.size = unit(.4, 'cm'),
        plot.caption = element_text(colour = "grey50",
                                    size = 8,
                                    vjust = 17,
                                    hjust = .9)) -> map_RR



# Combine plots using {patchwork}
map_rate + map_RR 

map_rate + map_RR -> combined_plot

combined_plot +
  plot_annotation(title = "New York City COVID-19 Death Burden",
                  subtitle = "  by Zip Codes, 2020 - 2021")  &
  theme(text = element_text(family = "Avenir",
                            size = 12)) -> plot

# Save plot as jpg with `ggsave()` 
ggsave(plot,
       filename = "combined_plot.jpg",
       width = 7,
       height = 5.5)





















