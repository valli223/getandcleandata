############################################
# Script to analyse and tidy a dataset on 
# regular Human Activities 
# Takes an input - the directory containing
# the datasets
############################################
run_analysis <- function(pth) {
  
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
                    
    
    # print(good_var_nm) 
    
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
    
    ## Write the tidy file
    write.table(final_df, out_fl, row.names = FALSE)

}
