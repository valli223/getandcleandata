# Analysis and Cleaning of Human Activity Data
Vamsee Addepalli  
4 March 2016  

## Introduction

This document describes the methods by which a certain dataset related to Human Activity has
been obtained, analysed and then tidied for further usage. The document also details the
various variables used in the course of the analysis and also describes the data dictionary
of the final tidy data set.  

The companion script for this code book is - run_analysis.R - which is uploaded in the same
GitHub Repo link as this file is present.  

## Data Processing

Initially, the script performs certain checks to ascertain the files' availability and
initializes certain variables for future usage. Also, the needed libraries are loaded within
this section.  


```r
    library(dplyr)
    library(tidyr)
    library(data.table)

    ## Check if the path provided as input is a valid directory
    if ( ! dir.exists(pth) ) {
        stop("ERROR - Input dir path is not valid !!")
    }
    
    ## Prepare File names
    ### Master Files
    act_fl <- file.path(pth, "activity_labels.txt")
    ftr_fl <- file.path(pth, "features.txt")
    out_fl <- file.path(pth, "tidy_data.txt")
    
    ## File Types
    fl_typ <- c("train", "test")
    
    sub_fl <- character()
    y_fl <- character()
    x_fl <- character()
  
    ### Train and Test set file path preparation
    sub_fl[fl_typ] <- paste(file.path(pth, fl_typ, "subject_"), fl_typ, ".txt", sep = "")
    y_fl[fl_typ] <- paste(file.path(pth, fl_typ, "y_"), fl_typ, ".txt", sep = "")
    x_fl[fl_typ] <- paste(file.path(pth, fl_typ, "X_"), fl_typ, ".txt", sep = "")
    
    ### Initialize lists to store the data frames
    sub_df <- list()
    y_df <- list()
    x_df <- list()
    tmp_df <- list()
```

### Reading the files

There are two types of files provided - Train and Test - each containing 3 files with the
names - subject_train.txt, y_train.txt and X_train.txt (similarly for test). These are along
with the master files that are common for both Train and Test subsets. The master files are:
activity_labels.txt and features.txt  


```r
    ## Read the Master files 
    act_df <- tbl_df(read.table(act_fl, col.names = c("activity_id", "activity_label")))
    ftr_df <- tbl_df(read.table(ftr_fl, col.names = c("ftr_id", "ftr_lbl")))
    
    ## Need to extract only the Mean and Std Dev measurements of features
    req_ftr <- grep("mean\\(|std", ftr_df$ftr_lbl)
    
    ## Tidy the activity variable names
    ### The following steps are followed for the same:
    ### 1. Remove all '.' characters
    ### 2. change 't' and 'f' to their respective full forms
    ### 3. keep '_' between logical words/sub-words
    
    good_var_nm <- gsub("\\(\\)", "",
                        gsub("[.]+", "-",  
                             sub("^f", "freq-dom-sig-", 
                                 sub("^t", "tm-dom-sig-", ftr_df[req_ftr, ]$ftr_lbl)
                             )
                        )
                      )
    
    ## Read the 'Train' and 'Test' Files
    for(f in fl_typ) {
        sub_df[[f]] <- read.table(sub_fl[f], col.names = "subject_id")
        y_df[[f]] <- read.table(y_fl[f], col.names = "activity_id")
        x_df[[f]] <- read.table(x_fl[f])
        
        x_df[[f]] <- x_df[[f]][, req_ftr]
        colnames(x_df[[f]]) <- good_var_nm
        
        ### First join the x and y sets of files
        tmp_df[[f]] <- tbl_df(data.frame(sub_df[[f]], y_df[[f]], x_df[[f]]))
        
        ### Join the Label datasets with activity labels master file
        #### to get the activity labels
        tmp_df[[f]] <- tmp_df[[f]] %>% 
                        inner_join(act_df, by = "activity_id") %>%
                          select(subject_id, activity_label, everything(), -activity_id)
    }
```

The x, y and subject files are joined together using **bind_rows()** function (or any such
similar function can be used). Then, the activity identifier is replaced with its full name
in the last step as shown above.

### Normalize the Data

Once all the necessary variables have been captured, the script normalizes the data by using
the tidyr package and gets the mean of each of the combination of subject, activity and the
variable.


```r
    ## Append the 'Test' and 'Train' files
    int_df <- bind_rows(tmp_df[["train"]], tmp_df[["test"]])
    
    ### Gather the activity variables into a separate column
    tmp <- int_df %>% 
            gather(key = activity_variable, value = measurement, 
                   -c(subject_id, activity_label)) %>% 
              select(subject_id, activity_label, activity_variable, measurement) 
    
    setDT(tmp)
    setkey(tmp,subject_id, activity_label, activity_variable)
    
    ## Get the means of each measurement and store it in a separate column
    tmp <- tmp[, average_measurement_value := mean(measurement), by = key(tmp)]
    
    ## Get the distinct records and drop the measurement column
    final_df <- unique(tmp, by = key(tmp))[, 
                               .(subject_id, activity_label, 
                                 activity_variable,average_measurement_value)
                               ]
    
    str(final_df)
```

### Output

Finally the data is written into an output txt file as asked in the assignment using the
writeFile() function.


```r
    ## Write the tidy file
    write.table(final_df, out_fl, row.names = FALSE)
```

## Data Dictionary  

The following are the variables in the final dataset.

**subject_id**                  Integer                 Ex: 1 , 2 , 3  
   
ID assigned by the collecting system for each subject

**activity_label**              Factor Variable         Ex: "LAYING","SITTING"  
  
The full name of the activity that was performed by the Subject under both Test and Train
conditions

**activity_variable**           Character Vector  

The various measurements/variables that were taken while the subject was undertaking the
said activity by the different sensors on top of the smartphone.

Each variable name has 6 sub-parts within its name each separated by a '-' character.  
The nomenclature for the column names is as follows:  
1. The first three fields (separated by '-') represent whether the measurement is:  
    + tm-dom-sig        ---   Time domain signal   
    + freq_dom_sig      ---   Frequency domain signal    
2. The fourth field represents one of the below:  
    + BodyAcc           ---   Body Acceleration from accelerometer  
    + GravityAcc        ---   Gravity Acceleration from accelerometer  
    + BodyAccJerk       ---   Linear Body Acceleration from accelerometer  
    + BodyGyro          ---   Body Acceleration from gyroscope  
    + BodyGyroJerk      ---   Linear Body Acceleration from gyroscope  
    + BodyAccMag        ---   Magnitude of Body Acceleration from accelerometer  
    + GravityAccMag     ---   Magnitude of Gravity Acceleration from accelerometer  
    + BodyAccJerkMag    ---   Magnitude of Linear Body Acceleration from accelerometer  
    + BodyGyroMag       ---   Magnitude of Body Acceleration from gyroscope  
    + BodyGyroJerkMag   ---   Magnitude of Linear Body Acceleration from gyroscope  
3. The fifth field represents whether the measurement is a:  
    + mean              ---   Average of values taken at frequent intervals  
    + std               ---   Std Deviation of values taken at frequent intervals  
4. The sixth field (optional) contains the orientation associated with the measurement:   
    + X                 ---   X-Axial  
    + Y                 ---   Y-Axial  
    + Z                 ---   Z-Axial  
    

**average_measurement_value**     Numeric         

The average of each measurement per subject and per activity based on the obtained data.  
