# ------------------------------------------------------------------
# Portability note: install.packages() calls were removed from this
# script. Install the packages listed in the README before running,
# then run the script from this folder (paths are relative).
# ------------------------------------------------------------------

################ Lab 7 - Exploratory Spatial Data Analysis #####################

# Install packages 

# Load packages
library(tidyverse)
library(sf)
library(sfdep)
library(patchwork)
library(ggspatial)
library(classInt)
library(RColorBrewer)

# Set working directory 


# Read data
covid_zip <- st_read("NYC_zip_COVID19.shp")
NYC <- st_union(covid_zip)

# Descriptive statistics for death rate
summary(covid_zip$rate)
hist(covid_zip$rate)

# Base-map of death rates
ggplot() +
  geom_sf(data = covid_zip,
          aes(fill = rate),
          color = NA) +
  scale_fill_viridis_c() +
  geom_sf(data = NYC,
          fill = NA,
          color = "black") +
  theme_void() -> rate
print(rate)

# Calculate Spatial Lag  of death rate
covid_zip <- covid_zip |>
  mutate(nb = st_knn(geometry, 3),          # Identify neighbors
         wt = st_weights(nb, 
                         allow_zero = TRUE, # Allow empty neighbor sets
                         style = "W"),      # Row standardized 
         death_lag = st_lag(rate, nb, wt))  # Calculate spatial lag


# Descriptive statistics for spatial lag of death rate
summary(covid_zip$death_lag)
hist(covid_zip$death_lag)

# Map the lag death rate
ggplot() +
  geom_sf(data = covid_zip,
          aes(fill = death_lag),
          color = NA) +
  scale_fill_viridis_c() +
  geom_sf(data = NYC,
          fill = NA,
          color = "black") +
  theme_void() -> lag

rate + lag


# Visualize this relationship in a scatter plot 
ggplot(covid_zip, 
       aes(x = rate, y = death_lag)) +
  geom_point(alpha = .5) +
  geom_hline(yintercept = 399, color = "grey20", linetype = "dashed") + 
  geom_vline(xintercept = 399, color = "grey20", linetype = "dashed") +  
  geom_smooth(method = "lm", color = "red",  linewidth = 0.5, se = FALSE) +  # Regression line
  theme_minimal()


# Standardize rate and death_lag
covid_zip |>
  mutate(rate_std = (rate - mean(rate, na.rm = TRUE)) / sd(rate, na.rm = TRUE),
         death_lag_std = (death_lag - mean(death_lag, na.rm = TRUE)) / sd(death_lag, na.rm = TRUE)) -> covid_zip


# Visualize this relationship in a scatter plot 
ggplot(covid_zip, 
       aes(x = rate_std, y = death_lag_std)) +
  geom_point(alpha = .5) +
  geom_hline(yintercept = 0, color = "grey20", linetype = "dashed") + 
  geom_vline(xintercept = 0, color = "grey20", linetype = "dashed") +  
  geom_abline(intercept = 0, slope = 1, color = "red", linewidth = .5) +
  theme_minimal()


# Global Morans I
moran_I <- global_moran_perm(covid_zip$rate, 
                             covid_zip$nb, 
                             covid_zip$wt, 
                             alternative = "two.sided",
                             nsim = 999)

print(moran_I)
plot(moran_I)


# Local Moran's I 
covid_zip <- covid_zip |>
                 mutate(local_moran_I = local_moran(rate, nb, wt, nsim = 999, alternative = "two.sided")) |> 
                 unnest(local_moran_I)

ggplot() +
   geom_sf(data  = covid_zip, 
           aes(fill = mean)) +
   scale_fill_manual(values = c("High-High" = "#FF0000", 
                               "Low-Low" = "#0000FF",   
                               "Low-High" = "#66CCFF",   
                               "High-Low" = "#FF99CC",  
                               "Not significant" = "grey90"))

# Scatter plot 
ggplot(covid_zip, 
       aes(x = rate_std, y = death_lag_std, color = mean)) +
  geom_point() +
  geom_hline(yintercept = 0, color = "grey20", linetype = "dashed") + 
  geom_vline(xintercept = 0, color = "grey20", linetype = "dashed") +  
  geom_abline(intercept = 0, slope = 1, color = "red", linewidth = .5) +
  theme_minimal()


# Classify significant clusters
covid_zip |> 
  mutate(cluster_type = case_when(
         mean  == "Low-Low" & p_ii <= 0.05 ~ "Low-Low",
         mean  == "High-Low" & p_ii <= 0.05 ~ "High-Low",
         mean  == "Low-High" & p_ii <= 0.05 ~ "Low-High",
         mean  == "High-High" & p_ii <= 0.05 ~ "High-High",
         TRUE ~ "Not significant")) -> covid_zip

# Map it!
ggplot() +
  geom_sf(data  = covid_zip, 
          aes(fill = cluster_type)) +
  scale_fill_manual(values = c("High-High" = "#FF0000", 
                               "Low-Low" = "#0000FF",   
                               "Low-High" = "#66CCFF",   
                               "High-Low" = "#FF99CC",  
                               "Not significant" = "grey90"))

# Scatter plot 
ggplot(covid_zip, 
       aes(x = rate_std, y = death_lag_std, color = cluster_type)) +
  geom_point() +
  scale_color_manual(values = c("High-High" = "#FF0000", 
                                "Low-Low" = "#0000FF",   
                                "Low-High" = "#66CCFF",   
                                "High-Low" = "#FF99CC",  
                                "Not significant" = "grey90")) +  # 
  geom_hline(yintercept = 0, color = "grey20", linetype = "dashed") + 
  geom_vline(xintercept = 0, color = "grey20", linetype = "dashed") +  
  geom_abline(intercept = 0, slope = 1, color = "red", linewidth = .5) +
  theme_minimal()


# Select the HH and LL clusters
covid_zip |> 
  filter(cluster_type %in% c("High-High", "Low-Low")) -> cluster_map

# Map it!
ggplot() +
  annotation_map_tile(type = "cartolight", zoomin = 0) +
  geom_sf(data = NYC,
          fill = NA,
          color = "black") +
  geom_sf(data = cluster_map,
          aes(fill = cluster_type),
          alpha = 0.8,
          color = NA) +
  scale_fill_manual(values = c("#FF0000", "#0000FF")) +
  labs(title = "Cluster Analysis of COVID-19 Deaths",
       subtitle = "New York City, 2020 - 2021",
       fill = "Clusters",
       caption = "Author: Tobechi Dimkpa \n Source: NYC DOH \n Date:March 12 2025") +
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
                   width_hint = .2) -> map

# Export and submit as HW
ggsave(map,
       filename = "cluster_nyc.jpg",
       width = 6,
       height = 6)






















