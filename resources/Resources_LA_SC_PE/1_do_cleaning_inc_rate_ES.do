clear mata
capture log close
set more off

********************************************************************************
*********************** CLEANING DO FILE 1 *************************************
************* REPLICATION - ATWOOD (2022) - EVENT STUDY DATASET***************** 
********************************************************************************

*This do file creates the dataset used to calculate measles incidence rate, both in the main dataset and in the dataset used to plot the event study, on the effect of measles vaccine on measles incidence.


global home "C:\Users\elsap\Dropbox\replication_project_LA_SC_PE\resources"

global tables  			"$home/output_replication/tables"
global figures 			"$home/output_replication/figures"
global do_files      	"$home/do_files_replication"
global data    			"$home/data_replication"
global raw		    	"$home/raw_data"
global logs   	 		"$home/logs_replication"



**#1. CALCULATE MEASLES INCIDENCE RATES**************************

use "$raw/case_counts_population.dta", clear

keep population state statefip bpl_region4 bpl_region9 year measles
reshape wide population measles, i(state)  j(year)

*generate measles rate by year
local i = 1952 
while `i' <= 1975 {
gen measles_rate_`i'=((measles`i')/population`i')*100000
label variable measles_rate_`i' "measles rate in `i' per 100,000"
local i = `i' + 1 
}


*generate average pre-vaccine measles rates  
gen avg_2yr_measles_rate=(measles_rate_1962+measles_rate_1963)/2
gen avg_3yr_measles_rate=(measles_rate_1961+measles_rate_1962+measles_rate_1963)/3
gen avg_4yr_measles_rate=(measles_rate_1960+measles_rate_1961+measles_rate_1962+measles_rate_1963)/4
gen avg_5yr_measles_rate=(measles_rate_1959+measles_rate_1960+measles_rate_1961+measles_rate_1962+measles_rate_1963)/5
gen avg_6yr_measles_rate=(measles_rate_1958+measles_rate_1959+measles_rate_1960+measles_rate_1961+measles_rate_1962+measles_rate_1963)/6
gen avg_7yr_measles_rate=(measles_rate_1957+measles_rate_1958+measles_rate_1959+measles_rate_1960+measles_rate_1961+measles_rate_1962+measles_rate_1963)/7
gen avg_8yr_measles_rate=(measles_rate_1956+measles_rate_1957+measles_rate_1958+measles_rate_1959+measles_rate_1960+measles_rate_1961+measles_rate_1962+measles_rate_1963)/8
gen avg_9yr_measles_rate=(measles_rate_1955+measles_rate_1956+measles_rate_1957+measles_rate_1958+measles_rate_1959+measles_rate_1960+measles_rate_1961+measles_rate_1962+measles_rate_1963)/9
gen avg_10yr_measles_rate=(measles_rate_1954+measles_rate_1955+measles_rate_1956+measles_rate_1957+measles_rate_1958+measles_rate_1959+measles_rate_1960+measles_rate_1961+measles_rate_1962+measles_rate_1963)/10
gen avg_11yr_measles_rate=(measles_rate_1953+measles_rate_1954+measles_rate_1955+measles_rate_1956+measles_rate_1957+measles_rate_1958+measles_rate_1959+measles_rate_1960+measles_rate_1961+measles_rate_1962+measles_rate_1963)/11
gen avg_12yr_measles_rate=(measles_rate_1952+measles_rate_1953+measles_rate_1954+measles_rate_1955+measles_rate_1956+measles_rate_1957+measles_rate_1958+measles_rate_1959+measles_rate_1960+measles_rate_1961+measles_rate_1962+measles_rate_1963)/12


save "$data/inc_rate.dta", replace //incidence rate dataset


**#2. DATA CLEANING FOR THE EVENT STUDY ANALYSIS ********

use "$data/inc_rate.dta", clear

keep state* avg_12yr_measles_rate

save "$data/inc_rate_ES.dta", replace 


*Merge with population data
use "$raw/case_counts_population.dta", clear


merge m:1 statefip using "$data/inc_rate_ES.dta"
drop _merge

*generate measles rate by year

gen measles_rate=((measles)/population)*100000
label variable measles_rate "measles rate in  per 100,000"

xi i.statefip //state dummies

gen exp = year - 1964
recode exp (.=-1) (-1000/-6=-6) (11/1000=11)
char exp[omit] -1
xi i.exp, pref(_T) //exposure dummies

 
drop measles pertussis chicken_pox mumps rubella
rename measles_rate Measles


save "$data/inc_rate_ES.dta", replace 
