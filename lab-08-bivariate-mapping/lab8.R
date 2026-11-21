# ------------------------------------------------------------------
# Portability note: install.packages() calls were removed from this
# script. Install the packages listed in the README before running,
# then run the script from this folder (paths are relative).
# ------------------------------------------------------------------

####################### Lab 8 Bivariate Mapping in R ###########################
# Install packages

# Load packages
library(tidyverse)
library(sf)
library(sfdep)
library(ggspatial)
library(RColorBrewer)
library(biscale)
library(classInt)
library(patchwork)

# Set working directory



# Read-in shp
covid_zip <- st_read("NYC_covid19_zip.shp") |> 
                 mutate(r_death = round(r_death,1),
                        per_pov = round(per_pov,1))
# Dissolve NYC
NYC <- st_union(covid_zip)

#### Bivariate EDA
# Scatterplots with {ggplot2}
covid_zip |> 
  ggplot(aes(x = per_pov, y = r_death)) +
  geom_point(color = "grey50",
             size = 0.8) +
  geom_smooth(method = "lm",
              color = "darkred",
              linetype = "dashed",
              linewidth = .4,
              se = FALSE) +
  theme_minimal() +
  labs(title = "Relationship between Poverty and COVID-19 Death Rate",
       subtitle = "New York City, 2020 - 2021",
       x = "% below Poverty Line",
       y = "Rate")

# Pearson's Correlation Coefficient 
cor.test(covid_zip$per_pov, covid_zip$r_death, method = "pearson")

# Get our centroid 
centroids <-covid_zip |> 
               st_centroid() 

# Select Color Pal
display.brewer.all(type = "seq")

# Natural break jenks 
jenks_breaks <- classIntervals(covid_zip$per_pov, n = 5, style = "jenks")$brks

# Base map
ggplot() +
  geom_sf(data = covid_zip,
          aes(fill = per_pov),
          color = NA) +
  scale_fill_fermenter(direction = 1,
                       palette = "Purples",
                       breaks = jenks_breaks,
                       guide = "legend") +
  theme_void()


# Add the centroid layer 
ggplot() +
  geom_sf(data = covid_zip,
          aes(fill = per_pov),
          color = NA) +
  scale_fill_fermenter(direction = 1,
                       palette = "Purples",
                       breaks = jenks_breaks,
                       guide = guide_legend(guide = "legend",
                                            title = "Rate")) +
  geom_sf(data = centroids,
          aes(size = r_death),
          color = "#40E0D0",
          alpha = 0.7) +
  scale_size_continuous(breaks = c(300, 400, 800, 1228),
                        range = c(0.01, 4),
                        name = "Death Rate")

# Add final elements 
ggplot() +
  geom_sf(data = covid_zip,
          aes(fill = per_pov),
          color = NA) +
  scale_fill_fermenter(direction = 1,
                       palette = "Purples",
                       breaks = jenks_breaks,
                       guide = guide_legend(guide = "legend",
                                            title = "Rate")) +
  geom_sf(data = centroids,
          aes(size = r_death),
          color = "#40E0D0",
          alpha = 0.7) +
  scale_size_continuous(breaks = c(300, 400, 800, 1228),
                        range = c(0.01, 4),
                        name = "Death Rate") +
  geom_sf(data = NYC,
          color = "black",
          fill = NA) +
  labs(title = "Percent Poor and COVID-19 Death Rate",
       subtitle = "New York City, 2020-2021",
       caption = "Author: Tobechi Dimkpa \n Source: NYC DOH \n Date:March 26 2025") +
  theme_void() +
  theme(plot.title = element_text(size = 13),
        plot.title.position = "plot",
        plot.subtitle = element_text(size = 11,
                                     face = "italic"),
        legend.title = element_text(size = 12),
        legend.position = c(0.2, 0.68),
        legend.key.size = unit(.4, 'cm'),
        plot.caption = element_text(colour = "grey50",
                                    size = 8,
                                    vjust = 15,
                                    hjust = .95)) +
  annotation_north_arrow(height = unit(.8, "cm"),
                         width = unit(.6, "cm"),
                         pad_x = unit(0.6, "in"), 
                         pad_y = unit(0, "in"),
                         style = north_arrow_minimal) +
  annotation_scale(style = "ticks",
                   pad_x = unit(1, "in"),
                   pad_y = unit(.05, "in"),
                   unit_category = "imperial",
                   width_hint = .2) -> map1

# Export and submit it as part of Assignment 8
ggsave(map1,
       filename = "bivariate_map.jpg",
       width = 6,
       height = 6)



#### Bivariate Map ----
# Classify our data
bi_zip <- bi_class(covid_zip, 
                   x = per_pov, 
                   y = r_death, 
                   style = "quantile",
                   dim = 3)

# Map it!
ggplot () +
  geom_sf(data = bi_zip, 
          aes(fill = bi_class), 
          color = NA, 
          linewidth = 0.1, 
          show.legend = FALSE)

# Preview bivariate color palette  
bi_pal(pal = "GrPink", dim = 3)
?bi_pal

# Create map 
ggplot () +
  geom_sf(data = bi_zip, aes(fill = bi_class), 
          color = NA, 
          show.legend = FALSE) +
  bi_scale_fill(pal = "GrPink", dim = 3) +
  geom_sf(data = NYC,
          color = "black",
          fill = NA) +
  labs(title = "COVID-19 Death Rate and Poverty",
       subtitle = "New York City, 2020 - 2021",
       caption ="Author: Tobechi Dimkpa \n Source: NYC DOH, US CENSUS \n Date:March 26 2025") +
  theme_void() + 
  theme(plot.title = element_text(size = 13),
        plot.title.position = "plot",
        plot.subtitle = element_text(size = 11,
                                     face = "italic"),
        legend.title = element_text(size = 12),
        legend.position = c(0.2, 0.68),
        legend.key.size = unit(.4, 'cm'),
        plot.caption = element_text(colour = "grey50",
                                    size = 8,
                                    vjust = 11,
                                    hjust = .95)) -> map2

