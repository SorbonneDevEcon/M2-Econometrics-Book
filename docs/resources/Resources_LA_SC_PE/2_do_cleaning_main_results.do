clear mata
capture log close
set more off

********************************************************************************
*********************** CLEANING DO FILE 2 *************************************
************* REPLICATION - ATWOOD (2022) - MAIN DATASET ***********************
********************************************************************************

*This do file creates the main dataset used to produce the main results of this paper. It uses both the measles incidence rate of each state between 1952 and 1963, and labor market outcomes of individuals from the ACS, 2000-2017


global home "C:\Users\elsap\Dropbox\replication_project_LA_SC_PE\resources"

global tables  			"$home/output_replication/tables"
global figures 			"$home/output_replication/figures"
global do_files      	"$home/do_files_replication"
global data    			"$home/data_replication"
global raw		    	"$home/raw_data"
global logs   	 		"$home/logs_replication"


**#ACS cleaning (2000-2017)*************************************************


use "$raw/longrun_20002017_acs.dta", clear

*Inclusion criteria ********************************

*keep only those 25 < age < 60 
keep if age>25
keep if age<60

*keep only those native born
generate native=bpl<57
replace native=. if bpl==.

keep if native==1


*keep only black and white people observations
gen white=race==1
gen black=race==2
gen other=race>2

gen blackwhite=1 if white==1 | black==1

keep if blackwhite==1


*Create control variables *************************

* create exposure variable for interaction terms
gen exposure=0 if birthyr<1949

local i = 1
forval year = 1949/1963{
	replace exposure=`i' if birthyr == `year'
	local i = `i' + 1
}
replace exposure=16 if birthyr>1963

*create female identifier
gen female=sex==2

*create control variables for regressions
*dummy for age*black
egen ageblack=group(age black)
*dummy for age*female
egen agefemale=group(age female)
*dummy for black*female
gen blackfemale=black*female
*dummy for age*black*female
egen ageblackfemale=group(age black female)
*interaction for birthplace and black
gen bpl_black=bpl*black
*interaction for birthplace and female
gen bpl_female=bpl*female
*interaction for birthplace and black female
gen bpl_black_female=bpl*black*female


*Outcome variables ********************************************

*create log of income - wage and salary
gen ln_income=log(incwage)

*CPI adjusted income (put in 1999 dollars and then adjusted to 2018 dollars)
gen cpi_incwage=incwage*cpi99*1.507
gen ln_cpi_income=log(cpi_incwage)

*create poverty identifier
gen poverty100=poverty<101
replace poverty100=. if poverty==0


*create hours worked per week variable
gen hrs_worked=uhrswork if !missing(uhrswork)

*create employment status variable 
gen employed=empstat==1
replace employed=. if empstat==3
 
*create a non-0 income variable 
gen cpi_incwage_no0=cpi_incwage
replace cpi_incwage_no0=. if cpi_incwage==0 


save "$data/main_dataset_acs_200017.dta", replace 


*Merge with inc_rate.dta (measles rates)
use "$data/inc_rate.dta", clear

rename state bpl_state
rename statefip bpl

keep bpl* avg*

merge 1:m bpl using "$data/main_dataset_acs_200017.dta"


*create the different M_exp_rate (measles exposure rates) variables
*scale M_exp so coefficients are reader friendly
local i = 2
while `i' <= 12 {

generate M`i'_exp_rate=(avg_`i'yr_measles_rate*exposure)/100000 

local i = `i' + 1 
}

xi i.bpl


*create state of birth-cohort variable 
egen bplcohort=group(bpl birthyr)


*Unweighted 12 years measles rates
preserve 

collapse (mean) avg_12yr_measles_rate, by(bpl_state)

summ avg_12yr_measles_rate
scalar avg_measles_rate = r(mean)  // Store the mean in a scalar variable

restore

display avg_measles_rate //unweighted 12 years average measles rate 

*generate unweighted (line 3 of the table of main results)
gen unweight_avg_12_measles_rate = avg_measles_rate

save "$data/main_dataset_acs_200017", replace 


**# TOY DATASET VERSION*************
*In this part of the code, we are cleaning the dataset created by the author, so that we are only keeping the variables that we need for the main results.


**Keep only the necessary variables
keep year multyear serial hhwt pernum perwt region statefip cpi_incwage cpi_incwage_no0 ln_cpi_income poverty100 employed hrs_worked bpl birthyr ageblackfemale bpl_black bpl_female bpl_black_female black female M12_exp_rate bplcohort exposure unweight_avg_12_measles_rate 



*Label variable of interest
label variable M12_exp_rate "12 years prevacc. infection rate * Exposure to Vaccine"

*Label outcome variables
lab var cpi_incwage "Income"
lab var cpi_incwage_no0 "Income (if $>$ 0)"
lab var ln_cpi_income "ln Income"
lab var poverty100 "Poverty"
lab var employed "Employed"
lab var hrs_worked "Hours worked"

save "$data/main_dataset_acs_200017", replace 