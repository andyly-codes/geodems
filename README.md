# geodems
## Creating a bespoke geodemographic classification for marketing purposes

The aim of this task is to great a geodemographic classification to target a specific niche customer base for a start-up company. 
The start-up is a premium babyseat manufacturer and would like to market their product to young affluent families in London. 
The maps are build using tmap package - I find the aesthetic is super clean and the layering is familiar to ArcGIS.  

The main tasks are:
* selecting the variables 
* create customer segments using unsupervised clustering algorithm 
* visualise where the segments are based on cluster assignment 

## Choosing the variables
This is probably the most important step in the process. When variables are chosen you must justify why they should be used according to the brief (supported by literature where necessary). 

From the data avaialble I went for: 
* a range of ages - as a good indicator of lifestyle
* homeownership - people who own their home are more likely to have higher income
* renters - nowadays London has a higher proportion of young families who rent
* average income - demographic info used for 
* car ownership - need a car to use a car seat :) 
* 'higher-skilled' jobs - these are jobs classified by the government that are likely to earn more 
* young children - young children will be using this product   

Variables should be checked for multicollinearity prior to clustering. 
Definition of high correlation is up to individual but I've gone for > 0.8. 

![corellogram](https://github.com/andyly-codes/geodems/blob/master/corellogram.svg)

## K-means clustering 
There are different methods for choosing 'k', such as elbow, silhouette etc. 
In this elbow plot, the algorithm suggests a k of 4. 
However, I didn't think the clusters were distinguished enough,
so went for 5 cluster in the end. 


## Checking clusters 
Box & whiskers visualise the tightness of the clusters & outliers 

![boxwhisker](https://github.com/andyly-codes/geodems/blob/master/Rplot61.svg)

A summary of z-scores highlights certain characteristics within your clusters 

![boxwhisker](https://github.com/andyly-codes/geodems/blob/master/Rplot65.svg)

## Visualising the clusters

Following k-means clustering, append the assigned clusters to the corresponding MSOAs to get a map of all clusters. 
![Clusters](https://github.com/andyly-codes/geodems/blob/master/Rplot52.svg)

You can also assign the target cluster with a specific colour so it really stands out
![Target](https://github.com/andyly-codes/geodems/blob/master/Rplot59.svg)
