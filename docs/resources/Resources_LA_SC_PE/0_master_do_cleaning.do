clear mata
capture log close
set more off

********************************************************************************
*********************** MASTER CLEANING DO FILE ********************************
********************** REPLICATION - ATWOOD (2022) *****************************
********************************************************************************

global home "C:\Users\elsap\Dropbox\replication_project_LA_SC_PE\resources"

global tables  			"$home/output_replication/tables"
global figures 			"$home/output_replication/figures"
global do_files      	"$home/do_files_replication"
global data    			"$home/data_replication"
global raw		    	"$home/raw_data"
global logs   	 		"$home/logs_replication"


*Cleaning the raw files that you downloaded from the replication package to create 3 different datasets for each of the outputs that we will reproduce. 
*Warning: you need to run those 3 do files in the right order because both do file 2 and 3 need do file 1 to proceed without an error.

*Clean the measles incidence rate for the 2 other datasets and to compute the event study graph
do "$do_files/1_do_cleaning_inc_rate_ES.do"

*Clean ACS data from 2000 to 2017 to obtain the main dataset (to replicate the table of main results)
do "$do_files/2_do_cleaning_main_results.do"


*Clean ACS data from 1960 to 1970 to perform the placebo test 
do "$do_files/3_do_cleaning_placebo_test.do"


erase "$data/inc_rate.dta" //not needed in the rest of the analysis
