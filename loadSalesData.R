########################################
# load libraries
########################################
library(dplyr)
library(xlsx)
library(readxl)
library(ggplot2)
library(tidyr)

# set the data directory
data_dir <- '.'

########################################
# load and clean trip data
########################################
xlss <- Sys.glob(sprintf('%s/*.xls', data_dir))
vec <- c("BOROUGH", "NEIGHBORHOOD", "BUILDING_CATEGORY", "TAX_CLASS", 
  "BLOCK", "LOT", "EASEMENT", "BUILDING_CLASS", "ADDRESS", "APT_NUMBER", "ZIP_CODE", "RES_UNITS", "COM_UNITS", "TOTAL_UNITS", 
  "LAND_SQ_FT", "BUILD_SQ_FT", "YEAR_BUILT", "TAX_CLASS_AT_SALE", 
  "BUILD_CLASS_AT_SALE", "SALE_PRICE", "SALE_DATE")

# Load each year of sales data into one data frame
df2 <- data.frame()
for (xls in xlss) {
  tmp <- read_excel(xls, col_names = vec, skip = 5)
  df2 <- rbind(df2, tmp)
}

# Clear up extra NA data that shows up in the file
df2 <- na.omit(df2)

# Separate out the Building Code number from the text
states <- df2$BUILDING_CATEGORY
s <- substr(x = states, start = 1, stop = 2)
# Add the new building code number to the dataframe as an int
df2$BC_NUM <- as.numeric(s)
View(df2)

# Cut out all commercial buildings from the data
df3 <- df2[df2$BC_NUM<17 & df2$BC_NUM != 5 & df2$BC_NUM != 6,]

# Those with actual sales, not transfers for free
dfc <- df3[df3$SALE_PRICE > 0, ]


################################################################
### The names of these in the data file sales.Rdata are thus ###
################################################################
# The full sales data, without any removals
fullSales <- df2

# The sales only on housing buildings
homeSales <- df3

# Home Data that contains a real sale/no sales <= 0
trueHomeSales <- dfc
###########################

###############################
# Create refactored data
###############################

# Add Data Frame Fields for IsRes and IsIndv
# Rename file for shortness
df <- fullSales

##### Separate out the APT_NUM #####
df <- separate(df, ADDRESS, into = c("ADDRESS", "APTNUM"), sep = ",", remove = TRUE, extra = "drop")

# Change empty strings/NA to something. Might not be needed.
df$APTNUM[is.na(df$APTNUM)] <- " "
df$APT_NUMBER[df$APT_NUMBER == ""] <- " "

# Now merge into one column, making a unified APT_NUM column
df <- unite(df, col = "APT_NUM", c(10,11), sep = " ", remove = TRUE)

# Convert empty strings back to NA for making an isIndividual colum
df$APT_NUM[df$APT_NUM == "              "] <- NA

# Separate by individuality or not
df <- mutate(df, "isRes" = (BC_NUM <= 4 | BC_NUM == 7 | BC_NUM == 10 | BC_NUM == 14))

# Separate by residential or not
df <- mutate(df, "isIndv" = (BC_NUM <= 3 | (BC_NUM == 7 & !is.na(APT_NUM)) | (BC_NUM == 10 & !is.na(APT_NUM)) | (BC_NUM == 14 & !is.na(APT_NUM)) ))

# Separate into 3 frames, including the true home sales and the home sales
fullSalesRef <- df
homeSalesRef <- df[df$BC_NUM<17 & df$BC_NUM != 5 & df$BC_NUM != 6,]
trueHomeSalesRef <- homeSalesRef[homeSalesRef$SALE_PRICE > 0, ]


#################################
# Save the files
#################################

# To save the files yourself, otherwise you already have them
save(fullSales, homeSales, trueHomeSales, file = sprintf('%s/sales.RData', data_dir))
# Refactored save
save(fullSalesRef, homeSalesRef, trueHomeSalesRef, file = sprintf('%s/refactoredSales.RData', data_dir))
