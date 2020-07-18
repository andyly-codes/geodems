#Packages 

library(tidyverse)
library(readxl)
library(GGally)
library(ggcorrplot)
library(cluster)

#install.packages("usedist")
library("usedist")

#install.packages("NbClust")
library(NbClust)

#install.packages("factoextra")
library(factoextra)

#install.packages("corrplot")
library(corrplot)
source("http://www.sthda.com/upload/rquery_cormat.r")

#read in data

data <- read_excel("./Data/London-MSOA-retailer-data.xlsx")
View(data) 

  
#select the variables to represent group 
selection <- select(data, 1, "Young Children" = 8, "Homeowners" = 43, "Renters" = 45, "Car owner" = 58) %>% 
  mutate("High skill" = rowSums(data[64:66]))

#compute a correlation matrix
cor.mat <- selection[2:6]
corr <- round(cor(cor.mat), 2) 
head(corr)

p.mat <- cor_pmat(cor.mat)

ggcorrplot(corr, hc.order = TRUE, type = "lower",
           lab = TRUE,
           p.mat = p.mat,
           outline.col = "white", 
           ggtheme = ggplot2::theme_gray,
           title = "Correlation matrix between variables",
           colors = c("#6D9EC1", "white", "#E46726"))



#standardize the variables
data.scaled <- scale(cor.mat, center = TRUE, scale = TRUE)

#selecting k for k-means

fviz_nbclust(data.scaled, kmeans, method = "wss")

fviz_nbclust(data.scaled, kmeans, method = "silhouette")

cluster.final <- NbClust(data.scaled, distance = "euclidean", min.nc = 2, max.nc = 30, method = "kmeans")

#clustering
kmeansresult <- kmeans(data.scaled, 4)

print(kmeansresult)

fviz_cluster(kmeansresult, data=data.scaled, geom = "point", show.clust.cent = TRUE, ggtheme = theme_minimal(), repel = TRUE, ellipse.type = "norm")

km <- selection %>% 
  mutate(cluster = kmeansresult$cluster)

#add to scaled table 
final.scaled <- data.frame(data.scaled) %>%
  mutate(cluster = km$cluster)


cluster_data <- data.frame(final.scaled %>%
  group_by(cluster) %>%
  summarise_all("mean"))

#summary 
fill_colours <- c("#ffffff", "#cccccc")
plot <- cluster_data %>%
  gather(key=variable, value=summary, -cluster) %>%
  mutate(
    stat_sign=summary>0
  ) %>%
  ggplot(aes(x=variable, y=summary))+
  # stat_sign is a boolean identifying whether stat_value is pos or neg.
  geom_col(aes(fill=stat_sign), colour="#636363", size=0.3)+
  scale_fill_manual(values=fill_colours, guide=FALSE)+
  facet_grid(cluster~ ., scales="free", space="free_y")+
  labs(title = "Z-score Summary", xlab("Cluster")) + 
  coord_flip()+
  theme(axis.title=element_blank(),
        strip.text.y = element_text(angle=0))


plot

#boxplot
dist1 <- dist(final.scaled[1:5])
centroid.dist <- dist_to_centroids(dist1,km$cluster)
centroid.dist$CentroidGroup <- as.factor(centroid.dist$CentroidGroup)

ggplot(centroid.dist, aes(x=CentroidGroup, y=CentroidDistance, fill=CentroidGroup)) + 
  geom_boxplot() + 
  xlab("Cluster")+ 
  ylab("Distance between observation and centroid") + 
  theme(legend.position = "none") +
  labs(title = "Distance between assigned cluster centroids and observations")

sil <- silhouette(kmeansresult$cluster, dist(data.scaled))
fviz_silhouette(sil)

neg_sil_index <- which(sil[, "sil_width"] < 0)
sil[neg_sil_index, , drop = FALSE]

#######Mapping the clusters 

#import the libraries
library(sf)
library(tmap)
library(reshape2)
library(RColorBrewer)

#read in map shape file
MSOA <- st_read("./Data/LondonMSOA2011/msoa_boundaries.shp") 
cluster_only <- data.frame(km$MSOA, cluster = km$cluster)

#join cluster assignment to shapefile
joined_data <- left_join(MSOA, cluster_only, by =  c("msoa11cd" = "km.MSOA"))
summary(joined_data)

#read in local authority boundaries for extra context 
boundary <- st_read("./Data/LondonLA2011/borough_boundaries.shp")

#vector of boundary abbreviations for key (optional)
#boundary$abr <- c("LAM", "LSH", "MRT", "BRM", "CTY", "BAR", "BRN", "BXL", "BRT", "CMD", "CRD", 
                  #"ELG", "ENF", "GRN", "HCK", "HMS", "HGY", "HRW", "HVG", "HDN", "HNS", "ISL", 
                  #"KNS", "KNG", "NWM", "RDB", "RCH", "SWR", "STN", "TOW", "WTH", "WNS", "WST" )

#convert cluster number to factor
joined_data$cluster <- as.factor(joined_data$cluster)

#name clusters for use in key later
joined_data <- joined_data %>% 
  mutate(Classification = case_when(cluster == 1 ~ "High Earning Professionals", 
            cluster == 2 ~ "Local London Residents", 
            cluster == 3 ~ "Affluent Young Families", 
            cluster == 4 ~ "Average London Workers"))


joined_data$Classification <- as.factor(joined_data$Classification)


  p1 = 
    tm_shape(joined_data)+
    tm_fill(
            "Classification")+
    tm_shape(boundary, is.master = T) +
    tm_layout(main.title = "Geodemographic Classification of London MSOAs", main.title.size = 1.1, legend.position = c("left", "TOP"), legend.outside = T, legend.only = F) + 
    tm_text("abr", size=0.4) +
    tm_add_legend(type = "text", title = "Borough", text = boundary$abr, labels = boundary$lad15nm) +
    tm_borders("grey80") + 
    tm_compass(size = 0.4) +
    tm_scale_bar(width = 0.15) + 
    tm_credits(text = "Data obtained from UK Census 2011. \nBoundary data provided by ONS.", align = "left", position = "LEFT", size = 0.7)
    
  p1
  
#highlights the target cluster for second map
joined_data$cluster1 <- ifelse(joined_data$cluster == 3, "darkorange", "snow2")
  
  p2 = 
    tm_shape(joined_data) +
    tm_fill("cluster1") + 
    tm_borders("grey") +
    tm_layout(legend.position = c("left", "top"), legend.outside = T, main.title = "'Affluent Young Families' in London", title.size = 1.1, legend.text.size = 1.5) + 
    tm_shape(boundary) +
    tm_text("abr", size=0.6) + 
    tm_borders("grey20") + 
    tm_compass(size = 1) + 
    tm_scale_bar(width = 0.15) + 
    tm_credits(text = "Data obtained from 2011 Census.\nMSOA and London borough boundary files obtained from ONS.", align = "left", position = "LEFT")
p2  

