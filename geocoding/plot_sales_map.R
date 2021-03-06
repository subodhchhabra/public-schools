################################################################
##                      Mapping The Data                      ##
################################################################
# This file maps the original data and also data acquired from
  # model_sales_and_schools. To see the prediction data on the map,
  # please run that file first to get the prediction data.

# Grab source and libraries
source("find_school_district_by_address.R")
library(RColorBrewer)
library(dplyr)

# Get file paths for necessary shape files
filepath <- "2013_2014_School_Zones_8May2013"
shapefile <- "ES_Zones_2013-2014"

# Load necessary data frames for plotting
load("../pricePremium.RData")
load("../complete_data.RData")
load("../streeteasy/plotData.RData")

# Get school boundaries from NYC opendata shapefiles
school_zone_boundaries <- create_school_mapdata(filepath, shapefile)

# Change to a data.frame for easy plotting
schools_df <- fortify(school_zone_boundaries)
school_zone_boundaries@data$id = rownames(school_zone_boundaries@data)

# Group on what we plan to plot by
eP <- schools_zone_sales %>% group_by(DBN) %>% summarize(num = n())

# Get school boundaries
predictions <- merge(school_zone_boundaries@data, price_premium, by = "DBN", all.y = TRUE)

boundariesandschools <- merge(school_zone_boundaries@data, eP, by = "DBN", all.y=TRUE)
stratByBeds <- merge(school_zone_boundaries@data, plot_data, by = "DBN", all.y=TRUE)

# Inner join to the school data for plotting.
predB <- inner_join(schools_df, predictions)

salesB <- inner_join(schools_df, boundariesandschools)
fakeSalesB <- inner_join(schools_df, stratByBeds)

# Create base map for NYC
nyc_map <- create_city_basemap("New York, NY")
park_slope_map <- create_city_basemap("700 Garfield Street, Park Slope, NY", zoom = 15)


######################################
# Plots for fake data by the premium #
######################################

predC <- mutate(predB, binPremium = cut(mean_premium, 
                                        labels = c('< -$100', '-$100 - $0', '$0 - $100', '> $100'), 
                                        breaks = c(min(mean_premium), -100, 0, 100, max(mean_premium))))


predD <- mutate(predB, binPremium = cut(mean_premium, 
                                        labels = c('< -$150', '-$150 - -$100','-$100 - -$50', '-$50 - $0', '$0 - $50', '$50 - $100', '$100 - $150','> $150'), 
                                        breaks = c(min(mean_premium), -150, -100, -50, 0, 50, 100, 150, max(mean_premium))))


premiumMap2 <- ggmap(nyc_map) + geom_polygon(aes(x=long, y=lat, group=group, fill = binPremium), 
                              size=.2, color="black", 
                              data = predC, alpha=.8) + 
  ggtitle("Premium Costs for Each School Zone\nBased on Neighboring Zones\n") +
  scale_fill_brewer(palette = "RdBu") + guides(fill = guide_legend(title = "Premium")) +
  xlab('') + ylab('') + 
  theme(axis.ticks = element_blank(), axis.text.x=element_blank(), axis.text.y = element_blank(),
        legend.position = c(.2, .8))
ggsave(premiumMap2, file = "../figures/premiumMap2.pdf", width = 5, height = 5)
ggsave(premiumMap2, file = "../figures/premiumMap2.png", width = 5, height = 5)


## Park Slope Map Only
parkSlopePremiumMap2 <- ggmap(park_slope_map) + geom_polygon(aes(x=long, y=lat, group=group, fill = binPremium), 
                                            size=.2, color="black", 
                                            data = filter(predC, DBN == '13K282' | DBN == '15K321' |
                                                          DBN == '15K039') %>% mutate(DBN=droplevels(DBN)), 
                                            alpha=.8) + 
  ggtitle("Premium Costs for Park Slope School Zones\n") +
  scale_fill_brewer(palette = "RdBu") + guides(fill = guide_legend(title = "Premium")) +
  xlab('') + ylab('') + 
  theme(axis.ticks = element_blank(), axis.text.x=element_blank(), axis.text.y = element_blank(),
        legend.position = c(.85, .15))
