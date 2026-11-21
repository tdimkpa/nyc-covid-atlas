# ------------------------------------------------------------------
# Portability note: install.packages() calls were removed from this
# script. Install the packages listed in the README before running,
# then run the script from this folder (paths are relative).
# ------------------------------------------------------------------

#################### Geographically-Weighted Regression ########################

#### Set up your working environment ----

# Install packages

# Load packages
library(tidyverse)
library(sf)
library(RColorBrewer)
library(patchwork)
library(classInt)
library(spgwr)
library(jtools)



# Set working directory
# NOTE: the original setwd() call was removed for portability.
# Run this script from this project folder; all file paths below are relative.


# Read shps
data <- st_read("NYC_zip_COVID.shp") 


#### Exploratory Data Analysis ----

# Scatter plot 
data |> 
  ggplot(aes(x = per_ssn,  y = deth_rt)) +
  geom_point() + 
  labs(title = "Percent Essential Worker and COVID-19 Death Rate",
       x = "Percent Essential Worker",
       y = "Death Rate") +
  theme_minimal() +
  theme(legend.position = "bottom")

# Scatter plot - color by borough 
data |> 
  ggplot(aes(x = per_ssn,  y = deth_rt, color = CovidZip_2)) +
  geom_point() + 
  labs(title = "Percent Essential Worker and COVID-19 Death Rate",
       x = "Percent Essential Worker",
       y = "Death Rate",
       color = "Borough") +
  theme_minimal() +
  theme(legend.position = "bottom")

# Add linear fit and facet
data|> 
  ggplot(aes(x = per_ssn,  y = deth_rt, color = CovidZip_2)) +
  geom_point() + 
  geom_smooth(method = lm, se = FALSE) +
  labs(title = "Percent Essential Worker and COVID-19 Death Rate",
       x = "Percent Essential Worker",
       y = "Death Rate",
       color = "Borough") +
  facet_wrap(~CovidZip_2)  +
  theme_minimal() +
  theme(legend.position="bottom")


# Percent 65yrs and above 
data |> 
  ggplot(aes(x = pr_pp65,  y = deth_rt, color = CovidZip_2 )) +
  geom_point() + 
  labs(title = "Percent over 65yrs and COVID-19 Death Rate",
       x = "Percent over 65yrs",
       y = "Death Rate",
       color = "Borough") +
  theme_minimal() +
  theme(legend.position="bottom")



# Add linear fit and facet
data |> 
  ggplot(aes(x = pr_pp65,  y = deth_rt, color = CovidZip_2 )) +
  geom_point() + 
  geom_smooth(method = lm, se = FALSE) +
  labs(title = "Percent over 65yrs and COVID-19 Death Rate",
       x = "Percent over 65yrs",
       y = "Death Rate",
       color = "Borough") +
  facet_wrap(~CovidZip_2)  +
  theme_minimal() +
  theme(legend.position="bottom")


#### Multiple Regression ----
# Run the model
mreg <- lm(deth_rt ~ pr_pp65 + per_ssn + pr_hghd + med_inc  + pr_pbtr,
           data = data) 

# Display model results
summary(mreg)

# Plot results 
plot_summs(mreg, scale = TRUE, inner_ci_level = .95)

# Model fit 
AIC(mreg)


#### Geographically-Weighted Regression ----

# Fixed Bandwidth 
class(data)
data <- as_Spatial(data)


fixed_bw <- gwr.sel(deth_rt ~ pr_pp65 + per_ssn + pr_hghd + med_inc  + pr_pbtr,
               data = data, 
               adapt= FALSE, 
               gweight = gwr.Gauss,
               verbose = TRUE)


fbw_gwr <- gwr(deth_rt ~ pr_pp65 + per_ssn + pr_hghd + med_inc  + pr_pbtr,
               data = data, 
               bandwidth = fixed_bw,
               gweight= gwr.Gauss,
               hatmatrix=TRUE, 
               se.fit=TRUE)

print(fbw_gwr)

# What is in this object?
names(fbw_gwr)

# Grab results 
results <- fbw_gwr$SDF

class(results)

# Turn it back to sf object
results |> 
  st_as_sf() -> results.sf

class(results.sf)

#### Mapping Results ----

# Local R2
# Setting our breaks 
r2breaks <- classIntervals(results.sf$localR2, n = 4, style = "jenks")$brks

