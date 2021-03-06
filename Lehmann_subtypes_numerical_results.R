################################################################################
# This script receives an expression matrix with HGNC as gene ids
# and returns the Lehman subtype and stromal properties according STROMA4 package
## Author: Raúl Alejandro Mejía Pedroza github: https://github.com/raulmejia
################################################################################
# Installing and loading the required libraries
if (!require("BiocManager")) {
  install.packages("BiocManager", ask =FALSE)
  library("BiocManager")
}
if (!require("utils")) {
  install.packages("utils", ask =FALSE)
  library("utils")
}
if (!require("STROMA4")) {
  BiocManager::install("STROMA4", ask =FALSE)
  library("STROMA4")
}
if (!require("breastCancerMAINZ")) {
  BiocManager::install("breastCancerMAINZ", ask =FALSE)
  library("breastCancerMAINZ")
}
if (!require("Biobase")) {
  BiocManager::install("Biobase", ask =FALSE)
  library("Biobase")
}

###########################################
# DATA INPUT given by the user
###########################################
args <- commandArgs(trailingOnly = TRUE)
Path_to_your_Matrix<-args[1] # The path to your matrix
# Path_to_your_Matrix<-c("../Results/Splited/Submatrices_ohne_controls/Subexpression_matrix_Basal_from_METABRIC_.tsv") ; Path_of_Code<-c("./"); Path_of_Results<-c("../Results/Lehmann-STROMA4/METABRIC/"); Label_for_Results <-"METABRIC-only-Basals" ; Do_you_want_log2 <- "no" ; mymc.cores <- 7 
# Path_to_your_Matrix<-c("../Results/Splited/Submatrices_ohne_controls/Subexpression_matrix_Basal_from_TCGA_.tsv") ;     Path_of_Code<-c("./"); Path_of_Results<-c("../Results/Lehmann-STROMA4/TCGA/"); Label_for_Results <-"TCGA-only-Basals" ; Do_you_want_log2 <- "yes" ; mymc.cores <- 7 
Path_of_Code<-args[2] # The path to your code, scripts and so on ...
Path_of_Results<-args[3] # where do you want to save your results?
Label_for_Results<-args[4] # Label for your results
# If you use windows and you have troubles with your paths, please try out this tool: # Path_of_x <-choose.dir()
Do_you_want_log2 <- args[5] # Do you want that yor samples will be log2 tranformed by this program?
mymc.cores <- args[6] # Number of cores for use in your task

#########################
## Coercing some data given by the user
#########################
Do_you_want_log2 <- as.character(Do_you_want_log2)
mymc.cores <- as.numeric( mymc.cores )

###################
## Reading the data
###################
myeMatrix <- read.table( Path_to_your_Matrix, sep= "\t", header=TRUE, row.names = 1, quote = "" , stringsAsFactors = FALSE)
# getwd() ; setwd("/mnt/saveit/ABCB1_code")

########################################3
#### Eliminating the indicator row, labeled as "NORMALS" and the rows with orphan id's "ILMN" 
#########################################
if( length( which(rownames(myeMatrix) %in% "NORMALS") ) == 1 ){
  pos_Normals <- which( rownames(myeMatrix) %in% "NORMALS")
  myeMatrix <- myeMatrix[ -pos_Normals, ]
}
if( length( which(rownames(myeMatrix) %in% "NORMAL") ) == 1 ){
  pos_Normals <- which( rownames(myeMatrix) %in% "NORMAL")
  myeMatrix <- myeMatrix[ -pos_Normals, ]
}

ILMN_Pos <- grepl( "ILMN" , rownames(myeMatrix) )
myeMatrix <- myeMatrix[!ILMN_Pos , ]

###################################
### log-2 tranforming
###################################
#a <- matrix(rnorm(100,5000,5000), ncol= 10)

if(Do_you_want_log2 == "yes"){
    myeMatrix <- log2(myeMatrix + 1)
    print("The current program has just transformed your matrix to log2 scale")
    myeMatrix[1:10,1:7]
}else if(Do_you_want_log2 == "no"){
    myeMatrix <- myeMatrix
    print("Your matrix has NOT been log2 transformed by this program")
    myeMatrix[1:10,1:7]
}else{
    print("Please especify if you want \"yes\" or \"no \" that this program tranform your data in a log2 scale")
}

