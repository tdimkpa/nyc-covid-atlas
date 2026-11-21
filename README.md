# NYC COVID-19 Spatial Analysis

Spatial analysis of COVID-19 outcomes across New York City ZIP codes (Modified ZIP Code Tabulation Areas, MODZCTA), built in R with supporting maps made in QGIS and GeoDa. The five projects in this repository move from descriptive mapping through cluster detection and bivariate analysis to geographically weighted regression and interactive mapping.

## Contents

- [Mapping risk](#mapping-risk)
- [Exploratory spatial data analysis and clusters](#exploratory-spatial-data-analysis-and-clusters)
- [Bivariate mapping: poverty and COVID-19 deaths](#bivariate-mapping-poverty-and-covid-19-deaths)
- [Geographically weighted regression](#geographically-weighted-regression)
- [Interactive maps](#interactive-maps-code-only)
- [Running the code](#running-the-code)
- [Reproducibility notes](#reproducibility-notes)

---

## Mapping risk

**Folder:** `lab-02-mapping-risk/`

**Question:** How did COVID-19 death rates vary across New York City ZIP codes, and which areas carried the highest relative risk of dying?

**Data:** NYC Department of Health and Mental Hygiene COVID-19 data by MODZCTA (`data-by-modzcta.csv`), joined to MODZCTA boundary polygons.

**Methods:** Choropleth mapping with classified breaks (`classInt`), rate and relative-risk calculation, combined multi-panel figures (`patchwork`).

**Packages:** `tidycensus`, `tidyverse`, `sf`, `RColorBrewer`, `classInt`, `ggspatial`, `patchwork`

**What the maps show:**

- `COVID-19 death rates.png` — COVID-19 death rate per 100,000 residents by ZIP code.
- `combined_plot.jpg` — combined panels including the relative risk of dying from COVID-19 by ZIP code.

## Exploratory spatial data analysis and clusters

**Folder:** `lab-07-esda-clusters/`

**Question:** Was the geography of COVID-19 deaths in NYC spatially clustered, or consistent with a random pattern — and where were the significant clusters?

**Data:** NYC ZIP-code COVID-19 data (`NYC_zip_COVID19.shp`).

**Methods:** Exploratory spatial data analysis — global Moran's I with a permutation test, then Local Moran's I (LISA) with 999 simulations to identify significant high-high, low-low, and outlier ZIP codes (`sfdep`).

**Packages:** `tidyverse`, `sf`, `sfdep`, `patchwork`, `ggspatial`, `classInt`, `RColorBrewer`

**What the maps show:**

- `cluster qgis.png` — LISA cluster map of COVID-19 deaths (QGIS render).
- `cluster_nyc.jpg` — cluster analysis of COVID-19 deaths (R render).

## Bivariate mapping: poverty and COVID-19 deaths

**Folder:** `lab-08-bivariate-mapping/`

**Question:** How does neighborhood poverty relate to COVID-19 death rates across NYC ZIP codes, and is that relationship itself spatially clustered?

**Data:** NYC ZIP-code COVID-19 and poverty data (`NYC_covid19_zip.shp`).

**Methods:** Bivariate choropleth mapping (`biscale`), global and local bivariate Moran's I (`sfdep`).

**Packages:** `tidyverse`, `sf`, `sfdep`, `ggspatial`, `RColorBrewer`, `biscale`, `classInt`, `patchwork`

**What the maps show:**

- `bivariate_qgis.png` — bivariate map of percent poor and COVID-19 death rate (QGIS render).
- `bi_cluster_qgis.png` — bivariate LISA cluster map (QGIS render).
- `bi_cluster_nyc.jpg` — bivariate cluster map (R render).

## Geographically weighted regression

**Folder:** `lab-10-gwr/`

**Question:** Do the drivers of COVID-19 death rates vary across the city — does the same factor matter more in some neighborhoods than in others?

**Data:** NYC ZIP-code COVID-19 data with ZIP-level social determinants (`NYC_zip_COVID.shp`).

**Methods:** Geographically weighted regression with a fixed Gaussian kernel bandwidth (`spgwr`), modelling death rate against predictors including percent of residents over 65, median income, and other ZIP-level social determinants (see the script for the full model formula). Local coefficients and local R² are mapped to show where the model fits well and where relationships are strongest.

**Packages:** `tidyverse`, `sf`, `RColorBrewer`, `patchwork`, `classInt`, `spgwr`, `jtools`

**What the maps show:**

- `pessential_plot.jpg` — local relationship between percent essential workers and COVID-19 death rate.
- `p65_plot.jpg` — local relationship between percent of residents over 65 and COVID-19 death rate.
- `localr2_plot.jpg` — local R², showing where the model explains death rates well and where it does not.

## Interactive maps (code only)

**Folder:** `lab-11-interactive-maps/`

**Question:** How can COVID-19 death clusters and vaccination access be explored interactively, layer by layer, instead of in a static map?

**Data:** COVID-19 death clusters (`clusters_death.shp`) and NYC COVID-19 vaccination sites (`NYC_COVID19_vacc_sites.shp`), both included in the folder.

**Methods:** Interactive web maps built with `leaflet` and `leaflet.extras`, exported as standalone HTML widgets (`htmlwidgets`).

**Packages:** `sf`, `tidyverse`, `leaflet`, `leaflet.extras`, `htmlwidgets`, `classInt`, `RColorBrewer`

**What is included:** The R script (`Lab11.R`) and the two shapefiles it maps. **No rendered map is included for this project — it is code only.** No HTML map export was found in the source files, so there is no map image to show here; running the script produces the interactive map.

## Running the code

Each folder is self-contained: an R script plus its map outputs (and shapefiles, for the interactive-maps project). Requirements:

- R (scripts were written against R 4.x) and QGIS/GeoDa for the QGIS-rendered maps.
- Install the packages listed under each project above before running its script, e.g. `install.packages(c("tidyverse", "sf", ...))`.
- Run each script from inside its own folder — all file paths are relative. The original `setwd()` calls and `install.packages()` lines were removed for portability; see the header comment in each script.

## Reproducibility notes

- The map images are the original rendered outputs; the R scripts reproduce the R-rendered figures.
- Input data files (MODZCTA boundaries, `data-by-modzcta.csv`, and the NYC ZIP-code COVID-19 shapefiles read by the scripts) are **not** included in this repository, except for the two shapefiles in `lab-11-interactive-maps/`. The scripts read them by filename from the working directory, so place the corresponding data files alongside a script before re-running it. Public equivalents: NYC DOHMH COVID-19 data by MODZCTA and NYC Open Data ZIP-code boundaries.
- The interactive-maps script also reads `NYC_covid19_zip.shp`, which is not included here — that layer will need to be supplied to reproduce the full map.
