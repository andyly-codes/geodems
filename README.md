# geodems
## Creating a bespoke geodemographic classification for marketing purposes

The aim of this task is to great a geodemographic classification to target a specific niche customer base for a start-up company. 
The start-up is a premium babyseat manufacturer and would like to market their product to young affluent families in London. 
The maps are build using tmap package - I find the aesthetic is super clean and the layering is familiar to ArcGIS.  

The main tasks are 1) selecting the variables 
                   2) create customer segments using unsupervised clustering algorithm 
                   3) visualise where the segments are based on cluster assignment 

## Visualising the clusters

Following k-means clustering, append the assigned clusters to the corresponding MSOAs to get a map of all clusters. 
![Clusters](https://github.com/andyly-codes/geodems/blob/master/Rplot52.svg)

You can also assign the target cluster with a specific colour so it really stands out
![Target](https://github.com/andyly-codes/geodems/blob/master/Rplot59.svg)