#################################
## Creating the Feature data as an annotated DataFrame
################################
myFeatureData <- data.frame( Gene.symbol = rownames(myeMatrix), row.names = rownames(myeMatrix) )
myFeatureData <- as.data.frame(myFeatureData)
My_fData_Anotdf <- AnnotatedDataFrame( data=myFeatureData)
validObject(My_fData_Anotdf)

#################################################
######## Creating the PhenoData as an annotated data frame  
##################################################
myPhenoData <- data.frame( Patienten_id = colnames(myeMatrix), row.names = colnames(myeMatrix) )
My_pData_Anotdf <- AnnotatedDataFrame( data= myPhenoData)
validObject(My_pData_Anotdf)

##################################
## building an ExpressionSet
##################################
myExpressionSet1<- ExpressionSet(as.matrix(myeMatrix), phenoData=My_pData_Anotdf , featureData=My_fData_Anotdf )
#myExpressionSet2<- ExpressionSet( as.matrix(myeMatrix) , phenoData=annotatedDataFrameFrom(as.matrix(myeMatrix), byrow=FALSE), featureData=annotatedDataFrameFrom( as.matrix(myeMatrix), byrow=TRUE))

##################################
# Running the core function
##################################
# just.stromalp <- assign.properties(ESet=myExpressionSet1, geneID.column="Gene.symbol", genelists="Stroma4", n=10, mc.cores= mymc.cores)
# just.lehmanp <- assign.properties(ESet=myExpressionSet1, geneID.column="Gene.symbol", genelists="TNBCType", n=70, mc.cores= mymc.cores)
allp <- assign.properties(ESet=myExpressionSet1, geneID.column="Gene.symbol", genelists=c("Stroma4", "TNBCType"), n=70, mc.cores= mymc.cores)

###################################
##  converting the results from STROMA4 ("high", "intermediate", "low") to  numerical (-1, 0 , 1)
##################################
numericalallp <- pData(allp)
#head(numericalallp)
#head(pData(allp))
numericalallp <- numericalallp[,-which(colnames(numericalallp) %in% "Patienten_id")]
char2num <- function(row){
  row <-gsub("low" ,-1,row)
  row <-gsub("intermediate" , 0 ,row)
  row <-gsub("high" , 1 ,row)
  return(as.numeric(row))
}
numericalallp <- apply(numericalallp,1,char2num)
head(numericalallp)
numericalallp <- t(numericalallp)
colnames(numericalallp) <- colnames( pData(allp))[-1]

###################################
##  saving the results
##################################
dir.create( Path_of_Results, recursive = TRUE)

write.table(pData(allp) , file = paste0(Path_of_Results,"Lehmann's_Subt_and_properties_",Label_for_Results,".tsv" ), sep="\t", quote=FALSE , row.names= TRUE, col.names= TRUE )
saveRDS(pData(allp), file = paste0(Path_of_Results,"Lehmann's_Subt_and_properties_",Label_for_Results,".RDS" ))

write.table(numericalallp , file = paste0(Path_of_Results,"Lehmann's_Subt_and_properties_Numerical_",Label_for_Results,".tsv" ), sep="\t", quote=FALSE , row.names= TRUE, col.names= TRUE )
saveRDS(numericalallp, file = paste0(Path_of_Results,"Lehmann's_Subt_and_properties_Numerical_",Label_for_Results,".RDS" ))


# experimentData(mainz)
# exprs(just.stromal.properties)
# sampleNames(mainz)
# head(featureNames(mainz))
# head(pData(mainz))
# featureData(mainz)
# phenoData(mainz)
# varLabels(phenoData(mainz))
#head(varMetadata(mainz))
#pData(allp)
# featureData(mainz)
# fData(mainz)
##### Show me the results ####

#class(featureData(mainz))
#head(pData(featureData(mainz)))
#class(pData(featureData(mainz)))
#row.names(pData(featureData(mainz)))
#head( varMetadata(mainz))
#featureNames(mainz)
#pData(featureNames(mainz))
#data.frame( )

##### Toy example
#library(breastCancerMAINZ)
#data(mainz,package = 'breastCancerMAINZ')
#head(fData(mainz)[,"Gene.symbol",drop=FALSE])
#all.properties <- assign.properties(ESet=mainz, geneID.column="Gene.symbol", genelists=c("Stroma4", "TNBCType"), n=70, mc.cores=7)

