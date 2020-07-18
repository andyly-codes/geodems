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

data <- read_excel("London-MSOA-retailer-data.xlsx")
View(data) 

  
#select the variables to represent group 
selection <- select(data, 1, "Young Children" = 8, "Homeowners" = 43, "Renters" = 45, "Car owner" = 58, "Age 30 to 44" = 14, "Age 45 to 59" = 15, "Average Income" = 74) %>% 
  mutate("High skill" = rowSums(data[64:66])) %>% mutate("Age 20 to 29" = rowSums(data[12:13]))

#compute a correlation matrix
cor.mat <- selection[2:10]
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

cluster.final <- NbClust(data.scaled, distance = "euclidean", min.nc = 2, max.nc = 50, method = "kmeans")

#clustering
kmeansresult <- kmeans(data.scaled, 5)

print(kmeansresult)

fviz_cluster(kmeansresult, data=data.scaled, geom = "point", show.clust.cent = TRUE, ggtheme = theme_minimal(), repel = TRUE, ellipse.type = "norm")

km <- selection %>% 
  mutate(cluster = kmeansresult$cluster)

#Summary stats 

km %>%
  group_by(cluster) %>% 
  count(cluster)

km %>%
  group_by(cluster) %>% 
  count(cluster)/983

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
dist1 <- dist(final.scaled[1:10])
centroid.dist <- dist_to_centroids(dist1,km$cluster)
centroid.dist$CentroidGroup <- as.factor(centroid.dist$CentroidGroup)

ggplot(centroid.dist, aes(x=CentroidGroup, y=CentroidDistance, fill=CentroidGroup)) + 
  geom_boxplot() + 
  scale_x_discrete(labels = c("Affluent Young \nFamilies", "Wealthy Professional \nRenters", "Low Income Families", "Hard-up Urbanites", "Well-off Empty Nesters")) +
  xlab("Cluster")+ 
  ylab("Distance between observation and centroid") + 
  theme(legend.position = "none")

sil <- silhouette(kmeansresult$cluster, dist(data.scaled))
fviz_silhouette(sil)

neg_sil_index <- which(sil[, "sil_width"] < 0)
sil[neg_sil_index, , drop = FALSE]

#Mapping my cluster 

#import the libraries
library(sf)
library(tmap)
library(reshape2)
library(RColorBrewer)

MSOA <- st_read("./statistical-gis-boundaries-london/ESRI/MSOA_2011_London_gen_MHW.shp") 
cluster_only <- data.frame(km$MSOA, cluster = km$cluster)

joined_data <- left_join(MSOA, cluster_only, by =  c("MSOA11CD" = "km.MSOA"))
summary(joined_data)

boundary <- st_read("./statistical-gis-boundaries-london/ESRI/London_Borough_Excluding_MHW.shp")
summary(boundary)

wards <- st_read("./statistical-gis-boundaries-london/ESRI/London_Ward.shp")

boundary$abr <- c("LAM", "LSH", "MRT", "BRM", "CTY", "BAR", "BRN", "BXL", "BRT", "CMD", "CRD", "ELG", "ENF", "GRN", "HCK", "HMS", "HGY", "HRW", "HVG", "HDN", "HNS", "ISL", "KNS", "KNG", "NWM", "RDB", "RCH", "SWR", "STN", "TOW", "WTH", "WNS", "WST" )

joined_data$cluster <- as.factor(joined_data$cluster)

joined_data <- joined_data %>% 
  mutate(Classification = case_when(cluster == 5 ~ "Well-off Empty Nesters", 
            cluster == 4 ~ "Hard-up Urbanites", 
            cluster == 1 ~ "Affluent Young Families", 
            cluster == 2 ~ "Wealthy Professional Renters",
            cluster == 3 ~ "Low Income Families"))

joined_data$Classification <- as.factor(joined_data$Classification)

joined_data$cluster1 <- ifelse(joined_data$cluster == 1, "darkorange", "snow2")

  p1 = 
    tm_shape(joined_data)+
    tm_borders("grey", lwd = 0.5, alpha = 0.5) +
    tm_fill(style = "kmeans",
            "Classification")+
    tm_shape(boundary, border.alpha = 0) +
    tm_layout(legend.position = c("left", "bottom"), legend.only = F, frame = F, legend.text.size = 1) + 
    tm_borders("white", lwd = 1.5) + 
    tm_compass(size = 0.4) +
    tm_scale_bar(width = 0.15) 
  
  p1
  
  p2 = 
    tm_shape(joined_data) +
    tm_fill("cluster1") + 
    tm_borders("grey") +
    tm_shape(boundary) +
    tm_borders("white", lwd = 2) + 
    tm_text("abr", labels.text = "abr", size = 0.75) + 
    tm_compass(size = 1.2, text.size = 1) + 
    tm_scale_bar(width = 0.15) + 
    tm_add_legend(type = c("text"), labels = boundary$abr, text = boundary$NAME) +
    tm_layout(legend.outside = T,frame = F, legend.outside.position = "bottom", legend.stack = "horizontal") 
    
    
p2  

p3 = 
  tm_shape(joined_data) +
  tm_polygons(col = "cluster1",
              border.col = "grey") + 
  tm_shape(boundary) +
  tm_borders("white", lwd = 3) + 
  tm_text("NAME", labels.text = "abr", size = 0.8, remove.overlap = T) + 
  tm_compass(size = 1.2, text.size = 1) + 
  tm_scale_bar(width = 0.15, text.size = 0.8) + 
  tm_layout(legend.outside = T,frame = F, legend.outside.position = "right", legend.width = 1)
 

p3 


clusterstats <- filter(km, cluster == 1) 
  summarise(clusterstats)
  