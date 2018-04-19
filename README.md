# abod

## General 

The general idea of outlier detection is to identify data objects that do not fit well in the general data distributions. Angle-Based Outlier Detection (**ABOD**) [1] is an unsupervised anomaly detection (also outlier detection) method, created to be applied in high-dimensional data. Existing approaches are usually based on an assessment of distances, ABOD approach assesses the variance in the angles between the difference vectors of a point to the other points. In this way, the effects of dimensionality are alleviated compared to purely distance-based approaches.

The algorithms presented in [1] (*ABOD*, *FastABOD* and *LB-ABOD*) have been implemented in C. Then, the most expensive functions have been translated to assembly code reaching really high performances.


[1] Hans-Peter Kriegel, Matthias Schubert, Arthur Zimek. 2008. *Angle-Based Outlier Detection in High-Dimensional Data*. In Proceedings of the 14th ACM SIGKDD *International Conference on Knowledge Discovery and Data Mining* (KDD '08). ACM, New York, NY, USA, 444-452.

## Usage

To compile and run

./abod32c <*file_name*> [-d]\[-s]\[-k <*k_value*>]

and

./abod64c <*file_name*> [-d]\[-s]\[-k <*k_value*>]

Parameters:
 - -d : display input and output
 - -s : silent
 - -k <k_value> : number of nearest neighbors for FastABOD
 - -<method>, where <method> can be:
	- abod (for **ABOD**; default)
	- fastabod (for **FastABOD**)
	- lbabod (for **LB-ABOD**)
    
### Note:    
- type the filename without extension;
- some datasets are provided in the folder *datasets*: toy.dataset, ionosphere.dataset and ionosphere2d.dataset;  
- be sure to install *nasm* and *gcc-multilib* packages before running the code.


    