ggplot() +
  geom_sf(data = results.sf,
          aes(fill = localR2),
          color = NA) +
  scale_fill_fermenter(direction = 1,
                       palette = "BuPu",
                       breaks = r2breaks,
                       labels = c("0.56", "0.64", "0.71", "0.79", "0.86"),
                       guide = guide_colorbar(barwidth = 10, 
                                              barheight = 1, 
                                              ticks.colour = "white", 
                                              ticks.linewidth = 0.5)) + 
  labs(title = "Local R-Square",
       fill = "R2",
       caption = "Author: Tobechi Dimkpa \n Sources: NYC Health \n Date: April 9 2025") +
  theme_void() +
  theme(plot.title = element_text(size = 18),
        legend.position = "bottom",
        legend.key.size = unit(.6, 'cm'),
        plot.caption = element_text(colour = "grey50",
                                    size = 8,
                                    vjust = 0,
                                    hjust = .9))  -> localr2

# Export as jpg and submit as part of Assignment 10
ggsave(localr2,
       filename = "localr2_plot.jpg",
       width = 4.5,
       height = 6)

  
# Percent 65yrs and over 
p65breaks <- classIntervals(results.sf$pr_pp65, n = 4, style = "jenks")$brks

ggplot() +
  geom_sf(data = results.sf,
          aes(fill = pr_pp65),
          color = NA) +
  scale_fill_fermenter(direction = 1,
                       palette = "BuPu",
                       breaks = p65breaks,
                       labels = c("11.5", "15.3", "20.5", "24.6", "29.5"),
                       guide = guide_colorbar(barwidth = 10, 
                                              barheight = 1, 
                                              ticks.colour = "white", 
                                              ticks.linewidth = 0.5)) + 
  labs(fill = "Coefficient") +
  theme_void() +
  theme(legend.position = "bottom",
        legend.key.size = unit(.3, 'cm')) -> a1



# Determining statistical significance
results.sf |> 
  mutate(tval_65 = pr_pp65 / pr_pp65_se,
         t_65_cat = cut(tval_65,
                        breaks = c(-Inf, -2, 2, Inf),
                        labels = c("Significant", "Non-significant", "Significant"))) -> results.sf

# Mapping statistical significance
ggplot() +
  geom_sf(data = results.sf,
          aes(fill = t_65_cat),
          color = NA) +
  scale_fill_manual(values = c("#f88a7f", "#00a1d5")) + 
  theme_void() +
    labs(fill = "",
         caption = "Author: Tobechi Dimkpa \n Sources: NYC Health \n Date: April 9 2025") +
    theme_void() +
    theme(plot.title = element_text(size = 18),
          legend.position = "bottom",
          legend.key.size = unit(.6, 'cm'),
          plot.caption = element_text(colour = "grey50",
                                      size = 8,
                                      vjust = 0,
                                      hjust = .9)) -> a2
  
a1 + a2

a1 + a2  +
  plot_annotation(title = "Effect of % 65yr and Above")  &
  theme(text = element_text(size = 14)) -> plota

# Export as jpg and submit as part of Assignment 10
ggsave(plota,
       filename = "p65_plot.jpg",
       width = 7,
       height = 5.5)


# Percent Essential Workers
essbreaks <- classIntervals(results.sf$per_ssn, n = 4, style = "jenks")$brks

ggplot() +
  geom_sf(data = results.sf,
          aes(fill = per_ssn),
          color = NA) +
  scale_fill_fermenter(direction = 1,
                       palette = "BuPu",
                       breaks = essbreaks,
                       labels = c("-0.88", "1.58", "4.30", "7.9", "13.2"),
                       guide = guide_colorbar(barwidth = 10, 
                                              barheight = 1, 
                                              ticks.colour = "white", 
                                              ticks.linewidth = 0.5)) + 
  labs(fill = "Coefficient") +
  theme_void() +
  theme(legend.position = "bottom",
        legend.key.size = unit(.3, 'cm')) -> b1



# Determining statistical significance
results.sf |> 
  mutate(tval_essen = per_ssn / per_ssn_se,
         t_essen_cat = cut(tval_essen,
                        breaks = c(-Inf, -2, 2, Inf),
                        labels = c("Significant", "Non-significant", "Significant"))) -> results.sf

# Mapping statistical significance
ggplot() +
  geom_sf(data = results.sf,
          aes(fill = t_essen_cat),
          color = NA) +
  scale_fill_manual(values = c("#f88a7f", "#00a1d5")) + 
  theme_void() +
  labs(fill = "",
       caption = "Author: Tobechi Dimkpa \n Sources: NYC Health \n Date: April 9 2025") +
  theme_void() +
  theme(plot.title = element_text(size = 18),
        legend.position = "bottom",
        legend.key.size = unit(.6, 'cm'),
        plot.caption = element_text(colour = "grey50",
                                    size = 8,
                                    vjust = 0,
                                    hjust = .9)) -> b2

b1 + b2 +
  plot_annotation(title = "Effect of % Essential Worker")  &
  theme(text = element_text(size = 14)) -> plotb


# Export as jpg and submit as part of Assignment 10
ggsave(plotb,
       filename = "pessential_plot.jpg",
       width = 7,
       height = 5.5)