# Create bivariate legend 
bi_legend(pal = "GrPink",
          dim = 3,
          xlab = "Percent Poor",
          ylab =  "COVID-19 Deaths",
          size = 8) -> legend 

# Add it as an inset with {patchwork}
map2 +
  inset_element(legend, left = 0.05, bottom = 0.45,
                        right = 0.43, top = 0.85) -> bi_map

# Export it and submit it for Assignment 8
ggsave(bi_map,
       filename = "bi_map.jpg",
       width = 6,
       height = 6)


#### Bivariate Moran's I -------
# Calculate Spatial Lag  of poverty
covid_zip <- covid_zip |>
               mutate(nb = st_knn(geometry, 3),           # Identify neighbors
                      wt = st_weights(nb, 
                             allow_zero = TRUE,           # Allow empty neighbor sets
                             style = "W"),                # Row standardized 
                      pov_lag = st_lag(per_pov, nb, wt))  # Calculate spatial lag
              
# Summary
summary(covid_zip$r_death)
summary(covid_zip$pov_lag)



# Base-map of death rates
ggplot() +
  geom_sf(data = covid_zip,
          aes(fill = r_death),
          color = NA) +
  scale_fill_viridis_c() +
  theme_void() -> mortality


# Base-map of lagged poverty
ggplot() +
  geom_sf(data = covid_zip,
          aes(fill = pov_lag),
          color = NA) +
  scale_fill_viridis_c() +
  theme_void() -> lag_poverty

mortality + lag_poverty

# Scatter plot 
# standardize X and Y
covid_zip |>
  mutate(death_std = (r_death - mean(r_death, na.rm = TRUE)) / sd(r_death, na.rm = TRUE),
         lag_pov_std = (pov_lag - mean(pov_lag, na.rm = TRUE)) / sd(pov_lag, na.rm = TRUE)) -> covid_zip


ggplot(covid_zip, 
       aes(x = death_std, y = lag_pov_std)) +
  geom_point(alpha = .5) +
  geom_hline(yintercept = 0, color = "grey20", linetype = "dashed") + 
  geom_vline(xintercept = 0, color = "grey20", linetype = "dashed") +  
  geom_smooth(method = "lm", color = "red",  linewidth = 0.5, se = FALSE) +  # Regression line
  theme_minimal()


# Global Bivariate Morans i
global_moran_bv(covid_zip$r_death,
                covid_zip$per_pov,
                covid_zip$nb,
                covid_zip$wt) -> bv_gmorans
print(bv_gmorans)
plot(bv_gmorans)


# Bivariate Morans I
covid_zip <- covid_zip |>
                  mutate(biv_local_moran_I = local_moran_bv(r_death, per_pov,
                                                            nb, 
                                                            wt, 
                                                            nsim = 999)) |> 
                  unnest(biv_local_moran_I)         

# Classify the clusters and filter by High-High and Low-Low
covid_zip |> 
         mutate(cluster_type = case_when(
                    p_sim < 0.05 & death_std > 0 & lag_pov_std > 0 ~ "High-High",
                    p_sim < 0.05 & death_std < 0 & lag_pov_std < 0 ~ "Low-Low",
                    p_sim < 0.05 & death_std > 0 & lag_pov_std < 0 ~ "High-Low",
                    p_sim < 0.05 & death_std < 0 & lag_pov_std > 0 ~ "Low-High",
                    TRUE ~ "Not significant")) |> 
        filter(cluster_type %in% c("High-High", "Low-Low"))-> sel_clusters
   
# Base Map
ggplot() +
  annotation_map_tile(type = "cartolight", zoomin = 0) +
  geom_sf(data = sel_clusters,
          aes(fill = cluster_type),
          alpha = 0.8,
          color = NA) +
  scale_fill_manual(values = c("#FF0000", "#0000FF")) + 
  geom_sf(data = NYC,
        color = "black",
        fill = NA) 


# Add final elements 
ggplot() +
  annotation_map_tile(type = "cartolight", zoomin = 0) +
  geom_sf(data = sel_clusters,
          aes(fill = cluster_type),
          alpha = 0.8,
          color = NA) +
  scale_fill_manual(values = c("#FF0000", "#0000FF")) + 
  geom_sf(data = NYC,
          color = "black",
          fill = NA) +
  labs(title = "Spatial Clusters of COVID-19 Mortality and Poverty in NYC",
       subtitle = "Significant Bivariate Local Moran's I, 2020–2021",
       fill = "Clusters",
       caption = "Author: Tobechi Dimkpa \n Source: NYC DOH \n Date:March 26 2025") +
  theme_void() +
  theme(plot.title = element_text(size = 13),
        plot.title.position = "plot",
        plot.subtitle = element_text(size = 11,
                                     face = "italic"),
        legend.position = "bottom",
        plot.caption = element_text(colour = "grey10",
                                    size = 8,
                                    vjust = 35,
                                    hjust = .95)) + 
  annotation_north_arrow(height = unit(.8, "cm"),
                         width = unit(.6, "cm"),
                         pad_x = unit(0.6, "in"), 
                         pad_y = unit(0, "in"),
                         style = north_arrow_minimal) +
  annotation_scale(style = "ticks",
                   pad_x = unit(1, "in"),
                   pad_y = unit(.05, "in"),
                   unit_category = "imperial",
                   width_hint = .2) -> map3

# Export and submit as HW 8
ggsave(map3,
       filename = "bi_cluster_nyc.jpg",
       width = 6,
       height = 6)
        
















