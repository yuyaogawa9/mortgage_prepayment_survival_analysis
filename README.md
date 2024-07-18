# mortgage_prepayment_survival_analysis
This repository contains all of the code and dataset that are used in the analysis as well as the way to clean and prepare the raw data from Freddie Mac (https://www.freddiemac.com/research/datasets/sf-loanlevel-dataset). 

Freddie Mac has a full dataset; however, they also prepare a smaller dataset due to its sample size. Sample data provided by Freddie Mac is produced by randomly selecting about 12500 subsample of loans with the same vintage at each quarter. In this analysis, due to computational constraint, I use the sample data prepared by Freddie Mac instead of working with the full dataset. 

1) First step: Now make sure to download each sample folder (e.g., sample_1999, sample_2000, etc) and store them together in a folder named fraddie_mae_data. Each sample folder should contain sample_orig_<year>.txt file and sample_svcg_<year>.txt that are seperated by //. First one is a origination file that stores time invariant loan characteristics. Second one contains the loan performance which varies monthly until loan has a zero remaining balance. The ipynb file I attached named "create_csv.ipynb" visits each sample folder and create a dataframe for both origination data and loan performance data. It then merge together to produce a csv file named loan_performance.csv. Note that you can further reduce the sample size by randomly selecting the loans at each vintage. Due the the size of the data (about 70 million observation), I reduced it to about 5.6 million. 

2) Second step: Open "prepare_data.ipynb" file and run the code. This code will apply the logic to identify the loans that are defaulted or prepaid, create bins for some of the variables used in the paper, calculate the aggregate fraction of loans that are prepaid (and defaulted), and calculate the interest rate gap by averaging the current rate and long term fixed rate. This code will produce two files named "LOAN_surv.csv" and "pp_df_rate.csv"

3) Final step: Run the R code that is provided to replicate the analysis in the html paper. 

