# getandcleandata
Repository to store the artefacts related to Getting and Cleaning Data course.  

As part of the Course requirements, the script - **run_analysis.R** - has been uploaded into this repository.   
This script performs the following functionalities:  
1. Read all the necessary files related to Human Activity  
2. Join them logically for each subset of Training and Test datasets  
3. Merge/Append the Train and Test datasets  
4. Tidy the variable and activity names  
5. Write the final tidy dataset into an output file for uploading into Coursera Website    

The following are the instructions to run the script on RStudio command line is:  
          **> run_analysis(File_Path)**  
    where, File_Path --> full path of the directory containing the 'train' and 'test' folders related to this assignment  
    
The final tidy file - tidy_data.txt - will be created within the same directory that has been passed as input. A summary of the output file is shown at the end of the script.

The script loads the necessary libraries for its functionalities viz., dplyr, data.table and tidyr. 

A more detailed walkthrough into the various analysis steps is undertaken in the code book - CodeBook.md - file.