ggsave(parkSlopePremiumMap2, file = "../figures/parkSlopePremiumMap2.pdf", width = 5, height = 5)
ggsave(parkSlopePremiumMap2, file = "../figures/parkSlopePremiumMap2.png", width = 5, height = 5)


## Predicted Price for 2 BR 2 Bath
prices <- mutate(predB, binPrice = cut(X1, 
                                        labels = c('< $500', '$500 - $1000', '$1000 - $1500', '> $1500'), 
                                        breaks = c(min(X1), 500, 1000, 1500, max(X1))))

price2Bed2Baths <- ggmap(nyc_map) + geom_polygon(aes(x=long, y=lat, group=group, fill = binPrice), 
                                                 size=.2, color="black", 
                                                 data = filter(prices, bedrooms == 2 & baths == 2), alpha=.8) + 
  ggtitle("Predicted Price of 2BR/2BA Apts by District\n") + 
  scale_fill_brewer(palette = "RdBu") + guides(fill = guide_legend(title = "Price Per Square Ft")) +
  xlab('') + ylab('') + 
  theme(axis.ticks = element_blank(), axis.text.x=element_blank(), axis.text.y = element_blank(),
        legend.position = c(.2, .8))
ggsave(price2Bed2Baths, file = "../figures/price2Bed2Baths.pdf", width = 5, height = 5)
ggsave(price2Bed2Baths, file = "../figures/price2Bed2Baths.png", width = 5, height = 5)


#####################################################
# Plot polygons for school zones over the base map
#####################################################

# Map for number of sales by DBN
ggmap(nyc_map) + geom_polygon(aes(x=long, y=lat, group=group, fill = num), 
                                                size=.2, color="black", 
                                                data=salesB, alpha=.8) + ggtitle("Number of Sales By School District") +
  scale_fill_continuous(low="red", high="blue", guide = guide_legend(title = "Number of Sales"))


##################################
# Plots for fake data by bedroom
##################################

# Studios
ggmap(nyc_map) + geom_polygon(aes(x=long, y=lat, group=group, fill = X1), 
                              size=.2, color="black", 
                              data = filter(fakeSalesB, bedrooms == 0), alpha=.8) + 
                              ggtitle("Predicted Price Per Sqft of Studios by district") + 
  scale_colour_brewer("clarity") +
  scale_x_continuous(limits = c(-74.05, -73.8))

# 1 BR
ggmap(nyc_map) + geom_polygon(aes(x=long, y=lat, group=group, fill = X1), 
                              size=.2, color="black", 
                              data = filter(fakeSalesB, bedrooms == 1), alpha=.8) + 
  ggtitle("Predicted Price Per Sqft of 1BRs by district") + 
  scale_colour_brewer("clarity")  +
  scale_x_continuous(limits = c(-74.05, -73.8))

# 2 BR
ggmap(nyc_map) + geom_polygon(aes(x=long, y=lat, group=group, fill = X1), 
                              size=.2, color="black", 
                              data = filter(fakeSalesB, bedrooms == 2, baths == 2), alpha=.8) + 
  ggtitle("Predicted Price of 2BR/2BR Apts by District") + 
  scale_colour_brewer("clarity")  +
  scale_x_continuous(limits = c(-74.05, -73.8))

# 3 BR, just Park Slope
ggmap(nyc_map) + geom_polygon(aes(x=long, y=lat, group=group, fill = X1), 
                              size=.2, color="black", 
                              data = filter(fakeSalesB, bedrooms == 3, neighborhood == "Park Slope"), alpha=.8) + 
  ggtitle("Predicted Price Per Sqft of 3BR by district") + 
  scale_x_continuous(limits = c(-74.05, -73.8)) + scale_colour_brewer("clarity")
